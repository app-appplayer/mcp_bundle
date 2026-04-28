/// IoPolicyPort - Interface for I/O policy evaluation and rule management.
///
/// Defines policy rules that govern I/O device actions, including conditions,
/// constraints, rate limits, and interlocks. Used by adapters to evaluate
/// whether a given action should be allowed, denied, or require approval.
library;

import 'io_device_port.dart';

// ---------------------------------------------------------------------------
// Data types
// ---------------------------------------------------------------------------

/// Condition that determines when a policy rule applies.
class PolicyCondition {
  /// Exact action name or prefix match with trailing `*`.
  final String? action;

  /// URI prefix to match against the target device/resource.
  final String? targetPrefix;

  /// Allowed actor roles (any match satisfies the condition).
  final List<String>? actorRoleIn;

  /// Required safety class of the device.
  final SafetyClass? safetyClass;

  /// Transport type (e.g., 'mqtt', 'http', 'serial').
  final String? transport;

  const PolicyCondition({
    this.action,
    this.targetPrefix,
    this.actorRoleIn,
    this.safetyClass,
    this.transport,
  });

  factory PolicyCondition.fromJson(Map<String, dynamic> json) {
    return PolicyCondition(
      action: json['action'] as String?,
      targetPrefix: json['targetPrefix'] as String?,
      actorRoleIn: (json['actorRoleIn'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      safetyClass: json['safetyClass'] != null
          ? SafetyClass.values.firstWhere(
              (SafetyClass e) => e.name == json['safetyClass'] as String,
              orElse: () => SafetyClass.safe,
            )
          : null,
      transport: json['transport'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (action != null) 'action': action,
        if (targetPrefix != null) 'targetPrefix': targetPrefix,
        if (actorRoleIn != null) 'actorRoleIn': actorRoleIn,
        if (safetyClass != null) 'safetyClass': safetyClass!.name,
        if (transport != null) 'transport': transport,
      };
}

/// Numeric bound constraint for an argument value.
class Bound {
  /// Minimum allowed value (inclusive).
  final double? min;

  /// Maximum allowed value (inclusive).
  final double? max;

  const Bound({this.min, this.max});

  factory Bound.fromJson(Map<String, dynamic> json) {
    return Bound(
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (min != null) 'min': min,
        if (max != null) 'max': max,
      };
}

/// Rate limit constraint for action invocations.
class RateLimit {
  /// Maximum number of calls allowed within [window].
  final int maxCalls;

  /// Time window over which [maxCalls] is measured.
  final Duration window;

  RateLimit({
    required this.maxCalls,
    required this.window,
  });

  factory RateLimit.fromJson(Map<String, dynamic> json) {
    return RateLimit(
      maxCalls: json['maxCalls'] as int? ?? 0,
      window: Duration(milliseconds: json['windowMs'] as int? ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'maxCalls': maxCalls,
        'windowMs': window.inMilliseconds,
      };
}

/// Interlock that must be satisfied before an action proceeds.
class Interlock {
  /// URI of the device or resource to check.
  final String uri;

  /// Condition to evaluate against the interlock target.
  final InterlockCondition condition;

  /// Action to take when the interlock condition is met.
  final InterlockAction action;

  const Interlock({
    required this.uri,
    required this.condition,
    required this.action,
  });

  factory Interlock.fromJson(Map<String, dynamic> json) {
    return Interlock(
      uri: json['uri'] as String,
      condition: InterlockCondition.values.firstWhere(
        (InterlockCondition e) => e.name == json['condition'] as String,
        orElse: () => InterlockCondition.equals,
      ),
      action: InterlockAction.values.firstWhere(
        (InterlockAction e) => e.name == json['action'] as String,
        orElse: () => InterlockAction.deny,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'uri': uri,
        'condition': condition.name,
        'action': action.name,
      };
}

/// Constraints applied when a policy rule allows an action.
class PolicyConstraints {
  /// Numeric bounds per argument name.
  final Map<String, Bound>? bounds;

  /// Rate limit for the action.
  final RateLimit? rateLimit;

  /// Interlocks that must pass before the action proceeds.
  final List<Interlock>? interlocks;

  /// Whether explicit approval is required even when allowed.
  final bool? requireApproval;

  const PolicyConstraints({
    this.bounds,
    this.rateLimit,
    this.interlocks,
    this.requireApproval,
  });

  factory PolicyConstraints.fromJson(Map<String, dynamic> json) {
    return PolicyConstraints(
      bounds: (json['bounds'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, Bound.fromJson(v as Map<String, dynamic>)),
      ),
      rateLimit: json['rateLimit'] != null
          ? RateLimit.fromJson(json['rateLimit'] as Map<String, dynamic>)
          : null,
      interlocks: (json['interlocks'] as List<dynamic>?)
          ?.map((e) => Interlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      requireApproval: json['requireApproval'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (bounds != null)
          'bounds': bounds!.map((k, v) => MapEntry(k, v.toJson())),
        if (rateLimit != null) 'rateLimit': rateLimit!.toJson(),
        if (interlocks != null)
          'interlocks': interlocks!.map((i) => i.toJson()).toList(),
        if (requireApproval != null) 'requireApproval': requireApproval,
      };
}

/// A single policy rule governing I/O actions.
class PolicyRule {
  /// Unique rule identifier.
  final String id;

  /// Human-readable rule name.
  final String name;

  /// Optional description of the rule's purpose.
  final String? description;

  /// Condition that triggers this rule.
  final PolicyCondition when;

  /// Whether the action is allowed (`true`) or denied (`false`).
  final bool allow;

  /// Optional constraints applied when the rule allows an action.
  final PolicyConstraints? constraints;

  /// Evaluation priority. Higher values are evaluated first.
  final int? priority;

  /// Whether this rule is active.
  final bool enabled;

  const PolicyRule({
    required this.id,
    required this.name,
    this.description,
    required this.when,
    required this.allow,
    this.constraints,
    this.priority,
    this.enabled = true,
  });

  factory PolicyRule.fromJson(Map<String, dynamic> json) {
    return PolicyRule(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      when: PolicyCondition.fromJson(json['when'] as Map<String, dynamic>),
      allow: json['allow'] as bool,
      constraints: json['constraints'] != null
          ? PolicyConstraints.fromJson(
              json['constraints'] as Map<String, dynamic>)
          : null,
      priority: json['priority'] as int?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'when': when.toJson(),
        'allow': allow,
        if (constraints != null) 'constraints': constraints!.toJson(),
        if (priority != null) 'priority': priority,
        'enabled': enabled,
      };
}

/// Result of evaluating a policy against an action.
class PolicyDecision {
  /// The decision outcome.
  final Decision decision;

  /// ID of the rule that produced this decision, if any.
  final String? ruleId;

  /// Optional human-readable notes explaining the decision.
  final String? notes;

  const PolicyDecision({
    required this.decision,
    this.ruleId,
    this.notes,
  });

  factory PolicyDecision.fromJson(Map<String, dynamic> json) {
    return PolicyDecision(
      decision: Decision.values.firstWhere(
        (Decision e) => e.name == json['decision'] as String,
        orElse: () => Decision.deny,
      ),
      ruleId: json['ruleId'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'decision': decision.name,
        if (ruleId != null) 'ruleId': ruleId,
        if (notes != null) 'notes': notes,
      };
}

// ---------------------------------------------------------------------------
// Port
// ---------------------------------------------------------------------------

/// Port for managing and querying I/O policy rules.
abstract class IoPolicyPort {
  /// List policy rules, optionally filtered by device ID or action.
  Future<List<PolicyRule>> listRules({
    String? deviceIdFilter,
    String? actionFilter,
  });

  /// Add a new policy rule.
  Future<void> addRule(PolicyRule rule);

  /// Update an existing policy rule (matched by [rule.id]).
  Future<void> updateRule(PolicyRule rule);

  /// Remove a policy rule by its ID.
  Future<void> removeRule(String ruleId);
}

// ---------------------------------------------------------------------------
// Stub
// ---------------------------------------------------------------------------

/// Stub implementation of [IoPolicyPort] for testing.
class StubIoPolicyPort implements IoPolicyPort {
  final List<PolicyRule> _rules = [];

  @override
  Future<List<PolicyRule>> listRules({
    String? deviceIdFilter,
    String? actionFilter,
  }) async {
    return _rules.where((rule) {
      if (deviceIdFilter != null &&
          rule.when.targetPrefix != null &&
          !rule.when.targetPrefix!.startsWith(deviceIdFilter)) {
        return false;
      }
      if (actionFilter != null &&
          rule.when.action != null &&
          !rule.when.action!.startsWith(actionFilter)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> addRule(PolicyRule rule) async {
    _rules.add(rule);
  }

  @override
  Future<void> updateRule(PolicyRule rule) async {
    final index = _rules.indexWhere((r) => r.id == rule.id);
    if (index >= 0) {
      _rules[index] = rule;
    } else {
      throw StateError('Rule not found: ${rule.id}');
    }
  }

  @override
  Future<void> removeRule(String ruleId) async {
    _rules.removeWhere((r) => r.id == ruleId);
  }
}
