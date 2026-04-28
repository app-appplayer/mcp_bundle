/// FactGraph section models for MCP Bundle.
///
/// Contains embedded fact graph data and configuration.
/// Separate from FactGraphSchema which defines type definitions.
library;

/// A section containing embedded FactGraph data.
class FactGraphSection {
  /// Schema version.
  final String version;

  /// Storage mode: embedded, referenced, or hybrid.
  final FactGraphMode mode;

  /// Embedded data (facts, entities, relations).
  final EmbeddedFactGraphData? embedded;

  /// External reference configuration.
  final ExternalFactGraphRef? external;

  /// Extraction configuration.
  final ExtractionConfig? extraction;

  const FactGraphSection({
    this.version = '1.0.0',
    this.mode = FactGraphMode.embedded,
    this.embedded,
    this.external,
    this.extraction,
  });

  /// Create from JSON.
  factory FactGraphSection.fromJson(Map<String, dynamic> json) {
    return FactGraphSection(
      version: json['version'] as String? ?? '1.0.0',
      mode: FactGraphMode.fromString(json['mode'] as String?),
      embedded: json['embedded'] != null
          ? EmbeddedFactGraphData.fromJson(
              json['embedded'] as Map<String, dynamic>)
          : null,
      external: json['external'] != null
          ? ExternalFactGraphRef.fromJson(
              json['external'] as Map<String, dynamic>)
          : null,
      extraction: json['extraction'] != null
          ? ExtractionConfig.fromJson(
              json['extraction'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'version': version,
        'mode': mode.name,
        if (embedded != null) 'embedded': embedded!.toJson(),
        if (external != null) 'external': external!.toJson(),
        if (extraction != null) 'extraction': extraction!.toJson(),
      };

  /// Create a copy with modifications.
  FactGraphSection copyWith({
    String? version,
    FactGraphMode? mode,
    EmbeddedFactGraphData? embedded,
    ExternalFactGraphRef? external,
    ExtractionConfig? extraction,
  }) {
    return FactGraphSection(
      version: version ?? this.version,
      mode: mode ?? this.mode,
      embedded: embedded ?? this.embedded,
      external: external ?? this.external,
      extraction: extraction ?? this.extraction,
    );
  }
}

/// Storage mode for FactGraph data.
enum FactGraphMode {
  /// All data embedded in the bundle.
  embedded,

  /// Data stored externally, bundle contains references.
  referenced,

  /// Mix of embedded and referenced data.
  hybrid;

  static FactGraphMode fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'referenced':
        return FactGraphMode.referenced;
      case 'hybrid':
        return FactGraphMode.hybrid;
      case 'embedded':
      default:
        return FactGraphMode.embedded;
    }
  }
}

/// Container for embedded FactGraph data.
class EmbeddedFactGraphData {
  /// Embedded entities.
  final List<EmbeddedEntity> entities;

  /// Embedded facts.
  final List<EmbeddedFact> facts;

  /// Embedded relations.
  final List<EmbeddedRelation> relations;

  /// Embedded summaries.
  final List<EmbeddedSummary> summaries;

  /// Embedded policies.
  final List<EmbeddedPolicy> policies;

  const EmbeddedFactGraphData({
    this.entities = const [],
    this.facts = const [],
    this.relations = const [],
    this.summaries = const [],
    this.policies = const [],
  });

