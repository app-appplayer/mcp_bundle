/// Tests for Phase 1b context/retrieval ports (REDESIGN-PLAN.md §3.2).
///
/// Covers: ContextBundlePort, RetrievalPort, AssetPort, IndexPort.
library;

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:mcp_bundle/src/types/knowledge_types.dart' as knowledge;
import 'package:test/test.dart';

void main() {
  group('ContextBundlePort', () {
    const port = StubContextBundlePort();

    test('buildContextBundle returns a bundle with stub id', () async {
      final bundle = await port.buildContextBundle(
        const ContextBundleRequest(query: 'hello', workspaceId: 'w1'),
      );
      expect(bundle.id, 'stub-w1');
    });

    test('ContextBudget preserves fields', () {
      const budget = ContextBudget(
        maxNodes: 100,
        maxTokens: 8000,
        maxSentences: 50,
      );
      expect(budget.maxNodes, 100);
      expect(budget.maxTokens, 8000);
      expect(budget.maxSentences, 50);
    });
  });

  group('RetrievalPort', () {
    const port = StubRetrievalPort();

    test('queryKnowledge returns empty passages', () async {
      final result = await port.queryKnowledge('q');
      expect(result.passages, isEmpty);
    });

    test('queryKnowledge accepts filters and maxResults', () async {
      final result = await port.queryKnowledge(
        'q',
        retrieverId: 'r1',
        filters: const {'k': 'v'},
        maxResults: 10,
      );
      expect(result.isEmpty, isTrue);
    });

    test('listRetrievers returns empty list', () async {
      expect(await port.listRetrievers(), isEmpty);
    });
  });

  group('AssetPort', () {
    const port = StubAssetPort();

    test('getAsset throws AssetNotFoundException', () async {
      expect(
        () => port.getAsset('missing'),
        throwsA(isA<knowledge.AssetNotFoundException>()),
      );
    });

    test('streamAsset throws AssetNotFoundException', () async {
      expect(
        () => port.streamAsset('missing'),
        throwsA(isA<knowledge.AssetNotFoundException>()),
      );
    });
  });

  group('IndexPort', () {
    const port = StubIndexPort();

    test('buildIndex does not throw', () async {
      await port.buildIndex(
        'idx1',
        const IndexBuildConfig(assetRefs: ['a1']),
      );
    });

    test('indexExists returns false', () async {
      expect(await port.indexExists('idx1'), isFalse);
    });

    test('dropIndex does not throw', () async {
      await port.dropIndex('idx1');
    });
  });
}
