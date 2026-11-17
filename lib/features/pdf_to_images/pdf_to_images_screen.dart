import 'package:material_ui/material_ui.dart';

import '../../components/common.dart';
import '../../components/l10n_ext.dart';
import '../../components/tool_scaffold.dart';
import '../../design/tokens.dart';
import '../result/result_screen.dart';
import '../tools/tool_registry.dart';
import 'pdf_to_images_tool.dart';

class PdfToImagesScreen extends PdfToolWidget {
  const PdfToImagesScreen({super.key, super.initial});

  @override
  State<PdfToImagesScreen> createState() => _PdfToImagesScreenState();
}

class _PdfToImagesScreenState extends SinglePdfToolState<PdfToImagesScreen> {
  ImageFormat _format = ImageFormat.jpg;
  int _dpi = 150;
  bool _all = true;
  int _page = 1;

  Future<void> _run() async {
    final o = PdfToImagesOptions(format: _format, dpi: _dpi, singlePage: _all ? null : _page);
    final out = await runTool((ctx) => runPdfToImages(input!, o, ctx));
    if (out == null || !mounted) return;
    await showResult(context, outputs: [out], tool: ToolId.pdfToImages.name);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ToolScaffold(
      tool: ToolId.pdfToImages,
      actionLabel: l.convertAction,
      actionIcon: 'pdfToImages',
      onAction: input != null && !busy ? _run : null,
      children: [
        inputSection(),
        if (input != null) ...[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChoiceRow<ImageFormat>(
                  label: l.formatLabel,
                  value: _format,
                  options: const {ImageFormat.jpg: 'JPG', ImageFormat.png: 'PNG'},
                  onChanged: (v) => setState(() => _format = v),
                ),
                const SizedBox(height: Space.l),
                ChoiceRow<int>(
                  label: l.resolutionLabel,
                  value: _dpi,
                  options: {72: l.dpiScreen, 150: l.dpiStandard, 300: l.dpiPrint},
                  onChanged: (v) => setState(() => _dpi = v),
                ),
              ],
            ),
          ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChoiceRow<bool>(
                  label: l.pagesLabel,
                  value: _all,
                  options: {true: l.allPages, false: l.onePage},
                  onChanged: (v) => setState(() => _all = v),
                ),
                if (!_all && pageCount > 1) ...[
                  const SizedBox(height: Space.m),
                  Text('${l.pageNumberLabel}: ${formatNumber(context, _page)}',
                      style: Theme.of(context).textTheme.titleSmall),
                  Slider(
                    value: _page.toDouble(),
                    min: 1,
                    max: pageCount.toDouble(),
                    divisions: pageCount - 1,
                    label: formatNumber(context, _page),
                    onChanged: (v) => setState(() => _page = v.round()),
                  ),
                ],
                if (_all && pageCount > 1) ...[
                  const SizedBox(height: Space.s),
                  NoticeBox(text: l.splitZipNote),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
