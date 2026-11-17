import 'package:material_ui/material_ui.dart';

import '../../app/services.dart';
import '../../components/common.dart';
import '../../components/file_pick.dart';
import '../../components/l10n_ext.dart';
import '../../core/files/file_type.dart';
import '../../core/files/output_file.dart';
import '../../core/pdf/pdf_service.dart';
import '../../core/storage/file_store.dart';
import '../../design/icons.dart';
import '../../design/tokens.dart';
import '../files/file_actions.dart';
import '../tools/tool_registry.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onSeeAllFiles});
  final VoidCallback onSeeAllFiles;

  String _greeting(BuildContext context) {
    final h = DateTime.now().hour;
    final l = context.l10n;
    if (h >= 5 && h < 12) return l.greetingMorning;
    if (h >= 12 && h < 17) return l.greetingAfternoon;
    return l.greetingEvening;
  }

  Future<void> _pickAny(BuildContext context) async {
    final picked = await pickFromDevice(context, kind: PickKind.pdfOrImage);
    if (picked.isEmpty || !context.mounted) return;
    await chooseToolFor(context, picked.first);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = SatrColors.of(context);
    final store = AppScope.of(context).files;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final recent = store.query().take(5).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.xl),
              children: [
                MaxWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/brand/icon-192.png', width: 40, height: 40),
                          const SizedBox(width: Space.m),
                          Expanded(
                            child: Text(context.appName, style: Theme.of(context).textTheme.titleLarge),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.xl),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: HighlightTitle(_greeting(context),
                            style: Theme.of(context).textTheme.headlineMedium),
                      ),
                      const SizedBox(height: Space.l),
                      Semantics(
                        button: true,
                        label: l.homePickTitle,
                        child: InkWell(
                          onTap: () => _pickAny(context),
                          borderRadius: BorderRadius.circular(Radii.card),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: Space.xxl, horizontal: Space.l),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(Radii.card),
                              border: Border.all(color: c.line, width: 1.5),
                            ),
                            child: Column(
                              children: [
                                const IconTile('upload', size: 64, highlighted: true),
                                const SizedBox(height: Space.m),
                                Text(l.homePickTitle, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: Space.xs),
                                Text(l.homePickSubtitle,
                                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c.textMuted)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.s),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SatrIcon('privacy', size: 18, color: c.success),
                          const SizedBox(width: Space.xs),
                          Text(l.privacyLine, style: Theme.of(context).textTheme.bodySmall!.copyWith(color: c.textMuted)),
                        ],
                      ),
                      const SizedBox(height: Space.xl),
                      Text(l.homeQuickActions, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: Space.m),
                      GridView.count(
                        crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: Space.m,
                        crossAxisSpacing: Space.m,
                        childAspectRatio: 2.4,
                        children: [
                          for (final id in const [ToolId.merge, ToolId.compress, ToolId.imagesToPdf, ToolId.ocr])
                            _QuickAction(id: id),
                        ],
                      ),
                      const SizedBox(height: Space.xl),
                      Row(
                        children: [
                          Expanded(child: Text(l.homeRecent, style: Theme.of(context).textTheme.titleMedium)),
                          if (recent.isNotEmpty) TextButton(onPressed: onSeeAllFiles, child: Text(l.homeSeeAll)),
                        ],
                      ),
                      if (recent.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: Space.l),
                          child: Text(l.homeEmptyRecent,
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c.textMuted)),
                        )
                      else
                        for (final f in recent) FileRow(file: f),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.id});
  final ToolId id;

  @override
  Widget build(BuildContext context) {
    final def = toolDef(id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openTool(context, id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.m),
          child: Row(
            children: [
              IconTile(def.icon, size: 36),
              const SizedBox(width: Space.s),
              Expanded(
                child: Text(toolName(context, id),
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One file in a list (home, My files).
class FileRow extends StatelessWidget {
  const FileRow({super.key, required this.file, this.selected, this.onTap, this.onLongPress, this.trailing});
  final StoredFile file;
  final bool? selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = SatrColors.of(context);
    final icon = switch (file.kind) {
      FileKind.pdf => 'fileText',
      FileKind.image => 'image',
      FileKind.zip => 'archive',
      FileKind.text || FileKind.docx => 'textExtract',
      FileKind.other => 'file',
    };
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(start: Space.s, end: 0),
      tileColor: selected == true ? c.accent.withValues(alpha: 0.3) : null,
      leading: selected == null
          ? IconTile(icon, size: 40)
          : Checkbox(value: selected, onChanged: (_) => onTap?.call()),
      title: Row(
        children: [
          Flexible(child: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (file.favorite) ...[
            const SizedBox(width: 4),
            SatrIcon('star', size: 14, color: c.textMuted),
          ],
        ],
      ),
      subtitle: Text(
        '${formatBytes(context, file.size)} · ${formatDate(context, file.createdAt)} · ${producerName(context, file.tool)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ??
          IconButton(
            tooltip: context.l10n.more,
            icon: const SatrIcon('more'),
            onPressed: () => showFileActions(context, file),
          ),
      onTap: onTap ?? () => openStoredFile(context, file),
      onLongPress: onLongPress,
    );
  }
}

/// After picking a file from the home screen: suggest matching tools.
Future<void> chooseToolFor(BuildContext context, InputFile f, {bool offerSave = false}) async {
  final l = context.l10n;
  final isPdf = detectFileType(f.bytes) == DetectedType.pdf;
  final tools = kTools.where((t) => isPdf
      ? (t.accepts == PickKind.pdf || t.accepts == PickKind.pdfOrImage)
      : (t.accepts == PickKind.image || t.accepts == PickKind.pdfOrImage));
  final store = AppScope.of(context).files;
  final choice = await showModalBottomSheet<Object>(
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
              child: Text(l.sharedInTitle, style: Theme.of(c).textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              child: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(c).textTheme.bodySmall),
            ),
            ListTile(
              leading: const IconTile('folder', size: 40, highlighted: true),
              title: Text(l.saveToMyFiles),
              onTap: () => Navigator.of(c).pop('save'),
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
  if (!context.mounted || choice == null) return;
  if (choice == 'save') {
    await store.addBytes(f.name, f.bytes, tool: offerSave ? 'shared' : 'import');
    if (context.mounted) showMessage(context, l.resultSaved);
  } else if (choice is ToolId) {
    await openTool(context, choice, initial: [f]);
  }
}
