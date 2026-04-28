/// Policy section model.
///
/// Contains policy definitions for decision/validation rules.
/// Design: 02-models-design.md Section 4.6
library;

/// Policy section containing bundle policies.
class PolicySection {
  /// Policies defined in bundle.
  final List<Policy> policies;

  const PolicySection({
    this.policies = const [],
  });

  /// Create from JSON.
  factory PolicySection.fromJson(Map<String, dynamic> json) {
    return PolicySection(
      policies: (json['policies'] as List<dynamic>?)
              ?.map((e) => Policy.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      if (policies.isNotEmpty)
        'policies': policies.map((p) => p.toJson()).toList(),
    };
  }

  /// Create a copy with modifications.
  PolicySection copyWith({
    List<Policy>? policies,
  }) {
    return PolicySection(
      policies: policies ?? this.policies,
    );
  }

  /// Find policy by ID.
  Policy? findById(String id) {
    return policies.where((p) => p.id == id).firstOrNull;
  }

  /// Get policies sorted by priority (highest first).
  List<Policy> get sortedByPriority {
    final sorted = List<Policy>.from(policies);
    sorted.sort((a, b) => b.priority.compareTo(a.priority));
    return sorted;
  }
}

/// A policy definition with rules.
class Policy {
  /// Unique identifier.
  final String id;

  /// Human-readable name.
  final String name;

  /// Description.
  final String? description;

  /// Policy rules.
  final List<PolicyRule> rules;

  /// Priority (0-100, higher = more priority).
  final int priority;

  /// Whether this policy is enabled.
  final bool enabled;

  /// Tags for categorization.
  final List<String> tags;

  const Policy({
    required this.id,
    required this.name,
    this.description,
    required this.rules,
    this.priority = 50,
    this.enabled = true,
    this.tags = const [],
  });

  /// Create from JSON.
  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      rules: (json['rules'] as List<dynamic>?)
              ?.map((e) => PolicyRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      priority: json['priority'] as int? ?? 50,
      enabled: json['enabled'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'rules': rules.map((r) => r.toJson()).toList(),
      'priority': priority,
      if (!enabled) 'enabled': enabled,
      if (tags.isNotEmpty) 'tags': tags,
    };
  }

  /// Create a copy with modifications.
  Policy copyWith({
    String? id,
    String? name,
    String? description,
    List<PolicyRule>? rules,
    int? priority,
    bool? enabled,
    List<String>? tags,
  }) {
    return Policy(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rules: rules ?? this.rules,
      priority: priority ?? this.priority,
      enabled: enabled ?? this.enabled,
      tags: tags ?? this.tags,
    );
  }
}

/// A single policy rule.
class PolicyRule {
  /// Rule identifier.
  final String id;

  /// Condition that triggers this rule.
  final PolicyCondition condition;

  /// Action to take: "allow", "deny", "warn", "require_approval".
  final PolicyAction action;

  /// Message to display when rule triggers.
  final String? message;

  /// Metadata for this rule.
  final Map<String, dynamic>? metadata;

  const PolicyRule({
    required this.id,
    required this.condition,
    required this.action,
    this.message,
    this.metadata,
  });

