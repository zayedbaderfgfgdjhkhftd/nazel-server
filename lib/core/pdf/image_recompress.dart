// "Recommended" compression: re-encode large embedded JPEG photos at a lower
// resolution/quality using PDFium's page-object API. Text and vector content
// stay untouched and selectable.
//
// Safety rules (anything else is left alone):
//  - only top-level image objects with exactly one filter, DCTDecode (JPEG);
//  - only gray/RGB/ICC colour (no CMYK, Lab, indexed, separation ...);
//  - never images with any transparency (soft masks, colour-key masks):
//    PDFium's JPEG loader rebuilds the image dictionary and would drop them;
//  - only replaced when the new JPEG is at least 15% smaller.
// The caller then compares renders of every page before/after and falls back
// to light compression if anything changed visibly.

import 'dart:ffi';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:image/image.dart' as img;
import 'package:pdfium_dart/pdfium_dart.dart' as pd;
import 'package:pdfrx/pdfrx.dart';

class RecompressStats {
  RecompressStats(this.recoded, this.bytesBefore, this.bytesAfter);
  final int recoded;
  final int bytesBefore;
  final int bytesAfter;
}

typedef _RecompressArgs = ({int doc, int targetDpi, int quality, String? modulePath});

Future<RecompressStats> recompressJpegImages(
  PdfDocument doc, {
  required int targetDpi,
  required int quality,
}) {
  final modulePath = Pdfrx.pdfiumModulePath;
  return doc.useNativeDocumentHandle((h) => Isolate.run(() => _recompressNative(
      (doc: h, targetDpi: targetDpi, quality: quality, modulePath: modulePath))));
}

typedef _GetBlockNative = Int Function(Pointer<Void>, UnsignedLong, Pointer<UnsignedChar>, UnsignedLong);

Uint8List? _currentJpeg;

int _getBlock(Pointer<Void> param, int position, Pointer<UnsignedChar> buf, int size) {
  final src = _currentJpeg;
  if (src == null || position + size > src.length) return 0;
  buf.cast<Uint8>().asTypedList(size).setRange(0, size, src, position);
  return 1;
}

