import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../config/app_config.dart';
import '../arabic/normalize.dart';
import '../files/naming.dart';
import '../files/output_file.dart';

/// A file kept in the app's private storage ("My files").
class StoredFile {
  StoredFile({
    required this.id,
    required this.name,
    required this.size,
    required this.createdAt,
    required this.tool,
    required this.relPath,
    this.favorite = false,
    this.deletedAt,
  });

  final String id;
  String name;
  final int size;
  final DateTime createdAt;

  /// Tool id that produced the file ('import', 'shared', 'merge', ...).
  final String tool;
  final String relPath;
  bool favorite;
  DateTime? deletedAt;

  FileKind get kind => kindFromName(name);
  String get mime => mimeFromName(name);
  bool get isDeleted => deletedAt != null;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'size': size,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'tool': tool,
        'relPath': relPath,
        'favorite': favorite,
        'deletedAt': deletedAt?.millisecondsSinceEpoch,
      };

  static StoredFile fromJson(Map<String, Object?> j) => StoredFile(
        id: j['id']! as String,
        name: j['name']! as String,
        size: j['size']! as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt']! as int),
        tool: j['tool']! as String,
        relPath: j['relPath']! as String,
        favorite: (j['favorite'] as bool?) ?? false,
        deletedAt: j['deletedAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(j['deletedAt']! as int),
      );
}

enum FileSort { date, name, size }

/// Local file library: blobs on disk + a small JSON index.
///
/// Everything lives in the app's private directory; nothing leaves the device.
class FileStore extends ChangeNotifier {
  FileStore._(this.root);

  final Directory root;
  final List<StoredFile> _files = [];
  final _rand = Random();

  File get _indexFile => File(p.join(root.path, 'index.json'));
  Directory get _blobDir => Directory(p.join(root.path, 'blobs'));

  static Future<FileStore> open(Directory root) async {
    final store = FileStore._(root);
    await store._load();
    return store;
  }

  Future<void> _load() async {
    await _blobDir.create(recursive: true);
    _files.clear();
    if (await _indexFile.exists()) {
      try {
        final raw = jsonDecode(await _indexFile.readAsString()) as List;
        for (final e in raw) {
          final f = StoredFile.fromJson((e as Map).cast<String, Object?>());
          if (await File(p.join(root.path, f.relPath)).exists()) _files.add(f);
        }
      } catch (_) {
        // Corrupt index: keep going with an empty list rather than crash.
      }
    }
  }

  Future<void> _save() async {
    final tmp = File('${_indexFile.path}.tmp');
    await tmp.writeAsString(jsonEncode([for (final f in _files) f.toJson()]), flush: true);
    await tmp.rename(_indexFile.path);
    notifyListeners();
  }

  String _newId() {
    final t = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final r = _rand.nextInt(1 << 32).toRadixString(36);
    return '$t$r';
  }

  /// Files not in the trash.
  List<StoredFile> get active => _files.where((f) => !f.isDeleted).toList();

