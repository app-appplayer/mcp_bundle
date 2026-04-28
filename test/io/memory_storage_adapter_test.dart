import 'dart:async';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  late MemoryStorageAdapter adapter;

  setUp(() {
    adapter = MemoryStorageAdapter();
  });

  tearDown(() {
    adapter.dispose();
  });

  // ==================== Seed Data ====================

  group('MemoryStorageAdapter - seed', () {
    test('seeds bundle data', () async {
      adapter.seed('bundle://test', {'id': 'test-bundle'});
      final result = await adapter.readBundle(Uri.parse('bundle://test'));
      expect(result['id'], equals('test-bundle'));
    });

    test('seed stores a deep copy (mutation isolation)', () async {
      final original = <String, dynamic>{
        'data': <String, dynamic>{'value': 1},
      };
      adapter.seed('bundle://copy', original);

      // Mutate the original map after seeding
      (original['data'] as Map<String, dynamic>)['value'] = 999;

      final result = await adapter.readBundle(Uri.parse('bundle://copy'));
      final data = result['data'] as Map<String, dynamic>;
      expect(data['value'], equals(1));
    });

    test('seedAsset stores asset data', () async {
      final data = Uint8List.fromList([1, 2, 3, 4]);
      adapter.seedAsset('asset://img.png', data);
      final result = await adapter.readAsset(Uri.parse('asset://img.png'));
      expect(result, equals(data));
    });

    test('seed emits created change event', () async {
      final events = <BundleChangeEvent>[];
      adapter.watch(Uri.parse('bundle://any'))?.listen(events.add);

      adapter.seed('bundle://new', {'id': 'new'});

      // Allow the stream event to propagate
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.type, equals(BundleChangeType.created));
    });

    test('seedAsset emits created change event', () async {
      final events = <BundleChangeEvent>[];
      adapter.watch(Uri.parse('asset://any'))?.listen(events.add);

      adapter.seedAsset('asset://data.bin', Uint8List.fromList([10]));

      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.type, equals(BundleChangeType.created));
    });
  });

  // ==================== Read Operations ====================

  group('MemoryStorageAdapter - readBundle', () {
    test('reads seeded bundle', () async {
      adapter.seed('bundle://read', {'name': 'Test'});
      final result = await adapter.readBundle(Uri.parse('bundle://read'));
      expect(result['name'], equals('Test'));
    });

    test('returns a deep copy (read isolation)', () async {
      adapter.seed('bundle://iso', {'count': 0});
      final result = await adapter.readBundle(Uri.parse('bundle://iso'));
      result['count'] = 999;

      // Second read should return original value
      final result2 = await adapter.readBundle(Uri.parse('bundle://iso'));
      expect(result2['count'], equals(0));
    });

    test('throws BundleNotFoundException for missing bundle', () async {
      expect(
        () => adapter.readBundle(Uri.parse('bundle://missing')),
        throwsA(isA<BundleNotFoundException>()),
      );
    });
  });

  group('MemoryStorageAdapter - readAsset', () {
    test('reads seeded asset', () async {
      final data = Uint8List.fromList([5, 10, 15]);
      adapter.seedAsset('asset://file.bin', data);
      final result = await adapter.readAsset(Uri.parse('asset://file.bin'));
      expect(result, equals(data));
    });

    test('returns a copy of asset bytes', () async {
      final data = Uint8List.fromList([1, 2, 3]);
      adapter.seedAsset('asset://copy', data);
      final result = await adapter.readAsset(Uri.parse('asset://copy'));
      result[0] = 99;

      final result2 = await adapter.readAsset(Uri.parse('asset://copy'));
      expect(result2[0], equals(1));
    });

    test('throws AssetNotFoundException for missing asset', () async {
      expect(
        () => adapter.readAsset(Uri.parse('asset://missing')),
        throwsA(isA<AssetNotFoundException>()),
      );
    });
  });

  // ==================== Write Operations ====================

  group('MemoryStorageAdapter - writeBundle', () {
    test('writes and reads back bundle data', () async {
      final uri = Uri.parse('bundle://write');
      await adapter.writeBundle(uri, {'key': 'value'});
      final result = await adapter.readBundle(uri);
      expect(result['key'], equals('value'));
    });

    test('overwrites existing bundle', () async {
      final uri = Uri.parse('bundle://overwrite');
      await adapter.writeBundle(uri, {'v': 1});
      await adapter.writeBundle(uri, {'v': 2});
      final result = await adapter.readBundle(uri);
      expect(result['v'], equals(2));
    });

    test('emits created event for new bundle', () async {
      final events = <BundleChangeEvent>[];
      adapter.watch(Uri.parse('bundle://any'))?.listen(events.add);

      await adapter.writeBundle(
        Uri.parse('bundle://new-write'),
        {'x': 1},
      );

      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.type, equals(BundleChangeType.created));
    });

    test('emits modified event for existing bundle', () async {
      final uri = Uri.parse('bundle://modify');
      await adapter.writeBundle(uri, {'x': 1});

      final events = <BundleChangeEvent>[];
      adapter.watch(uri)?.listen(events.add);

      await adapter.writeBundle(uri, {'x': 2});

      await Future<void>.delayed(Duration.zero);

      expect(events.last.type, equals(BundleChangeType.modified));
    });

    test('stores a deep copy (write isolation)', () async {
      final uri = Uri.parse('bundle://write-iso');
      final data = <String, dynamic>{
        'nested': <String, dynamic>{'a': 1},
      };
      await adapter.writeBundle(uri, data);

      // Mutate original after write
      (data['nested'] as Map<String, dynamic>)['a'] = 999;

      final result = await adapter.readBundle(uri);
      expect((result['nested'] as Map<String, dynamic>)['a'], equals(1));
    });
  });

  group('MemoryStorageAdapter - writeAsset', () {
    test('writes and reads back asset data', () async {
      final uri = Uri.parse('asset://write.bin');
      final data = Uint8List.fromList([10, 20, 30]);
      await adapter.writeAsset(uri, data);
      final result = await adapter.readAsset(uri);
      expect(result, equals(data));
    });

    test('overwrites existing asset', () async {
      final uri = Uri.parse('asset://overwrite.bin');
      await adapter.writeAsset(uri, Uint8List.fromList([1]));
      await adapter.writeAsset(uri, Uint8List.fromList([2]));
      final result = await adapter.readAsset(uri);
      expect(result, equals(Uint8List.fromList([2])));
    });

    test('emits created event for new asset', () async {
      final events = <BundleChangeEvent>[];
      adapter.watch(Uri.parse('asset://any'))?.listen(events.add);

      await adapter.writeAsset(
        Uri.parse('asset://new.bin'),
        Uint8List.fromList([1]),
      );

      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.type, equals(BundleChangeType.created));
    });

    test('emits modified event for existing asset', () async {
      final uri = Uri.parse('asset://mod.bin');
      await adapter.writeAsset(uri, Uint8List.fromList([1]));

      final events = <BundleChangeEvent>[];
      adapter.watch(uri)?.listen(events.add);

      await adapter.writeAsset(uri, Uint8List.fromList([2]));

      await Future<void>.delayed(Duration.zero);

      expect(events.last.type, equals(BundleChangeType.modified));
    });
  });

  // ==================== Exists ====================

  group('MemoryStorageAdapter - exists', () {
    test('returns true for existing bundle', () async {
      adapter.seed('bundle://exists', {'id': 'yes'});
      expect(await adapter.exists(Uri.parse('bundle://exists')), isTrue);
    });

    test('returns true for existing asset', () async {
      adapter.seedAsset('asset://exists', Uint8List.fromList([1]));
      expect(await adapter.exists(Uri.parse('asset://exists')), isTrue);
    });

    test('returns false for non-existing URI', () async {
      expect(await adapter.exists(Uri.parse('bundle://nope')), isFalse);
    });

    test('returns false after deletion', () async {
      final uri = Uri.parse('bundle://delete-me');
      adapter.seed('bundle://delete-me', {'id': 'temp'});
      await adapter.delete(uri);
      expect(await adapter.exists(uri), isFalse);
    });
  });

  // ==================== Delete ====================

  group('MemoryStorageAdapter - delete', () {
    test('deletes existing bundle', () async {
      final uri = Uri.parse('bundle://del');
      adapter.seed('bundle://del', {'id': 'del'});
      await adapter.delete(uri);
      expect(await adapter.exists(uri), isFalse);
    });

    test('deletes existing asset', () async {
      final uri = Uri.parse('asset://del.bin');
      adapter.seedAsset('asset://del.bin', Uint8List.fromList([1]));
      await adapter.delete(uri);
      expect(await adapter.exists(uri), isFalse);
    });

    test('emits deleted event when item existed', () async {
      final uri = Uri.parse('bundle://del-event');
      adapter.seed('bundle://del-event', {'id': 'del'});

      final events = <BundleChangeEvent>[];
      adapter.watch(uri)?.listen(events.add);

      await adapter.delete(uri);

      await Future<void>.delayed(Duration.zero);

      expect(events.last.type, equals(BundleChangeType.deleted));
    });

    test('does not emit event when item did not exist', () async {
      final events = <BundleChangeEvent>[];
      adapter.watch(Uri.parse('bundle://any'))?.listen(events.add);

      await adapter.delete(Uri.parse('bundle://nonexistent'));

      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });
  });

  // ==================== List ====================

  group('MemoryStorageAdapter - list', () {
    test('lists bundles matching prefix', () async {
      adapter.seed('bundle://dir/a.json', {'id': 'a'});
      adapter.seed('bundle://dir/b.json', {'id': 'b'});
      adapter.seed('bundle://other/c.json', {'id': 'c'});

      final results = await adapter.list(Uri.parse('bundle://dir/'));
      expect(results, hasLength(2));
      expect(
        results.map((u) => u.toString()),
        containsAll(['bundle://dir/a.json', 'bundle://dir/b.json']),
      );
    });

    test('returns empty list when no bundles match', () async {
      adapter.seed('bundle://other/x.json', {'id': 'x'});
      final results = await adapter.list(Uri.parse('bundle://empty/'));
      expect(results, isEmpty);
    });

    test('returns empty list when storage is empty', () async {
      final results = await adapter.list(Uri.parse('bundle://'));
      expect(results, isEmpty);
    });

    test('does not list assets (only bundles)', () async {
      adapter.seedAsset('asset://dir/img.png', Uint8List.fromList([1]));
      final results = await adapter.list(Uri.parse('asset://dir/'));
      expect(results, isEmpty);
    });
  });

  // ==================== Watch ====================

  group('MemoryStorageAdapter - watch', () {
    test('returns a broadcast stream', () {
      final stream = adapter.watch(Uri.parse('bundle://any'));
      expect(stream, isNotNull);
    });

    test('stream receives events from multiple operations', () async {
      final events = <BundleChangeEvent>[];
      adapter.watch(Uri.parse('bundle://any'))?.listen(events.add);

      adapter.seed('bundle://w1', {'id': '1'});
      await adapter.writeBundle(Uri.parse('bundle://w2'), {'id': '2'});
      await adapter.delete(Uri.parse('bundle://w1'));

      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(3));
      expect(events[0].type, equals(BundleChangeType.created));
      expect(events[1].type, equals(BundleChangeType.created));
      expect(events[2].type, equals(BundleChangeType.deleted));
    });

    test('change event has correct URI', () async {
      final events = <BundleChangeEvent>[];
      adapter.watch(Uri.parse('bundle://any'))?.listen(events.add);

      adapter.seed('bundle://target', {'id': 'target'});

      await Future<void>.delayed(Duration.zero);

      expect(events.first.uri.toString(), equals('bundle://target'));
    });

    test('change event has timestamp', () async {
      final events = <BundleChangeEvent>[];
      adapter.watch(Uri.parse('bundle://any'))?.listen(events.add);

      final before = DateTime.now();
      adapter.seed('bundle://time', {'id': 'time'});
      await Future<void>.delayed(Duration.zero);
      final after = DateTime.now();

      expect(events.first.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(events.first.timestamp.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });

  // ==================== Clear ====================

  group('MemoryStorageAdapter - clear', () {
    test('removes all bundles', () async {
      adapter.seed('bundle://a', {'id': 'a'});
      adapter.seed('bundle://b', {'id': 'b'});
      adapter.clear();
      expect(adapter.bundleUris, isEmpty);
    });

    test('removes all assets', () async {
      adapter.seedAsset('asset://a', Uint8List.fromList([1]));
      adapter.seedAsset('asset://b', Uint8List.fromList([2]));
      adapter.clear();
      expect(adapter.assetUris, isEmpty);
    });

    test('cleared bundle becomes unreadable', () async {
      adapter.seed('bundle://gone', {'id': 'gone'});
      adapter.clear();
      expect(
        () => adapter.readBundle(Uri.parse('bundle://gone')),
        throwsA(isA<BundleNotFoundException>()),
      );
    });

    test('cleared asset becomes unreadable', () async {
      adapter.seedAsset('asset://gone', Uint8List.fromList([1]));
      adapter.clear();
      expect(
        () => adapter.readAsset(Uri.parse('asset://gone')),
        throwsA(isA<AssetNotFoundException>()),
      );
    });
  });

  // ==================== URI Accessors ====================

  group('MemoryStorageAdapter - URI accessors', () {
    test('bundleUris returns all bundle keys', () {
      adapter.seed('bundle://1', {'id': '1'});
      adapter.seed('bundle://2', {'id': '2'});
      expect(adapter.bundleUris, containsAll(['bundle://1', 'bundle://2']));
    });

    test('assetUris returns all asset keys', () {
      adapter.seedAsset('asset://1', Uint8List.fromList([1]));
      adapter.seedAsset('asset://2', Uint8List.fromList([2]));
      expect(adapter.assetUris, containsAll(['asset://1', 'asset://2']));
    });

    test('bundleUris is empty initially', () {
      expect(adapter.bundleUris, isEmpty);
    });

    test('assetUris is empty initially', () {
      expect(adapter.assetUris, isEmpty);
    });
  });
}
