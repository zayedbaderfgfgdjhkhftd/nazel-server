import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// A file another app shared with Satr (Android share sheet / "Open with").
/// It has already been copied into the app's cache by the native side.
class SharedInFile {
  SharedInFile({required this.path, required this.name, this.mime});
  final String path;
  final String name;
  final String? mime;
}

/// Small native bridge (see android/app/src/main/kotlin/.../MainActivity.kt).
class PlatformBridge {
  PlatformBridge() {
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'sharedFiles') {
          _shared.add(_parse(call.arguments));
        }
        return null;
      });
    }
  }

  static const _channel = MethodChannel('app.satr.pdf/platform');
  final _shared = StreamController<List<SharedInFile>>.broadcast();

  /// Files shared while the app is running.
  Stream<List<SharedInFile>> get sharedFiles => _shared.stream;

  /// Files that launched the app (consumed once).
  Future<List<SharedInFile>> takeInitialSharedFiles() async {
    if (!Platform.isAndroid) return const [];
    try {
      return _parse(await _channel.invokeMethod('takeSharedFiles'));
    } catch (_) {
      return const [];
    }
  }

  /// Total device RAM in bytes, or null if unknown.
  Future<int?> totalMemory() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<int>('totalMemory');
    } catch (_) {
      return null;
    }
  }

  /// Free space on the app's storage volume in bytes, or null if unknown.
  Future<int?> freeSpace() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<int>('freeSpace');
    } catch (_) {
      return null;
    }
  }

  List<SharedInFile> _parse(Object? args) {
    if (args is! List) return const [];
    return [
      for (final e in args)
        if (e is Map && e['path'] is String)
          SharedInFile(
            path: e['path'] as String,
            name: (e['name'] as String?) ?? 'file',
            mime: e['mime'] as String?,
          ),
    ];
  }
}
