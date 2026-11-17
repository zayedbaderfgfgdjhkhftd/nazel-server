/// Product-level settings in ONE place: name, ads, limits.
///
/// Change the app name here (and in android/app/src/main/AndroidManifest.xml
/// `android:label`, which Android reads before Flutter starts).
library;

class AppConfig {
  AppConfig._();

  /// Display name in Arabic and Latin script.
  static const String appNameAr = 'سَطر';
  static const String appNameEn = 'Satr PDF';

  /// Shown in Settings > About. Keep in sync with pubspec.yaml `version`.
  static const String version = '1.0.1';

  /// Android application id (Google Play package name).
  static const String packageId = 'app.satr.pdf';

  /// Ads are prepared but OFF. While false, no ad SDK is compiled into the
  /// app and nothing ad-related is loaded. See ADS.md to turn them on.
  static const AdsConfig ads = AdsConfig(enabled: false);

  /// Files in the trash are deleted for good after this many days.
  static const int trashRetentionDays = 30;

  /// OCR words below this confidence (0-100) are highlighted for review.
  static const int ocrLowConfidence = 60;

  /// Soft input-size warning thresholds, chosen from device memory.
  static const int softLimitLowMemoryBytes = 50 * 1024 * 1024;
  static const int softLimitHighMemoryBytes = 150 * 1024 * 1024;

  /// Devices with this much RAM or less use the low soft limit.
  static const int lowMemoryDeviceBytes = 4 * 1024 * 1024 * 1024;

  static String appName(String languageCode) =>
      languageCode == 'ar' ? appNameAr : appNameEn;
}

class AdsConfig {
  const AdsConfig({required this.enabled});

  /// Master switch. When false, `AdSlot` renders nothing.
  final bool enabled;
}
