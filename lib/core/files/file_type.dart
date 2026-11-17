import 'dart:typed_data';

/// File types recognised by their first bytes ("magic bytes"), never by the
/// extension alone.
enum DetectedType { pdf, jpeg, png, webp, heic, zip, unknown }

extension DetectedTypeX on DetectedType {
  bool get isImage =>
      this == DetectedType.jpeg ||
      this == DetectedType.png ||
      this == DetectedType.webp ||
      this == DetectedType.heic;

  String get mime => switch (this) {
        DetectedType.pdf => 'application/pdf',
        DetectedType.jpeg => 'image/jpeg',
        DetectedType.png => 'image/png',
        DetectedType.webp => 'image/webp',
        DetectedType.heic => 'image/heic',
        DetectedType.zip => 'application/zip',
        DetectedType.unknown => 'application/octet-stream',
      };

  String get extension => switch (this) {
        DetectedType.pdf => 'pdf',
        DetectedType.jpeg => 'jpg',
        DetectedType.png => 'png',
        DetectedType.webp => 'webp',
        DetectedType.heic => 'heic',
        DetectedType.zip => 'zip',
        DetectedType.unknown => 'bin',
      };
}

const _heifBrands = {
  'heic', 'heix', 'hevc', 'hevx', 'heim', 'heis', 'hevm', 'hevs', //
  'mif1', 'msf1', 'avif', 'avis',
};

/// Detects the type of [bytes] from its signature. Needs at most the first
/// 1 KB of the file.
DetectedType detectFileType(Uint8List bytes) {
  if (bytes.length < 4) return DetectedType.unknown;
  if (_startsWith(bytes, const [0xFF, 0xD8, 0xFF])) return DetectedType.jpeg;
  if (_startsWith(bytes, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return DetectedType.png;
  }
  if (bytes.length >= 12 &&
      _ascii(bytes, 0, 4) == 'RIFF' &&
      _ascii(bytes, 8, 4) == 'WEBP') {
    return DetectedType.webp;
  }
  if (bytes.length >= 12 && _ascii(bytes, 4, 4) == 'ftyp') {
    final brand = _ascii(bytes, 8, 4);
    if (_heifBrands.contains(brand)) return DetectedType.heic;
  }
  if (_startsWith(bytes, const [0x50, 0x4B, 0x03, 0x04])) return DetectedType.zip;
  // PDF readers accept a header anywhere in the first 1024 bytes.
  final limit = bytes.length < 1024 ? bytes.length : 1024;
  for (var i = 0; i + 5 <= limit; i++) {
    if (bytes[i] == 0x25 && // %
        bytes[i + 1] == 0x50 && // P
        bytes[i + 2] == 0x44 && // D
        bytes[i + 3] == 0x46 && // F
        bytes[i + 4] == 0x2D) {
      return DetectedType.pdf;
    }
  }
  return DetectedType.unknown;
}

bool _startsWith(Uint8List b, List<int> sig) {
  if (b.length < sig.length) return false;
  for (var i = 0; i < sig.length; i++) {
    if (b[i] != sig[i]) return false;
  }
  return true;
}

String _ascii(Uint8List b, int start, int len) {
  if (b.length < start + len) return '';
  return String.fromCharCodes(b.sublist(start, start + len));
}

/// Quick structural sanity check for PDF output: header + EOF marker.
bool looksLikeCompletePdf(Uint8List bytes) {
  if (bytes.length < 64 || detectFileType(bytes) != DetectedType.pdf) {
    return false;
  }
  final tailStart = bytes.length > 2048 ? bytes.length - 2048 : 0;
  final tail = String.fromCharCodes(bytes.sublist(tailStart));
  return tail.contains('%%EOF');
}
