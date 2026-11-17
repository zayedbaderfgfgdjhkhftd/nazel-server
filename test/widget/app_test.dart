import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:satr_pdf/app/app.dart';
import 'package:satr_pdf/app/services.dart';
import 'package:satr_pdf/core/platform/platform_bridge.dart';
import 'package:satr_pdf/core/storage/file_store.dart';
import 'package:satr_pdf/core/storage/settings_store.dart';
import 'package:satr_pdf/features/tools/tools_screen.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:satr_pdf/components/tool_scaffold.dart';
import 'package:satr_pdf/features/tools/tool_registry.dart';
import 'package:satr_pdf/l10n/gen/app_localizations.dart';

Future<AppServices> _services(WidgetTester tester) async {
  late AppServices s;
  await tester.runAsync(() async {
    final dir = await Directory.systemTemp.createTemp('satr_widget');
    s = AppServices(
      files: await FileStore.open(Directory('${dir.path}/library')),
      settings: await SettingsStore.open(dir),
      platform: PlatformBridge(),
      tempDir: dir,
    );
  });
  return s;
}

void main() {
  testWidgets('starts in Arabic, right-to-left, with the 4 tabs', (tester) async {
    final s = await _services(tester);
    await tester.pumpWidget(SatrApp(services: s));
    await tester.pumpAndSettle();
    expect(find.text('الرئيسية'), findsWidgets);
    expect(find.text('الأدوات'), findsWidgets);
    expect(find.text('ملفاتي'), findsWidgets);
    expect(find.text('الإعدادات'), findsWidgets);
    expect(find.text('ملفاتك تبقى على جهازك'), findsOneWidget);
    final dir = tester.widget<Directionality>(find.byType(Directionality).first);
    expect(dir.textDirection, TextDirection.rtl);
  });

  testWidgets('tools tab lists every tool group', (tester) async {
    final s = await _services(tester);
    await tester.pumpWidget(SatrApp(services: s));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الأدوات').last);
    await tester.pumpAndSettle();
    expect(find.byType(ToolsScreen), findsOneWidget);
    for (final g in ['تنظيم', 'تحويل', 'تعديل']) {
      expect(find.text(g), findsOneWidget);
    }
    expect(find.text('دمج ملفات PDF'), findsWidgets);
  });

  testWidgets('switching to English flips to left-to-right', (tester) async {
    final s = await _services(tester);
    await tester.pumpWidget(SatrApp(services: s));
    await tester.pumpAndSettle();
    await tester.runAsync(() => s.settings.setLanguage('en'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Your files stay on your device'), findsOneWidget);
    final dir = tester.widget<Directionality>(find.byType(Directionality).first);
    expect(dir.textDirection, TextDirection.ltr);
  });

  testWidgets('every tool screen opens and shows its file picker (phone size)', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final s = await _services(tester);
    for (final id in ToolId.values) {
      await tester.pumpWidget(AppScope(
        services: s,
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: buildToolScreen(id, const []),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(PickPrompt), findsOneWidget, reason: id.name);
      // The pick box must be on screen, not pushed off by the bottom action.
      final box = tester.getRect(find.byType(PickPrompt));
      expect(box.top, lessThan(700), reason: id.name);
      expect(box.height, greaterThan(80), reason: id.name);
    }
  });

  testWidgets('My files shows an empty state with an action', (tester) async {
    final s = await _services(tester);
    await tester.pumpWidget(SatrApp(services: s));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ملفاتي').last);
    await tester.pumpAndSettle();
    expect(find.text('لا توجد ملفات بعد. أنشئ ملفًا بإحدى الأدوات أو استورد ملفًا.'), findsOneWidget);
  });
}
