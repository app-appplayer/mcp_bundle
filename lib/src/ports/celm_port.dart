/// CeLM — a guarded local execution loop over structured state.
///
/// The contract exists to take load off a planning model, locally. Work is
/// answered at the lowest tier that can answer it: a fact costs nothing, a
/// domain judgment costs a small local model, and the planner is reached
/// only where a planner is the answer. Everything in this file is shaped
/// by that — an outcome distinguishes "blocked" from "failed" so a caller
/// does not re-plan what merely needs stopping, and an escalation carries
/// a digest rather than a state so the planner reads a question rather
/// than a screen.
///
/// Every type that crosses the port has a JSON form. The port surface is
/// also an MCP tool surface, and a value that cannot be serialized cannot
/// be a tool result. A value that fails to deserialize is refused, never
/// coerced: a wrong enum name or a missing provenance is an error at the
/// boundary, not a default that reads as something else.
///
/// Implemented by `mcp_celm`.
library;

import 'analysis_port.dart' show AnalysisActor, AnalysisError;

// ============================================================================
// Decoding helpers
// ============================================================================

/// Refuse a value the contract does not know. Coercing an unknown name to
/// a default would let a typo pass every check that the name was meant to
/// trip.
Never _unknownValue(String kind, Object? value) => throw AnalysisError(
      code: 'celm.unknown_value',
      message: 'Unknown $kind "$value"',
      details: {'kind': kind, 'value': value},
    );

Never _missingField(String type, String field) => throw AnalysisError(
      code: 'celm.missing_field',
      message: '$type requires "$field"',
      details: {'type': type, 'field': field},
    );

T _enumByName<T extends Enum>(List<T> values, String kind, Object? raw) {
  if (raw is! String) _unknownValue(kind, raw);
  for (final v in values) {
    if (v.name == raw) return v;
  }
  _unknownValue(kind, raw);
}

String _requireString(Map<String, dynamic> json, String type, String field) {
  final v = json[field];
  if (v is String) return v;
  _missingField(type, field);
}

Map<String, dynamic> _requireMap(
  Map<String, dynamic> json,
  String type,
  String field,
) {
  final v = json[field];
  if (v is Map<String, dynamic>) return v;
  _missingField(type, field);
}

DateTime _requireTime(Map<String, dynamic> json, String type, String field) =>
    DateTime.parse(_requireString(json, type, field));

List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) decode) =>
    (raw as List<dynamic>?)
        ?.map((e) => decode(e as Map<String, dynamic>))
        .toList() ??
    const [];

// ============================================================================
// Addressing
// ============================================================================

/// A goal the domain pack defines, with its parameters.
///
/// A caller names a goal; it does not author one. The step graph is domain
/// knowledge and lives in the pack, so a port taking a goal *definition*
/// would make the planner write the structure — the load this contract
/// removes, handed back at the door.
class CelmGoalRef {
  /// Goal id, as the pack defines it.
  final String id;

  /// Parameters the goal declares.
  final Map<String, dynamic> params;

  const CelmGoalRef({required this.id, this.params = const {}});

  factory CelmGoalRef.fromJson(Map<String, dynamic> json) => CelmGoalRef(
        id: _requireString(json, 'CelmGoalRef', 'id'),
        params: (json['params'] as Map<String, dynamic>?) ?? const {},
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (params.isNotEmpty) 'params': params,
      };
}

/// Caller-supplied limits for one run, narrowing what the manifest permits.
///
/// A constraint may only remove permission. A run cannot ask for more than
/// its manifest allows, so a caller cannot widen a boundary by asking.
class CelmConstraints {
  /// Refuse any action that writes.
  final bool readOnly;

  /// Stop after this long, if sooner than the manifest's budget.
  final Duration? deadline;

  const CelmConstraints({this.readOnly = false, this.deadline});

  factory CelmConstraints.fromJson(Map<String, dynamic> json) =>
      CelmConstraints(
        readOnly: json['readOnly'] as bool? ?? false,
        deadline: json['deadlineMs'] == null
            ? null
            : Duration(milliseconds: (json['deadlineMs'] as num).toInt()),
      );

