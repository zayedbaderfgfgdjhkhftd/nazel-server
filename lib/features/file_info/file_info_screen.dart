import 'package:material_ui/material_ui.dart';

import '../../components/common.dart';
import '../../components/file_pick.dart';
import '../../components/job_ui.dart';
import '../../components/l10n_ext.dart';
import '../../components/tool_scaffold.dart';
import '../../core/pdf/pdf_service.dart';
import '../../core/pdf/pdfium_native.dart';
import '../../design/tokens.dart';
import '../result/result_screen.dart';
import '../tools/tool_registry.dart';
import 'file_info_tool.dart';

class FileInfoScreen extends PdfToolWidget {
  const FileInfoScreen({super.key, super.initial});

  @override
  State<FileInfoScreen> createState() => _FileInfoScreenState();
}

class _FileInfoScreenState extends State<FileInfoScreen> {
  InputFile? _input;
  PdfInfo? _info;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(widget.initial.first));
    }
  }

  Future<void> _pick() async {
    final picked = await pickInputs(context, kind: PickKind.pdf);
    if (picked.isNotEmpty) await _load(picked.first);
  }

  Future<void> _load(InputFile f) async {
    try {
      final info = await readPdfInfo(f.bytes);
      setState(() {
        _input = f;
        _info = info;
      });
    } catch (e) {
      if (mounted) await showErrorDialog(context, errorMessage(context, e));
    }
  }

  Future<void> _clear() async {
    setState(() => _busy = true);
    final out = await runJob(context, (ctx) => runClearMetadata(_input!, ctx));
    if (mounted) setState(() => _busy = false);
    if (out == null || !mounted) return;
    await showResult(context, outputs: [out], tool: ToolId.fileInfo.name);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final info = _info;
    String meta(String key) {
      final v = info?.meta[key];
      if (v == null) return l.none;
      if (key.endsWith('Date')) {
        final d = parsePdfDate(v);
        return d == null ? v : formatDateTime(context, d);
      }
      return v;
    }

    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 130, child: Text(k, style: Theme.of(context).textTheme.bodySmall)),
              Expanded(child: SelectableText(v, style: Theme.of(context).textTheme.bodyMedium)),
            ],
          ),
        );

    return ToolScaffold(
      tool: ToolId.fileInfo,
      actionLabel: l.fiClearMeta,
      actionIcon: 'eraser',
      onAction: info != null && !info.encrypted && !_busy ? _clear : null,
      children: [
        if (_input == null)
          PickPrompt(label: l.pickPdf, onTap: _pick)
        else
          InputFileTile(input: _input!, onChange: _busy ? null : _pick),
        if (info != null) ...[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                row(l.fiFileSize, formatBytes(context, info.fileSize)),
                row(l.fiVersion, info.version ?? l.none),
                row(l.fiEncrypted, info.encrypted ? l.yes : l.no),
                if (!info.encrypted) ...[
                  row(l.fiPages, formatNumber(context, info.pageCount)),
                  row(
                    l.fiPageSizes,
                    info.pageSizes.entries.map((e) {
                      final name = paperName(e.key.w, e.key.h);
                      final mm = '${(e.key.w * 25.4 / 72).round()}×${(e.key.h * 25.4 / 72).round()} mm';
                      return '${name == null ? mm : '$name ($mm)'} · ${l.pagesCount(e.value)}';
                    }).join('\n'),
                  ),
                ],
              ],
            ),
          ),
          if (info.encrypted)
            NoticeBox(text: '${l.fiEncryptedNote} ${l.errEncrypted}', icon: 'lock')
          else ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  row(l.fiTitle, meta('Title')),
                  row(l.fiAuthor, meta('Author')),
                  row(l.fiSubject, meta('Subject')),
                  row(l.fiKeywords, meta('Keywords')),
                  row(l.fiCreator, meta('Creator')),
                  row(l.fiProducer, meta('Producer')),
                  row(l.fiCreated, meta('CreationDate')),
                  row(l.fiModified, meta('ModDate')),
                ],
              ),
            ),
            NoticeBox(text: l.fiClearMetaNote),
          ],
        ],
      ],
    );
  }
}