  /// Create from JSON.
  factory EmbeddedFactGraphData.fromJson(Map<String, dynamic> json) {
    return EmbeddedFactGraphData(
      entities: (json['entities'] as List<dynamic>?)
              ?.map((e) => EmbeddedEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      facts: (json['facts'] as List<dynamic>?)
              ?.map((e) => EmbeddedFact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      relations: (json['relations'] as List<dynamic>?)
              ?.map((e) => EmbeddedRelation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summaries: (json['summaries'] as List<dynamic>?)
              ?.map((e) => EmbeddedSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      policies: (json['policies'] as List<dynamic>?)
              ?.map((e) => EmbeddedPolicy.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        if (entities.isNotEmpty)
          'entities': entities.map((e) => e.toJson()).toList(),
        if (facts.isNotEmpty) 'facts': facts.map((f) => f.toJson()).toList(),
        if (relations.isNotEmpty)
          'relations': relations.map((r) => r.toJson()).toList(),
        if (summaries.isNotEmpty)
          'summaries': summaries.map((s) => s.toJson()).toList(),
        if (policies.isNotEmpty)
          'policies': policies.map((p) => p.toJson()).toList(),
      };

  /// Check if data is empty.
  bool get isEmpty =>
      entities.isEmpty &&
      facts.isEmpty &&
      relations.isEmpty &&
      summaries.isEmpty &&
      policies.isEmpty;

  /// Check if data is not empty.
  bool get isNotEmpty => !isEmpty;
}

/// An embedded entity in the FactGraph.
class EmbeddedEntity {
  /// Unique identifier.
  final String id;

  /// Entity type (must match schema).
  final String type;

  /// Entity name/label.
  final String? name;

  /// Entity properties.
  final Map<String, dynamic> properties;

  /// Source reference.
  final String? sourceId;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last update timestamp.
  final DateTime? updatedAt;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const EmbeddedEntity({
    required this.id,
    required this.type,
    this.name,
    this.properties = const {},
    this.sourceId,
    this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  /// Create from JSON.
  factory EmbeddedEntity.fromJson(Map<String, dynamic> json) {
    return EmbeddedEntity(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      name: json['name'] as String?,
      properties: json['properties'] as Map<String, dynamic>? ?? {},
      sourceId: json['sourceId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        if (name != null) 'name': name,
        if (properties.isNotEmpty) 'properties': properties,
        if (sourceId != null) 'sourceId': sourceId,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Create a copy with modifications.
  EmbeddedEntity copyWith({
    String? id,
    String? type,
    String? name,
    Map<String, dynamic>? properties,
    String? sourceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return EmbeddedEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      properties: properties ?? this.properties,
      sourceId: sourceId ?? this.sourceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// An embedded fact in the FactGraph.
class EmbeddedFact {
  /// Unique identifier.
  final String id;

  /// Fact type (must match schema).
  final String type;

  /// Entity this fact belongs to.
  final String entityId;

  /// Fact value.
  final dynamic value;

  /// Confidence score (0.0-1.0).
  final double confidence;

  /// Source reference.
  final String? sourceId;

  /// Evidence references.
  final List<String> evidenceRefs;

  /// Valid from date.
  final DateTime? validFrom;

  /// Valid until date.
  final DateTime? validUntil;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const EmbeddedFact({
    required this.id,
    required this.type,
    required this.entityId,
    required this.value,
    this.confidence = 1.0,
    this.sourceId,
    this.evidenceRefs = const [],
    this.validFrom,
    this.validUntil,
    this.createdAt,
    this.metadata = const {},
  });

  /// Create from JSON.
  factory EmbeddedFact.fromJson(Map<String, dynamic> json) {
    return EmbeddedFact(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      entityId: json['entityId'] as String? ?? '',
      value: json['value'],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      sourceId: json['sourceId'] as String?,
      evidenceRefs: (json['evidenceRefs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      validFrom: json['validFrom'] != null
          ? DateTime.tryParse(json['validFrom'] as String)
          : null,
      validUntil: json['validUntil'] != null
          ? DateTime.tryParse(json['validUntil'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'entityId': entityId,
        'value': value,
        if (confidence != 1.0) 'confidence': confidence,
        if (sourceId != null) 'sourceId': sourceId,
        if (evidenceRefs.isNotEmpty) 'evidenceRefs': evidenceRefs,
        if (validFrom != null) 'validFrom': validFrom!.toIso8601String(),
        if (validUntil != null) 'validUntil': validUntil!.toIso8601String(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Create a copy with modifications.
  EmbeddedFact copyWith({
    String? id,
    String? type,
    String? entityId,
    dynamic value,
    double? confidence,
    String? sourceId,
    List<String>? evidenceRefs,
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return EmbeddedFact(
      id: id ?? this.id,
      type: type ?? this.type,
      entityId: entityId ?? this.entityId,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      sourceId: sourceId ?? this.sourceId,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// An embedded relation in the FactGraph.
class EmbeddedRelation {
  /// Unique identifier.
  final String id;

  /// Relation type (must match schema).
  final String type;

  /// Source entity ID.
  final String fromEntityId;

  /// Target entity ID.
  final String toEntityId;

  /// Relation properties.
  final Map<String, dynamic> properties;

  /// Confidence score (0.0-1.0).
  final double confidence;

  /// Source reference.
  final String? sourceId;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const EmbeddedRelation({
    required this.id,
    required this.type,
    required this.fromEntityId,
    required this.toEntityId,
    this.properties = const {},
    this.confidence = 1.0,
    this.sourceId,
    this.createdAt,
    this.metadata = const {},
  });

  /// Create from JSON.
  factory EmbeddedRelation.fromJson(Map<String, dynamic> json) {
    return EmbeddedRelation(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      fromEntityId: json['fromEntityId'] as String? ?? json['from'] as String? ?? '',
      toEntityId: json['toEntityId'] as String? ?? json['to'] as String? ?? '',
      properties: json['properties'] as Map<String, dynamic>? ?? {},
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      sourceId: json['sourceId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'fromEntityId': fromEntityId,
        'toEntityId': toEntityId,
        if (properties.isNotEmpty) 'properties': properties,
        if (confidence != 1.0) 'confidence': confidence,
        if (sourceId != null) 'sourceId': sourceId,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Create a copy with modifications.
  EmbeddedRelation copyWith({
    String? id,
    String? type,
    String? fromEntityId,
    String? toEntityId,
    Map<String, dynamic>? properties,
    double? confidence,
    String? sourceId,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return EmbeddedRelation(
      id: id ?? this.id,
      type: type ?? this.type,
      fromEntityId: fromEntityId ?? this.fromEntityId,
      toEntityId: toEntityId ?? this.toEntityId,
      properties: properties ?? this.properties,
      confidence: confidence ?? this.confidence,
      sourceId: sourceId ?? this.sourceId,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// An embedded summary in the FactGraph.
class EmbeddedSummary {
  /// Unique identifier.
  final String id;

  /// Summary type.
  final String type;

  /// Entity this summary belongs to (optional).
  final String? entityId;

  /// Summary content.
  final String content;

  /// Source facts used to generate this summary.
  final List<String> sourceFactIds;

  /// Generation timestamp.
  final DateTime? generatedAt;

  /// Confidence score (0.0-1.0).
  final double confidence;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const EmbeddedSummary({
    required this.id,
    required this.type,
    this.entityId,
    required this.content,
    this.sourceFactIds = const [],
    this.generatedAt,
    this.confidence = 1.0,
    this.metadata = const {},
  });

  /// Create from JSON.
  factory EmbeddedSummary.fromJson(Map<String, dynamic> json) {
    return EmbeddedSummary(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      entityId: json['entityId'] as String?,
      content: json['content'] as String? ?? '',
      sourceFactIds: (json['sourceFactIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'] as String)
          : null,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        if (entityId != null) 'entityId': entityId,
        'content': content,
        if (sourceFactIds.isNotEmpty) 'sourceFactIds': sourceFactIds,
        if (generatedAt != null) 'generatedAt': generatedAt!.toIso8601String(),
        if (confidence != 1.0) 'confidence': confidence,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

/// An embedded policy in the FactGraph.
class EmbeddedPolicy {
  /// Unique identifier.
  final String id;

  /// Policy name.
  final String name;

  /// Policy type.
  final String type;

  /// Policy rules.
  final List<EmbeddedPolicyRule> rules;

  /// Priority (higher = evaluated first).
  final int priority;

  /// Whether policy is enabled.
  final bool enabled;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const EmbeddedPolicy({
    required this.id,
    required this.name,
    required this.type,
    this.rules = const [],
    this.priority = 0,
    this.enabled = true,
    this.metadata = const {},
  });

  /// Create from JSON.
  factory EmbeddedPolicy.fromJson(Map<String, dynamic> json) {
    return EmbeddedPolicy(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      rules: (json['rules'] as List<dynamic>?)
              ?.map(
                  (e) => EmbeddedPolicyRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      priority: json['priority'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        if (rules.isNotEmpty) 'rules': rules.map((r) => r.toJson()).toList(),
        if (priority != 0) 'priority': priority,
        if (!enabled) 'enabled': enabled,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

/// A rule within an embedded policy.
class EmbeddedPolicyRule {
  /// Rule identifier.
  final String id;

  /// Condition expression.
  final String condition;

  /// Action to take when condition is met.
  final String action;

  /// Action parameters.
  final Map<String, dynamic> parameters;

  const EmbeddedPolicyRule({
    required this.id,
    required this.condition,
    required this.action,
    this.parameters = const {},
  });

  /// Create from JSON.
  factory EmbeddedPolicyRule.fromJson(Map<String, dynamic> json) {
    return EmbeddedPolicyRule(
      id: json['id'] as String? ?? '',
      condition: json['condition'] as String? ?? '',
      action: json['action'] as String? ?? '',
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'condition': condition,
        'action': action,
        if (parameters.isNotEmpty) 'parameters': parameters,
      };
}

/// External FactGraph reference configuration.
class ExternalFactGraphRef {
  /// URI to external FactGraph service.
  final String uri;

  /// Namespace for scoping.
  final String? namespace;

  /// Authentication configuration.
  final Map<String, dynamic>? authentication;

  /// Sync policy.
  final SyncPolicy? syncPolicy;

  const ExternalFactGraphRef({
    required this.uri,
    this.namespace,
    this.authentication,
    this.syncPolicy,
  });

  /// Create from JSON.
  factory ExternalFactGraphRef.fromJson(Map<String, dynamic> json) {
    return ExternalFactGraphRef(
      uri: json['uri'] as String? ?? '',
      namespace: json['namespace'] as String?,
      authentication: json['authentication'] as Map<String, dynamic>?,
      syncPolicy: json['syncPolicy'] != null
          ? SyncPolicy.fromJson(json['syncPolicy'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'uri': uri,
        if (namespace != null) 'namespace': namespace,
        if (authentication != null) 'authentication': authentication,
        if (syncPolicy != null) 'syncPolicy': syncPolicy!.toJson(),
      };
}

/// Sync policy for external FactGraph.
class SyncPolicy {
  /// Sync mode: realtime, periodic, manual.
  final String mode;

  /// Sync interval (for periodic mode).
  final Duration? interval;

  /// Conflict resolution strategy.
  final String conflictResolution;

  const SyncPolicy({
    this.mode = 'manual',
    this.interval,
    this.conflictResolution = 'lastWriteWins',
  });

  /// Create from JSON.
  factory SyncPolicy.fromJson(Map<String, dynamic> json) {
    return SyncPolicy(
      mode: json['mode'] as String? ?? 'manual',
      interval: json['intervalMs'] != null
          ? Duration(milliseconds: json['intervalMs'] as int)
          : null,
      conflictResolution:
          json['conflictResolution'] as String? ?? 'lastWriteWins',
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'mode': mode,
        if (interval != null) 'intervalMs': interval!.inMilliseconds,
        'conflictResolution': conflictResolution,
      };
}

/// Extraction configuration for FactGraph.
class ExtractionConfig {
  /// Extraction rules.
  final List<ExtractionRule> rules;

  /// Validators for extracted data.
  final List<ExtractionValidator> validators;

  const ExtractionConfig({
    this.rules = const [],
    this.validators = const [],
  });

  /// Create from JSON.
  factory ExtractionConfig.fromJson(Map<String, dynamic> json) {
    return ExtractionConfig(
      rules: (json['rules'] as List<dynamic>?)
              ?.map((e) => ExtractionRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      validators: (json['validators'] as List<dynamic>?)
              ?.map((e) =>
                  ExtractionValidator.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        if (rules.isNotEmpty) 'rules': rules.map((r) => r.toJson()).toList(),
        if (validators.isNotEmpty)
          'validators': validators.map((v) => v.toJson()).toList(),
      };
}

/// Extraction rule for FactGraph.
class ExtractionRule {
  /// Rule identifier.
  final String id;

  /// Source type to extract from.
  final String sourceType;

  /// Target entity/fact type.
  final String targetType;

  /// Extraction pattern or expression.
  final String pattern;

  /// Mapping configuration.
  final Map<String, dynamic> mapping;

  /// Whether rule is enabled.
  final bool enabled;

  const ExtractionRule({
    required this.id,
    required this.sourceType,
    required this.targetType,
    required this.pattern,
    this.mapping = const {},
    this.enabled = true,
  });

  /// Create from JSON.
  factory ExtractionRule.fromJson(Map<String, dynamic> json) {
    return ExtractionRule(
      id: json['id'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      pattern: json['pattern'] as String? ?? '',
      mapping: json['mapping'] as Map<String, dynamic>? ?? {},
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceType': sourceType,
        'targetType': targetType,
        'pattern': pattern,
        if (mapping.isNotEmpty) 'mapping': mapping,
        if (!enabled) 'enabled': enabled,
      };
}

/// Validator for extracted FactGraph data.
class ExtractionValidator {
  /// Validator identifier.
  final String id;

  /// Target type to validate.
  final String targetType;

  /// Validation rules.
  final List<ValidationRule> rules;

  const ExtractionValidator({
    required this.id,
    required this.targetType,
    this.rules = const [],
  });

  /// Create from JSON.
  factory ExtractionValidator.fromJson(Map<String, dynamic> json) {
    return ExtractionValidator(
      id: json['id'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      rules: (json['rules'] as List<dynamic>?)
              ?.map((e) => ValidationRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'targetType': targetType,
        if (rules.isNotEmpty) 'rules': rules.map((r) => r.toJson()).toList(),
      };
}

/// A validation rule.
class ValidationRule {
  /// Field to validate.
  final String field;

  /// Validation type: required, pattern, range, custom.
  final String type;

  /// Validation value (pattern, range, etc.).
  final dynamic value;

  /// Error message on failure.
  final String? message;

  const ValidationRule({
    required this.field,
    required this.type,
    this.value,
    this.message,
  });

  /// Create from JSON.
  factory ValidationRule.fromJson(Map<String, dynamic> json) {
    return ValidationRule(
      field: json['field'] as String? ?? '',
      type: json['type'] as String? ?? '',
      value: json['value'],
      message: json['message'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'field': field,
        'type': type,
        if (value != null) 'value': value,
        if (message != null) 'message': message,
      };
}
