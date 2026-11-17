import 'package:flutter_test/flutter_test.dart';
import 'package:satr_pdf/core/arabic/normalize.dart';
import 'package:satr_pdf/core/arabic/presentation_forms.dart';
import 'package:satr_pdf/core/files/file_type.dart';
import 'package:satr_pdf/core/files/naming.dart';
import 'package:satr_pdf/core/pdf/page_ranges.dart';
import 'package:satr_pdf/core/pdf/pdfium_native.dart';

import '../helpers.dart';

void main() {
  group('file type by magic bytes', () {
    test('detects fixtures', () {
      expect(detectFileType(fixture('one_page.pdf')), DetectedType.pdf);
      expect(detectFileType(fixture('photo.jpg')), DetectedType.jpeg);
      expect(detectFileType(fixture('alpha.png')), DetectedType.png);
      expect(detectFileType(fixture('photo.webp')), DetectedType.webp);
      expect(detectFileType(fixture('photo.heic')), DetectedType.heic);
    });
    test('extension does not matter', () {
      expect(detectFileType(fixture('fake.pdf')), DetectedType.unknown);
    });
    test('complete-PDF structure check', () {
      expect(looksLikeCompletePdf(fixture('one_page.pdf')), isTrue);
      expect(looksLikeCompletePdf(fixture('corrupt.pdf')), isFalse);
    });
  });

  group('file naming', () {
    test('tool suffix', () {
      expect(outputFileName('contract.pdf', 'compressed', 'pdf'), 'contract-compressed.pdf');
      expect(outputFileName('عقد الإيجار.pdf', 'merged', 'pdf'), 'عقد الإيجار-merged.pdf');
      expect(outputFileName('a/b:c?.pdf', 'x', 'zip'), 'b_c_-x.zip');
      expect(outputFileName('.pdf', 'x', 'pdf'), 'satr-x.pdf');
    });
    test('rename keeps extension', () {
      expect(renamedFileName('old.pdf', 'جديد'), 'جديد.pdf');
      expect(renamedFileName('old.pdf', 'new.txt'), 'new.pdf');
    });
  });

  group('page ranges', () {
    test('parses mixed syntax and digits', () {
      expect(parsePageRanges('1-3, 5, 8-10', 10),
          const [PageRange(1, 3), PageRange(5, 5), PageRange(8, 10)]);
      expect(parsePageRanges('١-٣، ٥', 10), const [PageRange(1, 3), PageRange(5, 5)]);
      expect(parsePageRanges('2–4', 10), const [PageRange(2, 4)]);
    });
    test('validates', () {
      expect(() => parsePageRanges('', 5), throwsA(isA<RangeParseException>()));
      expect(() => parsePageRanges('1-9', 5),
          throwsA(predicate((e) => e is RangeParseException && e.error == RangeError.outOfBounds)));
      expect(() => parsePageRanges('4-2', 5),
          throwsA(predicate((e) => e is RangeParseException && e.error == RangeError.reversed)));
      expect(() => parsePageRanges('1,,a', 5),
          throwsA(predicate((e) => e is RangeParseException && e.error == RangeError.syntax)));
    });
    test('chunks and flatten', () {
      expect(chunkPages(5, 2), const [PageRange(1, 2), PageRange(3, 4), PageRange(5, 5)]);
      expect(flattenRanges(const [PageRange(3, 4), PageRange(1, 3)]), [1, 2, 3, 4]);
    });
  });

  group('Arabic search normalisation', () {
    test('alef forms, ta marbuta, alef maqsura, tashkeel', () {
      expect(normalizeForSearch('أحمد'), normalizeForSearch('احمد'));
      expect(normalizeForSearch('إسلام'), normalizeForSearch('اسلام'));
      expect(normalizeForSearch('آمال'), normalizeForSearch('امال'));
      expect(normalizeForSearch('مدرسة'), normalizeForSearch('مدرسه'));
      expect(normalizeForSearch('مستشفى'), normalizeForSearch('مستشفي'));
      expect(normalizeForSearch('مُحَمَّد'), 'محمد');
      expect(normalizeForSearch('كتـــاب'), 'كتاب');
      expect(normalizeForSearch('ملف ٢٠٢٤'), 'ملف 2024');
    });
    test('search matches', () {
      expect(searchMatches('عقد الإيجار.pdf', 'الايجار'), isTrue);
      expect(searchMatches('Report.PDF', 'report'), isTrue);
      expect(searchMatches('فاتورة', 'فاتوره'), isTrue);
      expect(searchMatches('فاتورة', 'عقد'), isFalse);
    });
    test('digits and direction', () {
      expect(toEasternArabicDigits('12 / 30'), '١٢ / ٣٠');
      expect(isRtlText('مرحبا hello'), isTrue);
      expect(isRtlText('hello مرحبا'), isFalse);
      expect(isRtlText('123'), isFalse);
    });
    test('presentation forms', () {
      // "سطر" written with presentation-form glyph codes.
      expect(normalizePresentationForms('\u{FEB3}\u{FEE4}\u{FEAE}'), 'سمر');
      expect(normalizePresentationForms('\u{FEFB}'), 'لا');
      expect(normalizePresentationForms('plain'), 'plain');
    });
  });

  group('PDF geometry', () {
    test('visual to user space for all rotations', () {
      // 600x800 page.
      expect(visualToUser(0, 0, rotation: 0, left: 0, top: 800, right: 600, bottom: 0), (0.0, 800.0));
      expect(visualToUser(0, 0, rotation: 1, left: 0, top: 800, right: 600, bottom: 0), (0.0, 0.0));
      expect(visualToUser(800, 0, rotation: 1, left: 0, top: 800, right: 600, bottom: 0), (0.0, 800.0));
      expect(visualToUser(0, 0, rotation: 2, left: 0, top: 800, right: 600, bottom: 0), (600.0, 0.0));
      expect(visualToUser(0, 0, rotation: 3, left: 0, top: 800, right: 600, bottom: 0), (600.0, 800.0));
    });
    test('stamp matrix unrotated', () {
      final m = stampMatrix(
          stampWidth: 100, stampHeight: 50, x: 10, y: 20, width: 200, height: 100,
          rotation: 0, left: 0, top: 800, right: 600, bottom: 0);
      expect(m, [2.0, 0.0, 0.0, 2.0, 10.0, 680.0]);
    });
    test('PDF dates', () {
      expect(parsePdfDate("D:20240131120000Z")!.toUtc(), DateTime.utc(2024, 1, 31, 12));
      expect(parsePdfDate("D:20240131150000+03'00'")!.toUtc(), DateTime.utc(2024, 1, 31, 12));
      expect(parsePdfDate('garbage'), isNull);
    });
  });
}
