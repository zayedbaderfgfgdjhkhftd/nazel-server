import 'package:material_ui/material_ui.dart';

import '../../components/common.dart';
import '../../components/job_ui.dart';
import '../../components/l10n_ext.dart';
import '../../components/tool_scaffold.dart';
import '../../design/tokens.dart';
import '../result/result_screen.dart';
import '../tools/tool_registry.dart';
import 'compress_tool.dart';

class CompressScreen extends PdfToolWidget {
  const CompressScreen({super.key, super.initial});

  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends SinglePdfToolState<CompressScreen> {
  CompressLevel _level = CompressLevel.recommended;
  int _dpi = 100;

  Future<void> _run() async {
    final l = context.l10n;
    if (_level == CompressLevel.strong) {
      // Quality loss must be accepted before running.
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(l.compressStrongWarning),
          actions: [
            TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.of(c).pop(true), child: Text(l.continueAnyway)),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    final r = await runTool((ctx) => runCompress(input!, CompressOptions(level: _level, strongDpi: _dpi), ctx));
    if (r == null || !mounted) return;
    final before = formatBytes(context, r.originalSize);
    final after = formatBytes(context, r.newSize);
    if (r.keptOriginal) {
      await showErrorDialog(context, l.compressNotSmaller(before, after));
      return;
    }
    final percent = formatNumber(context, (r.savedFraction * 100).round());
    await showResult(
      context,
      outputs: [r.file!],
      tool: ToolId.compress.name,
      details: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.compressResult(before, after), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Space.xs),
              HighlightTitle(l.compressSaved(percent), style: Theme.of(context).textTheme.titleSmall),
              if (r.imagesRecoded > 0) ...[
                const SizedBox(height: Space.xs),
                Text(l.compressImagesRecoded(r.imagesRecoded), style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (_level == CompressLevel.recommended && r.levelUsed == CompressLevel.light)
          NoticeBox(text: l.compressFellBack),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget option(CompressLevel level, String title, String desc) => RadioListTile<CompressLevel>(
          value: level,
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(desc),
          contentPadding: EdgeInsets.zero,
        );
    return ToolScaffold(
      tool: ToolId.compress,
      actionLabel: l.compressAction,
      actionIcon: 'compress',
      onAction: input != null && !busy ? _run : null,
      children: [
        inputSection(),
        if (input != null) ...[
          SectionCard(
            child: RadioGroup<CompressLevel>(
              groupValue: _level,
              onChanged: (v) => setState(() => _level = v ?? _level),
              child: Column(
                children: [
                  option(CompressLevel.light, l.compressLight, l.compressLightDesc),
                  option(CompressLevel.recommended, l.compressRecommended, l.compressRecommendedDesc),
                  option(CompressLevel.strong, l.compressStrong, l.compressStrongDesc),
                ],
              ),
            ),
          ),
          if (_level == CompressLevel.strong) ...[
            NoticeBox(text: l.compressStrongWarning, warning: true),
            SectionCard(
              child: ChoiceRow<int>(
                label: l.compressDpi,
                value: _dpi,
                options: {for (final d in const [72, 100, 150]) d: l.dpiValue(d)},
                onChanged: (v) => setState(() => _dpi = v),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
