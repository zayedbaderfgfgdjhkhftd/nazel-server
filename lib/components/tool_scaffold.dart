import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';

import '../ads/ad_slot.dart';
import '../core/files/file_type.dart';
import '../core/jobs/job.dart';
import '../core/pdf/pdf_service.dart';
import '../design/icons.dart';
import '../design/tokens.dart';
import '../features/tools/tool_registry.dart';
import 'common.dart';
import 'file_pick.dart';
import 'job_ui.dart';
import 'l10n_ext.dart';

/// Standard layout for a tool: title, scrolling options, pinned action.
class ToolScaffold extends StatelessWidget {
  const ToolScaffold({
    super.key,
    required this.tool,
    required this.children,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon,
    this.appBarActions,
    this.body,
  });

  final ToolId tool;
  final List<Widget> children;
  final String actionLabel;
  final VoidCallback? onAction;
  final String? actionIcon;
  final List<Widget>? appBarActions;

  /// Replaces the default scrolling list (e.g. for full-height grids).
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(toolName(context, tool)), actions: appBarActions),
      body: body ??
          ListView(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xl),
            children: [
              MaxWidth(
                maxWidth: 720,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      if (i > 0) const SizedBox(height: Space.l),
                      children[i],
                    ],
                    const SizedBox(height: Space.l),
                    const AdSlot(AdPlacement.toolsBottom),
                  ],
                ),
              ),
            ],
          ),
      bottomNavigationBar: BottomAction(label: actionLabel, onPressed: onAction, icon: actionIcon),
    );
  }
}

/// Big call-to-action shown when no input is selected yet.
class PickPrompt extends StatelessWidget {
  const PickPrompt({super.key, required this.label, required this.onTap, this.icon = 'upload'});
  final String label;
  final VoidCallback onTap;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final c = SatrColors.of(context);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Space.xxl, horizontal: Space.l),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: c.line, width: 1.5),
          ),
          child: Column(
            children: [
              IconTile(icon, size: 56, highlighted: true),
              const SizedBox(height: Space.m),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// A selected input file with a "change" or "remove" action.
class InputFileTile extends StatelessWidget {
  const InputFileTile({
    super.key,
    required this.input,
    this.subtitle,
    this.onChange,
    this.onRemove,
    this.leadingIcon,
    this.dragHandle,
  });

  final InputFile input;
  final String? subtitle;
  final VoidCallback? onChange;
  final VoidCallback? onRemove;
  final String? leadingIcon;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final type = detectFileType(input.bytes.length > 64 ? input.bytes.sublist(0, 64) : input.bytes);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s),
        child: Row(
          children: [
            ?dragHandle,
            IconTile(leadingIcon ?? (type == DetectedType.pdf ? 'fileText' : 'image'), size: 40),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(input.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(subtitle ?? formatBytes(context, input.bytes.length),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (onChange != null) TextButton(onPressed: onChange, child: Text(l.change)),
            if (onRemove != null)
              IconButton(tooltip: l.remove, onPressed: onRemove, icon: const SatrIcon('close', size: 20)),
          ],
        ),
      ),
    );
  }
}

abstract class PdfToolWidget extends StatefulWidget {
  const PdfToolWidget({super.key, this.initial = const []});
  final List<InputFile> initial;
}

/// Base state for tools that work on ONE PDF: picking, validation (magic
/// bytes, encryption, corruption), page count, an open document for
/// thumbnails, and a run helper that disables the action while working.
abstract class SinglePdfToolState<W extends PdfToolWidget> extends State<W> {
  InputFile? input;
  PdfDocument? doc;
  bool busy = false;

  int get pageCount => doc?.pages.length ?? 0;

  @override
  void initState() {
    super.initState();
    if (widget.initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => setInput(widget.initial.first));
    }
  }

  @override
  void dispose() {
    doc?.dispose();
    super.dispose();
  }

  /// Called after a new document is loaded.
  void onDocumentLoaded() {}

  Future<void> pick() async {
    final picked = await pickInputs(context, kind: PickKind.pdf);
    if (picked.isNotEmpty) await setInput(picked.first);
  }

  Future<void> setInput(InputFile f) async {
    try {
      final d = await PdfService.openForEdit(f.bytes);
      final old = doc;
      setState(() {
        input = f;
        doc = d;
      });
      await old?.dispose();
      onDocumentLoaded();
    } catch (e) {
      if (mounted) await showErrorDialog(context, errorMessage(context, e));
    }
  }

  /// Input card or pick prompt.
  Widget inputSection() {
    final l = context.l10n;
    if (input == null) return PickPrompt(label: l.pickPdf, onTap: pick);
    return InputFileTile(
      input: input!,
      subtitle: '${formatBytes(context, input!.bytes.length)} · ${l.pagesCount(pageCount)}',
      onChange: busy ? null : pick,
    );
  }

  /// Runs a job with progress UI; [busy] blocks double runs.
  Future<T?> runTool<T>(Future<T> Function(JobContext ctx) task) async {
    if (busy) return null;
    setState(() => busy = true);
    try {
      return await runJob<T>(context, task);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
