// Direct PDFium calls for features pdfrx does not wrap: stamping images onto
// pages (watermark, page numbers, drawn signature), reading metadata and the
// PDF version.
//
// All calls run inside `PdfDocument.useNativeDocumentHandle`, which suspends
// pdfrx's own PDFium worker, so PDFium is never used from two threads at once.
// Longer loops run in a short-lived isolate to keep the UI responsive.

import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:pdfium_dart/pdfium_dart.dart' as pd;
import 'package:pdfrx/pdfrx.dart';

/// Where a stamp goes on a page, in the page's *visual* coordinate system
/// (points, origin at the top-left corner of the page as displayed, taking
/// the page's /Rotate into account).
class StampPlacement {
  const StampPlacement({
    required this.pageIndex,
    required this.stampIndex,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int pageIndex;

  /// Index of the page inside the stamp PDF to draw.
  final int stampIndex;
  final double x;
  final double y;
  final double width;
  final double height;
}

class _StampArgs {
  _StampArgs(this.docAddress, this.stampPdf, this.placements, this.modulePath);
  final int docAddress;
  final Uint8List stampPdf;
  final List<StampPlacement> placements;
  final String? modulePath;
}

/// Draws pages of [stampPdf] onto pages of [doc] as Form XObjects.
///
/// Each stamp page is converted to ONE XObject that is shared by every page
/// using it, so a watermark on 300 pages is stored once. The original page
/// content is not regenerated: PDFium appends a new content stream.
Future<int> stampPages(
  PdfDocument doc,
  Uint8List stampPdf,
  List<StampPlacement> placements,
) {
  final modulePath = Pdfrx.pdfiumModulePath;
  return doc.useNativeDocumentHandle(
    (handle) => Isolate.run(
      () => _stampNative(_StampArgs(handle, stampPdf, placements, modulePath)),
    ),
  );
}

int _stampNative(_StampArgs a) {
  final pdfium = pd.getPdfium(modulePath: a.modulePath);
  final doc = pd.FPDF_DOCUMENT.fromAddress(a.docAddress);
  return using((arena) {
    final buf = arena<Uint8>(a.stampPdf.length);
    buf.asTypedList(a.stampPdf.length).setAll(0, a.stampPdf);
    final stampDoc = pdfium.FPDF_LoadMemDocument64(buf.cast(), a.stampPdf.length, nullptr);
    if (stampDoc == nullptr) {
      throw Exception('Stamp PDF could not be loaded (${pdfium.FPDF_GetLastError()})');
    }
    final xobjects = <int, pd.FPDF_XOBJECT>{};
    final stampSizes = <int, ({double w, double h})>{};
    var stamped = 0;
    try {
      final byPage = <int, List<StampPlacement>>{};
      for (final pl in a.placements) {
        (byPage[pl.pageIndex] ??= []).add(pl);
      }
      final rect = arena<pd.FS_RECTF>();
      final size = arena<pd.FS_SIZEF>();
      final pageCount = pdfium.FPDF_GetPageCount(doc);
      for (final entry in byPage.entries) {
        if (entry.key < 0 || entry.key >= pageCount) continue;
        final page = pdfium.FPDF_LoadPage(doc, entry.key);
        if (page == nullptr) continue;
        try {
          final rot = pdfium.FPDFPage_GetRotation(page) & 3;
          if (pdfium.FPDF_GetPageBoundingBox(page, rect) == 0) continue;
          final l = rect.ref.left;
          final t = rect.ref.top;
          final r = rect.ref.right;
          final b = rect.ref.bottom;
          for (final pl in entry.value) {
            final xo = xobjects.putIfAbsent(
              pl.stampIndex,
              () => pdfium.FPDF_NewXObjectFromPage(doc, stampDoc, pl.stampIndex),
            );
            if (xo == nullptr) continue;
            final ss = stampSizes.putIfAbsent(pl.stampIndex, () {
              pdfium.FPDF_GetPageSizeByIndexF(stampDoc, pl.stampIndex, size);
              return (w: size.ref.width, h: size.ref.height);
            });
            final form = pdfium.FPDF_NewFormObjectFromXObject(xo);
            if (form == nullptr) continue;
            final m = stampMatrix(
              stampWidth: ss.w,
              stampHeight: ss.h,
              x: pl.x,
              y: pl.y,
              width: pl.width,
              height: pl.height,
              rotation: rot,
              left: l,
              top: t,
              right: r,
              bottom: b,
            );
            pdfium.FPDFPageObj_Transform(form, m[0], m[1], m[2], m[3], m[4], m[5]);
            pdfium.FPDFPage_InsertObject(page, form);
            stamped++;
          }
          pdfium.FPDFPage_GenerateContent(page);
        } finally {
          pdfium.FPDF_ClosePage(page);
        }
      }
    } finally {
      for (final xo in xobjects.values) {
        if (xo != nullptr) pdfium.FPDF_CloseXObject(xo);
      }
      pdfium.FPDF_CloseDocument(stampDoc);
    }
    return stamped;
  });
}

/// Maps a point in the page's visual space (origin top-left, y down) to PDF
/// user space for a page whose crop box is (left, top, right, bottom) and
/// whose /Rotate is `rotation` * 90 degrees clockwise.
(double, double) visualToUser(
  double xv,
  double yv, {
  required int rotation,
  required double left,
  required double top,
  required double right,
  required double bottom,
}) {
  switch (rotation & 3) {
    case 1:
      return (left + yv, bottom + xv);
    case 2:
      return (right - xv, bottom + yv);
    case 3:
      return (right - yv, top - xv);
    default:
      return (left + xv, top - yv);
  }
}

/// The affine matrix [a, b, c, d, e, f] that draws a stamp page of
/// stampWidth x stampHeight points upright into the visual rectangle
/// (x, y, width, height) of the target page.
List<double> stampMatrix({
  required double stampWidth,
  required double stampHeight,
  required double x,
  required double y,
  required double width,
  required double height,
  required int rotation,
  required double left,
  required double top,
  required double right,
  required double bottom,
}) {
  (double, double) map(double u, double v) {
    final xv = x + u * (width / stampWidth);
    final yv = y + height - v * (height / stampHeight);
    return visualToUser(xv, yv,
        rotation: rotation, left: left, top: top, right: right, bottom: bottom);
  }

  final p0 = map(0, 0);
  final p1 = map(stampWidth, 0);
  final p2 = map(0, stampHeight);
  return [
    (p1.$1 - p0.$1) / stampWidth,
    (p1.$2 - p0.$2) / stampWidth,
    (p2.$1 - p0.$1) / stampHeight,
    (p2.$2 - p0.$2) / stampHeight,
    p0.$1,
    p0.$2,
  ];
}

/// Document information read directly from PDFium.
class NativeDocInfo {
  NativeDocInfo({required this.version, required this.meta});

  /// e.g. "1.7", or null if unknown.
  final String? version;

  /// Info dictionary entries (Title, Author, ...). Empty values are omitted.
  final Map<String, String> meta;
}

const kMetaTags = [
  'Title',
  'Author',
  'Subject',
  'Keywords',
  'Creator',
  'Producer',
  'CreationDate',
  'ModDate',
];

Future<NativeDocInfo> readNativeInfo(PdfDocument doc) {
  final modulePath = Pdfrx.pdfiumModulePath;
  return doc.useNativeDocumentHandle((handle) {
    final pdfium = pd.getPdfium(modulePath: modulePath);
    final d = pd.FPDF_DOCUMENT.fromAddress(handle);
    return using((arena) {
      final ver = arena<Int>();
      String? version;
      if (pdfium.FPDF_GetFileVersion(d, ver) != 0) {
        final v = ver.value;
        version = '${v ~/ 10}.${v % 10}';
      }
      final meta = <String, String>{};
      for (final tag in kMetaTags) {
        final tagPtr = tag.toNativeUtf8(allocator: arena).cast<Char>();
        final len = pdfium.FPDF_GetMetaText(d, tagPtr, nullptr, 0);
        if (len <= 2) continue;
        final buf = arena<Uint8>(len);
        pdfium.FPDF_GetMetaText(d, tagPtr, buf.cast(), len);
        final units = buf.cast<Uint16>().asTypedList(len ~/ 2);
        final end = units.indexOf(0);
        final s = String.fromCharCodes(end >= 0 ? units.sublist(0, end) : units).trim();
        if (s.isNotEmpty) meta[tag] = s;
      }
      return NativeDocInfo(version: version, meta: meta);
    });
  });
}

/// Parses a PDF date like `D:20240131120000+03'00'`. Returns null if invalid.
DateTime? parsePdfDate(String? raw) {
  if (raw == null) return null;
  final m = RegExp(r"^(?:D:)?(\d{4})(\d{2})?(\d{2})?(\d{2})?(\d{2})?(\d{2})?([Zz+\-])?(\d{2})?'?(\d{2})?")
      .firstMatch(raw.trim());
  if (m == null) return null;
  int g(int i, int def) => m.group(i) == null ? def : int.parse(m.group(i)!);
  final utc = DateTime.utc(g(1, 0), g(2, 1), g(3, 1), g(4, 0), g(5, 0), g(6, 0));
  final sign = m.group(7);
  if (sign == null) return DateTime(utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second);
  if (sign == 'Z' || sign == 'z') return utc.toLocal();
  final offset = Duration(hours: g(8, 0), minutes: g(9, 0));
  return (sign == '+' ? utc.subtract(offset) : utc.add(offset)).toLocal();
}
