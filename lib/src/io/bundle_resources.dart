/// Read/write access to the bundle's reserved sub-folders.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'bundle_file_store.dart';
import 'exceptions.dart';

/// The twelve reserved folder names in a bundle's `.mbd/` tree.
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

  /// Atomic subject-predicate-object fact records (typically newline-
  /// delimited or per-fact JSON files). Companion to the inline
  /// `manifest.facts[]` carry — large-volume facts live here.
  static const facts = BundleFolder._('facts');

  /// Workflow definitions — ordered step sequences. Companion to the
  /// inline `manifest.workflows[]` carry — large or generated workflow
  /// definitions live here as standalone files.
  static const workflows = BundleFolder._('workflows');

  /// Pipeline definitions — ordered stage sequences for data / build /
  /// deploy flows. Companion to the inline `manifest.pipelines[]` carry.
  static const pipelines = BundleFolder._('pipelines');

  /// Runbook definitions — ordered procedure sequences for operational
  /// tasks (incident response, recovery, routine maintenance). Companion
  /// to the inline `manifest.runbooks[]` carry.
  static const runbooks = BundleFolder._('runbooks');

  /// Tool definitions — host-callable tool entries (host builtin / MCP
  /// server / cloud endpoint / bundled JS). Companion to the inline
  /// `manifest.tools[]` carry — large schemas or bundled JS sources live
  /// here as standalone files.
  static const tools = BundleFolder._('tools');

  /// Profile definitions.
  static const profiles = BundleFolder._('profiles');

  /// Philosophy / ethos definitions.
  static const philosophy = BundleFolder._('philosophy');

  /// Agent definitions (4-axis bindings + runtime config).
  static const agents = BundleFolder._('agents');

  /// All reserved folder names, in declaration order.
  static const values = <BundleFolder>[
    ui,
    assets,
    skills,
    knowledge,
    facts,
    workflows,
    pipelines,
    runbooks,
    tools,
    profiles,
    philosophy,
    agents,
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
  /// Bind to `<bundleRoot>/<folder.name>` on the local filesystem.
  ///
  /// [bundleRoot] is the absolute path of the `.mbd/` directory.
  /// [folder] selects which reserved sub-tree this surface exposes.
  BundleResources({
    required String bundleRoot,
    required this.folder,
  }) : _store = FileBundleFileStore(bundleRoot);

  /// Bind to `<folder.name>/` inside an arbitrary [BundleFileStore].
  ///
  /// This is the form a host without a filesystem uses — the reserved
  /// folder layout is unchanged, only where its bytes live.
  BundleResources.onStore({
    required BundleFileStore store,
    required this.folder,
  }) : _store = store;

  /// Which reserved folder this surface points at.
  final BundleFolder folder;

  final BundleFileStore _store;

  /// Resolve a caller-supplied relative path to a bundle-root relative
  /// key, rejecting absolute paths and `..` traversal.
  String _key(String relativePath) =>
      '${folder.name}/${normaliseBundlePath(relativePath)}';

  /// Read file contents as UTF-8 text.
  ///
  /// Throws [BundleResourceNotFoundException] on missing file.
  Future<String> read(String relativePath) async {
    final bytes = await _store.read(_key(relativePath));
    if (bytes == null) {
      throw BundleResourceNotFoundException(folder.name, relativePath);
    }
    return utf8.decode(bytes);
  }

  /// Read file contents as raw bytes.
  Future<Uint8List> readBytes(String relativePath) async {
    final bytes = await _store.read(_key(relativePath));
    if (bytes == null) {
      throw BundleResourceNotFoundException(folder.name, relativePath);
    }
    return bytes;
  }

  /// Write UTF-8 text. Creates parent directories as needed.
  Future<void> write(String relativePath, String content) async {
    await _store.write(
      _key(relativePath),
      Uint8List.fromList(utf8.encode(content)),
    );
  }

  /// Write raw bytes. Creates parent directories as needed.
  Future<void> writeBytes(String relativePath, Uint8List bytes) async {
    await _store.write(_key(relativePath), bytes);
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
  Future<bool> exists(String relativePath) =>
      _store.exists(_key(relativePath));

  /// Delete the file. No-op when missing.
  Future<void> delete(String relativePath) =>
      _store.delete(_key(relativePath));

  /// Enumerate files under this folder.
  ///
  /// [extension] filters by suffix (e.g. `.json`). Pass `null` for all
  /// files. Returns relative paths from this folder's root with
  /// forward-slash separators, sorted lexicographically. Returns an
  /// empty list when the folder does not exist.
  Future<List<String>> list({String? extension}) async {
    final prefix = '${folder.name}/';
    final keys = await _store.list(folder: folder.name);
    final out = <String>[];
    for (final key in keys) {
      if (extension != null && !key.endsWith(extension)) continue;
      out.add(key.startsWith(prefix) ? key.substring(prefix.length) : key);
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
