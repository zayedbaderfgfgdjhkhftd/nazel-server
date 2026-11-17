import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:satr_pdf/core/image/image_ops.dart';
import 'package:satr_pdf/core/jobs/job.dart';
import 'package:satr_pdf/core/render/text_image.dart';
import 'package:satr_pdf/features/page_numbers/page_numbers_tool.dart';
import 'package:satr_pdf/features/signature/signature_tool.dart';
import 'package:satr_pdf/features/watermark/watermark_tool.dart';

import '../helpers.dart';

void main() {
  setUpAll(() async {
    await initPdfium();
    await loadAppFonts();
  });

  group('Arabic text rendered to an image (spec section 4)', () {
    test('matches the reference rendering', () async {
      final rt = await renderTextImage('سطر: ملفاتك تبقى على جهازك 2024',
          fontSizePt: 24, color: const ui.Color(0xFF14171C), scale: 3);
      expect(rt.widthPt, greaterThan(100));
      expect(rt.heightPt, greaterThan(20));
      final decoded = img.decodePng(rt.png)!;
      // Not blank: a reasonable share of pixels carries ink.
      final inked = decoded.where((p) => p.a > 128).length / (decoded.width * decoded.height);
      expect(inked, inInclusiveRange(0.05, 0.6));
      // Reference image reviewed by eye (letters joined, right-to-left).
      // Regenerate with: flutter test --update-goldens test/unit/stamp_tools_test.dart
      await expectLater(rt.png, matchesGoldenFile('goldens/arabic_text_render.png'));
    });
    test('rotation grows the bounds', () async {
      final flat = await renderTextImage('سري', fontSizePt: 40, color: const ui.Color(0xFF000000));
      final rot = await renderTextImage('سري',
          fontSizePt: 40, color: const ui.Color(0xFF000000), rotationDeg: 45);
      expect(rot.heightPt, greaterThan(flat.heightPt));
    });
  });

  test('Arabic text watermark is drawn in the centre of every page', () async {
    final out = await runWatermark(
      input('three_pages.pdf'),
      const WatermarkOptions(
          text: 'سري للغاية', opacity: 0.8, rotationDeg: 0, fontSizePt: 60, color: ui.Color(0xFFB42318)),
      JobContext(),
    );
    expect(out.pageCount, 3);
    for (var p = 0; p < 3; p++) {
      final r = await renderPdfPage(out.bytes, p);
      // Centre band of the page now has red ink.
      final cx = r.width ~/ 2, cy = r.height ~/ 2;
      expect(_redRatio(r, cx - 120, cy - 25, cx + 120, cy + 25), greaterThan(0.05),
          reason: 'page ${p + 1}');
    }
    // Text layer of the original page is preserved.
    final d = await openPdf(out.bytes);
    expect((await d.pages[0].loadText())!.fullText, contains('Page 1'));
    await d.dispose();
  });

  test('image watermark only on selected pages', () async {
    final out = await runWatermark(
      input('three_pages.pdf'),
      WatermarkOptions(
        type: WatermarkType.image,
        imageBytes: fixture('alpha.png'),
        opacity: 1,
        rotationDeg: 0,
        imageWidthFraction: 0.5,
        anchor: Anchor9.center,
        pagesText: '2',
      ),
      JobContext(),
    );
    final p1 = await renderPdfPage(out.bytes, 0);
    final p2 = await renderPdfPage(out.bytes, 1);
    final cx = p1.width ~/ 2, cy = p1.height ~/ 2;
    expect(_blueRatio(p1, cx - 50, cy - 20, cx + 50, cy + 20), lessThan(0.01));
    expect(_blueRatio(p2, cx - 50, cy - 20, cx + 50, cy + 20), greaterThan(0.5));
  });

  test('page numbers: bottom centre, Eastern Arabic digits, cover skipped', () async {
    expect(pageLabel(0, 3, const PageNumberOptions(skipFirst: true)), isNull);
    expect(pageLabel(1, 3, const PageNumberOptions(skipFirst: true)), '2');
    expect(pageLabel(0, 12, const PageNumberOptions(withTotal: true, easternDigits: true)), '١ / ١٢');
    expect(pageLabel(0, 3, const PageNumberOptions(start: 5, withTotal: true)), '5 / 7');

    final out = await runPageNumbers(input('three_pages.pdf'),
        const PageNumberOptions(skipFirst: true, easternDigits: true, fontSizePt: 16), JobContext());
    expect(out.pageCount, 3);
    final first = await renderPdfPage(out.bytes, 0);
    final second = await renderPdfPage(out.bytes, 1);
    final cx = first.width ~/ 2, h = first.height;
    // Bottom band, centred: empty on the cover, ink on page 2.
    expect(inkRatio(first, cx - 15, h - 45, cx + 15, h - 20), lessThan(0.01));
    expect(inkRatio(second, cx - 15, h - 45, cx + 15, h - 20), greaterThan(0.03));
  });

  test('drawn signature lands where it was placed', () async {
    final png = removeWhiteBackgroundJob((bytes: fixture('signature_photo.jpg'), threshold: 200));
    final sig = img.decodePng(png)!;
    expect(hasTransparency(sig), isTrue, reason: 'white background removed');
    final out = await runSignature(
      input('three_pages.pdf'),
      SignatureOptions(
        png: png,
        pngWidth: sig.width,
        pngHeight: sig.height,
        pageIndex: 2,
        left: 0.55,
        top: 0.8,
        width: 0.35,
      ),
      JobContext(),
    );
    final r = await renderPdfPage(out.bytes, 2);
    final x0 = (r.width * 0.55).round(), y0 = (r.height * 0.8).round();
    final w = (r.width * 0.35).round();
    final hgt = (w * sig.height / sig.width).round();
    expect(inkRatio(r, x0, y0, x0 + w, y0 + hgt), greaterThan(0.02));
    // Other pages untouched.
    final other = await renderPdfPage(out.bytes, 0);
    expect(inkRatio(other, x0, y0, x0 + w, y0 + hgt), lessThan(0.005));
  });

  test('stamp is not affected by a page that leaves its CTM scaled', () async {
    // unbalanced_cm.pdf is 400x400 pt and ends its content with a 2x scale.
    final png = img.encodePng(img.Image(width: 40, height: 40)
      ..clear(img.ColorRgba8(0, 160, 0, 255)));
    final out = await runSignature(
      input('unbalanced_cm.pdf'),
      SignatureOptions(png: png, pngWidth: 40, pngHeight: 40, pageIndex: 0, left: 0.75, top: 0.05, width: 0.1),
      JobContext(),
    );
    final r = await renderPdfPage(out.bytes, 0);
    // Expected at x 300..340, y 20..60 (pt == px at 72 DPI).
    expect(_greenRatio(r, 305, 25, 335, 55), greaterThan(0.8));
  });

  test('stamp on a rotated page appears upright at the visual position', () async {
    // rotated.pdf page 1 has /Rotate 90 (displayed landscape).
    final png = img.encodePng(img.Image(width: 80, height: 40)
      ..clear(img.ColorRgba8(0, 160, 0, 255)));
    final out = await runSignature(
      input('rotated.pdf'),
      SignatureOptions(png: png, pngWidth: 80, pngHeight: 40, pageIndex: 0, left: 0.05, top: 0.05, width: 0.2),
      JobContext(),
    );
    final r = await renderPdfPage(out.bytes, 0);
    expect(r.width, greaterThan(r.height), reason: 'rendered landscape');
    final x0 = (r.width * 0.05).round(), y0 = (r.height * 0.05).round();
    final w = (r.width * 0.2).round(), h = w ~/ 2;
    expect(_greenRatio(r, x0 + 3, y0 + 3, x0 + w - 3, y0 + h - 3), greaterThan(0.8));
  });

  test('stamping produces a valid file for every fixture page size', () async {
    final out = await runWatermark(
        input('fifty_pages.pdf'), const WatermarkOptions(text: 'Satr'), JobContext());
    expect(out.pageCount, 50);
    // Shared XObject: 50 stamped pages cost far less than 50 copies.
    expect(out.bytes.length, lessThan(fixture('fifty_pages.pdf').length + 60000));
    File('build/test-output/watermarked50.pdf')
      ..createSync(recursive: true)
      ..writeAsBytesSync(out.bytes);
  });
}

double _colorRatio(dynamic r, int x0, int y0, int x1, int y1, bool Function(int b, int g, int rr) f) {
  final bgra = r.bgra as Uint8List;
  final width = r.width as int;
  var hit = 0, total = 0;
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final i = (y * width + x) * 4;
      if (f(bgra[i], bgra[i + 1], bgra[i + 2])) hit++;
      total++;
    }
  }
  return total == 0 ? 0 : hit / total;
}

double _redRatio(dynamic r, int x0, int y0, int x1, int y1) =>
    _colorRatio(r, x0, y0, x1, y1, (b, g, rr) => rr > 150 && g < 120 && b < 120);
double _greenRatio(dynamic r, int x0, int y0, int x1, int y1) =>
    _colorRatio(r, x0, y0, x1, y1, (b, g, rr) => g > 120 && rr < 60 && b < 60);
double _blueRatio(dynamic r, int x0, int y0, int x1, int y1) =>
    _colorRatio(r, x0, y0, x1, y1, (b, g, rr) => b > 150 && rr < 80);
