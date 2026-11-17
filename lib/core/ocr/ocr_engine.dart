import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Recognises text in an image file and returns hOCR markup.
abstract class OcrBackend {
  /// Makes sure the traineddata files for [languages] are ready on disk.
  Future<void> ensureLanguages(List<String> languages);

  /// [language] like 'ara', 'eng' or 'ara+eng'.
  Future<String> recognizeHocr(String imagePath, String language);
}

/// Language data shipped inside the app (assets/tessdata, Apache-2.0,
/// from tesseract-ocr/tessdata_fast). Sizes in bytes.
const Map<String, int> kBundledOcrLanguages = {
  'ara': 1432056,
  'eng': 4113088,
};

/// Tesseract through the `tesseract_ocr` plugin (Android: Tesseract4Android).
///
/// The traineddata files are bundled as assets and copied once into the app's
/// private storage, because Tesseract needs real files. Nothing is downloaded.
class TesseractBackend implements OcrBackend {
  static const _channel = MethodChannel('tesseract_ocr');

  /// Parent directory that contains `tessdata/`.
  static Future<Directory> dataRoot() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'ocr'));
  }

  static Future<File> languageFile(String lang) async =>
      File(p.join((await dataRoot()).path, 'tessdata', '$lang.traineddata'));

  /// Prepared (copied) size per language, or null if not prepared.
  static Future<Map<String, int?>> preparedSizes() async {
    final out = <String, int?>{};
    for (final lang in kBundledOcrLanguages.keys) {
      final f = await languageFile(lang);
      out[lang] = await f.exists() ? await f.length() : null;
    }
    return out;
  }

  static Future<void> removePrepared(String lang) async {
    final f = await languageFile(lang);
    if (await f.exists()) await f.delete();
  }

  static Future<void> prepare(String lang) async {
    final f = await languageFile(lang);
    final expected = kBundledOcrLanguages[lang];
    if (await f.exists() && await f.length() == expected) return;
    await f.parent.create(recursive: true);
    final data = await rootBundle.load('assets/tessdata/$lang.traineddata');
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
    await tmp.rename(f.path);
  }

  @override
  Future<void> ensureLanguages(List<String> languages) async {
    for (final l in languages) {
      await prepare(l);
    }
  }

  @override
  Future<String> recognizeHocr(String imagePath, String language) async {
    final root = await dataRoot();
    final result = await _channel.invokeMethod<String>('extractHocr', {
      'imagePath': imagePath,
      'tessData': root.path,
      'language': language,
    });
    return result ?? '';
  }
}
