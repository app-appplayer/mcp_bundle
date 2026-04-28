import 'dart:convert';

import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  // ==================== Canonicalizer ====================

  group('Canonicalizer', () {
    const canon = Canonicalizer();

    group('null values', () {
      test('canonicalizes null to "null"', () {
        expect(canon.canonicalize(null), equals('null'));
      });
    });

    group('boolean values', () {
      test('canonicalizes true', () {
        expect(canon.canonicalize(true), equals('true'));
      });

      test('canonicalizes false', () {
        expect(canon.canonicalize(false), equals('false'));
      });
    });

    group('number values', () {
      test('canonicalizes integer', () {
        expect(canon.canonicalize(42), equals('42'));
      });

      test('canonicalizes zero', () {
        expect(canon.canonicalize(0), equals('0'));
      });

      test('canonicalizes negative integer', () {
        expect(canon.canonicalize(-7), equals('-7'));
      });

      test('canonicalizes double with fractional part', () {
        expect(canon.canonicalize(3.14), equals('3.14'));
      });

      test('canonicalizes whole double to integer representation', () {
        // 5.0 should become "5" since it has no fractional part
        expect(canon.canonicalize(5.0), equals('5'));
      });

      test('canonicalizes NaN as null', () {
        expect(canon.canonicalize(double.nan), equals('null'));
      });

      test('canonicalizes positive infinity as null', () {
        expect(canon.canonicalize(double.infinity), equals('null'));
      });

      test('canonicalizes negative infinity as null', () {
        expect(canon.canonicalize(double.negativeInfinity), equals('null'));
      });

      test('canonicalizes large integer', () {
        expect(canon.canonicalize(9007199254740992), equals('9007199254740992'));
      });
    });

    group('string values', () {
      test('canonicalizes simple string', () {
        expect(canon.canonicalize('hello'), equals('"hello"'));
      });

      test('canonicalizes empty string', () {
        expect(canon.canonicalize(''), equals('""'));
      });

      test('escapes double quote', () {
        expect(canon.canonicalize('say "hi"'), equals(r'"say \"hi\""'));
      });

      test('escapes backslash', () {
        expect(canon.canonicalize(r'a\b'), equals(r'"a\\b"'));
      });

      test('escapes newline', () {
        expect(canon.canonicalize('line1\nline2'), equals(r'"line1\nline2"'));
      });

      test('escapes carriage return', () {
        expect(canon.canonicalize('a\rb'), equals(r'"a\rb"'));
      });

      test('escapes tab', () {
        expect(canon.canonicalize('a\tb'), equals(r'"a\tb"'));
      });

      test('escapes backspace', () {
        expect(canon.canonicalize('a\bb'), equals(r'"a\bb"'));
      });

      test('escapes form feed', () {
        expect(canon.canonicalize('a\fb'), equals(r'"a\fb"'));
      });

      test('escapes control character below 0x20 with unicode escape', () {
        // 0x01 = SOH control character
        final input = String.fromCharCode(0x01);
        expect(canon.canonicalize(input), equals(r'"\u0001"'));
      });

      test('preserves unicode characters', () {
        expect(canon.canonicalize('cafe\u0301'), equals('"cafe\u0301"'));
      });
    });

    group('array values', () {
      test('canonicalizes empty array', () {
        expect(canon.canonicalize(<dynamic>[]), equals('[]'));
      });

      test('canonicalizes single-element array', () {
        expect(canon.canonicalize([1]), equals('[1]'));
      });

      test('canonicalizes multi-element array', () {
        expect(canon.canonicalize([1, 2, 3]), equals('[1,2,3]'));
      });

      test('preserves array order', () {
        expect(canon.canonicalize(['b', 'a', 'c']), equals('["b","a","c"]'));
      });

      test('canonicalizes array with mixed types', () {
        expect(
          canon.canonicalize([1, 'two', true, null]),
          equals('[1,"two",true,null]'),
        );
      });

      test('canonicalizes nested arrays', () {
        expect(canon.canonicalize([[1, 2], [3]]), equals('[[1,2],[3]]'));
      });
    });

    group('object values', () {
      test('canonicalizes empty object', () {
        expect(canon.canonicalize(<String, dynamic>{}), equals('{}'));
      });

      test('sorts keys alphabetically', () {
        final input = <String, dynamic>{'z': 1, 'a': 2, 'm': 3};
        expect(canon.canonicalize(input), equals('{"a":2,"m":3,"z":1}'));
      });

      test('canonicalizes nested objects with sorted keys', () {
        final input = <String, dynamic>{
          'b': <String, dynamic>{'y': 2, 'x': 1},
          'a': 0,
        };
        expect(
          canon.canonicalize(input),
          equals('{"a":0,"b":{"x":1,"y":2}}'),
        );
      });

      test('handles non-String-keyed maps by converting keys', () {
        final input = <dynamic, dynamic>{1: 'one', 2: 'two'};
        // Keys converted to string and sorted
        expect(canon.canonicalize(input), equals('{"1":"one","2":"two"}'));
      });

      test('canonicalizes object with mixed value types', () {
        final input = <String, dynamic>{
          'str': 'hello',
          'num': 42,
          'bool': true,
          'nil': null,
        };
        expect(
          canon.canonicalize(input),
          equals('{"bool":true,"nil":null,"num":42,"str":"hello"}'),
        );
      });
    });

    group('complex nested structures', () {
      test('canonicalizes deeply nested structure consistently', () {
        final input = <String, dynamic>{
          'users': [
            <String, dynamic>{'name': 'Bob', 'age': 30},
            <String, dynamic>{'name': 'Alice', 'age': 25},
          ],
          'count': 2,
        };
        final result = canon.canonicalize(input);
        expect(
          result,
          equals(
            '{"count":2,"users":[{"age":30,"name":"Bob"},{"age":25,"name":"Alice"}]}',
          ),
        );
      });

      test('canonicalizes same data regardless of key insertion order', () {
        final a = <String, dynamic>{'x': 1, 'y': 2, 'z': 3};
        final b = <String, dynamic>{'z': 3, 'x': 1, 'y': 2};
        expect(canon.canonicalize(a), equals(canon.canonicalize(b)));
      });
    });

    group('fallback for unknown types', () {
      test('canonicalizes unknown type via toString', () {
        // An object that is not null/bool/num/String/List/Map
        // will be converted to a string via toString()
        final result = canon.canonicalize(Uri.parse('https://example.com'));
        expect(result, equals('"https://example.com"'));
      });
    });

    group('canonicalizeToBytes', () {
      test('returns UTF-8 encoded canonical form', () {
        final result = canon.canonicalizeToBytes('hello');
        expect(result, equals(utf8.encode('"hello"')));
      });

      test('returns UTF-8 bytes for object', () {
        final input = <String, dynamic>{'a': 1};
        final result = canon.canonicalizeToBytes(input);
        expect(result, equals(utf8.encode('{"a":1}')));
      });
    });
  });

  // ==================== JsonComparator ====================

  group('JsonComparator', () {
    const comparator = JsonComparator();

    group('null comparison', () {
      test('null equals null', () {
        expect(comparator.equals(null, null), isTrue);
      });

      test('null does not equal non-null', () {
        expect(comparator.equals(null, 1), isFalse);
      });

      test('non-null does not equal null', () {
        expect(comparator.equals(1, null), isFalse);
      });
    });

    group('primitive comparison', () {
      test('identical values are equal', () {
        const x = 'same';
        expect(comparator.equals(x, x), isTrue);
      });

      test('equal integers', () {
        expect(comparator.equals(42, 42), isTrue);
      });

      test('unequal integers', () {
        expect(comparator.equals(42, 43), isFalse);
      });

      test('equal strings', () {
        expect(comparator.equals('hello', 'hello'), isTrue);
      });

      test('unequal strings', () {
        expect(comparator.equals('hello', 'world'), isFalse);
      });

      test('equal booleans', () {
        expect(comparator.equals(true, true), isTrue);
      });

      test('unequal booleans', () {
        expect(comparator.equals(true, false), isFalse);
      });

      test('different types are not equal', () {
        expect(comparator.equals(1, '1'), isFalse);
      });
    });

    group('NaN handling', () {
      test('NaN equals NaN', () {
        expect(comparator.equals(double.nan, double.nan), isTrue);
      });

      test('NaN does not equal a number', () {
        expect(comparator.equals(double.nan, 0), isFalse);
      });
    });

    group('numeric comparison', () {
      test('int and double with same value are equal', () {
        expect(comparator.equals(1, 1.0), isTrue);
      });

      test('different numeric values are not equal', () {
        expect(comparator.equals(1, 2.0), isFalse);
      });
    });

    group('list comparison', () {
      test('empty lists are equal', () {
        expect(comparator.equals(<dynamic>[], <dynamic>[]), isTrue);
      });

      test('equal lists', () {
        expect(comparator.equals([1, 2, 3], [1, 2, 3]), isTrue);
      });

      test('lists with different lengths are not equal', () {
        expect(comparator.equals([1, 2], [1, 2, 3]), isFalse);
      });

      test('lists with different elements are not equal', () {
        expect(comparator.equals([1, 2, 3], [1, 2, 4]), isFalse);
      });

      test('nested lists are compared deeply', () {
        expect(
          comparator.equals([
            [1, 2],
            [3, 4]
          ], [
            [1, 2],
            [3, 4]
          ]),
          isTrue,
        );
      });

      test('nested lists with differences are detected', () {
        expect(
          comparator.equals([
            [1, 2],
            [3, 4]
          ], [
            [1, 2],
            [3, 5]
          ]),
          isFalse,
        );
      });
    });

    group('map comparison', () {
      test('empty maps are equal', () {
        expect(comparator.equals(<String, dynamic>{}, <String, dynamic>{}), isTrue);
      });

      test('equal maps', () {
        expect(
          comparator.equals(
            {'a': 1, 'b': 2},
            {'a': 1, 'b': 2},
          ),
          isTrue,
        );
      });

      test('maps with different keys are not equal', () {
        expect(
          comparator.equals(
            {'a': 1},
            {'b': 1},
          ),
          isFalse,
        );
      });

      test('maps with different values are not equal', () {
        expect(
          comparator.equals(
            {'a': 1},
            {'a': 2},
          ),
          isFalse,
        );
      });

      test('maps with different lengths are not equal', () {
        expect(
          comparator.equals(
            {'a': 1, 'b': 2},
            {'a': 1},
          ),
          isFalse,
        );
      });

      test('deeply nested maps are compared correctly', () {
        final a = {
          'x': {
            'y': {'z': 1}
          }
        };
        final b = {
          'x': {
            'y': {'z': 1}
          }
        };
        expect(comparator.equals(a, b), isTrue);
      });

      test('deeply nested maps with differences are detected', () {
        final a = {
          'x': {
            'y': {'z': 1}
          }
        };
        final b = {
          'x': {
            'y': {'z': 2}
          }
        };
        expect(comparator.equals(a, b), isFalse);
      });
    });

    group('mixed type structures', () {
      test('complex structure equality', () {
        final a = {
          'list': [1, 'two', true],
          'nested': {'a': null},
        };
        final b = {
          'list': [1, 'two', true],
          'nested': {'a': null},
        };
        expect(comparator.equals(a, b), isTrue);
      });

      test('complex structure inequality', () {
        final a = {
          'list': [1, 'two', true],
          'nested': {'a': null},
        };
        final b = {
          'list': [1, 'two', false],
          'nested': {'a': null},
        };
        expect(comparator.equals(a, b), isFalse);
      });
    });
  });

  // ==================== Convenience Functions ====================

  group('Convenience functions', () {
    group('canonicalizeJson', () {
      test('delegates to canonicalizer', () {
        final result = canonicalizeJson({'b': 2, 'a': 1});
        expect(result, equals('{"a":1,"b":2}'));
      });

      test('handles null', () {
        expect(canonicalizeJson(null), equals('null'));
      });

      test('handles primitive', () {
        expect(canonicalizeJson(42), equals('42'));
      });
    });

    group('jsonEquals', () {
      test('returns true for equal values', () {
        expect(jsonEquals({'a': 1}, {'a': 1}), isTrue);
      });

      test('returns false for unequal values', () {
        expect(jsonEquals({'a': 1}, {'a': 2}), isFalse);
      });

      test('compares NaN values as equal', () {
        expect(jsonEquals(double.nan, double.nan), isTrue);
      });
    });

    group('default instances', () {
      test('canonicalizer is a const Canonicalizer', () {
        expect(canonicalizer, isA<Canonicalizer>());
      });

      test('jsonComparator is a const JsonComparator', () {
        expect(jsonComparator, isA<JsonComparator>());
      });
    });
  });
}
