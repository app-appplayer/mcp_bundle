/// Pipelines section models for MCP Bundle.
///
/// Contains pipeline definitions — ordered stage sequences for data /
/// build / deploy flows. Stage shape is free-form for now (typed stage
/// schema will align with `mcp_knowledge_ops` in a future round).
library;

/// A section containing pipeline definitions.
class PipelinesSection {
  /// Schema version for pipelines section.
  final String schemaVersion;

  /// Pipeline definitions in this section.
  final List<PipelineEntry> pipelines;

  const PipelinesSection({
    this.schemaVersion = '1.0.0',
    this.pipelines = const [],
  });

  /// Create from JSON.
  factory PipelinesSection.fromJson(Map<String, dynamic> json) {
    return PipelinesSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      pipelines: (json['pipelines'] as List<dynamic>?)
              ?.map((e) => PipelineEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        if (pipelines.isNotEmpty)
          'pipelines': pipelines.map((p) => p.toJson()).toList(),
      };

  /// Whether this section has no pipelines.
  bool get isEmpty => pipelines.isEmpty;

  /// Whether this section has at least one pipeline.
  bool get isNotEmpty => pipelines.isNotEmpty;

  /// Find pipeline by id.
  PipelineEntry? findById(String id) {
    for (final p in pipelines) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Create a copy with modifications.
  PipelinesSection copyWith({
    String? schemaVersion,
    List<PipelineEntry>? pipelines,
  }) {
    return PipelinesSection(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      pipelines: pipelines ?? this.pipelines,
    );
  }
}

/// A single pipeline definition.
class PipelineEntry {
  /// Unique identifier.
  final String id;

  /// Human-readable name.
  final String name;

  /// Semantic version of this pipeline.
  final String version;

  /// Optional description.
  final String? description;

  /// Ordered stages. Free-form maps for now — typed stage schema will be
  /// introduced once the host runtime contract stabilizes.
  final List<Map<String, dynamic>> stages;

  /// Free-form metadata for host-specific extension.
  final Map<String, dynamic> metadata;

  const PipelineEntry({
    required this.id,
    required this.name,
    this.version = '1.0.0',
    this.description,
    this.stages = const [],
    this.metadata = const {},
  });

  /// Create from JSON.
  factory PipelineEntry.fromJson(Map<String, dynamic> json) {
    return PipelineEntry(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      description: json['description'] as String?,
      stages: (json['stages'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        if (description != null) 'description': description,
        if (stages.isNotEmpty) 'stages': stages,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Create a copy with modifications.
  PipelineEntry copyWith({
    String? id,
    String? name,
    String? version,
    String? description,
    List<Map<String, dynamic>>? stages,
    Map<String, dynamic>? metadata,
  }) {
    return PipelineEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
      stages: stages ?? this.stages,
      metadata: metadata ?? this.metadata,
    );
  }
}
