FROM python:3.12-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends ffmpeg ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /srv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# yt-dlp breaks when sites change; upgrade on every container start.
ENV PORT=8000
CMD pip install --no-cache-dir -U yt-dlp >/dev/null 2>&1; \
    uvicorn app.main:app --host 0.0.0.0 --port ${PORT} --workers 2 --proxy-headers
