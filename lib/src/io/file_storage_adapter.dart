/// File system storage adapter for bundle I/O.
///
/// Implements [BundleStoragePort] using dart:io File operations.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'bundle_storage_port.dart';
import 'exceptions.dart';

/// File system storage adapter implementing [BundleStoragePort].
///
/// Provides bundle storage operations on the local file system.
/// Supports both single JSON files and directory bundles (.mbd/).
class FileStorageAdapter implements BundleStoragePort {
  /// Optional base path for relative URIs.
  final String? basePath;

  /// Create a file storage adapter.
  ///
  /// If [basePath] is provided, relative URIs will be resolved against it.
  const FileStorageAdapter([this.basePath]);

  String _resolvePath(Uri uri) {
    if (uri.scheme == 'file' || uri.scheme.isEmpty) {
      final path = uri.toFilePath();
      if (basePath != null && !uri.isAbsolute) {
        return '$basePath/$path';
      }
      return path;
    }
    throw BundleLoadException('Unsupported URI scheme: ${uri.scheme}');
  }

  @override
  Future<Map<String, dynamic>> readBundle(Uri uri) async {
    final path = _resolvePath(uri);
    final file = File(path);

    if (await file.exists()) {
      return _readJsonFile(file);
    }

    // Check for directory bundle
    final dir = Directory(path);
    if (await dir.exists()) {
      final bundleFile = File('${dir.path}/manifest.json');
      if (await bundleFile.exists()) {
        return _readJsonFile(bundleFile);
      }
    }

    // Check for .mbd directory
    final mcpBundleDir = Directory('$path.mbd');
    if (await mcpBundleDir.exists()) {
      final bundleFile = File('${mcpBundleDir.path}/manifest.json');
      if (await bundleFile.exists()) {
        return _readJsonFile(bundleFile);
      }
    }

    throw BundleNotFoundException(uri);
  }

  Future<Map<String, dynamic>> _readJsonFile(File file) async {
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content);
      if (json is! Map<String, dynamic>) {
        throw BundleParseException('Bundle must be a JSON object');
      }
      return json;
    } on FormatException catch (e) {
      throw BundleParseException('Invalid JSON: ${e.message}');
    }
  }

  @override
  Future<void> writeBundle(Uri uri, Map<String, dynamic> data) async {
    final path = _resolvePath(uri);
    final file = File(path);

    try {
      await file.parent.create(recursive: true);
      final content = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(content);
    } catch (e) {
      throw BundleWriteException('Failed to write bundle: $e', uri: uri);
    }
  }

  @override
  Future<Uint8List> readAsset(Uri uri) async {
    final path = _resolvePath(uri);
    final file = File(path);

    if (!await file.exists()) {
      throw AssetNotFoundException(uri);
    }

    try {
      return await file.readAsBytes();
    } catch (e) {
      throw BundleLoadException('Failed to read asset: $e');
    }
  }

  @override
  Future<void> writeAsset(Uri uri, Uint8List data) async {
    final path = _resolvePath(uri);
    final file = File(path);

    try {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data);
    } catch (e) {
      throw BundleWriteException('Failed to write asset: $e', uri: uri);
    }
  }

  @override
  Future<bool> exists(Uri uri) async {
    final path = _resolvePath(uri);
    final file = File(path);
    if (await file.exists()) return true;

    final dir = Directory(path);
    if (await dir.exists()) return true;

    final mcpBundleDir = Directory('$path.mbd');
    return mcpBundleDir.exists();
  }

  @override
  Future<void> delete(Uri uri) async {
    final path = _resolvePath(uri);
    final file = File(path);

    try {
      if (await file.exists()) {
        await file.delete();
        return;
      }

      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        return;
      }

      final mcpBundleDir = Directory('$path.mbd');
      if (await mcpBundleDir.exists()) {
        await mcpBundleDir.delete(recursive: true);
      }
    } catch (e) {
      throw BundleWriteException('Failed to delete: $e', uri: uri);
    }
  }

  @override
  Future<List<Uri>> list(Uri directoryUri) async {
    final path = _resolvePath(directoryUri);
    final dir = Directory(path);

    if (!await dir.exists()) {
      return [];
    }

    final bundles = <Uri>[];

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        bundles.add(Uri.file(entity.path));
      } else if (entity is Directory && entity.path.endsWith('.mbd')) {
        bundles.add(Uri.file(entity.path));
      }
    }

    return bundles;
  }

  @override
  Stream<BundleChangeEvent>? watch(Uri uri) {
    final path = _resolvePath(uri);
    final dir = Directory(path);

    if (!dir.existsSync()) {
      return null;
    }

    return dir.watch(recursive: true).map((event) {
      BundleChangeType type;
      switch (event.type) {
        case FileSystemEvent.create:
          type = BundleChangeType.created;
        case FileSystemEvent.modify:
          type = BundleChangeType.modified;
        case FileSystemEvent.delete:
          type = BundleChangeType.deleted;
        default:
          type = BundleChangeType.modified;
      }

      return BundleChangeEvent(
        uri: Uri.file(event.path),
        type: type,
        timestamp: DateTime.now(),
      );
    });
  }
}
