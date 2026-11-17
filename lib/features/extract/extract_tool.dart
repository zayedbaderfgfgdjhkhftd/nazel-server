import '../../core/errors.dart';
import '../../core/files/naming.dart';
import '../../core/files/output_file.dart';
import '../../core/jobs/job.dart';
import '../../core/pdf/pdf_service.dart';

/// Copies the selected 1-based [pages] (in the given order) into a new PDF.
Future<OutputFile> runExtract(InputFile input, List<int> pages, JobContext ctx) async {
  if (pages.isEmpty) throw const AppException(AppErrorCode.nothingSelected);
  final doc = await PdfService.openForEdit(input.bytes);
  try {
    ctx.progress(0.2);
    for (final p in pages) {
      if (p < 1 || p > doc.pages.length) {
        throw AppException(AppErrorCode.generic, 'page $p out of range');
      }
    }
    final bytes = await PdfService.assemble([for (final p in pages) doc.pages[p - 1]]);
    ctx.progress(0.9, const JobStage.verifying());
    final n = await PdfService.verify(bytes, expectedPages: pages.length);
    return OutputFile(
      name: outputFileName(input.name, kToolFileSuffix['extract']!, 'pdf'),
      bytes: bytes,
      pageCount: n,
    );
  } finally {
    await doc.dispose();
  }
}
