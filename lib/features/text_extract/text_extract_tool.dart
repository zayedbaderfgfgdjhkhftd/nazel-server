import '../../core/arabic/presentation_forms.dart';
import '../../core/arabic/visual_order.dart';
import '../../core/jobs/job.dart';
import '../../core/pdf/pdf_service.dart';

class PageText {
  PageText(this.pageNumber, this.text);
  final int pageNumber;
  final String text;
  bool get isEmpty => text.trim().isEmpty;
}

/// Reads the embedded text layer of every page.
///
/// Arabic presentation forms (the shaped glyph codes some PDF writers store)
/// are converted back to normal letters so the text can be searched/edited.
Future<List<PageText>> runTextExtract(InputFile input, JobContext ctx) async {
  final doc = await PdfService.openForEdit(input.bytes);
  try {
    final out = <PageText>[];
    final total = doc.pages.length;
    for (var i = 0; i < total; i++) {
      ctx.progress(i / total, JobStage.page(i + 1, total));
      final raw = await doc.pages[i].loadText();
      var text = raw?.fullText ?? '';
      if (raw != null && raw.charRects.length == text.length) {
        text = reorderArabicLines(text, [
          for (final r in raw.charRects) CharBox(r.left, r.right, r.bottom, r.top),
        ]);
      }
      out.add(PageText(i + 1, cleanExtractedText(text)));
    }
    return out;
  } finally {
    await doc.dispose();
  }
}

String cleanExtractedText(String s) {
  var t = normalizePresentationForms(s);
  t = t.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  // Drop trailing spaces per line and excessive blank lines.
  t = t.split('\n').map((l) => l.trimRight()).join('\n');
  return t.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

/// Joins pages for TXT export with page headers.
String joinPages(List<PageText> pages, String Function(int) header) {
  final b = StringBuffer();
  for (final p in pages) {
    if (b.isNotEmpty) b.write('\n\n');
    b.writeln(header(p.pageNumber));
    b.write(p.text);
  }
  return b.toString();
}