RecompressStats _recompressNative(_RecompressArgs a) {
  final pdfium = pd.getPdfium(modulePath: a.modulePath);
  final doc = pd.FPDF_DOCUMENT.fromAddress(a.doc);
  final cb = NativeCallable<_GetBlockNative>.isolateLocal(_getBlock, exceptionalReturn: 0);
  var recoded = 0, before = 0, after = 0;
  try {
    using((arena) {
      final meta = arena<pd.FPDF_IMAGEOBJ_METADATA>();
      final fa = arena<pd.FPDF_FILEACCESS>();
      final pagePtr = arena<pd.FPDF_PAGE>();
      final filterBuf = arena<Uint8>(64);
      final pageCount = pdfium.FPDF_GetPageCount(doc);
      for (var p = 0; p < pageCount; p++) {
        final page = pdfium.FPDF_LoadPage(doc, p);
        if (page == nullptr) continue;
        var changed = false;
        try {
          final n = pdfium.FPDFPage_CountObjects(page);
          for (var i = 0; i < n; i++) {
            final obj = pdfium.FPDFPage_GetObject(page, i);
            if (obj == nullptr || pdfium.FPDFPageObj_GetType(obj) != pd.FPDF_PAGEOBJ_IMAGE) continue;
            if (pdfium.FPDFImageObj_GetImageFilterCount(obj) != 1) continue;
            final fl = pdfium.FPDFImageObj_GetImageFilter(obj, 0, filterBuf.cast(), 64);
            if (fl <= 1 || fl > 64) continue;
            final filter = String.fromCharCodes(filterBuf.asTypedList(fl - 1));
            if (filter != 'DCTDecode') continue;
            if (pdfium.FPDFImageObj_GetImageMetadata(obj, page, meta) == 0) continue;
            final cs = meta.ref.colorspace;
            if (cs != pd.FPDF_COLORSPACE_DEVICEGRAY &&
                cs != pd.FPDF_COLORSPACE_DEVICERGB &&
                cs != pd.FPDF_COLORSPACE_ICCBASED) {
              continue;
            }
            final bpp = meta.ref.bits_per_pixel;
            if (bpp != 8 && bpp != 24) continue;
            final raw = pdfium.FPDFImageObj_GetImageDataRaw(obj, nullptr, 0);
            if (raw < 24 * 1024) continue; // not worth it

            // Transparency check: a rendered bitmap with any non-opaque
            // pixel means a mask is involved -> skip.
            final rendered = pdfium.FPDFImageObj_GetRenderedBitmap(doc, page, obj);
            if (rendered == nullptr) continue;
            final transparent = _bitmapHasTransparency(pdfium, rendered);
            pdfium.FPDFBitmap_Destroy(rendered);
            if (transparent) continue;

            final bmp = pdfium.FPDFImageObj_GetBitmap(obj);
            if (bmp == nullptr) continue;
            img.Image? image;
            try {
              image = _bitmapToImage(pdfium, bmp);
            } finally {
              pdfium.FPDFBitmap_Destroy(bmp);
            }
            if (image == null) continue;
            final dpi = math.max(meta.ref.horizontal_dpi, meta.ref.vertical_dpi);
            if (dpi > a.targetDpi * 1.1) {
              final s = a.targetDpi / dpi;
              image = img.copyResize(image,
                  width: math.max(1, (image.width * s).round()),
                  height: math.max(1, (image.height * s).round()),
                  interpolation: img.Interpolation.average);
            }
            final jpeg = img.encodeJpg(image, quality: a.quality);
            if (jpeg.length >= raw * 0.85) continue;
            _currentJpeg = jpeg;
            fa.ref.m_FileLen = jpeg.length;
            fa.ref.m_GetBlock = cb.nativeFunction;
            fa.ref.m_Param = nullptr;
            pagePtr.value = page;
            if (pdfium.FPDFImageObj_LoadJpegFileInline(pagePtr, 1, obj, fa) != 0) {
              recoded++;
              before += raw;
              after += jpeg.length;
              changed = true;
            }
            _currentJpeg = null;
          }
          if (changed) pdfium.FPDFPage_GenerateContent(page);
        } finally {
          pdfium.FPDF_ClosePage(page);
        }
      }
    });
  } finally {
    cb.close();
  }
  return RecompressStats(recoded, before, after);
}

bool _bitmapHasTransparency(pd.PDFium pdfium, pd.FPDF_BITMAP bmp) {
  if (pdfium.FPDFBitmap_GetFormat(bmp) != pd.FPDFBitmap_BGRA) return false;
  final w = pdfium.FPDFBitmap_GetWidth(bmp);
  final h = pdfium.FPDFBitmap_GetHeight(bmp);
  final stride = pdfium.FPDFBitmap_GetStride(bmp);
  final buf = pdfium.FPDFBitmap_GetBuffer(bmp).cast<Uint8>().asTypedList(stride * h);
  for (var y = 0; y < h; y++) {
    final row = y * stride;
    for (var x = 0; x < w; x++) {
      if (buf[row + x * 4 + 3] != 255) return true;
    }
  }
  return false;
}

img.Image? _bitmapToImage(pd.PDFium pdfium, pd.FPDF_BITMAP bmp) {
  final format = pdfium.FPDFBitmap_GetFormat(bmp);
  final w = pdfium.FPDFBitmap_GetWidth(bmp);
  final h = pdfium.FPDFBitmap_GetHeight(bmp);
  final stride = pdfium.FPDFBitmap_GetStride(bmp);
  if (w <= 0 || h <= 0) return null;
  final buf = pdfium.FPDFBitmap_GetBuffer(bmp).cast<Uint8>().asTypedList(stride * h);
  final out = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    final row = y * stride;
    for (var x = 0; x < w; x++) {
      switch (format) {
        case pd.FPDFBitmap_Gray:
          final v = buf[row + x];
          out.setPixelRgb(x, y, v, v, v);
        case pd.FPDFBitmap_BGR:
          final o = row + x * 3;
          out.setPixelRgb(x, y, buf[o + 2], buf[o + 1], buf[o]);
        case pd.FPDFBitmap_BGRx:
        case pd.FPDFBitmap_BGRA:
          final o = row + x * 4;
          out.setPixelRgb(x, y, buf[o + 2], buf[o + 1], buf[o]);
        default:
          return null;
      }
    }
  }
  return out;
}
