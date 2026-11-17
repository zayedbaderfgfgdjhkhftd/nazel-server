import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app/app.dart';
import 'app/services.dart';
import 'core/platform/platform_bridge.dart';
import 'core/storage/file_store.dart';
import 'core/storage/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerAssetLicenses();
  await pdfrxFlutterInitialize();

  final support = await getApplicationSupportDirectory();
  final temp = await getTemporaryDirectory();
  final files = await FileStore.open(Directory(p.join(support.path, 'library')));
  final settings = await SettingsStore.open(support);
  // Trash items older than 30 days are deleted for good.
  await files.purgeExpired();

  runApp(SatrApp(
    services: AppServices(
      files: files,
      settings: settings,
      platform: PlatformBridge(),
      tempDir: temp,
    ),
  ));
}

/// Licences of bundled non-Dart assets, shown on the licences page.
void _registerAssetLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
        ['Readex Pro (font)'], await rootBundle.loadString('assets/fonts/OFL.txt'));
    yield LicenseEntryWithLineBreaks(
        ['tessdata_fast (Tesseract OCR models)'], await rootBundle.loadString('assets/tessdata/LICENSE'));
    yield const LicenseEntryWithLineBreaks(['Lucide icons'], _lucideIsc);
    yield LicenseEntryWithLineBreaks(['PDFium, FreeType, Tesseract and other native components'],
        await rootBundle.loadString('assets/licenses/NATIVE_NOTICES.txt'));
  });
}

const _lucideIsc = '''ISC License

Copyright (c) for portions of Lucide are held by Cole Bemis 2013-2022 as part of Feather (MIT). All other copyright (c) for Lucide are held by Lucide Contributors 2022.

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.''';
