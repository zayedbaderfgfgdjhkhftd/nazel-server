/// Output file naming: `<original-name>-<tool>.<ext>`, e.g.
/// `contract-compressed.pdf`.
library;

final _illegal = RegExp(r'[\\/:*?"<>|\x00-\x1F]');
final _spaces = RegExp(r'\s+');

/// Removes the extension from [fileName] ("a.b.pdf" -> "a.b").
String baseName(String fileName) {
  final slash = fileName.lastIndexOf(RegExp(r'[\\/]'));
  final name = slash >= 0 ? fileName.substring(slash + 1) : fileName;
  final dot = name.lastIndexOf('.');
  if (dot < 0) return name;
  // ".pdf" is just an extension: the base is empty.
  return name.substring(0, dot);
}

/// Returns the lower-case extension without the dot, or '' if none.
String extensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return '';
  return fileName.substring(dot + 1).toLowerCase();
}

/// Makes [name] safe for every common file system while keeping Arabic and
/// other letters intact.
String sanitizeFileBase(String name) {
  var s = name.replaceAll(_illegal, '_').replaceAll(_spaces, ' ').trim();
  // Leading/trailing dots and spaces are troublesome on some systems.
  s = s.replaceAll(RegExp(r'^[ .]+|[ .]+$'), '');
  if (s.length > 120) s = s.substring(0, 120).trim();
  return s.isEmpty ? 'satr' : s;
}

/// `<original-base>-<suffix>.<ext>`.
String outputFileName(String originalName, String suffix, String ext) {
  final base = sanitizeFileBase(baseName(originalName));
  final cleanSuffix = suffix.isEmpty ? '' : '-${sanitizeFileBase(suffix)}';
  return '$base$cleanSuffix.$ext';
}

/// Keeps the extension of [current] when the user renames to [newBase].
String renamedFileName(String current, String newBase) {
  final ext = extensionOf(current);
  final base = sanitizeFileBase(baseName(newBase));
  return ext.isEmpty ? base : '$base.$ext';
}

/// Tool ids used as file-name suffixes (always Latin, so names stay portable).
const Map<String, String> kToolFileSuffix = {
  'merge': 'merged',
  'split': 'split',
  'extract': 'extracted',
  'organize': 'organized',
  'compress': 'compressed',
  'pdfToImages': 'page',
  'imagesToPdf': 'images',
  'watermark': 'watermarked',
  'pageNumbers': 'numbered',
  'signature': 'signed',
  'textExtract': 'text',
  'ocr': 'ocr',
  'fileInfo': 'clean',
};
