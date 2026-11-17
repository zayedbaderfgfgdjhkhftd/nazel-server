import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../app/services.dart';
import '../core/files/file_type.dart';
import '../core/files/output_file.dart';
import '../core/pdf/pdf_service.dart';
import '../core/storage/file_store.dart';
import '../design/icons.dart';
import '../design/tokens.dart';
import 'common.dart';
import 'l10n_ext.dart';

enum PickKind { pdf, image, pdfOrImage }

bool acceptsType(PickKind kind, DetectedType t) => switch (kind) {
      PickKind.pdf => t == DetectedType.pdf,
      PickKind.image => t.isImage,
      PickKind.pdfOrImage => t == DetectedType.pdf || t.isImage,
    };

const _pdfExt = ['pdf'];
const _imageExt = ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'];

/// Asks "From device / From My files", then returns validated inputs
/// (checked by magic bytes, never by extension). Shows translated errors.
Future<List<InputFile>> pickInputs(
  BuildContext context, {
  required PickKind kind,
  bool multiple = false,
}) async {
  final l = context.l10n;
  final source = await showModalBottomSheet<String>(
    context: context,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const SatrIcon('phone'),
              title: Text(l.fromDevice),
              onTap: () => Navigator.of(c).pop('device'),
            ),
            ListTile(
              leading: const SatrIcon('folder'),
              title: Text(l.fromMyFiles),
              onTap: () => Navigator.of(c).pop('library'),
            ),
          ],
        ),
      ),
    ),
  );
  if (source == null || !context.mounted) return const [];
  if (source == 'library') return _pickFromLibrary(context, kind: kind, multiple: multiple);
  return pickFromDevice(context, kind: kind, multiple: multiple);
}

Future<List<InputFile>> pickFromDevice(
  BuildContext context, {
  required PickKind kind,
  bool multiple = false,
}) async {
  final ext = switch (kind) {
    PickKind.pdf => _pdfExt,
    PickKind.image => _imageExt,
    PickKind.pdfOrImage => [..._pdfExt, ..._imageExt],
  };
  List<PlatformFile> picked;
  try {
    if (multiple) {
      picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ext);
    } else {
      final one = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ext);
      picked = one == null ? const [] : [one];
    }
  } catch (_) {
    // Some platforms reject extension filters; fall back to any file.
    picked = multiple
        ? await FilePicker.pickFiles()
        : [?await FilePicker.pickFile()];
  }
  if (picked.isEmpty || !context.mounted) return const [];
  final inputs = <InputFile>[];
  for (final f in picked) {
    inputs.add(InputFile(f.name, await f.readAsBytes()));
  }
  if (!context.mounted) return const [];
  return validateInputs(context, inputs, kind);
}

/// Checks magic bytes, emptiness and the soft size limit.
Future<List<InputFile>> validateInputs(BuildContext context, List<InputFile> inputs, PickKind kind) async {
  final l = context.l10n;
  final ok = <InputFile>[];
  for (final f in inputs) {
    if (f.bytes.isEmpty) {
      showMessage(context, l.errEmptyFile);
      continue;
    }
    final t = detectFileType(f.bytes.length > 1024 ? Uint8List.sublistView(f.bytes, 0, 1024) : f.bytes);
    if (!acceptsType(kind, t)) {
      showMessage(context, kind == PickKind.pdf ? l.errNotPdf : (kind == PickKind.image ? l.errNotImage : l.errUnsupportedType));
      continue;
    }
    ok.add(f);
  }
  if (ok.isEmpty || !context.mounted) return ok;
  final limit = await AppScope.of(context).softSizeLimit();
  final biggest = ok.map((f) => f.bytes.length).reduce((a, b) => a > b ? a : b);
  if (biggest > limit && context.mounted) {
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.largeFileTitle),
        content: Text(l.largeFileBody(formatBytes(context, biggest))),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.of(c).pop(true), child: Text(l.continueAnyway)),
        ],
      ),
    );
    if (go != true) return const [];
  }
  return ok;
}

Future<List<InputFile>> _pickFromLibrary(BuildContext context, {required PickKind kind, required bool multiple}) async {
  final store = AppScope.of(context).files;
  final candidates = store.query().where((f) {
    final k = f.kind;
    return switch (kind) {
      PickKind.pdf => k == FileKind.pdf,
      PickKind.image => k == FileKind.image,
      PickKind.pdfOrImage => k == FileKind.pdf || k == FileKind.image,
    };
  }).toList();
  final chosen = await showModalBottomSheet<List<StoredFile>>(
    context: context,
    isScrollControlled: true,
    builder: (c) => _LibraryPicker(files: candidates, multiple: multiple),
  );
  if (chosen == null || chosen.isEmpty || !context.mounted) return const [];
  final inputs = [for (final f in chosen) InputFile(f.name, await store.readBytes(f))];
  if (!context.mounted) return const [];
  return validateInputs(context, inputs, kind);
}

class _LibraryPicker extends StatefulWidget {
  const _LibraryPicker({required this.files, required this.multiple});
  final List<StoredFile> files;
  final bool multiple;

  @override
  State<_LibraryPicker> createState() => _LibraryPickerState();
}

class _LibraryPickerState extends State<_LibraryPicker> {
  final _selected = <StoredFile>[];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = SatrColors.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              child: Row(
                children: [
                  Expanded(child: Text(l.fromMyFiles, style: Theme.of(context).textTheme.titleLarge)),
                  if (widget.multiple)
                    FilledButton(
                      onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected),
                      child: Text(l.done),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Space.s),
            Expanded(
              child: widget.files.isEmpty
                  ? EmptyState(icon: 'inbox', message: l.filesEmpty)
                  : ListView.builder(
                      itemCount: widget.files.length,
                      itemBuilder: (context, i) {
                        final f = widget.files[i];
                        final sel = _selected.contains(f);
                        return ListTile(
                          leading: SatrIcon(f.kind == FileKind.pdf ? 'fileText' : 'image'),
                          title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${formatBytes(context, f.size)} · ${formatDate(context, f.createdAt)}'),
                          trailing: widget.multiple
                              ? Checkbox(value: sel, onChanged: (_) => _toggle(f))
                              : null,
                          tileColor: sel ? c.accent.withValues(alpha: 0.25) : null,
                          onTap: () => widget.multiple ? _toggle(f) : Navigator.of(context).pop([f]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(StoredFile f) => setState(() => _selected.contains(f) ? _selected.remove(f) : _selected.add(f));
}

/// Reads a shared-in file from disk as an input.
Future<InputFile> inputFromPath(String path, String name) async =>
    InputFile(name, await File(path).readAsBytes());
