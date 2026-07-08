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

    test('EthosRecord.toJson emits ISO-8601 createdAt + payload as-is', () {
      final rec = EthosRecord(
        id: 'e1',
        name: 'Care',
        version: '2.0',
        payload: const {'priority': 'care', 'nested': {'k': 1}},
        createdAt: DateTime.utc(2026, 5, 4, 12, 30, 45),
        active: true,
      );
      final json = rec.toJson();
      expect(json['id'], 'e1');
      expect(json['name'], 'Care');
      expect(json['version'], '2.0');
      expect(json['active'], isTrue);
      expect(json['createdAt'], '2026-05-04T12:30:45.000Z');
      expect(json['payload'], rec.payload);
    });

    test('EthosRecord.fromJson round-trips through toJson', () {
      final original = EthosRecord(
        id: 'e1',
        name: 'Care',
        version: '2.0',
        payload: const {'priority': 'care', 'rules': ['r1', 'r2']},
        createdAt: DateTime.utc(2026, 5, 4, 12, 30, 45),
        active: true,
      );
      final encoded = original.toJson();
      final decoded = EthosRecord.fromJson(encoded);
      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.version, original.version);
      expect(decoded.payload, original.payload);
      expect(decoded.createdAt.toUtc(), original.createdAt.toUtc());
      expect(decoded.active, original.active);
    });

    test('EthosRecord.fromJson tolerates missing optional fields', () {
      final decoded = EthosRecord.fromJson(const {
        'id': 'e1',
        'name': 'Care',
        'version': '1.0',
        'payload': {},
        // createdAt + active omitted
      });
      expect(decoded.id, 'e1');
      expect(decoded.active, isFalse);
      // createdAt falls back to DateTime.now() — assert it is recent rather
      // than a fixed value.
      expect(
        DateTime.now().difference(decoded.createdAt).inSeconds < 5,
        isTrue,
      );
    });

    test('EthosStorePort has no deleteEthos — capability is separate', () {
      // StubEthosStorePort implements only EthosStorePort; deletion is opt-in.
      expect(port, isNot(isA<EthosStoreDelete>()));
    });
  });

  group('EthosStoreDelete (optional capability)', () {
    test('detected via type check; idempotent + clears active', () async {
      final store = _MemEthosStore();
      // Not the plain stub — a delete-capable adapter opts into the interface.
      expect(store, isA<EthosStoreDelete>());
      expect(store, isA<EthosStorePort>());

      final rec = EthosRecord(
        id: 'e1',
        name: 'Care',
        version: '1.0',
        payload: const {},
        createdAt: DateTime(2026, 1, 1),
      );
      await store.putEthos(rec);
      await store.activateEthos('e1');
      expect(await store.getActiveEthosId(), 'e1');

      await store.deleteEthos('e1');
      expect(await store.getEthos('e1'), isNull);
      // Deleting the active id clears the active pointer.
      expect(await store.getActiveEthosId(), isNull);

      // Idempotent — deleting an absent id does not throw.
      await store.deleteEthos('e1');
    });
  });
}

/// Minimal delete-capable ethos store — mirrors the KvEthosStoreAdapter
/// contract (`mcp_philosophy`) at the port level.
class _MemEthosStore implements EthosStorePort, EthosStoreDelete {
  final Map<String, EthosRecord> _records = <String, EthosRecord>{};
  String? _activeId;

  @override
  Future<EthosRecord?> getEthos(String id) async => _records[id];

  @override
  Future<void> putEthos(EthosRecord ethos) async => _records[ethos.id] = ethos;

  @override
  Future<List<EthosRecord>> listEthos({int? limit}) async =>
      _records.values.toList();

  @override
  Future<void> activateEthos(String id) async => _activeId = id;

  @override
  Future<String?> getActiveEthosId() async => _activeId;

  @override
  Future<void> deleteEthos(String id) async {
    _records.remove(id);
    if (_activeId == id) _activeId = null;
  }
}
