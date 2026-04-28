/// Philosophy Port - Abstract interface for Philosophy (Ethos) operations.
///
/// Provides contracts for evaluating value systems, checking prohibitions,
/// applying pipeline interventions, detecting cross-layer tensions,
/// and proposing philosophy evolution through feedback.
///
/// This port is consumed by mcp_skill, mcp_profile, mcp_knowledge_ops,
/// and mcp_flow_runtime. The default adapter lives in mcp_philosophy.
library;

import 'package:meta/meta.dart';

// =============================================================================
// PhilosophyPort
// =============================================================================

/// Abstract port interface for Philosophy operations.
///
/// Defines the contract for evaluating an entity's value system (Ethos)
/// against runtime context. This is the primary integration point between
/// the Philosophy layer and all other MCP packages.
///
/// Implementations:
/// - PhilosophyAdapter (in mcp_philosophy) — default implementation
abstract class PhilosophyPort {
  /// Evaluate the current context against the active Ethos.
  ///
  /// Returns [PhilosophyGuidance] containing applied value priority,
  /// prohibition check results, recommended action, confidence score,
  /// and human-readable explanation.
  Future<PhilosophyGuidance> evaluate(PhilosophyEvaluationContext context);

  /// Check a proposed action or output against all prohibitions.
  ///
  /// Returns [ProhibitionCheckResult] with individual check results
  /// and hard/soft violation flags.
  Future<ProhibitionCheckResult> checkProhibitions(
    ProhibitionCheckRequest request,
  );

  /// Apply philosophy intervention at a pipeline stage.
  ///
  /// Returns [InterventionResult] describing all modifications applied.
  /// For [InterventionPoint.postGeneration], if a hard prohibition is
  /// violated, the result will have [InterventionResult.blocksDelivery] = true.
  Future<InterventionResult> intervene(
    InterventionPoint point,
    PipelineContext context,
  );

  /// Retrieve the currently active Ethos instance.
  ///
  /// Returns the full [Ethos] with all components (value priorities,
  /// prohibitions, judgment criteria, directional attitudes).
  Future<Ethos> getEthos();

  /// Detect tensions between Philosophy and other layers.
  ///
  /// Optional method. Default implementation throws [UnsupportedError].
  ///
  /// Returns a list of [Tension] objects describing conflicts between
  /// the active Ethos and the provided multi-layer context.
  Future<List<Tension>> detectTensions(MultiLayerContext context) {
    throw UnsupportedError('detectTensions is not supported by this adapter');
  }

  /// Generate an evolution proposal from action feedback.
  ///
  /// Optional method. Default implementation throws [UnsupportedError].
  ///
  /// Returns an [EvolutionProposal] if the feedback suggests a meaningful
  /// change, or null if no evolution is warranted.
  ///
  /// Proposals must NEVER be auto-applied. They are returned
  /// for human review and explicit approval.
  Future<EvolutionProposal?> proposeFeedback(FeedbackEvent event) {
    throw UnsupportedError('proposeFeedback is not supported by this adapter');
  }
}

// =============================================================================
// Core Models - Ethos and Components
// =============================================================================

/// Root philosophy definition containing all components.
@immutable
class Ethos {
  /// Unique identifier.
  final String id;

  /// Human-readable name.
  final String name;

  /// Ordered value priorities (rank 1 = highest).
  final List<ValuePriority> valuePriorities;

  /// Absolute boundaries with severity classification.
  final List<Prohibition> prohibitions;

  /// Conditional decision rules.
  final List<JudgmentCriterion> judgmentCriteria;

  /// Fundamental postures toward domains (uncertainty, failure, conflict).
  final List<DirectionalAttitude> directionalAttitudes;

  /// Version, author, timestamps, context.
  final EthosMetadata metadata;

  /// Domain-specific applicability scopes.
  final List<EthosScope>? scopes;

  const Ethos({
    required this.id,
    required this.name,
    required this.valuePriorities,
    required this.prohibitions,
    this.judgmentCriteria = const [],
    this.directionalAttitudes = const [],
    required this.metadata,
    this.scopes,
  });

  /// Get the highest-priority ValuePriority (rank 1).
  ValuePriority? get topPriority =>
      valuePriorities.isEmpty ? null : valuePriorities.first;

  /// Get all hard prohibitions.
  List<Prohibition> get hardProhibitions =>
      prohibitions
          .where((p) => p.severity == ProhibitionSeverity.hard)
          .toList();

  /// Get all soft prohibitions.
  List<Prohibition> get softProhibitions =>
      prohibitions
          .where((p) => p.severity == ProhibitionSeverity.soft)
          .toList();

