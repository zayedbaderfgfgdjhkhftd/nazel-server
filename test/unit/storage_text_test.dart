import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satr_pdf/core/docx/docx_writer.dart';
import 'package:satr_pdf/core/files/output_file.dart';
import 'package:satr_pdf/core/jobs/job.dart';
import 'package:satr_pdf/core/ocr/hocr.dart';
import 'package:satr_pdf/core/ocr/ocr_engine.dart';
import 'package:satr_pdf/core/storage/file_store.dart';
import 'package:satr_pdf/features/ocr/ocr_tool.dart';

import '../helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('My files store', () {
    late Directory dir;
    late FileStore store;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('satr_store');
      store = await FileStore.open(dir);
    });
    tearDown(() => dir.delete(recursive: true));

    test('add, rename, favourite, search, sort', () async {
      final a = await store.addBytes('عقد الإيجار.pdf', Uint8List.fromList([1, 2, 3]), tool: 'merge');
      await store.addBytes('photo.jpg', Uint8List(10), tool: 'import');
      await store.addBytes('notes.txt', Uint8List(5), tool: 'ocr');
      expect(store.active.length, 3);
      expect(store.query(search: 'الايجار').single.id, a.id);
      expect(store.query(kind: FileKind.image).single.name, 'photo.jpg');
      expect(store.query(sort: FileSort.size).first.name, 'photo.jpg');
      expect(store.query(sort: FileSort.name, descending: false).first.name, 'notes.txt');

      await store.rename(a.id, 'عقد جديد');
      expect(store.byId(a.id)!.name, 'عقد جديد.pdf');
      await store.setFavorite(a.id, true);
      expect(store.query(favoritesOnly: true).single.id, a.id);

      // Persisted to disk and reloaded.
      final reopened = await FileStore.open(dir);
      expect(reopened.byId(a.id)!.name, 'عقد جديد.pdf');
      expect(reopened.byId(a.id)!.favorite, isTrue);
      expect(await reopened.readBytes(reopened.byId(a.id)!), [1, 2, 3]);
    });

    test('duplicate names get a suffix', () async {
      await store.addBytes('a.pdf', Uint8List(1), tool: 'x');
      final b = await store.addBytes('a.pdf', Uint8List(1), tool: 'x');
      expect(b.name, 'a (2).pdf');
    });

    test('trash, restore, delete forever, 30-day purge', () async {
      final a = await store.addBytes('a.pdf', Uint8List(4), tool: 'x');
      final b = await store.addBytes('b.pdf', Uint8List(4), tool: 'x');
      await store.moveToTrash([a.id], now: DateTime.now().subtract(const Duration(days: 31)));
      await store.moveToTrash([b.id]);
      expect(store.active, isEmpty);
      expect(store.trash.length, 2);
      await store.restore([b.id]);
      expect(store.active.single.id, b.id);
      expect(await store.purgeExpired(), 1);
      expect(store.byId(a.id), isNull);
      expect(File('${dir.path}/${a.relPath}').existsSync(), isFalse);
      await store.deleteForever([b.id]);
      expect(store.active, isEmpty);
    });

    test('clear all', () async {
      await store.addBytes('a.pdf', Uint8List(4), tool: 'x');
      await store.clearAll();
      expect(store.active, isEmpty);
      expect(store.usedBytes, 0);
    });
  });

  group('hOCR', () {
    test('parses words, lines, paragraphs and confidence', () {
      final r = parseHocr(File('test/fixtures/sample_ara.hocr').readAsStringSync());
      expect(r.paragraphs, isNotEmpty);
      expect(r.text.split('\n').first, 'سطر تطبيق عربي لمعالجة ملفات على جهازك');
      expect(r.words.length, greaterThanOrEqualTo(20));
      expect(r.meanConfidence, greaterThan(50));
    });
    test('low-confidence ranges point at the right words', () {
      const hocr = """
<p class='ocr_par'><span class='ocr_line' title='bbox 0 0 1 1'>
<span class='ocrx_word' title='bbox 0 0 1 1; x_wconf 95'>مرحبا</span>
<span class='ocrx_word' title='bbox 0 0 1 1; x_wconf 31'>بكم</span>
</span><span class='ocr_line' title='bbox 0 0 1 1'>
<span class='ocrx_word' title='bbox 0 0 1 1; x_wconf 20'>A&amp;B</span>
</span></p>""";
      final r = parseHocr(hocr);
      expect(r.text, 'مرحبا بكم\nA&B');
      final ranges = r.lowConfidenceRanges(60);
      expect([for (final (s, e) in ranges) r.text.substring(s, e)], ['بكم', 'A&B']);
      expect(r.lowConfidenceCount(60), 2);
    });
    test('plain-text engine output is accepted without confidences', () {
      final r = parseOcrOutput('سطر واحد\nسطر ثان\n\nفقرة');
      expect(r.text, 'سطر واحد\nسطر ثان\n\nفقرة');
      expect(r.hasConfidence, isFalse);
      expect(r.lowConfidenceCount(60), 0);
      expect(r.lowConfidenceRanges(60), isEmpty);
    });
  });

  test('DOCX: valid package with right-to-left Arabic paragraphs', () {
    final bytes = buildDocx('مرحبا بكم\nسطر ثاني\n\nEnglish paragraph & more', title: 'test');
    final zip = ZipDecoder().decodeBytes(bytes);
    final names = zip.files.map((f) => f.name).toSet();
    expect(names, containsAll(['[Content_Types].xml', '_rels/.rels', 'word/document.xml']));
    final doc = utf8.decode(zip.findFile('word/document.xml')!.content);
    final paras = RegExp(r'<w:p>.*?</w:p>').allMatches(doc).map((m) => m.group(0)!).toList();
    expect(paras.length, 2);
    expect(paras[0], contains('<w:bidi/>'));
    expect(paras[0], contains('<w:rtl/>'));
    expect(paras[0], contains('<w:br/>'));
    expect(paras[1], isNot(contains('<w:bidi/>')));
    expect(paras[1], contains('English paragraph &amp; more'));
  });

  group('OCR pipeline with the Tesseract engine', () {
    final cli = Process.runSync('which', ['tesseract']).exitCode == 0;
    test('reads the Arabic test image (accuracy is recorded, not faked)', () async {
      final expected = (jsonDecode(File('test/fixtures/ocr_expected.json').readAsStringSync())
          as Map)['ocr_arabic_naskh.png'] as Map;
      final want = (expected['lines'] as List).join(' ').split(' ');
      final tmp = await Directory.systemTemp.createTemp('ocr');
      final result = await runOcr(
        fixture('ocr_arabic_naskh.png'),
        const OcrOptions(language: OcrLanguage.arabic),
        JobContext(),
        backend: _CliBackend(),
        tempDir: tmp,
      );
      final got = result.words.map((w) => w.text).toSet();
      final found = want.where(got.contains).length;
      // ignore: avoid_print
      print('OCR Arabic (naskh): $found/${want.length} words, '
          'mean confidence ${result.meanConfidence.toStringAsFixed(1)}');
      expect(found / want.length, greaterThanOrEqualTo(0.8));
    }, skip: cli ? false : 'tesseract CLI not installed');
  });
}

/// Same engine (Tesseract) and same bundled model files as the app, driven
/// through the CLI because the Flutter plugin has no host-test channel.
class _CliBackend implements OcrBackend {
  @override
  Future<void> ensureLanguages(List<String> languages) async {}

  @override
  Future<String> recognizeHocr(String imagePath, String language) async {
    final r = await Process.run('tesseract', [
      imagePath, 'stdout', '--tessdata-dir', 'assets/tessdata', '-l', language, //
      '-c', 'tessedit_create_hocr=1',
    ]);
    if (r.exitCode != 0) throw Exception(r.stderr);
    return r.stdout as String;
  }
}

// Keeps OutputFile referenced for kind mapping tests.
// ignore: unused_element
final _k = kindFromName('x.docx');
