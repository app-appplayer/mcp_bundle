/// Workflows section models for MCP Bundle.
///
/// Contains workflow definitions — ordered step sequences describing how
/// to accomplish a task. Step shape is free-form for now (a typed step
/// schema will align with `mcp_knowledge_ops` in a future round).
library;

/// A section containing workflow definitions.
class WorkflowsSection {
  /// Schema version for workflows section.
  final String schemaVersion;

  /// Workflow definitions in this section.
  final List<WorkflowEntry> workflows;

  const WorkflowsSection({
    this.schemaVersion = '1.0.0',
    this.workflows = const [],
  });

  /// Create from JSON.
  factory WorkflowsSection.fromJson(Map<String, dynamic> json) {
    return WorkflowsSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      workflows: (json['workflows'] as List<dynamic>?)
              ?.map((e) => WorkflowEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        if (workflows.isNotEmpty)
          'workflows': workflows.map((w) => w.toJson()).toList(),
      };

  /// Whether this section has no workflows.
  bool get isEmpty => workflows.isEmpty;

  /// Whether this section has at least one workflow.
  bool get isNotEmpty => workflows.isNotEmpty;

  /// Find workflow by id.
  WorkflowEntry? findById(String id) {
    for (final w in workflows) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// Create a copy with modifications.
  WorkflowsSection copyWith({
    String? schemaVersion,
    List<WorkflowEntry>? workflows,
  }) {
    return WorkflowsSection(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      workflows: workflows ?? this.workflows,
    );
  }
}

/// A single workflow definition.
class WorkflowEntry {
  /// Unique identifier.
  final String id;

  /// Human-readable name.
  final String name;

  /// Semantic version of this workflow.
  final String version;

  /// Optional description.
  final String? description;

  /// Ordered steps. Free-form maps for now — typed step schema will be
  /// introduced once the host runtime contract stabilizes.
  final List<Map<String, dynamic>> steps;

  /// Free-form metadata for host-specific extension.
  final Map<String, dynamic> metadata;

  const WorkflowEntry({
    required this.id,
    required this.name,
    this.version = '1.0.0',
    this.description,
    this.steps = const [],
    this.metadata = const {},
  });

  /// Create from JSON.
  factory WorkflowEntry.fromJson(Map<String, dynamic> json) {
    return WorkflowEntry(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      description: json['description'] as String?,
      steps: (json['steps'] as List<dynamic>?)
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
        if (steps.isNotEmpty) 'steps': steps,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Create a copy with modifications.
  WorkflowEntry copyWith({
    String? id,
    String? name,
    String? version,
    String? description,
    List<Map<String, dynamic>>? steps,
    Map<String, dynamic>? metadata,
  }) {
    return WorkflowEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      metadata: metadata ?? this.metadata,
    );
  }
}
