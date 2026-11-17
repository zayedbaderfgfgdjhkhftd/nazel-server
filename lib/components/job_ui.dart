import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/errors.dart';
import '../core/jobs/job.dart';
import '../design/tokens.dart';
import 'common.dart';
import 'l10n_ext.dart';

/// Runs [task] with a non-dismissible progress sheet (progress bar, current
/// step, Cancel button). Returns the result, or null if the user cancelled or
/// an error occurred (a translated message is shown in that case).
///
/// The caller should disable its own "run" button while this is pending.
Future<T?> runJob<T>(BuildContext context, Future<T> Function(JobContext ctx) task) async {
  final progress = ValueNotifier<(double, JobStage)>((0, const JobStage.working()));
  final ctx = JobContext(onProgress: (f, s) => progress.value = (f, s));
  final done = Completer<void>();
  T? result;
  Object? error;

  final sheet = showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    showDragHandle: false,
    builder: (sheetContext) => PopScope(
      canPop: false,
      child: _ProgressSheet(progress: progress, onCancel: ctx.cancel),
    ),
  );

  // Let the sheet appear before heavy work starts.
  await Future<void>.delayed(const Duration(milliseconds: 16));
  try {
    result = await task(ctx);
  } catch (e) {
    error = e;
  } finally {
    done.complete();
  }
  if (context.mounted) Navigator.of(context).pop();
  await sheet;
  progress.dispose();

  if (!context.mounted) return null;
  if (error is JobCancelledException || (error == null && ctx.isCancelled)) {
    showMessage(context, context.l10n.cancelled);
    return null;
  }
  if (error != null) {
    debugPrint('Job failed: $error');
    await showErrorDialog(context, errorMessage(context, error));
    return null;
  }
  return result;
}

Future<void> showErrorDialog(BuildContext context, String message) => showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: Text(c.l10n.ok)),
        ],
      ),
    );

class _ProgressSheet extends StatelessWidget {
  const _ProgressSheet({required this.progress, required this.onCancel});
  final ValueNotifier<(double, JobStage)> progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = SatrColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.xl, Space.l),
        child: ValueListenableBuilder<(double, JobStage)>(
          valueListenable: progress,
          builder: (context, v, _) {
            final (fraction, stage) = v;
            final label = switch (stage.kind) {
              JobStageKind.page => l.progressPage(stage.current, stage.total),
              JobStageKind.file => l.progressFile(stage.current, stage.total),
              JobStageKind.verifying => l.progressVerifying,
              JobStageKind.preparingOcr => l.progressPreparingOcr,
              JobStageKind.readingText => l.progressReadingText,
              JobStageKind.working => l.working,
            };
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.working, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: Space.l),
                Semantics(
                  label: label,
                  value: '${(fraction * 100).round()}%',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: fraction <= 0.01 ? null : fraction,
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(height: Space.s),
                Text(label, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: c.textMuted)),
                const SizedBox(height: Space.l),
                OutlinedButton(onPressed: onCancel, child: Text(l.cancel)),
              ],
            );
          },
        ),
      ),
    );
  }
}
