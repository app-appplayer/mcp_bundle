/// Decision Port - Policy-driven decision evaluation.
///
/// Capability-named port for evaluating a decision policy against a
/// context and producing guidance. Standard abstract contract per
/// REDESIGN-PLAN.md §3.4 Phase 1a (0.1.0-a2).
///
/// Provider: `mcp_profile`.
library;

import '../types/decision_guidance.dart';

/// Port for decision evaluation.
///
/// Given a policy identifier and a context, return a [DecisionGuidance]
/// describing the recommended action and modifiers.
abstract class DecisionPort {
  /// Evaluate the decision policy.
  ///
  /// [policy] is the policy identifier (or inline policy document — the
  /// adapter decides). [context] is an opaque map supplied by the caller.
  Future<DecisionGuidance> decide(
    String policy,
    Map<String, dynamic> context,
  );
}

/// Stub decision port for testing.
class StubDecisionPort implements DecisionPort {
  const StubDecisionPort();

  @override
  Future<DecisionGuidance> decide(
    String policy,
    Map<String, dynamic> context,
  ) async {
    return const DecisionGuidance(
      action: DecisionAction.proceed,
      confidence: 0.5,
      explanation: 'stub decision',
    );
  }
}
