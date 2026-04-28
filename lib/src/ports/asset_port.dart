/// Asset Port - Binary asset retrieval.
///
/// Capability-named port per REDESIGN-PLAN.md §3.2.
///
/// Provider: `mcp_fact_graph`.
library;

import '../types/knowledge_types.dart';

/// Port for asset retrieval.
abstract class AssetPort {
  /// Get an asset by ID.
  Future<AssetContent> getAsset(String id);

  /// Open a byte stream to an asset.
  Stream<List<int>> streamAsset(String id);
}

/// Stub implementation for testing.
class StubAssetPort implements AssetPort {
  const StubAssetPort();

  @override
  Future<AssetContent> getAsset(String id) async {
    throw AssetNotFoundException(id);
  }

  @override
  Stream<List<int>> streamAsset(String id) {
    throw AssetNotFoundException(id);
  }
}
