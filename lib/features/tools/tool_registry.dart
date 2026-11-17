import 'package:material_ui/material_ui.dart';

import '../../components/file_pick.dart';
import '../../components/l10n_ext.dart';
import '../../core/pdf/pdf_service.dart';
import '../compress/compress_screen.dart';
import '../extract/extract_screen.dart';
import '../file_info/file_info_screen.dart';
import '../images_to_pdf/images_to_pdf_screen.dart';
import '../merge/merge_screen.dart';
import '../ocr/ocr_screen.dart';
import '../organize/organize_screen.dart';
import '../page_numbers/page_numbers_screen.dart';
import '../pdf_to_images/pdf_to_images_screen.dart';
import '../signature/signature_screen.dart';
import '../split/split_screen.dart';
import '../text_extract/text_extract_screen.dart';
import '../watermark/watermark_screen.dart';

enum ToolId {
  merge,
  split,
  extract,
  organize,
  pdfToImages,
  imagesToPdf,
  watermark,
  pageNumbers,
  signature,
  textExtract,
  ocr,
  compress,
  fileInfo,
}

enum ToolGroup { organize, convert, edit, text, optimize }

class ToolDef {
  const ToolDef(this.id, this.icon, this.group, this.accepts);
  final ToolId id;
  final String icon;
  final ToolGroup group;

  /// What the tool takes as input (used for "use in a tool").
  final PickKind accepts;
}

const List<ToolDef> kTools = [
  ToolDef(ToolId.merge, 'merge', ToolGroup.organize, PickKind.pdf),
  ToolDef(ToolId.split, 'split', ToolGroup.organize, PickKind.pdf),
  ToolDef(ToolId.extract, 'extract', ToolGroup.organize, PickKind.pdf),
  ToolDef(ToolId.organize, 'organize', ToolGroup.organize, PickKind.pdf),
  ToolDef(ToolId.pdfToImages, 'pdfToImages', ToolGroup.convert, PickKind.pdf),
  ToolDef(ToolId.imagesToPdf, 'imagesToPdf', ToolGroup.convert, PickKind.image),
  ToolDef(ToolId.watermark, 'watermark', ToolGroup.edit, PickKind.pdf),
  ToolDef(ToolId.pageNumbers, 'pageNumbers', ToolGroup.edit, PickKind.pdf),
  ToolDef(ToolId.signature, 'signature', ToolGroup.edit, PickKind.pdf),
  ToolDef(ToolId.textExtract, 'textExtract', ToolGroup.text, PickKind.pdf),
  ToolDef(ToolId.ocr, 'ocr', ToolGroup.text, PickKind.pdfOrImage),
  ToolDef(ToolId.compress, 'compress', ToolGroup.optimize, PickKind.pdf),
  ToolDef(ToolId.fileInfo, 'info', ToolGroup.optimize, PickKind.pdf),
];

ToolDef toolDef(ToolId id) => kTools.firstWhere((t) => t.id == id);

String toolName(BuildContext context, ToolId id) {
  final l = context.l10n;
  return switch (id) {
    ToolId.merge => l.toolMerge,
    ToolId.split => l.toolSplit,
    ToolId.extract => l.toolExtract,
    ToolId.organize => l.toolOrganize,
    ToolId.pdfToImages => l.toolPdfToImages,
    ToolId.imagesToPdf => l.toolImagesToPdf,
    ToolId.watermark => l.toolWatermark,
    ToolId.pageNumbers => l.toolPageNumbers,
    ToolId.signature => l.toolSignature,
    ToolId.textExtract => l.toolTextExtract,
    ToolId.ocr => l.toolOcr,
    ToolId.compress => l.toolCompress,
    ToolId.fileInfo => l.toolFileInfo,
  };
}

String toolDescription(BuildContext context, ToolId id) {
  final l = context.l10n;
  return switch (id) {
    ToolId.merge => l.toolMergeDesc,
    ToolId.split => l.toolSplitDesc,
    ToolId.extract => l.toolExtractDesc,
    ToolId.organize => l.toolOrganizeDesc,
    ToolId.pdfToImages => l.toolPdfToImagesDesc,
    ToolId.imagesToPdf => l.toolImagesToPdfDesc,
    ToolId.watermark => l.toolWatermarkDesc,
    ToolId.pageNumbers => l.toolPageNumbersDesc,
    ToolId.signature => l.toolSignatureDesc,
    ToolId.textExtract => l.toolTextExtractDesc,
    ToolId.ocr => l.toolOcrDesc,
    ToolId.compress => l.toolCompressDesc,
    ToolId.fileInfo => l.toolFileInfoDesc,
  };
}

String groupName(BuildContext context, ToolGroup g) {
  final l = context.l10n;
  return switch (g) {
    ToolGroup.organize => l.groupOrganize,
    ToolGroup.convert => l.groupConvert,
    ToolGroup.edit => l.groupEdit,
    ToolGroup.text => l.groupText,
    ToolGroup.optimize => l.groupOptimize,
  };
}

/// Display name for the tool that produced a stored file.
String producerName(BuildContext context, String toolId) {
  if (toolId == 'import') return context.l10n.toolImported;
  if (toolId == 'shared') return context.l10n.toolShared;
  for (final t in ToolId.values) {
    if (t.name == toolId) return toolName(context, t);
  }
  return toolId;
}

Widget buildToolScreen(ToolId id, List<InputFile> initial) => switch (id) {
      ToolId.merge => MergeScreen(initial: initial),
      ToolId.split => SplitScreen(initial: initial),
      ToolId.extract => ExtractScreen(initial: initial),
      ToolId.organize => OrganizeScreen(initial: initial),
      ToolId.pdfToImages => PdfToImagesScreen(initial: initial),
      ToolId.imagesToPdf => ImagesToPdfScreen(initial: initial),
      ToolId.watermark => WatermarkScreen(initial: initial),
      ToolId.pageNumbers => PageNumbersScreen(initial: initial),
      ToolId.signature => SignatureScreen(initial: initial),
      ToolId.textExtract => TextExtractScreen(initial: initial),
      ToolId.ocr => OcrScreen(initial: initial),
      ToolId.compress => CompressScreen(initial: initial),
      ToolId.fileInfo => FileInfoScreen(initial: initial),
    };

Future<void> openTool(BuildContext context, ToolId id, {List<InputFile> initial = const []}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => buildToolScreen(id, initial)));
