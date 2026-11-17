import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../config/app_config.dart';
import '../core/platform/platform_bridge.dart';
import '../core/storage/file_store.dart';
import '../core/storage/settings_store.dart';

/// App-wide services, created once in main().
class AppServices {
  AppServices({
    required this.files,
    required this.settings,
    required this.platform,
    required this.tempDir,
  });

  final FileStore files;
  final SettingsStore settings;
  final PlatformBridge platform;
  final Directory tempDir;

  /// Files shared into the app that the UI has not handled yet.
  final ValueNotifier<List<SharedInFile>> pendingShared = ValueNotifier(const []);

  int? _totalMemory;

  /// Soft size limit before warning the user, based on device RAM.
  Future<int> softSizeLimit() async {
    _totalMemory ??= await platform.totalMemory() ?? AppConfig.lowMemoryDeviceBytes;
    return _totalMemory! <= AppConfig.lowMemoryDeviceBytes
        ? AppConfig.softLimitLowMemoryBytes
        : AppConfig.softLimitHighMemoryBytes;
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
