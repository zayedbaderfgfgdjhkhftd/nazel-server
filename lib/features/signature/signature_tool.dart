import 'dart:typed_data';

import '../../core/errors.dart';
import '../../core/files/naming.dart';
import '../../core/files/output_file.dart';
import '../../core/jobs/job.dart';
import '../../core/pdf/pdf_service.dart';
import '../../core/pdf/pdfium_native.dart';
import '../../core/pdf/stamp_pdf.dart';

/// A drawn signature (an image), placed on a page. This is NOT a digital or
/// certified signature, and the UI never calls it one.
class SignatureOptions {
  const SignatureOptions({
    required this.png,
    required this.pngWidth,
    required this.pngHeight,
    required this.pageIndex,
    required this.left,
    required this.top,
    required this.width,
    this.allPages = false,
  });

  /// Signature image with a transparent background.
  final Uint8List png;
  final int pngWidth;
  final int pngHeight;

  /// 0-based page to sign (ignored when [allPages]).
  final int pageIndex;

  /// Position/size as fractions (0..1) of the page's visual width/height.
  /// The height follows from the image aspect ratio.
  final double left;
  final double top;
  final double width;
  final bool allPages;
}

Future<OutputFile> runSignature(InputFile input, SignatureOptions o, JobContext ctx) async {
  if (o.png.isEmpty || o.pngWidth <= 0 || o.pngHeight <= 0) {
    throw const AppException(AppErrorCode.nothingSelected);
  }
  final doc = await PdfService.openForEdit(input.bytes);
  try {
    final count = doc.pages.length;
    if (!o.allPages && (o.pageIndex < 0 || o.pageIndex >= count)) {
      throw AppException(AppErrorCode.generic, 'page ${o.pageIndex}');
    }
    ctx.progress(0.1);
    final stamp = StampImage(o.png, o.pngWidth * 0.75, o.pngHeight * 0.75);
    final stampPdf = await ctx.compute(buildStampPdf, [stamp]);
    ctx.progress(0.4);
    final indices = o.allPages ? [for (var i = 0; i < count; i++) i] : [o.pageIndex];
    final placements = <StampPlacement>[];
    for (final i in indices) {
      final page = doc.pages[i];
      final w = page.width * o.width;
      final h = w * o.pngHeight / o.pngWidth;
      placements.add(StampPlacement(
        pageIndex: i,
        stampIndex: 0,
        x: page.width * o.left,
        y: page.height * o.top,
        width: w,
        height: h,
      ));
    }
    await stampPages(doc, stampPdf, placements);
    ctx.progress(0.7);
    final bytes = await doc.encodePdf();
    ctx.progress(0.9, const JobStage.verifying());
    final n = await PdfService.verify(bytes, expectedPages: count);
    return OutputFile(
      name: outputFileName(input.name, kToolFileSuffix['signature']!, 'pdf'),
      bytes: bytes,
      pageCount: n,
    );
  } finally {
    await doc.dispose();
  }
}
