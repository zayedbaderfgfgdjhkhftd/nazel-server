import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import '../errors.dart';

/// Raw BGRA pixels of a rendered page.
class RenderedPage {
  RenderedPage(this.bgra, this.width, this.height);
  final Uint8List bgra;
  final int width;
  final int height;
}

/// Renders [page] at [dpi] (72 = 1 pixel per point) on a white background.
/// The page's /Rotate is applied, so the image is upright as displayed.
Future<RenderedPage> renderPage(PdfPage page, double dpi, {int maxPixels = 40000000}) async {
  var scale = dpi / 72.0;
  // Guard against absurd sizes (e.g. huge posters at 300 DPI).
  final pixels = page.width * scale * page.height * scale;
  if (pixels > maxPixels) scale *= (maxPixels / pixels).clamp(0.01, 1.0).toDouble();
  final w = (page.width * scale).round().clamp(1, 20000);
  final h = (page.height * scale).round().clamp(1, 20000);
  final image = await page.render(
    fullWidth: w.toDouble(),
    fullHeight: h.toDouble(),
    backgroundColor: 0xffffffff,
    annotationRenderingMode: PdfAnnotationRenderingMode.annotationAndForms,
  );
  if (image == null) throw const AppException(AppErrorCode.corrupt, 'render failed');
  try {
    return RenderedPage(Uint8List.fromList(image.pixels), image.width, image.height);
  } finally {
    image.dispose();
  }
}
