import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../config/app_config.dart';
import '../core/errors.dart';
import '../core/files/output_file.dart';
import '../core/pdf/page_ranges.dart';
import '../l10n/gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get lang => Localizations.localeOf(this).languageCode;
  String get appName => AppConfig.appName(lang);
}

/// Human-readable size using the current locale's digits.
String formatBytes(BuildContext context, int bytes) {
  final lang = context.lang;
  final units = lang == 'ar' ? ['بايت', 'ك.ب', 'م.ب', 'ج.ب'] : ['B', 'KB', 'MB', 'GB'];
  var v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  final f = NumberFormat(i == 0 || v >= 100 ? '#,##0' : '#,##0.#', lang);
  return '${f.format(v)} ${units[i]}';
}

String formatNumber(BuildContext context, num n) => NumberFormat.decimalPattern(context.lang).format(n);

// Western digits everywhere (sizes, counts and dates match); Arabic month names.
String formatDateTime(BuildContext context, DateTime d) =>
    (DateFormat.yMMMd(context.lang).add_jm()..useNativeDigits = false).format(d);

String formatDate(BuildContext context, DateTime d) =>
    (DateFormat.yMMMd(context.lang)..useNativeDigits = false).format(d);

/// Translated message for any error thrown by a tool.
String errorMessage(BuildContext context, Object error) {
  final l = context.l10n;
  if (error is AppException) {
    return switch (error.code) {
      AppErrorCode.corrupt => l.errCorrupt,
      AppErrorCode.encrypted => l.errEncrypted,
      AppErrorCode.unsupportedType => l.errUnsupportedType,
      AppErrorCode.notPdf => l.errNotPdf,
      AppErrorCode.notImage => l.errNotImage,
      AppErrorCode.heicUnsupported => l.errHeic,
      AppErrorCode.emptyFile => l.errEmptyFile,
      AppErrorCode.outputInvalid => l.errOutputInvalid,
      AppErrorCode.ocrFailed => l.errOcr,
      AppErrorCode.nothingSelected => l.errNothingSelected,
      AppErrorCode.generic => l.errGeneric,
    };
  }
  if (error is RangeParseException) return rangeErrorMessage(context, error, 0);
  return l.errGeneric;
}

String rangeErrorMessage(BuildContext context, RangeParseException e, int max) {
  final l = context.l10n;
  return switch (e.error) {
    RangeError.empty => l.rangeErrEmpty,
    RangeError.syntax => l.rangeErrSyntax,
    RangeError.outOfBounds => l.rangeErrOutOfBounds(max),
    RangeError.reversed => l.rangeErrReversed,
  };
}

String kindLabel(BuildContext context, FileKind k) {
  final l = context.l10n;
  return switch (k) {
    FileKind.pdf => l.kindPdf,
    FileKind.image => l.kindImage,
    FileKind.text => l.kindText,
    FileKind.zip => l.kindZip,
    FileKind.docx => l.kindDocx,
    FileKind.other => l.kindOther,
  };
}
