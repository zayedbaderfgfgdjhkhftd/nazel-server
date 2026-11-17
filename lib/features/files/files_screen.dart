import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/services.dart';
import '../../components/common.dart';
import '../../components/l10n_ext.dart';
import '../../core/files/file_type.dart';
import '../../core/files/output_file.dart';
import '../../core/share/share_service.dart';
import '../../core/storage/file_store.dart';
import '../../design/icons.dart';
import '../../design/tokens.dart';
import '../home/home_screen.dart';
import 'file_actions.dart';

enum _View { recent, all, favorites }

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key, required this.onGoToTools});
  final VoidCallback onGoToTools;

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  _View _view = _View.recent;
  final _search = TextEditingController();
  FileKind? _kind;
  FileSort _sort = FileSort.date;
  bool _desc = true;
  final _selected = <String>{};
  int? _free;

  bool get _selecting => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final free = await AppScope.of(context).platform.freeSpace();
      if (mounted) setState(() => _free = free);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final store = AppScope.of(context).files;
    final picked = await FilePicker.pickFiles();
    var n = 0;
    for (final f in picked) {
      final bytes = await f.readAsBytes();
      if (bytes.isEmpty) continue;
      final t = detectFileType(bytes.length > 1024 ? bytes.sublist(0, 1024) : bytes);
      if (t == DetectedType.unknown && !f.name.toLowerCase().endsWith('.txt')) {
        if (mounted) showMessage(context, context.l10n.errUnsupportedType);
        continue;
      }
      await store.addBytes(f.name, bytes, tool: 'import');
      n++;
    }
    if (n > 0 && mounted) showMessage(context, context.l10n.imported);
  }

  Future<void> _bulkSave(List<StoredFile> files) async {
    final store = AppScope.of(context).files;
    for (final f in files) {
      await ShareService.saveToDevice(f.name, await store.readBytes(f));
    }
    setState(_selected.clear);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = SatrColors.of(context);
    final store = AppScope.of(context).files;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        var files = store.query(
          search: _search.text,
          kind: _kind,
          favoritesOnly: _view == _View.favorites,
          sort: _view == _View.recent ? FileSort.date : _sort,
          descending: _view == _View.recent ? true : _desc,
        );
        if (_view == _View.recent) {
          final cutoff = DateTime.now().subtract(const Duration(days: 7));
          files = files.where((f) => f.createdAt.isAfter(cutoff)).take(30).toList();
        }
        _selected.removeWhere((id) => store.byId(id)?.isDeleted ?? true);
        final selectedFiles = [for (final f in files) if (_selected.contains(f.id)) f];
        return Scaffold(
          appBar: _selecting
              ? AppBar(
                  leading: IconButton(onPressed: () => setState(_selected.clear), icon: const SatrIcon('close')),
                  title: Text(l.selectedN(_selected.length)),
                  actions: [
                    IconButton(
                      tooltip: l.selectAll,
                      onPressed: () => setState(() => _selected.addAll(files.map((f) => f.id))),
                      icon: const SatrIcon('selectAll'),
                    ),
                    IconButton(
                      tooltip: l.saveToDevice,
                      onPressed: () => _bulkSave(selectedFiles),
                      icon: const SatrIcon('download'),
                    ),
                    IconButton(
                      tooltip: l.moveToTrash,
                      onPressed: () async {
                        final ids = _selected.toList();
                        setState(_selected.clear);
                        await trashWithUndo(context, ids);
                      },
                      icon: SatrIcon('trash', color: c.danger),
                    ),
                  ],
                )
              : AppBar(
                  title: Text(l.filesTitle),
                  actions: [
                    IconButton(tooltip: l.importFiles, onPressed: _import, icon: const SatrIcon('plus')),
                    IconButton(
                      tooltip: l.trash,
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: (_) => const TrashScreen())),
                      icon: const SatrIcon('trash'),
                    ),
                  ],
                ),
          body: MaxWidth(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
                  child: SegmentedButton<_View>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: _View.recent, label: Text(l.tabRecent)),
                      ButtonSegment(value: _View.all, label: Text(l.tabAll)),
                      ButtonSegment(value: _View.favorites, label: Text(l.tabFavorites)),
                    ],
                    selected: {_view},
                    onSelectionChanged: (s) => setState(() => _view = s.first),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 0),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: l.searchFiles,
                      prefixIcon: const Padding(padding: EdgeInsets.all(12), child: SatrIcon('search', size: 20)),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => setState(_search.clear),
                              icon: const SatrIcon('close', size: 18),
                            ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.s),
                  child: Row(
                    children: [
                      for (final e in <FileKind?, String>{
                        null: l.filterAll,
                        FileKind.pdf: l.filterPdf,
                        FileKind.image: l.filterImage,
                        FileKind.text: l.filterText,
                        FileKind.zip: l.filterZip,
                      }.entries)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: Space.s),
                          child: ChoiceChip(
                            label: Text(e.value),
                            selected: _kind == e.key,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _kind = e.key),
                          ),
                        ),
                      if (_view != _View.recent)
                        PopupMenuButton<FileSort>(
                          tooltip: l.sortBy,
                          onSelected: (s) => setState(() {
                            if (s == _sort) {
                              _desc = !_desc;
                            } else {
                              _sort = s;
                              _desc = s != FileSort.name;
                            }
                          }),
                          itemBuilder: (_) => [
                            PopupMenuItem(value: FileSort.date, child: Text(l.sortDate)),
                            PopupMenuItem(value: FileSort.name, child: Text(l.sortName)),
                            PopupMenuItem(value: FileSort.size, child: Text(l.sortSize)),
                          ],
                          child: Chip(
                            avatar: const SatrIcon('sort', size: 16),
                            label: Text('${l.sortBy}: ${switch (_sort) {
                              FileSort.date => l.sortDate,
                              FileSort.name => l.sortName,
                              FileSort.size => l.sortSize,
                            }}'),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: files.isEmpty
                      ? EmptyState(
                          icon: _search.text.isNotEmpty ? 'search' : (_view == _View.favorites ? 'star' : 'inbox'),
                          message: _search.text.isNotEmpty
                              ? l.searchEmpty
                              : (_view == _View.favorites ? l.favoritesEmpty : l.filesEmpty),
                          action: _search.text.isEmpty && _view != _View.favorites ? l.goToTools : null,
                          onAction: widget.onGoToTools,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: Space.s),
                          itemCount: files.length,
                          itemBuilder: (context, i) {
                            final f = files[i];
                            return FileRow(
                              file: f,
                              selected: _selecting ? _selected.contains(f.id) : null,
                              onTap: _selecting
                                  ? () => setState(() => _selected.contains(f.id) ? _selected.remove(f.id) : _selected.add(f.id))
                                  : null,
                              onLongPress: () => setState(() => _selected.add(f.id)),
                              trailing: _selecting ? const SizedBox.shrink() : null,
                            );
                          },
                        ),
                ),
                _StorageBar(used: store.usedBytes, free: _free),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StorageBar extends StatelessWidget {
  const _StorageBar({required this.used, required this.free});
  final int used;
  final int? free;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = SatrColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line.withValues(alpha: 0.6)))),
      child: Row(
        children: [
          SatrIcon('storage', size: 18, color: c.textMuted),
          const SizedBox(width: Space.s),
          Expanded(
            child: Text(
              [
                l.storageUsed(context.appName, formatBytes(context, used)),
                if (free != null) l.storageFree(formatBytes(context, free!)),
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  Future<bool> _confirm(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(c.l10n.confirmDeleteForever),
          actions: [
            TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(c.l10n.cancel)),
            FilledButton(onPressed: () => Navigator.of(c).pop(true), child: Text(c.l10n.deleteForever)),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final store = AppScope.of(context).files;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final items = store.trash;
        return Scaffold(
          appBar: AppBar(
            title: Text(l.trash),
            actions: [
              if (items.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    if (await _confirm(context)) await store.emptyTrash();
                  },
                  child: Text(l.emptyTrash),
                ),
            ],
          ),
          body: MaxWidth(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(Space.l),
                  child: NoticeBox(text: l.trashNote),
                ),
                Expanded(
                  child: items.isEmpty
                      ? EmptyState(icon: 'trash', message: l.trashEmpty)
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final f = items[i];
                            return ListTile(
                              title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${formatBytes(context, f.size)} · ${formatDateTime(context, f.deletedAt!)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: l.restore,
                                    onPressed: () => store.restore([f.id]),
                                    icon: const SatrIcon('restore'),
                                  ),
                                  IconButton(
                                    tooltip: l.deleteForever,
                                    onPressed: () async {
                                      if (await _confirm(context)) await store.deleteForever([f.id]);
                                    },
                                    icon: SatrIcon('trash', color: SatrColors.of(context).danger),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
