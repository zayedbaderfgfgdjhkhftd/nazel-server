import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) => arb.keys.where((k) => !k.startsWith('@')).toSet();

Set<String> _placeholders(String s) =>
    RegExp(r'\{(\w+)[,}]').allMatches(s).map((m) => m.group(1)!).toSet();

void main() {
  test('every key exists in both Arabic and English', () {
    final en = _keys(_arb('en'));
    final ar = _keys(_arb('ar'));
    expect(en.difference(ar), isEmpty, reason: 'missing in app_ar.arb');
    expect(ar.difference(en), isEmpty, reason: 'missing in app_en.arb');
  });

  test('placeholders match between languages', () {
    final en = _arb('en');
    final ar = _arb('ar');
    for (final k in _keys(en)) {
      expect(_placeholders(ar[k] as String), _placeholders(en[k] as String), reason: k);
    }
  });

  test('no empty strings', () {
    for (final lang in ['en', 'ar']) {
      final arb = _arb(lang);
      for (final k in _keys(arb)) {
        expect((arb[k] as String).trim(), isNotEmpty, reason: '$lang:$k');
      }
    }
  });

  test('no hard-coded user-facing text in widgets', () {
    // Literal words inside Text(...) / label: / tooltip: are not allowed;
    // format names like JPG/PNG are fine.
    const allowed = {'JPG', 'PNG', '1 / N'};
    final pattern = RegExp(r"""(?:Text\(|label:\s*|tooltip:\s*|hintText:\s*|title:\s*)'([^'$]*)'""");
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.contains('l10n/gen') || f.path.endsWith('.g.dart')) continue;
      final src = f.readAsStringSync();
      for (final m in pattern.allMatches(src)) {
        final s = m.group(1)!;
        if (allowed.contains(s)) continue;
        if (RegExp(r'[A-Za-z؀-ۿ]{3,}').hasMatch(s)) offenders.add('${f.path}: "$s"');
      }
    }
    expect(offenders, isEmpty);
  });
}
