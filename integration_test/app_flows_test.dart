// End-to-end flows on the real app (real PDFium, real Tesseract), driven
// through the UI. Run on Linux desktop (CI/dev machine):
//   xvfb-run flutter test integration_test -d linux
// Store screenshots are written to build/screenshots/.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:satr_pdf/app/app.dart';
import 'package:satr_pdf/app/services.dart';
import 'package:satr_pdf/core/files/output_file.dart';
import 'package:satr_pdf/core/platform/platform_bridge.dart';
import 'package:satr_pdf/core/storage/file_store.dart';
import 'package:satr_pdf/core/storage/settings_store.dart';
import 'package:satr_pdf/features/tools/tools_screen.dart';

final _boundary = GlobalKey();

Future<AppServices> _boot(WidgetTester tester, {String lang = 'ar', List<String> seed = const []}) async {
  late AppServices s;
  await tester.runAsync(() async {
    await pdfrxFlutterInitialize();
    final dir = await Directory.systemTemp.createTemp('satr_e2e');
    final files = await FileStore.open(Directory('${dir.path}/library'));
    for (final name in seed) {
      await files.addBytes(name, File('test/fixtures/$name').readAsBytesSync(), tool: 'import');
    }
    final settings = await SettingsStore.open(dir);
    await settings.setLanguage(lang);
    s = AppServices(files: files, settings: settings, platform: PlatformBridge(), tempDir: dir);
  });
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  await tester.pumpWidget(RepaintBoundary(key: _boundary, child: SatrApp(services: s)));
  await tester.pumpAndSettle();
  return s;
}

/// Pumps until [finder] matches (real async work: PDFium, isolates, OCR).
Future<void> pumpUntil(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 90)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().toList();
  throw TestFailure('Timed out waiting for $finder. Visible: $texts');
}

Future<void> screenshot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final f = File('build/screenshots/$name.png');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(data!.buffer.asUint8List());
  });
}

