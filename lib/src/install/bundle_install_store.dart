/// Where installed bundles live — the install root expressed as a port.
///
/// [McpBundleInstaller] owns verification, limits and policy; it does not
/// own the question of *where the bytes land*. That question has more
/// than one answer (a directory on disk, an account's cloud storage),
/// and answering it with a `String` path silently restricts the
/// installer to hosts that can resolve one.
///
/// The port is deliberately shaped around what installing actually needs
/// and nothing else: enumerate, open, stage, promote, remove, serialise.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../io/bundle_file_store.dart';
import '../io/exceptions.dart';

/// A collection of installed bundles.
abstract interface class BundleInstallStore {
  /// Ids of bundles that are fully installed.
  ///
  /// A bundle mid-install must not appear here. Callers treat this as the
  /// registry — an id that shows up is expected to be openable.
  Future<List<String>> listInstalled();

  /// File surface of installed bundle [id], or `null` when not installed.
  Future<BundleFileStore?> openInstalled(String id);

  /// Open a staging area to write a new copy of [id] into.
  ///
  /// Staged content is invisible to [listInstalled] until it is promoted.
  Future<BundleStagingArea> beginInstall(String id);

  /// Remove installed bundle [id]. No-op when it is not installed.
  Future<void> remove(String id);

  /// Locator for [id] in this store's own terms — an absolute path for
  /// a filesystem store, a storage key for a remote one.
  ///
  /// Reported back to callers as `InstalledBundle.installPath`. It names
  /// a location; it does not promise that location is openable with
  /// `dart:io`.
  String locatorOf(String id);

  /// Run [body] with this store held exclusively.
  ///
  /// Installs mutate a shared registry, so two of them running at once
  /// can interleave into a state neither asked for. Implementations that
  /// cannot offer real exclusion must say so rather than pretend.
  Future<T> withLock<T>(Future<T> Function() body);
}

/// A staged, not-yet-installed copy of one bundle.
abstract interface class BundleStagingArea {
  /// Write the bundle's files here.
  BundleFileStore get files;

  /// Make the staged content the installed bundle, replacing any
  /// previous copy.
  ///
  /// Where the underlying storage supports an atomic swap this must use
  /// it. Where it does not, a failed promote must still never leave a
  /// **partially replaced** bundle visible to
  /// [BundleInstallStore.listInstalled] — better that the id disappears
  /// than that it appears installed while half of it is the old copy.
  ///
  /// Returns the locator the store uses for the promoted bundle.
  Future<String> promote();

  /// Discard the staged content. No-op once promoted.
  Future<void> abandon();
}

/// [BundleInstallStore] over a directory on the local filesystem.
///
/// This is the behaviour that shipped before the port existed: staging
/// directory, `rename` as the commit, an exclusive lock file at the
/// root. Desktop and mobile hosts keep exactly what they had.
class FileBundleInstallStore implements BundleInstallStore {
  /// Install into [installRoot], creating it on first use.
  FileBundleInstallStore(this.installRoot);

  /// Directory that holds one sub-directory per installed bundle.
  final String installRoot;

  /// Name of the sub-directory staged installs are built in.
  static const stagingDir = '.staging';

  static const _lockFile = '.lock';
  static const _manifestEntry = 'manifest.json';

  @override
  Future<List<String>> listInstalled() async {
    final root = Directory(installRoot);
    if (!await root.exists()) return const [];
    final out = <String>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = _basename(entity.path);
      if (name == stagingDir || name.startsWith('.')) continue;
      // A directory with no manifest is not a bundle — half-deleted
      // leftovers must not be reported as installed.
      if (!await File(_join(entity.path, _manifestEntry)).exists()) continue;
      out.add(name);
    }
    out.sort();
    return out;
  }

  @override
  Future<BundleFileStore?> openInstalled(String id) async {
    final dir = Directory(_join(installRoot, id));
    if (!await dir.exists()) return null;
    if (!await File(_join(dir.path, _manifestEntry)).exists()) return null;
    return FileBundleFileStore(dir.absolute.path);
  }

  @override
  Future<BundleStagingArea> beginInstall(String id) async {
    final root = await _ensureRoot();
    final stagingRoot = Directory(_join(root.path, stagingDir));
    await stagingRoot.create(recursive: true);
    final staging = Directory(_join(stagingRoot.path, _uuid()));
    await staging.create();
    return _FileStagingArea(
      root: root,
      stagingRoot: stagingRoot,
      staging: staging,
      id: id,
    );
  }

  @override
  Future<void> remove(String id) async {
    final root = await _ensureRoot();
    final target = Directory(_join(root.path, id));
    if (!await target.exists()) return;
    // Move out of the way first, then delete: a partially deleted tree
    // still under its own id would keep answering `openInstalled`.
    final staging = Directory(_join(root.path, stagingDir, '${_uuid()}-deleted'));
    await Directory(_join(root.path, stagingDir)).create(recursive: true);
    await target.rename(staging.path);
    await staging.delete(recursive: true);
  }

  @override
  String locatorOf(String id) =>
      Directory(_join(installRoot, id)).absolute.path;

  @override
  Future<T> withLock<T>(Future<T> Function() body) async {
    final root = await _ensureRoot();
    final lockFile = File(_join(root.path, _lockFile));
    await lockFile.create(recursive: true);
    final handle = await lockFile.open(mode: FileMode.write);
    try {
      await handle.lock(FileLock.exclusive);
    } catch (_) {
      await handle.close();
      throw BundleBusyException(root.path);
    }
    try {
      return await body();
    } finally {
      try {
        await handle.unlock();
      } catch (_) {/* swallow — the close below releases it anyway */}
      await handle.close();
    }
  }

  Future<Directory> _ensureRoot() async {
    final dir = Directory(installRoot);
    await dir.create(recursive: true);
    return dir;
  }
}

