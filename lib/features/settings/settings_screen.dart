import 'package:material_ui/material_ui.dart';

import '../../app/services.dart';
import '../../components/common.dart';
import '../../components/l10n_ext.dart';
import '../../config/app_config.dart';
import '../../core/ocr/ocr_engine.dart';
import '../../design/icons.dart';
import '../../design/tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, int?> _ocr = const {};

  @override
  void initState() {
    super.initState();
    _refreshOcr();
  }

  Future<void> _refreshOcr() async {
    try {
      final s = await TesseractBackend.preparedSizes();
      if (mounted) setState(() => _ocr = s);
    } catch (_) {}
  }

  Future<void> _clearAll() async {
    final l = context.l10n;
    final services = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(l.clearAllConfirm(c.appName)),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.of(c).pop(true), child: Text(l.clearAllData)),
        ],
      ),
    );
    if (ok != true) return;
    await services.files.clearAll();
    for (final lang in kBundledOcrLanguages.keys) {
      await TesseractBackend.removePrepared(lang);
    }
    await services.settings.reset();
    await _refreshOcr();
    if (mounted) showMessage(context, l.dataCleared);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final services = AppScope.of(context);
    final settings = services.settings;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListenableBuilder(
        listenable: Listenable.merge([settings, services.files]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xl),
          children: [
            MaxWidth(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ChoiceRow<String>(
                          label: l.language,
                          value: settings.languageCode,
                          options: {'ar': l.langArabic, 'en': l.langEnglish},
                          onChanged: settings.setLanguage,
                        ),
                        const SizedBox(height: Space.l),
                        ChoiceRow<ThemeMode>(
                          label: l.theme,
                          value: settings.themeMode,
                          options: {
                            ThemeMode.system: l.themeSystem,
                            ThemeMode.light: l.themeLight,
                            ThemeMode.dark: l.themeDark,
                          },
                          onChanged: settings.setThemeMode,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.l),
                  SectionCard(
                    title: l.ocrData,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l.ocrDataDesc, style: Theme.of(context).textTheme.bodySmall),
                        for (final e in kBundledOcrLanguages.entries)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(e.key == 'ara' ? l.ocrLangAr : l.ocrLangEn),
                            subtitle: Text(_ocr[e.key] != null
                                ? l.ocrReady(formatBytes(context, _ocr[e.key]!))
                                : l.ocrNotReady(formatBytes(context, e.value))),
                            trailing: _ocr[e.key] != null
                                ? TextButton(
                                    onPressed: () async {
                                      await TesseractBackend.removePrepared(e.key);
                                      await _refreshOcr();
                                    },
                                    child: Text(l.remove),
                                  )
                                : TextButton(
                                    onPressed: () async {
                                      await TesseractBackend.prepare(e.key);
                                      await _refreshOcr();
                                    },
                                    child: Text(l.prepare),
                                  ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.l),
                  SectionCard(
                    title: l.storage,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l.storageUsed(context.appName, formatBytes(context, services.files.usedBytes))),
                        const SizedBox(height: Space.m),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SatrColors.of(context).danger,
                            side: BorderSide(color: SatrColors.of(context).danger),
                          ),
                          onPressed: _clearAll,
                          child: Text(l.clearAllData),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.l),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const SatrIcon('privacy'),
                          title: Text(l.privacyPolicy),
                          trailing: const SatrIcon('chevronEnd', size: 20),
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute<void>(builder: (_) => const PrivacyScreen())),
                        ),
                        ListTile(
                          leading: const SatrIcon('licenses'),
                          title: Text(l.licenses),
                          trailing: const SatrIcon('chevronEnd', size: 20),
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute<void>(builder: (_) => const LicensesScreen())),
                        ),
                        ListTile(
                          leading: const SatrIcon('about'),
                          title: Text(l.about),
                          subtitle: Text(l.versionLabel(AppConfig.version)),
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (c) => AlertDialog(
                              icon: Image.asset('assets/brand/icon-192.png', width: 64, height: 64),
                              title: Text(c.appName),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(l.aboutBody(c.appName), textAlign: TextAlign.center),
                                  const SizedBox(height: Space.s),
                                  Text(l.versionLabel(AppConfig.version), style: Theme.of(c).textTheme.bodySmall),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(c).pop(), child: Text(l.close)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget section(String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HighlightTitle(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Space.s),
              Text(body, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        );
    return Scaffold(
      appBar: AppBar(title: Text(l.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Space.l),
        children: [
          MaxWidth(
            maxWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.privacyIntro(context.appName), style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: Space.xl),
                section(l.privacyStoredTitle, l.privacyStoredBody),
                section(l.privacyNeverTitle, l.privacyNeverBody),
                section(l.privacyDeleteTitle, l.privacyDeleteBody),
                section(l.privacyChangesTitle, l.privacyChangesBody),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Main third-party components and their licences (full texts via
/// Flutter's license page, which includes every Dart package).
const _kComponents = <(String, String, String)>[
  ('Flutter', 'BSD-3-Clause', 'UI framework'),
  ('PDFium', 'BSD-3-Clause / Apache-2.0', 'PDF engine (via pdfrx)'),
  ('pdfrx / pdfium_dart', 'MIT', 'PDF viewer and bindings'),
  ('pdf (dart_pdf)', 'Apache-2.0', 'PDF generation'),
  ('Tesseract OCR + tessdata_fast', 'Apache-2.0', 'Text recognition'),
  ('Tesseract4Android', 'Apache-2.0', 'Tesseract on Android'),
  ('tesseract_ocr (plugin)', 'BSD-3-Clause', 'OCR bridge'),
  ('image', 'MIT', 'Image processing'),
  ('archive', 'MIT', 'ZIP and DOCX files'),
  ('file_picker', 'MIT', 'Choosing files'),
  ('share_plus, path_provider', 'BSD-3-Clause', 'Sharing and storage paths'),
  ('flutter_svg', 'MIT', 'Icons rendering'),
  ('reorderable_grid', 'MIT', 'Drag to reorder pages'),
  ('intl', 'BSD-3-Clause', 'Dates and numbers'),
  ('Lucide icons', 'ISC', 'Icon set'),
  ('Readex Pro', 'SIL OFL 1.1', 'Font'),
];

class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.licenses)),
      body: ListView(
        padding: const EdgeInsets.all(Space.l),
        children: [
          MaxWidth(
            maxWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.licensesIntro(context.appName), style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: Space.l),
                Card(
                  child: Column(
                    children: [
                      for (final (name, license, use) in _kComponents)
                        ListTile(
                          title: Text(name, textDirection: TextDirection.ltr),
                          subtitle: Text('$license · $use', textDirection: TextDirection.ltr),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.l),
                OutlinedButton(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: context.appName,
                    applicationVersion: AppConfig.version,
                    applicationIcon: Padding(
                      padding: const EdgeInsets.all(Space.s),
                      child: Image.asset('assets/brand/icon-192.png', width: 48, height: 48),
                    ),
                  ),
                  child: Text(l.licensesAll),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
