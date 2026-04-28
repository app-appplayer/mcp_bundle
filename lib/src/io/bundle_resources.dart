/// Read/write access to the bundle's reserved sub-folders.
///
/// See `docs/bundle_resource_io.md` for the design contract.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'exceptions.dart';

/// The six reserved folder names in a bundle's `.mbd/` tree.
///
/// Each name maps 1:1 to a sub-directory under the bundle root. Consumer
/// adapters interpret the folder's contents in domain-specific ways
/// (UI rendering for `ui/`, asset resolution for `assets/`, …); the
/// folder names themselves are part of the bundle format.
class BundleFolder {
  const BundleFolder._(this.name);

  /// UI definition files (mcp_ui_dsl JSON).
  static const ui = BundleFolder._('ui');

  /// Binary or text assets (icons, splash, fonts, …).
  static const assets = BundleFolder._('assets');

  /// Skill / capability module definitions.
  static const skills = BundleFolder._('skills');

  /// Knowledge sources, retriever configs.
  static const knowledge = BundleFolder._('knowledge');

  /// Profile definitions.
  static const profiles = BundleFolder._('profiles');

  /// Philosophy / ethos definitions.
  static const philosophy = BundleFolder._('philosophy');

  /// All reserved folder names, in declaration order.
  static const values = <BundleFolder>[
    ui,
    assets,
    skills,
    knowledge,
    profiles,
    philosophy,
  ];

  /// On-disk folder name (e.g. `'ui'`).
  final String name;

  @override
  String toString() => name;
}

/// Read/write surface for one reserved folder under a bundle's `.mbd/`
/// root. All paths are forward-slash separated and resolved relative to
/// the folder root — absolute paths and `..` traversal are rejected.
class BundleResources {
  /// Bind to `<bundleRoot>/<folder.name>`.
  ///
  /// [bundleRoot] is the absolute path of the `.mbd/` directory.
  /// [folder] selects which reserved sub-tree this surface exposes.
  BundleResources({
    required String bundleRoot,
    required this.folder,
  }) : _bundleRoot = bundleRoot;

  /// Which reserved folder this surface points at.
  final BundleFolder folder;

  final String _bundleRoot;

  String get _root =>
      '$_bundleRoot${Platform.pathSeparator}${folder.name}';

  /// Read file contents as UTF-8 text.
  ///
  /// Throws [BundleResourceNotFoundException] on missing file.
  Future<String> read(String relativePath) async {
    final file = _resolve(relativePath);
    if (!await file.exists()) {
      throw BundleResourceNotFoundException(folder.name, relativePath);
    }
    return file.readAsString();
  }

  /// Read file contents as raw bytes.
  Future<Uint8List> readBytes(String relativePath) async {
    final file = _resolve(relativePath);
    if (!await file.exists()) {
      throw BundleResourceNotFoundException(folder.name, relativePath);
    }
    return file.readAsBytes();
  }

  /// Write UTF-8 text. Creates parent directories as needed.
  Future<void> write(String relativePath, String content) async {
    final file = _resolve(relativePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Write raw bytes. Creates parent directories as needed.
  Future<void> writeBytes(String relativePath, Uint8List bytes) async {
    final file = _resolve(relativePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  /// JSON-encode [value] and write as UTF-8 text. Creates parent
  /// directories as needed. [indent] controls pretty-printing — 0 emits
  /// a single line with no padding; > 0 uses that many spaces. Symmetric
  /// with [readJson] so callers stop repeating `jsonEncode` + [write].
  Future<void> writeJson(
    String relativePath,
    Object? value, {
    int indent = 2,
  }) async {
    final encoder = indent > 0
        ? JsonEncoder.withIndent(' ' * indent)
        : const JsonEncoder();
    await write(relativePath, encoder.convert(value));
  }

  /// Whether the file exists.
  Future<bool> exists(String relativePath) async {
    final file = _resolve(relativePath);
    return file.exists();
  }

  /// Delete the file. No-op when missing.
  Future<void> delete(String relativePath) async {
    final file = _resolve(relativePath);
    if (await file.exists()) await file.delete();
  }

  /// Enumerate files under this folder.
  ///
  /// [extension] filters by suffix (e.g. `.json`). Pass `null` for all
  /// files. Returns relative paths from this folder's root with
  /// forward-slash separators, sorted lexicographically. Returns an
  /// empty list when the folder does not exist.
  Future<List<String>> list({String? extension}) async {
    final dir = Directory(_root);
    if (!await dir.exists()) return const [];

    final rootAbs = dir.absolute.path;
    final out = <String>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (extension != null && !entity.path.endsWith(extension)) continue;

      var rel = entity.absolute.path.substring(rootAbs.length);
      if (rel.startsWith(Platform.pathSeparator)) {
        rel = rel.substring(Platform.pathSeparator.length);
      }
      rel = rel.replaceAll(r'\', '/');
      out.add(rel);
    }
    out.sort();
    return out;
  }

  /// Decode `relativePath` as JSON text. Convenience wrapper around
  /// [read] + `jsonDecode` so callers don't repeat the boilerplate.
  Future<dynamic> readJson(String relativePath) async {
    final raw = await read(relativePath);
    try {
      return jsonDecode(raw);
    } on FormatException catch (e) {
      throw BundleResourceParseException(
        folder.name,
        relativePath,
        'Invalid JSON: ${e.message}',
      );
    }
  }

  /// Resolve a caller-supplied relative path against the folder root,
  /// rejecting absolute paths and any segment that would escape the
  /// folder via `..`.
  File _resolve(String relativePath) {
    if (relativePath.isEmpty) {
      throw ArgumentError.value(
          relativePath, 'relativePath', 'Path must not be empty');
    }
    // Reject absolute paths (`/foo`, `C:\foo`).
    if (relativePath.startsWith('/') ||
        relativePath.startsWith(r'\') ||
        (relativePath.length > 1 && relativePath[1] == ':')) {
      throw ArgumentError.value(
          relativePath, 'relativePath', 'Absolute paths are not allowed');
    }
    // Reject `..` traversal.
    final segments = relativePath.split(RegExp(r'[/\\]'));
    for (final seg in segments) {
      if (seg == '..') {
        throw ArgumentError.value(
            relativePath, 'relativePath', 'Path traversal is not allowed');
      }
    }
    // Normalise to platform separator.
    final normalised = relativePath.replaceAll('/', Platform.pathSeparator);
    return File('$_root${Platform.pathSeparator}$normalised');
  }
}

/// Thrown when [BundleResources.read] / [readBytes] is called against a
/// file that does not exist under the bundle's reserved folder.
class BundleResourceNotFoundException extends BundleLoadException {
  BundleResourceNotFoundException(this.folder, this.relativePath)
      : super('Bundle resource not found: $folder/$relativePath');

  /// Reserved folder name (`ui`, `assets`, …).
  final String folder;

  /// Path that was looked up, relative to the folder root.
  final String relativePath;
}

/// Thrown when [BundleResources.readJson] decodes a file that is not
/// valid JSON.
class BundleResourceParseException extends BundleLoadException {
  BundleResourceParseException(this.folder, this.relativePath, String details)
      : super('Bundle resource parse failed: $folder/$relativePath — $details');

  final String folder;
  final String relativePath;
}
