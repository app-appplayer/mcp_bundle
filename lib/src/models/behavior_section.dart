/// Behavior section — the bundle-side public schema for the unified
/// "behavior definition" knowledge category (the successor to the separate
/// flow / pipeline / runbook sections).
///
/// A behavior definition is an ordered list of declarative steps. Each step
/// carries `do` (a tool/skill invocation), `when` (a guard expression over
/// run state), `then` (guard result → outcome name), and ordering hints.
/// The host kernel maps these to its execution engine; this section is the
/// serializable carrier only — it encodes no control behavior itself.
library;

/// A section containing behavior definitions.
class BehaviorSection {
  /// Schema version for the behavior section.
  final String schemaVersion;

  /// Behavior definitions in this section.
  final List<BehaviorDefinition> definitions;

  const BehaviorSection({
    this.schemaVersion = '1.0.0',
    this.definitions = const [],
  });

  factory BehaviorSection.fromJson(Map<String, dynamic> json) {
    return BehaviorSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      definitions: (json['definitions'] as List<dynamic>?)
              ?.map((e) =>
                  BehaviorDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        if (definitions.isNotEmpty)
          'definitions': definitions.map((d) => d.toJson()).toList(),
      };

  bool get isEmpty => definitions.isEmpty;
  bool get isNotEmpty => definitions.isNotEmpty;

  BehaviorDefinition? findById(String id) {
    for (final d in definitions) {
      if (d.id == id) return d;
    }
    return null;
  }
}

/// A single behavior definition (one runnable unit).
class BehaviorDefinition {
  /// Unique identifier.
  final String id;

  /// Human-readable name.
  final String name;

  /// Optional description.
  final String? description;

  /// Ordered steps.
  final List<BehaviorStepDef> steps;

  /// Free-form metadata for host-specific extension.
  final Map<String, dynamic> metadata;

  const BehaviorDefinition({
    required this.id,
    required this.name,
    this.description,
    this.steps = const [],
    this.metadata = const {},
  });

  factory BehaviorDefinition.fromJson(Map<String, dynamic> json) {
    return BehaviorDefinition(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => BehaviorStepDef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (steps.isNotEmpty) 'steps': steps.map((s) => s.toJson()).toList(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

/// A single behavior step — the public step contract
/// `{ id, do, when, then, dependsOn, onFailure }`.
class BehaviorStepDef {
  /// Unique id within the definition.
  final String id;

  /// The action to run (`do`) — a free-form invocation map
  /// (`{tool, args}` | `{skill, inputs}` | `{kind, ref, args}`). The host
  /// engine interprets it. Null = a guard-only step.
  final Map<String, dynamic>? action;

  /// Guard expression over run state. Absent → always proceed.
  final String? when;

  /// Maps the stringified guard result to an outcome name (`proceed`,
  /// `skip`, `wait`, `stop`, `goto:<id>`, or any host-registered outcome).
  /// A `''` key is the default route.
  final Map<String, String> then;

  /// Step ids that must complete before this one.
  final List<String> dependsOn;

  /// Step id to jump to when the action fails. Absent → the run fails.
  final String? onFailure;

  const BehaviorStepDef({
    required this.id,
    this.action,
    this.when,
    this.then = const {},
    this.dependsOn = const [],
    this.onFailure,
  });

  factory BehaviorStepDef.fromJson(Map<String, dynamic> json) {
    return BehaviorStepDef(
      id: json['id'] as String? ?? '',
      action: json['do'] != null
          ? Map<String, dynamic>.from(json['do'] as Map)
          : null,
      when: json['when'] as String?,
      then: (json['then'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ??
          const {},
      dependsOn:
          (json['dependsOn'] as List?)?.map((e) => '$e').toList() ?? const [],
      onFailure: json['onFailure'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (action != null) 'do': action,
        if (when != null) 'when': when,
        if (then.isNotEmpty) 'then': then,
        if (dependsOn.isNotEmpty) 'dependsOn': dependsOn,
        if (onFailure != null) 'onFailure': onFailure,
      };
}
