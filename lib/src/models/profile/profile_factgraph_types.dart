/// Profile FactGraph Types - DTOs extracted from the legacy
/// `ProfileFactGraphPort` per REDESIGN-PLAN.md Phase 2 substep (0.1.0-a3).
///
/// Previously these types lived inline in
/// `mcp_bundle/dart/lib/src/ports/profile_factgraph_port.dart`. They were
/// moved here so that Phase 9 deletion of the legacy port file does not
/// take the DTOs with it. The legacy port file re-exports this library
/// during the transition window.
library;

import '../../types/period.dart';

// =============================================================================
// Fact Types
// =============================================================================

/// A fact in the fact graph (for profile queries).
class ProfileFact {
  /// Fact ID.
  final String id;

  /// Entity ID this fact belongs to.
  final String entityId;

  /// Fact type.
  final String type;

  /// Fact content.
  final Map<String, dynamic> content;

  /// Confidence score.
  final double confidence;

  /// Period when fact is valid (uses canonical Period type).
  final Period? period;

  /// Evidence references.
  final List<String> evidenceRefs;

  /// Creation timestamp.
  final DateTime createdAt;

  const ProfileFact({
    required this.id,
    required this.entityId,
    required this.type,
    required this.content,
    this.confidence = 1.0,
    this.period,
    this.evidenceRefs = const [],
    required this.createdAt,
  });

