/// Decision Guidance Types - Actions and modifiers for decision policies.
///
/// Canonical contract-layer types for profile decision evaluation results.
/// As per mcp_profile spec/03-decision-policy-schema.md §5.
library;

// =============================================================================
// DecisionGuidance (§5)
// =============================================================================

/// Guidance returned when a policy condition matches.
class DecisionGuidance {
  /// Recommended action.
  final DecisionAction action;

  /// Confidence in this recommendation (0.0 - 1.0).
  final double? confidence;

  /// Explanation for this guidance.
  final String? explanation;

  /// Additional modifiers for the decision.
  final List<DecisionModifier> modifiers;

  /// Custom metadata.
  final Map<String, dynamic>? metadata;

  const DecisionGuidance({
    required this.action,
    this.confidence,
    this.explanation,
    this.modifiers = const [],
    this.metadata,
  });

  /// Check if this guidance requires approval.
  bool get requiresApproval =>
      modifiers.any((m) => m.type == ModifierType.requireApproval);

  /// Check if this guidance requires evidence.
  bool get requiresEvidence =>
      modifiers.any((m) => m.type == ModifierType.requireEvidence);

  /// Get all modifiers of a specific type.
  List<DecisionModifier> getModifiers(ModifierType type) =>
      modifiers.where((m) => m.type == type).toList();

