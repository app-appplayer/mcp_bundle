/// Tools section models for MCP Bundle.
///
/// Carries inline tool declarations under `manifest.json` `tools[]`. Each
/// [ToolEntry] is a host-callable unit — Studio / AppPlayer consult this
/// section to discover what tools a bundle exposes and how to dispatch
/// them. Distinct from `SkillSection` (skill module + procedure graph)
/// and `AgentsSection` (4-axis bindings): tools are leaf invocables
/// (host builtin / MCP server / cloud endpoint / bundled JS).
library;

/// A section containing tool entries.
class ToolsSection {
  /// Schema version for tools section.
  final String schemaVersion;

  /// Tool entries in this section.
  final List<ToolEntry> tools;

  const ToolsSection({
    this.schemaVersion = '1.0.0',
    this.tools = const [],
  });

  /// Create from JSON.
  factory ToolsSection.fromJson(Map<String, dynamic> json) {
    return ToolsSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      tools: (json['tools'] as List<dynamic>?)
              ?.map((e) => ToolEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        if (tools.isNotEmpty) 'tools': tools.map((t) => t.toJson()).toList(),
      };

  /// Whether this section is empty.
  bool get isEmpty => tools.isEmpty;

  /// Whether this section is not empty.
  bool get isNotEmpty => tools.isNotEmpty;

  /// Find tool by id (matches against [ToolEntry.id]). Returns `null`
  /// when no entry has the given id (entries without ids are skipped).
  ToolEntry? findById(String id) {
    for (final t in tools) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Find tool by name.
  ToolEntry? findByName(String name) {
    for (final t in tools) {
      if (t.name == name) return t;
    }
    return null;
  }

  /// Create a copy with modifications.
  ToolsSection copyWith({
    String? schemaVersion,
    List<ToolEntry>? tools,
  }) {
    return ToolsSection(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      tools: tools ?? this.tools,
    );
  }
}

/// Discriminator for how a [ToolEntry] is dispatched.
///
/// - [host] — host-builtin tool (e.g. `studio.*`). `target` is an empty
///   map.
/// - [mcp] — external MCP server. `target` carries
///   `{transport: 'http'|'stdio', url?, command?, args?}`.
/// - [cloud] — external HTTPS endpoint. `target` carries `{url}`.
/// - [js] — JavaScript shipped inside the bundle. `target` carries
///   `{entry, fn}` (entry = file path under bundle, fn = function name).
/// - [ts] — compiled real-code tool (TypeScript source shipped inside the
///   bundle; `target` carries `{entry, fn}` like [js]). Executed SERVER-side
///   by a serving runtime built from the bundle (a `BundleType.server`
///   bundle) — hosts have no executor for it and treat the entry as a
///   declaration (spec 08 §5).
/// - [unknown] — kind value not recognized at parse time. Hosts may
///   choose to surface or skip; validator flags unknown kinds.
enum ToolKind {
  host,
  mcp,
  cloud,
  js,
  ts,
  unknown;

  /// Parse a string to [ToolKind], returning [ToolKind.unknown] when
  /// the value does not match any known kind. Case-insensitive.
  static ToolKind fromString(String? value) {
    if (value == null) return ToolKind.unknown;
    switch (value.toLowerCase()) {
      case 'host':
        return ToolKind.host;
      case 'mcp':
        return ToolKind.mcp;
      case 'cloud':
        return ToolKind.cloud;
      case 'js':
        return ToolKind.js;
      case 'ts':
        return ToolKind.ts;
      default:
        return ToolKind.unknown;
    }
  }

  /// Wire string for this kind. [ToolKind.unknown] round-trips as
  /// `'unknown'`.
  String get wireValue {
    switch (this) {
      case ToolKind.host:
        return 'host';
      case ToolKind.mcp:
        return 'mcp';
      case ToolKind.cloud:
        return 'cloud';
      case ToolKind.js:
        return 'js';
      case ToolKind.ts:
        return 'ts';
      case ToolKind.unknown:
        return 'unknown';
    }
  }
}

/// A single tool declaration.
///
/// The [target] map is kind-discriminated free-form so hosts can carry
/// the dispatch payload uniformly. The validator does not enforce the
/// kind-specific shape (lenient policy at 0.3.3) — only `name` (required,
/// non-empty), unique `name` within the section, and `kind` not
/// [ToolKind.unknown] are checked.
class ToolEntry {
  /// Optional identifier (e.g. for cross-reference). Distinct from
  /// [name] which is the dispatch handle.
  final String? id;

  /// Tool name — the handle a host uses to invoke this tool. Required.
  final String name;

  /// Optional human-readable description.
  final String? description;

  /// How this tool is dispatched. Defaults to [ToolKind.host].
  final ToolKind kind;

  /// Kind-discriminated dispatch payload. Shape depends on [kind]:
  ///
  /// - [ToolKind.host]: empty `{}` — the host already knows how to
  ///   dispatch builtin tools (e.g. `studio.*`).
  /// - [ToolKind.mcp]: `{transport: 'http'|'stdio', url?, command?,
  ///   args?}` — outbound MCP server connection params.
  /// - [ToolKind.cloud]: `{url}` — HTTPS endpoint.
  /// - [ToolKind.js]: `{entry, fn}` — `entry` is a path under the
  ///   bundle (e.g. `tools/foo.js`), `fn` is the exported function name.
  ///
  /// Validator does not enforce shape — hosts get the map as-is.
  final Map<String, dynamic> target;

  /// Optional JSON schema describing the tool's input. Free-form Map so
  /// callers can adopt JSON Schema, MCP `inputSchema`, or any other
  /// dialect. `null` = no declared schema.
  final Map<String, dynamic>? inputSchema;

  /// Optional JSON schema describing the tool's output. Free-form Map —
  /// same dialect-agnostic policy as [inputSchema]. When present, hosts
  /// MAY use this to validate tool responses or to drive
  /// `mergeState`-style auto-merge integrity checks (see
  /// `mcp_ui_dsl/spec/1.3` §3.10 auto-merge). `null` = no declared
  /// schema.
  final Map<String, dynamic>? outputSchema;

  /// Optional scope tag list — e.g. agent ids / role names that may
  /// invoke this tool. `null` = unscoped (host-default access).
  final List<String>? agentScope;

  /// Free-form metadata for host-specific extension.
  final Map<String, dynamic> metadata;

  const ToolEntry({
    this.id,
    required this.name,
    this.description,
    this.kind = ToolKind.host,
    this.target = const {},
    this.inputSchema,
    this.outputSchema,
    this.agentScope,
    this.metadata = const {},
  });

  /// Create from JSON.
  factory ToolEntry.fromJson(Map<String, dynamic> json) {
    return ToolEntry(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      kind: ToolKind.fromString(json['kind'] as String?),
      target: (json['target'] as Map?)?.cast<String, dynamic>() ?? const {},
      inputSchema: (json['inputSchema'] as Map?)?.cast<String, dynamic>(),
      outputSchema: (json['outputSchema'] as Map?)?.cast<String, dynamic>(),
      agentScope: (json['agentScope'] as List?)?.cast<String>(),
      metadata:
          (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        if (description != null) 'description': description,
        'kind': kind.wireValue,
        if (target.isNotEmpty) 'target': target,
        if (inputSchema != null) 'inputSchema': inputSchema,
        if (outputSchema != null) 'outputSchema': outputSchema,
        if (agentScope != null) 'agentScope': agentScope,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Create a copy with modifications.
  ToolEntry copyWith({
    String? id,
    String? name,
    String? description,
    ToolKind? kind,
    Map<String, dynamic>? target,
    Map<String, dynamic>? inputSchema,
    Map<String, dynamic>? outputSchema,
    List<String>? agentScope,
    Map<String, dynamic>? metadata,
  }) {
    return ToolEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      kind: kind ?? this.kind,
      target: target ?? this.target,
      inputSchema: inputSchema ?? this.inputSchema,
      outputSchema: outputSchema ?? this.outputSchema,
      agentScope: agentScope ?? this.agentScope,
      metadata: metadata ?? this.metadata,
    );
  }
}
