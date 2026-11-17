import 'package:material_ui/material_ui.dart';
import 'package:reorderable_grid/reorderable_grid.dart';

import '../../components/common.dart';
import '../../components/l10n_ext.dart';
import '../../components/page_grid.dart';
import '../../components/tool_scaffold.dart';
import '../../core/pdf/pdf_service.dart';
import '../../design/icons.dart';
import '../../design/tokens.dart';
import '../result/result_screen.dart';
import '../tools/tool_registry.dart';
import 'organize_tool.dart';

class OrganizeScreen extends PdfToolWidget {
  const OrganizeScreen({super.key, super.initial});

  @override
  State<OrganizeScreen> createState() => _OrganizeScreenState();
}

class _Item {
  _Item(this.item) : key = UniqueKey();
  OrganizeItem item;
  final Key key;
}

class _OrganizeScreenState extends SinglePdfToolState<OrganizeScreen> {
  final _items = <_Item>[];
  int? _selected;

  @override
  void onDocumentLoaded() => _reset();

  void _reset() => setState(() {
        _items
          ..clear()
          ..addAll([for (var i = 0; i < pageCount; i++) _Item(SourcePage(i))]);
        _selected = null;
      });

  Future<void> _run() async {
    if (_items.isEmpty) {
      showMessage(context, context.l10n.organizeNeedOne);
      return;
    }
    final items = [for (final i in _items) i.item];
    final out = await runTool((ctx) => runOrganize(input!, items, ctx));
    if (out == null || !mounted) return;
    await showResult(context, outputs: [out], tool: ToolId.organize.name);
  }

  void _rotate(int index, int delta) =>
      setState(() => _items[index].item = _items[index].item.rotated(delta));

  void _duplicate(int index) =>
      setState(() => _items.insert(index + 1, _Item(_items[index].item)));

  void _delete(int index) => setState(() {
        _items.removeAt(index);
        _selected = null;
      });

  Future<void> _insertBlank(int index) async {
    final l = context.l10n;
    final base = _items[index].item;
    final size = switch (base) {
      SourcePage(:final index) => (width: doc!.pages[index].width, height: doc!.pages[index].height),
      BlankPage(:final width, :final height) => (width: width, height: height),
    };
    final choice = await showModalBottomSheet<({double width, double height})>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                leading: const SatrIcon('filePlus'),
                title: Text(l.blankA4),
                onTap: () => Navigator.of(c).pop(PaperSizes.a4)),
            ListTile(
                leading: const SatrIcon('filePlus'),
                title: Text(l.blankLetter),
                onTap: () => Navigator.of(c).pop(PaperSizes.letter)),
            ListTile(
                leading: const SatrIcon('filePlus'),
                title: Text(l.blankSameSize),
                onTap: () => Navigator.of(c).pop(size)),
          ],
        ),
      ),
    );
    if (choice == null) return;
    setState(() => _items.insert(index + 1, _Item(BlankPage(choice.width, choice.height))));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sel = _selected;
    return ToolScaffold(
      tool: ToolId.organize,
      actionLabel: l.organizeAction,
      actionIcon: 'check',
      onAction: input != null && _items.isNotEmpty && !busy ? _run : null,
      appBarActions: [
        if (input != null) TextButton(onPressed: busy ? null : _reset, child: Text(l.reset)),
      ],
      body: input == null
          ? Padding(padding: const EdgeInsets.all(Space.l), child: inputSection())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      inputSection(),
                      const SizedBox(height: Space.s),
                      Text(l.organizeHint, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableGridView.builder(
                    padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l),
                    gridDelegate: kPageGridDelegate,
                    itemCount: _items.length,
                    onReorder: (a, b) => setState(() {
                      _items.insert(b, _items.removeAt(a));
                      _selected = null;
                    }),
                    itemBuilder: (context, i) {
                      final it = _items[i];
                      final item = it.item;
                      return PageThumb(
                        key: it.key,
                        document: doc,
                        pageNumber: item is SourcePage ? item.index + 1 : 1,
                        blank: item is BlankPage,
                        quarterTurns: item.quarterTurns,
                        selected: sel == i,
                        label: item is SourcePage ? l.pageN(item.index + 1) : l.blankPage,
                        onTap: () => setState(() => _selected = sel == i ? null : i),
                      );
                    },
                  ),
                ),
                if (sel != null && sel < _items.length)
                  _Toolbar(
                    onRotateLeft: () => _rotate(sel, 3),
                    onRotateRight: () => _rotate(sel, 1),
                    onDuplicate: () => _duplicate(sel),
                    onBlank: () => _insertBlank(sel),
                    onDelete: _items.length > 1 ? () => _delete(sel) : null,
                  ),
              ],
            ),
      children: const [],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onDuplicate,
    required this.onBlank,
    required this.onDelete,
  });
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onDuplicate;
  final VoidCallback onBlank;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = SatrColors.of(context);
    Widget b(String icon, String label, VoidCallback? onTap, {Color? color}) => Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.control),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SatrIcon(icon, color: onTap == null ? c.line : color),
                  const SizedBox(height: 2),
                  Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(color: color)),
                ],
              ),
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.line))),
      padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: Space.xs),
      child: Row(
        children: [
          b('rotateLeft', l.rotateLeft, onRotateLeft),
          b('rotateRight', l.rotateRight, onRotateRight),
          b('copy', l.duplicate, onDuplicate),
          b('filePlus', l.insertBlank, onBlank),
          b('trash', l.delete, onDelete, color: c.danger),
        ],
      ),
    );
  }
}
