import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:satr_pdf/core/pdf/pdf_service.dart';
import 'package:satr_pdf/core/pdf/render.dart';

final fixturesDir = Directory('test/fixtures');

Uint8List fixture(String name) => File('${fixturesDir.path}/$name').readAsBytesSync();

InputFile input(String name) => InputFile(name, fixture(name));

bool _pdfiumReady = false;

/// Initialises PDFium for host tests (set PDFIUM_PATH to override the library).
Future<void> initPdfium() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (_pdfiumReady) return;
  await pdfrxInitialize();
  _pdfiumReady = true;
}

bool _fontsReady = false;

/// Loads the bundled Readex Pro font so dart:ui text rendering is real.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (_fontsReady) return;
  final loader = FontLoader('ReadexPro')
    ..addFont(rootBundle.load('assets/fonts/ReadexPro-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/ReadexPro-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/ReadexPro-Bold.ttf'));
  await loader.load();
  _fontsReady = true;
}

Future<PdfDocument> openPdf(Uint8List bytes) =>
    PdfDocument.openData(bytes, sourceName: PdfService.sourceName('test'));

Future<int> pageCountOf(Uint8List bytes) async {
  final d = await openPdf(bytes);
  try {
    return d.pages.length;
  } finally {
    await d.dispose();
  }
}

Future<RenderedPage> renderPdfPage(Uint8List bytes, int index, {double dpi = 72}) async {
  final d = await openPdf(bytes);
  try {
    return await renderPage(d.pages[index], dpi);
  } finally {
    await d.dispose();
  }
}

/// Fraction of pixels in a rect (in pixels) that are "dark/coloured"
/// (not near-white).
double inkRatio(RenderedPage r, int x0, int y0, int x1, int y1) {
  var ink = 0, total = 0;
  for (var y = y0.clamp(0, r.height); y < y1.clamp(0, r.height); y++) {
    for (var x = x0.clamp(0, r.width); x < x1.clamp(0, r.width); x++) {
      final i = (y * r.width + x) * 4;
      final lum = (r.bgra[i] + r.bgra[i + 1] + r.bgra[i + 2]) / 3;
      if (lum < 200) ink++;
      total++;
    }
  }
  return total == 0 ? 0 : ink / total;
}
