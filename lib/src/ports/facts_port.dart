/// Facts Port - CRUD over canonical facts in the graph.
///
/// Capability-named port per REDESIGN-PLAN.md §3.1. Supersedes the
/// fact-query fragments in the legacy `SkillFactGraphPort`/
/// `ProfileFactGraphPort`/`ops_ports.FactGraphPort`.
///
/// Provider: `mcp_fact_graph`.
library;

import '../types/period.dart';

/// Port for fact graph fact operations.
abstract class FactsPort {
  /// Query facts by workspace, type, period, entity, or custom filters.
  Future<List<FactRecord>> queryFacts(FactQuery query);

  /// Write a batch of facts.
  Future<void> writeFacts(List<FactRecord> facts);

  /// Get a single fact by ID.
  Future<FactRecord?> getFact(String id);

  /// Delete facts by ID.
  Future<void> deleteFacts(List<String> ids);
}

/// Canonical fact record used by [FactsPort].
class FactRecord {
  /// Fact identifier.
  final String id;

  /// Workspace identifier.
  final String workspaceId;

  /// Fact type.
  final String type;

  /// Optional entity reference.
  final String? entityId;

  /// Fact content payload.
  final Map<String, dynamic> content;

  /// Confidence score (0.0 – 1.0).
  final double? confidence;

  /// Valid period.
  final Period? period;

  /// Evidence references.
  final List<String> evidenceRefs;

  /// Creation timestamp.
  final DateTime createdAt;

  const FactRecord({
    required this.id,
    required this.workspaceId,
    required this.type,
    this.entityId,
    required this.content,
    this.confidence,
    this.period,
    this.evidenceRefs = const [],
    required this.createdAt,
  });
}

/// Query descriptor for [FactsPort.queryFacts].
class FactQuery {
  /// Workspace identifier.
  final String workspaceId;

  /// Fact types to include.
  final List<String>? types;

  /// Entity identifier filter.
  final String? entityId;

  /// Time period filter.
  final Period? period;

  /// Point in time.
  final DateTime? asOf;

  /// Maximum results.
  final int? limit;

  /// Custom filters.
  final Map<String, dynamic>? filters;

  const FactQuery({
    required this.workspaceId,
    this.types,
    this.entityId,
    this.period,
    this.asOf,
    this.limit,
    this.filters,
  });
}

/// Stub implementation for testing.
class StubFactsPort implements FactsPort {
  const StubFactsPort();

  @override
  Future<List<FactRecord>> queryFacts(FactQuery query) async => [];

  @override
  Future<void> writeFacts(List<FactRecord> facts) async {}

  @override
  Future<FactRecord?> getFact(String id) async => null;

  @override
  Future<void> deleteFacts(List<String> ids) async {}
}
