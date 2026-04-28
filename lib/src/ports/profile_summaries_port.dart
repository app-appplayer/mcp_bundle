/// Profile Summaries Port - Evaluation-layer profile summaries.
///
/// Capability-named port per REDESIGN-PLAN.md §3.4. Distinct from the
/// fact-level `SummariesPort` — profile summaries are evaluation outputs.
///
/// Provider: `mcp_profile`.
library;

import '../types/period.dart';

/// Port for profile summary retrieval.
abstract class ProfileSummariesPort {
  /// Get a profile summary for an entity over a period.
  Future<ProfileSummaryResult?> getProfileSummary(
    String entityId, {
    Period? period,
  });
}

/// Evaluation-level profile summary result.
class ProfileSummaryResult {
  /// Entity identifier.
  final String entityId;

  /// Summary content (narrative form).
  final String narrative;

  /// Dimension scores (dimension ID → normalized score).
  final Map<String, double> dimensionScores;

  /// Confidence score.
  final double confidence;

  /// Period covered.
  final Period? period;

  /// Generation timestamp.
  final DateTime generatedAt;

  const ProfileSummaryResult({
    required this.entityId,
    required this.narrative,
    this.dimensionScores = const {},
    this.confidence = 1.0,
    this.period,
    required this.generatedAt,
  });
}

/// Stub implementation for testing.
class StubProfileSummariesPort implements ProfileSummariesPort {
  const StubProfileSummariesPort();

  @override
  Future<ProfileSummaryResult?> getProfileSummary(
    String entityId, {
    Period? period,
  }) async =>
      null;
}
