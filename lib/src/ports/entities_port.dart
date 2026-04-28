/// Entities Port - Entity CRUD and linking.
///
/// Capability-named port per REDESIGN-PLAN.md §3.1.
///
/// Provider: `mcp_fact_graph`.
library;

/// Port for entity operations in the fact graph.
abstract class EntitiesPort {
  /// Get an entity by ID.
  Future<EntityRecord?> getEntity(String entityId);

  /// Link an entity to another by a typed relationship.
  Future<void> linkEntity(
    String sourceId,
    String targetId,
    String relation, {
    Map<String, dynamic>? attributes,
  });

  /// Query entities.
  Future<List<EntityRecord>> queryEntities(EntityQuery query);

  /// Merge two entities; [surviving] absorbs [absorbed].
  Future<EntityRecord> mergeEntities(String surviving, String absorbed);
}

/// Canonical entity record.
class EntityRecord {
  /// Entity identifier.
  final String id;

  /// Workspace identifier.
  final String workspaceId;

  /// Entity type.
  final String type;

  /// Entity display name.
  final String name;

  /// Property bag.
  final Map<String, dynamic> properties;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime? updatedAt;

  const EntityRecord({
    required this.id,
    required this.workspaceId,
    required this.type,
    required this.name,
    this.properties = const {},
    required this.createdAt,
    this.updatedAt,
  });
}

/// Query descriptor for [EntitiesPort.queryEntities].
class EntityQuery {
  /// Workspace identifier.
  final String workspaceId;

  /// Entity types to include.
  final List<String>? types;

  /// Name contains filter.
  final String? nameContains;

  /// Property filters.
  final Map<String, dynamic>? propertyFilters;

  /// Maximum results.
  final int? limit;

  const EntityQuery({
    required this.workspaceId,
    this.types,
    this.nameContains,
    this.propertyFilters,
    this.limit,
  });
}

/// Stub implementation for testing.
class StubEntitiesPort implements EntitiesPort {
  const StubEntitiesPort();

  @override
  Future<EntityRecord?> getEntity(String entityId) async => null;

  @override
  Future<void> linkEntity(
    String sourceId,
    String targetId,
    String relation, {
    Map<String, dynamic>? attributes,
  }) async {}

  @override
  Future<List<EntityRecord>> queryEntities(EntityQuery query) async => [];

  @override
  Future<EntityRecord> mergeEntities(String surviving, String absorbed) async {
    return EntityRecord(
      id: surviving,
      workspaceId: 'stub',
      type: 'merged',
      name: 'stub',
      createdAt: DateTime.now(),
    );
  }
}
