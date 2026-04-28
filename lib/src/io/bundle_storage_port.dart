/// Storage abstraction for bundle I/O operations.
///
/// This interface defines the contract for bundle storage operations.
/// Implementations can provide file system, HTTP, or in-memory storage.
library;

import 'dart:typed_data';

/// Bundle change event types.
enum BundleChangeType {
  /// Bundle was created.
  created,

  /// Bundle was modified.
  modified,

  /// Bundle was deleted.
  deleted,
}

/// Event emitted when a bundle changes.
class BundleChangeEvent {
  /// URI of the changed bundle.
  final Uri uri;

  /// Type of change.
  final BundleChangeType type;

  /// Timestamp of the change.
  final DateTime timestamp;

  const BundleChangeEvent({
    required this.uri,
    required this.type,
    required this.timestamp,
  });

  @override
  String toString() => 'BundleChangeEvent($type, $uri, $timestamp)';
}

/// Abstract interface for bundle storage operations.
///
/// This port defines the contract for:
/// - Reading and writing bundle JSON data
/// - Reading and writing binary assets
/// - Checking existence and listing bundles
/// - Watching for changes (optional)
abstract interface class BundleStoragePort {
  /// Read bundle JSON from URI.
  ///
  /// Returns the parsed JSON as a map.
  /// Throws [BundleNotFoundException] if bundle doesn't exist.
  Future<Map<String, dynamic>> readBundle(Uri uri);

  /// Write bundle JSON to URI.
  ///
  /// Creates parent directories if they don't exist.
  /// Throws [BundleWriteException] on write failure.
  Future<void> writeBundle(Uri uri, Map<String, dynamic> data);

  /// Read asset binary data.
  ///
  /// Returns the raw bytes of the asset.
  /// Throws [AssetNotFoundException] if asset doesn't exist.
  Future<Uint8List> readAsset(Uri uri);

  /// Write asset binary data.
  ///
  /// Creates parent directories if they don't exist.
  /// Throws [BundleWriteException] on write failure.
  Future<void> writeAsset(Uri uri, Uint8List data);

  /// Check if bundle or asset exists.
  Future<bool> exists(Uri uri);

  /// Delete bundle or asset.
  ///
  /// Returns silently if the URI doesn't exist.
  /// Throws [BundleWriteException] on deletion failure.
  Future<void> delete(Uri uri);

  /// List bundles in directory.
  ///
  /// Returns URIs of all bundles found in the directory.
  /// For file storage, this looks for .json files and .mbd directories.
  Future<List<Uri>> list(Uri directoryUri);

  /// Watch for changes (optional).
  ///
  /// Returns a stream of change events, or null if watching is not supported.
  Stream<BundleChangeEvent>? watch(Uri uri);
}
