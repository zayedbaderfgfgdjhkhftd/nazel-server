"""Nazel extraction API.

A small FastAPI service around yt-dlp. The mobile app sends it a social-media
link; the service answers with clean metadata and the list of downloadable
formats, with watermarked variants filtered out.

Endpoints
---------
GET  /health                     liveness probe
POST /api/extract   {"url": ...} metadata + formats (+ carousel items)
GET  /api/download?url=&format_id=&item=
                                 server-side download/merge, streamed back.
                                 Used when a format can't be fetched directly
                                 by the phone (separate audio/video streams,
                                 cookie-bound URLs, HLS playlists, ...).
"""

from __future__ import annotations

import asyncio
import hashlib
import os
import re
import shutil
import tempfile
import time
from typing import Any
from urllib.parse import urlparse

import yt_dlp
from fastapi import BackgroundTasks, Depends, FastAPI, Header, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel, Field

API_KEY = os.getenv("NAZEL_API_KEY", "").strip()
CACHE_TTL = int(os.getenv("NAZEL_CACHE_TTL", "300"))
MAX_FILESIZE_MB = int(os.getenv("NAZEL_MAX_FILESIZE_MB", "500"))
RATE_LIMIT_PER_MIN = int(os.getenv("NAZEL_RATE_LIMIT_PER_MIN", "30"))
COOKIES_FILE = os.getenv("NAZEL_COOKIES_FILE", "").strip() or None
PROXY = os.getenv("NAZEL_PROXY", "").strip() or None

app = FastAPI(title="Nazel API", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

WATERMARK_HINTS = ("watermark", "download_addr")

PLATFORMS: dict[str, tuple[str, ...]] = {
    "tiktok": ("tiktok.com", "douyin.com"),
    "instagram": ("instagram.com", "instagr.am"),
    "facebook": ("facebook.com", "fb.watch", "fb.com"),
    "twitter": ("twitter.com", "x.com", "t.co"),
    "youtube": ("youtube.com", "youtu.be"),
    "snapchat": ("snapchat.com",),
    "pinterest": ("pinterest.com", "pin.it"),
    "reddit": ("reddit.com", "redd.it"),
    "threads": ("threads.net", "threads.com"),
    "likee": ("likee.video", "likee.com"),
    "vimeo": ("vimeo.com",),
    "dailymotion": ("dailymotion.com", "dai.ly"),
    "linkedin": ("linkedin.com",),
    "twitch": ("twitch.tv",),
    "soundcloud": ("soundcloud.com",),
    "kwai": ("kwai.com", "kw.ai"),
}


# --------------------------------------------------------------------------- #
# Infrastructure: auth, rate limiting, cache
# --------------------------------------------------------------------------- #
def require_key(x_api_key: str | None = Header(default=None)) -> None:
    if API_KEY and x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="invalid_api_key")


_hits: dict[str, list[float]] = {}


def rate_limit(request: Request) -> None:
    ip = request.headers.get("x-forwarded-for", request.client.host if request.client else "?")
    ip = ip.split(",")[0].strip()
    now = time.time()
    window = [t for t in _hits.get(ip, []) if now - t < 60]
    if len(window) >= RATE_LIMIT_PER_MIN:
        raise HTTPException(status_code=429, detail="rate_limited")
    window.append(now)
    _hits[ip] = window


_cache: dict[str, tuple[float, dict[str, Any]]] = {}


def cache_get(key: str) -> dict[str, Any] | None:
    hit = _cache.get(key)
    if hit and time.time() - hit[0] < CACHE_TTL:
        return hit[1]
    _cache.pop(key, None)
    return None


def cache_put(key: str, value: dict[str, Any]) -> None:
    if len(_cache) > 500:
        for k in sorted(_cache, key=lambda k: _cache[k][0])[:100]:
            _cache.pop(k, None)
    _cache[key] = (time.time(), value)


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
URL_RE = re.compile(r"https?://[^\s<>\"']+", re.I)


def clean_url(raw: str) -> str:
    m = URL_RE.search(raw.strip())
    if not m:
        raise HTTPException(status_code=400, detail="invalid_url")
    return m.group(0).rstrip(").,;!?")


def detect_platform(url: str) -> str:
    host = (urlparse(url).hostname or "").lower()
    for name, hosts in PLATFORMS.items():
        if any(host == h or host.endswith("." + h) for h in hosts):
            return name
    return "other"


def ydl_opts(**extra: Any) -> dict[str, Any]:
    opts: dict[str, Any] = {
        "quiet": True,
        "no_warnings": True,
        "noplaylist": False,
        "skip_download": True,
        "socket_timeout": 20,
        "retries": 2,
        "extractor_retries": 2,
        "geo_bypass": True,
        "http_headers": {
            "User-Agent": (
                "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 "
                "(KHTML, like Gecko) Chrome/126.0 Mobile Safari/537.36"
            )
        },
    }
    if COOKIES_FILE and os.path.exists(COOKIES_FILE):
        opts["cookiefile"] = COOKIES_FILE
    if PROXY:
        opts["proxy"] = PROXY
    opts.update(extra)
    return opts


