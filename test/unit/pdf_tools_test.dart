import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';
import 'package:satr_pdf/core/errors.dart';
import 'package:satr_pdf/core/jobs/job.dart';
import 'package:satr_pdf/core/pdf/pdf_service.dart';
import 'package:satr_pdf/features/compress/compress_tool.dart';
import 'package:satr_pdf/features/extract/extract_tool.dart';
import 'package:satr_pdf/features/file_info/file_info_tool.dart';
import 'package:satr_pdf/features/images_to_pdf/images_to_pdf_tool.dart';
import 'package:satr_pdf/features/merge/merge_tool.dart';
import 'package:satr_pdf/features/organize/organize_tool.dart';
import 'package:satr_pdf/features/pdf_to_images/pdf_to_images_tool.dart';
import 'package:satr_pdf/features/split/split_tool.dart';
import 'package:satr_pdf/features/text_extract/text_extract_tool.dart';

import '../helpers.dart';

Matcher throwsAppError(AppErrorCode code) =>
    throwsA(predicate((e) => e is AppException && e.code == code, 'AppException($code)'));

void main() {
  setUpAll(initPdfium);

  group('input validation', () {
    test('encrypted PDF is refused by editing tools', () async {
      expect(PdfService.openForEdit(fixture('encrypted.pdf')), throwsAppError(AppErrorCode.encrypted));
      expect(await PdfService.isEncrypted(fixture('encrypted.pdf')), isTrue);
      expect(await PdfService.isEncrypted(fixture('one_page.pdf')), isFalse);
    });
    test('corrupt PDF gives a clear error', () async {
      expect(PdfService.openForEdit(fixture('corrupt.pdf')), throwsAppError(AppErrorCode.corrupt));
    });
    test('fake PDF (wrong magic bytes) is refused', () async {
      expect(PdfService.openForEdit(fixture('fake.pdf')), throwsAppError(AppErrorCode.notPdf));
    });
    test('empty file', () async {
      expect(PdfService.openForEdit(Uint8List(0)), throwsAppError(AppErrorCode.emptyFile));
    });
  });

  test('merge keeps all pages in order', () async {
    final out = await runMerge(
        [input('one_page.pdf'), input('three_pages.pdf'), input('fifty_pages.pdf')], JobContext());
    expect(out.name, 'one_page-merged.pdf');
    expect(out.pageCount, 54);
    expect(await pageCountOf(out.bytes), 54);
    // Page 2 of the result is page 1 of three_pages.pdf.
    final d = await openPdf(out.bytes);
    final text = await d.pages[1].loadText();
    expect(text!.fullText, contains('Page 1'));
    final last = await d.pages[53].loadText();
    expect(last!.fullText, contains('Page 50'));
    await d.dispose();
  });

  test('merge needs two files', () async {
    expect(runMerge([input('one_page.pdf')], JobContext()), throwsAppError(AppErrorCode.nothingSelected));
  });

  group('split', () {
    test('ranges -> zip of PDFs', () async {
      final out = await runSplit(input('fifty_pages.pdf'),
          const SplitOptions(mode: SplitMode.ranges, rangesText: '1-3, 5, 48-50'), JobContext());
      expect(out.name, 'fifty_pages-split.zip');
      final zip = ZipDecoder().decodeBytes(out.bytes);
      expect(zip.files.map((f) => f.name),
          ['fifty_pages-pages-1-3.pdf', 'fifty_pages-page-5.pdf', 'fifty_pages-pages-48-50.pdf']);
      final counts = [for (final f in zip.files) await pageCountOf(f.content)];
      expect(counts, [3, 1, 3]);
    });
    test('every N pages', () async {
      final out = await runSplit(
          input('fifty_pages.pdf'), const SplitOptions(mode: SplitMode.everyN, everyN: 20), JobContext());
      final zip = ZipDecoder().decodeBytes(out.bytes);
      expect([for (final f in zip.files) await pageCountOf(f.content)], [20, 20, 10]);
    });
    test('each page', () async {
      final out = await runSplit(
          input('three_pages.pdf'), const SplitOptions(mode: SplitMode.eachPage), JobContext());
      expect(ZipDecoder().decodeBytes(out.bytes).files.length, 3);
    });
    test('single range -> plain PDF', () async {
      final out = await runSplit(input('fifty_pages.pdf'),
          const SplitOptions(mode: SplitMode.ranges, rangesText: '10-12'), JobContext());
      expect(out.name, endsWith('.pdf'));
      expect(await pageCountOf(out.bytes), 3);
    });
  });

  test('extract pages in chosen order', () async {
    final out = await runExtract(input('fifty_pages.pdf'), [7, 2], JobContext());
    expect(out.pageCount, 2);
    final d = await openPdf(out.bytes);
    expect((await d.pages[0].loadText())!.fullText, contains('Page 7'));
    expect((await d.pages[1].loadText())!.fullText, contains('Page 2'));
    await d.dispose();
  });

  test('organize: reorder, rotate, delete, duplicate, blank', () async {
    final items = <OrganizeItem>[
      const SourcePage(2), // page 3 first
      const SourcePage(0, quarterTurns: 1), // page 1 rotated 90
      const SourcePage(0), // duplicate of page 1
      const BlankPage(612, 792), // Letter
      // page 2 deleted (absent)
    ];
    final out = await runOrganize(input('three_pages.pdf'), items, JobContext());
    expect(out.pageCount, 4);
    final d = await openPdf(out.bytes);
    expect((await d.pages[0].loadText())!.fullText, contains('Page 3'));
    expect(d.pages[1].rotation, PdfPageRotation.clockwise90);
    expect(d.pages[2].rotation, PdfPageRotation.none);
    expect((await d.pages[2].loadText())!.fullText, contains('Page 1'));
    expect(d.pages[3].width, closeTo(612, 0.5));
    expect(d.pages[3].height, closeTo(792, 0.5));
    expect((await d.pages[3].loadText())!.fullText.trim(), isEmpty);
    await d.dispose();
  });

  group('compress', () {
    test('strong rasterises pages and shrinks an image-heavy file', () async {
      final r = await runCompress(input('with_images.pdf'),
          const CompressOptions(level: CompressLevel.strong, strongDpi: 72), JobContext());
      expect(r.keptOriginal, isFalse);
      expect(r.newSize, lessThan(r.originalSize));
      expect(await pageCountOf(r.file!.bytes), 1);
      // ignore: avoid_print
      print('strong: ${r.originalSize} -> ${r.newSize} (${(r.savedFraction * 100).toStringAsFixed(1)}%)');
    });
    test('recommended re-encodes the large JPEG and keeps text pages intact', () async {
      final r = await runCompress(
          input('with_images.pdf'), const CompressOptions(level: CompressLevel.recommended), JobContext());
      // ignore: avoid_print
      print('recommended: ${r.originalSize} -> ${r.newSize}, level ${r.levelUsed}, '
          'images ${r.imagesRecoded}');
      expect(r.levelUsed, CompressLevel.recommended);
      expect(r.imagesRecoded, 1);
      expect(r.newSize, lessThan(r.originalSize ~/ 2));
    });
    test('recommended on a text-only file falls back to light', () async {
      final r = await runCompress(
          input('arabic_text.pdf'), const CompressOptions(level: CompressLevel.recommended), JobContext());
      expect(r.levelUsed, CompressLevel.light);
    });
    test('light keeps text selectable; if not smaller, the original is kept', () async {
      final r = await runCompress(
          input('english_text.pdf'), const CompressOptions(level: CompressLevel.light), JobContext());
      // ignore: avoid_print
      print('light: ${r.originalSize} -> ${r.newSize} kept original: ${r.keptOriginal}');
      if (!r.keptOriginal) {
        final d = await openPdf(r.file!.bytes);
        expect((await d.pages[0].loadText())!.fullText, contains('Satr'));
        await d.dispose();
      } else {
        expect(r.newSize, greaterThanOrEqualTo(r.originalSize));
      }
    });
  });

  group('PDF to images', () {
    test('single page JPG at 150 DPI', () async {
      final out = await runPdfToImages(input('three_pages.pdf'),
          const PdfToImagesOptions(format: ImageFormat.jpg, dpi: 150, singlePage: 2), JobContext());
      expect(out.name, 'three_pages-page-2.jpg');
      final im = img.decodeJpg(out.bytes)!;
      expect(im.width, closeTo(595 * 150 / 72, 2));
    });
    test('all pages PNG -> zip', () async {
      final out = await runPdfToImages(input('three_pages.pdf'),
          const PdfToImagesOptions(format: ImageFormat.png, dpi: 72), JobContext());
      final zip = ZipDecoder().decodeBytes(out.bytes);
      expect(zip.files.length, 3);
      expect(img.decodePng(zip.files.first.content), isNotNull);
    });
  });

  group('images to PDF', () {
    test('respects EXIF orientation (landscape pixels shown as portrait)', () async {
      final out = await runImagesToPdf(
        [input('photo_exif6.jpg')],
        const ImagesToPdfOptions(pageSize: PageSizeOption.fitImage, margin: MarginOption.none),
        JobContext(),
      );
      final d = await openPdf(out.bytes);
      // 400x300 pixels with orientation 6 -> upright 300x400 -> 225x300 pt.
      expect(d.pages[0].width, closeTo(225, 1));
      expect(d.pages[0].height, closeTo(300, 1));
      await d.dispose();
    });
    test('JPG + PNG (alpha) + WebP, A4 with margins', () async {
      final out = await runImagesToPdf(
          [input('photo.jpg'), input('alpha.png'), input('photo.webp')],
          const ImagesToPdfOptions(),
          JobContext());
      expect(out.pageCount, 3);
      final d = await openPdf(out.bytes);
      // Landscape photo -> auto orientation picks landscape A4.
      expect(d.pages[0].width, closeTo(841.9, 1));
      await d.dispose();
    });
  });

  group('text extraction', () {
    test('Arabic text layer comes back in reading order', () async {
      final pages = await runTextExtract(input('arabic_text.pdf'), JobContext());
      final t = pages.first.text;
      // ignore: avoid_print
      print(t);
      expect(t, contains('مستند عربي'));
      expect(t, contains('سطر تطبيق عربي لمعالجة ملفات على جهازك'));
      expect(t, contains('الملفات لا تغادر الجهاز أبدا'));
      expect(t, contains('يعمل بدون إنترنت بعد أول زيارة'));
    });
    test('mixed Arabic + English', () async {
      final t = (await runTextExtract(input('mixed_text.pdf'), JobContext())).first.text;
      // ignore: avoid_print
      print(t);
      expect(t, contains('Satr keeps your files on your device'));
      expect(t, contains('الملفات لا تغادر الجهاز'));
      expect(t, contains('رقم الطلب 2024 في ملف PDF'));
    });
    test('English text is unchanged', () async {
      final t = (await runTextExtract(input('english_text.pdf'), JobContext())).first.text;
      expect(t, contains('Merge, split and compress documents'));
      expect(t, contains('Satr keeps your files on your device.'));
    });
    test('scanned PDF has no text layer', () async {
      final pages = await runTextExtract(input('scanned.pdf'), JobContext());
      expect(pages.every((p) => p.isEmpty), isTrue);
    });
  });

  group('file info', () {
    test('reads pages, sizes, version and metadata', () async {
      final info = await readPdfInfo(fixture('three_pages.pdf'));
      expect(info.pageCount, 3);
      expect(info.pageSizes.keys.map((k) => paperName(k.w, k.h)), ['A4']);
      expect(info.version, isNotNull);
      expect(info.meta['Title'], 'Satr fixture');
      expect(info.encrypted, isFalse);
    });
    test('encrypted file is reported as such', () async {
      final info = await readPdfInfo(fixture('encrypted.pdf'));
      expect(info.encrypted, isTrue);
    });
    test('clear metadata removes the Info entries', () async {
      final out = await runClearMetadata(input('three_pages.pdf'), JobContext());
      final info = await readPdfInfo(out.bytes);
      expect(info.pageCount, 3);
      expect(info.meta.containsKey('Title'), isFalse);
      // PDFium writes its own Creator/Producer ("PDFium") and a fresh
      // creation date; the original values must be gone.
      expect(info.meta['Creator'], isNot('Chromium'));
      expect(info.meta['Producer'] ?? '', isNot(contains('Skia')));
    });
  });

  test('cancellation stops a job and produces nothing', () async {
    final ctx = JobContext();
    ctx.cancel();
    expect(runMerge([input('one_page.pdf'), input('three_pages.pdf')], ctx),
        throwsA(isA<JobCancelledException>()));
  });
}
