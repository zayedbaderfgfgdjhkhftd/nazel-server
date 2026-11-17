import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../../app/services.dart';
import '../../components/common.dart';
import '../../components/file_pick.dart';
import '../../components/job_ui.dart';
import '../../components/l10n_ext.dart';
import '../../core/files/file_type.dart';
import '../../core/files/naming.dart';
import '../../core/image/platform_decode.dart';
import '../../core/pdf/pdf_service.dart';
import '../../design/tokens.dart';
import '../tools/tool_registry.dart';
import 'viewer_screen.dart';

/// Opens a file the user picked or shared (not yet in My files) in the right
/// viewer: PDFs in the PDF viewer, images in the image viewer.
Future<void> openInputInViewer(BuildContext context, InputFile f) async {
  final services = AppScope.of(context);
  final type = detectFileType(f.bytes.length > 1024 ? f.bytes.sublist(0, 1024) : f.bytes);
  if (type != DetectedType.pdf && !type.isImage) {
    await showErrorDialog(context, context.l10n.errUnsupportedType);
    return;
  }
  var bytes = f.bytes;
  var name = f.name;
  if (type == DetectedType.heic) {
    try {
      bytes = await heicToJpeg(bytes);
      name = '${baseName(name)}.jpg';
    } catch (e) {
      if (context.mounted) await showErrorDialog(context, errorMessage(context, e));
      return;
    }
  }
  // The viewers read from a file: keep a temporary copy (the original is
  // never touched).
  final dir = Directory(p.join(services.tempDir.path, 'view'));
  await dir.create(recursive: true);
  final ext = type == DetectedType.pdf ? 'pdf' : (type == DetectedType.heic ? 'jpg' : type.extension);
  final file = File(p.join(dir.path, '${DateTime.now().microsecondsSinceEpoch}.$ext'));
  await file.writeAsBytes(bytes, flush: true);
  if (!context.mounted) return;
  final source = InputFile(name, bytes);
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => type == DetectedType.pdf
        ? ViewerScreen(file: file, title: name, source: source)
        : ImageViewerScreen(file: file, title: name, source: source),
  ));
}

/// Lists the tools that accept [f] (PDF or image) and opens the chosen one.
Future<void> showFileToolsSheet(BuildContext context, InputFile f) async {
  final l = context.l10n;
  final type = detectFileType(f.bytes.length > 1024 ? f.bytes.sublist(0, 1024) : f.bytes);
  final isPdf = type == DetectedType.pdf;
  final tools = kTools.where((t) => isPdf
      ? (t.accepts == PickKind.pdf || t.accepts == PickKind.pdfOrImage)
      : (t.accepts == PickKind.image || t.accepts == PickKind.pdfOrImage));
  final chosen = await showModalBottomSheet<ToolId>(
    context: context,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.8),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
              child: Text(l.viewerTools, style: Theme.of(c).textTheme.titleLarge),
            ),
            for (final t in tools)
              ListTile(
                leading: IconTile(t.icon, size: 40),
                title: Text(toolName(c, t.id)),
                subtitle: Text(toolDescription(c, t.id), maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.of(c).pop(t.id),
              ),
          ],
        ),
      ),
    ),
  );
  if (chosen == null || !context.mounted) return;
  await openTool(context, chosen, initial: [f]);
}
