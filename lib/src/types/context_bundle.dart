/// Canonical ContextBundle type for skill execution context.
///
/// Contains context information retrieved from the FactGraph
/// for enriching skill execution.
library;

/// Context bundle from FactGraph for skill execution.
///
/// Contains entities, events, views, and claims retrieved
/// from the fact graph to provide context for skill execution.
class ContextBundle {
  /// Bundle ID.
  final String id;

  /// Retrieved entities.
  final List<ContextEntity> entities;

  /// Retrieved events.
  final List<ContextEvent> events;

  /// Retrieved views/summaries.
  final List<ContextView> views;

  /// Claims from the context.
  final List<ContextClaim> claims;

  /// When the bundle was created.
  final DateTime createdAt;

  /// Total token count estimate.
  final int? estimatedTokens;

  const ContextBundle({
    required this.id,
    this.entities = const [],
    this.events = const [],
    this.views = const [],
    this.claims = const [],
    required this.createdAt,
    this.estimatedTokens,
  });

  /// Create an empty context bundle.
  factory ContextBundle.empty() {
    return ContextBundle(
      id: 'empty',
      createdAt: DateTime.now(),
    );
  }

  /// Create from JSON.
  factory ContextBundle.fromJson(Map<String, dynamic> json) {
    return ContextBundle(
      id: json['id'] as String? ?? '',
      entities: (json['entities'] as List<dynamic>?)
              ?.map((e) => ContextEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => ContextEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      views: (json['views'] as List<dynamic>?)
              ?.map((e) => ContextView.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      claims: (json['claims'] as List<dynamic>?)
              ?.map((e) => ContextClaim.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      estimatedTokens: json['estimatedTokens'] as int?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        if (entities.isNotEmpty)
          'entities': entities.map((e) => e.toJson()).toList(),
        if (events.isNotEmpty)
          'events': events.map((e) => e.toJson()).toList(),
        if (views.isNotEmpty) 'views': views.map((e) => e.toJson()).toList(),
        if (claims.isNotEmpty)
          'claims': claims.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        if (estimatedTokens != null) 'estimatedTokens': estimatedTokens,
      };

  /// Check if the bundle is empty.
  bool get isEmpty =>
      entities.isEmpty && events.isEmpty && views.isEmpty && claims.isEmpty;

  @override
  String toString() =>
      'ContextBundle(id: $id, entities: ${entities.length}, events: ${events.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ContextBundle && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Entity from context.
class ContextEntity {
  /// Entity ID.
  final String id;

  /// Entity type.
  final String type;

  /// Entity name.
  final String name;

  /// Entity attributes.
  final Map<String, dynamic> attributes;

  const ContextEntity({
    required this.id,
    required this.type,
    required this.name,
    this.attributes = const {},
  });

  factory ContextEntity.fromJson(Map<String, dynamic> json) {
    return ContextEntity(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      name: json['name'] as String? ?? '',
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        if (attributes.isNotEmpty) 'attributes': attributes,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ContextEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Event from context.
class ContextEvent {
  /// Event ID.
  final String id;

  /// Event type.
  final String type;

  /// Event timestamp.
  final DateTime timestamp;

  /// Event data.
  final Map<String, dynamic> data;

  const ContextEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.data = const {},
  });

  factory ContextEvent.fromJson(Map<String, dynamic> json) {
    return ContextEvent(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        if (data.isNotEmpty) 'data': data,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ContextEvent && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// View/summary from context.
class ContextView {
  /// View ID.
  final String id;

  /// View type.
  final String type;

  /// View content.
  final String content;

  /// Point-in-time snapshot.
  final DateTime asOf;

  const ContextView({
    required this.id,
    required this.type,
    required this.content,
    required this.asOf,
  });

  factory ContextView.fromJson(Map<String, dynamic> json) {
    return ContextView(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      content: json['content'] as String? ?? '',
      asOf: json['asOf'] != null
          ? DateTime.parse(json['asOf'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'content': content,
        'asOf': asOf.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ContextView && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Claim from context.
class ContextClaim {
  /// Claim ID.
  final String id;

  /// Claim text.
  final String text;

  /// Confidence score.
  final double confidence;

  /// Evidence references.
  final List<String> evidenceRefs;

  const ContextClaim({
    required this.id,
    required this.text,
    required this.confidence,
    this.evidenceRefs = const [],
  });

  factory ContextClaim.fromJson(Map<String, dynamic> json) {
    return ContextClaim(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      evidenceRefs:
          (json['evidenceRefs'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'confidence': confidence,
        if (evidenceRefs.isNotEmpty) 'evidenceRefs': evidenceRefs,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ContextClaim && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
