/// Agent section models for MCP Bundle.
///
/// Contains agent *definitions* — static descriptions of operational
/// entities that bind a role to four-axis knowledge assets (profiles,
/// skills, facts, philosophies) plus runtime configuration (model,
/// tools, behavior). The host runtime (e.g. FlowBrain) instantiates
/// these definitions into live agents; the bundle only carries the
/// definition.
library;

/// A section containing agent definitions.
class AgentsSection {
  /// Schema version for this section. Default `'1.0.0'`.
  final String schemaVersion;

  /// Agent definitions in this section.
  final List<AgentDefinition> agents;

  const AgentsSection({
    this.schemaVersion = '1.0.0',
    this.agents = const [],
  });

  /// Create from JSON.
  factory AgentsSection.fromJson(Map<String, dynamic> json) {
    return AgentsSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      agents: (json['agents'] as List<dynamic>?)
              ?.map((e) => AgentDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        if (agents.isNotEmpty)
          'agents': agents.map((a) => a.toJson()).toList(),
      };

  /// Whether this section is empty.
  bool get isEmpty => agents.isEmpty;

  /// Whether this section is not empty.
  bool get isNotEmpty => agents.isNotEmpty;

  /// Find agent by id.
  AgentDefinition? findById(String id) {
    for (final a in agents) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Create a copy with modifications.
  AgentsSection copyWith({
    String? schemaVersion,
    List<AgentDefinition>? agents,
  }) {
    return AgentsSection(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      agents: agents ?? this.agents,
    );
  }
}

/// A single agent definition. Composes 4-axis knowledge bindings with
/// runtime configuration. The bundle stores the definition only — the
/// host runtime is responsible for instantiating it (resolving the
/// referenced profile / skill / fact / philosophy ids and connecting
/// the model + tools).
class AgentDefinition {
  /// Unique identifier.
  final String id;

  /// Human-readable name.
  final String name;

  /// Role label (e.g. "UI Designer", "DSL Auditor").
  final String role;

  /// Optional description.
  final String? description;

  /// Profile ids this agent inherits.
  final List<String> profileIds;

  /// Skill ids this agent can perform.
  final List<String> skillIds;

  /// Fact source ids this agent can query.
  final List<String> factSourceIds;

  /// Philosophy ids this agent follows.
  final List<String> philosophyIds;

  /// Additional system prompt fragment appended after profile content.
  final String? systemPrompt;

  /// Model configuration (provider / model / sampling). Optional —
  /// host may apply defaults when omitted.
  final AgentModelConfig? model;

  /// Tool names this agent is permitted to invoke. `null` = host default.
  final List<String>? tools;

  /// Behavioral limits (turn cap / timeout / retry).
  final AgentBehaviorConfig? behavior;

  /// Free-form metadata for host-specific extension.
  final Map<String, dynamic> metadata;

  const AgentDefinition({
    required this.id,
    required this.name,
    required this.role,
    this.description,
    this.profileIds = const [],
    this.skillIds = const [],
    this.factSourceIds = const [],
    this.philosophyIds = const [],
    this.systemPrompt,
    this.model,
    this.tools,
    this.behavior,
    this.metadata = const {},
  });

  /// Create from JSON.
  factory AgentDefinition.fromJson(Map<String, dynamic> json) {
    return AgentDefinition(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      description: json['description'] as String?,
      profileIds: _stringList(json['profileIds']),
      skillIds: _stringList(json['skillIds']),
      factSourceIds: _stringList(json['factSourceIds']),
      philosophyIds: _stringList(json['philosophyIds']),
      systemPrompt: json['systemPrompt'] as String?,
      model: json['model'] != null
          ? AgentModelConfig.fromJson(json['model'] as Map<String, dynamic>)
          : null,
      tools: json['tools'] != null ? _stringList(json['tools']) : null,
      behavior: json['behavior'] != null
          ? AgentBehaviorConfig.fromJson(
              json['behavior'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        if (description != null) 'description': description,
        if (profileIds.isNotEmpty) 'profileIds': profileIds,
        if (skillIds.isNotEmpty) 'skillIds': skillIds,
        if (factSourceIds.isNotEmpty) 'factSourceIds': factSourceIds,
        if (philosophyIds.isNotEmpty) 'philosophyIds': philosophyIds,
        if (systemPrompt != null) 'systemPrompt': systemPrompt,
        if (model != null) 'model': model!.toJson(),
        if (tools != null) 'tools': tools,
        if (behavior != null) 'behavior': behavior!.toJson(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Create a copy with modifications.
  AgentDefinition copyWith({
    String? id,
    String? name,
    String? role,
    String? description,
    List<String>? profileIds,
    List<String>? skillIds,
    List<String>? factSourceIds,
    List<String>? philosophyIds,
    String? systemPrompt,
    AgentModelConfig? model,
    List<String>? tools,
    AgentBehaviorConfig? behavior,
    Map<String, dynamic>? metadata,
  }) {
    return AgentDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      description: description ?? this.description,
      profileIds: profileIds ?? this.profileIds,
      skillIds: skillIds ?? this.skillIds,
      factSourceIds: factSourceIds ?? this.factSourceIds,
      philosophyIds: philosophyIds ?? this.philosophyIds,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      model: model ?? this.model,
      tools: tools ?? this.tools,
      behavior: behavior ?? this.behavior,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Model configuration for an agent.
class AgentModelConfig {
  /// Provider id (e.g. "anthropic", "openai", "gemini").
  final String? provider;

  /// Model id (e.g. "claude-opus-4-7", "gpt-4o").
  final String? model;

  /// Sampling temperature (0.0-2.0). `null` = provider default.
  final double? temperature;

  /// Top-p nucleus sampling. `null` = provider default.
  final double? topP;

  /// Maximum output tokens. `null` = provider default.
  final int? maxTokens;

  /// Free-form provider-specific options.
  final Map<String, dynamic> options;

  const AgentModelConfig({
    this.provider,
    this.model,
    this.temperature,
    this.topP,
    this.maxTokens,
    this.options = const {},
  });

  factory AgentModelConfig.fromJson(Map<String, dynamic> json) {
    return AgentModelConfig(
      provider: json['provider'] as String?,
      model: json['model'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      topP: (json['topP'] as num?)?.toDouble(),
      maxTokens: json['maxTokens'] as int?,
      options: json['options'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        if (provider != null) 'provider': provider,
        if (model != null) 'model': model,
        if (temperature != null) 'temperature': temperature,
        if (topP != null) 'topP': topP,
        if (maxTokens != null) 'maxTokens': maxTokens,
        if (options.isNotEmpty) 'options': options,
      };

  AgentModelConfig copyWith({
    String? provider,
    String? model,
    double? temperature,
    double? topP,
    int? maxTokens,
    Map<String, dynamic>? options,
  }) {
    return AgentModelConfig(
      provider: provider ?? this.provider,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      maxTokens: maxTokens ?? this.maxTokens,
      options: options ?? this.options,
    );
  }
}

/// Behavioral limits for an agent's runtime loop.
class AgentBehaviorConfig {
  /// Maximum turns in a single conversation. `null` = host default.
  final int? turnLimit;

  /// Per-turn timeout in milliseconds. `null` = host default.
  final int? timeoutMs;

  /// Retry count on transient failures. `null` = host default.
  final int? maxRetries;

  /// Whether to allow parallel tool calls in a single turn.
  final bool? parallelTools;

  /// Free-form host-specific options.
  final Map<String, dynamic> options;

  const AgentBehaviorConfig({
    this.turnLimit,
    this.timeoutMs,
    this.maxRetries,
    this.parallelTools,
    this.options = const {},
  });

  factory AgentBehaviorConfig.fromJson(Map<String, dynamic> json) {
    return AgentBehaviorConfig(
      turnLimit: json['turnLimit'] as int?,
      timeoutMs: json['timeoutMs'] as int?,
      maxRetries: json['maxRetries'] as int?,
      parallelTools: json['parallelTools'] as bool?,
      options: json['options'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        if (turnLimit != null) 'turnLimit': turnLimit,
        if (timeoutMs != null) 'timeoutMs': timeoutMs,
        if (maxRetries != null) 'maxRetries': maxRetries,
        if (parallelTools != null) 'parallelTools': parallelTools,
        if (options.isNotEmpty) 'options': options,
      };

  AgentBehaviorConfig copyWith({
    int? turnLimit,
    int? timeoutMs,
    int? maxRetries,
    bool? parallelTools,
    Map<String, dynamic>? options,
  }) {
    return AgentBehaviorConfig(
      turnLimit: turnLimit ?? this.turnLimit,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      maxRetries: maxRetries ?? this.maxRetries,
      parallelTools: parallelTools ?? this.parallelTools,
      options: options ?? this.options,
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return const [];
}
