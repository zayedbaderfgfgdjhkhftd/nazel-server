import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../files/output_file.dart';

/// Share and "save to device" helpers.
class ShareService {
  /// Opens the system share sheet with the file. Returns false if sharing is
  /// unavailable (the caller then offers "Save to device" instead).
  static Future<bool> shareFile(File file, String name) async {
    try {
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, name: name, mimeType: mimeFromName(name))],
        fileNameOverrides: [name],
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Lets the user choose where to save a copy (Android: system "save" screen).
  /// Returns true if saved.
  static Future<bool> saveToDevice(String name, Uint8List bytes) async {
    final uri = await FilePicker.saveFile(
      fileName: name,
      bytes: bytes,
      mimeType: mimeFromName(name),
    );
    return uri != null;
  }
}
