/// Knowledge Ports - Collection storage.
///
/// Standalone ports (`McpPort`, `EvidencePort`, `ExpressionPort`) live in
/// their own files under `ports/` and are exported via `ports.dart`. This
/// file defines only `CollectionStoragePort`.
library;

// =============================================================================
// Collection Storage Port
// =============================================================================

/// Abstract collection-based storage port.
///
/// Provides collection-based storage with query support.
/// Unlike KvStoragePort (key-value), this port organizes data into collections.
abstract class CollectionStoragePort {
  /// Save an item to a collection.
  Future<void> save(String collection, String id, Map<String, dynamic> data);

  /// Get an item by collection and ID.
  Future<Map<String, dynamic>?> get(String collection, String id);

  /// Query items in a collection.
  Future<List<Map<String, dynamic>>> query(
    String collection,
    QueryFilter filter,
  );

  /// Delete an item from a collection.
  Future<void> delete(String collection, String id);

  /// Check if an item exists.
  Future<bool> exists(String collection, String id);

  /// List all IDs in a collection.
  Future<List<String>> listIds(String collection);
}

/// Query filter for collection storage.
class QueryFilter {
  /// Filter conditions.
  final Map<String, dynamic> conditions;

  /// Maximum number of results.
  final int? limit;

  /// Offset for pagination.
  final int? offset;

  /// Field to order by.
  final String? orderBy;

  /// Whether to order descending.
  final bool descending;

  const QueryFilter({
    this.conditions = const {},
    this.limit,
    this.offset,
    this.orderBy,
    this.descending = false,
  });

  /// Empty filter.
  static const QueryFilter empty = QueryFilter();
}

/// In-memory collection storage for testing.
class InMemoryCollectionStoragePort implements CollectionStoragePort {
  final Map<String, Map<String, Map<String, dynamic>>> _data = {};

  @override
  Future<void> save(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    _data.putIfAbsent(collection, () => {});
    _data[collection]![id] = data;
  }

  @override
  Future<Map<String, dynamic>?> get(String collection, String id) async {
    return _data[collection]?[id];
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String collection,
    QueryFilter filter,
  ) async {
    final collectionData = _data[collection]?.values.toList() ?? [];
    var result = collectionData;
    if (filter.offset != null && filter.offset! > 0) {
      result = result.skip(filter.offset!).toList();
    }
    if (filter.limit != null) {
      result = result.take(filter.limit!).toList();
    }
    return result;
  }

  @override
  Future<void> delete(String collection, String id) async {
    _data[collection]?.remove(id);
  }

  @override
  Future<bool> exists(String collection, String id) async {
    return _data[collection]?.containsKey(id) ?? false;
  }

  @override
  Future<List<String>> listIds(String collection) async {
    return _data[collection]?.keys.toList() ?? [];
  }

  /// Clear all data.
  void clear() {
    _data.clear();
  }
}