  factory ProfileFact.fromJson(Map<String, dynamic> json) {
    return ProfileFact(
      id: json['id'] as String,
      entityId: json['entityId'] as String,
      type: json['type'] as String,
      content: json['content'] as Map<String, dynamic>? ?? {},
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      period: json['period'] != null
          ? Period.fromJson(json['period'] as Map<String, dynamic>)
          : null,
      evidenceRefs: (json['evidenceRefs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityId': entityId,
        'type': type,
        'content': content,
        'confidence': confidence,
        if (period != null) 'period': period!.toJson(),
        if (evidenceRefs.isNotEmpty) 'evidenceRefs': evidenceRefs,
        'createdAt': createdAt.toIso8601String(),
      };
}

// =============================================================================
// Metric Types
// =============================================================================

/// A metric value for profile evaluation.
class ProfileMetricValue {
  /// Metric name.
  final String name;

  /// Metric value.
  final dynamic value;

  /// Value type.
  final String valueType;

  /// Confidence.
  final double confidence;

  /// Computation timestamp.
  final DateTime computedAt;

  /// Period for this value (uses canonical Period type).
  final Period? period;

  const ProfileMetricValue({
    required this.name,
    required this.value,
    this.valueType = 'number',
    this.confidence = 1.0,
    required this.computedAt,
    this.period,
  });

  factory ProfileMetricValue.fromJson(Map<String, dynamic> json) {
    return ProfileMetricValue(
      name: json['name'] as String,
      value: json['value'],
      valueType: json['valueType'] as String? ?? 'number',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      computedAt: DateTime.parse(json['computedAt'] as String),
      period: json['period'] != null
          ? Period.fromJson(json['period'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'valueType': valueType,
        'confidence': confidence,
        'computedAt': computedAt.toIso8601String(),
        if (period != null) 'period': period!.toJson(),
      };

  /// Get value as double.
  double get asDouble {
    if (value is num) return (value as num).toDouble();
    return 0.0;
  }

  /// Get value as int.
  int get asInt {
    if (value is num) return (value as num).toInt();
    return 0;
  }

  /// Get value as string.
  String get asString {
    return value?.toString() ?? '';
  }
}

// =============================================================================
// Summary Types
// =============================================================================

/// A summary for profile evaluation.
class ProfileSummary {
  /// Summary ID.
  final String id;

  /// Entity ID.
  final String entityId;

  /// Summary type.
  final String type;

  /// Summary content.
  final String content;

  /// Confidence score.
  final double confidence;

  /// Period covered (uses canonical Period type).
  final Period? period;

  /// Source fact IDs.
  final List<String> sourceFactIds;

  /// Creation timestamp.
  final DateTime createdAt;

  const ProfileSummary({
    required this.id,
    required this.entityId,
    required this.type,
    required this.content,
    this.confidence = 1.0,
    this.period,
    this.sourceFactIds = const [],
    required this.createdAt,
  });

  factory ProfileSummary.fromJson(Map<String, dynamic> json) {
    return ProfileSummary(
      id: json['id'] as String,
      entityId: json['entityId'] as String,
      type: json['type'] as String,
      content: json['content'] as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      period: json['period'] != null
          ? Period.fromJson(json['period'] as Map<String, dynamic>)
          : null,
      sourceFactIds: (json['sourceFactIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityId': entityId,
        'type': type,
        'content': content,
        'confidence': confidence,
        if (period != null) 'period': period!.toJson(),
        if (sourceFactIds.isNotEmpty) 'sourceFactIds': sourceFactIds,
        'createdAt': createdAt.toIso8601String(),
      };
}

// =============================================================================
// Pattern Types
// =============================================================================

/// A pattern detected in data (for profile evaluation).
class ProfilePattern {
  /// Pattern ID.
  final String id;

  /// Pattern type.
  final String type;

  /// Pattern description.
  final String description;

  /// Confidence score.
  final double confidence;

  /// Pattern frequency.
  final int frequency;

  /// Related entity IDs.
  final List<String> entityIds;

  /// Pattern features.
  final Map<String, dynamic> features;

  /// Detection timestamp.
  final DateTime detectedAt;

  const ProfilePattern({
    required this.id,
    required this.type,
    required this.description,
    this.confidence = 1.0,
    this.frequency = 1,
    this.entityIds = const [],
    this.features = const {},
    required this.detectedAt,
  });

  factory ProfilePattern.fromJson(Map<String, dynamic> json) {
    return ProfilePattern(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      frequency: json['frequency'] as int? ?? 1,
      entityIds: (json['entityIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      features: json['features'] as Map<String, dynamic>? ?? {},
      detectedAt: DateTime.parse(json['detectedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'description': description,
        'confidence': confidence,
        'frequency': frequency,
        if (entityIds.isNotEmpty) 'entityIds': entityIds,
        if (features.isNotEmpty) 'features': features,
        'detectedAt': detectedAt.toIso8601String(),
      };
}

// =============================================================================
// Context Bundle Types
// =============================================================================

/// A context bundle for profile evaluation.
class ProfileContextBundle {
  /// Bundle ID.
  final String id;

  /// Bundle type.
  final String type;

  /// Primary entity ID.
  final String entityId;

  /// Facts in the bundle.
  final List<ProfileFact> facts;

  /// Metrics in the bundle.
  final Map<String, ProfileMetricValue> metrics;

  /// Summaries in the bundle.
  final List<ProfileSummary> summaries;

  /// Period covered (uses canonical Period type).
  final Period? period;

  /// Creation timestamp.
  final DateTime createdAt;

  const ProfileContextBundle({
    required this.id,
    required this.type,
    required this.entityId,
    this.facts = const [],
    this.metrics = const {},
    this.summaries = const [],
    this.period,
    required this.createdAt,
  });

  factory ProfileContextBundle.fromJson(Map<String, dynamic> json) {
    return ProfileContextBundle(
      id: json['id'] as String,
      type: json['type'] as String,
      entityId: json['entityId'] as String,
      facts: (json['facts'] as List<dynamic>?)
              ?.map((e) => ProfileFact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metrics: (json['metrics'] as Map<String, dynamic>?)?.map(
            (k, v) =>
                MapEntry(k, ProfileMetricValue.fromJson(v as Map<String, dynamic>)),
          ) ??
          {},
      summaries: (json['summaries'] as List<dynamic>?)
              ?.map((e) => ProfileSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      period: json['period'] != null
          ? Period.fromJson(json['period'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'entityId': entityId,
        if (facts.isNotEmpty) 'facts': facts.map((f) => f.toJson()).toList(),
        if (metrics.isNotEmpty)
          'metrics': metrics.map((k, v) => MapEntry(k, v.toJson())),
        if (summaries.isNotEmpty)
          'summaries': summaries.map((s) => s.toJson()).toList(),
        if (period != null) 'period': period!.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };
}