  Map<String, dynamic> toJson() => {
        if (readOnly) 'readOnly': true,
        if (deadline != null) 'deadlineMs': deadline!.inMilliseconds,
      };
}

// ============================================================================
// Observation
// ============================================================================

/// How deeply perception should look.
///
/// Coarse-to-fine is not an optimization here: a descriptor states what it
/// examined, and it can only state that if it was asked. The values are
/// ordered — a coverage entry at a deeper level satisfies a requirement
/// for a shallower one.
enum CelmDepth {
  /// Top-level objects and their identities. Enough to navigate.
  coarse,

  /// Structure within the scope — parts, roles, relations.
  structure,

  /// Down to the atoms a measurement or a predicate needs.
  atoms;

  /// Refuses an unknown name. A misspelt depth that quietly became
  /// `coarse` would pass the manifest's depth check and then resolve every
  /// absence as unexamined.
  static CelmDepth fromString(String value) =>
      _enumByName(CelmDepth.values, 'depth', value);

  /// True when this depth is at least [required].
  bool satisfies(CelmDepth required) => index >= required.index;
}

/// What to look at, and how deeply.
class CelmObserveRequest {
  /// Region, window, or named area. Null means everything available.
  final String? scope;

  final CelmDepth depth;

  const CelmObserveRequest({this.scope, this.depth = CelmDepth.coarse});

  factory CelmObserveRequest.fromJson(Map<String, dynamic> json) =>
      CelmObserveRequest(
        scope: json['scope'] as String?,
        depth: json['depth'] == null
            ? CelmDepth.coarse
            : CelmDepth.fromString(json['depth'] as String),
      );

  Map<String, dynamic> toJson() => {
        if (scope != null) 'scope': scope,
        'depth': depth.name,
      };
}

/// What perception examined, and to what depth.
///
/// This is what separates "it is not there" from "nobody looked". Without
/// it every absence has to be treated as unobservable, which escalates on
/// the most ordinary event there is — a window that has not opened yet.
class CelmCoverage {
  final String scope;
  final CelmDepth depth;

  const CelmCoverage({required this.scope, required this.depth});

  factory CelmCoverage.fromJson(Map<String, dynamic> json) => CelmCoverage(
        scope: _requireString(json, 'CelmCoverage', 'scope'),
        depth: CelmDepth.fromString(
          _requireString(json, 'CelmCoverage', 'depth'),
        ),
      );

  Map<String, dynamic> toJson() => {'scope': scope, 'depth': depth.name};
}

/// One descriptor field, with how well it was seen.
///
/// Quality decides whether a question is answerable. It never becomes part
/// of a judgment's confidence: how well something was seen and how sure a
/// conclusion is are different quantities, and a threshold over their
/// product means nothing.
class CelmFieldRef {
  final String field;
  final double quality;

  const CelmFieldRef({required this.field, required this.quality});