class _FileStagingArea implements BundleStagingArea {
  _FileStagingArea({
    required this.root,
    required this.stagingRoot,
    required this.staging,
    required this.id,
  });

  final Directory root;
  final Directory stagingRoot;
  final Directory staging;
  final String id;

  @override
  BundleFileStore get files => FileBundleFileStore(staging.absolute.path);

  @override
  Future<String> promote() async {
    final targetPath = _join(root.path, id);
    final target = Directory(targetPath);
    Directory? displaced;
    if (await target.exists()) {
      displaced = Directory(_join(stagingRoot.path, '${_uuid()}-previous'));
      await target.rename(displaced.path);
    }
    try {
      await staging.rename(targetPath);
    } catch (e) {
      // Put the previous copy back — a failed replace must not also
      // uninstall what was already working.
      if (displaced != null) {
        await displaced.rename(targetPath);
      }
      rethrow;
    }
    if (displaced != null && await displaced.exists()) {
      await displaced.delete(recursive: true);
    }
    return target.absolute.path;
  }

  @override
  Future<void> abandon() async {
    if (await staging.exists()) {
      await staging.delete(recursive: true);
    }
  }
}

/// [BundleInstallStore] holding everything in memory.
///
/// The reference implementation for stores with no rename and no file
/// lock — which is every remote store. Promotion is marker-based: the
/// installed copy is dropped, the staged files are moved in, and the id
/// only becomes visible again once the move finished.
class MemoryBundleInstallStore implements BundleInstallStore {
  final _installed = <String, MemoryBundleFileStore>{};
  Future<void> _lock = Future.value();

  @override
  Future<List<String>> listInstalled() async {
    final out = _installed.keys.toList()..sort();
    return out;
  }

  @override
  Future<BundleFileStore?> openInstalled(String id) async => _installed[id];

  @override
  Future<BundleStagingArea> beginInstall(String id) async =>
      _MemoryStagingArea(this, id);

  @override
  Future<void> remove(String id) async {
    _installed.remove(id);
  }

  @override
  String locatorOf(String id) => 'memory:$id';

  @override
  Future<T> withLock<T>(Future<T> Function() body) async {
    final mine = Completer<void>();
    final prev = _lock;
    _lock = mine.future;
    await prev;
    try {
      return await body();
    } finally {
      mine.complete();
    }
  }
}

class _MemoryStagingArea implements BundleStagingArea {
  _MemoryStagingArea(this._store, this._id);

  final MemoryBundleInstallStore _store;
  final String _id;
  final MemoryBundleFileStore _files = MemoryBundleFileStore();
  var _promoted = false;

  @override
  BundleFileStore get files => _files;

  @override
  Future<String> promote() async {
    // Drop the old copy before writing the new one: for the duration the
    // id reads as *not installed*, which a caller can act on, rather
    // than as installed-but-half-replaced, which it cannot.
    _store._installed.remove(_id);
    final promoted = MemoryBundleFileStore();
    for (final path in await _files.list()) {
      final bytes = await _files.read(path);
      if (bytes != null) await promoted.write(path, bytes);
    }
    _store._installed[_id] = promoted;
    _promoted = true;
    return 'memory:$_id';
  }

  @override
  Future<void> abandon() async {
    if (_promoted) return;
    for (final path in await _files.list()) {
      await _files.delete(path);
    }
  }
}

String _join(String a, [String? b, String? c]) {
  final parts = <String>[a, if (b != null) b, if (c != null) c];
  return parts.join(Platform.pathSeparator);
}

String _basename(String path) {
  final i = path.lastIndexOf(Platform.pathSeparator);
  return i < 0 ? path : path.substring(i + 1);
}

String _uuid() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final rand = (now * 2654435761) & 0xFFFFFFFF;
  return '${now.toRadixString(16)}-${rand.toRadixString(16).padLeft(8, '0')}';
}

/// UTF-8 JSON encode helper shared by installer sidecar writing.
Uint8List encodeJsonBytes(Object? value, {int indent = 2}) {
  final encoder =
      indent > 0 ? JsonEncoder.withIndent(' ' * indent) : const JsonEncoder();
  return Uint8List.fromList(utf8.encode(encoder.convert(value)));
}
