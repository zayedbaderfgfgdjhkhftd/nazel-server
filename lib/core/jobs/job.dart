import 'dart:async';
import 'dart:isolate';

import '../errors.dart';

/// Progress + cancellation handle passed to every tool's `run()`.
///
/// Heavy work runs off the UI isolate (PDFium runs in pdfrx's worker isolate,
/// pixel/encoding work in short-lived isolates). Cancellation is checked
/// between units of work (a page, a file) and, for isolate work, the isolate
/// is killed immediately.
class JobContext {
  JobContext({this.onProgress});

  final void Function(double fraction, JobStage stage)? onProgress;

  bool _cancelled = false;
  final List<void Function()> _cancelHooks = [];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final h in List.of(_cancelHooks)) {
      h();
    }
  }

  /// Throws [JobCancelledException] if the user cancelled.
  void checkCancelled() {
    if (_cancelled) throw const JobCancelledException();
  }

  /// Reports progress (0..1) and checks cancellation.
  void progress(double fraction, [JobStage stage = const JobStage.working()]) {
    checkCancelled();
    onProgress?.call(fraction.clamp(0.0, 1.0), stage);
  }

  /// Runs [computation] in a new isolate. The isolate is killed at once if the
  /// job is cancelled.
  Future<R> compute<M, R>(FutureOr<R> Function(M message) computation, M message) async {
    checkCancelled();
    final resultPort = ReceivePort();
    final completer = Completer<R>();
    late final void Function() hook;
    Isolate? isolate;
    hook = () {
      isolate?.kill(priority: Isolate.immediate);
      resultPort.close();
      if (!completer.isCompleted) {
        completer.completeError(const JobCancelledException());
      }
    };
    _cancelHooks.add(hook);
    try {
      isolate = await Isolate.spawn<_IsolateTask<M, R>>(
        _isolateEntry,
        _IsolateTask(computation, message, resultPort.sendPort),
        onError: resultPort.sendPort,
        onExit: resultPort.sendPort,
      );
      if (_cancelled) hook();
      resultPort.listen((msg) {
        if (completer.isCompleted) return;
        if (msg is _IsolateResult) {
          if (msg.error != null) {
            completer.completeError(msg.error!, msg.stack);
          } else {
            completer.complete(msg.value as R);
          }
        } else if (msg is List && msg.length == 2) {
          // Uncaught error from onError: [error, stack].
          completer.completeError(Exception(msg[0]), StackTrace.fromString('${msg[1]}'));
        } else if (msg == null) {
          // Isolate exited without a result.
          completer.completeError(const JobCancelledException());
        }
      });
      return await completer.future;
    } finally {
      _cancelHooks.remove(hook);
      resultPort.close();
    }
  }
}

class _IsolateTask<M, R> {
  _IsolateTask(this.fn, this.message, this.port);
  final FutureOr<R> Function(M) fn;
  final M message;
  final SendPort port;
}

class _IsolateResult {
  _IsolateResult(this.value, this.error, this.stack);
  final Object? value;
  final Object? error;
  final StackTrace? stack;
}

Future<void> _isolateEntry<M, R>(_IsolateTask<M, R> task) async {
  try {
    final v = await task.fn(task.message);
    Isolate.exit(task.port, _IsolateResult(v, null, null));
  } catch (e, s) {
    // Errors must be sendable; AppException/JobCancelledException are.
    final err = (e is AppException || e is JobCancelledException) ? e : Exception('$e');
    Isolate.exit(task.port, _IsolateResult(null, err, s));
  }
}

/// What the job is doing right now (shown under the progress bar).
class JobStage {
  const JobStage.working()
      : kind = JobStageKind.working,
        current = 0,
        total = 0;
  const JobStage.page(this.current, this.total) : kind = JobStageKind.page;
  const JobStage.file(this.current, this.total) : kind = JobStageKind.file;
  const JobStage.preparingOcr()
      : kind = JobStageKind.preparingOcr,
        current = 0,
        total = 0;
  const JobStage.readingText()
      : kind = JobStageKind.readingText,
        current = 0,
        total = 0;
  const JobStage.verifying()
      : kind = JobStageKind.verifying,
        current = 0,
        total = 0;

  final JobStageKind kind;
  final int current;
  final int total;
}

enum JobStageKind { working, page, file, preparingOcr, readingText, verifying }
