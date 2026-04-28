/// Tests for Phase 1b philosophy layer (REDESIGN-PLAN.md §3.5).
///
/// Covers: EthosStorePort.
library;

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('EthosStorePort', () {
    const port = StubEthosStorePort();

    test('getEthos returns null', () async {
      expect(await port.getEthos('missing'), isNull);
    });

    test('putEthos does not throw', () async {
      await port.putEthos(
        EthosRecord(
          id: 'e1',
          name: 'Default Ethos',
          version: '1.0',
          payload: const {},
          createdAt: DateTime.now(),
        ),
      );
    });

    test('listEthos returns empty list', () async {
      expect(await port.listEthos(), isEmpty);
    });

    test('activateEthos does not throw', () async {
      await port.activateEthos('e1');
    });

    test('getActiveEthosId returns null', () async {
      expect(await port.getActiveEthosId(), isNull);
    });

    test('EthosRecord preserves fields', () {
      final rec = EthosRecord(
        id: 'e1',
        name: 'Care-first',
        version: '2.0',
        payload: const {'priority': 'care'},
        createdAt: DateTime(2026, 1, 1),
        active: true,
      );
      expect(rec.name, 'Care-first');
      expect(rec.active, isTrue);
      expect(rec.payload['priority'], 'care');
    });
  });
}
