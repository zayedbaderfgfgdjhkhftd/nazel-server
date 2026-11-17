import 'package:material_ui/material_ui.dart';

import '../../components/common.dart';
import '../../components/l10n_ext.dart';
import '../../components/tool_scaffold.dart';
import '../../design/icons.dart';
import '../../design/tokens.dart';
import '../result/result_screen.dart';
import '../tools/tool_registry.dart';
import 'page_numbers_tool.dart';

class PageNumbersScreen extends PdfToolWidget {
  const PageNumbersScreen({super.key, super.initial});

  @override
  State<PageNumbersScreen> createState() => _PageNumbersScreenState();
}

class _PageNumbersScreenState extends SinglePdfToolState<PageNumbersScreen> {
  NumberPosition _position = NumberPosition.bottomCenter;
  int _start = 1;
  bool _withTotal = false;
  bool _eastern = false;
  double _fontSize = 11;
  bool _skipFirst = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Arabic UI defaults to Eastern Arabic digits.
    if (!_touched) _eastern = context.lang == 'ar';
  }

  bool _touched = false;

  PageNumberOptions get _options => PageNumberOptions(
        position: _position,
        start: _start,
        withTotal: _withTotal,
        easternDigits: _eastern,
        fontSizePt: _fontSize,
        skipFirst: _skipFirst,
      );

  Future<void> _run() async {
    final out = await runTool((ctx) => runPageNumbers(input!, _options, ctx));
    if (out == null || !mounted) return;
    await showResult(context, outputs: [out], tool: ToolId.pageNumbers.name);
  }

  String _posLabel(NumberPosition p) {
    final l = context.l10n;
    return switch (p) {
      NumberPosition.topLeft => l.posTopLeft,
      NumberPosition.topCenter => l.posTopCenter,
      NumberPosition.topRight => l.posTopRight,
      NumberPosition.bottomLeft => l.posBottomLeft,
      NumberPosition.bottomCenter => l.posBottomCenter,
      NumberPosition.bottomRight => l.posBottomRight,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final count = pageCount == 0 ? 1 : pageCount;
    final preview = pageLabel(_skipFirst && count > 1 ? 1 : 0, count, _options) ?? '';
    return ToolScaffold(
      tool: ToolId.pageNumbers,
      actionLabel: l.pnAction,
      actionIcon: 'pageNumbers',
      onAction: input != null && !busy ? _run : null,
      children: [
        inputSection(),
        if (input != null) ...[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.positionLabel, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: Space.s),
                Wrap(
                  spacing: Space.s,
                  runSpacing: Space.s,
                  textDirection: TextDirection.ltr,
                  children: [
                    for (final p in NumberPosition.values)
                      ChoiceChip(
                        label: Text(_posLabel(p)),
                        selected: _position == p,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _position = p),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChoiceRow<bool>(
                  label: l.pnFormat,
                  value: _withTotal,
                  options: const {false: '1', true: '1 / N'},
                  onChanged: (v) => setState(() => _withTotal = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.pnEastern),
                  value: _eastern,
                  onChanged: (v) => setState(() {
                    _touched = true;
                    _eastern = v;
                  }),
                ),
                Row(
                  children: [
                    Expanded(child: Text(l.pnStart, style: Theme.of(context).textTheme.titleSmall)),
                    IconButton(
                      onPressed: _start > 1 ? () => setState(() => _start--) : null,
                      icon: const Text('−', style: TextStyle(fontSize: 22)),
                    ),
                    SizedBox(
                        width: 40,
                        child: Text(formatNumber(context, _start), textAlign: TextAlign.center)),
                    IconButton(onPressed: () => setState(() => _start++), icon: const SatrIcon('plus')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text(l.fontSizeLabel, style: Theme.of(context).textTheme.titleSmall)),
                    Text('${_fontSize.round()}', textDirection: TextDirection.ltr),
                  ],
                ),
                Slider(
                  value: _fontSize,
                  min: 8,
                  max: 24,
                  divisions: 16,
                  label: '${_fontSize.round()}',
                  onChanged: (v) => setState(() => _fontSize = v.roundToDouble()),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.pnSkipFirst),
                  subtitle: Text(l.pnSkipFirstHelp),
                  value: _skipFirst,
                  onChanged: (v) => setState(() => _skipFirst = v),
                ),
              ],
            ),
          ),
          NoticeBox(text: l.pnPreview(preview)),
        ],
      ],
    );
  }
}
