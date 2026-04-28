/// Tests for HttpStorageAdapter ClientException handling.
///
/// Covers all `on http.ClientException catch` blocks and
/// `on TimeoutException catch` in the list method.
library;

import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mcp_bundle/src/io/exceptions.dart';
import 'package:mcp_bundle/src/io/http_storage_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('HttpStorageAdapter ClientException handling', () {
    late HttpStorageAdapter adapter;

    setUp(() {
      final client = MockClient((request) {
        throw http.ClientException('connection failed');
      });
      adapter = HttpStorageAdapter(
        client: client,
        baseUrl: 'https://example.com',
      );
    });

    test('readBundle throws BundleReadException on ClientException', () async {
      await expectLater(
        adapter.readBundle(Uri.parse('bundles/test.json')),
        throwsA(
          isA<BundleReadException>().having(
            (e) => e.message,
            'message',
            contains('HTTP error: connection failed'),
          ),
        ),
      );
    });

    test('writeBundle throws BundleWriteException on ClientException',
        () async {
      await expectLater(
        adapter.writeBundle(
          Uri.parse('bundles/test.json'),
          <String, dynamic>{'name': 'test'},
        ),
        throwsA(
          isA<BundleWriteException>().having(
            (e) => e.message,
            'message',
            contains('HTTP error: connection failed'),
          ),
        ),
      );
    });

    test('readAsset throws BundleReadException on ClientException', () async {
      await expectLater(
        adapter.readAsset(Uri.parse('assets/test.bin')),
        throwsA(
          isA<BundleReadException>().having(
            (e) => e.message,
            'message',
            contains('HTTP error: connection failed'),
          ),
        ),
      );
    });

    test('writeAsset throws BundleWriteException on ClientException',
        () async {
      await expectLater(
        adapter.writeAsset(
          Uri.parse('assets/test.bin'),
          Uint8List.fromList([1, 2, 3]),
        ),
        throwsA(
          isA<BundleWriteException>().having(
            (e) => e.message,
            'message',
            contains('HTTP error: connection failed'),
          ),
        ),
      );
    });

    test('delete throws BundleWriteException on ClientException', () async {
      await expectLater(
        adapter.delete(Uri.parse('bundles/test.json')),
        throwsA(
          isA<BundleWriteException>().having(
            (e) => e.message,
            'message',
            contains('HTTP error: connection failed'),
          ),
        ),
      );
    });

    test('exists returns false on ClientException', () async {
      final result = await adapter.exists(Uri.parse('bundles/test.json'));
      expect(result, isFalse);
    });

    test('list returns empty list on ClientException', () async {
      final result = await adapter.list(Uri.parse('bundles/'));
      expect(result, isEmpty);
    });
  });

  group('HttpStorageAdapter TimeoutException in list', () {
    test('list returns empty list on TimeoutException', () async {
      // Use a MockClient that delays longer than the timeout
      final client = MockClient((request) async {
        await Future<void>.delayed(const Duration(seconds: 5));
        return http.Response('[]', 200);
      });
      final adapter = HttpStorageAdapter(
        client: client,
        baseUrl: 'https://example.com',
        // Use a very short timeout to trigger TimeoutException
        timeout: const Duration(milliseconds: 1),
      );

      final result = await adapter.list(Uri.parse('bundles/'));
      expect(result, isEmpty);
    });
  });
}
