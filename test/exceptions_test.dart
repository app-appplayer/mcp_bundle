import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  group('BundleLoadException', () {
    test('creates exception with message', () {
      final exception = BundleLoadException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.cause, isNull);
    });

    test('creates exception with message and cause', () {
      final cause = Exception('Original error');
      final exception = BundleLoadException('Test error', cause);
      expect(exception.message, equals('Test error'));
      expect(exception.cause, equals(cause));
    });

    test('toString returns formatted message', () {
      final exception = BundleLoadException('Test error');
      expect(exception.toString(), equals('BundleLoadException: Test error'));
    });
  });

  group('BundleParseException', () {
    test('creates exception with message only', () {
      final exception = BundleParseException('Parse error');
      expect(exception.message, equals('Parse error'));
      expect(exception.line, isNull);
      expect(exception.column, isNull);
    });

    test('creates exception with line number', () {
      final exception = BundleParseException('Parse error', line: 10);
      expect(exception.message, equals('Parse error'));
      expect(exception.line, equals(10));
    });

    test('creates exception with line and column', () {
      final exception = BundleParseException('Parse error', line: 10, column: 5);
      expect(exception.line, equals(10));
      expect(exception.column, equals(5));
    });

    test('toString includes line number when present', () {
      final exception = BundleParseException('Parse error', line: 10);
      expect(exception.toString(), equals('BundleParseException: Parse error at line 10'));
    });

    test('toString omits line number when null', () {
      final exception = BundleParseException('Parse error');
      expect(exception.toString(), equals('BundleParseException: Parse error'));
    });
  });

  group('BundleMissingFieldException', () {
    test('creates exception with field path', () {
      final exception = BundleMissingFieldException('manifest.id');
      expect(exception.fieldPath, equals('manifest.id'));
      expect(exception.message, contains('manifest.id'));
    });

    test('toString returns formatted message', () {
      final exception = BundleMissingFieldException('manifest.id');
      expect(exception.toString(), equals('BundleMissingFieldException: Missing field "manifest.id"'));
    });
  });

  group('BundleInvalidValueException', () {
    test('creates exception with field path and value', () {
      final exception = BundleInvalidValueException('manifest.version', 123, 'string');
      expect(exception.fieldPath, equals('manifest.version'));
      expect(exception.value, equals(123));
      expect(exception.expectedType, equals('string'));
    });

    test('message includes type information', () {
      final exception = BundleInvalidValueException('field', 'value', 'number');
      expect(exception.message, contains('expected number'));
      expect(exception.message, contains('String'));
    });

    test('toString returns formatted message', () {
      final exception = BundleInvalidValueException('field', 123, 'string');
      expect(exception.toString(), contains('Invalid value at "field"'));
      expect(exception.toString(), contains('expected string'));
    });
  });

  group('BundleSchemaVersionException', () {
    test('creates exception with version and supported versions', () {
      final exception = BundleSchemaVersionException('2.0.0', ['1.0.0', '1.1.0']);
      expect(exception.foundVersion, equals('2.0.0'));
      expect(exception.supportedVersions, equals(['1.0.0', '1.1.0']));
    });

    test('message includes found version', () {
      final exception = BundleSchemaVersionException('2.0.0', ['1.0.0']);
      expect(exception.message, contains('2.0.0'));
    });

    test('toString includes supported versions', () {
      final exception = BundleSchemaVersionException('2.0.0', ['1.0.0', '1.1.0']);
      expect(exception.toString(), contains('2.0.0'));
      expect(exception.toString(), contains('1.0.0, 1.1.0'));
    });
  });

  group('BundleReferenceException', () {
    test('creates exception with reference and type', () {
      final exception = BundleReferenceException('skill_id', 'skill');
      expect(exception.reference, equals('skill_id'));
      expect(exception.referenceType, equals('skill'));
    });

    test('message includes reference type', () {
      final exception = BundleReferenceException('asset_id', 'asset');
      expect(exception.message, contains('asset'));
      expect(exception.message, contains('asset_id'));
    });

    test('toString returns formatted message', () {
      final exception = BundleReferenceException('ref', 'type');
      expect(exception.toString(), contains('Unresolved type reference "ref"'));
    });
  });

  group('BundleValidationException', () {
    test('creates exception with message', () {
      final exception = BundleValidationException('Validation failed');
      expect(exception.message, equals('Validation failed'));
      expect(exception.errors, isEmpty);
      expect(exception.warnings, isEmpty);
    });

    test('creates exception with errors and warnings', () {
      final errors = [BundleMissingFieldException('field')];
      final warnings = ['Warning 1', 'Warning 2'];
      final exception = BundleValidationException(
        'Validation failed',
        errors: errors,
        warnings: warnings,
      );
      expect(exception.errors, hasLength(1));
      expect(exception.warnings, hasLength(2));
    });

    test('toString includes error and warning counts', () {
      final errors = [
        BundleMissingFieldException('field1'),
        BundleMissingFieldException('field2'),
      ];
      final warnings = ['Warning 1'];
      final exception = BundleValidationException(
        'Validation failed',
        errors: errors,
        warnings: warnings,
      );
      expect(exception.toString(), contains('2 errors'));
      expect(exception.toString(), contains('1 warnings'));
    });
  });
}
