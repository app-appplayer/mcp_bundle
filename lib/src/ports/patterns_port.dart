/// Patterns Port - Pattern storage and retrieval.
///
/// Capability-named port per REDESIGN-PLAN.md §3.1.
///
/// Provider: `mcp_fact_graph`.
library;

/// Port for pattern operations.
abstract class PatternsPort {
  /// Store a pattern.
  Future<String> storePattern(PatternRecord pattern);

  /// Query patterns by workspace/type/entity/frequency.
  Future<List<PatternRecord>> queryPatterns(PatternQuery query);

  /// Get a pattern by ID.
  Future<PatternRecord?> getPattern(String id);
}

/// Canonical pattern record.
class PatternRecord {
  /// Pattern identifier.
  final String id;

  /// Workspace identifier.
  final String workspaceId;

  /// Pattern type.
  final String type;

  /// Human-readable description.
  final String description;

  /// Confidence score.
  final double confidence;

  /// Observation frequency.
  final int frequency;

  /// Related entity identifiers.
  final List<String> entityIds;

  /// Pattern feature bag.
  final Map<String, dynamic> features;

  /// Detection timestamp.
  final DateTime detectedAt;

  const PatternRecord({
    required this.id,
    required this.workspaceId,
    required this.type,
    required this.description,
    this.confidence = 1.0,
    this.frequency = 1,
    this.entityIds = const [],
    this.features = const {},
    required this.detectedAt,
  });
}

/// Query descriptor for [PatternsPort.queryPatterns].
class PatternQuery {
  /// Workspace identifier.
  final String workspaceId;

  /// Pattern type filter.
  final String? type;

  /// Entity filter.
  final String? entityId;

  /// Minimum frequency filter.
  final int? minFrequency;

  /// Maximum results.
  final int? limit;

  const PatternQuery({
    required this.workspaceId,
    this.type,
    this.entityId,
    this.minFrequency,
    this.limit,
  });
}

/// Stub implementation for testing.
class StubPatternsPort implements PatternsPort {
  const StubPatternsPort();

  @override
  Future<String> storePattern(PatternRecord pattern) async => pattern.id;

  @override
  Future<List<PatternRecord>> queryPatterns(PatternQuery query) async => [];

  @override
  Future<PatternRecord?> getPattern(String id) async => null;
}