  /// Check if this Ethos is scoped to a specific domain.
  bool isApplicableTo(String domain) =>
      scopes == null || scopes!.any((s) => s.domain == domain);

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'valuePriorities': valuePriorities.map((v) => v.toJson()).toList(),
      'prohibitions': prohibitions.map((p) => p.toJson()).toList(),
      'judgmentCriteria': judgmentCriteria.map((j) => j.toJson()).toList(),
      'directionalAttitudes':
          directionalAttitudes.map((d) => d.toJson()).toList(),
      'metadata': metadata.toJson(),
      if (scopes != null) 'scopes': scopes!.map((s) => s.toJson()).toList(),
    };
  }

  /// Create from JSON.
  factory Ethos.fromJson(Map<String, dynamic> json) {
    return Ethos(
      id: json['id'] as String,
      name: json['name'] as String,
      valuePriorities: (json['valuePriorities'] as List<dynamic>)
          .map((e) => ValuePriority.fromJson(e as Map<String, dynamic>))
          .toList(),
      prohibitions: (json['prohibitions'] as List<dynamic>)
          .map((e) => Prohibition.fromJson(e as Map<String, dynamic>))
          .toList(),
      judgmentCriteria: (json['judgmentCriteria'] as List<dynamic>?)
              ?.map((e) => JudgmentCriterion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      directionalAttitudes: (json['directionalAttitudes'] as List<dynamic>?)
              ?.map(
                  (e) => DirectionalAttitude.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      metadata:
          EthosMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      scopes: (json['scopes'] as List<dynamic>?)
          ?.map((e) => EthosScope.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Ordered principle for value conflict resolution.
@immutable
class ValuePriority {
  /// Unique identifier.
  final String id;

  /// Rank order (1 = highest priority).
  final int rank;

  /// Value that takes precedence.
  final String higherValue;

  /// Value that yields.
  final String lowerValue;

  /// Justification for this ordering.
  final String rationale;

  /// Context-dependent conditions for priority shifts.
  final List<String>? conditions;

  const ValuePriority({
    required this.id,
    required this.rank,
    required this.higherValue,
    required this.lowerValue,
    required this.rationale,
    this.conditions,
  });

  /// Whether this priority is context-dependent.
  bool get isConditional => conditions != null && conditions!.isNotEmpty;

  /// Human-readable format: "higherValue > lowerValue".
  String get display => '$higherValue > $lowerValue';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rank': rank,
      'higherValue': higherValue,
      'lowerValue': lowerValue,
      'rationale': rationale,
      if (conditions != null) 'conditions': conditions,
    };
  }

  factory ValuePriority.fromJson(Map<String, dynamic> json) {
    return ValuePriority(
      id: json['id'] as String,
      rank: json['rank'] as int,
      higherValue: json['higherValue'] as String,
      lowerValue: json['lowerValue'] as String,
      rationale: json['rationale'] as String,
      conditions: (json['conditions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

/// Absolute boundary with severity classification.
@immutable
class Prohibition {
  /// Unique identifier.
  final String id;

  /// The boundary statement.
  final String statement;

  /// hard = blocking, soft = warning.
  final ProhibitionSeverity severity;

  /// Why this boundary exists.
  final String rationale;

  /// Explicit exceptions to this prohibition.
  final List<ProhibitionException>? exceptions;

  const Prohibition({
    required this.id,
    required this.statement,
    required this.severity,
    required this.rationale,
    this.exceptions,
  });

  /// Whether this prohibition has explicit exceptions.
  bool get hasExceptions => exceptions != null && exceptions!.isNotEmpty;

  /// Whether this is a hard (blocking) prohibition.
  bool get isHard => severity == ProhibitionSeverity.hard;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'statement': statement,
      'severity': severity.name,
      'rationale': rationale,
      if (exceptions != null)
        'exceptions': exceptions!.map((e) => e.toJson()).toList(),
    };
  }

  factory Prohibition.fromJson(Map<String, dynamic> json) {
    return Prohibition(
      id: json['id'] as String,
      statement: json['statement'] as String,
      severity: ProhibitionSeverity.fromString(json['severity'] as String),
      rationale: json['rationale'] as String,
      exceptions: (json['exceptions'] as List<dynamic>?)
          ?.map((e) => ProhibitionException.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Exception condition for a prohibition.
@immutable
class ProhibitionException {
  /// When the exception applies.
  final String condition;

  /// Required justification for applying exception.
  final String justificationRequired;

  const ProhibitionException({
    required this.condition,
    required this.justificationRequired,
  });

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'justificationRequired': justificationRequired,
    };
  }

  factory ProhibitionException.fromJson(Map<String, dynamic> json) {
    return ProhibitionException(
      condition: json['condition'] as String,
      justificationRequired: json['justificationRequired'] as String,
    );
  }
}

/// Conditional decision rule with preferred action.
@immutable
class JudgmentCriterion {
  /// Unique identifier.
  final String id;

  /// Expression-language conditions.
  final List<String> conditions;

  /// What to do when conditions match.
  final String preferredAction;

  /// Additional validation needed.
  final String? requiredValidation;

  /// Fallback if preferred action fails.
  final String? fallbackStrategy;

  const JudgmentCriterion({
    required this.id,
    required this.conditions,
    required this.preferredAction,
    this.requiredValidation,
    this.fallbackStrategy,
  });

  /// Whether this criterion has a fallback.
  bool get hasFallback => fallbackStrategy != null;

  /// Whether additional validation is required.
  bool get requiresValidation => requiredValidation != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conditions': conditions,
      'preferredAction': preferredAction,
      if (requiredValidation != null) 'requiredValidation': requiredValidation,
      if (fallbackStrategy != null) 'fallbackStrategy': fallbackStrategy,
    };
  }

  factory JudgmentCriterion.fromJson(Map<String, dynamic> json) {
    return JudgmentCriterion(
      id: json['id'] as String,
      conditions: (json['conditions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      preferredAction: json['preferredAction'] as String,
      requiredValidation: json['requiredValidation'] as String?,
      fallbackStrategy: json['fallbackStrategy'] as String?,
    );
  }
}

/// Fundamental posture toward a domain.
@immutable
class DirectionalAttitude {
  /// Unique identifier.
  final String id;

  /// Domain of attitude applicability.
  final AttitudeDomain domain;

  /// Descriptive statement of the posture.
  final String posture;

  /// Concrete behavioral effects.
  final List<String> behavioralImplications;

  const DirectionalAttitude({
    required this.id,
    required this.domain,
    required this.posture,
    required this.behavioralImplications,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain': domain.name,
      'posture': posture,
      'behavioralImplications': behavioralImplications,
    };
  }

  factory DirectionalAttitude.fromJson(Map<String, dynamic> json) {
    return DirectionalAttitude(
      id: json['id'] as String,
      domain: AttitudeDomain.fromString(json['domain'] as String),
      posture: json['posture'] as String,
      behavioralImplications: (json['behavioralImplications'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}

/// Version, author, timestamps, context metadata for an Ethos.
@immutable
class EthosMetadata {
  /// Semantic version of this Ethos.
  final String version;

  /// Creator/maintainer.
  final String? author;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Usage context description.
  final String? context;

  /// Categorization tags.
  final List<String> tags;

  const EthosMetadata({
    required this.version,
    this.author,
    required this.createdAt,
    required this.updatedAt,
    this.context,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      if (author != null) 'author': author,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (context != null) 'context': context,
      if (tags.isNotEmpty) 'tags': tags,
    };
  }

  factory EthosMetadata.fromJson(Map<String, dynamic> json) {
    return EthosMetadata(
      version: json['version'] as String,
      author: json['author'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      context: json['context'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

/// Domain-specific applicability scope for an Ethos.
@immutable
class EthosScope {
  /// Domain this scope applies to.
  final String domain;

  /// Human-readable description.
  final String? description;

  /// Scope tags.
  final List<String>? tags;

  const EthosScope({
    required this.domain,
    this.description,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    return {
      'domain': domain,
      if (description != null) 'description': description,
      if (tags != null) 'tags': tags,
    };
  }

  factory EthosScope.fromJson(Map<String, dynamic> json) {
    return EthosScope(
      domain: json['domain'] as String,
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

// =============================================================================
// Core Enums
// =============================================================================

/// Severity of a prohibition: hard = blocking, soft = warning.
enum ProhibitionSeverity {
  hard,
  soft,
  unknown;

  static ProhibitionSeverity fromString(String value) {
    return ProhibitionSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProhibitionSeverity.unknown,
    );
  }
}

/// Domain of attitude applicability.
enum AttitudeDomain {
  uncertainty,
  failure,
  conflict,
  unknownDomain;

  static AttitudeDomain fromString(String value) {
    return AttitudeDomain.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AttitudeDomain.unknownDomain,
    );
  }
}

// =============================================================================
// Evaluation Models
// =============================================================================

/// Result of evaluating an Ethos against a context.
@immutable
class PhilosophyGuidance {
  /// Which value priority was invoked.
  final ValuePriority? valuePriorityApplied;

  /// Pass/fail for all prohibitions.
  final ProhibitionCheckResult prohibitionChecks;

  /// Applicable judgment criteria.
  final List<MatchedCriterion> matchedCriteria;

  /// Resolved directional attitude.
  final DirectionalAttitude? directionalAttitude;

  /// What action to take.
  final String recommendedAction;

  /// Confidence score (0.0-1.0).
  final double confidence;

  /// Human-readable explanation.
  final String explanation;

  /// Whether any hard prohibition was violated.
  final bool prohibitionViolated;

  const PhilosophyGuidance({
    this.valuePriorityApplied,
    required this.prohibitionChecks,
    this.matchedCriteria = const [],
    this.directionalAttitude,
    required this.recommendedAction,
    required this.confidence,
    required this.explanation,
    required this.prohibitionViolated,
  });

  /// Whether this guidance allows proceeding.
  bool get allowsProceeding => !prohibitionViolated;

  /// Whether this guidance has conflict annotations.
  bool get hasConflicts => matchedCriteria.any((c) => c.hasConflict);

  Map<String, dynamic> toJson() {
    return {
      if (valuePriorityApplied != null)
        'valuePriorityApplied': valuePriorityApplied!.toJson(),
      'prohibitionChecks': prohibitionChecks.toJson(),
      'matchedCriteria': matchedCriteria.map((m) => m.toJson()).toList(),
      if (directionalAttitude != null)
        'directionalAttitude': directionalAttitude!.toJson(),
      'recommendedAction': recommendedAction,
      'confidence': confidence,
      'explanation': explanation,
      'prohibitionViolated': prohibitionViolated,
    };
  }

  factory PhilosophyGuidance.fromJson(Map<String, dynamic> json) {
    return PhilosophyGuidance(
      valuePriorityApplied: json['valuePriorityApplied'] != null
          ? ValuePriority.fromJson(
              json['valuePriorityApplied'] as Map<String, dynamic>)
          : null,
      prohibitionChecks: ProhibitionCheckResult.fromJson(
          json['prohibitionChecks'] as Map<String, dynamic>),
      matchedCriteria: (json['matchedCriteria'] as List<dynamic>?)
              ?.map((e) => MatchedCriterion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      directionalAttitude: json['directionalAttitude'] != null
          ? DirectionalAttitude.fromJson(
              json['directionalAttitude'] as Map<String, dynamic>)
          : null,
      recommendedAction: json['recommendedAction'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      explanation: json['explanation'] as String,
      prohibitionViolated: json['prohibitionViolated'] as bool,
    );
  }
}

/// Context for philosophy evaluation.
///
/// Named [PhilosophyEvaluationContext] to avoid conflict with
/// the expression language's EvaluationContext.
@immutable
class PhilosophyEvaluationContext {
  /// Context identifier.
  final String contextId;

  /// Relevant facts from FactGraph.
  final Map<String, dynamic> facts;

  /// Relevant metrics.
  final Map<String, double> metrics;

  /// Action/output to evaluate (for prohibition checks).
  final String? proposedAction;

  /// Generated output to evaluate (post-generation).
  final String? proposedOutput;

  /// Current profile state (for tension detection).
  final Map<String, dynamic>? profileState;

  /// Current dynamic state weights (for intensity adjustment).
  final Map<String, dynamic>? stateWeighting;

  /// Evaluation timestamp.
  final DateTime evaluatedAt;

  PhilosophyEvaluationContext({
    required this.contextId,
    this.facts = const {},
    this.metrics = const {},
    this.proposedAction,
    this.proposedOutput,
    this.profileState,
    this.stateWeighting,
    DateTime? evaluatedAt,
  }) : evaluatedAt = evaluatedAt ?? DateTime.now();

  /// Whether this context has a proposed output to check.
  bool get hasProposedOutput => proposedOutput != null;

  /// Whether this context has profile state for tension detection.
  bool get hasProfileState => profileState != null;

  /// Get a fact value by key.
  dynamic getFact(String key) => facts[key];

  /// Get a metric value by key.
  double? getMetric(String key) => metrics[key];

  Map<String, dynamic> toJson() {
    return {
      'contextId': contextId,
      'facts': facts,
      'metrics': metrics,
      if (proposedAction != null) 'proposedAction': proposedAction,
      if (proposedOutput != null) 'proposedOutput': proposedOutput,
      if (profileState != null) 'profileState': profileState,
      if (stateWeighting != null) 'stateWeighting': stateWeighting,
      'evaluatedAt': evaluatedAt.toIso8601String(),
    };
  }

  factory PhilosophyEvaluationContext.fromJson(Map<String, dynamic> json) {
    return PhilosophyEvaluationContext(
      contextId: json['contextId'] as String,
      facts: json['facts'] as Map<String, dynamic>? ?? const {},
      metrics: (json['metrics'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble())) ??
          const {},
      proposedAction: json['proposedAction'] as String?,
      proposedOutput: json['proposedOutput'] as String?,
      profileState: json['profileState'] as Map<String, dynamic>?,
      stateWeighting: json['stateWeighting'] as Map<String, dynamic>?,
      evaluatedAt: json['evaluatedAt'] != null
          ? DateTime.parse(json['evaluatedAt'] as String)
          : null,
    );
  }
}

/// Request to check prohibitions.
@immutable
class ProhibitionCheckRequest {
  /// Action description to check.
  final String? proposedAction;

  /// Output text to check.
  final String? proposedOutput;

  /// Additional context.
  final Map<String, dynamic> context;

  /// Request timestamp.
  final DateTime requestedAt;

  ProhibitionCheckRequest({
    this.proposedAction,
    this.proposedOutput,
    this.context = const {},
    DateTime? requestedAt,
  }) : requestedAt = requestedAt ?? DateTime.now();

  /// At least one of proposedAction or proposedOutput must be provided.
  bool get isValid => proposedAction != null || proposedOutput != null;

  Map<String, dynamic> toJson() {
    return {
      if (proposedAction != null) 'proposedAction': proposedAction,
      if (proposedOutput != null) 'proposedOutput': proposedOutput,
      if (context.isNotEmpty) 'context': context,
      'requestedAt': requestedAt.toIso8601String(),
    };
  }

  factory ProhibitionCheckRequest.fromJson(Map<String, dynamic> json) {
    return ProhibitionCheckRequest(
      proposedAction: json['proposedAction'] as String?,
      proposedOutput: json['proposedOutput'] as String?,
      context: json['context'] as Map<String, dynamic>? ?? const {},
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'] as String)
          : null,
    );
  }
}

/// Result of prohibition checks.
@immutable
class ProhibitionCheckResult {
  /// Individual check results.
  final List<ProhibitionCheck> checks;

  /// Whether any hard prohibition was violated.
  final bool hasHardViolation;

  /// IDs of violated hard prohibitions.
  final List<String> hardViolationIds;

  /// IDs of violated soft prohibitions.
  final List<String> softViolationIds;

  const ProhibitionCheckResult({
    required this.checks,
    required this.hasHardViolation,
    this.hardViolationIds = const [],
    this.softViolationIds = const [],
  });

  /// Factory for all-pass result.
  factory ProhibitionCheckResult.allPassed(List<ProhibitionCheck> checks) {
    return ProhibitionCheckResult(
      checks: checks,
      hasHardViolation: false,
    );
  }

  /// Get only violated checks.
  List<ProhibitionCheck> get violations =>
      checks.where((c) => c.violated).toList();

  Map<String, dynamic> toJson() {
    return {
      'checks': checks.map((c) => c.toJson()).toList(),
      'hasHardViolation': hasHardViolation,
      'hardViolationIds': hardViolationIds,
      'softViolationIds': softViolationIds,
    };
  }

  factory ProhibitionCheckResult.fromJson(Map<String, dynamic> json) {
    return ProhibitionCheckResult(
      checks: (json['checks'] as List<dynamic>)
          .map((e) => ProhibitionCheck.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasHardViolation: json['hasHardViolation'] as bool,
      hardViolationIds: (json['hardViolationIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      softViolationIds: (json['softViolationIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

/// Individual prohibition check result.
@immutable
class ProhibitionCheck {
  /// ID of the checked prohibition.
  final String prohibitionId;

  /// Whether the prohibition was violated.
  final bool violated;

  /// Severity of the prohibition.
  final ProhibitionSeverity severity;

  /// Detail of the violation.
  final String? violationDetail;

  /// Whether an exception was applied.
  final bool exceptionApplied;

  /// Condition of the applied exception.
  final String? appliedExceptionCondition;

  const ProhibitionCheck({
    required this.prohibitionId,
    required this.violated,
    required this.severity,
    this.violationDetail,
    this.exceptionApplied = false,
    this.appliedExceptionCondition,
  });

  Map<String, dynamic> toJson() {
    return {
      'prohibitionId': prohibitionId,
      'violated': violated,
      'severity': severity.name,
      if (violationDetail != null) 'violationDetail': violationDetail,
      'exceptionApplied': exceptionApplied,
      if (appliedExceptionCondition != null)
        'appliedExceptionCondition': appliedExceptionCondition,
    };
  }

  factory ProhibitionCheck.fromJson(Map<String, dynamic> json) {
    return ProhibitionCheck(
      prohibitionId: json['prohibitionId'] as String,
      violated: json['violated'] as bool,
      severity: ProhibitionSeverity.fromString(json['severity'] as String),
      violationDetail: json['violationDetail'] as String?,
      exceptionApplied: json['exceptionApplied'] as bool? ?? false,
      appliedExceptionCondition:
          json['appliedExceptionCondition'] as String?,
    );
  }
}

/// Matched judgment criterion result.
@immutable
class MatchedCriterion {
  /// ID of the matched criterion.
  final String criterionId;

  /// Preferred action from the criterion.
  final String preferredAction;

  /// How strongly conditions matched (0.0-1.0).
  final double matchStrength;

  /// Whether this conflicts with another matched criterion.
  final bool hasConflict;

  /// ID of conflicting criterion.
  final String? conflictWith;

  /// Description of the conflict.
  final String? conflictAnnotation;

  const MatchedCriterion({
    required this.criterionId,
    required this.preferredAction,
    required this.matchStrength,
    this.hasConflict = false,
    this.conflictWith,
    this.conflictAnnotation,
  });

  Map<String, dynamic> toJson() {
    return {
      'criterionId': criterionId,
      'preferredAction': preferredAction,
      'matchStrength': matchStrength,
      'hasConflict': hasConflict,
      if (conflictWith != null) 'conflictWith': conflictWith,
      if (conflictAnnotation != null)
        'conflictAnnotation': conflictAnnotation,
    };
  }

  factory MatchedCriterion.fromJson(Map<String, dynamic> json) {
    return MatchedCriterion(
      criterionId: json['criterionId'] as String,
      preferredAction: json['preferredAction'] as String,
      matchStrength: (json['matchStrength'] as num).toDouble(),
      hasConflict: json['hasConflict'] as bool? ?? false,
      conflictWith: json['conflictWith'] as String?,
      conflictAnnotation: json['conflictAnnotation'] as String?,
    );
  }
}

/// Value conflict resolution result.
@immutable
class ValueResolution {
  /// The winning value priority.
  final ValuePriority winner;

  /// The losing value priority.
  final ValuePriority? loser;

  /// Why this resolution was chosen.
  final String rationale;

  /// Whether a conditional priority shift was applied.
  final bool contextDependent;

  /// Which condition triggered the shift.
  final String? appliedCondition;

  const ValueResolution({
    required this.winner,
    this.loser,
    required this.rationale,
    this.contextDependent = false,
    this.appliedCondition,
  });

  Map<String, dynamic> toJson() {
    return {
      'winner': winner.toJson(),
      if (loser != null) 'loser': loser!.toJson(),
      'rationale': rationale,
      'contextDependent': contextDependent,
      if (appliedCondition != null) 'appliedCondition': appliedCondition,
    };
  }

  factory ValueResolution.fromJson(Map<String, dynamic> json) {
    return ValueResolution(
      winner: ValuePriority.fromJson(json['winner'] as Map<String, dynamic>),
      loser: json['loser'] != null
          ? ValuePriority.fromJson(json['loser'] as Map<String, dynamic>)
          : null,
      rationale: json['rationale'] as String,
      contextDependent: json['contextDependent'] as bool? ?? false,
      appliedCondition: json['appliedCondition'] as String?,
    );
  }
}

// =============================================================================
// Intervention Models
// =============================================================================

/// Pipeline stage for philosophy intervention.
enum InterventionPoint {
  /// Before generation: filter knowledge, select approach, activate posture.
  preGeneration,

  /// During generation: re-rank candidates, adjust expression, modify structure.
  duringGeneration,

  /// After generation: check prohibitions, verify evidence, align tone.
  postGeneration,

  /// Forward compatibility.
  unknown;

  static InterventionPoint fromString(String value) {
    return InterventionPoint.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InterventionPoint.unknown,
    );
  }
}

/// Pipeline data for intervention.
@immutable
class PipelineContext {
  /// Pipeline identifier.
  final String pipelineId;

  /// Current intervention stage.
  final InterventionPoint currentPoint;

  /// FactGraph data retrieved.
  final Map<String, dynamic> knowledgeRetrieved;

  /// During-generation candidate responses.
  final List<String>? candidateResponses;

  /// Post-generation output.
  final String? generatedOutput;

  /// Current skill state.
  final Map<String, dynamic>? skillContext;

  /// Current profile state.
  final Map<String, dynamic>? profileContext;

  /// Dynamic state weights.
  final Map<String, double>? stateWeighting;

  /// Timestamp.
  final DateTime timestamp;

  PipelineContext({
    required this.pipelineId,
    required this.currentPoint,
    this.knowledgeRetrieved = const {},
    this.candidateResponses,
    this.generatedOutput,
    this.skillContext,
    this.profileContext,
    this.stateWeighting,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'pipelineId': pipelineId,
      'currentPoint': currentPoint.name,
      'knowledgeRetrieved': knowledgeRetrieved,
      if (candidateResponses != null) 'candidateResponses': candidateResponses,
      if (generatedOutput != null) 'generatedOutput': generatedOutput,
      if (skillContext != null) 'skillContext': skillContext,
      if (profileContext != null) 'profileContext': profileContext,
      if (stateWeighting != null) 'stateWeighting': stateWeighting,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PipelineContext.fromJson(Map<String, dynamic> json) {
    return PipelineContext(
      pipelineId: json['pipelineId'] as String,
      currentPoint:
          InterventionPoint.fromString(json['currentPoint'] as String),
      knowledgeRetrieved:
          json['knowledgeRetrieved'] as Map<String, dynamic>? ?? const {},
      candidateResponses: (json['candidateResponses'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      generatedOutput: json['generatedOutput'] as String?,
      skillContext: json['skillContext'] as Map<String, dynamic>?,
      profileContext: json['profileContext'] as Map<String, dynamic>?,
      stateWeighting: (json['stateWeighting'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }
}

/// Result of a pipeline intervention.
@immutable
class InterventionResult {
  /// Which pipeline stage was intervened.
  final InterventionPoint point;

  /// List of applied interventions.
  final List<AppliedIntervention> interventions;

  /// Whether a hard prohibition was violated.
  final bool prohibitionViolated;

  /// IDs of violated prohibitions.
  final List<String> prohibitionViolationIds;

  /// Whether pipeline data was modified.
  final bool modified;

  /// Description of what changed.
  final Map<String, dynamic>? modifications;

  /// Timestamp of intervention.
  final DateTime appliedAt;

  InterventionResult({
    required this.point,
    this.interventions = const [],
    this.prohibitionViolated = false,
    this.prohibitionViolationIds = const [],
    this.modified = false,
    this.modifications,
    DateTime? appliedAt,
  }) : appliedAt = appliedAt ?? DateTime.now();

  /// Factory for no-operation result.
  factory InterventionResult.noOp() {
    return InterventionResult(point: InterventionPoint.unknown);
  }

  /// Whether any intervention was applied.
  bool get hasInterventions => interventions.isNotEmpty;

  /// Whether this result blocks the pipeline.
  bool get blocksDelivery => prohibitionViolated;

  Map<String, dynamic> toJson() {
    return {
      'point': point.name,
      'interventions': interventions.map((i) => i.toJson()).toList(),
      'prohibitionViolated': prohibitionViolated,
      'prohibitionViolationIds': prohibitionViolationIds,
      'modified': modified,
      if (modifications != null) 'modifications': modifications,
      'appliedAt': appliedAt.toIso8601String(),
    };
  }

  factory InterventionResult.fromJson(Map<String, dynamic> json) {
    return InterventionResult(
      point: InterventionPoint.fromString(json['point'] as String),
      interventions: (json['interventions'] as List<dynamic>?)
              ?.map((e) =>
                  AppliedIntervention.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      prohibitionViolated: json['prohibitionViolated'] as bool? ?? false,
      prohibitionViolationIds:
          (json['prohibitionViolationIds'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [],
      modified: json['modified'] as bool? ?? false,
      modifications: json['modifications'] as Map<String, dynamic>?,
      appliedAt: json['appliedAt'] != null
          ? DateTime.parse(json['appliedAt'] as String)
          : null,
    );
  }
}

/// Individual intervention applied during pipeline processing.
@immutable
class AppliedIntervention {
  /// Unique identifier.
  final String id;

  /// Type of intervention.
  final InterventionType type;

  /// What was done.
  final String description;

  /// Why (linked to ethos component).
  final String rationale;

  /// Which value/prohibition/criterion triggered this.
  final String? ethosComponentId;

  /// State before intervention.
  final Map<String, dynamic>? before;

  /// State after intervention.
  final Map<String, dynamic>? after;

  const AppliedIntervention({
    required this.id,
    required this.type,
    required this.description,
    required this.rationale,
    this.ethosComponentId,
    this.before,
    this.after,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'rationale': rationale,
      if (ethosComponentId != null) 'ethosComponentId': ethosComponentId,
      if (before != null) 'before': before,
      if (after != null) 'after': after,
    };
  }

  factory AppliedIntervention.fromJson(Map<String, dynamic> json) {
    return AppliedIntervention(
      id: json['id'] as String,
      type: InterventionType.fromString(json['type'] as String),
      description: json['description'] as String,
      rationale: json['rationale'] as String,
      ethosComponentId: json['ethosComponentId'] as String?,
      before: json['before'] as Map<String, dynamic>?,
      after: json['after'] as Map<String, dynamic>?,
    );
  }
}

/// Types of pipeline intervention.
enum InterventionType {
  // Pre-generation
  knowledgeFilter,
  knowledgeRank,
  skillSelection,
  profileActivation,

  // During-generation
  candidateReRank,
  expressionAdjust,
  structureModify,

  // Post-generation
  prohibitionBlock,
  prohibitionWarn,
  evidenceVerify,
  toneAlign,

  // Forward compatibility
  unknown;

  static InterventionType fromString(String value) {
    return InterventionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InterventionType.unknown,
    );
  }
}

// =============================================================================
// Tension Models
// =============================================================================

/// Detected tension between Philosophy and another layer.
@immutable
class Tension {
  /// Unique identifier.
  final String id;

  /// Which layers are in conflict.
  final TensionSource source;

  /// What philosophy says.
  final String philosophyDirective;

  /// What the other layer says.
  final String opposingDirective;

  /// How serious the conflict is.
  final TensionSeverity severity;

  /// Human-readable description.
  final String description;

  /// Possible resolutions.
  final List<ResolutionOption> resolutionOptions;

  /// Which ethos component is involved.
  final String? ethosComponentId;

  /// When the tension was detected.
  final DateTime detectedAt;

  Tension({
    required this.id,
    required this.source,
    required this.philosophyDirective,
    required this.opposingDirective,
    required this.severity,
    required this.description,
    this.resolutionOptions = const [],
    this.ethosComponentId,
    DateTime? detectedAt,
  }) : detectedAt = detectedAt ?? DateTime.now();

  /// Whether this tension requires immediate resolution.
  bool get isCritical => severity == TensionSeverity.critical;

  /// Whether this tension has available resolution options.
  bool get isResolvable => resolutionOptions.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source.toJson(),
      'philosophyDirective': philosophyDirective,
      'opposingDirective': opposingDirective,
      'severity': severity.name,
      'description': description,
      'resolutionOptions':
          resolutionOptions.map((r) => r.toJson()).toList(),
      if (ethosComponentId != null) 'ethosComponentId': ethosComponentId,
      'detectedAt': detectedAt.toIso8601String(),
    };
  }

  factory Tension.fromJson(Map<String, dynamic> json) {
    return Tension(
      id: json['id'] as String,
      source:
          TensionSource.fromJson(json['source'] as Map<String, dynamic>),
      philosophyDirective: json['philosophyDirective'] as String,
      opposingDirective: json['opposingDirective'] as String,
      severity: TensionSeverity.fromString(json['severity'] as String),
      description: json['description'] as String,
      resolutionOptions: (json['resolutionOptions'] as List<dynamic>?)
              ?.map((e) =>
                  ResolutionOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      ethosComponentId: json['ethosComponentId'] as String?,
      detectedAt: json['detectedAt'] != null
          ? DateTime.parse(json['detectedAt'] as String)
          : null,
    );
  }
}

/// Source of a tension (which layers are in conflict).
@immutable
class TensionSource {
  /// Always philosophy.
  final TensionLayer primaryLayer;

  /// The opposing layer: profile, knowledge, or state.
  final TensionLayer opposingLayer;

  /// Specific ethos component ID.
  final String? primaryComponentId;

  /// Specific opposing component ID.
  final String? opposingComponentId;

  const TensionSource({
    this.primaryLayer = TensionLayer.philosophy,
    required this.opposingLayer,
    this.primaryComponentId,
    this.opposingComponentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'primaryLayer': primaryLayer.name,
      'opposingLayer': opposingLayer.name,
      if (primaryComponentId != null)
        'primaryComponentId': primaryComponentId,
      if (opposingComponentId != null)
        'opposingComponentId': opposingComponentId,
    };
  }

  factory TensionSource.fromJson(Map<String, dynamic> json) {
    return TensionSource(
      primaryLayer:
          TensionLayer.fromString(json['primaryLayer'] as String? ?? 'philosophy'),
      opposingLayer:
          TensionLayer.fromString(json['opposingLayer'] as String),
      primaryComponentId: json['primaryComponentId'] as String?,
      opposingComponentId: json['opposingComponentId'] as String?,
    );
  }
}

/// Resolution of a detected tension.
@immutable
class TensionResolution {
  /// ID of the resolved tension.
  final String tensionId;

  /// Strategy used for resolution.
  final ResolutionStrategy strategy;

  /// Description of resolution outcome.
  final String outcome;

  /// Confidence in the resolution (0.0-1.0).
  final double confidence;

  /// Changes applied.
  final Map<String, dynamic>? adjustments;

  /// When the tension was resolved.
  final DateTime resolvedAt;

  TensionResolution({
    required this.tensionId,
    required this.strategy,
    required this.outcome,
    required this.confidence,
    this.adjustments,
    DateTime? resolvedAt,
  }) : resolvedAt = resolvedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'tensionId': tensionId,
      'strategy': strategy.name,
      'outcome': outcome,
      'confidence': confidence,
      if (adjustments != null) 'adjustments': adjustments,
      'resolvedAt': resolvedAt.toIso8601String(),
    };
  }

  factory TensionResolution.fromJson(Map<String, dynamic> json) {
    return TensionResolution(
      tensionId: json['tensionId'] as String,
      strategy:
          ResolutionStrategy.fromString(json['strategy'] as String),
      outcome: json['outcome'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      adjustments: json['adjustments'] as Map<String, dynamic>?,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
    );
  }
}

/// Available resolution option for a tension.
@immutable
class ResolutionOption {
  /// Strategy for this option.
  final ResolutionStrategy strategy;

  /// Description of this option.
  final String description;

  /// Expected confidence of this resolution.
  final double estimatedConfidence;

  const ResolutionOption({
    required this.strategy,
    required this.description,
    required this.estimatedConfidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'strategy': strategy.name,
      'description': description,
      'estimatedConfidence': estimatedConfidence,
    };
  }

  factory ResolutionOption.fromJson(Map<String, dynamic> json) {
    return ResolutionOption(
      strategy:
          ResolutionStrategy.fromString(json['strategy'] as String),
      description: json['description'] as String,
      estimatedConfidence:
          (json['estimatedConfidence'] as num).toDouble(),
    );
  }
}

/// Multi-layer context for tension detection.
@immutable
class MultiLayerContext {
  /// Philosophy layer state.
  final PhilosophyEvaluationContext philosophyContext;

  /// Profile layer state.
  final Map<String, dynamic>? profileState;

  /// State/weighting layer.
  final Map<String, dynamic>? stateWeighting;

  /// Knowledge provenance.
  final Map<String, dynamic>? knowledgeProvenance;

  /// Assembly timestamp.
  final DateTime assembledAt;

  MultiLayerContext({
    required this.philosophyContext,
    this.profileState,
    this.stateWeighting,
    this.knowledgeProvenance,
    DateTime? assembledAt,
  }) : assembledAt = assembledAt ?? DateTime.now();

  /// Whether profile state is available for tension detection.
  bool get hasProfileState =>
      profileState != null && profileState!.isNotEmpty;

  /// Whether knowledge provenance is available.
  bool get hasKnowledgeProvenance =>
      knowledgeProvenance != null && knowledgeProvenance!.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'philosophyContext': philosophyContext.toJson(),
      if (profileState != null) 'profileState': profileState,
      if (stateWeighting != null) 'stateWeighting': stateWeighting,
      if (knowledgeProvenance != null)
        'knowledgeProvenance': knowledgeProvenance,
      'assembledAt': assembledAt.toIso8601String(),
    };
  }

  factory MultiLayerContext.fromJson(Map<String, dynamic> json) {
    return MultiLayerContext(
      philosophyContext: PhilosophyEvaluationContext.fromJson(
          json['philosophyContext'] as Map<String, dynamic>),
      profileState: json['profileState'] as Map<String, dynamic>?,
      stateWeighting: json['stateWeighting'] as Map<String, dynamic>?,
      knowledgeProvenance:
          json['knowledgeProvenance'] as Map<String, dynamic>?,
      assembledAt: json['assembledAt'] != null
          ? DateTime.parse(json['assembledAt'] as String)
          : null,
    );
  }
}

/// Severity of a tension.
enum TensionSeverity {
  low,
  medium,
  high,
  critical,
  unknown;

  static TensionSeverity fromString(String value) {
    return TensionSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TensionSeverity.unknown,
    );
  }
}

/// Which layer is involved in a tension.
enum TensionLayer {
  philosophy,
  profile,
  knowledge,
  state,
  unknown;

  static TensionLayer fromString(String value) {
    return TensionLayer.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TensionLayer.unknown,
    );
  }
}

/// Strategy for resolving a tension.
enum ResolutionStrategy {
  philosophyWins,
  compromise,
  contextDependent,
  defer,
  unknown;

  static ResolutionStrategy fromString(String value) {
    return ResolutionStrategy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ResolutionStrategy.unknown,
    );
  }
}

// =============================================================================
// Evolution Models
// =============================================================================

/// Action result feedback for philosophy evolution.
@immutable
class FeedbackEvent {
  /// Unique identifier.
  final String id;

  /// Action that produced the outcome.
  final String actionId;

  /// Ethos that was active.
  final String ethosId;

  /// Which value priority was applied.
  final String? valuePriorityId;

  /// Which criterion was applied.
  final String? judgmentCriterionId;

  /// Outcome classification.
  final FeedbackOutcome outcome;

  /// Outcome score (-1.0 to 1.0).
  final double outcomeScore;

  /// Human-readable outcome description.
  final String? outcomeDescription;

  /// Context snapshot at time of action.
  final Map<String, dynamic>? contextSnapshot;

  /// When the outcome occurred.
  final DateTime occurredAt;

  FeedbackEvent({
    required this.id,
    required this.actionId,
    required this.ethosId,
    this.valuePriorityId,
    this.judgmentCriterionId,
    required this.outcome,
    required this.outcomeScore,
    this.outcomeDescription,
    this.contextSnapshot,
    DateTime? occurredAt,
  }) : occurredAt = occurredAt ?? DateTime.now();

  /// Whether this feedback is linked to a specific value priority.
  bool get hasValuePriorityLink => valuePriorityId != null;

  /// Whether this feedback is linked to a specific judgment criterion.
  bool get hasCriterionLink => judgmentCriterionId != null;

  /// Whether this is a positive outcome.
  bool get isPositive => outcome == FeedbackOutcome.positive;

  /// Whether this is a negative outcome.
  bool get isNegative => outcome == FeedbackOutcome.negative;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionId': actionId,
      'ethosId': ethosId,
      if (valuePriorityId != null) 'valuePriorityId': valuePriorityId,
      if (judgmentCriterionId != null)
        'judgmentCriterionId': judgmentCriterionId,
      'outcome': outcome.name,
      'outcomeScore': outcomeScore,
      if (outcomeDescription != null)
        'outcomeDescription': outcomeDescription,
      if (contextSnapshot != null) 'contextSnapshot': contextSnapshot,
      'occurredAt': occurredAt.toIso8601String(),
    };
  }

  factory FeedbackEvent.fromJson(Map<String, dynamic> json) {
    return FeedbackEvent(
      id: json['id'] as String,
      actionId: json['actionId'] as String,
      ethosId: json['ethosId'] as String,
      valuePriorityId: json['valuePriorityId'] as String?,
      judgmentCriterionId: json['judgmentCriterionId'] as String?,
      outcome: FeedbackOutcome.fromString(json['outcome'] as String),
      outcomeScore: (json['outcomeScore'] as num).toDouble(),
      outcomeDescription: json['outcomeDescription'] as String?,
      contextSnapshot: json['contextSnapshot'] as Map<String, dynamic>?,
      occurredAt: json['occurredAt'] != null
          ? DateTime.parse(json['occurredAt'] as String)
          : null,
    );
  }
}

/// Outcome classification for feedback.
enum FeedbackOutcome {
  positive,
  negative,
  neutral,
  mixed,
  unknown;

  static FeedbackOutcome fromString(String value) {
    return FeedbackOutcome.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FeedbackOutcome.unknown,
    );
  }
}

/// Proposed change to an Ethos based on feedback patterns.
@immutable
class EvolutionProposal {
  /// Unique identifier.
  final String id;

  /// Target Ethos.
  final String ethosId;

  /// Type of evolution.
  final EvolutionType type;

  /// Which ethos component to modify.
  final String targetComponentId;

  /// Component type: "valuePriority", "judgmentCriterion", etc.
  final String targetComponentType;

  /// What change is proposed.
  final String description;

  /// Why this change is proposed.
  final String rationale;

  /// FeedbackEvent IDs supporting this proposal.
  final List<String> supportingFeedbackIds;

  /// Confidence in the proposal (0.0-1.0).
  final double confidence;

  /// Specific change details.
  final ProposedChange? proposedChange;

  /// Current status.
  final ProposalStatus status;

  /// When the proposal was created.
  final DateTime proposedAt;

  EvolutionProposal({
    required this.id,
    required this.ethosId,
    required this.type,
    required this.targetComponentId,
    required this.targetComponentType,
    required this.description,
    required this.rationale,
    this.supportingFeedbackIds = const [],
    required this.confidence,
    this.proposedChange,
    this.status = ProposalStatus.pending,
    DateTime? proposedAt,
  }) : proposedAt = proposedAt ?? DateTime.now();

  /// Whether this proposal has sufficient confidence (>= 0.7).
  bool get hasSufficientConfidence => confidence >= 0.7;

  /// Whether this proposal is still pending review.
  bool get isPending => status == ProposalStatus.pending;

  /// Number of supporting feedback events.
  int get supportCount => supportingFeedbackIds.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ethosId': ethosId,
      'type': type.name,
      'targetComponentId': targetComponentId,
      'targetComponentType': targetComponentType,
      'description': description,
      'rationale': rationale,
      'supportingFeedbackIds': supportingFeedbackIds,
      'confidence': confidence,
      if (proposedChange != null) 'proposedChange': proposedChange!.toJson(),
      'status': status.name,
      'proposedAt': proposedAt.toIso8601String(),
    };
  }

  factory EvolutionProposal.fromJson(Map<String, dynamic> json) {
    return EvolutionProposal(
      id: json['id'] as String,
      ethosId: json['ethosId'] as String,
      type: EvolutionType.fromString(json['type'] as String),
      targetComponentId: json['targetComponentId'] as String,
      targetComponentType: json['targetComponentType'] as String,
      description: json['description'] as String,
      rationale: json['rationale'] as String,
      supportingFeedbackIds:
          (json['supportingFeedbackIds'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [],
      confidence: (json['confidence'] as num).toDouble(),
      proposedChange: json['proposedChange'] != null
          ? ProposedChange.fromJson(
              json['proposedChange'] as Map<String, dynamic>)
          : null,
      status: ProposalStatus.fromString(
          json['status'] as String? ?? 'pending'),
      proposedAt: json['proposedAt'] != null
          ? DateTime.parse(json['proposedAt'] as String)
          : null,
    );
  }
}

/// Specific change details for an evolution proposal.
@immutable
class ProposedChange {
  /// Current state (for audit).
  final Map<String, dynamic>? before;

  /// Proposed state.
  final Map<String, dynamic>? after;

  /// Human-readable diff description.
  final String? diff;

  const ProposedChange({
    this.before,
    this.after,
    this.diff,
  });

  Map<String, dynamic> toJson() {
    return {
      if (before != null) 'before': before,
      if (after != null) 'after': after,
      if (diff != null) 'diff': diff,
    };
  }

  factory ProposedChange.fromJson(Map<String, dynamic> json) {
    return ProposedChange(
      before: json['before'] as Map<String, dynamic>?,
      after: json['after'] as Map<String, dynamic>?,
      diff: json['diff'] as String?,
    );
  }
}

/// Type of evolution.
enum EvolutionType {
  reinforce,
  weaken,
  refine,
  add,
  remove,
  unknown;

  static EvolutionType fromString(String value) {
    return EvolutionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EvolutionType.unknown,
    );
  }
}

/// Status of an evolution proposal.
enum ProposalStatus {
  pending,
  approved,
  rejected,
  applied,
  unknown;

  static ProposalStatus fromString(String value) {
    return ProposalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProposalStatus.unknown,
    );
  }
}

// =============================================================================
// State Integration Models
// =============================================================================

/// Dynamic adjustment factors for philosophy execution intensity.
///
/// Philosophy provides stable direction (value ordering, prohibitions).
/// StateWeighting adjusts intensity (how urgently, how cautiously)
/// without changing direction.
@immutable
class StateWeighting {
  /// 0.0 = no urgency, 1.0 = critical deadline.
  final double urgency;

  /// 0.0 = risk-tolerant, 1.0 = risk-averse.
  final double riskSensitivity;

  /// 0.0 = uncertain context, 1.0 = high certainty.
  final double confidence;

  /// 0.0 = calm, 1.0 = high emotional stakes.
  final double emotionalIntensity;

  const StateWeighting({
    this.urgency = 0.5,
    this.riskSensitivity = 0.5,
    this.confidence = 0.5,
    this.emotionalIntensity = 0.5,
  });

  /// Default neutral state (all weights at 0.5).
  static const StateWeighting neutral = StateWeighting();

  /// Whether any weight is at an extreme (> 0.8 or < 0.2).
  bool get hasExtremes =>
      urgency > 0.8 ||
      urgency < 0.2 ||
      riskSensitivity > 0.8 ||
      riskSensitivity < 0.2 ||
      confidence > 0.8 ||
      confidence < 0.2 ||
      emotionalIntensity > 0.8 ||
      emotionalIntensity < 0.2;

  Map<String, dynamic> toJson() {
    return {
      'urgency': urgency,
      'riskSensitivity': riskSensitivity,
      'confidence': confidence,
      'emotionalIntensity': emotionalIntensity,
    };
  }

  factory StateWeighting.fromJson(Map<String, dynamic> json) {
    return StateWeighting(
      urgency: (json['urgency'] as num?)?.toDouble() ?? 0.5,
      riskSensitivity: (json['riskSensitivity'] as num?)?.toDouble() ?? 0.5,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      emotionalIntensity:
          (json['emotionalIntensity'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

/// Audit record of how state modified philosophy output.
@immutable
class StateWeightingImpact {
  /// The state weights that were applied.
  final StateWeighting appliedWeighting;

  /// Field-to-adjustment-factor mapping.
  final Map<String, double> adjustments;

  /// Human-readable impact description.
  final String summary;

  /// Confirm philosophy direction was unchanged.
  final bool directionPreserved;

  /// Confirm prohibitions were unchanged.
  final bool prohibitionsPreserved;

  /// When the adjustment was applied.
  final DateTime appliedAt;

  StateWeightingImpact({
    required this.appliedWeighting,
    required this.adjustments,
    required this.summary,
    this.directionPreserved = true,
    this.prohibitionsPreserved = true,
    DateTime? appliedAt,
  }) : appliedAt = appliedAt ?? DateTime.now();

  /// Whether state had any effect on the output.
  bool get hadEffect => adjustments.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'appliedWeighting': appliedWeighting.toJson(),
      'adjustments': adjustments,
      'summary': summary,
      'directionPreserved': directionPreserved,
      'prohibitionsPreserved': prohibitionsPreserved,
      'appliedAt': appliedAt.toIso8601String(),
    };
  }

  factory StateWeightingImpact.fromJson(Map<String, dynamic> json) {
    return StateWeightingImpact(
      appliedWeighting: StateWeighting.fromJson(
          json['appliedWeighting'] as Map<String, dynamic>),
      adjustments: (json['adjustments'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      summary: json['summary'] as String,
      directionPreserved: json['directionPreserved'] as bool? ?? true,
      prohibitionsPreserved: json['prohibitionsPreserved'] as bool? ?? true,
      appliedAt: json['appliedAt'] != null
          ? DateTime.parse(json['appliedAt'] as String)
          : null,
    );
  }
}

// =============================================================================
// Stub Implementation
// =============================================================================

/// Stub philosophy port for testing.
class StubPhilosophyPort implements PhilosophyPort {
  const StubPhilosophyPort();

  @override
  Future<PhilosophyGuidance> evaluate(
      PhilosophyEvaluationContext context) async {
    return const PhilosophyGuidance(
      prohibitionChecks: ProhibitionCheckResult(
        checks: [],
        hasHardViolation: false,
      ),
      recommendedAction: 'stub-action',
      confidence: 0.5,
      explanation: 'Stub evaluation',
      prohibitionViolated: false,
    );
  }

  @override
  Future<ProhibitionCheckResult> checkProhibitions(
      ProhibitionCheckRequest request) async {
    return const ProhibitionCheckResult(
      checks: [],
      hasHardViolation: false,
    );
  }

  @override
  Future<InterventionResult> intervene(
    InterventionPoint point,
    PipelineContext context,
  ) async {
    return InterventionResult.noOp();
  }

  @override
  Future<Ethos> getEthos() async {
    final now = DateTime.now();
    return Ethos(
      id: 'stub-ethos',
      name: 'Stub Ethos',
      valuePriorities: const [],
      prohibitions: const [],
      metadata: EthosMetadata(
        version: '0.0.0',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<List<Tension>> detectTensions(MultiLayerContext context) {
    throw UnsupportedError('detectTensions is not supported by this adapter');
  }

  @override
  Future<EvolutionProposal?> proposeFeedback(FeedbackEvent event) {
    throw UnsupportedError('proposeFeedback is not supported by this adapter');
  }
}
