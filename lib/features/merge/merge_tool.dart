import 'package:pdfrx/pdfrx.dart';

import '../../core/errors.dart';
import '../../core/files/naming.dart';
import '../../core/files/output_file.dart';
import '../../core/jobs/job.dart';
import '../../core/pdf/pdf_service.dart';

/// Merges [inputs] (in order) into one PDF.
Future<OutputFile> runMerge(List<InputFile> inputs, JobContext ctx) async {
  if (inputs.length < 2) throw const AppException(AppErrorCode.nothingSelected);
  final docs = <PdfDocument>[];
  try {
    var expected = 0;
    for (var i = 0; i < inputs.length; i++) {
      ctx.progress(i / (inputs.length + 2), JobStage.file(i + 1, inputs.length));
      final d = await PdfService.openForEdit(inputs[i].bytes);
      docs.add(d);
      expected += d.pages.length;
    }
    ctx.progress(inputs.length / (inputs.length + 2));
    final bytes = await PdfService.assemble([for (final d in docs) ...d.pages]);
    ctx.progress(0.95, const JobStage.verifying());
    final n = await PdfService.verify(bytes, expectedPages: expected);
    return OutputFile(
      name: outputFileName(inputs.first.name, kToolFileSuffix['merge']!, 'pdf'),
      bytes: bytes,
      pageCount: n,
    );
  } finally {
    for (final d in docs) {
      await d.dispose();
    }
  }
}
