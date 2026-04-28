import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  group('TypeCoercionRules', () {
    test('default constructor has all rules disabled', () {
      const rules = TypeCoercionRules();
      expect(rules.stringToBool, isFalse);
      expect(rules.stringToNumber, isFalse);
      expect(rules.singleToList, isFalse);
      expect(rules.numberToBool, isFalse);
    });

    test('lenient constructor has all rules enabled', () {
      const rules = TypeCoercionRules.lenient();
      expect(rules.stringToBool, isTrue);
      expect(rules.stringToNumber, isTrue);
      expect(rules.singleToList, isTrue);
      expect(rules.numberToBool, isTrue);
    });

    test('strict constructor has all rules disabled', () {
      const rules = TypeCoercionRules.strict();
      expect(rules.stringToBool, isFalse);
      expect(rules.stringToNumber, isFalse);
      expect(rules.singleToList, isFalse);
      expect(rules.numberToBool, isFalse);
    });

    test('custom rules can be set individually', () {
      const rules = TypeCoercionRules(
        stringToBool: true,
        stringToNumber: false,
        singleToList: true,
        numberToBool: false,
      );
      expect(rules.stringToBool, isTrue);
      expect(rules.stringToNumber, isFalse);
      expect(rules.singleToList, isTrue);
      expect(rules.numberToBool, isFalse);
    });
  });

  group('TypeCoercer', () {
    group('coerce', () {
      test('returns null for null value', () {
        final coercer = TypeCoercer(const TypeCoercionRules());
        expect(coercer.coerce<String>(null), isNull);
      });

      test('returns default for null value when default provided', () {
        final coercer = TypeCoercer(const TypeCoercionRules());
        expect(coercer.coerce<String>(null, defaultValue: 'default'), equals('default'));
      });

      test('coerces 1 to true when numberToBool enabled', () {
        final coercer = TypeCoercer(const TypeCoercionRules.lenient());
        expect(coercer.coerce<bool>(1), isTrue);
      });

      test('coerces 0 to false when numberToBool enabled', () {
        final coercer = TypeCoercer(const TypeCoercionRules.lenient());
        expect(coercer.coerce<bool>(0), isFalse);
      });

      test('does not coerce number to bool when disabled', () {
        final coercer = TypeCoercer(const TypeCoercionRules.strict());
        expect(coercer.coerce<bool>(1), isNull);
      });

      test('returns value when type matches', () {
        final coercer = TypeCoercer(const TypeCoercionRules());
        expect(coercer.coerce<String>('test'), equals('test'));
        expect(coercer.coerce<int>(42), equals(42));
        expect(coercer.coerce<bool>(true), isTrue);
      });

      test('coerces "true" to bool when enabled', () {
        final coercer = TypeCoercer(const TypeCoercionRules.lenient());
        expect(coercer.coerce<bool>('true'), isTrue);
        expect(coercer.coerce<bool>('TRUE'), isTrue);
        expect(coercer.coerce<bool>('True'), isTrue);
      });

      test('coerces "false" to bool when enabled', () {
        final coercer = TypeCoercer(const TypeCoercionRules.lenient());
        expect(coercer.coerce<bool>('false'), isFalse);
        expect(coercer.coerce<bool>('FALSE'), isFalse);
        expect(coercer.coerce<bool>('False'), isFalse);
      });

      test('does not coerce string to bool when disabled', () {
        final coercer = TypeCoercer(const TypeCoercionRules.strict());
        expect(coercer.coerce<bool>('true'), isNull);
      });

      test('coerces string to int when enabled', () {
        final coercer = TypeCoercer(const TypeCoercionRules.lenient());
        expect(coercer.coerce<int>('42'), equals(42));
        expect(coercer.coerce<int>('-10'), equals(-10));
      });

      test('coerces string to double when enabled', () {
        final coercer = TypeCoercer(const TypeCoercionRules.lenient());
        expect(coercer.coerce<double>('3.14'), equals(3.14));
        expect(coercer.coerce<double>('-2.5'), equals(-2.5));
      });

      test('coerces string to num when enabled', () {
        final coercer = TypeCoercer(const TypeCoercionRules.lenient());
        expect(coercer.coerce<num>('42'), equals(42));
        expect(coercer.coerce<num>('3.14'), equals(3.14));
      });

      test('does not coerce string to number when disabled', () {
        final coercer = TypeCoercer(const TypeCoercionRules.strict());
        expect(coercer.coerce<int>('42'), isNull);
      });

      test('returns null for invalid number string', () {
        final coercer = TypeCoercer(const TypeCoercionRules.lenient());
        expect(coercer.coerce<int>('not a number'), isNull);
      });

      test('coerces single value to list when enabled', () {
        final coercer = TypeCoercer(const TypeCoercionRules.lenient());
        final result = coercer.coerce<List<dynamic>>('single');
        expect(result, isA<List<dynamic>>());
        expect(result, contains('single'));
      });

      test('does not coerce single to list when disabled', () {
        final coercer = TypeCoercer(const TypeCoercionRules.strict());
        expect(coercer.coerce<List<dynamic>>('single'), isNull);
      });
    });

    group('parseRequired', () {
      test('returns value when present', () {
        final coercer = TypeCoercer(const TypeCoercionRules());
        final errors = <BundleLoadException>[];
        final result = coercer.parseRequired<String>(
          {'field': 'value'},
          'field',
          errors,
        );
        expect(result, equals('value'));
        expect(errors, isEmpty);
      });

      test('adds error and throws when field is missing', () {
        final coercer = TypeCoercer(const TypeCoercionRules());
        final errors = <BundleLoadException>[];
        expect(
          () => coercer.parseRequired<String>({}, 'field', errors),
          throwsA(isA<BundleMissingFieldException>()),
        );
        expect(errors, hasLength(1));
      });

      test('returns default value when field is missing and default is provided', () {
        final coercer = TypeCoercer(const TypeCoercionRules());
        final errors = <BundleLoadException>[];
        final result = coercer.parseRequired<String>(
          {},
          'field',
          errors,
          defaultValue: 'default',
        );
        expect(result, equals('default'));
        expect(errors, hasLength(1));
      });
    });

    group('parseOptional', () {
      test('returns value when present', () {
        final coercer = TypeCoercer(const TypeCoercionRules());
        final result = coercer.parseOptional<String>(
          {'field': 'value'},
          'field',
        );
        expect(result, equals('value'));
      });

      test('returns default value when field is missing', () {
        final coercer = TypeCoercer(const TypeCoercionRules());
        final result = coercer.parseOptional<String>(
          {},
          'field',
          defaultValue: 'default',
        );
        expect(result, equals('default'));
      });

      test('returns null when field is missing and no default', () {
        final coercer = TypeCoercer(const TypeCoercionRules());
        final result = coercer.parseOptional<String>({}, 'field');
        expect(result, isNull);
      });
    });

    group('parseList', () {
      test('returns list when field is a list', () {
        final coercer = TypeCoercer(const TypeCoercionRules());
        final result = coercer.parseList<String>(
          {'items': ['a', 'b', 'c']},
          'items',
        );
        expect(result, equals(['a', 'b', 'c']));
      });

      test('returns empty list when field is missing', () {
        final coercer = TypeCoercer(const TypeCoercionRules());
        final result = coercer.parseList<String>({}, 'items');
        expect(result, isEmpty);
      });

      test('returns default list when field is missing and default provided', () {
        final coercer = TypeCoercer(const TypeCoercionRules());
        final result = coercer.parseList<String>(
          {},
          'items',
          defaultValue: ['default'],
        );
        expect(result, equals(['default']));
      });

      test('coerces single value to list when enabled', () {
        final coercer = TypeCoercer(const TypeCoercionRules.lenient());
        final result = coercer.parseList<String>(
          {'items': 'single'},
          'items',
        );
        expect(result, equals(['single']));
      });

      test('returns empty list for single value when coercion disabled', () {
        final coercer = TypeCoercer(const TypeCoercionRules.strict());
        final result = coercer.parseList<String>(
          {'items': 'single'},
          'items',
        );
        expect(result, isEmpty);
      });

      test('uses item parser when provided', () {
        final coercer = TypeCoercer(const TypeCoercionRules());
        final result = coercer.parseList<int>(
          {'items': [1, 2, 3]},
          'items',
          itemParser: (item) => (item as int) * 2,
        );
        expect(result, equals([2, 4, 6]));
      });

      test('filters by type when no item parser', () {
        final coercer = TypeCoercer(const TypeCoercionRules());
        final result = coercer.parseList<String>(
          {'items': ['a', 1, 'b', 2]},
          'items',
        );
        expect(result, equals(['a', 'b']));
      });
    });
  });

  group('RecoveryStrategy', () {
    test('has all expected values', () {
      expect(RecoveryStrategy.values, contains(RecoveryStrategy.skip));
      expect(RecoveryStrategy.values, contains(RecoveryStrategy.useDefault));
      expect(RecoveryStrategy.values, contains(RecoveryStrategy.repair));
      expect(RecoveryStrategy.values, contains(RecoveryStrategy.fail));
    });
  });

  group('ErrorRecoveryHandler', () {
    late ErrorRecoveryHandler handler;
    late List<BundleLoadException> errors;
    late List<String> warnings;

    setUp(() {
      handler = ErrorRecoveryHandler(
        coercionRules: const TypeCoercionRules.lenient(),
        allowPartialLoad: true,
      );
      errors = [];
      warnings = [];
    });

    group('handleMissingField', () {
      test('skip strategy adds warning and returns null', () {
        final result = handler.handleMissingField<String>(
          'field',
          errors,
          warnings,
          strategy: RecoveryStrategy.skip,
        );
        expect(result, isNull);
        expect(errors, isEmpty);
        expect(warnings, hasLength(1));
        expect(warnings.first, contains('skipped'));
      });

      test('useDefault strategy returns default and adds warning', () {
        final result = handler.handleMissingField<String>(
          'field',
          errors,
          warnings,
          defaultValue: 'default',
          strategy: RecoveryStrategy.useDefault,
        );
        expect(result, equals('default'));
        expect(warnings, hasLength(1));
        expect(warnings.first, contains('using default'));
      });

      test('useDefault without default adds error', () {
        final result = handler.handleMissingField<String>(
          'field',
          errors,
          warnings,
          strategy: RecoveryStrategy.useDefault,
        );
        expect(result, isNull);
        expect(errors, hasLength(1));
      });

      test('repair strategy returns default and adds warning', () {
        final result = handler.handleMissingField<String>(
          'field',
          errors,
          warnings,
          defaultValue: 'repaired',
          strategy: RecoveryStrategy.repair,
        );
        expect(result, equals('repaired'));
        expect(warnings, hasLength(1));
        expect(warnings.first, contains('repair'));
      });

      test('fail strategy adds error and returns null', () {
        final result = handler.handleMissingField<String>(
          'field',
          errors,
          warnings,
          strategy: RecoveryStrategy.fail,
        );
        expect(result, isNull);
        expect(errors, hasLength(1));
      });

      test('fail strategy throws when partial load not allowed', () {
        final strictHandler = ErrorRecoveryHandler(
          coercionRules: const TypeCoercionRules.strict(),
          allowPartialLoad: false,
        );
        expect(
          () => strictHandler.handleMissingField<String>(
            'field',
            errors,
            warnings,
            strategy: RecoveryStrategy.fail,
          ),
          throwsA(isA<BundleMissingFieldException>()),
        );
      });
    });

    group('handleInvalidValue', () {
      test('skip strategy adds warning and returns null', () {
        final result = handler.handleInvalidValue<int>(
          'field',
          'not a number',
          'int',
          errors,
          warnings,
          strategy: RecoveryStrategy.skip,
        );
        expect(result, isNull);
        expect(errors, isEmpty);
        expect(warnings, hasLength(1));
        expect(warnings.first, contains('skipped'));
      });

      test('useDefault strategy returns default and adds warning', () {
        final result = handler.handleInvalidValue<int>(
          'field',
          'invalid',
          'int',
          errors,
          warnings,
          defaultValue: 42,
          strategy: RecoveryStrategy.useDefault,
        );
        expect(result, equals(42));
        expect(warnings, hasLength(1));
      });

      test('repair strategy attempts coercion', () {
        final result = handler.handleInvalidValue<int>(
          'field',
          '42',
          'int',
          errors,
          warnings,
          strategy: RecoveryStrategy.repair,
        );
        expect(result, equals(42));
        expect(warnings, hasLength(1));
        expect(warnings.first, contains('coerced'));
      });

      test('repair strategy falls back to default when coercion fails', () {
        final result = handler.handleInvalidValue<int>(
          'field',
          'not a number',
          'int',
          errors,
          warnings,
          defaultValue: 0,
          strategy: RecoveryStrategy.repair,
        );
        expect(result, equals(0));
        expect(errors, hasLength(1));
      });

      test('fail strategy adds error and returns null', () {
        final result = handler.handleInvalidValue<int>(
          'field',
          'invalid',
          'int',
          errors,
          warnings,
          strategy: RecoveryStrategy.fail,
        );
        expect(result, isNull);
        expect(errors, hasLength(1));
      });

      test('fail strategy throws when partial load not allowed', () {
        final strictHandler = ErrorRecoveryHandler(
          coercionRules: const TypeCoercionRules.strict(),
          allowPartialLoad: false,
        );
        expect(
          () => strictHandler.handleInvalidValue<int>(
            'field',
            'invalid',
            'int',
            errors,
            warnings,
            strategy: RecoveryStrategy.fail,
          ),
          throwsA(isA<BundleInvalidValueException>()),
        );
      });
    });
  });
}
