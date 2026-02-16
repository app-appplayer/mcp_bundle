/// Flow Section model for MCP Bundle.
///
/// Contains flow definitions for orchestrating skills and actions.
library;

/// Flow section containing flow definitions.
class FlowSection {
  /// Schema version for flow section.
  final String schemaVersion;

  /// List of flow definitions.
  final List<FlowDefinition> flows;

  /// Shared variables accessible across flows.
  final Map<String, dynamic> sharedState;

  /// Error handlers.
  final List<ErrorHandler> errorHandlers;

  const FlowSection({
    this.schemaVersion = '1.0.0',
    this.flows = const [],
    this.sharedState = const {},
    this.errorHandlers = const [],
  });

  factory FlowSection.fromJson(Map<String, dynamic> json) {
    return FlowSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      flows: (json['flows'] as List<dynamic>?)
              ?.map((e) => FlowDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sharedState: json['sharedState'] as Map<String, dynamic>? ?? {},
      errorHandlers: (json['errorHandlers'] as List<dynamic>?)
              ?.map((e) => ErrorHandler.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      if (flows.isNotEmpty) 'flows': flows.map((f) => f.toJson()).toList(),
      if (sharedState.isNotEmpty) 'sharedState': sharedState,
      if (errorHandlers.isNotEmpty)
        'errorHandlers': errorHandlers.map((e) => e.toJson()).toList(),
    };
  }
}

/// Flow definition.
class FlowDefinition {
  /// Flow identifier.
  final String id;

  /// Flow name.
  final String name;

  /// Flow description.
  final String? description;

  /// Flow trigger.
  final FlowTrigger? trigger;

  /// Flow steps.
  final List<FlowStep> steps;

  /// Input parameters.
  final List<FlowParameter> inputs;

  /// Output definition.
  final FlowOutput? output;

  /// Flow timeout in milliseconds.
  final int? timeoutMs;

  /// Retry configuration.
  final RetryConfig? retry;

  const FlowDefinition({
    required this.id,
    required this.name,
    this.description,
    this.trigger,
    this.steps = const [],
    this.inputs = const [],
    this.output,
    this.timeoutMs,
    this.retry,
  });

