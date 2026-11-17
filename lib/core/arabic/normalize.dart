/// Arabic-aware text normalisation for search.
///
/// - removes diacritics (tashkeel) and tatweel
/// - treats أ / إ / آ / ٱ / ا as the same letter
/// - treats ة / ه and ى / ي as the same letter
/// - converts Eastern Arabic digits to Western digits
/// - lower-cases Latin letters and collapses whitespace
library;

String normalizeForSearch(String input) {
  final b = StringBuffer();
  for (final r in input.runes) {
    // Tashkeel U+064B..U+065F, superscript alef U+0670, tatweel U+0640,
    // Quranic marks U+06D6..U+06ED.
    if ((r >= 0x064B && r <= 0x065F) ||
        r == 0x0670 ||
        r == 0x0640 ||
        (r >= 0x06D6 && r <= 0x06ED)) {
      continue;
    }
    switch (r) {
      case 0x0623: // أ
      case 0x0625: // إ
      case 0x0622: // آ
      case 0x0671: // ٱ
        b.writeCharCode(0x0627); // ا
      case 0x0629: // ة
        b.writeCharCode(0x0647); // ه
      case 0x0649: // ى
        b.writeCharCode(0x064A); // ي
      default:
        if (r >= 0x0660 && r <= 0x0669) {
          b.writeCharCode(0x30 + r - 0x0660);
        } else if (r >= 0x06F0 && r <= 0x06F9) {
          b.writeCharCode(0x30 + r - 0x06F0);
        } else {
          b.writeCharCode(r);
        }
    }
  }
  return b.toString().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// True if [haystack] contains [needle] after normalising both.
bool searchMatches(String haystack, String needle) {
  final n = normalizeForSearch(needle);
  if (n.isEmpty) return true;
  return normalizeForSearch(haystack).contains(n);
}

/// Converts Western digits to Eastern Arabic digits (١٢٣).
String toEasternArabicDigits(String input) {
  final b = StringBuffer();
  for (final r in input.runes) {
    if (r >= 0x30 && r <= 0x39) {
      b.writeCharCode(0x0660 + r - 0x30);
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

/// True if the first strong directional character is right-to-left.
bool isRtlText(String text) {
  for (final r in text.runes) {
    if ((r >= 0x0590 && r <= 0x08FF) ||
        (r >= 0xFB1D && r <= 0xFDFF) ||
        (r >= 0xFE70 && r <= 0xFEFF)) {
      return true;
    }
    if ((r >= 0x41 && r <= 0x5A) ||
        (r >= 0x61 && r <= 0x7A) ||
        (r >= 0xC0 && r <= 0x24F)) {
      return false;
    }
  }
  return false;
}
