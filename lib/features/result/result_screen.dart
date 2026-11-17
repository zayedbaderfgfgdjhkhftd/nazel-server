import 'package:material_ui/material_ui.dart';

import '../../ads/ad_slot.dart';
import '../../app/services.dart';
import '../../components/common.dart';
import '../../components/l10n_ext.dart';
import '../../core/files/output_file.dart';
import '../../core/storage/file_store.dart';
import '../../design/icons.dart';
import '../../design/tokens.dart';
import '../files/file_actions.dart';

/// Saves verified outputs to "My files" and shows the result screen.
Future<void> showResult(
  BuildContext context, {
  required List<OutputFile> outputs,
  required String tool,
  List<Widget> details = const [],
}) async {
  final store = AppScope.of(context).files;
  final saved = <StoredFile>[];
  for (final o in outputs) {
    saved.add(await store.addOutput(o, tool: tool));
  }
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => ResultScreen(files: saved, outputs: outputs, details: details),
  ));
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.files, required this.outputs, this.details = const []});
  final List<StoredFile> files;
  final List<OutputFile> outputs;
  final List<Widget> details;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = SatrColors.of(context);
    final f = files.first;
    final out = outputs.first;
    return Scaffold(
      appBar: AppBar(title: Text(l.resultTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Space.l),
        children: [
          MaxWidth(
            maxWidth: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                    child: Center(child: SatrIcon('check', size: 36, color: c.onAccent)),
                  ),
                ),
                const SizedBox(height: Space.l),
                Center(child: HighlightTitle(l.resultTitle)),
                const SizedBox(height: Space.xs),
                Center(child: Text(l.resultSaved, style: Theme.of(context).textTheme.bodySmall)),
                const SizedBox(height: Space.xl),
                SectionCard(
                  child: Row(
                    children: [
                      IconTile(f.kind == FileKind.pdf ? 'fileText' : (f.kind == FileKind.image ? 'image' : 'archive')),
                      const SizedBox(width: Space.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                            Text(
                              [
                                formatBytes(context, f.size),
                                if (out.pageCount != null) l.pagesCount(out.pageCount!),
                              ].join(' · '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                for (final d in details) ...[const SizedBox(height: Space.m), d],
                const SizedBox(height: Space.xl),
                if (f.kind != FileKind.zip && f.kind != FileKind.docx)
                  FilledButton(
                    onPressed: () => openStoredFile(context, f),
                    child: Text(l.open),
                  ),
                const SizedBox(height: Space.s),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => shareStoredFile(context, f),
                        icon: const SatrIcon('share', size: 20),
                        label: Text(l.share),
                      ),
                    ),
                    const SizedBox(width: Space.s),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => saveStoredFile(context, f),
                        icon: const SatrIcon('download', size: 20),
                        label: Text(l.save),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.s),
                TextButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: Text(l.useAnotherTool),
                ),
                const SizedBox(height: Space.l),
                const AdSlot(AdPlacement.resultBottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
