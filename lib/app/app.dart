import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

import '../config/app_config.dart';
import '../design/theme.dart';
import '../l10n/gen/app_localizations.dart';
import 'services.dart';
import 'shell.dart';

class SatrApp extends StatelessWidget {
  const SatrApp({super.key, required this.services});
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: services.settings,
        builder: (context, _) {
          final lang = services.settings.languageCode;
          return MaterialApp(
            title: AppConfig.appName(lang),
            debugShowCheckedModeBanner: false,
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: services.settings.themeMode,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
