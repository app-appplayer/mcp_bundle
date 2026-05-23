/// Facts section models for MCP Bundle.
///
/// Contains atomic factual statements as subject-predicate-object triples
/// with optional confidence + source provenance. Distinct from
/// [KnowledgeSection] (RAG sources) — Facts are typed assertions; Knowledge
/// is retrievable document content.
library;

/// A section containing fact triples.
class FactsSection {
  /// Schema version for facts section.
  final String schemaVersion;

  /// Fact triples in this section.
  final List<Fact> facts;

  const FactsSection({
    this.schemaVersion = '1.0.0',
    this.facts = const [],
  });

  /// Create from JSON.
  factory FactsSection.fromJson(Map<String, dynamic> json) {
    return FactsSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      facts: (json['facts'] as List<dynamic>?)
              ?.map((e) => Fact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        if (facts.isNotEmpty) 'facts': facts.map((f) => f.toJson()).toList(),
      };

  /// Whether this section has no facts.
  bool get isEmpty => facts.isEmpty;

  /// Whether this section has at least one fact.
  bool get isNotEmpty => facts.isNotEmpty;

  /// Find fact by id.
  Fact? findById(String id) {
    for (final f in facts) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Create a copy with modifications.
  FactsSection copyWith({
    String? schemaVersion,
    List<Fact>? facts,
  }) {
    return FactsSection(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      facts: facts ?? this.facts,
    );
  }
}

/// A single atomic fact — subject / predicate / object triple with
/// optional confidence and source provenance.
class Fact {
  /// Optional identifier (e.g. for cross-reference).
  final String? id;

  /// Subject of the fact (entity / topic).
  final String subject;

  /// Predicate (relation / property).
  final String predicate;

  /// Object — may be a string, number, bool, Map, or List. Free-form so
  /// hosts can encode scalar / structured values uniformly.
  final dynamic object;

  /// Confidence in the fact (0.0-1.0). Optional — `null` = unknown.
  final double? confidence;

  /// Optional source pointer (knowledge source id, citation, URL).
  final String? source;

  /// Free-form metadata for host-specific extension.
  final Map<String, dynamic> metadata;

  const Fact({
    this.id,
    required this.subject,
    required this.predicate,
    required this.object,
    this.confidence,
    this.source,
    this.metadata = const {},
  });

  /// Factory that clamps [confidence] into the 0.0-1.0 range.
  factory Fact.clamped({
    String? id,
    required String subject,
    required String predicate,
    required dynamic object,
    double? confidence,
    String? source,
    Map<String, dynamic> metadata = const {},
  }) {
    return Fact(
      id: id,
      subject: subject,
      predicate: predicate,
      object: object,
      confidence: _clampConfidence(confidence),
      source: source,
      metadata: metadata,
    );
  }

  /// Create from JSON. `confidence` is clamped to 0.0-1.0 when present.
  factory Fact.fromJson(Map<String, dynamic> json) {
    return Fact(
      id: json['id'] as String?,
      subject: json['subject'] as String? ?? '',
      predicate: json['predicate'] as String? ?? '',
      object: json['object'],
      confidence: _clampConfidence((json['confidence'] as num?)?.toDouble()),
      source: json['source'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'subject': subject,
        'predicate': predicate,
        'object': object,
        if (confidence != null) 'confidence': confidence,
        if (source != null) 'source': source,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Create a copy with modifications.
  Fact copyWith({
    String? id,
    String? subject,
    String? predicate,
    dynamic object,
    double? confidence,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    return Fact(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      predicate: predicate ?? this.predicate,
      object: object ?? this.object,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }

  static double? _clampConfidence(double? value) {
    if (value == null) return null;
    if (value < 0.0) return 0.0;
    if (value > 1.0) return 1.0;
    return value;
  }
}
