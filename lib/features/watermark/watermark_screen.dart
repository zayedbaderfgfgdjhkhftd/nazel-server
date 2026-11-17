import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../components/common.dart';
import '../../components/file_pick.dart';
import '../../components/l10n_ext.dart';
import '../../components/tool_scaffold.dart';
import '../../core/files/file_type.dart';
import '../../core/image/platform_decode.dart';
import '../../core/pdf/page_ranges.dart';
import '../../design/tokens.dart';
import '../result/result_screen.dart';
import '../tools/tool_registry.dart';
import 'watermark_tool.dart';

class WatermarkScreen extends PdfToolWidget {
  const WatermarkScreen({super.key, super.initial});

  @override
  State<WatermarkScreen> createState() => _WatermarkScreenState();
}

class _WatermarkScreenState extends SinglePdfToolState<WatermarkScreen> {
  WatermarkType _type = WatermarkType.text;
  final _text = TextEditingController();
  Uint8List? _image;
  String? _imageName;
  Anchor9 _anchor = Anchor9.center;
  double _opacity = 0.3;
  double _rotation = 45;
  double _fontSize = 48;
  double _imageWidth = 0.4;
  bool _allPages = true;
  final _pages = TextEditingController();
  String? _pagesError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_text.text.isEmpty) _text.text = context.l10n.wmTextDefault;
  }

  @override
  void dispose() {
    _text.dispose();
    _pages.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await pickInputs(context, kind: PickKind.image);
    if (picked.isEmpty) return;
    var bytes = picked.first.bytes;
    if (detectFileType(bytes) == DetectedType.heic) bytes = await heicToJpeg(bytes);
    setState(() {
      _image = bytes;
      _imageName = picked.first.name;
    });
  }

  void _validatePages() {
    if (_allPages) return setState(() => _pagesError = null);
    try {
      parsePageRanges(_pages.text, pageCount);
      setState(() => _pagesError = null);
    } on RangeParseException catch (e) {
      setState(() => _pagesError = rangeErrorMessage(context, e, pageCount));
    }
  }

  Future<void> _run() async {
    final o = WatermarkOptions(
      type: _type,
      text: _text.text,
      imageBytes: _image,
      anchor: _anchor,
      opacity: _opacity,
      rotationDeg: _rotation,
      fontSizePt: _fontSize,
      imageWidthFraction: _imageWidth,
      pagesText: _allPages ? null : _pages.text,
    );
    final out = await runTool((ctx) => runWatermark(input!, o, ctx));
    if (out == null || !mounted) return;
    await showResult(context, outputs: [out], tool: ToolId.watermark.name);
  }

  String _anchorLabel(Anchor9 a) {
    final l = context.l10n;
    return switch (a) {
      Anchor9.topLeft => l.posTopLeft,
      Anchor9.topCenter => l.posTopCenter,
      Anchor9.topRight => l.posTopRight,
      Anchor9.centerLeft => l.posCenterLeft,
      Anchor9.center => l.posCenter,
      Anchor9.centerRight => l.posCenterRight,
      Anchor9.bottomLeft => l.posBottomLeft,
      Anchor9.bottomCenter => l.posBottomCenter,
      Anchor9.bottomRight => l.posBottomRight,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = SatrColors.of(context);
    final ready = input != null &&
        !busy &&
        (_type == WatermarkType.text ? _text.text.trim().isNotEmpty : _image != null) &&
        _pagesError == null;
    return ToolScaffold(
      tool: ToolId.watermark,
      actionLabel: l.wmAction,
      actionIcon: 'watermark',
      onAction: ready ? _run : null,
      children: [
        inputSection(),
        if (input != null) ...[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChoiceRow<WatermarkType>(
                  label: l.toolWatermark,
                  value: _type,
                  options: {WatermarkType.text: l.wmTypeText, WatermarkType.image: l.wmTypeImage},
                  onChanged: (v) => setState(() {
                    _type = v;
                    if (v == WatermarkType.image && _rotation == 45) _rotation = 0;
                  }),
                ),
                const SizedBox(height: Space.l),
                if (_type == WatermarkType.text) ...[
                  TextField(
                    controller: _text,
                    decoration: InputDecoration(labelText: l.wmTextLabel),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: Space.s),
                  Text(l.wmTextAsImageNote, style: Theme.of(context).textTheme.bodySmall),
                ] else
                  OutlinedButton(
                    onPressed: _pickImage,
                    child: Text(_imageName ?? l.wmChooseImage, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          SectionCard(
            title: l.positionLabel,
            child: Center(
              child: SizedBox(
                width: 3 * 56 + 2 * Space.s,
                child: Wrap(
                  spacing: Space.s,
                  runSpacing: Space.s,
                  textDirection: TextDirection.ltr, // the grid maps to the page as seen
                  children: [
                    for (final a in Anchor9.values)
                      Tooltip(
                        message: _anchorLabel(a),
                        child: Semantics(
                          selected: _anchor == a,
                          button: true,
                          label: _anchorLabel(a),
                          child: InkWell(
                            onTap: () => setState(() => _anchor = a),
                            borderRadius: BorderRadius.circular(Radii.control),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _anchor == a ? c.accent : c.bg,
                                borderRadius: BorderRadius.circular(Radii.control),
                                border: Border.all(color: _anchor == a ? c.text : c.line),
                              ),
                              child: Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      color: _anchor == a ? c.onAccent : c.line, shape: BoxShape.circle),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _slider(l.opacityLabel, '${(_opacity * 100).round()}%', _opacity, 0.05, 1,
                    (v) => setState(() => _opacity = v)),
                _slider(l.rotationLabel, '${_rotation.round()}°', _rotation, -90, 90,
                    (v) => setState(() => _rotation = v.roundToDouble()), divisions: 36),
                if (_type == WatermarkType.text)
                  _slider(l.fontSizeLabel, '${_fontSize.round()}', _fontSize, 12, 120,
                      (v) => setState(() => _fontSize = v.roundToDouble()))
                else
                  _slider(l.imageSizeLabel, '${(_imageWidth * 100).round()}%', _imageWidth, 0.1, 1,
                      (v) => setState(() => _imageWidth = v)),
              ],
            ),
          ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChoiceRow<bool>(
                  label: l.applyToLabel,
                  value: _allPages,
                  options: {true: l.allPages, false: l.selectedPages},
                  onChanged: (v) {
                    setState(() => _allPages = v);
                    _validatePages();
                  },
                ),
                if (!_allPages) ...[
                  const SizedBox(height: Space.m),
                  TextField(
                    controller: _pages,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(hintText: l.splitRangesHint, errorText: _pagesError),
                    onChanged: (_) => _validatePages(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _slider(String label, String value, double v, double min, double max, ValueChanged<double> onChanged,
          {int? divisions}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
              Text(value, textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          Slider(value: v.clamp(min, max), min: min, max: max, divisions: divisions, label: value, onChanged: onChanged),
        ],
      );
}
