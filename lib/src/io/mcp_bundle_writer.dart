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
    final manifestFile = File('$absRoot${Platform.pathSeparator}$manifestEntry');
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
}
