import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  test('pdfium loads', () async {
    await pdfrxInitialize();
    final doc = await PdfDocument.createNew(sourceName: 'smoke');
    expect(doc.pages.length, 0);
    await doc.dispose();
  });
}
