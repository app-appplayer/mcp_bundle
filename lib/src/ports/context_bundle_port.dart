/// Context Bundle Port - Build context bundles for LLM prompts.
///
/// Capability-named port per REDESIGN-PLAN.md §3.2. Takes a request and
/// returns a fully-assembled context bundle drawing on the underlying
/// fact graph.
///
/// Provider: `mcp_fact_graph`.
library;

import '../types/context_bundle.dart';
import '../types/period.dart';

/// Port for context bundle construction.
abstract class ContextBundlePort {
  /// Build a context bundle from the fact graph.
  Future<ContextBundle> buildContextBundle(ContextBundleRequest request);
}

/// Request for [ContextBundlePort.buildContextBundle].
class ContextBundleRequest {
  /// Natural-language query.
  final String query;

  /// Workspace identifier.
  final String workspaceId;

  /// Point in time for the query.
  final DateTime? asOf;

  /// Period filter.
  final Period? period;

  /// Policy version.
  final String? policyVersion;

  /// Budget constraints.
  final ContextBudget? budget;

  const ContextBundleRequest({
    required this.query,
    required this.workspaceId,
    this.asOf,
    this.period,
    this.policyVersion,
    this.budget,
  });
}

/// Budget constraints for a context bundle.
class ContextBudget {
  /// Maximum number of nodes.
  final int? maxNodes;

  /// Maximum number of tokens.
  final int? maxTokens;

  /// Maximum number of sentences.
  final int? maxSentences;

  const ContextBudget({this.maxNodes, this.maxTokens, this.maxSentences});
}

/// Stub implementation for testing.
class StubContextBundlePort implements ContextBundlePort {
  const StubContextBundlePort();

  @override
  Future<ContextBundle> buildContextBundle(
    ContextBundleRequest request,
  ) async {
    return ContextBundle(
      id: 'stub-${request.workspaceId}',
      createdAt: request.asOf ?? DateTime.now(),
    );
  }
}
