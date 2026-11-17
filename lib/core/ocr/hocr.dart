/// Parsing of Tesseract hOCR output into words with confidence values.
library;

class OcrWord {
  OcrWord(this.text, this.confidence);
  final String text;

  /// 0..100 as reported by Tesseract (x_wconf), or -1 when the engine did
  /// not report a confidence (then the word is never highlighted).
  final int confidence;

  bool get hasConfidence => confidence >= 0;
}

class OcrLine {
  OcrLine(this.words);
  final List<OcrWord> words;
  String get text => words.map((w) => w.text).join(' ');
}

class OcrParagraph {
  OcrParagraph(this.lines);
  final List<OcrLine> lines;
}

class OcrResult {
  OcrResult(this.paragraphs);
  final List<OcrParagraph> paragraphs;

  List<OcrWord> get words => [
        for (final p in paragraphs)
          for (final l in p.lines) ...l.words,
      ];

  bool get isEmpty => words.every((w) => w.text.trim().isEmpty);

  /// Plain text: words joined by spaces, lines by newlines, paragraphs by a
  /// blank line. Nothing is added or "corrected".
  String get text => paragraphs
      .map((p) => p.lines.map((l) => l.text).where((t) => t.isNotEmpty).join('\n'))
      .where((t) => t.isNotEmpty)
      .join('\n\n');

  /// Character ranges in [text] of words below [threshold] confidence.
  List<(int, int)> lowConfidenceRanges(int threshold) {
    final ranges = <(int, int)>[];
    var offset = 0;
    var firstPara = true;
    for (final p in paragraphs) {
      final lines = p.lines.where((l) => l.text.isNotEmpty).toList();
      if (lines.isEmpty) continue;
      if (!firstPara) offset += 2;
      firstPara = false;
      for (var li = 0; li < lines.length; li++) {
        if (li > 0) offset += 1;
        final words = lines[li].words;
        for (var wi = 0; wi < words.length; wi++) {
          if (wi > 0) offset += 1;
          final w = words[wi];
          if (w.hasConfidence && w.confidence < threshold && w.text.isNotEmpty) {
            ranges.add((offset, offset + w.text.length));
          }
          offset += w.text.length;
        }
      }
    }
    return ranges;
  }

  int lowConfidenceCount(int threshold) =>
      words.where((w) => w.hasConfidence && w.confidence < threshold && w.text.isNotEmpty).length;

  /// False when the engine returned plain text without confidences.
  bool get hasConfidence => words.any((w) => w.hasConfidence);

  double get meanConfidence {
    final ws = words.where((w) => w.text.isNotEmpty && w.hasConfidence).toList();
    if (ws.isEmpty) return 0;
    return ws.fold<int>(0, (s, w) => s + w.confidence) / ws.length;
  }
}

final _token = RegExp(
  r"""<p\s+class=['"]ocr_par['"]|<span\s+class=['"](?:ocr_line|ocr_header|ocr_caption|ocr_textfloat)['"]|<span\s+class=['"]ocrx_word['"][^>]*?title=['"]([^'"]*)['"][^>]*>(.*?)</span>""",
  dotAll: true,
);
final _conf = RegExp(r'x_wconf\s+(\d+)');
final _tags = RegExp(r'<[^>]+>');

/// Parses engine output: hOCR when available (word confidences), otherwise
/// plain text (some platforms' plugins only return text).
OcrResult parseOcrOutput(String output) {
  if (output.contains('ocrx_word')) return parseHocr(output);
  final paragraphs = <OcrParagraph>[];
  for (final block in output.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'))) {
    final lines = <OcrLine>[];
    for (final l in block.split('\n')) {
      final words = l.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) => OcrWord(w, -1)).toList();
      if (words.isNotEmpty) lines.add(OcrLine(words));
    }
    if (lines.isNotEmpty) paragraphs.add(OcrParagraph(lines));
  }
  return OcrResult(paragraphs);
}

/// Parses hOCR markup. Unknown structure degrades gracefully to one paragraph.
OcrResult parseHocr(String hocr) {
  final paragraphs = <OcrParagraph>[];
  OcrParagraph? para;
  OcrLine? line;
  for (final m in _token.allMatches(hocr)) {
    final s = m.group(0)!;
    if (s.startsWith('<p')) {
      para = OcrParagraph([]);
      paragraphs.add(para);
      line = null;
    } else if (m.group(1) == null && m.group(2) == null) {
      if (para == null) {
        para = OcrParagraph([]);
        paragraphs.add(para);
      }
      line = OcrLine([]);
      para.lines.add(line);
    } else {
      if (para == null) {
        para = OcrParagraph([]);
        paragraphs.add(para);
      }
      if (line == null) {
        line = OcrLine([]);
        para.lines.add(line);
      }
      final conf = int.tryParse(_conf.firstMatch(m.group(1)!)?.group(1) ?? '') ?? 0;
      final text = _unescape(m.group(2)!.replaceAll(_tags, '')).trim();
      if (text.isNotEmpty) line.words.add(OcrWord(text, conf));
    }
  }
  return OcrResult(paragraphs
      .map((p) => OcrParagraph(p.lines.where((l) => l.words.isNotEmpty).toList()))
      .where((p) => p.lines.isNotEmpty)
      .toList());
}

String _unescape(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&apos;', "'")
    .replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)))
    .replaceAllMapped(
        RegExp(r'&#x([0-9a-fA-F]+);'), (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)))
    .replaceAll('&amp;', '&');
