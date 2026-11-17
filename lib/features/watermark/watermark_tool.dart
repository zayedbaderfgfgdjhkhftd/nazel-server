import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

import '../../core/errors.dart';
import '../../core/files/naming.dart';
import '../../core/files/output_file.dart';
import '../../core/image/image_ops.dart';
import '../../core/jobs/job.dart';
import '../../core/pdf/page_ranges.dart';
import '../../core/pdf/pdf_service.dart';
import '../../core/pdf/pdfium_native.dart';
import '../../core/pdf/stamp_pdf.dart';
import '../../core/render/text_image.dart';

enum WatermarkType { text, image }

/// 3x3 placement grid.
enum Anchor9 {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

class WatermarkOptions {
  const WatermarkOptions({
    this.type = WatermarkType.text,
    this.text = '',
    this.imageBytes,
    this.anchor = Anchor9.center,
    this.opacity = 0.3,
    this.rotationDeg = 45,
    this.fontSizePt = 48,
    this.imageWidthFraction = 0.4,
    this.pagesText,
    this.color = const Color(0xFF6B7280),
  });

  final WatermarkType type;
  final String text;
  final Uint8List? imageBytes;
  final Anchor9 anchor;

  /// 0.05..1
  final double opacity;

  /// Counter-clockwise degrees, -90..90.
  final double rotationDeg;
  final double fontSizePt;

  /// Image width as a fraction of page width.
  final double imageWidthFraction;

  /// Page ranges like "1-3, 5"; null = all pages.
  final String? pagesText;
  final Color color;
}

const double kStampMargin = 24;

/// Top-left corner of a [w] x [h] box anchored inside a page.
({double x, double y}) anchorPosition(
  Anchor9 a,
  double pageW,
  double pageH,
  double w,
  double h, {
  double margin = kStampMargin,
}) {
  final col = a.index % 3;
  final row = a.index ~/ 3;
  final x = switch (col) {
    0 => margin,
    1 => (pageW - w) / 2,
    _ => pageW - w - margin,
  };
  final y = switch (row) {
    0 => margin,
    1 => (pageH - h) / 2,
    _ => pageH - h - margin,
  };
  return (x: x, y: y);
}

Future<OutputFile> runWatermark(InputFile input, WatermarkOptions o, JobContext ctx) async {
  if (o.type == WatermarkType.text && o.text.trim().isEmpty) {
    throw const AppException(AppErrorCode.nothingSelected);
  }
  if (o.type == WatermarkType.image && o.imageBytes == null) {
    throw const AppException(AppErrorCode.nothingSelected);
  }
  final doc = await PdfService.openForEdit(input.bytes);
  try {
    final count = doc.pages.length;
    final pages = o.pagesText == null || o.pagesText!.trim().isEmpty
        ? [for (var i = 1; i <= count; i++) i]
        : flattenRanges(parsePageRanges(o.pagesText!, count));
    ctx.progress(0.1);

    StampImage stamp;
    if (o.type == WatermarkType.text) {
      // Arabic-safe: shaped by the platform text engine, embedded as image.
      final rt = await renderTextImage(o.text.trim(),
          fontSizePt: o.fontSizePt,
          color: o.color,
          opacity: o.opacity,
          rotationDeg: o.rotationDeg);
      stamp = StampImage(rt.png, rt.widthPt, rt.heightPt);
    } else {
      final prepared = await ctx.compute(prepareWatermarkImageJob, (
        bytes: o.imageBytes!,
        opacity: o.opacity,
        rotationDeg: o.rotationDeg,
        maxSide: 1600,
      ));
      stamp = StampImage(prepared.png, prepared.width * 0.75, prepared.height * 0.75);
    }
    ctx.progress(0.3);
    final stampPdf = await ctx.compute(buildStampPdf, [stamp]);
    ctx.progress(0.5);

    final placements = <StampPlacement>[];
    for (final p in pages) {
      final page = doc.pages[p - 1];
      double w, h;
      if (o.type == WatermarkType.text) {
        w = stamp.widthPt;
        h = stamp.heightPt;
      } else {
        w = page.width * o.imageWidthFraction.clamp(0.05, 1.0);
        h = w * stamp.heightPt / stamp.widthPt;
      }
      // Never larger than the page (minus margins).
      final fit = math.min(
        1.0,
        math.min((page.width - 2 * kStampMargin) / w, (page.height - 2 * kStampMargin) / h),
      );
      w *= fit;
      h *= fit;
      final pos = anchorPosition(o.anchor, page.width, page.height, w, h);
      placements.add(StampPlacement(
          pageIndex: p - 1, stampIndex: 0, x: pos.x, y: pos.y, width: w, height: h));
    }
    await stampPages(doc, stampPdf, placements);
    ctx.progress(0.8);
    final bytes = await doc.encodePdf();
    ctx.progress(0.9, const JobStage.verifying());
    final n = await PdfService.verify(bytes, expectedPages: count);
    return OutputFile(
      name: outputFileName(input.name, kToolFileSuffix['watermark']!, 'pdf'),
      bytes: bytes,
      pageCount: n,
    );
  } finally {
    await doc.dispose();
  }
}
