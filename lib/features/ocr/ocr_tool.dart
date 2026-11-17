import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../core/errors.dart';
import '../../core/image/image_ops.dart';
import '../../core/jobs/job.dart';
import '../../core/ocr/hocr.dart';
import '../../core/ocr/ocr_engine.dart';

enum OcrLanguage { arabic, english, both }

extension OcrLanguageX on OcrLanguage {
  String get code => switch (this) {
        OcrLanguage.arabic => 'ara',
        OcrLanguage.english => 'eng',
        OcrLanguage.both => 'ara+eng',
      };
  List<String> get packs => switch (this) {
        OcrLanguage.arabic => ['ara'],
        OcrLanguage.english => ['eng'],
        OcrLanguage.both => ['ara', 'eng'],
      };
}

class OcrOptions {
  const OcrOptions({this.language = OcrLanguage.arabic, this.preprocess = const OcrPreprocess()});
  final OcrLanguage language;
  final OcrPreprocess preprocess;
}

/// Runs OCR on [imageBytes] (JPEG/PNG/WebP; HEIC must be converted first).
///
/// The text is exactly what the engine read: nothing is invented or
/// auto-corrected. Low-confidence words are reported for highlighting.
Future<OcrResult> runOcr(
  Uint8List imageBytes,
  OcrOptions o,
  JobContext ctx, {
  required OcrBackend backend,
  required Directory tempDir,
}) async {
  ctx.progress(0.05, const JobStage.preparingOcr());
  await backend.ensureLanguages(o.language.packs);
  ctx.progress(0.15);
  final png = await ctx.compute(preprocessForOcrJob, (
    bytes: imageBytes,
    grayscale: o.preprocess.grayscale,
    contrast: o.preprocess.contrast,
    binarize: o.preprocess.binarize,
    maxSide: 4200,
  ));
  final file = File(p.join(tempDir.path, 'ocr-${DateTime.now().microsecondsSinceEpoch}.png'));
  await file.writeAsBytes(png, flush: true);
  try {
    ctx.progress(0.3, const JobStage.readingText());
    String hocr;
    try {
      hocr = await backend.recognizeHocr(file.path, o.language.code);
    } catch (e) {
      throw AppException(AppErrorCode.ocrFailed, e);
    }
    ctx.checkCancelled();
    ctx.progress(0.95);
    return parseOcrOutput(hocr);
  } finally {
    try {
      await file.delete();
    } catch (_) {}
  }
}