def is_watermarked(f: dict[str, Any]) -> bool:
    text = " ".join(str(f.get(k) or "") for k in ("format_id", "format_note", "format")).lower()
    return any(h in text for h in WATERMARK_HINTS)


def format_label(f: dict[str, Any], kind: str) -> str:
    if kind == "audio":
        abr = f.get("abr")
        return f"MP3 / {int(abr)}kbps" if abr else "Audio"
    h = f.get("height")
    if h:
        fps = f.get("fps")
        tag = "4K" if h >= 2160 else "2K" if h >= 1440 else "Full HD" if h >= 1080 else "HD" if h >= 720 else "SD"
        return f"{h}p {tag}" + (f" {int(fps)}fps" if fps and fps > 30 else "")
    return f.get("format_note") or f.get("format_id") or "Video"


def build_formats(info: dict[str, Any]) -> list[dict[str, Any]]:
    raw = info.get("formats") or [info]
    out: list[dict[str, Any]] = []
    best_by_height: dict[int, dict[str, Any]] = {}
    best_audio: dict[str, Any] | None = None

    for f in raw:
        if is_watermarked(f) or f.get("ext") in ("mhtml",):
            continue
        vcodec, acodec = f.get("vcodec"), f.get("acodec")
        has_video = vcodec not in (None, "none") or (vcodec is None and f.get("height"))
        has_audio = acodec not in (None, "none") or (acodec is None and not f.get("height"))
        protocol = str(f.get("protocol") or "https")

        if not has_video and has_audio:
            if best_audio is None or (f.get("abr") or 0) > (best_audio.get("abr") or 0):
                best_audio = f
            continue
        if not has_video:
            continue

        height = int(f.get("height") or 0)
        score = (
            1 if has_audio else 0,  # progressive first: no merge needed
            1 if protocol.startswith("http") and "m3u8" not in protocol else 0,
            f.get("tbr") or 0,
        )
        prev = best_by_height.get(height)
        if prev is None or score > prev["_score"]:
            best_by_height[height] = {**f, "_score": score, "_has_audio": bool(has_audio)}

    for height in sorted(best_by_height, reverse=True):
        f = best_by_height[height]
        protocol = str(f.get("protocol") or "https")
        direct = (
            f["_has_audio"]
            and protocol in ("http", "https")
            and bool(f.get("url"))
        )
        out.append(
            {
                "id": f.get("format_id"),
                "kind": "video",
                "label": format_label(f, "video"),
                "ext": "mp4" if not direct else (f.get("ext") or "mp4"),
                "height": height or None,
                "filesize": f.get("filesize") or f.get("filesize_approx"),
                "has_audio": f["_has_audio"],
                "direct": direct,
                "url": f.get("url") if direct else None,
                "headers": _headers_for(f, info) if direct else None,
            }
        )

    if best_audio:
        out.append(
            {
                "id": best_audio.get("format_id"),
                "kind": "audio",
                "label": format_label(best_audio, "audio"),
                "ext": "m4a" if best_audio.get("ext") in ("m4a", "mp4") else (best_audio.get("ext") or "m4a"),
                "height": None,
                "filesize": best_audio.get("filesize") or best_audio.get("filesize_approx"),
                "has_audio": True,
                "direct": str(best_audio.get("protocol") or "https") in ("http", "https"),
                "url": best_audio.get("url"),
                "headers": _headers_for(best_audio, info),
            }
        )
    return out


def _headers_for(f: dict[str, Any], info: dict[str, Any]) -> dict[str, str]:
    headers = dict(f.get("http_headers") or info.get("http_headers") or {})
    cookies = f.get("cookies") or info.get("cookies")
    if cookies:
        headers["Cookie"] = cookies
    return {k: str(v) for k, v in headers.items()}


def build_item(info: dict[str, Any]) -> dict[str, Any]:
    thumbs = info.get("thumbnails") or []
    thumb = info.get("thumbnail") or (thumbs[-1].get("url") if thumbs else None)
    formats = build_formats(info)
    is_image = not formats and (info.get("ext") in ("jpg", "jpeg", "png", "webp") or bool(thumb))
    return {
        "id": str(info.get("id") or ""),
        "title": (info.get("title") or info.get("description") or "")[:300],
        "thumbnail": thumb,
        "duration": info.get("duration"),
        "type": "image" if is_image else "video",
        "image_url": (info.get("url") or thumb) if is_image else None,
        "formats": formats,
    }


