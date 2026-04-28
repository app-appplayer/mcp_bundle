import 'package:test/test.dart';
import 'package:mcp_bundle/ports.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  // ==========================================================================
  // UiResult
  // ==========================================================================
  group('UiResult', () {
    test('ok creates a successful result', () {
      const result = UiResult.ok({'key': 'value'});
      expect(result.success, isTrue);
      expect(result.data, equals({'key': 'value'}));
      expect(result.error, isNull);
      expect(result.warnings, isNull);
    });

    test('fail creates a failed result', () {
      final error = UiError(code: 'ERR', message: 'Something went wrong');
      final result = UiResult<Map<String, dynamic>>.fail(error);
      expect(result.success, isFalse);
      expect(result.data, isNull);
      expect(result.error, isNotNull);
      expect(result.error!.code, equals('ERR'));
    });

    test('okWithWarnings creates success with warnings', () {
      final warnings = [
        UiError(code: 'WARN', message: 'Minor issue'),
      ];
      final result =
          UiResult.okWithWarnings(const {'key': 'value'}, warnings);
      expect(result.success, isTrue);
      expect(result.data, isNotNull);
      expect(result.warnings, hasLength(1));
      expect(result.warnings!.first.code, equals('WARN'));
    });

    test('toJson serializes correctly', () {
      final result = UiResult.ok({'key': 'value'});
      final json = result.toJson((data) => data);
      expect(json['success'], isTrue);
      expect(json['data'], equals({'key': 'value'}));
    });

    test('toJson with error serializes correctly', () {
      final error = UiError(code: 'ERR', message: 'fail');
      final result = UiResult<Map<String, dynamic>>.fail(error);
      final json = result.toJson();
      expect(json['success'], isFalse);
      expect(json['error'], isNotNull);
      expect((json['error'] as Map<String, dynamic>)['code'], equals('ERR'));
    });
  });

  // ==========================================================================
  // UiError
  // ==========================================================================
  group('UiError', () {
    test('creates with required fields', () {
      final error = UiError(code: 'NOT_FOUND', message: 'Not found');
      expect(error.code, equals('NOT_FOUND'));
      expect(error.message, equals('Not found'));
      expect(error.path, isNull);
      expect(error.context, isNull);
    });

    test('creates with all fields', () {
      final error = UiError(
        code: 'INVALID',
        message: 'Invalid field',
        path: '/ui/screens/0',
        context: {'expected': 'string'},
      );
      expect(error.path, equals('/ui/screens/0'));
      expect(error.context, equals({'expected': 'string'}));
    });

    test('fromJson parses correctly', () {
      final json = {
        'code': 'ERR',
        'message': 'Error message',
        'path': '/root',
        'context': {'detail': 'info'},
      };
      final error = UiError.fromJson(json);
      expect(error.code, equals('ERR'));
      expect(error.message, equals('Error message'));
      expect(error.path, equals('/root'));
      expect(error.context, equals({'detail': 'info'}));
    });

    test('toJson serializes correctly', () {
      final error = UiError(
        code: 'ERR',
        message: 'msg',
        path: '/p',
      );
      final json = error.toJson();
      expect(json['code'], equals('ERR'));
      expect(json['message'], equals('msg'));
      expect(json['path'], equals('/p'));
      expect(json.containsKey('context'), isFalse);
    });

    test('toString includes code and message', () {
      final error = UiError(code: 'ERR', message: 'msg');
      expect(error.toString(), equals('UiError(ERR: msg)'));
    });

    test('toString includes path when present', () {
      final error = UiError(code: 'ERR', message: 'msg', path: '/a/b');
      expect(error.toString(), equals('UiError(ERR: msg at /a/b)'));
    });
  });

  // ==========================================================================
  // UiWriteOutput
  // ==========================================================================
  group('UiWriteOutput', () {
    test('creates with required fields', () {
      final output = UiWriteOutput(
        uiSection: const UiSection(),
        manifestMetadata: {'name': 'Test'},
      );
      expect(output.uiSection, isA<UiSection>());
      expect(output.manifestMetadata['name'], equals('Test'));
    });
  });

  // ==========================================================================
  // StubUiPort
  // ==========================================================================
  group('StubUiPort', () {
    late StubUiPort port;
    late McpBundle bundle;

    setUp(() {
      port = StubUiPort();
      bundle = const McpBundle(
        manifest: BundleManifest(
          id: 'com.example.test',
          name: 'Test App',
          version: '1.0.0',
          description: 'A test application',
        ),
      );
    });

    test('implements UiPort', () {
      expect(port, isA<UiPort>());
    });

    group('toDefinition', () {
      test('returns success with bundle metadata', () async {
        final result = await port.toDefinition(bundle);
        expect(result.success, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!['type'], equals('application'));
        expect(result.data!['title'], equals('Test App'));
        expect(result.data!['version'], equals('1.0.0'));
      });
    });

    group('toAppInfo', () {
      test('returns success with app info subset', () async {
        final result = await port.toAppInfo(bundle);
        expect(result.success, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!['id'], equals('com.example.test'));
        expect(result.data!['name'], equals('Test App'));
        expect(result.data!['version'], equals('1.0.0'));
        expect(result.data!['description'], equals('A test application'));
      });

      test('omits null optional fields', () async {
        const minimalBundle = McpBundle(
          manifest: BundleManifest(
            id: 'com.example.minimal',
            name: 'Minimal',
            version: '0.1.0',
          ),
        );
        final result = await port.toAppInfo(minimalBundle);
        expect(result.success, isTrue);
        expect(result.data!.containsKey('description'), isFalse);
        expect(result.data!.containsKey('icon'), isFalse);
        expect(result.data!.containsKey('category'), isFalse);
      });
    });

    group('fromDefinition', () {
      test('returns success with extracted sections', () async {
        final definitionJson = <String, dynamic>{
          'title': 'Generated App',
          'version': '2.0.0',
          'id': 'com.example.gen',
          'description': 'Generated application',
        };
        final result = await port.fromDefinition(definitionJson);
        expect(result.success, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.uiSection, isA<UiSection>());
        expect(result.data!.manifestMetadata['name'], equals('Generated App'));
        expect(result.data!.manifestMetadata['version'], equals('2.0.0'));
        expect(result.data!.manifestMetadata['id'], equals('com.example.gen'));
        expect(
          result.data!.manifestMetadata['description'],
          equals('Generated application'),
        );
      });

      test('omits null fields from manifestMetadata', () async {
        final definitionJson = <String, dynamic>{
          'title': 'Minimal',
        };
        final result = await port.fromDefinition(definitionJson);
        expect(result.success, isTrue);
        expect(result.data!.manifestMetadata['name'], equals('Minimal'));
        expect(
          result.data!.manifestMetadata.containsKey('version'),
          isFalse,
        );
        expect(result.data!.manifestMetadata.containsKey('id'), isFalse);
      });

      test('handles empty definition', () async {
        final result =
            await port.fromDefinition(<String, dynamic>{});
        expect(result.success, isTrue);
        expect(result.data!.uiSection, isA<UiSection>());
        expect(result.data!.manifestMetadata, isEmpty);
      });
    });
  });
}
