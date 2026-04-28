/// Appraisal Result Types - Output of metric computation.
///
/// Canonical contract-layer types for profile appraisal results.
/// As per mcp_profile spec/02-appraisal-metrics-schema.md §8.
library;

// =============================================================================
// MetricSourceType
// =============================================================================

/// Source type for metric computation.
enum MetricSourceType {
  /// From fact graph queries.
  factgraph,

  /// Computed from other metrics.
  computed,

  /// Fixed static value.
  static_,

  /// LLM-derived analysis.
  llmDerived;

  /// JSON serialization name (snake_case per spec).
  String toJson() {
    return switch (this) {
      MetricSourceType.factgraph => 'factgraph',
      MetricSourceType.computed => 'computed',
      MetricSourceType.static_ => 'static',
      MetricSourceType.llmDerived => 'llm_derived',
    };
  }

  /// Parse from JSON string.
  static MetricSourceType fromJson(String value) {
    return switch (value) {
      'factgraph' => MetricSourceType.factgraph,
      'computed' => MetricSourceType.computed,
      'static' => MetricSourceType.static_,
      'llm_derived' => MetricSourceType.llmDerived,
      _ => MetricSourceType.computed,
    };
  }
}

// =============================================================================
// AppraisalResult (§8)
// =============================================================================

/// Complete result of appraisal metric computation.
class AppraisalResult {
  /// Profile ID used for appraisal.
  final String profileId;

  /// Context ID being appraised.
  final String contextId;

  /// Reference time for the appraisal.
  final DateTime asOf;

  /// Individual metric results.
  final Map<String, MetricResult> metrics;

  /// Aggregated overall score (0.0 - 1.0).
  final double aggregatedScore;

  /// Computation metadata.
  final AppraisalMetadata metadata;

  const AppraisalResult({
    required this.profileId,
    required this.contextId,
    required this.asOf,
    required this.metrics,
    required this.aggregatedScore,
    required this.metadata,
  });

  /// Get metric by ID.
  MetricResult? getMetric(String id) => metrics[id];

  /// Get normalized value for metric.
  double? getNormalizedValue(String id) => metrics[id]?.normalizedValue;

  /// Check if all metrics are high confidence (>= 0.6).
  bool get isHighConfidence {
    return metrics.values.every((m) => m.confidence >= 0.6);
  }

  /// Get low confidence metrics (<= 0.5).
  List<MetricResult> get lowConfidenceMetrics {
    return metrics.values.where((m) => m.confidence <= 0.5).toList();
  }

  factory AppraisalResult.fromJson(Map<String, dynamic> json) {
    return AppraisalResult(
      profileId: json['profileId'] as String,
      contextId: json['contextId'] as String,
      asOf: DateTime.parse(json['asOf'] as String),
      metrics: (json['metrics'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, MetricResult.fromJson(v as Map<String, dynamic>)),
      ),
      aggregatedScore: (json['aggregatedScore'] as num).toDouble(),
      metadata:
          AppraisalMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'contextId': contextId,
        'asOf': asOf.toIso8601String(),
        'metrics': metrics.map((k, v) => MapEntry(k, v.toJson())),
        'aggregatedScore': aggregatedScore,
        'metadata': metadata.toJson(),
      };

  /// Create an empty appraisal result.
  factory AppraisalResult.empty({
    required String profileId,
    String contextId = '',
    DateTime? asOf,
  }) {
    return AppraisalResult(
      profileId: profileId,
      contextId: contextId,
      asOf: asOf ?? DateTime.now(),
      metrics: const {},
      aggregatedScore: 1.0,
      metadata: AppraisalMetadata(computedAt: DateTime.now()),
    );
  }
}

// =============================================================================
// MetricResult (§8)
// =============================================================================

/// Result for a single computed metric.
class MetricResult {
  /// Metric ID.
  final String id;

  /// Raw computed value (null if computation failed).
  final double? rawValue;

  /// Normalized value (0.0 - 1.0).
  final double normalizedValue;

  /// Source type used for computation.
  final MetricSourceType sourceType;

  /// Confidence in the computed value (0.0 - 1.0).
  final double confidence;

  const MetricResult({
    required this.id,
    this.rawValue,
    required this.normalizedValue,
    required this.sourceType,
    required this.confidence,
  });

  /// Check if this is a low confidence result.
  bool get isLowConfidence => confidence < 0.5;

  /// Check if this is a medium confidence result.
  bool get isMediumConfidence => confidence >= 0.5 && confidence < 0.8;

