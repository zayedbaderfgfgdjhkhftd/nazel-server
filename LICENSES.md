# Licences — Satr PDF

Rule (spec section 2.4): only permissive licences (MIT, Apache-2.0, BSD, ISC,
and OFL for fonts). **No GPL / AGPL** (e.g. MuPDF is not used).

Run `python3 tool/licenses/audit.py` to re-check every Dart package in
`pubspec.lock`; it fails on GPL/AGPL/LGPL/unknown licences. The in-app page
(Settings → Open-source licenses) shows the full texts.

## Main components

| Component | Licence | Used for |
|---|---|---|
| Flutter / Dart SDK | BSD-3-Clause | App framework |
| PDFium (via pdfium-binaries) | BSD-3-Clause / Apache-2.0 | Open, render, edit, save PDFs |
| pdfrx, pdfium_dart, pdfium_flutter | MIT | PDFium bindings + viewer |
| pdf (dart_pdf) | Apache-2.0 | Building PDFs (images → PDF, stamps) |
| Tesseract OCR | Apache-2.0 | Text recognition engine |
| Tesseract4Android | Apache-2.0 | Tesseract build for Android (incl. Leptonica BSD-2) |
| tesseract_ocr (Flutter plugin) | BSD-3-Clause | Bridge to Tesseract |
| tessdata_fast `ara`, `eng` | Apache-2.0 | OCR language models (bundled) |
| image | MIT | Image decoding/encoding, EXIF, pre-processing |
| archive | MIT | ZIP output, DOCX packaging |
| file_picker | MIT | Choosing / saving files |
| share_plus, path_provider, intl, path | BSD-3-Clause | Sharing, paths, dates/numbers |
| flutter_svg | MIT | Rendering the icons |
| reorderable_grid | MIT | Drag-to-reorder page grid |
| Lucide icons | ISC | Icon set (stroke 1.75) |
| Readex Pro | SIL OFL 1.1 | Arabic + Latin font |

Native third-party code inside PDFium and Tesseract (FreeType under the FTL,
libjpeg-turbo, libpng, zlib, lcms2, OpenJPEG, Abseil, ICU, AGG) is listed in
`assets/licenses/NATIVE_NOTICES.txt` and shown in the app.

Fixture-generation tools used only during development (not shipped):
Chromium/Playwright, Pillow, pillow-heif, qpdf, fonttools.

## Every Dart package (from pubspec.lock)

`dbus` (MPL-2.0) is only a dependency of `file_picker_linux` (Linux desktop
builds used for testing). It is not compiled into the Android app.

