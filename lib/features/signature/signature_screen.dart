import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../components/common.dart';
import '../../components/file_pick.dart';
import '../../components/job_ui.dart';
import '../../components/l10n_ext.dart';
import '../../components/tool_scaffold.dart';
import '../../core/files/file_type.dart';
import '../../core/image/image_ops.dart';
import '../../core/image/platform_decode.dart';
import '../../core/pdf/pdf_service.dart' show InputFile;
import '../../design/icons.dart';
import '../../design/tokens.dart';
import '../result/result_screen.dart';
import '../tools/tool_registry.dart';
import 'signature_tool.dart';

/// A signature image ready to place (PNG with transparency).
class SignatureImage {
  SignatureImage(this.png, this.width, this.height);
  final Uint8List png;
  final int width;
  final int height;
}

class SignatureScreen extends PdfToolWidget {
  const SignatureScreen({super.key, super.initial});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends SinglePdfToolState<SignatureScreen> {
  bool _drawMode = true;
  final _strokes = <List<Offset>>[];
  Color _ink = const Color(0xFF0F172A);
  double _thickness = 3;
  Size _padSize = Size.zero;

  Uint8List? _uploaded;
  bool _removeBg = true;
  SignatureImage? _uploadedPrepared;

  Future<void> _upload() async {
    final picked = await pickInputs(context, kind: PickKind.image);
    if (picked.isEmpty) return;
    var bytes = picked.first.bytes;
    if (detectFileType(bytes) == DetectedType.heic) bytes = await heicToJpeg(bytes);
    _uploaded = bytes;
    await _prepareUpload();
  }

  Future<void> _prepareUpload() async {
    final src = _uploaded;
    if (src == null) return;
    final removeBg = _removeBg;
    final png = await Isolate.run(() {
      if (removeBg) return removeWhiteBackgroundJob((bytes: src, threshold: 200));
      final im = decodeUpright(src);
      return img.encodePng(im);
    });
    final decoded = img.decodePng(png)!;
    if (!mounted) return;
    setState(() => _uploadedPrepared = SignatureImage(png, decoded.width, decoded.height));
  }

  /// Renders the drawn strokes (transparent background, 3x) and trims them.
  Future<SignatureImage?> _renderDrawing() async {
    if (_strokes.every((s) => s.isEmpty)) return null;
    const scale = 3.0;
    var minX = double.infinity, minY = double.infinity, maxX = -double.infinity, maxY = -double.infinity;
    for (final s in _strokes) {
      for (final p in s) {
        minX = math.min(minX, p.dx);
        minY = math.min(minY, p.dy);
        maxX = math.max(maxX, p.dx);
        maxY = math.max(maxY, p.dy);
      }
    }
    final pad = _thickness * 2;
    final w = ((maxX - minX + 2 * pad) * scale).ceil().clamp(1, 4000);
    final h = ((maxY - minY + 2 * pad) * scale).ceil().clamp(1, 4000);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(scale)
      ..translate(pad - minX, pad - minY);
    final paint = Paint()
      ..color = _ink
      ..strokeWidth = _thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in _strokes) {
      if (s.length == 1) {
        canvas.drawCircle(s.first, _thickness / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      } else {
        final path = Path()..moveTo(s.first.dx, s.first.dy);
        for (final p in s.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
    final image = await recorder.endRecording().toImage(w, h);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return SignatureImage(data!.buffer.asUint8List(), w, h);
  }

  Future<void> _next() async {
    final sig = _drawMode ? await _renderDrawing() : _uploadedPrepared;
    if (!mounted) return;
    if (sig == null) {
      showMessage(context, context.l10n.sigEmpty);
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _PlacementScreen(input: input!, document: doc!, signature: sig),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = SatrColors.of(context);
    final hasSig = _drawMode ? _strokes.any((s) => s.isNotEmpty) : _uploadedPrepared != null;
    return ToolScaffold(
      tool: ToolId.signature,
      actionLabel: l.sigNext,
      actionIcon: 'chevronEnd',
      onAction: input != null && hasSig ? _next : null,
      children: [
        NoticeBox(text: l.sigNotice, icon: 'signature'),
        inputSection(),
        if (input != null) ...[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChoiceRow<bool>(
                  label: l.toolSignature,
                  value: _drawMode,
                  options: {true: l.sigDraw, false: l.sigUpload},
                  onChanged: (v) => setState(() => _drawMode = v),
                ),
                const SizedBox(height: Space.l),
                if (_drawMode) ...[
                  AspectRatio(
                    aspectRatio: 2.6,
                    child: LayoutBuilder(builder: (context, box) {
                      _padSize = box.biggest;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(Radii.control),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: c.line),
                            borderRadius: BorderRadius.circular(Radii.control),
                          ),
                          child: GestureDetector(
                            onPanStart: (d) => setState(() => _strokes.add([d.localPosition])),
                            onPanUpdate: (d) => setState(() {
                              final p = d.localPosition;
                              if (p.dx >= 0 && p.dy >= 0 && p.dx <= _padSize.width && p.dy <= _padSize.height) {
                                _strokes.last.add(p);
                              }
                            }),
                            child: CustomPaint(
                              painter: _StrokesPainter(_strokes, _ink, _thickness),
                              child: _strokes.isEmpty
                                  ? Center(
                                      child: Text(l.sigDrawHere,
                                          style: const TextStyle(color: Color(0xFF6B7280))))
                                  : const SizedBox.expand(),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: Space.s),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _strokes.isEmpty ? null : () => setState(_strokes.removeLast),
                        icon: const SatrIcon('undo', size: 20),
                        label: Text(l.sigUndo),
                      ),
                      TextButton.icon(
                        onPressed: _strokes.isEmpty ? null : () => setState(_strokes.clear),
                        icon: const SatrIcon('eraser', size: 20),
                        label: Text(l.sigClear),
                      ),
                    ],
                  ),
                  ChoiceRow<Color>(
                    label: l.sigInk,
                    value: _ink,
                    options: {const Color(0xFF0F172A): l.colorBlack, const Color(0xFF1D4ED8): l.colorBlue},
                    onChanged: (v) => setState(() => _ink = v),
                  ),
                  const SizedBox(height: Space.s),
                  Text(l.sigThickness, style: Theme.of(context).textTheme.titleSmall),
                  Slider(value: _thickness, min: 1.5, max: 8, onChanged: (v) => setState(() => _thickness = v)),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: _upload,
                    icon: const SatrIcon('imageUp', size: 20),
                    label: Text(l.sigUpload),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.sigRemoveBg),
                    value: _removeBg,
                    onChanged: (v) {
                      setState(() => _removeBg = v);
                      _prepareUpload();
                    },
                  ),
                  if (_uploadedPrepared != null)
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: c.line),
                        borderRadius: BorderRadius.circular(Radii.control),
                      ),
                      padding: const EdgeInsets.all(Space.s),
                      child: Image.memory(_uploadedPrepared!.png, fit: BoxFit.contain),
                    ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StrokesPainter extends CustomPainter {
  _StrokesPainter(this.strokes, this.color, this.width);
  final List<List<Offset>> strokes;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.isEmpty) continue;
      if (s.length == 1) {
        canvas.drawCircle(s.first, width / 2, Paint()..color = color);
        continue;
      }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final p in s.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokesPainter old) => true;
}

/// Drag/resize the signature on a page, then save a signed copy.
class _PlacementScreen extends StatefulWidget {
  const _PlacementScreen({required this.input, required this.document, required this.signature});
  final InputFile input;
  final PdfDocument document;
  final SignatureImage signature;

  @override
  State<_PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<_PlacementScreen> {
  int _page = 0;
  double _left = 0.55, _top = 0.78, _width = 0.32;
  bool _allPages = false;
  bool _busy = false;

  PdfPage get page => widget.document.pages[_page];

  double _heightFraction() =>
      _width * page.width * widget.signature.height / widget.signature.width / page.height;

  void _clamp() {
    _width = _width.clamp(0.05, 1.0);
    final h = _heightFraction();
    if (h > 1) _width = _width / h;
    _left = _left.clamp(0.0, 1.0 - _width);
    _top = _top.clamp(0.0, 1.0 - _heightFraction());
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final o = SignatureOptions(
      png: widget.signature.png,
      pngWidth: widget.signature.width,
      pngHeight: widget.signature.height,
      pageIndex: _page,
      left: _left,
      top: _top,
      width: _width,
      allPages: _allPages,
    );
    final out = await runJob(context, (ctx) => runSignature(widget.input, o, ctx));
    if (mounted) setState(() => _busy = false);
    if (out == null || !mounted) return;
    await showResult(context, outputs: [out], tool: ToolId.signature.name);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = SatrColors.of(context);
    final count = widget.document.pages.length;
    return Scaffold(
      appBar: AppBar(title: Text(l.toolSignature)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.s),
            child: Text(l.sigPlaceHint, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              child: LayoutBuilder(builder: (context, box) {
                final aspect = page.width / page.height;
                var w = box.maxWidth, h = w / aspect;
                if (h > box.maxHeight) {
                  h = box.maxHeight;
                  w = h * aspect;
                }
                final sw = _width * w;
                final sh = _heightFraction() * h;
                return Center(
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(border: Border.all(color: c.line)),
                              child: PdfPageView(document: widget.document, pageNumber: _page + 1),
                            ),
                          ),
                          Positioned(
                            left: _left * w,
                            top: _top * h,
                            width: sw,
                            height: sh,
                            child: GestureDetector(
                              onPanUpdate: (d) => setState(() {
                                _left += d.delta.dx / w;
                                _top += d.delta.dy / h;
                                _clamp();
                              }),
                              child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: c.accent, width: 2),
                                    color: c.accent.withValues(alpha: 0.08)),
                                child: Image.memory(widget.signature.png, fit: BoxFit.fill),
                              ),
                            ),
                          ),
                          Positioned(
                            left: _left * w + sw - 16,
                            top: _top * h + sh - 16,
                            child: GestureDetector(
                              onPanUpdate: (d) => setState(() {
                                _width += d.delta.dx / w;
                                _clamp();
                              }),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle, border: Border.all(color: c.onAccent)),
                                child: Center(child: SatrIcon('zoomIn', size: 16, color: c.onAccent)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          if (count > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _page > 0 ? () => setState(() { _page--; _clamp(); }) : null,
                    icon: const SatrIcon('chevronStart'),
                    tooltip: l.viewerPrev,
                  ),
                  Expanded(
                    child: Text('${l.sigPage}: ${l.progressPage(_page + 1, count)}', textAlign: TextAlign.center),
                  ),
                  IconButton(
                    onPressed: _page < count - 1 ? () => setState(() { _page++; _clamp(); }) : null,
                    icon: const SatrIcon('chevronEnd'),
                    tooltip: l.viewerNext,
                  ),
                ],
              ),
            ),
          if (count > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.sigAllPages),
                value: _allPages,
                onChanged: (v) => setState(() => _allPages = v),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAction(label: l.sigAction, icon: 'signature', onPressed: _busy ? null : _save),
    );
  }
}