  factory FlowDefinition.fromJson(Map<String, dynamic> json) {
    return FlowDefinition(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      trigger: json['trigger'] != null
          ? FlowTrigger.fromJson(json['trigger'] as Map<String, dynamic>)
          : null,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => FlowStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      inputs: (json['inputs'] as List<dynamic>?)
              ?.map((e) => FlowParameter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      output: json['output'] != null
          ? FlowOutput.fromJson(json['output'] as Map<String, dynamic>)
          : null,
      timeoutMs: json['timeoutMs'] as int?,
      retry: json['retry'] != null
          ? RetryConfig.fromJson(json['retry'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (trigger != null) 'trigger': trigger!.toJson(),
      if (steps.isNotEmpty) 'steps': steps.map((s) => s.toJson()).toList(),
      if (inputs.isNotEmpty) 'inputs': inputs.map((i) => i.toJson()).toList(),
      if (output != null) 'output': output!.toJson(),
      if (timeoutMs != null) 'timeoutMs': timeoutMs,
      if (retry != null) 'retry': retry!.toJson(),
    };
  }
}

/// Flow trigger definition.
class FlowTrigger {
  /// Trigger type.
  final TriggerType type;

  /// Trigger configuration.
  final Map<String, dynamic> config;

  /// Trigger condition expression.
  final String? condition;

  const FlowTrigger({
    required this.type,
    this.config = const {},
    this.condition,
  });

  factory FlowTrigger.fromJson(Map<String, dynamic> json) {
    return FlowTrigger(
      type: TriggerType.fromString(json['type'] as String? ?? 'manual'),
      config: json['config'] as Map<String, dynamic>? ?? {},
      condition: json['condition'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (config.isNotEmpty) 'config': config,
      if (condition != null) 'condition': condition,
    };
  }
}

/// Trigger types.
enum TriggerType {
  manual,
  schedule,
  event,
  webhook,
  startup,
  onChange,
  unknown;

  static TriggerType fromString(String value) {
    return TriggerType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TriggerType.unknown,
    );
  }
}

/// Flow step definition.
class FlowStep {
  /// Step identifier.
  final String id;

  /// Step type.
  final StepType type;

  /// Step name.
  final String? name;

  /// Step configuration.
  final Map<String, dynamic> config;

  /// Condition for step execution.
  final String? condition;

  /// Next step(s) on success.
  final List<String> next;

  /// Next step on error.
  final String? onError;

  /// Step timeout in milliseconds.
  final int? timeoutMs;

  /// Retry configuration.
  final RetryConfig? retry;

  const FlowStep({
    required this.id,
    required this.type,
    this.name,
    this.config = const {},
    this.condition,
    this.next = const [],
    this.onError,
    this.timeoutMs,
    this.retry,
  });

  factory FlowStep.fromJson(Map<String, dynamic> json) {
    return FlowStep(
      id: json['id'] as String? ?? '',
      type: StepType.fromString(json['type'] as String? ?? 'action'),
      name: json['name'] as String?,
      config: json['config'] as Map<String, dynamic>? ?? {},
      condition: json['condition'] as String?,
      next: (json['next'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      onError: json['onError'] as String?,
      timeoutMs: json['timeoutMs'] as int?,
      retry: json['retry'] != null
          ? RetryConfig.fromJson(json['retry'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      if (name != null) 'name': name,
      if (config.isNotEmpty) 'config': config,
      if (condition != null) 'condition': condition,
      if (next.isNotEmpty) 'next': next,
      if (onError != null) 'onError': onError,
      if (timeoutMs != null) 'timeoutMs': timeoutMs,
      if (retry != null) 'retry': retry!.toJson(),
    };
  }
}

/// Step types.
enum StepType {
  /// Execute an action.
  action,

  /// Call a skill.
  skill,

  /// Call another flow.
  flow,

  /// Conditional branch.
  condition,

  /// Switch/match statement.
  switchCase,

  /// Parallel execution.
  parallel,

  /// Loop/iteration.
  loop,

  /// Wait/delay.
  wait,

  /// Set variable.
  setVar,

  /// Transform data.
  transform,

  /// Call external API.
  api,

  /// LLM call.
  llm,

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

/// Flow parameter definition.
class FlowParameter {
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

  /// Validation schema.
  final Map<String, dynamic>? validation;

  const FlowParameter({
    required this.name,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.description,
    this.validation,
  });

  factory FlowParameter.fromJson(Map<String, dynamic> json) {
    return FlowParameter(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'string',
      required: json['required'] as bool? ?? false,
      defaultValue: json['default'],
      description: json['description'] as String?,
      validation: json['validation'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      if (required) 'required': required,
      if (defaultValue != null) 'default': defaultValue,
      if (description != null) 'description': description,
      if (validation != null) 'validation': validation,
    };
  }
}

/// Flow output definition.
class FlowOutput {
  /// Output type.
  final String type;

  /// Output schema.
  final Map<String, dynamic>? schema;

  /// Output expression.
  final String? expression;

  const FlowOutput({
    required this.type,
    this.schema,
    this.expression,
  });

  factory FlowOutput.fromJson(Map<String, dynamic> json) {
    return FlowOutput(
      type: json['type'] as String? ?? 'any',
      schema: json['schema'] as Map<String, dynamic>?,
      expression: json['expression'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (schema != null) 'schema': schema,
      if (expression != null) 'expression': expression,
    };
  }
}

/// Retry configuration.
class RetryConfig {
  /// Maximum retry attempts.
  final int maxAttempts;

  /// Initial delay in milliseconds.
  final int initialDelayMs;

  /// Maximum delay in milliseconds.
  final int maxDelayMs;

  /// Backoff multiplier.
  final double backoffMultiplier;

  /// Retryable error codes.
  final List<String> retryOn;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelayMs = 1000,
    this.maxDelayMs = 30000,
    this.backoffMultiplier = 2.0,
    this.retryOn = const [],
  });

  factory RetryConfig.fromJson(Map<String, dynamic> json) {
    return RetryConfig(
      maxAttempts: json['maxAttempts'] as int? ?? 3,
      initialDelayMs: json['initialDelayMs'] as int? ?? 1000,
      maxDelayMs: json['maxDelayMs'] as int? ?? 30000,
      backoffMultiplier: (json['backoffMultiplier'] as num?)?.toDouble() ?? 2.0,
      retryOn: (json['retryOn'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxAttempts': maxAttempts,
      'initialDelayMs': initialDelayMs,
      'maxDelayMs': maxDelayMs,
      'backoffMultiplier': backoffMultiplier,
      if (retryOn.isNotEmpty) 'retryOn': retryOn,
    };
  }
}

/// Error handler definition.
class ErrorHandler {
  /// Handler name.
  final String name;

  /// Error patterns to match.
  final List<String> patterns;

  /// Handler action.
  final Map<String, dynamic> action;

  /// Whether to continue after handling.
  final bool continueFlow;

  const ErrorHandler({
    required this.name,
    this.patterns = const [],
    this.action = const {},
    this.continueFlow = false,
  });

  factory ErrorHandler.fromJson(Map<String, dynamic> json) {
    return ErrorHandler(
      name: json['name'] as String? ?? '',
      patterns: (json['patterns'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      action: json['action'] as Map<String, dynamic>? ?? {},
      continueFlow: json['continueFlow'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (patterns.isNotEmpty) 'patterns': patterns,
      if (action.isNotEmpty) 'action': action,
      if (continueFlow) 'continueFlow': continueFlow,
    };
  }
}
