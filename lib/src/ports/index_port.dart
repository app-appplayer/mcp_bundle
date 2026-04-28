/// Index Port - Knowledge index lifecycle.
///
/// Capability-named port per REDESIGN-PLAN.md §3.2.
///
/// Provider: `mcp_fact_graph`.
library;

import '../types/knowledge_types.dart';

/// Port for knowledge index management.
abstract class IndexPort {
  /// Build a knowledge index.
  Future<void> buildIndex(String id, IndexBuildConfig config);

  /// Check whether an index exists.
  Future<bool> indexExists(String id);

  /// Drop an index.
  Future<void> dropIndex(String id);
}

/// Stub implementation for testing.
class StubIndexPort implements IndexPort {
  const StubIndexPort();

  @override
  Future<void> buildIndex(String id, IndexBuildConfig config) async {}

  @override
  Future<bool> indexExists(String id) async => false;

  @override
  Future<void> dropIndex(String id) async {}
}
