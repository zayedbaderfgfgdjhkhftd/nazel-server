import 'dart:typed_data';

import 'package:pdf/pdf.dart' as pg;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart';

import '../../core/files/naming.dart';
import '../../core/files/output_file.dart';
import '../../core/image/image_ops.dart';
import '../../core/jobs/job.dart';
import '../../core/pdf/image_recompress.dart';
import '../../core/pdf/pdf_service.dart';
import '../../core/pdf/render.dart';

enum CompressLevel { light, recommended, strong }

class CompressOptions {
  const CompressOptions({this.level = CompressLevel.recommended, this.strongDpi = 100});
  final CompressLevel level;

  /// Resolution for [CompressLevel.strong] (pages become images).
  final int strongDpi;
}

class CompressResult {
  CompressResult({
    required this.originalSize,
    required this.newSize,
    required this.file,
    required this.levelUsed,
    this.imagesRecoded = 0,
  });

  final int originalSize;

  /// Size of the produced file (even when it was not kept).
  final int newSize;

  /// Null when the result was not smaller: the original is kept as-is.
  final OutputFile? file;

  /// May be [CompressLevel.light] when "recommended" had to fall back.
  final CompressLevel levelUsed;
  final int imagesRecoded;

  bool get keptOriginal => file == null;
  double get savedFraction => originalSize == 0 ? 0 : 1 - newSize / originalSize;
}

Future<CompressResult> runCompress(InputFile input, CompressOptions options, JobContext ctx) async {
  final original = input.bytes.length;
  final name = outputFileName(input.name, kToolFileSuffix['compress']!, 'pdf');
  Uint8List bytes;
  var levelUsed = options.level;
  var recoded = 0;
  int pages;

  final doc = await PdfService.openForEdit(input.bytes);
  try {
    pages = doc.pages.length;
    switch (options.level) {
      case CompressLevel.light:
        ctx.progress(0.3);
        bytes = await doc.encodePdf();
      case CompressLevel.recommended:
        ctx.progress(0.1);
        final stats = await recompressJpegImages(doc, targetDpi: 150, quality: 70);
        ctx.progress(0.5);
        if (stats.recoded == 0) {
          levelUsed = CompressLevel.light;
          bytes = await doc.encodePdf();
        } else {
          bytes = await doc.encodePdf();
          ctx.progress(0.6, const JobStage.verifying());
          final ok = await _rendersMatch(input.bytes, bytes, ctx);
          if (ok) {
            recoded = stats.recoded;
          } else {
            // Something changed visibly: discard and use lossless clean-up.
            levelUsed = CompressLevel.light;
            final fresh = await PdfService.openForEdit(input.bytes);
            try {
              bytes = await fresh.encodePdf();
            } finally {
              await fresh.dispose();
            }
          }
        }
      case CompressLevel.strong:
        bytes = await _rasterize(doc, options.strongDpi, ctx);
    }
  } finally {
    await doc.dispose();
  }

  ctx.progress(0.97, const JobStage.verifying());
  final n = await PdfService.verify(bytes, expectedPages: pages);
  final keep = bytes.length < original;
  return CompressResult(
    originalSize: original,
    newSize: bytes.length,
    file: keep ? OutputFile(name: name, bytes: bytes, pageCount: n) : null,
    levelUsed: levelUsed,
    imagesRecoded: recoded,
  );
}

/// Strong: every page becomes a JPEG image (text is no longer selectable).
Future<Uint8List> _rasterize(PdfDocument doc, int dpi, JobContext ctx) async {
  final jpegs = <({Uint8List jpeg, double w, double h})>[];
  final total = doc.pages.length;
  for (var i = 0; i < total; i++) {
    ctx.progress(i / (total + 1), JobStage.page(i + 1, total));
    final page = doc.pages[i];
    final r = await renderPage(page, dpi.toDouble());
    final jpeg = await ctx.compute(encodeBgraJob,
        (bgra: r.bgra, width: r.width, height: r.height, png: false, quality: 60));
    jpegs.add((jpeg: jpeg, w: page.width, h: page.height));
  }
  ctx.progress(total / (total + 1));
  return ctx.compute(_buildImagePdf, jpegs);
}

Future<Uint8List> _buildImagePdf(List<({Uint8List jpeg, double w, double h})> pages) {
  final doc = pw.Document(compress: true);
  for (final p in pages) {
    final image = pw.MemoryImage(p.jpeg);
    doc.addPage(pw.Page(
      pageFormat: pg.PdfPageFormat(p.w, p.h),
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.SizedBox.expand(child: pw.Image(image, fit: pw.BoxFit.fill)),
    ));
  }
  return doc.save();
}

/// Renders every page of both files at low resolution and checks they look
/// the same (allowing for JPEG noise).
Future<bool> _rendersMatch(Uint8List a, Uint8List b, JobContext ctx) async {
  final da = await PdfDocument.openData(a, sourceName: PdfService.sourceName('cmpA'));
  final db = await PdfDocument.openData(b, sourceName: PdfService.sourceName('cmpB'));
  try {
    if (da.pages.length != db.pages.length) return false;
    for (var i = 0; i < da.pages.length; i++) {
      ctx.progress(0.6 + 0.35 * i / da.pages.length, JobStage.page(i + 1, da.pages.length));
      final ra = await renderPage(da.pages[i], 36);
      final rb = await renderPage(db.pages[i], 36);
      if (!pageImagesSimilar(ra, rb)) return false;
    }
    return true;
  } finally {
    await da.dispose();
    await db.dispose();
  }
}

/// Mean absolute difference must stay small and few pixels may differ a lot.
bool pageImagesSimilar(RenderedPage a, RenderedPage b) {
  if (a.width != b.width || a.height != b.height) return false;
  var sum = 0;
  var big = 0;
  final n = a.width * a.height;
  for (var i = 0; i < a.bgra.length; i += 4) {
    final d = ((a.bgra[i] - b.bgra[i]).abs() +
            (a.bgra[i + 1] - b.bgra[i + 1]).abs() +
            (a.bgra[i + 2] - b.bgra[i + 2]).abs()) ~/
        3;
    sum += d;
    if (d > 96) big++;
  }
  return sum / n < 6.0 && big / n < 0.01;
}
