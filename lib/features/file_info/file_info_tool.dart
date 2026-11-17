import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import '../../core/errors.dart';
import '../../core/files/file_type.dart';
import '../../core/files/naming.dart';
import '../../core/files/output_file.dart';
import '../../core/jobs/job.dart';
import '../../core/pdf/pdf_service.dart';
import '../../core/pdf/pdfium_native.dart';

class PdfInfo {
  PdfInfo({
    required this.pageCount,
    required this.pageSizes,
    required this.fileSize,
    required this.version,
    required this.meta,
    required this.encrypted,
  });

  final int pageCount;

  /// Distinct page sizes in points, with how many pages use each.
  final Map<({int w, int h}), int> pageSizes;
  final int fileSize;
  final String? version;
  final Map<String, String> meta;
  final bool encrypted;
}

/// Reads page count, sizes, version, metadata and encryption state.
/// Encrypted files that open without a password are still described.
Future<PdfInfo> readPdfInfo(Uint8List bytes) async {
  if (detectFileType(bytes) != DetectedType.pdf) throw const AppException(AppErrorCode.notPdf);
  PdfDocument doc;
  try {
    doc = await PdfDocument.openData(bytes,
        sourceName: PdfService.sourceName('info'), passwordProvider: () => null);
  } on PdfPasswordException {
    return PdfInfo(
      pageCount: 0,
      pageSizes: const {},
      fileSize: bytes.length,
      version: _headerVersion(bytes),
      meta: const {},
      encrypted: true,
    );
  } catch (e) {
    throw AppException(AppErrorCode.corrupt, e);
  }
  try {
    final sizes = <({int w, int h}), int>{};
    for (final p in doc.pages) {
      final k = (w: p.width.round(), h: p.height.round());
      sizes[k] = (sizes[k] ?? 0) + 1;
    }
    final native = await readNativeInfo(doc);
    return PdfInfo(
      pageCount: doc.pages.length,
      pageSizes: sizes,
      fileSize: bytes.length,
      version: native.version ?? _headerVersion(bytes),
      meta: native.meta,
      encrypted: doc.isEncrypted,
    );
  } finally {
    await doc.dispose();
  }
}

String? _headerVersion(Uint8List bytes) {
  final head = String.fromCharCodes(bytes.take(1024));
  return RegExp(r'%PDF-(\d\.\d)').firstMatch(head)?.group(1);
}

/// Creates a copy without document metadata (Info dictionary and XMP).
///
/// The pages are copied into a fresh document; document-level extras such as
/// bookmarks and form fields are not carried over (the UI says so).
Future<OutputFile> runClearMetadata(InputFile input, JobContext ctx) async {
  final doc = await PdfService.openForEdit(input.bytes);
  try {
    ctx.progress(0.3);
    final bytes = await PdfService.assemble(doc.pages);
    ctx.progress(0.8, const JobStage.verifying());
    final n = await PdfService.verify(bytes, expectedPages: doc.pages.length);
    return OutputFile(
      name: outputFileName(input.name, kToolFileSuffix['fileInfo']!, 'pdf'),
      bytes: bytes,
      pageCount: n,
    );
  } finally {
    await doc.dispose();
  }
}

/// Common paper names for display.
String? paperName(int w, int h) {
  final a = w < h ? w : h;
  final b = w < h ? h : w;
  bool near(int x, int y) => (x - y).abs() <= 3;
  if (near(a, 595) && near(b, 842)) return 'A4';
  if (near(a, 612) && near(b, 792)) return 'Letter';
  if (near(a, 612) && near(b, 1008)) return 'Legal';
  if (near(a, 420) && near(b, 595)) return 'A5';
  if (near(a, 842) && near(b, 1191)) return 'A3';
  return null;
}
