import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../components/common.dart';
import '../../components/file_pick.dart';
import '../../components/job_ui.dart';
import '../../components/l10n_ext.dart';
import '../../components/tool_scaffold.dart';
import '../../core/files/file_type.dart';
import '../../core/image/platform_decode.dart';
import '../../core/pdf/pdf_service.dart';
import '../../design/icons.dart';
import '../../design/tokens.dart';
import '../result/result_screen.dart';
import '../tools/tool_registry.dart';
import 'images_to_pdf_tool.dart';

class ImagesToPdfScreen extends PdfToolWidget {
  const ImagesToPdfScreen({super.key, super.initial});

  @override
  State<ImagesToPdfScreen> createState() => _ImagesToPdfScreenState();
}

class _ImagesToPdfScreenState extends State<ImagesToPdfScreen> {
  late final List<InputFile> _images = [...widget.initial];
  bool _busy = false;
  PageSizeOption _size = PageSizeOption.a4;
  OrientationOption _orientation = OrientationOption.auto;
  MarginOption _margin = MarginOption.small;
  FitOption _fit = FitOption.contain;

  Future<void> _add() async {
    final picked = await pickInputs(context, kind: PickKind.image, multiple: true);
    setState(() => _images.addAll(picked));
  }

  Future<void> _run() async {
    if (_images.isEmpty) return;
    setState(() => _busy = true);
    final opts = ImagesToPdfOptions(pageSize: _size, orientation: _orientation, margin: _margin, fit: _fit);
    final out = await runJob(context, (ctx) async {
      // HEIC is decoded by the platform codec (UI isolate), then the rest
      // runs in background isolates.
      final ready = <InputFile>[];
      for (final f in _images) {
        ctx.checkCancelled();
        ready.add(detectFileType(f.bytes) == DetectedType.heic
            ? InputFile(f.name, await heicToJpeg(f.bytes))
            : f);
      }
      return runImagesToPdf(ready, opts, ctx);
    });
    if (mounted) setState(() => _busy = false);
    if (out == null || !mounted) return;
    await showResult(context, outputs: [out], tool: ToolId.imagesToPdf.name);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ToolScaffold(
      tool: ToolId.imagesToPdf,
      actionLabel: l.createPdfAction,
      actionIcon: 'imagesToPdf',
      onAction: _images.isNotEmpty && !_busy ? _run : null,
      children: [
        if (_images.isEmpty)
          PickPrompt(label: l.pickImages, onTap: _add, icon: 'image')
        else ...[
          Text('${l.imagesCount(_images.length)} · ${l.imagesHint}', style: Theme.of(context).textTheme.bodySmall),
          SizedBox(
            height: 132,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              onReorderItem: (a, b) => setState(() => _images.insert(b, _images.removeAt(a))),
              itemBuilder: (context, i) => _Thumb(
                key: ObjectKey(_images[i]),
                bytes: _images[i].bytes,
                index: i + 1,
                onRemove: _busy ? null : () => setState(() => _images.removeAt(i)),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _add,
            icon: const SatrIcon('plus', size: 20),
            label: Text(l.addMore),
          ),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChoiceRow<PageSizeOption>(
                  label: l.pageSizeLabel,
                  value: _size,
                  options: {
                    PageSizeOption.a4: l.pageSizeA4,
                    PageSizeOption.letter: l.pageSizeLetter,
                    PageSizeOption.fitImage: l.pageSizeFit,
                  },
                  onChanged: (v) => setState(() => _size = v),
                ),
                if (_size != PageSizeOption.fitImage) ...[
                  const SizedBox(height: Space.l),
                  ChoiceRow<OrientationOption>(
                    label: l.orientationLabel,
                    value: _orientation,
                    options: {
                      OrientationOption.auto: l.orientationAuto,
                      OrientationOption.portrait: l.orientationPortrait,
                      OrientationOption.landscape: l.orientationLandscape,
                    },
                    onChanged: (v) => setState(() => _orientation = v),
                  ),
                ],
                const SizedBox(height: Space.l),
                ChoiceRow<MarginOption>(
                  label: l.marginsLabel,
                  value: _margin,
                  options: {
                    MarginOption.none: l.marginNone,
                    MarginOption.small: l.marginSmall,
                    MarginOption.large: l.marginLarge,
                  },
                  onChanged: (v) => setState(() => _margin = v),
                ),
                if (_size != PageSizeOption.fitImage) ...[
                  const SizedBox(height: Space.l),
                  ChoiceRow<FitOption>(
                    label: l.fitLabel,
                    value: _fit,
                    options: {FitOption.contain: l.fitContain, FitOption.cover: l.fitCover},
                    onChanged: (v) => setState(() => _fit = v),
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

class _Thumb extends StatelessWidget {
  const _Thumb({super.key, required this.bytes, required this.index, this.onRemove});
  final Uint8List bytes;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = SatrColors.of(context);
    final isHeic = detectFileType(bytes) == DetectedType.heic;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: Space.s),
      child: SizedBox(
        width: 96,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.control),
                child: Container(
                  color: c.surface,
                  child: isHeic
                      ? const Center(child: SatrIcon('image'))
                      : Image.memory(bytes, fit: BoxFit.cover, cacheWidth: 200,
                          errorBuilder: (_, _, _) => const Center(child: SatrIcon('image'))),
                ),
              ),
            ),
            PositionedDirectional(
              start: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(color: c.brand, borderRadius: BorderRadius.circular(6)),
                child: Text(formatNumber(context, index),
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(color: c.bg)),
              ),
            ),
            if (onRemove != null)
              PositionedDirectional(
                top: 0,
                end: 0,
                child: IconButton(
                  onPressed: onRemove,
                  tooltip: context.l10n.remove,
                  style: IconButton.styleFrom(backgroundColor: c.bg.withValues(alpha: 0.85)),
                  icon: const SatrIcon('close', size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
