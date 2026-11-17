import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../arabic/normalize.dart';

/// A PNG image of rendered text plus its size in PDF points.
class RenderedText {
  RenderedText(this.png, this.widthPt, this.heightPt);
  final Uint8List png;
  final double widthPt;
  final double heightPt;
}

/// Renders [text] with the platform text engine (HarfBuzz shaping + bidi), so
/// Arabic letters join correctly and mixed Arabic/Latin text is ordered
/// correctly. The result is embedded in PDFs as an image (section 4 of the
/// spec): it looks right everywhere, but it is not selectable/searchable.
///
/// Must run on the UI isolate (uses dart:ui).
///
/// - [fontSizePt]: size in PDF points.
/// - [scale]: pixels per point (4 = 288 DPI, comfortably above 3x).
/// - [opacity]: 0..1, baked into the PNG alpha channel.
/// - [rotationDeg]: counter-clockwise rotation; the image bounds grow to fit.
Future<RenderedText> renderTextImage(
  String text, {
  required double fontSizePt,
  required ui.Color color,
  double opacity = 1,
  double rotationDeg = 0,
  double scale = 4,
  ui.FontWeight weight = ui.FontWeight.w500,
  String fontFamily = 'ReadexPro',
}) async {
  final direction = isRtlText(text) ? ui.TextDirection.rtl : ui.TextDirection.ltr;
  final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
    textDirection: direction,
    textAlign: ui.TextAlign.center,
    fontFamily: fontFamily,
    fontSize: fontSizePt * scale,
    fontWeight: weight,
    height: 1.25,
  ))
    ..pushStyle(ui.TextStyle(
      color: color.withValues(alpha: color.a * opacity.clamp(0.0, 1.0)),
      fontFamily: fontFamily,
      fontSize: fontSizePt * scale,
      fontWeight: weight,
    ))
    ..addText(text);
  final para = pb.build()..layout(const ui.ParagraphConstraints(width: 1e6));
  final w = para.maxIntrinsicWidth.ceilToDouble() + 2 * scale;
  para.layout(ui.ParagraphConstraints(width: w));
  final h = para.height.ceilToDouble();

  final rad = rotationDeg * math.pi / 180;
  final bw = (w * math.cos(rad)).abs() + (h * math.sin(rad)).abs();
  final bh = (w * math.sin(rad)).abs() + (h * math.cos(rad)).abs();
  final iw = math.max(1, bw.ceil());
  final ih = math.max(1, bh.ceil());

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.translate(iw / 2, ih / 2);
  canvas.rotate(-rad); // positive = counter-clockwise on screen
  canvas.drawParagraph(para, ui.Offset(-w / 2, -h / 2));
  final picture = recorder.endRecording();
  final image = await picture.toImage(iw, ih);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return RenderedText(data!.buffer.asUint8List(), iw / scale, ih / scale);
}
