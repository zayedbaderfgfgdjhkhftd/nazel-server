// Pure-Dart image helpers. Safe to run in background isolates and in tests.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;

import '../errors.dart';

/// Decodes JPEG/PNG/WebP (not HEIC; see `platform_decode.dart`) and applies
/// the EXIF orientation so the pixels are upright.
img.Image decodeUpright(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) throw const AppException(AppErrorCode.corrupt, 'image decode');
  return img.bakeOrientation(image);
}

/// Builds an image from BGRA pixels (as produced by PDFium renders).
img.Image imageFromBgra(Uint8List bgra, int width, int height) => img.Image.fromBytes(
      width: width,
      height: height,
      bytes: bgra.buffer,
      bytesOffset: bgra.offsetInBytes,
      numChannels: 4,
      order: img.ChannelOrder.bgra,
    );

/// Builds an image from RGBA pixels (as produced by dart:ui).
img.Image imageFromRgba(Uint8List rgba, int width, int height) => img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgba.buffer,
      bytesOffset: rgba.offsetInBytes,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );

/// Message for [encodeBgraJob] (isolate-friendly record).
typedef BgraEncodeRequest = ({
  Uint8List bgra,
  int width,
  int height,
  bool png,
  int quality,
});

/// Encodes BGRA pixels as JPEG (on white) or PNG.
Uint8List encodeBgraJob(BgraEncodeRequest r) {
  var image = imageFromBgra(r.bgra, r.width, r.height);
  if (r.png) return img.encodePng(image, level: 6);
  // JPEG has no alpha: flatten onto white first.
  image = image.convert(numChannels: 3, alpha: 255);
  return img.encodeJpg(image, quality: r.quality);
}

/// Returns true if [image] has any pixel that is not fully opaque.
bool hasTransparency(img.Image image) {
  if (!image.hasAlpha) return false;
  for (final p in image) {
    if (p.a < p.maxChannelValue) return true;
  }
  return false;
}

/// Options for OCR pre-processing.
class OcrPreprocess {
  const OcrPreprocess({this.grayscale = true, this.contrast = true, this.binarize = false});
  final bool grayscale;
  final bool contrast;
  final bool binarize;
}

typedef OcrPrepRequest = ({Uint8List bytes, bool grayscale, bool contrast, bool binarize, int maxSide});

/// Pre-processes an image for OCR and returns PNG bytes.
Uint8List preprocessForOcrJob(OcrPrepRequest r) {
  var image = decodeUpright(r.bytes);
  image = flattenOnWhite(image);
  final longest = math.max(image.width, image.height);
  if (longest > r.maxSide) {
    final s = r.maxSide / longest;
    image = img.copyResize(image,
        width: (image.width * s).round(),
        height: (image.height * s).round(),
        interpolation: img.Interpolation.average);
  }
  if (r.grayscale || r.binarize) image = img.grayscale(image);
  if (r.contrast) image = img.normalize(image, min: 0, max: 255);
  if (r.binarize) image = binarizeOtsu(image);
  return img.encodePng(image, level: 1);
}

/// Composites transparent pixels onto white (OCR and JPEG need opaque input).
img.Image flattenOnWhite(img.Image image) {
  if (!image.hasAlpha) return image;
  final out = img.Image(width: image.width, height: image.height);
  img.fill(out, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(out, image);
  return out;
}

/// Black & white conversion with Otsu's threshold.
img.Image binarizeOtsu(img.Image gray) {
  final hist = List<int>.filled(256, 0);
  for (final p in gray) {
    hist[p.luminance.toInt().clamp(0, 255)]++;
  }
  final total = gray.width * gray.height;
  var sum = 0.0;
  for (var i = 0; i < 256; i++) {
    sum += i * hist[i];
  }
  var sumB = 0.0, wB = 0, best = 0.0, threshold = 127;
  for (var t = 0; t < 256; t++) {
    wB += hist[t];
    if (wB == 0) continue;
    final wF = total - wB;
    if (wF == 0) break;
    sumB += t * hist[t];
    final mB = sumB / wB;
    final mF = (sum - sumB) / wF;
    final between = wB * wF * (mB - mF) * (mB - mF);
    if (between > best) {
      best = between;
      threshold = t;
    }
  }
  final out = img.Image(width: gray.width, height: gray.height);
  for (final p in gray) {
    final v = p.luminance > threshold ? 255 : 0;
    out.setPixelRgb(p.x, p.y, v, v, v);
  }
  return out;
}

typedef RemoveBgRequest = ({Uint8List bytes, int threshold});

/// Makes near-white pixels transparent (for uploaded signature photos).
/// Pixels darker than [threshold] stay opaque; lighter ones fade out.
/// Returns a trimmed PNG.
Uint8List removeWhiteBackgroundJob(RemoveBgRequest r) {
  var image = decodeUpright(r.bytes).convert(numChannels: 4);
  final t = r.threshold.clamp(100, 250);
  for (final p in image) {
    final lum = p.luminance.toDouble();
    final alpha = lum >= t ? 0.0 : ((t - lum) / (t * 0.35)).clamp(0.0, 1.0) * 255;
    p.a = math.min(p.a.toDouble(), alpha);
  }
  image = trimTransparent(image);
  return img.encodePng(image, level: 6);
}

/// Crops fully transparent borders.
img.Image trimTransparent(img.Image image) {
  var minX = image.width, minY = image.height, maxX = -1, maxY = -1;
  for (final p in image) {
    if (p.a > 8) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }
  }
  if (maxX < 0) return image;
  return img.copyCrop(image, x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);
}

typedef WatermarkImageRequest = ({Uint8List bytes, double opacity, double rotationDeg, int maxSide});

/// Prepares an image watermark: downsizes, applies opacity and rotation.
/// Returns (png, width, height) in pixels.
({Uint8List png, int width, int height}) prepareWatermarkImageJob(WatermarkImageRequest r) {
  var image = decodeUpright(r.bytes).convert(numChannels: 4);
  final longest = math.max(image.width, image.height);
  if (longest > r.maxSide) {
    final s = r.maxSide / longest;
    image = img.copyResize(image,
        width: math.max(1, (image.width * s).round()),
        height: math.max(1, (image.height * s).round()),
        interpolation: img.Interpolation.average);
  }
  final o = r.opacity.clamp(0.0, 1.0);
  for (final p in image) {
    p.a = p.a * o;
  }
  if (r.rotationDeg.abs() > 0.01) {
    // copyRotate turns clockwise for positive angles.
    image = img.copyRotate(image, angle: -r.rotationDeg, interpolation: img.Interpolation.linear);
  }
  return (png: img.encodePng(image, level: 6), width: image.width, height: image.height);
}

/// Packs [files] (name -> bytes) into a ZIP. PDFs and images are already
/// compressed, so they are stored without recompression.
Uint8List zipFiles(Map<String, Uint8List> files) {
  final archive = Archive();
  for (final e in files.entries) {
    final f = ArchiveFile.bytes(e.key, e.value);
    final ext = e.key.split('.').last.toLowerCase();
    if (const {'pdf', 'jpg', 'jpeg', 'png', 'zip', 'docx'}.contains(ext)) {
      f.compression = CompressionType.none;
    }
    archive.addFile(f);
  }
  return ZipEncoder().encodeBytes(archive);
}
