# Testing — real results

All numbers below come from actual runs on 17 Nov 2026 (Linux x86_64 build
machine, Flutter 3.50.0, PDFium chromium/8125, Tesseract 5.3.4 CLI for the
accuracy measurement). Nothing here is estimated. What was **not** tested is
listed at the end.

## Summary

| Suite | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | No issues found (exit code 0; generated l10n code excluded) |
| Unit + widget tests | `flutter test` | **71 / 71 passed** |
| End-to-end on the real app (Linux desktop build, real PDFium + Tesseract) | `xvfb-run flutter test integration_test -d linux` | **9 / 9 passed** |
| GitHub Actions (ubuntu-24.04) | `.github/workflows/build.yml` | analyze + all tests + APK/AAB build **succeed** (run 44124439159) |
| Android release build | `flutter build apk --release` | builds; arm64 APK permissions contain **no INTERNET** |
| Licence audit | `python3 tool/licenses/audit.py` | passes: 7 Apache-2.0, 84 BSD-3, 23 MIT, 1 MPL-2.0 (Linux-only `dbus`), no GPL/AGPL |
| AdMob switch | `tool/admob/enable_admob.sh <Google test ids>` on a copy | dependency added, config/manifest updated, AdMob code analyses clean |

## Unit tests (test/unit, test/widget)

- **basics_test (15)**: magic-byte detection (PDF, JPEG, PNG, WebP, HEIC; a
  `.pdf` that is really text is rejected), complete-PDF check (corrupt file
  detected), output names (`contract.pdf` → `contract-compressed.pdf`, Arabic
  names kept, illegal characters replaced), page ranges (`1-3, 5, 8-10`,
  Eastern Arabic digits `١-٣، ٥`, en dash, all error cases), Arabic search
  normalisation (أ/إ/آ/ا, ة/ه, ى/ي, tashkeel, tatweel, ٢٠٢٤ → 2024),
  presentation forms → letters, page-geometry mapping for /Rotate 0/90/180/270,
  PDF dates.
- **pdf_tools_test (28)**: encrypted / corrupt / fake / empty inputs give the
  right error; merge (1+3+50 pages → 54, order checked by page text); split
  by ranges (ZIP of 3,1,3 pages), every 20 (20/20/10), each page, single
  range → plain PDF; extract in chosen order; organize (reorder + rotate 90° +
  duplicate + delete + Letter blank page, verified by page text, rotation and
  size); compress (see numbers below); PDF→JPG at 150 DPI (width 1240 px) and
  PDF→PNG ZIP; images→PDF with EXIF orientation 6 (400×300 photo becomes a
  225×300 pt portrait page) and JPG+PNG(alpha)+WebP on A4; text extraction
  (Arabic, mixed Arabic/English, English, scanned = no text layer); file info
  (pages, A4, version, Title) and metadata removal; cancellation.
- **stamp_tools_test (9)**: Arabic text rendered to PNG matches the reviewed
  reference image (`test/unit/goldens/arabic_text_render.png`, 0.5% pixel
  tolerance); Arabic text watermark on every page (pixel check in the page
  centre, original text layer still present); image watermark only on page 2;
  page numbers (cover skipped, Eastern digits, label rules `١ / ١٢`, `5 / 7`);
  drawn signature placed at the exact rectangle, other pages untouched; stamp
  on a page whose content leaves a 2× CTM (not affected); stamp on a /Rotate 90
  page lands upright at the visual position; 50-page watermark shares one
  XObject (file grows by < 60 KB).
- **storage_text_test (9)**: My files add / rename / favourite / Arabic search
  / sort / reload from disk, duplicate names, trash → restore → 30-day purge →
  delete forever, clear all; hOCR parsing with confidences and low-confidence
  ranges; plain-text engine output; DOCX package with RTL Arabic paragraphs;
  OCR pipeline on the Arabic image.
- **i18n_test (4)**: every key in both `app_ar.arb` and `app_en.arb`, same
  placeholders, no empty strings, no hard-coded words in widget code.
- **widget app_test (5)**: starts in Arabic RTL with the 4 tabs; tools tab
  groups; switching to English flips to LTR; **every one of the 13 tool
  screens opens at phone size (390×844) with its file picker visible**;
  My files empty state.

## End-to-end (integration_test/app_flows_test.dart)

