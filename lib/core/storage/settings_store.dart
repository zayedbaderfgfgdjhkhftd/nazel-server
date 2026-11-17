import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:path/path.dart' as p;

/// User preferences, stored as a small JSON file in app storage.
class SettingsStore extends ChangeNotifier {
  SettingsStore._(this._file);

  final File _file;

  /// 'ar' (default) or 'en'.
  String _languageCode = 'ar';
  ThemeMode _themeMode = ThemeMode.system;

  String get languageCode => _languageCode;
  ThemeMode get themeMode => _themeMode;

  static Future<SettingsStore> open(Directory root) async {
    final s = SettingsStore._(File(p.join(root.path, 'settings.json')));
    if (await s._file.exists()) {
      try {
        final j = jsonDecode(await s._file.readAsString()) as Map<String, Object?>;
        final lang = j['language'];
        if (lang == 'ar' || lang == 'en') s._languageCode = lang! as String;
        s._themeMode = switch (j['theme']) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
      } catch (_) {}
    }
    return s;
  }

  Future<void> setLanguage(String code) async {
    if (code != 'ar' && code != 'en') return;
    _languageCode = code;
    await _persist();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _persist();
  }

  Future<void> reset() async {
    _languageCode = 'ar';
    _themeMode = ThemeMode.system;
    if (await _file.exists()) await _file.delete();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(jsonEncode({
      'language': _languageCode,
      'theme': switch (_themeMode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    }));
    notifyListeners();
  }
}