  /// Create from JSON.
  factory PolicyRule.fromJson(Map<String, dynamic> json) {
    return PolicyRule(
      id: json['id'] as String? ?? '',
      condition: PolicyCondition.fromJson(
        json['condition'] as Map<String, dynamic>? ?? {},
      ),
      action: PolicyAction.fromString(json['action'] as String? ?? 'deny'),
      message: json['message'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'condition': condition.toJson(),
      'action': action.name,
      if (message != null) 'message': message,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create a copy with modifications.
  PolicyRule copyWith({
    String? id,
    PolicyCondition? condition,
    PolicyAction? action,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return PolicyRule(
      id: id ?? this.id,
      condition: condition ?? this.condition,
      action: action ?? this.action,
      message: message ?? this.message,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Policy action types.
enum PolicyAction {
  /// Allow the action.
  allow,

  /// Deny the action.
  deny,

  /// Warn but allow.
  warn,

  /// Require explicit approval.
  requireApproval,

  /// Log and continue.
  log,

  /// Unknown action.
  unknown;

  static PolicyAction fromString(String value) {
    switch (value.toLowerCase()) {
      case 'allow':
        return PolicyAction.allow;
      case 'deny':
        return PolicyAction.deny;
      case 'warn':
        return PolicyAction.warn;
      case 'require_approval':
      case 'requireapproval':
        return PolicyAction.requireApproval;
      case 'log':
        return PolicyAction.log;
      default:
        return PolicyAction.unknown;
    }
  }
}

/// Base class for policy conditions.
sealed class PolicyCondition {
  const PolicyCondition();

  /// Create from JSON.
  factory PolicyCondition.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'threshold':
        return ThresholdCondition.fromJson(json);
      case 'composite':
        return CompositeCondition.fromJson(json);
      case 'expression':
        return ExpressionCondition.fromJson(json);
      case 'always':
        return const AlwaysCondition();
      case 'metric':
        return MetricCondition.fromJson(json);
      default:
        // Default to expression if there's an expression field
        if (json.containsKey('expression')) {
          return ExpressionCondition.fromJson(json);
        }
        return ExpressionCondition(expression: json.toString());
    }
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson();

  /// Evaluate condition against context.
  bool evaluate(Map<String, dynamic> context);
}

/// Threshold-based condition.
class ThresholdCondition extends PolicyCondition {
  /// Metric name to check.
  final String metric;

  /// Comparison operator.
  final ThresholdOperator operator;

  /// Threshold value: number or [min, max] for "between".
  final dynamic value;

  const ThresholdCondition({
    required this.metric,
    required this.operator,
    required this.value,
  });

  /// Create from JSON.
  factory ThresholdCondition.fromJson(Map<String, dynamic> json) {
    return ThresholdCondition(
      metric: json['metric'] as String? ?? '',
      operator: ThresholdOperator.fromString(json['operator'] as String? ?? '>='),
      value: json['value'] ?? 0.0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'threshold',
      'metric': metric,
      'operator': operator.symbol,
      'value': value,
    };
  }

  @override
  bool evaluate(Map<String, dynamic> context) {
    final contextValue = context[metric];
    if (contextValue == null || contextValue is! num) return false;

    final numValue = contextValue.toDouble();

    if (operator == ThresholdOperator.between) {
      if (value is List && value.length == 2) {
        final min = (value[0] as num).toDouble();
        final max = (value[1] as num).toDouble();
        return numValue >= min && numValue <= max;
      }
      return false;
    }

    if (value is! num) return false;
    final thresholdValue = (value as num).toDouble();

    switch (operator) {
      case ThresholdOperator.gt:
        return numValue > thresholdValue;
      case ThresholdOperator.lt:
        return numValue < thresholdValue;
      case ThresholdOperator.gte:
        return numValue >= thresholdValue;
      case ThresholdOperator.lte:
        return numValue <= thresholdValue;
      case ThresholdOperator.eq:
        return numValue == thresholdValue;
      case ThresholdOperator.ne:
        return numValue != thresholdValue;
      case ThresholdOperator.between:
        return false; // Handled above
    }
  }

  /// Create a copy with modifications.
  ThresholdCondition copyWith({
    String? metric,
    ThresholdOperator? operator,
    dynamic value,
  }) {
    return ThresholdCondition(
      metric: metric ?? this.metric,
      operator: operator ?? this.operator,
      value: value ?? this.value,
    );
  }
}

/// Composite condition combining multiple conditions.
class CompositeCondition extends PolicyCondition {
  /// Logical operator: "and", "or", "not".
  final CompositeOperator operator;

  /// Child conditions.
  final List<PolicyCondition> conditions;

  const CompositeCondition({
    required this.operator,
    required this.conditions,
  });

  /// Create from JSON.
  factory CompositeCondition.fromJson(Map<String, dynamic> json) {
    return CompositeCondition(
      operator: CompositeOperator.fromString(json['operator'] as String? ?? 'and'),
      conditions: (json['conditions'] as List<dynamic>?)
              ?.map((e) => PolicyCondition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'composite',
      'operator': operator.name,
      'conditions': conditions.map((c) => c.toJson()).toList(),
    };
  }

  @override
  bool evaluate(Map<String, dynamic> context) {
    switch (operator) {
      case CompositeOperator.and:
        return conditions.every((c) => c.evaluate(context));
      case CompositeOperator.or:
        return conditions.any((c) => c.evaluate(context));
      case CompositeOperator.not:
        if (conditions.isEmpty) return true;
        return !conditions.first.evaluate(context);
    }
  }

  /// Create a copy with modifications.
  CompositeCondition copyWith({
    CompositeOperator? operator,
    List<PolicyCondition>? conditions,
  }) {
    return CompositeCondition(
      operator: operator ?? this.operator,
      conditions: conditions ?? this.conditions,
    );
  }
}

/// Composite logical operators.
enum CompositeOperator {
  and,
  or,
  not;

  static CompositeOperator fromString(String value) {
    switch (value.toLowerCase()) {
      case 'and':
        return CompositeOperator.and;
      case 'or':
        return CompositeOperator.or;
      case 'not':
        return CompositeOperator.not;
      default:
        return CompositeOperator.and;
    }
  }
}

/// Threshold comparison operators.
enum ThresholdOperator {
  /// Greater than (>).
  gt('>'),

  /// Greater than or equal (>=).
  gte('>='),

  /// Less than (<).
  lt('<'),

  /// Less than or equal (<=).
  lte('<='),

  /// Equal (==).
  eq('=='),

  /// Not equal (!=).
  ne('!='),

  /// Between [min, max].
  between('between');

  /// The symbol representation.
  final String symbol;

  const ThresholdOperator(this.symbol);

  static ThresholdOperator fromString(String value) {
    switch (value.toLowerCase()) {
      case '>':
      case 'gt':
        return ThresholdOperator.gt;
      case '>=':
      case 'gte':
        return ThresholdOperator.gte;
      case '<':
      case 'lt':
        return ThresholdOperator.lt;
      case '<=':
      case 'lte':
        return ThresholdOperator.lte;
      case '==':
      case 'eq':
        return ThresholdOperator.eq;
      case '!=':
      case 'ne':
        return ThresholdOperator.ne;
      case 'between':
        return ThresholdOperator.between;
      default:
        return ThresholdOperator.gte;
    }
  }
}

/// Expression-based condition.
class ExpressionCondition extends PolicyCondition {
  /// Expression string to evaluate.
  final String expression;

  const ExpressionCondition({required this.expression});

  /// Create from JSON.
  factory ExpressionCondition.fromJson(Map<String, dynamic> json) {
    return ExpressionCondition(
      expression: json['expression'] as String? ?? 'true',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'expression',
      'expression': expression,
    };
  }

  @override
  bool evaluate(Map<String, dynamic> context) {
    // Expression evaluation delegated to expression language evaluator
    // For now, return false as a placeholder
    // TODO: Integrate with expression evaluator from mcp_bundle expression package
    return false;
  }

  /// Create a copy with modifications.
  ExpressionCondition copyWith({String? expression}) {
    return ExpressionCondition(
      expression: expression ?? this.expression,
    );
  }
}

/// Always true condition.
class AlwaysCondition extends PolicyCondition {
  const AlwaysCondition();

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'always'};
  }

  @override
  bool evaluate(Map<String, dynamic> context) => true;
}

/// Metric existence/confidence condition.
class MetricCondition extends PolicyCondition {
  /// Metric ID to check.
  final String metric;

  /// Check if metric value is present.
  final bool? exists;

  /// Minimum confidence threshold.
  final double? confidence;

  const MetricCondition({
    required this.metric,
    this.exists,
    this.confidence,
  });

  /// Create from JSON.
  factory MetricCondition.fromJson(Map<String, dynamic> json) {
    return MetricCondition(
      metric: json['metric'] as String? ?? '',
      exists: json['exists'] as bool?,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'metric',
      'metric': metric,
      if (exists != null) 'exists': exists,
      if (confidence != null) 'confidence': confidence,
    };
  }

  @override
  bool evaluate(Map<String, dynamic> context) {
    final value = context[metric];

    // Check existence
    if (exists != null) {
      final isPresent = value != null;
      if (isPresent != exists) return false;
    }

    // Check confidence
    if (confidence != null && value is num) {
      return value.toDouble() >= confidence!;
    }

    return exists == null || (exists! && value != null);
  }

  /// Create a copy with modifications.
  MetricCondition copyWith({
    String? metric,
    bool? exists,
    double? confidence,
  }) {
    return MetricCondition(
      metric: metric ?? this.metric,
      exists: exists ?? this.exists,
      confidence: confidence ?? this.confidence,
    );
  }
}

/// Result of policy evaluation.
class PolicyEvaluationResult {
  /// Whether the overall evaluation passed.
  final bool passed;

  /// Action determined by the evaluation.
  final PolicyAction action;

  /// Triggered rules.
  final List<TriggeredRule> triggeredRules;

  /// Messages from triggered rules.
  final List<String> messages;

  const PolicyEvaluationResult({
    required this.passed,
    required this.action,
    this.triggeredRules = const [],
    this.messages = const [],
  });

  /// Create a passing result.
  factory PolicyEvaluationResult.pass() {
    return const PolicyEvaluationResult(
      passed: true,
      action: PolicyAction.allow,
    );
  }

  /// Create a failing result.
  factory PolicyEvaluationResult.fail({
    PolicyAction action = PolicyAction.deny,
    List<TriggeredRule> triggeredRules = const [],
    List<String> messages = const [],
  }) {
    return PolicyEvaluationResult(
      passed: false,
      action: action,
      triggeredRules: triggeredRules,
      messages: messages,
    );
  }
}

/// A rule that was triggered during evaluation.
class TriggeredRule {
  /// Policy ID.
  final String policyId;

  /// Rule ID.
  final String ruleId;

  /// Action from the rule.
  final PolicyAction action;

  /// Message from the rule.
  final String? message;

  const TriggeredRule({
    required this.policyId,
    required this.ruleId,
    required this.action,
    this.message,
  });
}
