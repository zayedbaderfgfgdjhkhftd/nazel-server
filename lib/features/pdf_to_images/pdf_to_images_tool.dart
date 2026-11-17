import 'dart:typed_data';

import '../../core/errors.dart';
import '../../core/files/naming.dart';
import '../../core/files/output_file.dart';
import '../../core/image/image_ops.dart';
import '../../core/jobs/job.dart';
import '../../core/pdf/pdf_service.dart';
import '../../core/pdf/render.dart';

enum ImageFormat { jpg, png }

class PdfToImagesOptions {
  const PdfToImagesOptions({this.format = ImageFormat.jpg, this.dpi = 150, this.singlePage});
  final ImageFormat format;

  /// 72, 150 or 300.
  final int dpi;

  /// 1-based page to export alone, or null for all pages.
  final int? singlePage;
}

/// Renders pages to JPG/PNG. One page -> an image; several -> a ZIP.
Future<OutputFile> runPdfToImages(InputFile input, PdfToImagesOptions o, JobContext ctx) async {
  final doc = await PdfService.openForEdit(input.bytes);
  try {
    final total = doc.pages.length;
    final pages = o.singlePage == null ? [for (var i = 1; i <= total; i++) i] : [o.singlePage!];
    for (final p in pages) {
      if (p < 1 || p > total) throw AppException(AppErrorCode.generic, 'page $p');
    }
    final ext = o.format == ImageFormat.png ? 'png' : 'jpg';
    final base = sanitizeFileBase(baseName(input.name));
    final out = <String, Uint8List>{};
    for (var i = 0; i < pages.length; i++) {
      ctx.progress(i / (pages.length + 1), JobStage.page(i + 1, pages.length));
      final r = await renderPage(doc.pages[pages[i] - 1], o.dpi.toDouble());
      final bytes = await ctx.compute(encodeBgraJob, (
        bgra: r.bgra,
        width: r.width,
        height: r.height,
        png: o.format == ImageFormat.png,
        quality: 90,
      ));
      if (bytes.isEmpty) throw const AppException(AppErrorCode.outputInvalid);
      out['$base-page-${pages[i]}.$ext'] = bytes;
    }
    ctx.progress(0.98, const JobStage.verifying());
    if (out.length == 1) {
      final e = out.entries.first;
      return OutputFile(name: e.key, bytes: e.value);
    }
    return OutputFile(name: outputFileName(input.name, 'images', 'zip'), bytes: zipFiles(out));
  } finally {
    await doc.dispose();
  }
}