  factory DecisionGuidance.fromJson(Map<String, dynamic> json) {
    return DecisionGuidance(
      action: DecisionActionExtension.fromJsonName(json['action'] as String),
      confidence: (json['confidence'] as num?)?.toDouble(),
      explanation: json['explanation'] as String?,
      modifiers: (json['modifiers'] as List<dynamic>?)
              ?.map((e) => DecisionModifier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'action': action.toJsonName(),
        if (confidence != null) 'confidence': confidence,
        if (explanation != null) 'explanation': explanation,
        if (modifiers.isNotEmpty)
          'modifiers': modifiers.map((m) => m.toJson()).toList(),
        if (metadata != null) 'metadata': metadata,
      };

  /// Create default "proceed" guidance.
  static const DecisionGuidance defaultProceed = DecisionGuidance(
    action: DecisionAction.proceed,
    confidence: 1.0,
  );

  /// Alias for [defaultProceed].
  static const DecisionGuidance proceed = defaultProceed;
}

// =============================================================================
// DecisionAction (§5.1)
// =============================================================================

/// Actions that can be recommended by a decision policy.
enum DecisionAction {
  /// Continue normally.
  proceed,

  /// Continue with extra care.
  proceedWithCaution,

  /// Wait for more information.
  hold,

  /// Ask clarifying questions.
  question,

  /// Request human/expert input.
  escalate,

  /// Do not proceed.
  reject,

  /// Postpone decision.
  defer,

  /// Application-specific action.
  custom,
}

extension DecisionActionExtension on DecisionAction {
  String toJsonName() {
    return switch (this) {
      DecisionAction.proceed => 'proceed',
      DecisionAction.proceedWithCaution => 'proceed_with_caution',
      DecisionAction.hold => 'hold',
      DecisionAction.question => 'question',
      DecisionAction.escalate => 'escalate',
      DecisionAction.reject => 'reject',
      DecisionAction.defer => 'defer',
      DecisionAction.custom => 'custom',
    };
  }

  static DecisionAction fromJsonName(String name) {
    return switch (name) {
      'proceed' => DecisionAction.proceed,
      'proceed_with_caution' => DecisionAction.proceedWithCaution,
      'hold' => DecisionAction.hold,
      'question' => DecisionAction.question,
      'escalate' => DecisionAction.escalate,
      'reject' => DecisionAction.reject,
      'defer' => DecisionAction.defer,
      'custom' => DecisionAction.custom,
      _ => DecisionAction.proceed,
    };
  }

  /// Whether this action allows proceeding.
  bool get allowsProceeding => this == DecisionAction.proceed ||
      this == DecisionAction.proceedWithCaution;

  /// Whether this action blocks proceeding.
  bool get blocksProceeding => this == DecisionAction.hold ||
      this == DecisionAction.reject ||
      this == DecisionAction.defer;

  /// Whether this action requires human intervention.
  bool get requiresHuman => this == DecisionAction.escalate ||
      this == DecisionAction.question;
}

// =============================================================================
// DecisionModifier (§5.2)
// =============================================================================

/// Additional modifier for a decision.
class DecisionModifier {
  /// Modifier type.
  final ModifierType type;

  /// Modifier configuration.
  final Map<String, dynamic>? config;

  const DecisionModifier({
    required this.type,
    this.config,
  });

  /// Get config value with type cast.
  T? getConfig<T>(String key) {
    if (config == null) return null;
    final value = config![key];
    if (value is T) return value;
    return null;
  }

  factory DecisionModifier.fromJson(Map<String, dynamic> json) {
    return DecisionModifier(
      type: ModifierType.values.firstWhere(
        (t) => t.name == _toEnumName(json['type'] as String),
        orElse: () => ModifierType.custom,
      ),
      config: json['config'] as Map<String, dynamic>?,
    );
  }

  static String _toEnumName(String name) {
    // Convert snake_case to camelCase
    final parts = name.split('_');
    return parts.first +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join('');
  }

  Map<String, dynamic> toJson() => {
        'type': type.toJsonName(),
        if (config != null) 'config': config,
      };

  /// Create require_evidence modifier.
  factory DecisionModifier.requireEvidence({
    int minSources = 1,
    List<String>? evidenceTypes,
  }) {
    return DecisionModifier(
      type: ModifierType.requireEvidence,
      config: {
        'minSources': minSources,
        if (evidenceTypes != null) 'evidenceTypes': evidenceTypes,
      },
    );
  }

  /// Create require_approval modifier.
  factory DecisionModifier.requireApproval({
    required String approverRole,
    String? expiresIn,
  }) {
    return DecisionModifier(
      type: ModifierType.requireApproval,
      config: {
        'approverRole': approverRole,
        if (expiresIn != null) 'expiresIn': expiresIn,
      },
    );
  }

  /// Create add_disclaimer modifier.
  factory DecisionModifier.addDisclaimer({
    required String text,
    String position = 'start',
  }) {
    return DecisionModifier(
      type: ModifierType.addDisclaimer,
      config: {
        'text': text,
        'position': position,
      },
    );
  }

  /// Create notify modifier.
  factory DecisionModifier.notify({
    required List<String> channels,
    required List<String> recipients,
    String? template,
    String urgency = 'normal',
  }) {
    return DecisionModifier(
      type: ModifierType.notify,
      config: {
        'channels': channels,
        'recipients': recipients,
        if (template != null) 'template': template,
        'urgency': urgency,
      },
    );
  }

  /// Create log modifier.
  factory DecisionModifier.log({
    String level = 'info',
  }) {
    return DecisionModifier(
      type: ModifierType.log,
      config: {
        'level': level,
      },
    );
  }
}

// =============================================================================
// ModifierType (§5.2)
// =============================================================================

/// Types of decision modifiers.
enum ModifierType {
  /// Need more evidence before proceeding.
  requireEvidence,

  /// Need human approval before proceeding.
  requireApproval,

  /// Include warning/disclaimer in output.
  addDisclaimer,

  /// Reduce scope of action.
  limitScope,

  /// Lower confidence in output.
  reduceConfidence,

  /// Add extra validation steps.
  increaseValidation,

  /// Send notification.
  notify,

  /// Enhanced logging.
  log,

  /// Application-specific modifier.
  custom,
}

extension ModifierTypeExtension on ModifierType {
  String toJsonName() {
    return switch (this) {
      ModifierType.requireEvidence => 'require_evidence',
      ModifierType.requireApproval => 'require_approval',
      ModifierType.addDisclaimer => 'add_disclaimer',
      ModifierType.limitScope => 'limit_scope',
      ModifierType.reduceConfidence => 'reduce_confidence',
      ModifierType.increaseValidation => 'increase_validation',
      ModifierType.notify => 'notify',
      ModifierType.log => 'log',
      ModifierType.custom => 'custom',
    };
  }
}
