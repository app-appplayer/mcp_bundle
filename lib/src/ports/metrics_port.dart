/// Metrics Port (evaluation) - Evaluation-layer metric retrieval/computation.
///
/// This is the **evaluation-layer `MetricsPort`** (plural). For the
/// instrumentation-layer `MetricPort` (singular), see `metric_port.dart`.
/// They are intentionally distinct capabilities — REDESIGN-PLAN.md §3.4
/// Open Question (0.1.0-a2) default: retain singular/plural distinction.
///
/// Provider: `mcp_profile`.
library;

import '../types/appraisal_result.dart';
import '../types/period.dart';

/// Port for evaluation metric operations.
abstract class MetricsPort {
  /// Retrieve a single metric for an entity over a period.
  Future<MetricResult?> getMetric(
    String name,
    String entityId, {
    Period? period,
  });

  /// Retrieve multiple metrics for an entity.
  Future<Map<String, MetricResult>> getMetrics(
    List<String> names,
    String entityId, {
    Period? period,
  });

  /// Compute a metric on demand from a specification.
  Future<MetricResult> computeMetric(MetricSpec spec);
}

/// Specification for on-demand metric computation.
class MetricSpec {
  /// Metric identifier.
  final String id;

  /// Entity identifier (target).
  final String entityId;

  /// Period.
  final Period? period;

  /// Computation parameters.
  final Map<String, dynamic>? parameters;

  const MetricSpec({
    required this.id,
    required this.entityId,
    this.period,
    this.parameters,
  });
}

/// Stub implementation for testing.
class StubMetricsPort implements MetricsPort {
  const StubMetricsPort();

  @override
  Future<MetricResult?> getMetric(
    String name,
    String entityId, {
    Period? period,
  }) async =>
      null;

  @override
  Future<Map<String, MetricResult>> getMetrics(
    List<String> names,
    String entityId, {
    Period? period,
  }) async =>
      {};

  @override
  Future<MetricResult> computeMetric(MetricSpec spec) async {
    return MetricResult(
      id: spec.id,
      normalizedValue: 0.5,
      sourceType: MetricSourceType.static_,
      confidence: 0.5,
    );
  }
}
