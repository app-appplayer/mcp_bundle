/// Skill Section model for MCP Bundle.
///
/// Contains skill module definitions.
library;

/// Skill section containing skill modules.
class SkillSection {
  /// Schema version for skill section.
  final String schemaVersion;

  /// List of skill modules.
  final List<SkillModule> modules;

  /// Shared skill configuration.
  final SkillConfig? config;

  const SkillSection({
    this.schemaVersion = '1.0.0',
    this.modules = const [],
    this.config,
  });

  factory SkillSection.fromJson(Map<String, dynamic> json) {
    return SkillSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      modules: (json['modules'] as List<dynamic>?)
              ?.map((e) => SkillModule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      config: json['config'] != null
          ? SkillConfig.fromJson(json['config'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      if (modules.isNotEmpty)
        'modules': modules.map((m) => m.toJson()).toList(),
      if (config != null) 'config': config!.toJson(),
    };
  }
}

/// Skill module definition.
class SkillModule {
  /// Skill identifier.
  final String id;

  /// Skill name.
  final String name;

  /// Skill version.
  final String version;

  /// Skill description.
  final String? description;

  /// Provider/author.
  final String? provider;

  /// Input parameters.
  final List<SkillParameter> inputs;

  /// Output definition.
  final SkillOutput? output;

  /// Skill procedures.
  final List<SkillProcedure> procedures;

  /// Skill triggers.
  final List<SkillTrigger> triggers;

  /// Required capabilities.
  final List<String> capabilities;

  /// MCP tools required.
  final List<McpToolRef> mcpTools;

  /// Knowledge sources.
  final List<KnowledgeSourceRef> knowledgeSources;

  /// Rubric for evaluation.
  final SkillRubric? rubric;

  const SkillModule({
    required this.id,
    required this.name,
    this.version = '1.0.0',
    this.description,
    this.provider,
    this.inputs = const [],
    this.output,
    this.procedures = const [],
    this.triggers = const [],
    this.capabilities = const [],
    this.mcpTools = const [],
    this.knowledgeSources = const [],
    this.rubric,
  });

  factory SkillModule.fromJson(Map<String, dynamic> json) {
    return SkillModule(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      description: json['description'] as String?,
      provider: json['provider'] as String?,
      inputs: (json['inputs'] as List<dynamic>?)
              ?.map((e) => SkillParameter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      output: json['output'] != null
          ? SkillOutput.fromJson(json['output'] as Map<String, dynamic>)
          : null,
      procedures: (json['procedures'] as List<dynamic>?)
              ?.map((e) => SkillProcedure.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      triggers: (json['triggers'] as List<dynamic>?)
              ?.map((e) => SkillTrigger.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      mcpTools: (json['mcpTools'] as List<dynamic>?)
              ?.map((e) => McpToolRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      knowledgeSources: (json['knowledgeSources'] as List<dynamic>?)
              ?.map(
                  (e) => KnowledgeSourceRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      rubric: json['rubric'] != null
          ? SkillRubric.fromJson(json['rubric'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      if (description != null) 'description': description,
      if (provider != null) 'provider': provider,
      if (inputs.isNotEmpty) 'inputs': inputs.map((i) => i.toJson()).toList(),
      if (output != null) 'output': output!.toJson(),
      if (procedures.isNotEmpty)
        'procedures': procedures.map((p) => p.toJson()).toList(),
      if (triggers.isNotEmpty)
        'triggers': triggers.map((t) => t.toJson()).toList(),
      if (capabilities.isNotEmpty) 'capabilities': capabilities,
      if (mcpTools.isNotEmpty)
        'mcpTools': mcpTools.map((m) => m.toJson()).toList(),
      if (knowledgeSources.isNotEmpty)
        'knowledgeSources': knowledgeSources.map((k) => k.toJson()).toList(),
      if (rubric != null) 'rubric': rubric!.toJson(),
    };
  }
}

/// Skill parameter definition.
class SkillParameter {
  /// Parameter name.
  final String name;

  /// Parameter type.
  final String type;

  /// Whether required.
  final bool required;

  /// Default value.
  final dynamic defaultValue;

  /// Description.
  final String? description;

  /// Validation constraints.
  final Map<String, dynamic>? constraints;

  const SkillParameter({
    required this.name,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.description,
    this.constraints,
  });

  factory SkillParameter.fromJson(Map<String, dynamic> json) {
    return SkillParameter(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'string',
      required: json['required'] as bool? ?? false,
      defaultValue: json['default'],
      description: json['description'] as String?,
      constraints: json['constraints'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      if (required) 'required': required,
      if (defaultValue != null) 'default': defaultValue,
      if (description != null) 'description': description,
      if (constraints != null) 'constraints': constraints,
    };
  }
}

/// Skill output definition.
class SkillOutput {
  /// Output type.
  final String type;

  /// Output schema.
  final Map<String, dynamic>? schema;

  /// Description.
  final String? description;

  /// Claims to produce.
  final List<ClaimDef>? claims;

  const SkillOutput({
    required this.type,
    this.schema,
    this.description,
    this.claims,
  });

  factory SkillOutput.fromJson(Map<String, dynamic> json) {
    return SkillOutput(
      type: json['type'] as String? ?? 'any',
      schema: json['schema'] as Map<String, dynamic>?,
      description: json['description'] as String?,
      claims: (json['claims'] as List<dynamic>?)
          ?.map((e) => ClaimDef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (schema != null) 'schema': schema,
      if (description != null) 'description': description,
      if (claims != null) 'claims': claims!.map((c) => c.toJson()).toList(),
    };
  }
}

/// Claim definition.
class ClaimDef {
  /// Claim type.
  final String type;

  /// Claim template.
  final String? template;

  /// Confidence level.
  final String? confidence;

  const ClaimDef({
    required this.type,
    this.template,
    this.confidence,
  });

  factory ClaimDef.fromJson(Map<String, dynamic> json) {
    return ClaimDef(
      type: json['type'] as String? ?? '',
      template: json['template'] as String?,
      confidence: json['confidence'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (template != null) 'template': template,
      if (confidence != null) 'confidence': confidence,
    };
  }
}

/// Skill procedure definition.
class SkillProcedure {
  /// Procedure identifier.
  final String id;

  /// Procedure name.
  final String name;

  /// Procedure description.
  final String? description;

  /// Procedure steps.
  final List<ProcedureStep> steps;

  /// Entry point step.
  final String? entryPoint;

  const SkillProcedure({
    required this.id,
    required this.name,
    this.description,
    this.steps = const [],
    this.entryPoint,
  });

  factory SkillProcedure.fromJson(Map<String, dynamic> json) {
    return SkillProcedure(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => ProcedureStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      entryPoint: json['entryPoint'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (steps.isNotEmpty) 'steps': steps.map((s) => s.toJson()).toList(),
      if (entryPoint != null) 'entryPoint': entryPoint,
    };
  }
}

/// Procedure step.
class ProcedureStep {
  /// Step identifier.
  final String id;

  /// Step action.
  final StepAction action;

  /// Condition expression.
  final String? condition;

  /// Next step(s).
  final List<String> next;

  /// Error handler.
  final String? onError;

  const ProcedureStep({
    required this.id,
    required this.action,
    this.condition,
    this.next = const [],
    this.onError,
  });

  factory ProcedureStep.fromJson(Map<String, dynamic> json) {
    return ProcedureStep(
      id: json['id'] as String? ?? '',
      action: StepAction.fromJson(json['action'] as Map<String, dynamic>? ?? {}),
      condition: json['condition'] as String?,
      next: (json['next'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      onError: json['onError'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action.toJson(),
      if (condition != null) 'condition': condition,
      if (next.isNotEmpty) 'next': next,
      if (onError != null) 'onError': onError,
    };
  }
}

/// Step action definition.
class StepAction {
  /// Action type.
  final StepActionType type;

  /// Action configuration.
  final Map<String, dynamic> config;

  const StepAction({
    required this.type,
    this.config = const {},
  });

  factory StepAction.fromJson(Map<String, dynamic> json) {
    return StepAction(
      type: StepActionType.fromString(json['type'] as String? ?? 'prompt'),
      config: Map<String, dynamic>.from(json)..remove('type'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      ...config,
    };
  }
}

/// Step action types.
enum StepActionType {
  prompt,
  tool,
  retrieve,
  validate,
  transform,
  branch,
  loop,
  output,
  unknown;

  static StepActionType fromString(String value) {
    return StepActionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StepActionType.unknown,
    );
  }
}

/// Skill trigger definition.
class SkillTrigger {
  /// Trigger type.
  final SkillTriggerType type;

  /// Trigger pattern (for intent/pattern triggers).
  final String? pattern;

  /// Trigger configuration.
  final Map<String, dynamic> config;

  const SkillTrigger({
    required this.type,
    this.pattern,
    this.config = const {},
  });

  factory SkillTrigger.fromJson(Map<String, dynamic> json) {
    return SkillTrigger(
      type: SkillTriggerType.fromString(json['type'] as String? ?? 'explicit'),
      pattern: json['pattern'] as String?,
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (pattern != null) 'pattern': pattern,
      if (config.isNotEmpty) 'config': config,
    };
  }
}

/// Skill trigger types.
enum SkillTriggerType {
  explicit,
  intent,
  pattern,
  event,
  unknown;

  static SkillTriggerType fromString(String value) {
    return SkillTriggerType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SkillTriggerType.unknown,
    );
  }
}

/// MCP tool reference.
class McpToolRef {
  /// Server ID.
  final String serverId;

  /// Tool name.
  final String toolName;

  /// Required/optional.
  final bool required;

  const McpToolRef({
    required this.serverId,
    required this.toolName,
    this.required = true,
  });

  factory McpToolRef.fromJson(Map<String, dynamic> json) {
    return McpToolRef(
      serverId: json['serverId'] as String? ?? '',
      toolName: json['toolName'] as String? ?? '',
      required: json['required'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverId': serverId,
      'toolName': toolName,
      if (!required) 'required': required,
    };
  }
}

/// Knowledge source reference.
class KnowledgeSourceRef {
  /// Source identifier.
  final String sourceId;

  /// Retrieval mode.
  final String mode;

  /// Top K results.
  final int? topK;

  const KnowledgeSourceRef({
    required this.sourceId,
    this.mode = 'similarity',
    this.topK,
  });

  factory KnowledgeSourceRef.fromJson(Map<String, dynamic> json) {
    return KnowledgeSourceRef(
      sourceId: json['sourceId'] as String? ?? '',
      mode: json['mode'] as String? ?? 'similarity',
      topK: json['topK'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'mode': mode,
      if (topK != null) 'topK': topK,
    };
  }
}

/// Skill rubric for evaluation.
class SkillRubric {
  /// Rubric criteria.
  final List<RubricCriterion> criteria;

  /// Minimum passing score.
  final double? minScore;

  const SkillRubric({
    this.criteria = const [],
    this.minScore,
  });

  factory SkillRubric.fromJson(Map<String, dynamic> json) {
    return SkillRubric(
      criteria: (json['criteria'] as List<dynamic>?)
              ?.map((e) => RubricCriterion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      minScore: (json['minScore'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (criteria.isNotEmpty)
        'criteria': criteria.map((c) => c.toJson()).toList(),
      if (minScore != null) 'minScore': minScore,
    };
  }
}

/// Rubric criterion.
class RubricCriterion {
  /// Criterion name.
  final String name;

  /// Criterion description.
  final String? description;

  /// Weight.
  final double weight;

  /// Scoring levels.
  final List<ScoringLevel> levels;

  const RubricCriterion({
    required this.name,
    this.description,
    this.weight = 1.0,
    this.levels = const [],
  });

  factory RubricCriterion.fromJson(Map<String, dynamic> json) {
    return RubricCriterion(
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      levels: (json['levels'] as List<dynamic>?)
              ?.map((e) => ScoringLevel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'weight': weight,
      if (levels.isNotEmpty) 'levels': levels.map((l) => l.toJson()).toList(),
    };
  }
}

/// Scoring level.
class ScoringLevel {
  /// Level score.
  final int score;

  /// Level description.
  final String description;

  const ScoringLevel({
    required this.score,
    required this.description,
  });

  factory ScoringLevel.fromJson(Map<String, dynamic> json) {
    return ScoringLevel(
      score: json['score'] as int? ?? 0,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'description': description,
    };
  }
}

/// Shared skill configuration.
class SkillConfig {
  /// Default LLM settings.
  final Map<String, dynamic> llmDefaults;

  /// Default timeout in milliseconds.
  final int? defaultTimeoutMs;

  /// Default retry configuration.
  final Map<String, dynamic>? retryDefaults;

  const SkillConfig({
    this.llmDefaults = const {},
    this.defaultTimeoutMs,
    this.retryDefaults,
  });

  factory SkillConfig.fromJson(Map<String, dynamic> json) {
    return SkillConfig(
      llmDefaults: json['llmDefaults'] as Map<String, dynamic>? ?? {},
      defaultTimeoutMs: json['defaultTimeoutMs'] as int?,
      retryDefaults: json['retryDefaults'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (llmDefaults.isNotEmpty) 'llmDefaults': llmDefaults,
      if (defaultTimeoutMs != null) 'defaultTimeoutMs': defaultTimeoutMs,
      if (retryDefaults != null) 'retryDefaults': retryDefaults,
    };
  }
}
