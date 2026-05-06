/// Philosophy section models for MCP Bundle.
///
/// Contains philosophy / ethos definitions — guiding principles paired
/// with applied examples and counter-examples. Distinct from
/// [PolicySection] (decision rules) — Philosophy captures *why* and
/// *what to learn from*, Policy captures *what to enforce*.
library;

/// A section containing philosophy definitions.
class PhilosophySection {
  /// Philosophies defined in this section.
  final List<Philosophy> philosophies;

  const PhilosophySection({
    this.philosophies = const [],
  });

  /// Create from JSON.
  factory PhilosophySection.fromJson(Map<String, dynamic> json) {
    return PhilosophySection(
      philosophies: (json['philosophies'] as List<dynamic>?)
              ?.map((e) => Philosophy.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        if (philosophies.isNotEmpty)
          'philosophies': philosophies.map((p) => p.toJson()).toList(),
      };

  /// Whether this section is empty.
  bool get isEmpty => philosophies.isEmpty;

  /// Whether this section is not empty.
  bool get isNotEmpty => philosophies.isNotEmpty;

  /// Find philosophy by id.
  Philosophy? findById(String id) {
    for (final p in philosophies) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Create a copy with modifications.
  PhilosophySection copyWith({
    List<Philosophy>? philosophies,
  }) {
    return PhilosophySection(
      philosophies: philosophies ?? this.philosophies,
    );
  }
}

/// A single philosophy — guiding principle with examples.
class Philosophy {
  /// Unique identifier.
  final String id;

  /// Short human-readable name.
  final String name;

  /// The principle itself, expressed in one or two sentences.
  final String statement;

  /// Why this principle exists. Optional — kept lightweight.
  final String? rationale;

  /// Applied examples illustrating the principle in action.
  final List<PhilosophyExample> examples;

  /// Counter-examples — situations the principle warns against.
  final List<PhilosophyExample> counterexamples;

  /// Optional school / category label (e.g. "engineering", "design").
  final String? school;

  /// Confidence in the principle (0.0-1.0). Optional — defaults unset.
  final double? confidence;

  /// Free-form metadata for host-specific extension.
  final Map<String, dynamic> metadata;

  const Philosophy({
    required this.id,
    required this.name,
    required this.statement,
    this.rationale,
    this.examples = const [],
    this.counterexamples = const [],
    this.school,
    this.confidence,
    this.metadata = const {},
  });

  /// Create from JSON.
  factory Philosophy.fromJson(Map<String, dynamic> json) {
    return Philosophy(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      statement: json['statement'] as String? ?? '',
      rationale: json['rationale'] as String?,
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) =>
                  PhilosophyExample.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      counterexamples: (json['counterexamples'] as List<dynamic>?)
              ?.map((e) =>
                  PhilosophyExample.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      school: json['school'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'statement': statement,
        if (rationale != null) 'rationale': rationale,
        if (examples.isNotEmpty)
          'examples': examples.map((e) => e.toJson()).toList(),
        if (counterexamples.isNotEmpty)
          'counterexamples':
              counterexamples.map((e) => e.toJson()).toList(),
        if (school != null) 'school': school,
        if (confidence != null) 'confidence': confidence,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Create a copy with modifications.
  Philosophy copyWith({
    String? id,
    String? name,
    String? statement,
    String? rationale,
    List<PhilosophyExample>? examples,
    List<PhilosophyExample>? counterexamples,
    String? school,
    double? confidence,
    Map<String, dynamic>? metadata,
  }) {
    return Philosophy(
      id: id ?? this.id,
      name: name ?? this.name,
      statement: statement ?? this.statement,
      rationale: rationale ?? this.rationale,
      examples: examples ?? this.examples,
      counterexamples: counterexamples ?? this.counterexamples,
      school: school ?? this.school,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// A single example or counter-example illustrating a philosophy.
class PhilosophyExample {
  /// Description of the example.
  final String description;

  /// Optional context — when / where the example applies.
  final String? context;

  /// Optional source pointer (file path, URL, citation).
  final String? source;

  const PhilosophyExample({
    required this.description,
    this.context,
    this.source,
  });

  /// Create from JSON.
  factory PhilosophyExample.fromJson(Map<String, dynamic> json) {
    return PhilosophyExample(
      description: json['description'] as String? ?? '',
      context: json['context'] as String?,
      source: json['source'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'description': description,
        if (context != null) 'context': context,
        if (source != null) 'source': source,
      };

  /// Create a copy with modifications.
  PhilosophyExample copyWith({
    String? description,
    String? context,
    String? source,
  }) {
    return PhilosophyExample(
      description: description ?? this.description,
      context: context ?? this.context,
      source: source ?? this.source,
    );
  }
}
