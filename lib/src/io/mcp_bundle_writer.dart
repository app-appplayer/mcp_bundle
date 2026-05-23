/// Write an `McpBundle` to a fresh `.mbd/` directory tree.
///
/// Dual to [McpBundleLoader.loadDirectory]. Owns the `manifest.json`
/// write path so callers do not duplicate `jsonEncode` +
/// `File.writeAsString`, and routes every reserved-folder file write
/// through [BundleResources] so path safety, UTF-8 enforcement, and
/// parent-dir creation match the runtime read/write surface.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../models/bundle.dart';
import 'bundle_resources.dart';
import 'exceptions.dart';

/// Writer entry point for `.mbd/` directory trees.
class McpBundleWriter {
  static const String manifestEntry = 'manifest.json';

  /// Write [bundle] to a fresh `.mbd/` tree at [mbdPath].
  ///
  /// Steps:
  /// 1. Create [mbdPath] (recursive). When the directory exists and
  ///    is non-empty, throw [BundleWriteException] unless [overwrite]
  ///    is `true`, in which case existing entries are removed first.
  /// 2. Serialise [bundle] via [bundle.toJson] and write JSON to
  ///    `<mbdPath>/manifest.json` indented by [indent] spaces (default
  ///    2; pass 0 for single-line output).
  /// 3. For every entry in [reservedFiles], invoke the matching
  ///    [BundleResources] method:
  ///    - `String` → [BundleResources.write]
  ///    - `Uint8List` / `List<int>` → [BundleResources.writeBytes]
  ///    - any other [Object] → [BundleResources.writeJson] (same indent)
  ///
  /// Returns the absolute path of the written `.mbd/` directory.
  static Future<String> writeDirectory(
    McpBundle bundle,
    String mbdPath, {
    Map<BundleFolder, Map<String, Object>> reservedFiles = const {},
    int indent = 2,
    bool overwrite = false,
  }) async {
    final dir = Directory(mbdPath);
    if (await dir.exists()) {
      final existing = await dir.list().toList();
      if (existing.isNotEmpty) {
        if (!overwrite) {
          throw BundleWriteException(
            'Refusing to overwrite non-empty directory: $mbdPath '
            '(pass overwrite: true to replace contents)',
            uri: Uri.directory(dir.absolute.path),
          );
        }
        for (final entity in existing) {
          await entity.delete(recursive: true);
        }
      }
    } else {
      await dir.create(recursive: true);
    }

    final absRoot = dir.absolute.path;
    await _writeManifestFile(bundle, absRoot, indent: indent);

    for (final entry in reservedFiles.entries) {
      final resources = BundleResources(
        bundleRoot: absRoot,
        folder: entry.key,
      );
      for (final fileEntry in entry.value.entries) {
        final value = fileEntry.value;
        if (value is String) {
          await resources.write(fileEntry.key, value);
        } else if (value is Uint8List) {
          await resources.writeBytes(fileEntry.key, value);
        } else if (value is List<int>) {
          await resources.writeBytes(
            fileEntry.key,
            Uint8List.fromList(value),
          );
        } else {
          await resources.writeJson(
            fileEntry.key,
            value,
            indent: indent,
          );
        }
      }
    }

    return absRoot;
  }

  /// Write [bundle] 's `manifest.json` **only** — no reserved-folder
  /// touch. Use for authoring tools that mutate the manifest in-memory
  /// (load → `copyWith` → [writeManifest]) without rewriting the
  /// `.mbd/` directory tree. Prefer this over [writeDirectory] for
  /// partial updates: it has a fraction of the I/O cost of a full
  /// rewrite, leaves disk-only files (`knowledge/`, `agents/`, … and
  /// any author-side scratch) untouched, and races less with other
  /// readers.
  ///
  /// **Consistency contract**: [writeManifest] does NOT enforce that
  /// the manifest stays in sync with reserved-folder contents. If the
  /// caller adds (e.g.) a new `manifest.knowledge.documents[i]` entry
  /// whose `path` points into `knowledge/` without writing the file
  /// there, the bundle becomes incoherent — subsequent
  /// [McpBundleLoader.loadDirectory] will surface the missing file at
  /// load time (per loader policy). For ops that touch both sides,
  /// use [writeDirectory] with the full `reservedFiles` payload.
  ///
  /// [mbdPath] must already exist. Throws [BundleWriteException] when
  /// the directory is missing or the manifest cannot be written.
  static Future<void> writeManifest(
    McpBundle bundle,
    String mbdPath, {
    int indent = 2,
  }) async {
    final dir = Directory(mbdPath);
    if (!await dir.exists()) {
      throw BundleWriteException(
        'Bundle directory does not exist: $mbdPath',
        uri: Uri.directory(dir.absolute.path),
      );
    }
    await _writeManifestFile(bundle, dir.absolute.path, indent: indent);
  }

  /// Internal: serialise [bundle] and write `manifest.json` under
  /// [absRoot]. Shared by [writeDirectory] and [writeManifest] so the
  /// JSON-encode + flush path stays single-source.
  static Future<void> _writeManifestFile(
    McpBundle bundle,
    String absRoot, {
    required int indent,
  }) async {
    final manifestFile =
        File('$absRoot${Platform.pathSeparator}$manifestEntry');
    final encoder = indent > 0
        ? JsonEncoder.withIndent(' ' * indent)
        : const JsonEncoder();
    try {
      await manifestFile.writeAsString(
        encoder.convert(bundle.toJson()),
        flush: true,
      );
    } catch (e) {
      throw BundleWriteException(
        'Failed to write $manifestEntry: $e',
        uri: Uri.file(manifestFile.path),
      );
    }
  }
}
