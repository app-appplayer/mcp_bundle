import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mcp_bundle/src/io/http_storage_adapter.dart';
import 'package:mcp_bundle/src/io/bundle_storage_port.dart';
import 'package:mcp_bundle/src/io/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('HttpStorageAdapter', () {
    group('constructor', () {
      test('creates with defaults', () {
        final adapter = HttpStorageAdapter();
        expect(adapter.baseUrl, isNull);
        expect(adapter.headers, isEmpty);
        expect(adapter.auth, isNull);
        expect(adapter.timeout, equals(const Duration(seconds: 30)));
      });

      test('creates with custom config', () {
        final adapter = HttpStorageAdapter(
          baseUrl: 'https://api.example.com',
          headers: {'X-Custom': 'value'},
          timeout: const Duration(seconds: 10),
        );
        expect(adapter.baseUrl, equals('https://api.example.com'));
        expect(adapter.headers, {'X-Custom': 'value'});
        expect(adapter.timeout, equals(const Duration(seconds: 10)));
      });
    });

    group('registry factory', () {
      test('creates with registry URL', () {
        final adapter = HttpStorageAdapter.registry(
          'https://registry.example.com',
        );
        expect(adapter.baseUrl, equals('https://registry.example.com'));
      });

      test('creates with API key', () {
        final adapter = HttpStorageAdapter.registry(
          'https://registry.example.com',
          apiKey: 'secret-key',
        );
        expect(adapter.headers['X-API-Key'], equals('secret-key'));
      });

      test('creates with custom headers', () {
        final adapter = HttpStorageAdapter.registry(
          'https://registry.example.com',
          headers: {'X-Custom': 'val'},
        );
        expect(adapter.headers['X-Custom'], equals('val'));
      });
    });

    group('readBundle', () {
      test('reads valid JSON bundle', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.toString(),
              equals('https://api.example.com/manifest.json'));
          return http.Response(
            jsonEncode({'manifest': {'id': 'test', 'name': 'Test', 'version': '1.0.0'}}),
            200,
          );
        });

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        final data = await adapter.readBundle(Uri.parse('manifest.json'));
        expect(data['manifest'], isNotNull);
        expect((data['manifest'] as Map<String, dynamic>)['id'], equals('test'));
      });

      test('resolves absolute URL without baseUrl', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.toString(),
              equals('https://cdn.example.com/b.json'));
          return http.Response('{"test": true}', 200);
        });

        final adapter = HttpStorageAdapter(client: mockClient);
        final data =
            await adapter.readBundle(Uri.parse('https://cdn.example.com/b.json'));
        expect(data['test'], isTrue);
      });

      test('throws BundleNotFoundException on 404', () async {
        final mockClient = MockClient(
          (_) async => http.Response('Not Found', 404),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        expect(
          () => adapter.readBundle(Uri.parse('missing.json')),
          throwsA(isA<BundleNotFoundException>()),
        );
      });

      test('throws BundleReadException on non-200 status', () async {
        final mockClient = MockClient(
          (_) async => http.Response('Server Error', 500),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        expect(
          () => adapter.readBundle(Uri.parse('error.json')),
          throwsA(isA<BundleReadException>()),
        );
      });

      test('throws BundleParseException on invalid JSON', () async {
        final mockClient = MockClient(
          (_) async => http.Response('not json', 200),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        expect(
          () => adapter.readBundle(Uri.parse('bad.json')),
          throwsA(isA<BundleParseException>()),
        );
      });

      test('throws BundleParseException when JSON is not an object', () async {
        final mockClient = MockClient(
          (_) async => http.Response('[1,2,3]', 200),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        expect(
          () => adapter.readBundle(Uri.parse('array.json')),
          throwsA(isA<BundleParseException>()),
        );
      });

      test('throws BundleLoadException for relative URI without baseUrl',
          () async {
        final mockClient = MockClient(
          (_) async => http.Response('{}', 200),
        );

        final adapter = HttpStorageAdapter(client: mockClient);

        expect(
          () => adapter.readBundle(Uri.parse('relative.json')),
          throwsA(isA<BundleLoadException>()),
        );
      });
    });

    group('writeBundle', () {
      test('writes bundle data via PUT', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('PUT'));
          expect(request.headers['Content-Type'],
              contains('application/json'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['key'], equals('value'));
          return http.Response('', 201);
        });

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        await adapter.writeBundle(
          Uri.parse('output.json'),
          {'key': 'value'},
        );
      });

      test('accepts 200 status', () async {
        final mockClient = MockClient(
          (_) async => http.Response('', 200),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        await adapter.writeBundle(Uri.parse('out.json'), {});
      });

      test('accepts 204 status', () async {
        final mockClient = MockClient(
          (_) async => http.Response('', 204),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        await adapter.writeBundle(Uri.parse('out.json'), {});
      });

      test('throws BundleWriteException on error status', () async {
        final mockClient = MockClient(
          (_) async => http.Response('Forbidden', 403),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        expect(
          () => adapter.writeBundle(Uri.parse('out.json'), {}),
          throwsA(isA<BundleWriteException>()),
        );
      });
    });

    group('readAsset', () {
      test('reads binary asset', () async {
        final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        final mockClient = MockClient((request) async {
          expect(request.headers.containsKey('Accept'), isFalse);
          return http.Response.bytes(bytes, 200);
        });

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        final result = await adapter.readAsset(Uri.parse('image.png'));
        expect(result, equals(bytes));
      });

      test('throws AssetNotFoundException on 404', () async {
        final mockClient = MockClient(
          (_) async => http.Response('', 404),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        expect(
          () => adapter.readAsset(Uri.parse('missing.png')),
          throwsA(isA<AssetNotFoundException>()),
        );
      });

      test('throws BundleReadException on non-200 status', () async {
        final mockClient = MockClient(
          (_) async => http.Response('Error', 500),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        expect(
          () => adapter.readAsset(Uri.parse('error.png')),
          throwsA(isA<BundleReadException>()),
        );
      });
    });

    group('writeAsset', () {
      test('writes binary asset via PUT', () async {
        final bytes = Uint8List.fromList([10, 20, 30]);
        final mockClient = MockClient((request) async {
          expect(request.method, equals('PUT'));
          expect(request.headers['Content-Type'],
              equals('application/octet-stream'));
          expect(request.bodyBytes, equals(bytes));
          return http.Response('', 201);
        });

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        await adapter.writeAsset(Uri.parse('data.bin'), bytes);
      });

      test('throws BundleWriteException on error status', () async {
        final mockClient = MockClient(
          (_) async => http.Response('', 500),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        expect(
          () => adapter.writeAsset(Uri.parse('data.bin'), Uint8List(0)),
          throwsA(isA<BundleWriteException>()),
        );
      });
    });

    group('exists', () {
      test('returns true on 200', () async {
        final mockClient = MockClient(
          (_) async => http.Response('', 200),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        expect(await adapter.exists(Uri.parse('manifest.json')), isTrue);
      });

      test('returns false on non-200', () async {
        final mockClient = MockClient(
          (_) async => http.Response('', 404),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        expect(await adapter.exists(Uri.parse('missing.json')), isFalse);
      });

      test('returns false on client exception', () async {
        final mockClient = MockClient(
          (_) async => throw http.ClientException('network error'),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        expect(await adapter.exists(Uri.parse('error.json')), isFalse);
      });
    });

    group('delete', () {
      test('succeeds on 200', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('DELETE'));
          return http.Response('', 200);
        });

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        await adapter.delete(Uri.parse('manifest.json'));
      });

      test('succeeds on 204', () async {
        final mockClient = MockClient(
          (_) async => http.Response('', 204),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        await adapter.delete(Uri.parse('manifest.json'));
      });

      test('succeeds on 404 (already gone)', () async {
        final mockClient = MockClient(
          (_) async => http.Response('', 404),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        await adapter.delete(Uri.parse('gone.json'));
      });

      test('throws BundleWriteException on error status', () async {
        final mockClient = MockClient(
          (_) async => http.Response('', 500),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        expect(
          () => adapter.delete(Uri.parse('error.json')),
          throwsA(isA<BundleWriteException>()),
        );
      });
    });

    group('list', () {
      test('parses string array response', () async {
        final mockClient = MockClient(
          (_) async => http.Response(
            jsonEncode(['bundle-a.json', 'bundle-b.json']),
            200,
          ),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        final uris = await adapter.list(Uri.parse('bundles/'));
        expect(uris, hasLength(2));
        expect(uris[0].toString(), equals('bundle-a.json'));
        expect(uris[1].toString(), equals('bundle-b.json'));
      });

      test('parses object array with uri field', () async {
        final mockClient = MockClient(
          (_) async => http.Response(
            jsonEncode([
              {'uri': 'https://cdn.example.com/a.json'},
              {'uri': 'https://cdn.example.com/b.json'},
            ]),
            200,
          ),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        final uris = await adapter.list(Uri.parse('bundles/'));
        expect(uris, hasLength(2));
      });

      test('parses object array with path field', () async {
        final mockClient = MockClient(
          (_) async => http.Response(
            jsonEncode([
              {'path': '/bundles/a.json'},
            ]),
            200,
          ),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        final uris = await adapter.list(Uri.parse('bundles/'));
        expect(uris, hasLength(1));
      });

      test('returns empty list on non-200', () async {
        final mockClient = MockClient(
          (_) async => http.Response('', 500),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        final uris = await adapter.list(Uri.parse('bundles/'));
        expect(uris, isEmpty);
      });

      test('returns empty list on non-array response', () async {
        final mockClient = MockClient(
          (_) async => http.Response('{"key":"value"}', 200),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        final uris = await adapter.list(Uri.parse('bundles/'));
        expect(uris, isEmpty);
      });

      test('returns empty list on invalid JSON', () async {
        final mockClient = MockClient(
          (_) async => http.Response('not json', 200),
        );

        final adapter = HttpStorageAdapter(
          client: mockClient,
          baseUrl: 'https://api.example.com',
        );

        final uris = await adapter.list(Uri.parse('bundles/'));
        expect(uris, isEmpty);
      });
    });

    group('watch', () {
      test('returns null (HTTP does not support watching)', () {
        final adapter = HttpStorageAdapter(
          baseUrl: 'https://api.example.com',
        );
        expect(adapter.watch(Uri.parse('manifest.json')), isNull);
      });
    });
  });

  group('HttpAuthConfig', () {
    test('bearer creates bearer config', () {
      const auth = HttpAuthConfig.bearer('my-token');
      expect(auth.type, equals(HttpAuthType.bearer));
      expect(auth.token, equals('my-token'));
      expect(auth.username, isNull);
      expect(auth.password, isNull);
    });

    test('basic creates basic auth config', () {
      const auth = HttpAuthConfig.basic(
        username: 'user',
        password: 'pass',
      );
      expect(auth.type, equals(HttpAuthType.basic));
      expect(auth.username, equals('user'));
      expect(auth.password, equals('pass'));
      expect(auth.token, isNull);
    });

    test('apiKey creates API key config', () {
      const auth = HttpAuthConfig.apiKey('key-123');
      expect(auth.type, equals(HttpAuthType.apiKey));
      expect(auth.token, equals('key-123'));
      expect(auth.headerName, equals('X-API-Key'));
    });

    test('apiKey with custom header name', () {
      const auth =
          HttpAuthConfig.apiKey('key-456', headerName: 'X-Custom-Key');
      expect(auth.headerName, equals('X-Custom-Key'));
    });
  });

  group('Authentication headers', () {
    test('bearer token adds Authorization header', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.headers['Authorization'],
          equals('Bearer my-token'),
        );
        return http.Response('{}', 200);
      });

      final adapter = HttpStorageAdapter(
        client: mockClient,
        baseUrl: 'https://api.example.com',
        auth: const HttpAuthConfig.bearer('my-token'),
      );

      await adapter.readBundle(Uri.parse('manifest.json'));
    });

    test('basic auth adds encoded Authorization header', () async {
      final mockClient = MockClient((request) async {
        final expected =
            'Basic ${base64Encode(utf8.encode('user:pass'))}';
        expect(request.headers['Authorization'], equals(expected));
        return http.Response('{}', 200);
      });

      final adapter = HttpStorageAdapter(
        client: mockClient,
        baseUrl: 'https://api.example.com',
        auth: const HttpAuthConfig.basic(
          username: 'user',
          password: 'pass',
        ),
      );

      await adapter.readBundle(Uri.parse('manifest.json'));
    });

    test('API key adds custom header', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['X-API-Key'], equals('my-key'));
        return http.Response('{}', 200);
      });

      final adapter = HttpStorageAdapter(
        client: mockClient,
        baseUrl: 'https://api.example.com',
        auth: const HttpAuthConfig.apiKey('my-key'),
      );

      await adapter.readBundle(Uri.parse('manifest.json'));
    });
  });

  group('URL resolution', () {
    test('resolves relative URI with baseUrl', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(),
            equals('https://api.example.com/bundles/test.json'));
        return http.Response('{}', 200);
      });

      final adapter = HttpStorageAdapter(
        client: mockClient,
        baseUrl: 'https://api.example.com',
      );

      await adapter.readBundle(Uri.parse('bundles/test.json'));
    });

    test('baseUrl with trailing slash works', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(),
            equals('https://api.example.com/test.json'));
        return http.Response('{}', 200);
      });

      final adapter = HttpStorageAdapter(
        client: mockClient,
        baseUrl: 'https://api.example.com/',
      );

      await adapter.readBundle(Uri.parse('test.json'));
    });

    test('absolute URL ignores baseUrl', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(),
            equals('https://cdn.example.com/manifest.json'));
        return http.Response('{}', 200);
      });

      final adapter = HttpStorageAdapter(
        client: mockClient,
        baseUrl: 'https://api.example.com',
      );

      await adapter.readBundle(
          Uri.parse('https://cdn.example.com/manifest.json'));
    });
  });

  group('BundleChangeEvent', () {
    test('creates with required fields', () {
      final event = BundleChangeEvent(
        uri: Uri.parse('manifest.json'),
        type: BundleChangeType.modified,
        timestamp: DateTime.utc(2025, 1, 1),
      );
      expect(event.uri.toString(), equals('manifest.json'));
      expect(event.type, equals(BundleChangeType.modified));
    });
  });
}
