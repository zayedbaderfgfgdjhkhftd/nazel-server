import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../app/services.dart';
import '../../components/common.dart';
import '../../components/file_pick.dart';
import '../../components/job_ui.dart';
import '../../components/l10n_ext.dart';
import '../../components/tool_scaffold.dart';
import '../../config/app_config.dart';
import '../../core/arabic/normalize.dart';
import '../../core/docx/docx_writer.dart';
import '../../core/files/file_type.dart';
import '../../core/files/naming.dart';
import '../../core/files/output_file.dart';
import '../../core/image/image_ops.dart';
import '../../core/image/platform_decode.dart';
import '../../core/ocr/hocr.dart';
import '../../core/ocr/ocr_engine.dart';
import '../../core/pdf/pdf_service.dart';
import '../../core/pdf/render.dart';
import '../../design/icons.dart';
import '../../design/tokens.dart';
import '../result/result_screen.dart';
import '../tools/tool_registry.dart';
import 'ocr_tool.dart';

class OcrScreen extends PdfToolWidget {
  const OcrScreen({super.key, super.initial});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  InputFile? _input;
  PdfDocument? _pdf;
  int _page = 1;
  OcrLanguage _lang = OcrLanguage.arabic;
  bool _gray = true, _contrast = true, _binarize = false;
  bool _busy = false;
  OcrResult? _result;
  _HighlightController? _text;