def extract_sync(url: str) -> dict[str, Any]:
    with yt_dlp.YoutubeDL(ydl_opts()) as ydl:
        info = ydl.extract_info(url, download=False)
    info = ydl.sanitize_info(info)
    entries = [e for e in (info.get("entries") or []) if e] if info.get("_type") == "playlist" else [info]
    entries = entries[:30]
    return {
        "source_url": url,
        "platform": detect_platform(url),
        "title": (info.get("title") or info.get("description") or "")[:300],
        "author": info.get("uploader") or info.get("channel") or info.get("creator"),
        "author_avatar": None,
        "thumbnail": info.get("thumbnail") or (entries[0].get("thumbnail") if entries else None),
        "duration": info.get("duration"),
        "items": [build_item(e) for e in entries],
    }


def friendly_error(e: Exception) -> tuple[int, str]:
    msg = str(e).lower()
    if "private" in msg or "login" in msg or "cookies" in msg or "sign in" in msg:
        return 403, "private_or_login_required"
    if "unsupported url" in msg:
        return 422, "unsupported_url"
    if "not available" in msg or "removed" in msg or "404" in msg:
        return 404, "not_found"
    if "geo" in msg or "country" in msg:
        return 451, "geo_blocked"
    return 502, "extraction_failed"


# --------------------------------------------------------------------------- #
# Routes
# --------------------------------------------------------------------------- #
class ExtractRequest(BaseModel):
    url: str = Field(..., min_length=8, max_length=2048)


@app.get("/api/app-version")
def app_version() -> dict[str, Any]:
    """Latest app release, for the in-app updater (set via env on the host)."""
    return {
        "version": os.getenv("NAZEL_APP_VERSION", ""),
        "build": int(os.getenv("NAZEL_APP_BUILD", "0") or 0),
        "url": os.getenv("NAZEL_APP_URL", ""),
        "notes": os.getenv("NAZEL_APP_NOTES", ""),
        "force": os.getenv("NAZEL_APP_FORCE", "false").lower() == "true",
    }


@app.get("/health")
def health() -> dict[str, Any]:
    return {"ok": True, "yt_dlp": yt_dlp.version.__version__}


@app.post("/api/extract", dependencies=[Depends(require_key), Depends(rate_limit)])
async def extract(req: ExtractRequest) -> JSONResponse:
    url = clean_url(req.url)
    key = hashlib.sha1(url.encode()).hexdigest()
    if (cached := cache_get(key)) is not None:
        return JSONResponse(cached)
    try:
        data = await asyncio.to_thread(extract_sync, url)
    except yt_dlp.utils.DownloadError as e:
        status, code = friendly_error(e)
        raise HTTPException(status_code=status, detail=code) from e
    if not any(i["formats"] or i["image_url"] for i in data["items"]):
        raise HTTPException(status_code=404, detail="no_media_found")
    cache_put(key, data)
    return JSONResponse(data)


@app.get("/api/download", dependencies=[Depends(require_key), Depends(rate_limit)])
async def download(
    background: BackgroundTasks,
    url: str = Query(..., min_length=8, max_length=2048),
    format_id: str | None = Query(default=None, max_length=64),
    item: int = Query(default=0, ge=0, le=29),
    audio_only: bool = Query(default=False),
) -> FileResponse:
    url = clean_url(url)
    workdir = tempfile.mkdtemp(prefix="nazel_")
    background.add_task(shutil.rmtree, workdir, ignore_errors=True)

    if audio_only:
        selector = f"{format_id}/bestaudio/best" if format_id else "bestaudio/best"
    else:
        selector = (
            f"{format_id}+bestaudio[ext=m4a]/{format_id}+bestaudio/{format_id}/best"
            if format_id
            else "bestvideo*+bestaudio/best"
        )

    opts = ydl_opts(
        skip_download=False,
        format=selector,
        format_sort=["vcodec:h264", "acodec:aac"],
        merge_output_format="mp4",
        outtmpl=os.path.join(workdir, "%(id)s.%(ext)s"),
        playlist_items=str(item + 1),
        max_filesize=MAX_FILESIZE_MB * 1024 * 1024,
        concurrent_fragment_downloads=4,
    )

    def run() -> str:
        with yt_dlp.YoutubeDL(opts) as ydl:
            ydl.download([url])
        files = [os.path.join(workdir, f) for f in os.listdir(workdir) if not f.endswith(".part")]
        if not files:
            raise yt_dlp.utils.DownloadError("no file produced")
        return max(files, key=os.path.getsize)

    try:
        path = await asyncio.to_thread(run)
    except yt_dlp.utils.DownloadError as e:
        status, code = friendly_error(e)
        raise HTTPException(status_code=status, detail=code) from e

    ext = os.path.splitext(path)[1] or ".mp4"
    media = "audio/mp4" if audio_only else "video/mp4"
    return FileResponse(path, media_type=media, filename=f"nazel_{int(time.time())}{ext}")
