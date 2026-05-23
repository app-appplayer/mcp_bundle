/// Runbooks section models for MCP Bundle.
///
/// Contains runbook definitions — ordered procedure sequences for
/// operational tasks (incident response, recovery, routine maintenance).
/// Procedure shape is free-form for now (typed procedure schema will
/// align with `mcp_knowledge_ops` in a future round).
library;

/// A section containing runbook definitions.
class RunbooksSection {
  /// Schema version for runbooks section.
  final String schemaVersion;

  /// Runbook definitions in this section.
  final List<RunbookEntry> runbooks;

  const RunbooksSection({
    this.schemaVersion = '1.0.0',
    this.runbooks = const [],
  });

  /// Create from JSON.
  factory RunbooksSection.fromJson(Map<String, dynamic> json) {
    return RunbooksSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      runbooks: (json['runbooks'] as List<dynamic>?)
              ?.map((e) => RunbookEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        if (runbooks.isNotEmpty)
          'runbooks': runbooks.map((r) => r.toJson()).toList(),
      };

  /// Whether this section has no runbooks.
  bool get isEmpty => runbooks.isEmpty;

  /// Whether this section has at least one runbook.
  bool get isNotEmpty => runbooks.isNotEmpty;

  /// Find runbook by id.
  RunbookEntry? findById(String id) {
    for (final r in runbooks) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Create a copy with modifications.
  RunbooksSection copyWith({
    String? schemaVersion,
    List<RunbookEntry>? runbooks,
  }) {
    return RunbooksSection(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      runbooks: runbooks ?? this.runbooks,
    );
  }
}

/// A single runbook definition.
class RunbookEntry {
  /// Unique identifier.
  final String id;

  /// Human-readable name.
  final String name;

  /// Semantic version of this runbook.
  final String version;

  /// Optional description.
  final String? description;

  /// Ordered procedure entries. Free-form maps for now — typed procedure
  /// schema will be introduced once the host runtime contract stabilizes.
  final List<Map<String, dynamic>> procedure;

  /// Free-form metadata for host-specific extension.
  final Map<String, dynamic> metadata;

  const RunbookEntry({
    required this.id,
    required this.name,
    this.version = '1.0.0',
    this.description,
    this.procedure = const [],
    this.metadata = const {},
  });

  /// Create from JSON.
  factory RunbookEntry.fromJson(Map<String, dynamic> json) {
    return RunbookEntry(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      description: json['description'] as String?,
      procedure: (json['procedure'] as List<dynamic>?)
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
        if (procedure.isNotEmpty) 'procedure': procedure,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Create a copy with modifications.
  RunbookEntry copyWith({
    String? id,
    String? name,
    String? version,
    String? description,
    List<Map<String, dynamic>>? procedure,
    Map<String, dynamic>? metadata,
  }) {
    return RunbookEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
      procedure: procedure ?? this.procedure,
      metadata: metadata ?? this.metadata,
    );
  }
}
