/// In-memory storage adapter for bundle I/O.
///
/// Implements [BundleStoragePort] using in-memory maps.
/// Useful for testing and caching scenarios.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'bundle_storage_port.dart';
import 'exceptions.dart';

/// In-memory storage adapter implementing [BundleStoragePort].
///
/// Stores bundles and assets in memory maps.
/// Supports change notifications via stream.
class MemoryStorageAdapter implements BundleStoragePort {
  final Map<String, Map<String, dynamic>> _bundles = {};
  final Map<String, Uint8List> _assets = {};
  final StreamController<BundleChangeEvent> _changes =
      StreamController.broadcast();

  /// Create a memory storage adapter.
  MemoryStorageAdapter();

  /// Seed with bundle data for testing.
  void seed(String uriString, Map<String, dynamic> bundle) {
    _bundles[uriString] = _deepCopy(bundle);
    _emitChange(Uri.parse(uriString), BundleChangeType.created);
  }

  /// Seed with asset data for testing.
  void seedAsset(String uriString, Uint8List data) {
    _assets[uriString] = data;
    _emitChange(Uri.parse(uriString), BundleChangeType.created);
  }

  /// Clear all stored data.
  void clear() {
    _bundles.clear();
    _assets.clear();
  }

  /// Get all stored bundle URIs.
  List<String> get bundleUris => _bundles.keys.toList();

  /// Get all stored asset URIs.
  List<String> get assetUris => _assets.keys.toList();

  void _emitChange(Uri uri, BundleChangeType type) {
    _changes.add(BundleChangeEvent(
      uri: uri,
      type: type,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<Map<String, dynamic>> readBundle(Uri uri) async {
    final key = uri.toString();
    final bundle = _bundles[key];
    if (bundle == null) {
      throw BundleNotFoundException(uri);
    }
    return _deepCopy(bundle);
  }

  @override
  Future<void> writeBundle(Uri uri, Map<String, dynamic> data) async {
    final key = uri.toString();
    final isNew = !_bundles.containsKey(key);
    _bundles[key] = _deepCopy(data);
    _emitChange(uri, isNew ? BundleChangeType.created : BundleChangeType.modified);
  }

  @override
  Future<Uint8List> readAsset(Uri uri) async {
    final key = uri.toString();
    final asset = _assets[key];
    if (asset == null) {
      throw AssetNotFoundException(uri);
    }
    return Uint8List.fromList(asset);
  }

  @override
  Future<void> writeAsset(Uri uri, Uint8List data) async {
    final key = uri.toString();
    final isNew = !_assets.containsKey(key);
    _assets[key] = Uint8List.fromList(data);
    _emitChange(uri, isNew ? BundleChangeType.created : BundleChangeType.modified);
  }

  @override
  Future<bool> exists(Uri uri) async {
    final key = uri.toString();
    return _bundles.containsKey(key) || _assets.containsKey(key);
  }

  @override
  Future<void> delete(Uri uri) async {
    final key = uri.toString();
    final existed = _bundles.remove(key) != null || _assets.remove(key) != null;
    if (existed) {
      _emitChange(uri, BundleChangeType.deleted);
    }
  }

  @override
  Future<List<Uri>> list(Uri directoryUri) async {
    final prefix = directoryUri.toString();
    final results = <Uri>[];

    for (final key in _bundles.keys) {
      if (key.startsWith(prefix)) {
        results.add(Uri.parse(key));
      }
    }

    return results;
  }

  @override
  Stream<BundleChangeEvent>? watch(Uri uri) {
    return _changes.stream;
  }

  /// Dispose the adapter and close streams.
  void dispose() {
    _changes.close();
  }

  /// Deep copy a JSON-compatible value.
  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}
