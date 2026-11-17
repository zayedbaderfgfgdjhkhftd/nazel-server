import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart' as pg;
import 'package:pdf/widgets.dart' as pw;

import '../../core/errors.dart';
import '../../core/files/file_type.dart';
import '../../core/files/naming.dart';
import '../../core/files/output_file.dart';
import '../../core/image/image_ops.dart';
import '../../core/jobs/job.dart';
import '../../core/pdf/pdf_service.dart';

enum PageSizeOption { a4, letter, fitImage }

enum OrientationOption { auto, portrait, landscape }

enum MarginOption { none, small, large }

enum FitOption { contain, cover }

class ImagesToPdfOptions {
  const ImagesToPdfOptions({
    this.pageSize = PageSizeOption.a4,
    this.orientation = OrientationOption.auto,
    this.margin = MarginOption.small,
    this.fit = FitOption.contain,
  });
  final PageSizeOption pageSize;
  final OrientationOption orientation;
  final MarginOption margin;
  final FitOption fit;

  double get marginPt => switch (margin) {
        MarginOption.none => 0,
        MarginOption.small => 18,
        MarginOption.large => 42,
      };
}

/// One prepared image: bytes dart_pdf can embed + its upright pixel size.
typedef PreparedImage = ({Uint8List bytes, int width, int height});

/// Turns any supported image (HEIC must already be converted to JPEG by the
/// caller on the UI isolate) into embeddable bytes. JPEGs are embedded as-is
/// (no re-compression; EXIF orientation is honoured by the PDF writer);
/// WebP is converted to PNG (lossless) or JPEG (photos).
PreparedImage prepareImageJob(Uint8List bytes) {
  final type = detectFileType(bytes);
  if (type == DetectedType.jpeg) {
    // Header-only parse: fast even for 12 MP photos.
    pg.PdfJpegInfo info;
    try {
      info = pg.PdfJpegInfo(bytes);
    } catch (e) {
      throw AppException(AppErrorCode.corrupt, e);
    }
    final w = info.width;
    if (w == null || w <= 0 || info.height <= 0) {
      throw const AppException(AppErrorCode.corrupt, 'jpeg size');
    }
    // EXIF orientations 5-8 swap width and height when displayed upright.
    final swap = info.orientation.index >= 4;
    return (bytes: bytes, width: swap ? info.height : w, height: swap ? w : info.height);
  }
  if (type == DetectedType.png) {
    if (bytes.length < 24) throw const AppException(AppErrorCode.corrupt, 'png');
    final bd = ByteData.sublistView(bytes);
    final w = bd.getUint32(16);
    final h = bd.getUint32(20);
    if (w == 0 || h == 0) throw const AppException(AppErrorCode.corrupt, 'png size');
    return (bytes: bytes, width: w, height: h);
  }
  if (type == DetectedType.webp) {
    final image = decodeUpright(bytes);
    final out = hasTransparency(image)
        ? img.encodePng(image, level: 6)
        : img.encodeJpg(image.convert(numChannels: 3), quality: 92);
    return (bytes: out, width: image.width, height: image.height);
  }
  throw const AppException(AppErrorCode.notImage);
}

/// Computes the page size (points) for an image of [w] x [h] pixels.
({double width, double height}) pageSizeFor(int w, int h, ImagesToPdfOptions o) {
  if (o.pageSize == PageSizeOption.fitImage) {
    // 96 DPI convention: 1 px = 0.75 pt. Margins are added around the image.
    return (width: w * 0.75 + 2 * o.marginPt, height: h * 0.75 + 2 * o.marginPt);
  }
  final base = o.pageSize == PageSizeOption.a4 ? PaperSizes.a4 : PaperSizes.letter;
  final landscape = switch (o.orientation) {
    OrientationOption.portrait => false,
    OrientationOption.landscape => true,
    OrientationOption.auto => w > h,
  };
  return landscape
      ? (width: base.height, height: base.width)
      : (width: base.width, height: base.height);
}

typedef _BuildRequest = ({List<PreparedImage> images, ImagesToPdfOptions options});

Future<Uint8List> _buildPdfJob(_BuildRequest r) {
  final doc = pw.Document(compress: true);
  for (final im in r.images) {
    final size = pageSizeFor(im.width, im.height, r.options);
    final provider = pw.MemoryImage(im.bytes);
    final fit = r.options.fit == FitOption.cover ? pw.BoxFit.cover : pw.BoxFit.contain;
    doc.addPage(pw.Page(
      pageFormat: pg.PdfPageFormat(size.width, size.height),
      margin: pw.EdgeInsets.all(r.options.marginPt),
      build: (_) => pw.SizedBox.expand(
        child: pw.ClipRect(child: pw.Center(child: pw.Image(provider, fit: fit))),
      ),
    ));
  }
  return doc.save();
}

/// Converts images (already HEIC-normalised) to one PDF, one image per page.
Future<OutputFile> runImagesToPdf(
  List<InputFile> images,
  ImagesToPdfOptions options,
  JobContext ctx,
) async {
  if (images.isEmpty) throw const AppException(AppErrorCode.nothingSelected);
  final prepared = <PreparedImage>[];
  for (var i = 0; i < images.length; i++) {
    ctx.progress(i / (images.length + 1), JobStage.file(i + 1, images.length));
    prepared.add(await ctx.compute(prepareImageJob, images[i].bytes));
  }
  ctx.progress(images.length / (images.length + 1));
  final bytes = await ctx.compute(_buildPdfJob, (images: prepared, options: options));
  ctx.progress(0.98, const JobStage.verifying());
  final n = await PdfService.verify(bytes, expectedPages: images.length);
  return OutputFile(
    name: outputFileName(images.first.name, kToolFileSuffix['imagesToPdf']!, 'pdf'),
    bytes: bytes,
    pageCount: n,
  );
}

/// Longest side helper used by previews.
int longestSide(int w, int h) => math.max(w, h);
