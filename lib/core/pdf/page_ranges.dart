/// Parsing of page-range expressions like `1-3, 5, 8-10`.
///
/// Accepts Western (0-9) and Eastern Arabic (٠-٩) digits, the Arabic comma
/// (،) and common dash characters.
library;

enum RangeError { empty, syntax, outOfBounds, reversed }

class RangeParseException implements Exception {
  const RangeParseException(this.error, [this.token]);
  final RangeError error;
  final String? token;

  @override
  String toString() => 'RangeParseException($error, $token)';
}

/// A contiguous, 1-based, inclusive page range.
class PageRange {
  const PageRange(this.start, this.end);
  final int start;
  final int end;

  List<int> get pages => [for (var p = start; p <= end; p++) p];

  @override
  bool operator ==(Object other) =>
      other is PageRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => start == end ? '$start' : '$start-$end';
}

String normalizeDigits(String input) {
  final b = StringBuffer();
  for (final r in input.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      b.writeCharCode(0x30 + r - 0x0660); // Arabic-Indic
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      b.writeCharCode(0x30 + r - 0x06F0); // Extended (Persian)
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

/// Parses [text] into ranges, validating them against [pageCount].
/// Throws [RangeParseException].
List<PageRange> parsePageRanges(String text, int pageCount) {
  final normalized = normalizeDigits(text)
      .replaceAll('،', ',')
      .replaceAll('؛', ',')
      .replaceAll(';', ',')
      .replaceAll(RegExp('[‐-―−]'), '-');
  final parts = normalized
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty) throw const RangeParseException(RangeError.empty);
  final result = <PageRange>[];
  final single = RegExp(r'^(\d+)$');
  final span = RegExp(r'^(\d+)\s*-\s*(\d+)$');
  for (final part in parts) {
    int start;
    int end;
    final m1 = single.firstMatch(part);
    final m2 = span.firstMatch(part);
    if (m1 != null) {
      start = end = int.parse(m1.group(1)!);
    } else if (m2 != null) {
      start = int.parse(m2.group(1)!);
      end = int.parse(m2.group(2)!);
    } else {
      throw RangeParseException(RangeError.syntax, part);
    }
    if (start < 1 || end < 1 || start > pageCount || end > pageCount) {
      throw RangeParseException(RangeError.outOfBounds, part);
    }
    if (end < start) throw RangeParseException(RangeError.reversed, part);
    result.add(PageRange(start, end));
  }
  return result;
}

/// Sorted, de-duplicated page numbers from [ranges].
List<int> flattenRanges(List<PageRange> ranges) {
  final set = <int>{for (final r in ranges) ...r.pages};
  return set.toList()..sort();
}

/// Splits 1..pageCount into chunks of [every] pages.
List<PageRange> chunkPages(int pageCount, int every) {
  if (every < 1) throw ArgumentError.value(every, 'every');
  return [
    for (var s = 1; s <= pageCount; s += every)
      PageRange(s, (s + every - 1) > pageCount ? pageCount : s + every - 1),
  ];
}
