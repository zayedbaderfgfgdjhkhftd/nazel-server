import 'dart:typed_data';

import '../../core/files/naming.dart';
import '../../core/files/output_file.dart';
import '../../core/image/image_ops.dart';
import '../../core/jobs/job.dart';
import '../../core/pdf/page_ranges.dart';
import '../../core/pdf/pdf_service.dart';

enum SplitMode { ranges, everyN, eachPage }

class SplitOptions {
  const SplitOptions({this.mode = SplitMode.ranges, this.rangesText = '', this.everyN = 1});
  final SplitMode mode;
  final String rangesText;
  final int everyN;
}

/// Splits one PDF into several. One part -> a PDF; several -> a ZIP of PDFs.
Future<OutputFile> runSplit(InputFile input, SplitOptions options, JobContext ctx) async {
  final doc = await PdfService.openForEdit(input.bytes);
  try {
    final count = doc.pages.length;
    final groups = switch (options.mode) {
      SplitMode.ranges => parsePageRanges(options.rangesText, count),
      SplitMode.everyN => chunkPages(count, options.everyN),
      SplitMode.eachPage => chunkPages(count, 1),
    };
    final base = sanitizeFileBase(baseName(input.name));
    final parts = <String, Uint8List>{};
    for (var i = 0; i < groups.length; i++) {
      ctx.progress(i / groups.length, JobStage.file(i + 1, groups.length));
      final g = groups[i];
      final bytes = await PdfService.assemble([for (final p in g.pages) doc.pages[p - 1]]);
      await PdfService.verify(bytes, expectedPages: g.pages.length);
      final label = g.start == g.end ? 'page-${g.start}' : 'pages-${g.start}-${g.end}';
      parts[_unique(parts, '$base-$label.pdf')] = bytes;
    }
    ctx.progress(0.98, const JobStage.verifying());
    if (parts.length == 1) {
      final e = parts.entries.first;
      return OutputFile(name: e.key, bytes: e.value, pageCount: groups.first.pages.length);
    }
    return OutputFile(
      name: outputFileName(input.name, kToolFileSuffix['split']!, 'zip'),
      bytes: zipFiles(parts),
    );
  } finally {
    await doc.dispose();
  }
}

String _unique(Map<String, Object> existing, String name) {
  if (!existing.containsKey(name)) return name;
  final b = baseName(name);
  for (var i = 2;; i++) {
    final n = '$b-$i.pdf';
    if (!existing.containsKey(n)) return n;
  }
}
