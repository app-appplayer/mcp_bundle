/// Per-bundle file surface — the root of an installed bundle expressed as
/// a port rather than a filesystem path.
///
/// A bundle's reserved tree (`ui/`, `assets/`, `tools/`, …) is a set of
/// paths, not necessarily a directory. On desktop and mobile those paths
/// are files under a `.mbd/` root; on hosts with no filesystem (web) they
/// live in whatever storage the host provides. Everything that reads or
/// writes an installed bundle goes through this port so the tree's
/// location stops being a `String` the caller has to be able to resolve.
///
/// Paths are forward-slash separated and relative to the bundle root
/// (`'ui/app.json'`). Absolute paths and `..` traversal are rejected —
/// a bundle must not be able to name anything outside itself.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Read/write surface for the contents of one bundle.
///
/// Implementations must not interpret bundle semantics — this port moves
/// bytes. Manifest parsing, integrity checks and install policy stay in
/// the layers above.
abstract interface class BundleFileStore {
  /// Read `path`, or `null` when it does not exist.
  ///
  /// Absence is a return value, not an exception: callers routinely probe
  /// for optional files, and making that path throw pushes every caller
  /// into a try/catch that hides real read failures.
  Future<Uint8List?> read(String path);

  /// Whether `path` exists.
  ///
  /// Separate from [read] because probing must not cost a transfer — on a
  /// remote store reading a file to learn whether it is there would pull
  /// the whole body across the wire.
  Future<bool> exists(String path);

  /// Write `bytes` at `path`, creating intermediate structure as needed.
  Future<void> write(String path, Uint8List bytes);

  /// Delete `path`. No-op when it does not exist.
  Future<void> delete(String path);

  /// Enumerate paths under [folder] (bundle-root relative, sorted).
  ///
  /// [folder] is a sub-folder of the bundle (`'ui'`). Pass `null` for the
  /// whole bundle. Returns an empty list when the folder holds nothing —
  /// an absent folder is not an error.
  Future<List<String>> list({String? folder});
}

/// Rejects paths that are absolute or escape the bundle root, and
/// normalises separators to `/`.
///
/// Shared by implementations so the guarantee holds regardless of which
/// store a host plugs in — a store that forgot the check would let a
/// crafted bundle write outside its own tree.
String normaliseBundlePath(String path) {
  if (path.isEmpty) {
    throw ArgumentError.value(path, 'path', 'Path must not be empty');
  }
  if (path.startsWith('/') ||
      path.startsWith(r'\') ||
      (path.length > 1 && path[1] == ':')) {
    throw ArgumentError.value(path, 'path', 'Absolute paths are not allowed');
  }
  final segments = path.split(RegExp(r'[/\\]'));
  for (final seg in segments) {
    if (seg == '..') {
      throw ArgumentError.value(path, 'path', 'Path traversal is not allowed');
    }
  }
  return segments.where((s) => s.isNotEmpty && s != '.').join('/');
}

/// [BundleFileStore] over a `.mbd/` directory on the local filesystem.
///
/// This is what desktop and mobile hosts get, and it is the behaviour
/// every existing consumer already has — the port was introduced under
/// them, not instead of them.
class FileBundleFileStore implements BundleFileStore {
  /// Bind to the `.mbd/` directory at [bundleRoot].
  FileBundleFileStore(this.bundleRoot);

  /// Absolute path of the bundle's `.mbd/` directory.
  final String bundleRoot;

  @override
  Future<Uint8List?> read(String path) async {
    final file = File(_native(path));
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<bool> exists(String path) => File(_native(path)).exists();

  @override
  Future<void> write(String path, Uint8List bytes) async {
    final file = File(_native(path));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<void> delete(String path) async {
    final file = File(_native(path));
    if (await file.exists()) await file.delete();
  }

  @override
  Future<List<String>> list({String? folder}) async {
    // Walk the folder itself rather than the whole bundle and filter —
    // a bundle can carry a large `assets/` tree and listing `ui/` must
    // not pay for it.
    final sub = folder == null ? null : normaliseBundlePath(folder);
    final root = Directory(sub == null ? bundleRoot : _native(sub));
    if (!await root.exists()) return const [];

    final rootAbs = root.absolute.path;
    final out = <String>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      var rel = entity.absolute.path;
      if (!rel.startsWith(rootAbs)) continue;
      rel = rel.substring(rootAbs.length);
      if (rel.startsWith(Platform.pathSeparator)) {
        rel = rel.substring(Platform.pathSeparator.length);
      }
      rel = rel.replaceAll(r'\', '/');
      out.add(sub == null ? rel : '$sub/$rel');
    }
    out.sort();
    return out;
  }

  String _native(String path) {
    final normalised = normaliseBundlePath(path);
    return '$bundleRoot${Platform.pathSeparator}'
        '${normalised.replaceAll('/', Platform.pathSeparator)}';
  }
}

/// In-memory [BundleFileStore].
///
/// Used by tests, and by hosts that hold a bundle transiently (a fetched
/// archive expanded for a single run without being installed).
class MemoryBundleFileStore implements BundleFileStore {
  /// Start empty, or seeded from [initial] (bundle-root relative paths).
  MemoryBundleFileStore([Map<String, Uint8List>? initial]) {
    if (initial != null) {
      initial.forEach((k, v) => _files[normaliseBundlePath(k)] = v);
    }
  }

  /// Seed from UTF-8 text — the common shape in tests.
  factory MemoryBundleFileStore.ofText(Map<String, String> initial) {
    return MemoryBundleFileStore({
      for (final e in initial.entries)
        e.key: Uint8List.fromList(utf8.encode(e.value)),
    });
  }

  final _files = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String path) async =>
      _files[normaliseBundlePath(path)];

  @override
  Future<bool> exists(String path) async =>
      _files.containsKey(normaliseBundlePath(path));

  @override
  Future<void> write(String path, Uint8List bytes) async {
    _files[normaliseBundlePath(path)] = bytes;
  }

  @override
  Future<void> delete(String path) async {
    _files.remove(normaliseBundlePath(path));
  }

  @override
  Future<List<String>> list({String? folder}) async {
    // Match on the folder boundary, not a bare string prefix — otherwise
    // listing `ui` would also return `ui_legacy/…`.
    final sub = folder == null ? null : '${normaliseBundlePath(folder)}/';
    final out = _files.keys
        .where((k) => sub == null || k.startsWith(sub))
        .toList()
      ..sort();
    return out;
  }
}
