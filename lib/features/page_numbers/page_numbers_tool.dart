import 'dart:ui' show Color, FontWeight;

import '../../core/arabic/normalize.dart';
import '../../core/files/naming.dart';
import '../../core/files/output_file.dart';
import '../../core/jobs/job.dart';
import '../../core/pdf/pdf_service.dart';
import '../../core/pdf/pdfium_native.dart';
import '../../core/pdf/stamp_pdf.dart';
import '../../core/render/text_image.dart';

enum NumberPosition { topLeft, topCenter, topRight, bottomLeft, bottomCenter, bottomRight }

class PageNumberOptions {
  const PageNumberOptions({
    this.position = NumberPosition.bottomCenter,
    this.start = 1,
    this.withTotal = false,
    this.easternDigits = false,
    this.fontSizePt = 11,
    this.skipFirst = false,
    this.color = const Color(0xFF14171C),
  });

  final NumberPosition position;
  final int start;

  /// "1 / N" instead of "1".
  final bool withTotal;

  /// ١٢٣ instead of 123.
  final bool easternDigits;
  final double fontSizePt;

  /// The first page (cover) is counted but gets no number.
  final bool skipFirst;
  final Color color;
}

/// Label for page index [i] (0-based) of [count], or null for no number.
String? pageLabel(int i, int count, PageNumberOptions o) {
  if (o.skipFirst && i == 0) return null;
  final n = o.start + i;
  final total = o.start + count - 1;
  final label = o.withTotal ? '$n / $total' : '$n';
  return o.easternDigits ? toEasternArabicDigits(label) : label;
}

const double kNumberMargin = 28;

Future<OutputFile> runPageNumbers(InputFile input, PageNumberOptions o, JobContext ctx) async {
  final doc = await PdfService.openForEdit(input.bytes);
  try {
    final count = doc.pages.length;
    final stamps = <StampImage>[];
    final placements = <StampPlacement>[];
    for (var i = 0; i < count; i++) {
      if (i % 10 == 0) ctx.progress(0.6 * i / count, JobStage.page(i + 1, count));
      final label = pageLabel(i, count, o);
      if (label == null) continue;
      final rt = await renderTextImage(label,
          fontSizePt: o.fontSizePt, color: o.color, weight: FontWeight.w500);
      final page = doc.pages[i];
      final w = rt.widthPt, h = rt.heightPt;
      final col = o.position.index % 3;
      final top = o.position.index < 3;
      final x = switch (col) {
        0 => kNumberMargin,
        1 => (page.width - w) / 2,
        _ => page.width - w - kNumberMargin,
      };
      final y = top ? kNumberMargin - h / 4 : page.height - kNumberMargin - h * 3 / 4;
      placements.add(StampPlacement(
          pageIndex: i, stampIndex: stamps.length, x: x, y: y, width: w, height: h));
      stamps.add(StampImage(rt.png, w, h));
    }
    ctx.progress(0.65);
    final stampPdf = await ctx.compute(buildStampPdf, stamps);
    ctx.progress(0.75);
    await stampPages(doc, stampPdf, placements);
    final bytes = await doc.encodePdf();
    ctx.progress(0.9, const JobStage.verifying());
    final n = await PdfService.verify(bytes, expectedPages: count);
    return OutputFile(
      name: outputFileName(input.name, kToolFileSuffix['pageNumbers']!, 'pdf'),
      bytes: bytes,
      pageCount: n,
    );
  } finally {
    await doc.dispose();
  }
}

