# Architecture — Satr PDF

Flutter (Dart 3.14, Flutter 3.50) Android app. No backend, no network at
runtime, no AI. Every file is processed on the device.

## Layers

```
lib/
  main.dart              startup: pdfrx init, stores, 30-day trash purge
  app/                   MaterialApp (theme, locale), AppShell (bottom nav), services
  config/app_config.dart name, version, ads switch, limits  <- single place to rename the app
  design/                colour tokens, ThemeData (light/dark), Lucide icons (generated)
  components/            shared widgets: tool scaffold, pickers, job progress sheet, page grid
  ads/                   AdSlot + AdBackend (no-op by default; AdMob via tool/admob)
  l10n/                  app_ar.arb, app_en.arb (+ generated code in l10n/gen)
  core/
    pdf/                 PdfService (pdfrx), PDFium FFI (stamping, metadata, image
                         recompression), page ranges, rendering
    image/               pure-Dart image ops (isolates), HEIC via platform codec
    arabic/              search normalisation, presentation forms, visual->logical order
    render/              text -> PNG with the platform text engine (Arabic shaping)
    ocr/                 Tesseract backend (method channel), hOCR parser
    docx/                minimal DOCX writer with RTL paragraphs
    jobs/                JobContext: progress, cancellation, killable isolates
    storage/             FileStore (blobs + JSON index), SettingsStore
    share/               share sheet, "save to device" (system file dialog)
    platform/            MethodChannel to MainActivity (RAM, free space, shared files)
  features/<tool>/
    <tool>_tool.dart     pure run(inputs, options, JobContext) -> verified OutputFile
    <tool>_screen.dart   UI for the tool
```

Every tool follows: pick → options → run (progress + cancel, button disabled
while running) → result (saved to My files) → open / share / save.

## PDF engine

- **pdfrx / PDFium** opens, renders, merges, splits, reorders, rotates and
  saves PDFs. PDFium runs in pdfrx's own worker isolate, so the UI never
  blocks.
- **Stamps** (watermark, page numbers, drawn signature): the stamp is drawn
  into a small PDF with `pdf` (dart_pdf), turned into a Form XObject with
  `FPDF_NewXObjectFromPage` and placed on each page with a matrix computed
  for the page's crop box and `/Rotate`. One XObject is shared by all pages.
  PDFium appends a new content stream; the original content is not
  regenerated. Native calls run inside `useNativeDocumentHandle`, which
  pauses pdfrx's worker, so PDFium is never used concurrently.
- **Arabic text in output PDFs** is rendered by Flutter's text engine
  (HarfBuzz shaping + bidi) to a PNG at 4x (288 DPI) and embedded as an image
  (spec section 4). It is therefore not selectable — the UI says so.
- **Compression**
  - light: full rewrite by PDFium (drops old incremental revisions);
  - recommended: re-encodes large embedded JPEGs (DCTDecode, no masks) at
    150 DPI / quality 70 via PDFium's page-object API, then renders every
    page before/after at 36 DPI and **falls back to light** if anything
    changed visibly;
  - strong: renders pages to JPEG and rebuilds the PDF (user is warned first).
  - If the result is not smaller, the original is kept and nothing is saved.
- **Verification**: every produced PDF is re-opened with PDFium, its page
  count is checked and `%PDF-` / `%%EOF` are required before it is saved.

## Arabic text extraction

Many writers (e.g. Chromium) store Arabic glyphs left-to-right. PDFium then
returns words with reversed letters. `core/arabic/visual_order.dart` uses the
glyph positions: inside each word, Arabic runs whose x positions increase are
reversed; if the Arabic words themselves are in page order, the line is
converted from visual to logical order. Presentation forms (ﻻ, ﺳ …) are
normalised back to letters (table generated from Unicode NFKC).

## OCR

`tesseract_ocr` (Android: Tesseract4Android) with the bundled `tessdata_fast`
models (ara 1.4 MB, eng 4.1 MB). Images are pre-processed in an isolate
(upright, grayscale, contrast, optional Otsu black/white). The plugin's
`extractHocr` method returns hOCR; words below confidence 60 are highlighted.
Nothing is downloaded: models are copied from the app's assets to private
storage on first use (Settings can remove/prepare that copy).

## Storage

`FileStore`: files in `<app support>/library/blobs/<id>.<ext>` and an atomic
JSON index (`index.json`). Trash keeps items for 30 days (purged at start).
Search uses Arabic normalisation (أ/إ/آ/ا, ة/ه, ى/ي, no tashkeel).
Android auto-backup is disabled so files never leave the device.

## Concurrency & cancellation

`JobContext` reports progress and checks cancellation between units of work
(file, page). CPU-heavy pure-Dart work (JPEG/PNG encoding, DOCX/PDF building,
image pre-processing) runs in a fresh isolate that is **killed immediately**
on cancel. PDFium work runs in pdfrx's worker. Partial results are never
saved.

## Privacy by construction

The release manifest removes `android.permission.INTERNET`
(`tools:node="remove"`), so the shipped app cannot open network connections.
Auto backup and device-transfer are disabled for app data.

## Future (not built)

Camera scanner, password protect/unprotect (needs a permissive engine such as
qpdf), Office conversion, searchable-PDF output, AI features (via a proxy
server, tied to revenue), cloud backup, ads. The tool registry
(`features/tools/tool_registry.dart`) and the `AdBackend` interface are the
extension points.