  factory CelmFieldRef.fromJson(Map<String, dynamic> json) => CelmFieldRef(
        field: _requireString(json, 'CelmFieldRef', 'field'),
        quality: (json['quality'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {'field': field, 'quality': quality};
}

/// A structured state snapshot: what perception produced, and what it
/// examined to produce it.
class CelmObservation {
  /// Structured content, in the perception layer's descriptor schema.
  final Map<String, dynamic> descriptor;

  /// What was examined. Empty coverage makes every absence unobservable.
  final List<CelmCoverage> coverage;

  final DateTime at;

  const CelmObservation({
    required this.descriptor,
    required this.coverage,
    required this.at,
  });

  factory CelmObservation.fromJson(Map<String, dynamic> json) =>
      CelmObservation(
        descriptor: (json['descriptor'] as Map<String, dynamic>?) ?? const {},
        coverage: _list(json['coverage'], CelmCoverage.fromJson),
        at: _requireTime(json, 'CelmObservation', 'at'),
      );

  Map<String, dynamic> toJson() => {
        'descriptor': descriptor,
        if (coverage.isNotEmpty)
          'coverage': coverage.map((c) => c.toJson()).toList(),
        'at': at.toIso8601String(),
      };
}

// ============================================================================
// Evidence
// ============================================================================

/// A conclusion a run reached, and how it reached it.
///
/// Two types rather than one type with a provenance string: a consumer
/// that must separate what was measured from what was inferred cannot
/// forget to, and a judgment cannot be constructed without naming the
/// reasoner that made it.
///
/// The separation holds across serialization too. [CelmConclusion.fromJson]
/// dispatches on `provenance`, and each subtype's factory refuses a record
/// whose provenance is not its own — a judged record cannot come back from
/// a store as an observation.
sealed class CelmConclusion {
  final String id;
  final String runId;
  final String statement;
  final DateTime at;

  const CelmConclusion({
    required this.id,
    required this.runId,
    required this.statement,
    required this.at,
  });

  /// Decodes by `provenance`. Missing or unknown provenance is refused.
  static CelmConclusion fromJson(Map<String, dynamic> json) {
    final provenance = _requireString(json, 'CelmConclusion', 'provenance');
    return switch (provenance) {
      'observed' => ObservedConclusion.fromJson(json),
      'judged' => JudgedConclusion.fromJson(json),
      _ => _unknownValue('provenance', provenance),
    };
  }

  Map<String, dynamic> toJson();
}

void _requireProvenance(Map<String, dynamic> json, String expected) {
  final actual = _requireString(json, 'CelmConclusion', 'provenance');
  if (actual != expected) {
    throw AnalysisError(
      code: 'celm.provenance_mismatch',
      message: 'Expected provenance "$expected", record says "$actual"',
      details: {'expected': expected, 'actual': actual},
    );
  }
}

/// Established by a deterministic predicate over descriptor fields.
///
/// Carries no confidence, because it has none: the predicate held or it
/// did not.
class ObservedConclusion extends CelmConclusion {
  final List<CelmFieldRef> inputs;

  const ObservedConclusion({
    required super.id,
    required super.runId,
    required super.statement,
    required super.at,
    this.inputs = const [],
  });

  /// Refuses a record whose provenance is not `observed`.
  factory ObservedConclusion.fromJson(Map<String, dynamic> json) {
    _requireProvenance(json, 'observed');
    return ObservedConclusion(
      id: _requireString(json, 'ObservedConclusion', 'id'),
      runId: _requireString(json, 'ObservedConclusion', 'runId'),
      statement: json['statement'] as String? ?? '',
      at: _requireTime(json, 'ObservedConclusion', 'at'),
      inputs: _list(json['inputs'], CelmFieldRef.fromJson),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'runId': runId,
        'statement': statement,
        'provenance': 'observed',
        if (inputs.isNotEmpty) 'inputs': inputs.map((i) => i.toJson()).toList(),
        'at': at.toIso8601String(),
      };
}

/// Reached by inference over structured state.
///
/// Never standalone evidence: it reaches a consumer as a conclusion drawn
/// from observations, with those observations named.
class JudgedConclusion extends CelmConclusion {
  final double confidence;

  /// Which reasoner judged, and whether it ran off-box.
  final String reasoner;

  /// True when the reasoner was not local. A domain judgment made
  /// remotely is a bootstrap, and the record says so rather than letting
  /// it pass for the arrangement this contract is for.
  final bool reasonerRemote;

  /// Ids of the conclusions this one rests on.
  final List<String> premises;

  final String rationale;

  const JudgedConclusion({
    required super.id,
    required super.runId,
    required super.statement,
    required super.at,
    required this.confidence,
    required this.reasoner,
    this.reasonerRemote = false,
    this.premises = const [],
    this.rationale = '',
  });

  /// Refuses a record whose provenance is not `judged`, and one that
  /// names no reasoner.
  factory JudgedConclusion.fromJson(Map<String, dynamic> json) {
    _requireProvenance(json, 'judged');
    return JudgedConclusion(
      id: _requireString(json, 'JudgedConclusion', 'id'),
      runId: _requireString(json, 'JudgedConclusion', 'runId'),
      statement: json['statement'] as String? ?? '',
      at: _requireTime(json, 'JudgedConclusion', 'at'),
      confidence: (json['confidence'] as num?)?.toDouble() ??
          _missingField('JudgedConclusion', 'confidence'),
      reasoner: _requireString(json, 'JudgedConclusion', 'reasoner'),
      reasonerRemote: json['reasonerRemote'] as bool? ?? false,
      premises:
          (json['premises'] as List<dynamic>?)?.cast<String>() ?? const [],
      rationale: json['rationale'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'runId': runId,
        'statement': statement,
        'provenance': 'judged',
        'confidence': confidence,
        'reasoner': reasoner,
        if (reasonerRemote) 'reasonerRemote': true,
        if (premises.isNotEmpty) 'premises': premises,
        if (rationale.isNotEmpty) 'rationale': rationale,
        'at': at.toIso8601String(),
      };
}

/// One conclusion with everything under it, down to observed fields.
class CelmEvidence {
  final CelmConclusion conclusion;

  /// Premises, transitively. A chain reaching no observation is a
  /// judgment resting on nothing, and is worth seeing as such.
  final List<CelmConclusion> chain;

  const CelmEvidence({required this.conclusion, this.chain = const []});

  factory CelmEvidence.fromJson(Map<String, dynamic> json) => CelmEvidence(
        conclusion: CelmConclusion.fromJson(
          _requireMap(json, 'CelmEvidence', 'conclusion'),
        ),
        chain: _list(json['chain'], CelmConclusion.fromJson),
      );

  Map<String, dynamic> toJson() => {
        'conclusion': conclusion.toJson(),
        if (chain.isNotEmpty) 'chain': chain.map((c) => c.toJson()).toList(),
      };
}

// ============================================================================
// Escalation
// ============================================================================

/// A reference to a golden reference the pack attached to a check.
class CelmReferenceRef {
  final String id;
  final String field;
  final Map<String, dynamic> expected;

  const CelmReferenceRef({
    required this.id,
    required this.field,
    this.expected = const {},
  });

  factory CelmReferenceRef.fromJson(Map<String, dynamic> json) =>
      CelmReferenceRef(
        id: _requireString(json, 'CelmReferenceRef', 'id'),
        field: _requireString(json, 'CelmReferenceRef', 'field'),
        expected: (json['expected'] as Map<String, dynamic>?) ?? const {},
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'field': field,
        if (expected.isNotEmpty) 'expected': expected,
      };
}

/// What a planner is given when the runtime cannot proceed.
///
/// The fields the blocked check reads, what was and was not examined, and
/// the knowledge attached to it — **not the descriptor**. The load being
/// removed is not only how often a model is called but how much it must
/// read to answer; a screen dump every time moves the cost rather than
/// removing it. A planner needing more asks through [CelmPort.observe].
class CelmDigest {
  /// Fields the blocked check references, with their quality.
  final List<CelmFieldRef> relevant;

  /// What perception examined, so "not there" is distinguishable from
  /// "not looked at".
  final List<CelmCoverage> coverage;

  /// References the pack attached to this check.
  final List<CelmReferenceRef> knowledge;

  const CelmDigest({
    this.relevant = const [],
    this.coverage = const [],
    this.knowledge = const [],
  });

  factory CelmDigest.fromJson(Map<String, dynamic> json) => CelmDigest(
        relevant: _list(json['relevant'], CelmFieldRef.fromJson),
        coverage: _list(json['coverage'], CelmCoverage.fromJson),
        knowledge: _list(json['knowledge'], CelmReferenceRef.fromJson),
      );

  Map<String, dynamic> toJson() => {
        if (relevant.isNotEmpty)
          'relevant': relevant.map((f) => f.toJson()).toList(),
        if (coverage.isNotEmpty)
          'coverage': coverage.map((c) => c.toJson()).toList(),
        if (knowledge.isNotEmpty)
          'knowledge': knowledge.map((k) => k.toJson()).toList(),
      };
}

/// Why the runtime stopped and handed up.
///
/// These are distinguished because the useful response differs. Collapsed
/// into one "it failed", a planner retries the thing that could not be
/// seen.
enum CelmEscalationReason {
  /// Seen well enough, could not decide — a judgment below the escalation
  /// threshold.
  lowConfidence,

  /// Could not see what the check needs — not covered, or below its floor.
  unobservable,

  /// Tried, within the allowance, and the retry budget is spent or the
  /// step has no alternative.
  budgetExhausted,

  /// Ready to act, gate closed.
  irreversibleGate,

  /// A skill's precondition did not hold and the step has no alternative.
  preconditionFailed,

  /// This step already escalated on exactly this state. Terminal.
  noProgress;

  static CelmEscalationReason fromString(String value) =>
      _enumByName(CelmEscalationReason.values, 'escalation reason', value);
}

/// Why a run could not start, or could not be permitted.
enum CelmRefusalReason {
  /// The pack defines no such goal.
  goalUnknown,

  /// The goal's parameters or constraints cannot be satisfied.
  goalUnsatisfiable,

  /// The action is not in the manifest's allow-list, or the caller's
  /// constraints forbid it.
  notPermitted,

  /// The action does not fit the declared loop regime.
  regimeViolation,

  /// A resumption named a step the goal does not contain.
  stepUnknown;

  static CelmRefusalReason fromString(String value) =>
      _enumByName(CelmRefusalReason.values, 'refusal reason', value);
}

/// One thing the runtime tried, and what came of it.
class CelmAttempt {
  final String step;
  final String action;
  final String result;
  final String? why;
  final DateTime at;

  const CelmAttempt({
    required this.step,
    required this.action,
    required this.result,
    required this.at,
    this.why,
  });

  factory CelmAttempt.fromJson(Map<String, dynamic> json) => CelmAttempt(
        step: _requireString(json, 'CelmAttempt', 'step'),
        action: json['action'] as String? ?? '',
        result: json['result'] as String? ?? '',
        why: json['why'] as String?,
        at: _requireTime(json, 'CelmAttempt', 'at'),
      );

  Map<String, dynamic> toJson() => {
        'step': step,
        'action': action,
        'result': result,
        if (why != null) 'why': why,
        'at': at.toIso8601String(),
      };
}

/// What a run has spent.
///
/// Retries and escalations are counted apart. They are different events
/// and are bounded separately: asking for help is not the same as
/// failing, and a run is not nearer to its end for having asked.
class CelmBudgetUse {
  final int attemptsSpent;
  final int attemptsAllowed;
  final int escalationsSpent;
  final int escalationsAllowed;
  final Duration elapsed;

  const CelmBudgetUse({
    required this.attemptsSpent,
    required this.attemptsAllowed,
    required this.escalationsSpent,
    required this.escalationsAllowed,
    required this.elapsed,
  });

  factory CelmBudgetUse.fromJson(Map<String, dynamic> json) => CelmBudgetUse(
        attemptsSpent: (json['attemptsSpent'] as num?)?.toInt() ?? 0,
        attemptsAllowed: (json['attemptsAllowed'] as num?)?.toInt() ?? 0,
        escalationsSpent: (json['escalationsSpent'] as num?)?.toInt() ?? 0,
        escalationsAllowed: (json['escalationsAllowed'] as num?)?.toInt() ?? 0,
        elapsed: Duration(
          milliseconds: (json['elapsedMs'] as num?)?.toInt() ?? 0,
        ),
      );

  Map<String, dynamic> toJson() => {
        'attemptsSpent': attemptsSpent,
        'attemptsAllowed': attemptsAllowed,
        'escalationsSpent': escalationsSpent,
        'escalationsAllowed': escalationsAllowed,
        'elapsedMs': elapsed.inMilliseconds,
      };
}

/// A planner's answer to an escalation.
sealed class CelmResumption {
  const CelmResumption();

  /// Decodes by `kind`. Unknown kinds are refused.
  static CelmResumption fromJson(Map<String, dynamic> json) {
    final kind = _requireString(json, 'CelmResumption', 'kind');
    return switch (kind) {
      'resumeAt' => ResumeAt(_requireString(json, 'ResumeAt', 'step')),
      'resumeWith' => ResumeWith(
          _requireString(json, 'ResumeWith', 'step'),
          (json['params'] as Map<String, dynamic>?) ?? const {},
        ),
      'abandon' => Abandon(json['why'] as String? ?? ''),
      _ => _unknownValue('resumption kind', kind),
    };
  }

  Map<String, dynamic> toJson();
}

/// Continue from a step already in the goal.
class ResumeAt extends CelmResumption {
  final String step;
  const ResumeAt(this.step);

  @override
  Map<String, dynamic> toJson() => {'kind': 'resumeAt', 'step': step};
}

/// Continue from a step, with corrected parameters.
class ResumeWith extends CelmResumption {
  final String step;
  final Map<String, dynamic> params;
  const ResumeWith(this.step, this.params);

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'resumeWith',
        'step': step,
        if (params.isNotEmpty) 'params': params,
      };
}

/// Stop. An abandoned escalation is a labelled negative, not a discarded
/// run — it is data the next reasoner learns from.
class Abandon extends CelmResumption {
  final String why;
  const Abandon(this.why);

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'abandon',
        if (why.isNotEmpty) 'why': why,
      };
}

// ============================================================================
// Outcome
// ============================================================================

/// How a run ended.
///
/// Four, not two. Escalation is not failure and cancellation is not
/// either; a caller that collapses them re-introduces the blind advance
/// this contract exists to prevent.
sealed class CelmOutcome {
  final String runId;
  const CelmOutcome(this.runId);

  /// Decodes by `outcome`. Unknown outcomes are refused.
  static CelmOutcome fromJson(Map<String, dynamic> json) {
    final kind = _requireString(json, 'CelmOutcome', 'outcome');
    final runId = _requireString(json, 'CelmOutcome', 'runId');
    return switch (kind) {
      'completed' => CelmCompleted(
          runId,
          conclusions: _list(json['conclusions'], CelmConclusion.fromJson),
          budget: CelmBudgetUse.fromJson(
            _requireMap(json, 'CelmCompleted', 'budget'),
          ),
        ),
      'escalated' => CelmEscalated(
          runId,
          reason: CelmEscalationReason.fromString(
            _requireString(json, 'CelmEscalated', 'reason'),
          ),
          digest: CelmDigest.fromJson(
            (json['digest'] as Map<String, dynamic>?) ?? const {},
          ),
          blockedAt: _requireString(json, 'CelmEscalated', 'blockedAt'),
          budget: CelmBudgetUse.fromJson(
            _requireMap(json, 'CelmEscalated', 'budget'),
          ),
          history: _list(json['history'], CelmAttempt.fromJson),
        ),
      'cancelled' => CelmCancelled(
          runId,
          stoppedAt: json['stoppedAt'] as String? ?? '',
          conclusions: _list(json['conclusions'], CelmConclusion.fromJson),
        ),
      'refused' => CelmRefused(
          runId,
          reason: CelmRefusalReason.fromString(
            _requireString(json, 'CelmRefused', 'reason'),
          ),
          detail: json['detail'] as String? ?? '',
        ),
      _ => _unknownValue('outcome', kind),
    };
  }

  Map<String, dynamic> toJson();
}

/// The goal's completion held.
class CelmCompleted extends CelmOutcome {
  final List<CelmConclusion> conclusions;
  final CelmBudgetUse budget;

  const CelmCompleted(
    super.runId, {
    this.conclusions = const [],
    required this.budget,
  });

  @override
  Map<String, dynamic> toJson() => {
        'outcome': 'completed',
        'runId': runId,
        if (conclusions.isNotEmpty)
          'conclusions': conclusions.map((c) => c.toJson()).toList(),
        'budget': budget.toJson(),
      };
}

/// Suspended. The run keeps its id, budget, history and evidence, and a
/// planner's answer names where to continue from.
class CelmEscalated extends CelmOutcome {
  final CelmEscalationReason reason;
  final CelmDigest digest;
  final List<CelmAttempt> history;
  final String blockedAt;
  final CelmBudgetUse budget;

  const CelmEscalated(
    super.runId, {
    required this.reason,
    required this.digest,
    required this.blockedAt,
    required this.budget,
    this.history = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
        'outcome': 'escalated',
        'runId': runId,
        'reason': reason.name,
        'digest': digest.toJson(),
        'blockedAt': blockedAt,
        'budget': budget.toJson(),
        if (history.isNotEmpty)
          'history': history.map((h) => h.toJson()).toList(),
      };
}

/// Stopped by a caller. What was observed before the stop was still
/// observed, so the evidence stands.
class CelmCancelled extends CelmOutcome {
  final List<CelmConclusion> conclusions;
  final String stoppedAt;

  const CelmCancelled(
    super.runId, {
    required this.stoppedAt,
    this.conclusions = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
        'outcome': 'cancelled',
        'runId': runId,
        'stoppedAt': stoppedAt,
        if (conclusions.isNotEmpty)
          'conclusions': conclusions.map((c) => c.toJson()).toList(),
      };
}

/// The run could not be started or could not be permitted.
class CelmRefused extends CelmOutcome {
  final CelmRefusalReason reason;
  final String detail;

  const CelmRefused(super.runId, {required this.reason, this.detail = ''});

  @override
  Map<String, dynamic> toJson() => {
        'outcome': 'refused',
        'runId': runId,
        'reason': reason.name,
        if (detail.isNotEmpty) 'detail': detail,
      };
}

/// A started run: its id, available before the run ends, and its outcome.
///
/// A caller holding only a pending future has no id to ask progress about
/// and nothing to cancel — and under a supervisory regime that future may
/// not complete at all.
///
/// This is the in-process shape. Over a wire, `execute` answers with the
/// run id alone and the outcome is read from [CelmProgress.outcome] once
/// the run has ended.
class CelmRunHandle {
  final String runId;
  final Future<CelmOutcome> outcome;

  const CelmRunHandle({required this.runId, required this.outcome});
}

/// Where a run has got to.
class CelmProgress {
  final String runId;
  final String currentStep;
  final List<CelmAttempt> history;
  final CelmBudgetUse budget;
  final bool escalated;

  /// Set once the run has ended. Null while it is running or suspended.
  /// This is how a caller that only has the id reads the result.
  final CelmOutcome? outcome;

  const CelmProgress({
    required this.runId,
    required this.currentStep,
    required this.budget,
    this.history = const [],
    this.escalated = false,
    this.outcome,
  });

  factory CelmProgress.fromJson(Map<String, dynamic> json) => CelmProgress(
        runId: _requireString(json, 'CelmProgress', 'runId'),
        currentStep: json['currentStep'] as String? ?? '',
        budget: CelmBudgetUse.fromJson(
          _requireMap(json, 'CelmProgress', 'budget'),
        ),
        history: _list(json['history'], CelmAttempt.fromJson),
        escalated: json['escalated'] as bool? ?? false,
        outcome: json['outcome'] == null
            ? null
            : CelmOutcome.fromJson(json['outcome'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'runId': runId,
        'currentStep': currentStep,
        'budget': budget.toJson(),
        if (history.isNotEmpty)
          'history': history.map((h) => h.toJson()).toList(),
        if (escalated) 'escalated': true,
        if (outcome != null) 'outcome': outcome!.toJson(),
      };
}

// ============================================================================
// Port
// ============================================================================

/// A guarded local execution loop.
///
/// The invariant every method serves: **a step that has not been verified
/// does not advance.** An implementation that advances on an unverified
/// result satisfies the signatures and not the contract.
abstract class CelmPort {
  /// Start [goal]. Returns once the run has an id; the outcome arrives on
  /// the handle.
  ///
  /// A goal the pack does not define, or one the caller's [constraints]
  /// make unsatisfiable, is answered with a handle whose outcome is
  /// [CelmRefused] — the id exists so the refusal is on record.
  Future<CelmRunHandle> execute(
    CelmGoalRef goal, {
    CelmConstraints? constraints,
    AnalysisActor? actor,
  });

  /// Stop a running goal. Evidence established before the stop survives.
  Future<CelmOutcome> cancel(String runId, {AnalysisActor? actor});

  /// Current structured state.
  ///
  /// [request] carries scope and depth. A descriptor states what it
  /// examined, and it can only do that if it was asked.
  Future<CelmObservation> observe({
    CelmObserveRequest? request,
    AnalysisActor? actor,
  });

  /// Progress, attempts and remaining budget of a run; its outcome once
  /// it has ended.
  Future<CelmProgress> progress(String runId, {AnalysisActor? actor});

  /// The evidence chain behind a conclusion.
  Future<CelmEvidence> explain(String conclusionId, {AnalysisActor? actor});

  /// Resume an escalated run with a planner's answer.
  ///
  /// An implementation re-perceives before deciding: the state that caused
  /// the escalation is stale by the time an answer arrives.
  Future<CelmOutcome> resume(
    String runId,
    CelmResumption resumption, {
    AnalysisActor? actor,
  });

  /// Conclusions from [runId] that may stand alone as evidence.
  ///
  /// Observations only. A judgment reaches a consumer through the premises
  /// of the conclusion that rests on it, where it is visibly inferred.
  Future<List<ObservedConclusion>> standalone(
    String runId, {
    AnalysisActor? actor,
  });
}

/// Stub implementation for testing.
class StubCelmPort implements CelmPort {
  final Map<String, CelmProgress> _runs = {};
  int _seq = 0;

  static const _emptyBudget = CelmBudgetUse(
    attemptsSpent: 0,
    attemptsAllowed: 0,
    escalationsSpent: 0,
    escalationsAllowed: 0,
    elapsed: Duration.zero,
  );

  @override
  Future<CelmRunHandle> execute(
    CelmGoalRef goal, {
    CelmConstraints? constraints,
    AnalysisActor? actor,
  }) async {
    final runId = 'stub-run-${++_seq}';
    final outcome = CelmCompleted(runId, budget: _emptyBudget);
    _runs[runId] = CelmProgress(
      runId: runId,
      currentStep: '',
      budget: _emptyBudget,
      outcome: outcome,
    );
    return CelmRunHandle(runId: runId, outcome: Future.value(outcome));
  }

  @override
  Future<CelmOutcome> cancel(String runId, {AnalysisActor? actor}) async =>
      CelmCancelled(runId, stoppedAt: '');

  @override
  Future<CelmObservation> observe({
    CelmObserveRequest? request,
    AnalysisActor? actor,
  }) async =>
      CelmObservation(
        descriptor: const {},
        coverage: const [],
        at: DateTime.now(),
      );

  @override
  Future<CelmProgress> progress(String runId, {AnalysisActor? actor}) async {
    final run = _runs[runId];
    if (run == null) {
      throw AnalysisError(
        code: 'celm.run_not_found',
        message: 'Run "$runId" not found',
        details: {'runId': runId},
      );
    }
    return run;
  }

  @override
  Future<CelmEvidence> explain(
    String conclusionId, {
    AnalysisActor? actor,
  }) async {
    throw AnalysisError(
      code: 'celm.conclusion_not_found',
      message: 'Conclusion "$conclusionId" not found',
      details: {'conclusionId': conclusionId},
    );
  }

  @override
  Future<CelmOutcome> resume(
    String runId,
    CelmResumption resumption, {
    AnalysisActor? actor,
  }) async =>
      switch (resumption) {
        Abandon() => CelmCancelled(runId, stoppedAt: ''),
        ResumeAt() ||
        ResumeWith() =>
          CelmCompleted(runId, budget: _emptyBudget),
      };

  @override
  Future<List<ObservedConclusion>> standalone(
    String runId, {
    AnalysisActor? actor,
  }) async =>
      const [];
}
