import 'dart:typed_data';

import 'package:pdf/pdf.dart' as pg;
import 'package:pdf/widgets.dart' as pw;

/// One stamp: a PNG (with alpha) and the size it should have, in points.
class StampImage {
  StampImage(this.png, this.widthPt, this.heightPt);
  final Uint8List png;
  final double widthPt;
  final double heightPt;
}

/// Builds a PDF whose page i contains stamps[i] filling the whole page.
/// The pages are later turned into Form XObjects and drawn onto the target
/// document (see `stampPages`).
Future<Uint8List> buildStampPdf(List<StampImage> stamps) async {
  final doc = pw.Document(compress: true);
  for (final s in stamps) {
    final image = pw.MemoryImage(s.png);
    doc.addPage(pw.Page(
      pageFormat: pg.PdfPageFormat(s.widthPt, s.heightPt),
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.SizedBox.expand(child: pw.Image(image, fit: pw.BoxFit.fill)),
    ));
  }
  return doc.save();
}
