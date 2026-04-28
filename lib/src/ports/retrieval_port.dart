/// Retrieval Port - Knowledge retrieval (RAG).
///
/// Capability-named port per REDESIGN-PLAN.md §3.2. Supersedes the
/// knowledge-access fragment in the legacy `SkillFactGraphPort`.
///
/// Provider: `mcp_fact_graph`.
library;

import '../types/knowledge_types.dart';

/// Port for knowledge retrieval operations.
abstract class RetrievalPort {
  /// Search knowledge sources for relevant passages.
  Future<RetrievalResult> queryKnowledge(
    String query, {
    String? retrieverId,
    Map<String, dynamic>? filters,
    int? maxResults,
  });

  /// List available retrievers.
  Future<List<RetrieverInfo>> listRetrievers();
}

/// Stub implementation for testing.
class StubRetrievalPort implements RetrievalPort {
  const StubRetrievalPort();

  @override
  Future<RetrievalResult> queryKnowledge(
    String query, {
    String? retrieverId,
    Map<String, dynamic>? filters,
    int? maxResults,
  }) async {
    return const RetrievalResult(passages: []);
  }

  @override
  Future<List<RetrieverInfo>> listRetrievers() async => [];
}