| Package | Version | Dependency | Licence |
|---|---|---|---|
| android_file_picker | 2.2.0 | transitive | MIT |
| archive | 4.7.1 | direct main | MIT |
| args | 2.7.0 | transitive | BSD-3-Clause |
| async | 2.13.1 | transitive | BSD-3-Clause |
| barcode | 2.2.9 | transitive | Apache-2.0 |
| bidi | 2.0.13 | transitive | MIT |
| boolean_selector | 2.1.2 | transitive | BSD-3-Clause |
| characters | 1.4.1 | transitive | BSD-3-Clause |
| cli_util | 0.6.0 | transitive | BSD-3-Clause |
| clock | 1.1.3 | transitive | Apache-2.0 |
| code_assets | 2.2.0 | transitive | BSD-3-Clause |
| collection | 1.19.1 | transitive | BSD-3-Clause |
| cross_file | 0.3.5+5 | transitive | BSD-3-Clause |
| crypto | 3.0.8 | transitive | BSD-3-Clause |
| cupertino_ui | 1.1.7 | direct main | BSD-3-Clause |
| dbus | 0.8.0 | transitive | MPL-2.0 (Linux desktop only, not in the Android app) |
| fake_async | 1.3.3 | transitive | Apache-2.0 |
| ffi | 2.2.0 | direct main | BSD-3-Clause |
| ffi_leak_tracker | 0.1.2 | transitive | BSD-3-Clause |
| file | 7.0.1 | transitive | BSD-3-Clause |
| file_picker | 13.4.0 | direct main | MIT |
| file_picker_darwin | 2.5.1 | transitive | MIT |
| file_picker_linux | 2.0.4 | transitive | MIT |
| file_picker_platform_interface | 4.3.0 | transitive | MIT |
| file_picker_web | 4.2.1 | transitive | MIT |
| fixnum | 1.1.1 | transitive | BSD-3-Clause |
| flutter | 0.0.0 | direct main | BSD-3-Clause |
| flutter_driver | 0.0.0 | transitive | BSD-3-Clause |
| flutter_lints | 6.0.0 | direct dev | BSD-3-Clause |
| flutter_localizations | 0.0.0 | direct main | BSD-3-Clause |
| flutter_svg | 2.4.0 | direct main | MIT |
| flutter_test | 0.0.0 | direct dev | BSD-3-Clause |
| flutter_web_plugins | 0.0.0 | transitive | BSD-3-Clause |
| fuchsia_remote_debug_protocol | 0.0.0 | transitive | BSD-3-Clause |
| glob | 2.2.0 | transitive | BSD-3-Clause |
| hooks | 2.2.0 | transitive | BSD-3-Clause |
| http | 1.6.0 | transitive | BSD-3-Clause |
| http_parser | 4.1.2 | transitive | BSD-3-Clause |
| image | 4.13.1 | direct main | MIT |
| integration_test | 0.0.0 | direct dev | BSD-3-Clause |
| intl | 0.20.3 | direct main | BSD-3-Clause |
| jni | 1.1.2 | transitive | BSD-3-Clause |
| jni_flutter | 1.0.4+1 | transitive | BSD-3-Clause |
| jni_util | 1.0.0 | transitive | BSD-3-Clause |
| leak_tracker | 11.0.2 | transitive | BSD-3-Clause |
| leak_tracker_flutter_testing | 3.0.10 | transitive | BSD-3-Clause |
| leak_tracker_testing | 3.0.2 | transitive | BSD-3-Clause |
| lints | 6.1.0 | transitive | BSD-3-Clause |
| listen | 1.0.1 | transitive | BSD-3-Clause |
| logging | 1.3.0 | transitive | BSD-3-Clause |
| matcher | 0.12.20 | transitive | BSD-3-Clause |
| material_color_utilities | 0.13.0 | transitive | Apache-2.0 |
| material_ui | 1.11.1 | direct main | BSD-3-Clause |
| meta | 1.19.0 | transitive | BSD-3-Clause |
| mime | 2.1.0 | transitive | BSD-3-Clause |
| native_toolchain_c | 0.19.6 | transitive | BSD-3-Clause |
| objective_c | 9.6.4 | transitive | BSD-3-Clause |
| package_config | 3.0.0 | transitive | BSD-3-Clause |
| path | 1.9.1 | direct main | BSD-3-Clause |
| path_parsing | 1.1.0 | transitive | MIT |
| path_provider | 2.1.6 | direct main | BSD-3-Clause |
| path_provider_android | 2.3.1 | transitive | BSD-3-Clause |
| path_provider_foundation | 2.6.0 | transitive | BSD-3-Clause |
| path_provider_linux | 2.2.2 | transitive | BSD-3-Clause |
| path_provider_platform_interface | 2.1.3 | transitive | BSD-3-Clause |
| path_provider_windows | 2.3.0 | transitive | BSD-3-Clause |
| pdf | 3.13.1 | direct main | Apache-2.0 |
| pdfium_dart | 0.4.3 | direct main | MIT |
| pdfium_flutter | 0.4.3 | transitive | MIT |
| pdfrx | 2.13.0 | direct main | MIT |
| pdfrx_engine | 0.9.3 | transitive | MIT |
| petitparser | 7.1.0 | transitive | MIT |
| platform | 3.2.0 | transitive | BSD-3-Clause |
| plugin_platform_interface | 2.1.8 | transitive | BSD-3-Clause |
| posix | 6.5.4 | transitive | MIT |
| process | 5.0.6 | transitive | BSD-3-Clause |
| pub_semver | 2.2.1 | transitive | BSD-3-Clause |
| qr | 3.0.3 | transitive | BSD-3-Clause |
| record_use | 1.1.1 | transitive | BSD-3-Clause |
| reorderable_grid | 1.0.13 | direct main | MIT |
| rxdart | 0.28.0 | transitive | Apache-2.0 |
| share_plus | 13.3.1 | direct main | BSD-3-Clause |
| share_plus_platform_interface | 7.2.0 | transitive | BSD-3-Clause |
| sky_engine | 0.0.0 | transitive | BSD-3-Clause |
| source_span | 1.10.2 | transitive | BSD-3-Clause |
| stack_trace | 1.12.2 | transitive | BSD-3-Clause |
| stream_channel | 2.1.4 | transitive | BSD-3-Clause |
| string_scanner | 1.4.1 | transitive | BSD-3-Clause |
| sync_http | 0.3.1 | transitive | BSD-3-Clause |
| synchronized | 3.6.1+1 | transitive | MIT |
| term_glyph | 1.2.2 | transitive | BSD-3-Clause |
| tesseract_ocr | 0.6.0 | direct main | BSD-3-Clause |
| test_api | 0.7.14 | transitive | BSD-3-Clause |
| typed_data | 1.4.0 | transitive | BSD-3-Clause |
| url_launcher | 6.3.3 | transitive | BSD-3-Clause |
| url_launcher_android | 6.3.33 | transitive | BSD-3-Clause |
| url_launcher_ios | 6.4.2 | transitive | BSD-3-Clause |
| url_launcher_linux | 3.2.3 | transitive | BSD-3-Clause |
| url_launcher_macos | 3.2.6 | transitive | BSD-3-Clause |
| url_launcher_platform_interface | 2.3.2 | transitive | BSD-3-Clause |
| url_launcher_web | 2.4.3 | transitive | BSD-3-Clause |
| url_launcher_windows | 3.1.6 | transitive | BSD-3-Clause |
| uuid | 4.6.0 | transitive | MIT |
| vector_graphics | 1.3.1 | transitive | BSD-3-Clause |
| vector_graphics_codec | 1.2.0 | transitive | BSD-3-Clause |
| vector_graphics_compiler | 1.3.6 | transitive | BSD-3-Clause |
| vector_math | 2.4.3 | transitive | BSD-3-Clause |
| vm_service | 15.4.0 | transitive | BSD-3-Clause |
| web | 1.1.2 | transitive | BSD-3-Clause |
| webdriver | 3.2.0 | transitive | Apache-2.0 |
| win32 | 6.4.0 | transitive | BSD-3-Clause |
| windows_file_picker | 2.0.2 | transitive | MIT |
| xdg_directories | 1.1.0 | transitive | BSD-3-Clause |
| xml | 7.0.1 | transitive | MIT |
| yaml | 3.1.4 | transitive | MIT |
