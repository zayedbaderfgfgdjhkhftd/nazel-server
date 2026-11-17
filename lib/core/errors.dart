/// Error codes shown to users through translated messages.
enum AppErrorCode {
  corrupt,
  encrypted,
  unsupportedType,
  notPdf,
  notImage,
  heicUnsupported,
  emptyFile,
  outputInvalid,
  ocrFailed,
  nothingSelected,
  generic,
}

/// An error with a code the UI can translate.
class AppException implements Exception {
  const AppException(this.code, [this.detail]);

  final AppErrorCode code;

  /// Developer detail (never shown verbatim to users).
  final Object? detail;

  @override
  String toString() => 'AppException($code${detail == null ? '' : ': $detail'})';
}

/// Thrown when the user cancels a running job.
class JobCancelledException implements Exception {
  const JobCancelledException();

  @override
  String toString() => 'JobCancelledException';
}