Future<void> openToolsTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> openTool(WidgetTester tester, String name) async {
  // Only look inside the Tools tab (the hidden Home tab has shortcuts too).
  final f = find.descendant(of: find.byType(ToolsScreen), matching: find.text(name)).first;
  await tester.scrollUntilVisible(f, 200,
      scrollable: find.descendant(of: find.byType(ToolsScreen), matching: find.byType(Scrollable)).first);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Picks files through the in-app "From My files" sheet.
Future<void> pickFromLibrary(WidgetTester tester, String prompt, List<String> names,
    {String fromMyFiles = 'من ملفاتي', String done = 'تم'}) async {
  await tester.tap(find.text(prompt));
  await tester.pumpAndSettle();
  await tester.tap(find.text(fromMyFiles));
  await tester.pumpAndSettle();
  for (final n in names) {
    await tester.tap(find.text(n).last);
    await tester.pumpAndSettle();
  }
  if (names.length > 1) {
    await tester.tap(find.text(done).last);
  }
  await pumpUntil(tester, find.byType(Scaffold));
  await tester.pumpAndSettle();
}

Future<int> pages(Uint8List bytes) async {
  final d = await PdfDocument.openData(bytes, sourceName: 'e2e-${DateTime.now().microsecondsSinceEpoch}');
  final n = d.pages.length;
  await d.dispose();
  return n;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home and tools screens (Arabic) + screenshots', (tester) async {
    await _boot(tester, seed: ['three_pages.pdf', 'photo.jpg']);
    expect(find.text('ملفاتك تبقى على جهازك'), findsOneWidget);
    await screenshot(tester, 'ar_01_home');
    await openToolsTab(tester, 'الأدوات');
    await screenshot(tester, 'ar_02_tools');
    await tester.tap(find.text('ملفاتي').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('الكل'));
    await tester.pumpAndSettle();
    await screenshot(tester, 'ar_05_files');
  });

  testWidgets('merge flow (Arabic)', (tester) async {
    final s = await _boot(tester, seed: ['one_page.pdf', 'three_pages.pdf']);
    await openToolsTab(tester, 'الأدوات');
    await openTool(tester, 'دمج ملفات PDF');
    await pickFromLibrary(tester, 'اختر ملفات PDF', ['one_page.pdf', 'three_pages.pdf']);
    await tester.tap(find.text('ادمج الملفات'));
    await pumpUntil(tester, find.text('حُفظ في ملفاتي'));
    await screenshot(tester, 'ar_03_merge_result');
    final merged = s.files.active.firstWhere((f) => f.tool == 'merge');
    expect(merged.name, 'one_page-merged.pdf');
    expect(await tester.runAsync(() async => pages(await s.files.readBytes(merged))), 4);
  });

  testWidgets('compress flow (Arabic): recommended shrinks the image PDF', (tester) async {
    final s = await _boot(tester, seed: ['with_images.pdf']);
    await openToolsTab(tester, 'الأدوات');
    await openTool(tester, 'ضغط ملف PDF');
    await pickFromLibrary(tester, 'اختر ملف PDF', ['with_images.pdf']);
    await screenshot(tester, 'ar_04_compress_options');
    await tester.tap(find.text('اضغط الملف'));
    await pumpUntil(tester, find.text('حُفظ في ملفاتي'));
    final out = s.files.active.firstWhere((f) => f.tool == 'compress');
    final original = s.files.active.firstWhere((f) => f.name == 'with_images.pdf');
    expect(out.size, lessThan(original.size));
  });

  testWidgets('images to PDF flow (English)', (tester) async {
    final s = await _boot(tester, lang: 'en', seed: ['photo.jpg', 'alpha.png']);
    await openToolsTab(tester, 'Tools');
    await openTool(tester, 'Images to PDF');
    await pickFromLibrary(tester, 'Choose images', ['photo.jpg', 'alpha.png'],
        fromMyFiles: 'From My files', done: 'Done');
    await tester.tap(find.text('Create PDF'));
    await pumpUntil(tester, find.text('Saved to My files'));
    final out = s.files.active.firstWhere((f) => f.tool == 'imagesToPdf');
    expect(out.kind, FileKind.pdf);
    expect(await tester.runAsync(() async => pages(await s.files.readBytes(out))), 2);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await screenshot(tester, 'en_02_tools');
  });

  testWidgets('OCR flow (Arabic image)', (tester) async {
    await _boot(tester, seed: ['ocr_arabic_naskh.png']);
    await openToolsTab(tester, 'الأدوات');
    await openTool(tester, 'النص من الصورة (OCR)');
    await pickFromLibrary(tester, 'اختر صورة أو ملف PDF', ['ocr_arabic_naskh.png']);
    await tester.tap(find.text('اقرأ النص'));
    await pumpUntil(tester, find.byType(TextField), timeout: const Duration(seconds: 180));
    final field = tester.widget<TextField>(find.byType(TextField).last);
    final text = field.controller!.text;
    expect(text, contains('سطر'));
    expect(text, contains('الملفات'));
    await screenshot(tester, 'ar_06_ocr_result');
  });

  testWidgets('My files: rename, trash, restore (English)', (tester) async {
    final s = await _boot(tester, lang: 'en', seed: ['one_page.pdf']);
    await tester.tap(find.text('My files').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'contract');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await pumpUntil(tester, find.text('contract.pdf'));
    await tester.tap(find.byTooltip('More options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to trash'));
    await tester.pumpAndSettle();
    expect(s.files.active, isEmpty);
    await tester.tap(find.byTooltip('Trash'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Restore'));
    await tester.pumpAndSettle();
    expect(s.files.active.single.name, 'contract.pdf');
  });

  testWidgets('home (English) screenshot', (tester) async {
    await _boot(tester, lang: 'en', seed: ['three_pages.pdf']);
    await screenshot(tester, 'en_01_home');
  });
}