  /// Check if this is a high confidence result.
  bool get isHighConfidence => confidence >= 0.8;

  factory MetricResult.fromJson(Map<String, dynamic> json) {
    return MetricResult(
      id: json['id'] as String,
      rawValue: (json['rawValue'] as num?)?.toDouble(),
      normalizedValue: (json['normalizedValue'] as num).toDouble(),
      sourceType: MetricSourceType.fromJson(json['sourceType'] as String),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (rawValue != null) 'rawValue': rawValue,
        'normalizedValue': normalizedValue,
        'sourceType': sourceType.toJson(),
        'confidence': confidence,
      };
}

// =============================================================================
// AppraisalMetadata (§8)
// =============================================================================

/// Metadata about the appraisal computation.
class AppraisalMetadata {
  /// When computation was performed.
  final DateTime computedAt;

  /// Computation duration in milliseconds.
  final int durationMs;

  /// Count of sources used by type.
  final Map<String, int> sourceCounts;

  /// Metrics that couldn't be computed.
  final List<String> missingMetrics;

  /// Metrics with low confidence (< 0.5).
  final List<String>? lowConfidenceMetrics;

  /// Metrics that triggered require_evidence per §9.3 step 4.
  final List<String> metricsRequiringEvidence;

  /// Warnings during computation.
  final List<String> warnings;

  const AppraisalMetadata({
    required this.computedAt,
    this.durationMs = 0,
    this.sourceCounts = const {},
    this.missingMetrics = const [],
    this.lowConfidenceMetrics,
    this.metricsRequiringEvidence = const [],
    this.warnings = const [],
  });

  /// Get duration as Duration object.
  Duration get duration => Duration(milliseconds: durationMs);

  factory AppraisalMetadata.fromJson(Map<String, dynamic> json) {
    return AppraisalMetadata(
      computedAt: DateTime.parse(json['computedAt'] as String),
      durationMs: json['durationMs'] as int? ?? 0,
      sourceCounts: (json['sourceCounts'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      missingMetrics: (json['missingMetrics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lowConfidenceMetrics: (json['lowConfidenceMetrics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      metricsRequiringEvidence:
          (json['metricsRequiringEvidence'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'computedAt': computedAt.toIso8601String(),
        'durationMs': durationMs,
        if (sourceCounts.isNotEmpty) 'sourceCounts': sourceCounts,
        if (missingMetrics.isNotEmpty) 'missingMetrics': missingMetrics,
        if (lowConfidenceMetrics != null && lowConfidenceMetrics!.isNotEmpty)
          'lowConfidenceMetrics': lowConfidenceMetrics,
        if (metricsRequiringEvidence.isNotEmpty)
          'metricsRequiringEvidence': metricsRequiringEvidence,
        if (warnings.isNotEmpty) 'warnings': warnings,
      };
}

/// Configuration for confidence threshold behavior in appraisal.
class ConfidenceThresholdConfig {
  /// Minimum confidence required for metric to be used (default: 0.3).
  final double minConfidenceThreshold;

  /// Confidence below which metric is replaced with defaultValue (default: 0.2).
  final double fallbackThreshold;

  /// Whether low confidence triggers require_evidence modifier (default: true).
  final bool triggerEvidenceOnLowConfidence;

  /// Confidence threshold for triggering evidence requirement (default: 0.5).
  final double evidenceTriggerThreshold;

  const ConfidenceThresholdConfig({
    this.minConfidenceThreshold = 0.3,
    this.fallbackThreshold = 0.2,
    this.triggerEvidenceOnLowConfidence = true,
    this.evidenceTriggerThreshold = 0.5,
  });

  factory ConfidenceThresholdConfig.fromJson(Map<String, dynamic> json) {
    return ConfidenceThresholdConfig(
      minConfidenceThreshold:
          (json['minConfidenceThreshold'] as num?)?.toDouble() ?? 0.3,
      fallbackThreshold:
          (json['fallbackThreshold'] as num?)?.toDouble() ?? 0.2,
      triggerEvidenceOnLowConfidence:
          json['triggerEvidenceOnLowConfidence'] as bool? ?? true,
      evidenceTriggerThreshold:
          (json['evidenceTriggerThreshold'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() => {
        'minConfidenceThreshold': minConfidenceThreshold,
        'fallbackThreshold': fallbackThreshold,
        'triggerEvidenceOnLowConfidence': triggerEvidenceOnLowConfidence,
        'evidenceTriggerThreshold': evidenceTriggerThreshold,
      };
}
