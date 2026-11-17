import 'package:material_ui/material_ui.dart';

import '../../components/common.dart';
import '../../components/l10n_ext.dart';
import '../../components/page_grid.dart';
import '../../components/tool_scaffold.dart';
import '../../design/tokens.dart';
import '../result/result_screen.dart';
import '../tools/tool_registry.dart';
import 'extract_tool.dart';

class ExtractScreen extends PdfToolWidget {
  const ExtractScreen({super.key, super.initial});

  @override
  State<ExtractScreen> createState() => _ExtractScreenState();
}

class _ExtractScreenState extends SinglePdfToolState<ExtractScreen> {
  final _selected = <int>{};

  @override
  void onDocumentLoaded() => setState(_selected.clear);

  Future<void> _run() async {
    final pages = _selected.toList()..sort();
    final out = await runTool((ctx) => runExtract(input!, pages, ctx));
    if (out == null || !mounted) return;
    await showResult(context, outputs: [out], tool: ToolId.extract.name);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ToolScaffold(
      tool: ToolId.extract,
      actionLabel: _selected.isEmpty ? l.extractAction : '${l.extractAction} (${formatNumber(context, _selected.length)})',
      actionIcon: 'extract',
      onAction: input != null && _selected.isNotEmpty && !busy ? _run : null,
      body: input == null
          ? Padding(padding: const EdgeInsets.all(Space.l), child: inputSection())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.s),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        inputSection(),
                        const SizedBox(height: Space.m),
                        Row(
                          children: [
                            Expanded(child: Text(l.extractHint, style: Theme.of(context).textTheme.bodySmall)),
                            TextButton(
                              onPressed: () => setState(() => _selected.length == pageCount
                                  ? _selected.clear()
                                  : _selected.addAll([for (var i = 1; i <= pageCount; i++) i])),
                              child: Text(_selected.length == pageCount ? l.selectNone : l.selectAll),
                            ),
                          ],
                        ),
                        Text(l.selectedCount(_selected.length), style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
                  sliver: SliverGrid.builder(
                    gridDelegate: kPageGridDelegate,
                    itemCount: pageCount,
                    itemBuilder: (context, i) {
                      final n = i + 1;
                      return PageThumb(
                        key: ValueKey(n),
                        document: doc,
                        pageNumber: n,
                        label: formatNumber(context, n),
                        selected: _selected.contains(n),
                        onTap: () => setState(() => _selected.contains(n) ? _selected.remove(n) : _selected.add(n)),
                      );
                    },
                  ),
                ),
                if (_selected.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.l),
                      child: NoticeBox(text: l.extractNeedOne),
                    ),
                  ),
              ],
            ),
      children: const [],
    );
  }
}
