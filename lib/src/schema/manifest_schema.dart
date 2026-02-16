/// Manifest schema definitions for MCP Bundle format.
///
/// Extended manifest schemas for specific resource types.
library;

import 'bundle_schema.dart';

/// Skill manifest schema.
class SkillManifest {
  /// Skill identifier.
  final String id;

  /// Skill name.
  final String name;

  /// Skill description.
  final String? description;

  /// Skill version.
  final String version;

  /// Input parameters schema.
  final List<ParameterSchema> inputs;

  /// Output schema.
  final OutputSchema? output;

  /// Skill steps/actions.
  final List<SkillStep> steps;

  /// Skill triggers.
  final List<SkillTrigger> triggers;

  const SkillManifest({
    required this.id,
    required this.name,
    this.description,
    this.version = '1.0.0',
    this.inputs = const [],
    this.output,
    this.steps = const [],
    this.triggers = const [],
  });

  factory SkillManifest.fromJson(Map<String, dynamic> json) {
    return SkillManifest(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      version: json['version'] as String? ?? '1.0.0',
      inputs: (json['inputs'] as List<dynamic>?)
              ?.map((e) => ParameterSchema.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      output: json['output'] != null
          ? OutputSchema.fromJson(json['output'] as Map<String, dynamic>)
          : null,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => SkillStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      triggers: (json['triggers'] as List<dynamic>?)
              ?.map((e) => SkillTrigger.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'version': version,
        if (inputs.isNotEmpty) 'inputs': inputs.map((i) => i.toJson()).toList(),
        if (output != null) 'output': output!.toJson(),
        if (steps.isNotEmpty) 'steps': steps.map((s) => s.toJson()).toList(),
        if (triggers.isNotEmpty)
          'triggers': triggers.map((t) => t.toJson()).toList(),
      };
}

/// Parameter schema for inputs/outputs.
class ParameterSchema {
  /// Parameter name.
  final String name;

  /// Parameter type.
  final String type;

  /// Parameter description.
  final String? description;

  /// Whether the parameter is required.
  final bool required;

  /// Default value.
  final dynamic defaultValue;

  /// Validation constraints.
  final Map<String, dynamic> constraints;

  const ParameterSchema({
    required this.name,
    required this.type,
    this.description,
    this.required = true,
    this.defaultValue,
    this.constraints = const {},
  });

  factory ParameterSchema.fromJson(Map<String, dynamic> json) {
    return ParameterSchema(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'string',
      description: json['description'] as String?,
      required: json['required'] as bool? ?? true,
      defaultValue: json['default'],
      constraints: json['constraints'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        if (description != null) 'description': description,
        'required': required,
        if (defaultValue != null) 'default': defaultValue,
        if (constraints.isNotEmpty) 'constraints': constraints,
      };
}

/// Output schema definition.
class OutputSchema {
  /// Output type.
  final String type;

  /// Output schema (for complex types).
  final Map<String, dynamic> schema;

  /// Output description.
  final String? description;

  const OutputSchema({
    required this.type,
    this.schema = const {},
    this.description,
  });

  factory OutputSchema.fromJson(Map<String, dynamic> json) {
    return OutputSchema(
      type: json['type'] as String? ?? 'any',
      schema: json['schema'] as Map<String, dynamic>? ?? {},
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (schema.isNotEmpty) 'schema': schema,
        if (description != null) 'description': description,
      };
}

/// A step within a skill.
class SkillStep {
  /// Step identifier.
  final String id;

  /// Step type (action, condition, loop, etc.).
  final StepType type;

  /// Step configuration.
  final Map<String, dynamic> config;

  /// Step condition (expression).
  final String? condition;

  /// Next step(s).
  final List<String> next;

  const SkillStep({
    required this.id,
    required this.type,
    this.config = const {},
    this.condition,
    this.next = const [],
  });

  factory SkillStep.fromJson(Map<String, dynamic> json) {
    return SkillStep(
      id: json['id'] as String? ?? '',
      type: StepType.fromString(json['type'] as String? ?? 'action'),
      config: json['config'] as Map<String, dynamic>? ?? {},
      condition: json['condition'] as String?,
      next: (json['next'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        if (config.isNotEmpty) 'config': config,
        if (condition != null) 'condition': condition,
        if (next.isNotEmpty) 'next': next,
      };
}

/// Step types.
enum StepType {
  /// Execute an action.
  action,

  /// Conditional branch.
  condition,

  /// Loop/iteration.
  loop,

  /// Parallel execution.
  parallel,

  /// Wait/delay.
  wait,

  /// Transform data.
  transform,

  /// Call another skill.
  call,

  /// Return/output.
  output,

  /// Unknown step type.
  unknown;

  static StepType fromString(String value) {
    return StepType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StepType.unknown,
    );
  }
}

/// Skill trigger definition.
class SkillTrigger {
  /// Trigger type.
  final TriggerType type;

  /// Trigger configuration.
  final Map<String, dynamic> config;

  /// Trigger condition (expression).
  final String? condition;

  const SkillTrigger({
    required this.type,
    this.config = const {},
    this.condition,
  });

  factory SkillTrigger.fromJson(Map<String, dynamic> json) {
    return SkillTrigger(
      type: TriggerType.fromString(json['type'] as String? ?? 'manual'),
      config: json['config'] as Map<String, dynamic>? ?? {},
      condition: json['condition'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (config.isNotEmpty) 'config': config,
        if (condition != null) 'condition': condition,
      };
}

/// Trigger types.
enum TriggerType {
  /// Manual invocation.
  manual,

  /// Scheduled execution.
  schedule,

  /// Event-based trigger.
  event,

  /// Webhook trigger.
  webhook,

  /// File change trigger.
  fileChange,

  /// Unknown trigger type.
  unknown;

  static TriggerType fromString(String value) {
    return TriggerType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TriggerType.unknown,
    );
  }
}

/// Profile manifest schema.
class ProfileManifest {
  /// Profile identifier.
  final String id;

  /// Profile name.
  final String name;

  /// Profile description.
  final String? description;

  /// Profile version.
  final String version;

  /// Profile sections.
  final List<ProfileSection> sections;

  /// Profile capabilities.
  final List<String> capabilities;

  const ProfileManifest({
    required this.id,
    required this.name,
    this.description,
    this.version = '1.0.0',
    this.sections = const [],
    this.capabilities = const [],
  });

  factory ProfileManifest.fromJson(Map<String, dynamic> json) {
    return ProfileManifest(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      version: json['version'] as String? ?? '1.0.0',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => ProfileSection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'version': version,
        if (sections.isNotEmpty)
          'sections': sections.map((s) => s.toJson()).toList(),
        if (capabilities.isNotEmpty) 'capabilities': capabilities,
      };
}

/// Profile section.
class ProfileSection {
  /// Section name.
  final String name;

  /// Section content.
  final String content;

  /// Section priority.
  final int priority;

  /// Section conditions.
  final String? condition;

  const ProfileSection({
    required this.name,
    required this.content,
    this.priority = 0,
    this.condition,
  });

  factory ProfileSection.fromJson(Map<String, dynamic> json) {
    return ProfileSection(
      name: json['name'] as String? ?? '',
      content: json['content'] as String? ?? '',
      priority: json['priority'] as int? ?? 0,
      condition: json['condition'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'content': content,
        if (priority != 0) 'priority': priority,
        if (condition != null) 'condition': condition,
      };
}

/// Create a BundleResource from a SkillManifest.
BundleResource skillToResource(SkillManifest skill, {String? path}) {
  return BundleResource(
    path: path ?? 'skills/${skill.id}.json',
    type: ResourceType.skill,
    content: skill.toJson(),
  );
}

/// Create a BundleResource from a ProfileManifest.
BundleResource profileToResource(ProfileManifest profile, {String? path}) {
  return BundleResource(
    path: path ?? 'profiles/${profile.id}.json',
    type: ResourceType.profile,
    content: profile.toJson(),
  );
}
