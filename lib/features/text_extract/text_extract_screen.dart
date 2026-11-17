import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../components/common.dart';
import '../../components/l10n_ext.dart';
import '../../components/tool_scaffold.dart';
import '../../core/arabic/normalize.dart';
import '../../core/docx/docx_writer.dart';
import '../../core/files/naming.dart';
import '../../core/files/output_file.dart';
import '../../design/icons.dart';
import '../../design/tokens.dart';
import '../result/result_screen.dart';
import '../tools/tool_registry.dart';
import 'text_extract_tool.dart';

class TextExtractScreen extends PdfToolWidget {
  const TextExtractScreen({super.key, super.initial});

  @override
  State<TextExtractScreen> createState() => _TextExtractScreenState();
}

class _TextExtractScreenState extends SinglePdfToolState<TextExtractScreen> {
  List<PageText>? _pages;

  @override
  void onDocumentLoaded() => setState(() => _pages = null);

  Future<void> _run() async {
    final pages = await runTool((ctx) => runTextExtract(input!, ctx));
    if (pages != null && mounted) setState(() => _pages = pages);
  }

  String _joined() => joinPages(_pages!.where((p) => !p.isEmpty).toList(), (n) => '— ${context.l10n.pageN(n)} —');

  Future<void> _export(bool docx) async {
    final text = _joined();
    final name = outputFileName(input!.name, kToolFileSuffix['textExtract']!, docx ? 'docx' : 'txt');
    final bytes = docx ? buildDocx(text, title: input!.name) : Uint8List.fromList(utf8.encode(text));
    await showResult(context, outputs: [OutputFile(name: name, bytes: bytes)], tool: ToolId.textExtract.name);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pages = _pages;
    final empty = pages?.where((p) => p.isEmpty).toList() ?? const [];
    final allEmpty = pages != null && empty.length == pages.length;
    return ToolScaffold(
      tool: ToolId.textExtract,
      actionLabel: l.teAction,
      actionIcon: 'textExtract',
      onAction: input != null && !busy ? _run : null,
      children: [
        inputSection(),
        if (pages != null) ...[
          if (allEmpty)
            NoticeBox(text: l.teAllEmpty, warning: true)
          else if (empty.isNotEmpty)
            NoticeBox(text: l.teOcrSuggest),
          if (empty.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => openTool(context, ToolId.ocr, initial: [input!]),
              icon: const SatrIcon('ocr', size: 20),
              label: Text(l.teOpenOcr),
            ),
          if (!allEmpty) ...[
            Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _joined()));
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
            for (final p in pages)
              SectionCard(
                title: l.pageN(p.pageNumber),
                child: p.isEmpty
                    ? Text(l.teNoText, style: Theme.of(context).textTheme.bodySmall)
                    : SelectableText(
                        p.text,
                        textDirection: isRtlText(p.text) ? TextDirection.rtl : TextDirection.ltr,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
              ),
          ],
        ],
      ],
    );
  }
}
