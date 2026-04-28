/// High-level repository for bundle operations.
///
/// Combines [BundleStoragePort] with [McpBundleLoader] for
/// complete load/save functionality.
library;

import 'dart:typed_data';

import 'bundle_storage_port.dart';
import 'file_storage_adapter.dart';
import 'mcp_bundle_loader.dart';
import 'memory_storage_adapter.dart';
import '../models/bundle.dart';

/// High-level API for bundle operations.
///
/// Provides a unified interface for loading, saving, and managing bundles.
/// Combines storage abstraction with parsing/serialization logic.
class BundleRepository {
  /// The storage backend.
  final BundleStoragePort storage;

  /// Create a repository with the given storage backend.
  BundleRepository(this.storage);

  /// Create a repository backed by the file system.
  ///
  /// If [basePath] is provided, relative URIs will be resolved against it.
  factory BundleRepository.file([String? basePath]) {
    return BundleRepository(FileStorageAdapter(basePath));
  }

  /// Create a repository backed by in-memory storage.
  ///
  /// Useful for testing scenarios.
  factory BundleRepository.memory() {
    return BundleRepository(MemoryStorageAdapter());
  }

  /// Load a bundle from URI.
  ///
  /// Reads the bundle JSON from storage and parses it using [McpBundleLoader].
  Future<McpBundle> load(Uri uri, {McpLoaderOptions? options}) async {
    final json = await storage.readBundle(uri);
    return McpBundleLoader.fromJson(json, options: options);
  }

  /// Save a bundle to URI.
  ///
  /// Serializes the bundle to JSON and writes to storage.
  Future<void> save(McpBundle bundle, Uri uri) async {
    final json = bundle.toJson();
    await storage.writeBundle(uri, json);
  }

  /// Check if a bundle exists at URI.
  Future<bool> exists(Uri uri) {
    return storage.exists(uri);
  }

  /// Delete a bundle at URI.
  Future<void> delete(Uri uri) {
    return storage.delete(uri);
  }

  /// List all bundles in a directory.
  Future<List<Uri>> list(Uri directoryUri) {
    return storage.list(directoryUri);
  }

  /// Load all bundles in a directory.
  ///
  /// Returns a map of URI to loaded bundle.
  /// Bundles that fail to load are skipped (errors are ignored).
  Future<Map<Uri, McpBundle>> loadAll(
    Uri directoryUri, {
    McpLoaderOptions? options,
  }) async {
    final uris = await storage.list(directoryUri);
    final results = <Uri, McpBundle>{};

    for (final uri in uris) {
      try {
        final bundle = await load(uri, options: options);
        results[uri] = bundle;
      } catch (_) {
        // Skip bundles that fail to load
      }
    }

    return results;
  }

  /// Watch for bundle changes.
  ///
  /// Returns a stream of change events, or null if watching is not supported.
  Stream<BundleChangeEvent>? watch(Uri uri) {
    return storage.watch(uri);
  }

  /// Read an asset from URI.
  Future<Uint8List> readAsset(Uri uri) {
    return storage.readAsset(uri);
  }

  /// Write an asset to URI.
  Future<void> writeAsset(Uri uri, Uint8List data) {
    return storage.writeAsset(uri, data);
  }
}
