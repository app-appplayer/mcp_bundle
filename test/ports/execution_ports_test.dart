/// Tests for Phase 1b execution ports (REDESIGN-PLAN.md §3.3).
///
/// Covers: SkillRuntimePort, SkillRegistryPort, unified McpPort.
library;

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('SkillRuntimePort', () {
    const port = StubSkillRuntimePort();

    test('executeSkill returns a finished handle', () async {
      final handle = await port.executeSkill('skill-1', const {'x': 1});
      expect(handle.skillId, 'skill-1');
      expect(handle.running, isFalse);
      expect(handle.finishedAt, isNotNull);
    });

    test('cancel does not throw', () async {
      await port.cancel('run-1');
    });
  });

  group('SkillRegistryPort', () {
    const port = StubSkillRegistryPort();

    test('registerBundle does not throw', () async {
      await port.registerBundle(
        const BundleDescriptor(
          id: 'b1',
          name: 'Bundle 1',
          version: '1.0.0',
        ),
      );
    });

    test('getBundle returns null', () async {
      expect(await port.getBundle('b1'), isNull);
    });

    test('listBundles returns empty list', () async {
      expect(await port.listBundles(), isEmpty);
    });

    test('unregister does not throw', () async {
      await port.unregister('b1');
    });

    test('BundleDescriptor preserves fields', () {
      const d = BundleDescriptor(
        id: 'b1',
        name: 'n',
        version: '1.0',
        skillIds: ['s1', 's2'],
        metadata: {'k': 'v'},
      );
      expect(d.skillIds, ['s1', 's2']);
      expect(d.metadata['k'], 'v');
    });
  });

  group('McpPort (unified)', () {
    const port = StubMcpPort();

    test('callTool returns stub result', () async {
      final result = await port.callTool('t', const {});
      expect(result.content, 'Stub tool result');
      expect(result.isError, isFalse);
    });

    test('callTool accepts optional serverId', () async {
      final result =
          await port.callTool('t', const {}, serverId: 'srv1');
      expect(result.isError, isFalse);
    });

    test('readResource returns ResourceContent with text', () async {
      final rc = await port.readResource('u', serverId: 'srv1');
      expect(rc.uri, 'u');
      expect(rc.text, isEmpty);
      expect(rc.isText, isTrue);
    });

    test('listTools and listResources return empty lists', () async {
      expect(await port.listTools(), isEmpty);
      expect(await port.listResources(serverId: 's1'), isEmpty);
    });

    test('subscribeResource returns null (unsupported)', () {
      expect(port.subscribeResource('u'), isNull);
    });

    test('getPrompt returns null', () async {
      expect(await port.getPrompt('p'), isNull);
    });

    test('isConnected returns true', () async {
      expect(await port.isConnected(), isTrue);
      expect(await port.isConnected(serverId: 's1'), isTrue);
    });

    test('ResourceContent binary branch', () {
      const rc = ResourceContent(
        uri: 'u',
        mimeType: 'application/octet-stream',
        bytes: [1, 2, 3],
      );
      expect(rc.isBinary, isTrue);
      expect(rc.isText, isFalse);
      expect(rc.bytes, [1, 2, 3]);
    });
  });
}
