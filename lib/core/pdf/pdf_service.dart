import 'dart:typed_data';

import 'package:pdf/pdf.dart' as pg;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart';

import '../errors.dart';
import '../files/file_type.dart';

/// An input file as picked by the user.
class InputFile {
  InputFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

/// Thin, testable wrapper around pdfrx (PDFium) for document-level work.
class PdfService {
  PdfService._();

  static int _seq = 0;

  /// pdfrx requires a unique source name per opened document.
  static String sourceName(String tag) =>
      'satr-$tag-${_seq++}-${DateTime.now().microsecondsSinceEpoch}';

  /// Opens [bytes] for an editing tool.
  ///
  /// Throws [AppException] with [AppErrorCode.encrypted] for protected files
  /// (editing tools don't process them in v1) and [AppErrorCode.corrupt] for
  /// damaged ones.
  static Future<PdfDocument> openForEdit(Uint8List bytes) async {
    if (bytes.isEmpty) throw const AppException(AppErrorCode.emptyFile);
    if (detectFileType(bytes) != DetectedType.pdf) {
      throw const AppException(AppErrorCode.notPdf);
    }
    PdfDocument doc;
    try {
      doc = await PdfDocument.openData(
        bytes,
        sourceName: sourceName('in'),
        passwordProvider: () => null,
      );
    } on PdfPasswordException catch (e) {
      throw AppException(AppErrorCode.encrypted, e);
    } catch (e) {
      throw AppException(AppErrorCode.corrupt, e);
    }
    if (doc.isEncrypted) {
      await doc.dispose();
      throw const AppException(AppErrorCode.encrypted);
    }
    if (doc.pages.isEmpty) {
      await doc.dispose();
      throw const AppException(AppErrorCode.corrupt, 'no pages');
    }
    return doc;
  }

  /// Returns true if [bytes] is a password-protected PDF (any security handler).
  static Future<bool> isEncrypted(Uint8List bytes) async {
    try {
      final doc = await PdfDocument.openData(
        bytes,
        sourceName: sourceName('probe'),
        passwordProvider: () => null,
      );
      final enc = doc.isEncrypted;
      await doc.dispose();
      return enc;
    } on PdfPasswordException {
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Verifies a produced PDF: it must have a valid structure, open in PDFium,
  /// be non-empty and (optionally) have exactly [expectedPages] pages.
  /// Returns the page count.
  static Future<int> verify(Uint8List bytes, {int? expectedPages}) async {
    if (!looksLikeCompletePdf(bytes)) {
      throw const AppException(AppErrorCode.outputInvalid, 'structure');
    }
    PdfDocument doc;
    try {
      doc = await PdfDocument.openData(bytes, sourceName: sourceName('verify'));
    } catch (e) {
      throw AppException(AppErrorCode.outputInvalid, e);
    }
    try {
      final n = doc.pages.length;
      if (n == 0) throw const AppException(AppErrorCode.outputInvalid, 'no pages');
      if (expectedPages != null && n != expectedPages) {
        throw AppException(AppErrorCode.outputInvalid, 'pages $n != $expectedPages');
      }
      return n;
    } finally {
      await doc.dispose();
    }
  }

  /// Builds a new PDF from [pages] (which may come from several open
  /// documents) and returns its bytes. Sources must stay open until this
  /// returns.
  static Future<Uint8List> assemble(List<PdfPage> pages) async {
    final out = await PdfDocument.createNew(sourceName: sourceName('out'));
    try {
      out.pages = pages;
      return await out.encodePdf();
    } finally {
      await out.dispose();
    }
  }

  /// Creates a PDF with blank pages of the given sizes (points).
  static Future<Uint8List> blankPagesPdf(List<({double width, double height})> sizes) async {
    final doc = pw.Document(compress: true);
    for (final s in sizes) {
      doc.addPage(pw.Page(
        pageFormat: pg.PdfPageFormat(s.width, s.height),
        build: (_) => pw.SizedBox(),
      ));
    }
    return doc.save();
  }
}

/// Standard paper sizes in points.
class PaperSizes {
  static const a4 = (width: 595.2756, height: 841.8898);
  static const letter = (width: 612.0, height: 792.0);
}