Real app UI, real engines, phone-sized view (390×844 @3x):

1. Home + Tools + My files screens in Arabic (screenshots).
2. **Merge** (Arabic): pick 2 PDFs from My files → merge → result screen →
   file `one_page-merged.pdf` with 4 pages.
3. **Compress** (Arabic): recommended level on the 1.08 MB image PDF → saved
   file smaller than the original.
4. **Images → PDF** (English): JPG + PNG → 2-page PDF.
5. **OCR** (Arabic image): the editable result contains «سطر» and «الملفات».
6. **My files** (English): rename → move to trash → restore.
7. **Viewer**: a PDF opened from My files is displayed (page indicator
   «صفحة 1 من 3» appears once PDFium has loaded it).
8. **Picked / "Open with" file**: opens straight in the viewer; "Save to My
   files" from the menu stores it; "Tools for this file" lists the PDF tools.
9. Home in English (screenshot).

Screenshots: `store/screenshots/` (Arabic and English).

> These e2e runs found and fixed real bugs: tool screens' bottom button
> took the whole screen height (body invisible), and the Linux OCR plugin
> returns plain text instead of hOCR (now handled).
>
> Version 1.0.1 fixes "PDFs don't open" reported from a real phone: a file
> chosen on Home or opened with "Open with" now goes straight to the viewer;
> Flutter deep linking is disabled so Android's content:// link is not taken
> as a route; and files copied after Dart asked for them on a cold start are
> now delivered instead of lost.

## Measured numbers

**Compression** (`test/fixtures/with_images.pdf`, 1,082,509 bytes, one
2400×1800 JPEG at 300 DPI):

| Level | Result | Note |
|---|---|---|
| Strong, 72 DPI | 16,918 bytes (−98.4%) | page becomes an image |
| Recommended | 199,365 bytes (−81.6%), 1 image re-encoded | text/vector untouched, renders compared before/after |
| Light on `english_text.pdf` | 23,812 → 23,784 bytes | tiny gain; when not smaller the original is kept |

**OCR accuracy** (share of expected words found; clean synthetic images
rendered by Chromium; `tool/fixtures/ocr_accuracy.py`):

| Image | tessdata_fast (bundled) | tessdata_best |
|---|---|---|
| Arabic, Noto Naskh 40 px | 24/24 (100%) | 24/24 (100%) |
| Arabic, Readex Pro 40 px | 18/24 (75%) | 21/24 (87.5%) |
| English, DejaVu Serif | 13/13 (100%) | 13/13 (100%) |

Through the app's own pipeline (pre-processing + hOCR parsing, Tesseract
engine with the bundled fast model): Arabic Naskh image 24/24 words, mean
confidence 92.2. Real photos and scans will score lower than these clean
images.

**PDF validity cross-check**: a 50-page watermarked output opens and renders
correctly in a second, independent engine (Poppler `pdftoppm`) and
`qpdf --check` reports no syntax or stream errors.

**Arabic text extraction**: Chromium-generated Arabic PDFs come out of PDFium
with letters reversed inside words; after the position-based reordering the
three fixtures read back exactly (e.g. «سطر تطبيق عربي لمعالجة ملفات على
جهازك», «رقم الطلب 2024 في ملف PDF»).

## NOT tested (honestly)

- **No run on a physical Android phone or emulator** (this build machine has
  no hardware virtualisation). The Android app was compiled (release APK) and
  its manifest/permissions inspected, and the same Dart code was exercised on
  Linux desktop, but these Android-only paths have not been run:
  - Tesseract4Android via the plugin (`extractHocr`), first-run copy of the
    language data;
  - HEIC decoding (needs Android 9+ platform codec);
  - share target / "Open with" intents and `MainActivity` channel;
  - system file picker and "Save to device" dialog;
  - performance and memory on low-end phones; very large files (> 100 MB).
- Lighthouse / PWA scores: not applicable (native app, not a web app).
- Accessibility audit with TalkBack: not done (touch targets ≥ 44 px, labels
  and contrast were designed in but not audited on device).
- DOCX opened in Microsoft Word: not done (package structure is tested).
- iOS: not built.

Run everything:
```bash
flutter analyze
flutter test
xvfb-run -a flutter test integration_test -d linux    # Linux desktop e2e
python3 tool/licenses/audit.py
```
