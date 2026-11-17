import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

import '../errors.dart';
import '../files/file_type.dart';
import 'image_ops.dart';

/// Decodes HEIC/HEIF with the platform codec (Android 9+ / iOS) and returns
/// JPEG bytes that the rest of the app can use. Must run on the UI isolate.
Future<Uint8List> heicToJpeg(Uint8List bytes, {int quality = 92}) async {
  ui.Codec codec;
  try {
    codec = await ui.instantiateImageCodec(bytes);
  } catch (e) {
    throw AppException(AppErrorCode.heicUnsupported, e);
  }
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  final w = image.width, h = image.height;
  image.dispose();
  codec.dispose();
  if (data == null) throw const AppException(AppErrorCode.heicUnsupported);
  final rgba = data.buffer.asUint8List();
  // JPEG encoding is CPU-heavy: keep it off the UI isolate.
  return Isolate.run(() => encodeRgbaToJpeg(rgba, w, h, quality));
}

Uint8List encodeRgbaToJpeg(Uint8List rgba, int w, int h, int quality) {
  final image = imageFromRgba(rgba, w, h).convert(numChannels: 3, alpha: 255);
  return img.encodeJpg(image, quality: quality);
}

/// Returns bytes in a format the pure-Dart pipeline can read: HEIC is
/// converted to JPEG via the platform; other images pass through unchanged.
Future<Uint8List> normalizeImageInput(Uint8List bytes) async {
  final t = detectFileType(bytes);
  if (t == DetectedType.heic) return heicToJpeg(bytes);
  if (!t.isImage) throw const AppException(AppErrorCode.notImage);
  return bytes;
}
