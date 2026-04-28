/// Summaries Port - Fact-level summary storage and refresh.
///
/// Capability-named port per REDESIGN-PLAN.md §3.1. Distinct from the
/// evaluation-layer `ProfileSummariesPort`: this port covers fact-level
/// rollups; profile summaries are evaluation outputs.
///
/// Provider: `mcp_fact_graph`.
library;

import '../types/period.dart';

/// Port for summary operations.
abstract class SummariesPort {
  /// Get a summary by entity and type.
  Future<SummaryRecord?> getSummary(
    String entityId,
    String summaryType, {
    Period? period,
  });

  /// Recompute a summary on demand.
  Future<SummaryRecord> refreshSummary(
    String entityId,
    String summaryType, {
    Period? period,
  });

  /// Mark summaries as stale (to be refreshed by workers).
  Future<void> markSummariesStale(
    List<String> entityIds, {
    String? summaryType,
  });

  /// Get stale summaries scheduled for refresh.
  Future<List<SummaryRecord>> getStaleSummaries({int? limit});
}

/// Canonical summary record.
class SummaryRecord {
  /// Summary identifier.
  final String id;

  /// Entity identifier.
  final String entityId;

  /// Summary type.
  final String type;

  /// Summary content.
  final String content;

  /// Confidence score.
  final double confidence;

  /// Whether the summary is stale and needs refresh.
  final bool isStale;

  /// Period covered.
  final Period? period;

  /// Source fact identifiers.
  final List<String> sourceFactIds;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last refresh timestamp.
  final DateTime? refreshedAt;

  const SummaryRecord({
    required this.id,
    required this.entityId,
    required this.type,
    required this.content,
    this.confidence = 1.0,
    this.isStale = false,
    this.period,
    this.sourceFactIds = const [],
    required this.createdAt,
    this.refreshedAt,
  });
}

/// Stub implementation for testing.
class StubSummariesPort implements SummariesPort {
  const StubSummariesPort();

  @override
  Future<SummaryRecord?> getSummary(
    String entityId,
    String summaryType, {
    Period? period,
  }) async =>
      null;

  @override
  Future<SummaryRecord> refreshSummary(
    String entityId,
    String summaryType, {
    Period? period,
  }) async {
    return SummaryRecord(
      id: '$entityId:$summaryType',
      entityId: entityId,
      type: summaryType,
      content: '',
      period: period,
      createdAt: DateTime.now(),
      refreshedAt: DateTime.now(),
    );
  }

  @override
  Future<void> markSummariesStale(
    List<String> entityIds, {
    String? summaryType,
  }) async {}

  @override
  Future<List<SummaryRecord>> getStaleSummaries({int? limit}) async => [];
}
