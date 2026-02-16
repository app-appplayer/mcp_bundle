/// Storage Port - Unified interface for storage operations.
///
/// Provides abstract contracts for storage operations that can be implemented
/// by various storage backends (memory, file, database, cloud).
library;

/// Generic storage port for typed entities.
abstract class StoragePort<T> {
  /// Save an item.
  Future<void> save(String id, T item);

  /// Get an item by ID.
  Future<T?> get(String id);

  /// Delete an item.
  Future<void> delete(String id);

  /// Get all items.
  Future<List<T>> getAll();

  /// Query items by criteria.
  Future<List<T>> query(Map<String, dynamic> criteria);

  /// Check if item exists.
  Future<bool> exists(String id);
}

/// Key-value storage port.
abstract class KvStoragePort {
  /// Set a value.
  Future<void> set(String key, dynamic value);

  /// Get a value.
  Future<dynamic> get(String key);

  /// Remove a value.
  Future<void> remove(String key);

  /// Check if key exists.
  Future<bool> exists(String key);

  /// List keys with optional prefix.
  Future<List<String>> keys({String? prefix});

  /// Clear all data.
  Future<void> clear();
}

/// In-memory KV storage for testing.
class InMemoryKvStoragePort implements KvStoragePort {
  final Map<String, dynamic> _data = {};

  @override
  Future<void> set(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  Future<dynamic> get(String key) async {
    return _data[key];
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<bool> exists(String key) async {
    return _data.containsKey(key);
  }

  @override
  Future<List<String>> keys({String? prefix}) async {
    if (prefix == null) return _data.keys.toList();
    return _data.keys.where((k) => k.startsWith(prefix)).toList();
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }
}

/// In-memory typed storage for testing.
class InMemoryStoragePort<T> implements StoragePort<T> {
  final Map<String, T> _data = {};

  @override
  Future<void> save(String id, T item) async {
    _data[id] = item;
  }

  @override
  Future<T?> get(String id) async {
    return _data[id];
  }

  @override
  Future<void> delete(String id) async {
    _data.remove(id);
  }

  @override
  Future<List<T>> getAll() async {
    return _data.values.toList();
  }

  @override
  Future<List<T>> query(Map<String, dynamic> criteria) async {
    // Simple implementation: return all items (override for filtering)
    return _data.values.toList();
  }

  @override
  Future<bool> exists(String id) async {
    return _data.containsKey(id);
  }
}
