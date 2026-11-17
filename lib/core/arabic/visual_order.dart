/// Rebuilds the logical (reading) order of Arabic text extracted from PDFs.
///
/// Many PDF writers (Chromium, some office suites) store Arabic glyphs in
/// visual order (left to right on the page). Text extraction then returns
/// Arabic words with their letters reversed, and sometimes whole lines in
/// visual word order. Glyph positions are reliable, so for each line that
/// contains Arabic we:
///  1. keep PDFium's word boundaries (spaces),
///  2. inside each word, reverse runs of Arabic letters whose positions go
///     left-to-right (logical Arabic order goes right-to-left),
///  3. if the Arabic words themselves are in left-to-right page order,
///     convert the line from visual to logical word order (reverse, then
///     restore left-to-right runs such as Latin words and numbers).
/// Ligatures (several characters sharing one glyph box) stay intact.
/// Lines without Arabic are returned unchanged.
library;

class CharBox {
  const CharBox(this.left, this.right, this.bottom, this.top);
  final double left;
  final double right;
  final double bottom;
  final double top;
  double get centerX => (left + right) / 2;
}

enum _Kind { r, l, en, n }

bool _isSpace(int c) => c == 0x20 || c == 0x09 || c == 0xA0;

_Kind _kindOf(int r) {
  if ((r >= 0x0660 && r <= 0x0669) || (r >= 0x06F0 && r <= 0x06F9) || (r >= 0x30 && r <= 0x39)) {
    return _Kind.en;
  }
  if ((r >= 0x0600 && r <= 0x06FF) ||
      (r >= 0x0750 && r <= 0x077F) ||
      (r >= 0x08A0 && r <= 0x08FF) ||
      (r >= 0xFB50 && r <= 0xFDFF) ||
      (r >= 0xFE70 && r <= 0xFEFF)) {
    return _Kind.r;
  }
  if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A) || (r >= 0xC0 && r <= 0x24F)) {
    return _Kind.l;
  }
  return _Kind.n;
}

class _Cluster {
  _Cluster(this.text, this.box);
  String text;
  final CharBox box;
}

class _Word {
  _Word(this.clusters);
  final List<_Cluster> clusters;
  String get text => clusters.map((c) => c.text).join();
  _Kind get kind {
    var hasL = false, hasEn = false;
    for (final r in text.runes) {
      final k = _kindOf(r);
      if (k == _Kind.r) return _Kind.r;
      if (k == _Kind.l) hasL = true;
      if (k == _Kind.en) hasEn = true;
    }
    return hasL ? _Kind.l : (hasEn ? _Kind.en : _Kind.n);
  }

  double get centerX =>
      clusters.fold<double>(0, (s, c) => s + c.box.centerX) / clusters.length;
}

/// Reorders [text] (as extracted) using per-character [boxes]
/// (same length as text's UTF-16 code units).
String reorderArabicLines(String text, List<CharBox> boxes) {
  if (boxes.length != text.length) return text;
  final out = StringBuffer();
  var start = 0;
  for (var i = 0; i <= text.length; i++) {
    final atEnd = i == text.length;
    final c = atEnd ? 0 : text.codeUnitAt(i);
    if (atEnd || c == 0x0A || c == 0x0D) {
      out.write(_reorderLine(text.substring(start, i), boxes.sublist(start, i)));
      if (!atEnd) out.writeCharCode(c);
      start = i + 1;
    }
  }
  return out.toString();
}

bool _mostlyIncreasing(List<double> xs) {
  var inc = 0, dec = 0;
  for (var i = 1; i < xs.length; i++) {
    final d = xs[i] - xs[i - 1];
    if (d > 0.01) inc++;
    if (d < -0.01) dec++;
  }
  return inc > dec;
}

String _reorderLine(String line, List<CharBox> boxes) {
  if (!line.runes.any((r) => _kindOf(r) == _Kind.r)) return line;

  // Words split on spaces; characters grouped into glyph clusters.
  final words = <_Word>[];
  _Word? current;
  for (var i = 0; i < line.length; i++) {
    final c = line.codeUnitAt(i);
    if (_isSpace(c)) {
      current = null;
      continue;
    }
    current ??= (_Word([])..let(words.add));
    final b = boxes[i];
    final last = current.clusters.isEmpty ? null : current.clusters.last;
    // Low surrogates and characters sharing the previous glyph box join it.
    if (last != null &&
        ((c >= 0xDC00 && c <= 0xDFFF) ||
            ((last.box.left - b.left).abs() < 0.01 && (last.box.right - b.right).abs() < 0.01))) {
      last.text += line[i];
    } else {
      current.clusters.add(_Cluster(line[i], b));
    }
  }

  // 2. Fix letter order inside words.
  for (final w in words) {
    final cl = w.clusters;
    var i = 0;
    while (i < cl.length) {
      if (!cl[i].text.runes.any((r) => _kindOf(r) == _Kind.r)) {
        i++;
        continue;
      }
      var j = i;
      while (j + 1 < cl.length && cl[j + 1].text.runes.any((r) => _kindOf(r) == _Kind.r)) {
        j++;
      }
      if (j > i && _mostlyIncreasing([for (var k = i; k <= j; k++) cl[k].box.centerX])) {
        final run = cl.sublist(i, j + 1).reversed.toList();
        cl.replaceRange(i, j + 1, run);
      }
      i = j + 1;
    }
  }

  // 3. Fix word order when the Arabic words are in visual (left-to-right) order.
  final arabicXs = [for (final w in words) if (w.kind == _Kind.r) w.centerX];
  var ordered = words;
  if (arabicXs.length >= 2 && _mostlyIncreasing(arabicXs)) {
    // Sort by position (visual), then visual -> logical for an RTL line.
    final visual = List<_Word>.of(words)..sort((a, b) => a.centerX.compareTo(b.centerX));
    final logical = visual.reversed.toList();
    var i = 0;
    while (i < logical.length) {
      final k = logical[i].kind;
      if (k != _Kind.l && k != _Kind.en) {
        i++;
        continue;
      }
      var end = i;
      var j = i + 1;
      while (j < logical.length) {
        final kj = logical[j].kind;
        if (kj == _Kind.l || kj == _Kind.en) {
          end = j;
        } else if (kj != _Kind.n) {
          break;
        }
        j++;
      }
      logical.replaceRange(i, end + 1, logical.sublist(i, end + 1).reversed);
      i = end + 1;
    }
    ordered = logical;
  }
  return ordered.map((w) => w.text).join(' ');
}

extension<T> on T {
  T let(void Function(T) f) {
    f(this);
    return this;
  }
}
