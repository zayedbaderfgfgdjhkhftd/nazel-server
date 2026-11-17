import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../../app/services.dart';
import '../../components/common.dart';
import '../../components/l10n_ext.dart';
import '../../core/files/output_file.dart';
import '../../core/pdf/pdf_service.dart';
import '../../core/share/share_service.dart';
import '../../core/storage/file_store.dart';
import '../../design/icons.dart';
import '../../design/tokens.dart';
import '../tools/tool_registry.dart';
import '../viewer/viewer_screen.dart';

/// Opens a stored file with the right in-app viewer.
Future<void> openStoredFile(BuildContext context, StoredFile f) async {
  final store = AppScope.of(context).files;
  final file = store.fileOf(f);
  switch (f.kind) {
    case FileKind.pdf:
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ViewerScreen(file: file, title: f.name)));
    case FileKind.image:
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ImageViewerScreen(file: file, title: f.name)));
    case FileKind.text:
      final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
      if (!context.mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => TextViewerScreen(text: text, title: f.name)));
    case FileKind.zip:
    case FileKind.docx:
    case FileKind.other:
      await showFileActions(context, f);
  }
}

Future<void> shareStoredFile(BuildContext context, StoredFile f) async {
  final store = AppScope.of(context).files;
  final ok = await ShareService.shareFile(store.fileOf(f), f.name);
  if (!ok && context.mounted) await saveStoredFile(context, f);
}

Future<void> saveStoredFile(BuildContext context, StoredFile f) async {
  final store = AppScope.of(context).files;
  final saved = await ShareService.saveToDevice(f.name, await store.readBytes(f));
  if (saved && context.mounted) showMessage(context, context.l10n.savedToDevice);
}

/// Picks a compatible tool and opens it with [f] as input.
Future<void> useInTool(BuildContext context, StoredFile f) async {
  final tools = kTools.where((t) => switch (f.kind) {
        FileKind.pdf => t.accepts.name.contains('pdf') || t.accepts.name == 'pdfOrImage',
        FileKind.image => t.accepts.name == 'image' || t.accepts.name == 'pdfOrImage',
        _ => false,
      });
  final chosen = await showModalBottomSheet<ToolId>(
    context: context,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.75),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final t in tools)
              ListTile(
                leading: IconTile(t.icon, size: 40),
                title: Text(toolName(c, t.id)),
                onTap: () => Navigator.of(c).pop(t.id),
              ),
          ],
        ),
      ),
    ),
  );
  if (chosen == null || !context.mounted) return;
  final bytes = await AppScope.of(context).files.readBytes(f);
  if (!context.mounted) return;
  await openTool(context, chosen, initial: [InputFile(f.name, bytes)]);
}

/// Bottom sheet with every action for a stored file.
Future<void> showFileActions(BuildContext context, StoredFile f, {VoidCallback? onRename}) async {
  final l = context.l10n;
  final store = AppScope.of(context).files;
  final c = SatrColors.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              child: Text(f.name, style: Theme.of(sheet).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
              child: Text(
                '${kindLabel(sheet, f.kind)} · ${formatBytes(sheet, f.size)} · ${producerName(sheet, f.tool)}',
                style: Theme.of(sheet).textTheme.bodySmall,
              ),
            ),
            if (f.kind == FileKind.pdf || f.kind == FileKind.image || f.kind == FileKind.text)
              _action(sheet, 'eye', l.open, () => openStoredFile(context, f)),
            _action(sheet, 'share', l.share, () => shareStoredFile(context, f)),
            _action(sheet, 'download', l.saveToDevice, () => saveStoredFile(context, f)),
            if (f.kind == FileKind.pdf || f.kind == FileKind.image)
              _action(sheet, 'tools', l.useInTool, () => useInTool(context, f)),
            _action(sheet, 'pencil', l.rename, () => renameStoredFile(context, f)),
            _action(sheet, 'star', f.favorite ? l.unfavorite : l.favorite,
                () => store.setFavorite(f.id, !f.favorite)),
            _action(sheet, 'trash', l.moveToTrash, () => trashWithUndo(context, [f.id]), color: c.danger),
            const SizedBox(height: Space.s),
          ],
        ),
      ),
    ),
  );
}

Widget _action(BuildContext sheet, String icon, String label, VoidCallback onTap, {Color? color}) => ListTile(
      leading: SatrIcon(icon, color: color),
      title: Text(label, style: color == null ? null : TextStyle(color: color)),
      onTap: () {
        Navigator.of(sheet).pop();
        onTap();
      },
    );

Future<void> renameStoredFile(BuildContext context, StoredFile f) async {
  final l = context.l10n;
  final ctrl = TextEditingController(text: f.name.contains('.') ? f.name.substring(0, f.name.lastIndexOf('.')) : f.name);
  final name = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(l.renameTitle),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(labelText: l.nameLabel),
        onSubmitted: (v) => Navigator.of(c).pop(v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(c).pop(), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.of(c).pop(ctrl.text), child: Text(l.save)),
      ],
    ),
  );
  if (name != null && name.trim().isNotEmpty && context.mounted) {
    await AppScope.of(context).files.rename(f.id, name.trim());
  }
}

Future<void> trashWithUndo(BuildContext context, List<String> ids) async {
  final store = AppScope.of(context).files;
  final l = context.l10n;
  await store.moveToTrash(ids);
  if (!context.mounted) return;
  showMessage(context, l.movedToTrash,
      action: SnackBarAction(label: l.undo, onPressed: () => store.restore(ids)));
}
