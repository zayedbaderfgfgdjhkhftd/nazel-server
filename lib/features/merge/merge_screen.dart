import 'package:material_ui/material_ui.dart';

import '../../components/common.dart';
import '../../components/file_pick.dart';
import '../../components/job_ui.dart';
import '../../components/l10n_ext.dart';
import '../../components/tool_scaffold.dart';
import '../../core/pdf/pdf_service.dart';
import '../../design/icons.dart';
import '../../design/tokens.dart';
import '../result/result_screen.dart';
import '../tools/tool_registry.dart';
import 'merge_tool.dart';

class MergeScreen extends PdfToolWidget {
  const MergeScreen({super.key, super.initial});

  @override
  State<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends State<MergeScreen> {
  late final List<InputFile> _files = [...widget.initial];
  bool _busy = false;

  Future<void> _add() async {
    final picked = await pickInputs(context, kind: PickKind.pdf, multiple: true);
    for (final f in picked) {
      // Validate early so problems show up before running.
      if (await PdfService.isEncrypted(f.bytes)) {
        if (mounted) showMessage(context, context.l10n.errEncrypted);
        continue;
      }
      _files.add(f);
    }
    setState(() {});
  }

  Future<void> _run() async {
    if (_files.length < 2) {
      showMessage(context, context.l10n.mergeNeedTwo);
      return;
    }
    setState(() => _busy = true);
    final out = await runJob(context, (ctx) => runMerge(_files, ctx));
    if (mounted) setState(() => _busy = false);
    if (out == null || !mounted) return;
    await showResult(context, outputs: [out], tool: ToolId.merge.name);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ToolScaffold(
      tool: ToolId.merge,
      actionLabel: l.mergeAction,
      actionIcon: 'merge',
      onAction: _busy || _files.length < 2 ? null : _run,
      children: [
        if (_files.isEmpty)
          PickPrompt(label: l.pickPdfs, onTap: _add)
        else ...[
          Text(l.mergeHint, style: Theme.of(context).textTheme.bodySmall),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (a, b) => setState(() => _files.insert(b, _files.removeAt(a))),
            children: [
              for (var i = 0; i < _files.length; i++)
                Padding(
                  key: ObjectKey(_files[i]),
                  padding: const EdgeInsets.only(bottom: Space.s),
                  child: InputFileTile(
                    input: _files[i],
                    dragHandle: ReorderableDragStartListener(
                      index: i,
                      child: const Padding(
                        padding: EdgeInsetsDirectional.only(end: Space.s),
                        child: SizedBox(width: kTouchTarget, height: kTouchTarget, child: Center(child: SatrIcon('grip'))),
                      ),
                    ),
                    onRemove: _busy ? null : () => setState(() => _files.removeAt(i)),
                  ),
                ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _add,
            icon: const SatrIcon('plus', size: 20),
            label: Text(l.addMore),
          ),
          if (_files.length < 2) NoticeBox(text: l.mergeNeedTwo),
        ],
      ],
    );
  }
}
