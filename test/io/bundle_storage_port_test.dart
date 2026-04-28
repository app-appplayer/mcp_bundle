import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  // ==================== BundleChangeType ====================

  group('BundleChangeType', () {
    test('has created value', () {
      expect(BundleChangeType.created, isNotNull);
    });

    test('has modified value', () {
      expect(BundleChangeType.modified, isNotNull);
    });

    test('has deleted value', () {
      expect(BundleChangeType.deleted, isNotNull);
    });

    test('has exactly three values', () {
      expect(BundleChangeType.values.length, equals(3));
    });

    test('all values are distinct', () {
      final unique = BundleChangeType.values.toSet();
      expect(unique.length, equals(BundleChangeType.values.length));
    });

    test('values list contains all enum members', () {
      expect(
        BundleChangeType.values,
        containsAll([
          BundleChangeType.created,
          BundleChangeType.modified,
          BundleChangeType.deleted,
        ]),
      );
    });
  });

  // ==================== BundleChangeEvent ====================

  group('BundleChangeEvent', () {
    group('construction', () {
      test('creates event with all required fields', () {
        final now = DateTime.now();
        final uri = Uri.parse('bundle://test/my-manifest.json');
        final event = BundleChangeEvent(
          uri: uri,
          type: BundleChangeType.created,
          timestamp: now,
        );
        expect(event.uri, equals(uri));
        expect(event.type, equals(BundleChangeType.created));
        expect(event.timestamp, equals(now));
      });

      test('creates event with modified type', () {
        final event = BundleChangeEvent(
          uri: Uri.parse('bundle://mod'),
          type: BundleChangeType.modified,
          timestamp: DateTime.now(),
        );
        expect(event.type, equals(BundleChangeType.modified));
      });

      test('creates event with deleted type', () {
        final event = BundleChangeEvent(
          uri: Uri.parse('bundle://del'),
          type: BundleChangeType.deleted,
          timestamp: DateTime.now(),
        );
        expect(event.type, equals(BundleChangeType.deleted));
      });

      test('preserves URI scheme and path', () {
        final uri = Uri.parse('file:///home/user/bundles/app.json');
        final event = BundleChangeEvent(
          uri: uri,
          type: BundleChangeType.created,
          timestamp: DateTime.now(),
        );
        expect(event.uri.scheme, equals('file'));
        expect(event.uri.path, equals('/home/user/bundles/app.json'));
      });

      test('preserves exact timestamp', () {
        final timestamp = DateTime(2026, 2, 22, 10, 30, 45);
        final event = BundleChangeEvent(
          uri: Uri.parse('bundle://ts'),
          type: BundleChangeType.created,
          timestamp: timestamp,
        );
        expect(event.timestamp, equals(timestamp));
      });
    });

    group('toString', () {
      test('includes type in string representation', () {
        final event = BundleChangeEvent(
          uri: Uri.parse('bundle://str'),
          type: BundleChangeType.created,
          timestamp: DateTime.now(),
        );
        expect(event.toString(), contains('created'));
      });

      test('includes URI in string representation', () {
        final event = BundleChangeEvent(
          uri: Uri.parse('bundle://my-uri'),
          type: BundleChangeType.modified,
          timestamp: DateTime.now(),
        );
        expect(event.toString(), contains('bundle://my-uri'));
      });

      test('includes timestamp in string representation', () {
        final timestamp = DateTime(2026, 1, 15, 12, 0, 0);
        final event = BundleChangeEvent(
          uri: Uri.parse('bundle://time'),
          type: BundleChangeType.deleted,
          timestamp: timestamp,
        );
        final str = event.toString();
        expect(str, contains('2026'));
      });

      test('toString contains BundleChangeEvent prefix', () {
        final event = BundleChangeEvent(
          uri: Uri.parse('bundle://prefix'),
          type: BundleChangeType.created,
          timestamp: DateTime.now(),
        );
        expect(event.toString(), startsWith('BundleChangeEvent'));
      });
    });
  });

  // ==================== BundleStoragePort interface ====================

  group('BundleStoragePort', () {
    test('MemoryStorageAdapter implements BundleStoragePort', () {
      final adapter = MemoryStorageAdapter();
      expect(adapter, isA<BundleStoragePort>());
      adapter.dispose();
    });
  });
}