  /// Files in the trash, newest deletion first.
  List<StoredFile> get trash => _files.where((f) => f.isDeleted).toList()
    ..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));

  StoredFile? byId(String id) {
    for (final f in _files) {
      if (f.id == id) return f;
    }
    return null;
  }

  File fileOf(StoredFile f) => File(p.join(root.path, f.relPath));

  Future<Uint8List> readBytes(StoredFile f) => fileOf(f).readAsBytes();

  /// Total bytes used by stored files (including trash).
  int get usedBytes => _files.fold(0, (s, f) => s + f.size);

  Future<StoredFile> addBytes(String name, Uint8List bytes, {required String tool}) async {
    final id = _newId();
    final ext = extensionOf(name);
    final rel = p.join('blobs', ext.isEmpty ? id : '$id.$ext');
    final file = File(p.join(root.path, rel));
    await file.writeAsBytes(bytes, flush: true);
    final stored = StoredFile(
      id: id,
      name: _uniqueName(name),
      size: bytes.length,
      createdAt: DateTime.now(),
      tool: tool,
      relPath: rel,
    );
    _files.add(stored);
    await _save();
    return stored;
  }

  Future<StoredFile> addOutput(OutputFile out, {required String tool}) =>
      addBytes(out.name, out.bytes, tool: tool);

  /// Copies a file from disk into the store (the original is never modified).
  Future<StoredFile> importFile(File source, {String? name, required String tool}) async {
    final bytes = await source.readAsBytes();
    return addBytes(name ?? p.basename(source.path), bytes, tool: tool);
  }

  String _uniqueName(String name) {
    final names = {for (final f in active) f.name};
    if (!names.contains(name)) return name;
    final base = baseName(name);
    final ext = extensionOf(name);
    for (var i = 2; i < 10000; i++) {
      final candidate = ext.isEmpty ? '$base ($i)' : '$base ($i).$ext';
      if (!names.contains(candidate)) return candidate;
    }
    return name;
  }

  Future<void> rename(String id, String newBase) async {
    final f = byId(id);
    if (f == null) return;
    final newName = renamedFileName(f.name, newBase);
    if (newName == f.name) return;
    f.name = _uniqueName(newName);
    await _save();
  }

  Future<void> setFavorite(String id, bool value) async {
    final f = byId(id);
    if (f == null) return;
    f.favorite = value;
    await _save();
  }

  Future<void> moveToTrash(Iterable<String> ids, {DateTime? now}) async {
    final t = now ?? DateTime.now();
    for (final id in ids) {
      byId(id)?.deletedAt = t;
    }
    await _save();
  }

  Future<void> restore(Iterable<String> ids) async {
    for (final id in ids) {
      byId(id)?.deletedAt = null;
    }
    await _save();
  }

  Future<void> deleteForever(Iterable<String> ids) async {
    final set = ids.toSet();
    for (final f in _files.where((f) => set.contains(f.id)).toList()) {
      try {
        await fileOf(f).delete();
      } catch (_) {}
      _files.remove(f);
    }
    await _save();
  }

  Future<void> emptyTrash() => deleteForever(trash.map((f) => f.id));

  /// Deletes trash items older than the retention period. Returns the count.
  Future<int> purgeExpired({DateTime? now}) async {
    final limit = (now ?? DateTime.now())
        .subtract(const Duration(days: AppConfig.trashRetentionDays));
    final expired = trash.where((f) => f.deletedAt!.isBefore(limit)).map((f) => f.id).toList();
    if (expired.isNotEmpty) await deleteForever(expired);
    return expired.length;
  }

  /// Deletes every stored file and the index.
  Future<void> clearAll() async {
    _files.clear();
    if (await _blobDir.exists()) await _blobDir.delete(recursive: true);
    await _blobDir.create(recursive: true);
    await _save();
  }

  /// Search + filter + sort for the "My files" screen.
  List<StoredFile> query({
    String search = '',
    FileKind? kind,
    bool favoritesOnly = false,
    FileSort sort = FileSort.date,
    bool descending = true,
  }) {
    var list = active.where((f) {
      if (favoritesOnly && !f.favorite) return false;
      if (kind != null) {
        // DOCX files are listed under "text".
        final k = f.kind == FileKind.docx ? FileKind.text : f.kind;
        if (k != kind) return false;
      }
      return searchMatches(f.name, search);
    }).toList();
    int cmp(StoredFile a, StoredFile b) => switch (sort) {
          FileSort.date => a.createdAt.compareTo(b.createdAt),
          FileSort.name =>
            normalizeForSearch(a.name).compareTo(normalizeForSearch(b.name)),
          FileSort.size => a.size.compareTo(b.size),
        };
    list.sort((a, b) => descending ? cmp(b, a) : cmp(a, b));
    return list;
  }
}
