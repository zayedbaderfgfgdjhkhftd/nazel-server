import 'dart:typed_data';

/// Broad file categories used by "My files" filters.
enum FileKind { pdf, image, text, zip, docx, other }

FileKind kindFromName(String name) {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  return switch (ext) {
    'pdf' => FileKind.pdf,
    'jpg' || 'jpeg' || 'png' || 'webp' || 'heic' || 'heif' => FileKind.image,
    'txt' => FileKind.text,
    'zip' => FileKind.zip,
    'docx' => FileKind.docx,
    _ => FileKind.other,
  };
}

String mimeFromName(String name) {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  return switch (ext) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' || 'heif' => 'image/heic',
    'txt' => 'text/plain',
    'zip' => 'application/zip',
    'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    _ => 'application/octet-stream',
  };
}

/// A file produced by a tool, before it is stored.
class OutputFile {
  OutputFile({required this.name, required this.bytes, this.pageCount});

  final String name;
  final Uint8List bytes;

  /// Verified page count for PDFs (null for other types).
  final int? pageCount;

  FileKind get kind => kindFromName(name);
  String get mime => mimeFromName(name);
  int get size => bytes.length;
}
