import 'package:pdfrx/pdfrx.dart';

import '../../core/errors.dart';
import '../../core/files/naming.dart';
import '../../core/files/output_file.dart';
import '../../core/jobs/job.dart';
import '../../core/pdf/pdf_service.dart';

/// One page in the organized result.
sealed class OrganizeItem {
  const OrganizeItem({this.quarterTurns = 0});

  /// Extra clockwise rotation in 90-degree steps (0..3).
  final int quarterTurns;

  OrganizeItem rotated(int deltaTurns);
}

/// A page taken from the source document (0-based index).
class SourcePage extends OrganizeItem {
  const SourcePage(this.index, {super.quarterTurns});
  final int index;

  @override
  SourcePage rotated(int deltaTurns) =>
      SourcePage(index, quarterTurns: (quarterTurns + deltaTurns) % 4);
}

/// A new blank page of the given size in points.
class BlankPage extends OrganizeItem {
  const BlankPage(this.width, this.height, {super.quarterTurns});
  final double width;
  final double height;

  @override
  BlankPage rotated(int deltaTurns) =>
      BlankPage(width, height, quarterTurns: (quarterTurns + deltaTurns) % 4);
}

/// Builds a new PDF from [items]: reordered, rotated, duplicated, deleted
/// (simply absent) and blank pages.
Future<OutputFile> runOrganize(InputFile input, List<OrganizeItem> items, JobContext ctx) async {
  if (items.isEmpty) throw const AppException(AppErrorCode.nothingSelected);
  final src = await PdfService.openForEdit(input.bytes);
  PdfDocument? blanks;
  try {
    ctx.progress(0.1);
    final blankItems = items.whereType<BlankPage>().toList();
    if (blankItems.isNotEmpty) {
      final bytes = await PdfService.blankPagesPdf(
          [for (final b in blankItems) (width: b.width, height: b.height)]);
      blanks = await PdfDocument.openData(bytes, sourceName: PdfService.sourceName('blank'));
    }
    var blankIdx = 0;
    final pages = <PdfPage>[];
    for (final item in items) {
      final PdfPage base = switch (item) {
        SourcePage(:final index) => src.pages[index],
        BlankPage() => blanks!.pages[blankIdx++],
      };
      pages.add(item.quarterTurns % 4 == 0
          ? base
          : base.rotatedBy(PdfPageRotation.values[item.quarterTurns % 4]));
    }
    ctx.progress(0.4);
    final out = await PdfService.assemble(pages);
    ctx.progress(0.9, const JobStage.verifying());
    final n = await PdfService.verify(out, expectedPages: items.length);
    return OutputFile(
      name: outputFileName(input.name, kToolFileSuffix['organize']!, 'pdf'),
      bytes: out,
      pageCount: n,
    );
  } finally {
    await blanks?.dispose();
    await src.dispose();
  }
}