  @override
  void initState() {
    super.initState();
    if (widget.initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setInput(widget.initial.first));
    }
  }

  @override
  void dispose() {
    _pdf?.dispose();
    _text?.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await pickInputs(context, kind: PickKind.pdfOrImage);
    if (picked.isNotEmpty) await _setInput(picked.first);
  }

  Future<void> _setInput(InputFile f) async {
    PdfDocument? pdf;
    if (detectFileType(f.bytes) == DetectedType.pdf) {
      try {
        pdf = await PdfService.openForEdit(f.bytes);
      } catch (e) {
        if (mounted) await showErrorDialog(context, errorMessage(context, e));
        return;
      }
    }
    final old = _pdf;
    setState(() {
      _input = f;
      _pdf = pdf;
      _page = 1;
      _result = null;
    });
    await old?.dispose();
  }

  Future<void> _run() async {
    setState(() => _busy = true);
    final services = AppScope.of(context);
    final input = _input!;
    final pdf = _pdf;
    final page = _page;
    final opts = OcrOptions(
      language: _lang,
      preprocess: OcrPreprocess(grayscale: _gray, contrast: _contrast, binarize: _binarize),
    );
    final result = await runJob(context, (ctx) async {
      Uint8List image;
      if (pdf != null) {
        // Scanned page -> 300 DPI image.
        final r = await renderPage(pdf.pages[page - 1], 300);
        image = await ctx.compute(encodeBgraJob,
            (bgra: r.bgra, width: r.width, height: r.height, png: true, quality: 100));
      } else {
        image = await normalizeImageInput(input.bytes);
      }
      return runOcr(image, opts, ctx, backend: TesseractBackend(), tempDir: services.tempDir);
    });
    if (mounted) setState(() => _busy = false);
    if (result == null || !mounted) return;
    _text?.dispose();
    setState(() {
      _result = result;
      _text = _HighlightController(
        text: result.text,
        uncertain: {
          for (final w in result.words)
            if (w.hasConfidence && w.confidence < AppConfig.ocrLowConfidence) w.text,
        },
        highlight: SatrColors.of(context).accent,
      );
    });
  }

  Future<void> _export(bool docx) async {
    final text = _text?.text ?? '';
    final name = outputFileName(_input!.name, kToolFileSuffix['ocr']!, docx ? 'docx' : 'txt');
    final bytes = docx ? buildDocx(text, title: _input!.name) : Uint8List.fromList(utf8.encode(text));
    await showResult(context, outputs: [OutputFile(name: name, bytes: bytes)], tool: ToolId.ocr.name);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = SatrColors.of(context);
    final r = _result;
    final pages = _pdf?.pages.length ?? 0;
    final lowCount = r?.lowConfidenceCount(AppConfig.ocrLowConfidence) ?? 0;
    return ToolScaffold(
      tool: ToolId.ocr,
      actionLabel: l.ocrAction,
      actionIcon: 'ocr',
      onAction: _input != null && !_busy ? _run : null,
      children: [
        if (_input == null)
          PickPrompt(label: l.pickImageOrPdf, onTap: _pick, icon: 'ocr')
        else
          InputFileTile(
            input: _input!,
            subtitle: _pdf == null
                ? formatBytes(context, _input!.bytes.length)
                : '${formatBytes(context, _input!.bytes.length)} · ${l.pagesCount(pages)}',
            onChange: _busy ? null : _pick,
          ),
        if (_input != null) ...[
          if (_pdf != null && pages > 1)
            SectionCard(
              title: '${l.ocrPdfPage}: ${formatNumber(context, _page)}',
              child: Slider(
                value: _page.toDouble(),
                min: 1,
                max: pages.toDouble(),
                divisions: pages - 1,
                label: formatNumber(context, _page),
                onChanged: (v) => setState(() => _page = v.round()),
              ),
            ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChoiceRow<OcrLanguage>(
                  label: l.ocrLanguage,
                  value: _lang,
                  options: {
                    OcrLanguage.arabic: l.ocrLangAr,
                    OcrLanguage.english: l.ocrLangEn,
                    OcrLanguage.both: l.ocrLangBoth,
                  },
                  onChanged: (v) => setState(() => _lang = v),
                ),
                const SizedBox(height: Space.m),
                Text(l.ocrPreprocess, style: Theme.of(context).textTheme.titleSmall),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _gray,
                  title: Text(l.ocrGrayscale),
                  onChanged: (v) => setState(() => _gray = v ?? _gray),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _contrast,
                  title: Text(l.ocrContrast),
                  onChanged: (v) => setState(() => _contrast = v ?? _contrast),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _binarize,
                  title: Text(l.ocrBinarize),
                  onChanged: (v) => setState(() => _binarize = v ?? _binarize),
                ),
              ],
            ),
          ),
          Text(l.ocrAccuracyNote, style: Theme.of(context).textTheme.bodySmall),
        ],
        if (r != null) ...[
          if (r.isEmpty)
            NoticeBox(text: l.ocrNoText, warning: true)
          else ...[
            if (lowCount > 0)
              Container(
                padding: const EdgeInsets.all(Space.m),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(Radii.control),
                ),
                child: Text('${l.ocrLowConfidence} ${l.ocrUncertainCount(lowCount)}'),
              ),
            Text(l.ocrEditable, style: Theme.of(context).textTheme.bodySmall),
            TextField(
              controller: _text,
              maxLines: null,
              minLines: 6,
              textDirection: isRtlText(_text!.text) ? TextDirection.rtl : TextDirection.ltr,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(),
            ),
            Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _text!.text));
                    if (context.mounted) showMessage(context, l.copied);
                  },
                  icon: const SatrIcon('copy', size: 20),
                  label: Text(l.copyAll),
                ),
                OutlinedButton.icon(
                  onPressed: () => _export(false),
                  icon: const SatrIcon('fileText', size: 20),
                  label: Text(l.exportTxt),
                ),
                OutlinedButton.icon(
                  onPressed: () => _export(true),
                  icon: const SatrIcon('file', size: 20),
                  label: Text(l.exportDocx),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

/// Text controller that highlights words OCR was unsure about, so the user
/// can review them. Highlighting follows the words while the text is edited.
class _HighlightController extends TextEditingController {
  _HighlightController({required super.text, required this.uncertain, required this.highlight});
  final Set<String> uncertain;
  final Color highlight;

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    if (uncertain.isEmpty) return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    final spans = <TextSpan>[];
    final re = RegExp(r'\S+|\s+');
    for (final m in re.allMatches(text)) {
      final t = m.group(0)!;
      final hit = uncertain.contains(t);
      spans.add(TextSpan(
        text: t,
        style: hit ? TextStyle(backgroundColor: highlight.withValues(alpha: 0.55)) : null,
      ));
    }
    return TextSpan(style: style, children: spans);
  }
}
