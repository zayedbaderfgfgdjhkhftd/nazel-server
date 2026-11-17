import 'package:material_ui/material_ui.dart';

import '../../components/common.dart';
import '../../components/l10n_ext.dart';
import '../../components/tool_scaffold.dart';
import '../../core/pdf/page_ranges.dart';
import '../../design/tokens.dart';
import '../result/result_screen.dart';
import '../tools/tool_registry.dart';
import 'split_tool.dart';

class SplitScreen extends PdfToolWidget {
  const SplitScreen({super.key, super.initial});

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends SinglePdfToolState<SplitScreen> {
  SplitMode _mode = SplitMode.ranges;
  final _ranges = TextEditingController();
  int _every = 1;
  String? _rangeError;

  @override
  void dispose() {
    _ranges.dispose();
    super.dispose();
  }

  @override
  void onDocumentLoaded() {
    if (_ranges.text.isEmpty && pageCount > 1) _ranges.text = '1-${(pageCount / 2).ceil()}';
    _validate();
  }

  void _validate() {
    if (_mode != SplitMode.ranges || input == null) {
      setState(() => _rangeError = null);
      return;
    }
    try {
      parsePageRanges(_ranges.text, pageCount);
      setState(() => _rangeError = null);
    } on RangeParseException catch (e) {
      setState(() => _rangeError = rangeErrorMessage(context, e, pageCount));
    }
  }

  Future<void> _run() async {
    final out = await runTool((ctx) => runSplit(
        input!, SplitOptions(mode: _mode, rangesText: _ranges.text, everyN: _every), ctx));
    if (out == null || !mounted) return;
    await showResult(context, outputs: [out], tool: ToolId.split.name);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final canRun = input != null && !busy && (_mode != SplitMode.ranges || _rangeError == null);
    return ToolScaffold(
      tool: ToolId.split,
      actionLabel: l.splitAction,
      actionIcon: 'split',
      onAction: canRun ? _run : null,
      children: [
        inputSection(),
        if (input != null) ...[
          SectionCard(
            child: ChoiceRow<SplitMode>(
              label: l.pagesLabel,
              value: _mode,
              options: {
                SplitMode.ranges: l.splitModeRanges,
                SplitMode.everyN: l.splitModeEvery,
                SplitMode.eachPage: l.splitModeEach,
              },
              onChanged: (m) {
                setState(() => _mode = m);
                _validate();
              },
            ),
          ),
          if (_mode == SplitMode.ranges)
            SectionCard(
              title: l.splitRangesLabel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _ranges,
                    keyboardType: TextInputType.text,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(hintText: l.splitRangesHint, errorText: _rangeError),
                    onChanged: (_) => _validate(),
                  ),
                  const SizedBox(height: Space.s),
                  Text(l.splitRangesHelp, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          if (_mode == SplitMode.everyN)
            SectionCard(
              title: l.splitEveryLabel,
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _every.toDouble(),
                      min: 1,
                      max: (pageCount < 2 ? 2 : pageCount).toDouble(),
                      divisions: pageCount < 2 ? 1 : pageCount - 1,
                      label: formatNumber(context, _every),
                      onChanged: (v) => setState(() => _every = v.round()),
                    ),
                  ),
                  SizedBox(width: 48, child: Text(formatNumber(context, _every), textAlign: TextAlign.center)),
                ],
              ),
            ),
          NoticeBox(text: l.splitZipNote),
        ],
      ],
    );
  }
}
