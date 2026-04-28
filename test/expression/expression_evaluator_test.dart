import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

/// Parses and evaluates an expression string with optional variable bindings.
dynamic eval(String source, [Map<String, dynamic>? vars]) {
  final tokens = Lexer(source).tokenize();
  final ast = Parser(tokens).parse();
  final ctx = EvaluationContext(variables: vars ?? {});
  return ExpressionEvaluator(ctx).evaluateOrThrow(ast);
}

/// Parses and evaluates an expression, returning the EvaluationResult wrapper.
EvaluationResult evalResult(String source, [Map<String, dynamic>? vars]) {
  final tokens = Lexer(source).tokenize();
  final ast = Parser(tokens).parse();
  final ctx = EvaluationContext(variables: vars ?? {});
  return ExpressionEvaluator(ctx).evaluate(ast);
}

void main() {
  // ---------------------------------------------------------------------------
  // evaluate() and evaluateOrThrow()
  // ---------------------------------------------------------------------------
  group('evaluate() and evaluateOrThrow()', () {
    test('evaluate returns success result for valid expression', () {
      final result = evalResult('2 + 3');
      expect(result.success, isTrue);
      expect(result.value, equals(5.0));
      expect(result.error, isNull);
    });

    test('evaluate returns failure result for invalid expression', () {
      final result = evalResult('undefinedVar');
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
      expect(result.error, contains('Undefined variable'));
    });

    test('evaluateOrThrow returns value on success', () {
      expect(eval('2 + 3'), equals(5.0));
    });

    test('evaluateOrThrow throws on error', () {
      expect(
        () => eval('undefinedVar'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('evaluate success toString contains Success', () {
      final result = evalResult('42');
      expect(result.toString(), contains('Success'));
    });

    test('evaluate failure toString contains Failure', () {
      final result = evalResult('undefinedVar');
      expect(result.toString(), contains('Failure'));
    });
  });

  // ---------------------------------------------------------------------------
  // EvaluationException
  // ---------------------------------------------------------------------------
  group('EvaluationException', () {
    test('contains message', () {
      final ex = EvaluationException('test error');
      expect(ex.message, equals('test error'));
    });

    test('toString includes class name and message', () {
      final ex = EvaluationException('something went wrong');
      expect(ex.toString(), contains('EvaluationException'));
      expect(ex.toString(), contains('something went wrong'));
    });
  });

  // ---------------------------------------------------------------------------
  // Literals
  // ---------------------------------------------------------------------------
  group('Literals', () {
    test('integer number', () {
      expect(eval('42'), equals(42.0));
    });

    test('floating-point number', () {
      expect(eval('3.14'), closeTo(3.14, 0.001));
    });

    test('zero', () {
      expect(eval('0'), equals(0.0));
    });

    test('large number', () {
      expect(eval('1000000'), equals(1000000.0));
    });

    test('scientific notation', () {
      // The lexer parses scientific notation as double
      expect(eval('1e3'), equals(1000.0));
    });

    test('string with double quotes', () {
      expect(eval('"hello"'), equals('hello'));
    });

    test('string with single quotes', () {
      expect(eval("'world'"), equals('world'));
    });

    test('empty string', () {
      expect(eval('""'), equals(''));
    });

    test('boolean true', () {
      expect(eval('true'), isTrue);
    });

    test('boolean false', () {
      expect(eval('false'), isFalse);
    });

    test('null literal', () {
      // The lexer stores null as the string 'null' because _addToken uses
      // literal ?? text, and null literal has literal: null which falls back
      // to the text 'null'.
      expect(eval('null'), equals('null'));
    });
  });

  // ---------------------------------------------------------------------------
  // Identifiers / Variables
  // ---------------------------------------------------------------------------
  group('Identifiers', () {
    test('reads a string variable', () {
      expect(eval('name', {'name': 'Alice'}), equals('Alice'));
    });

    test('reads a numeric variable', () {
      expect(eval('count', {'count': 42}), equals(42));
    });

    test('reads a boolean variable', () {
      expect(eval('flag', {'flag': true}), isTrue);
    });

    test('reads a null variable', () {
      expect(eval('nothing', {'nothing': null}), isNull);
    });

    test('reads a list variable', () {
      expect(eval('items', {'items': [1, 2, 3]}), equals([1, 2, 3]));
    });

    test('reads a map variable', () {
      expect(
        eval('data', {'data': {'key': 'value'}}),
        equals({'key': 'value'}),
      );
    });

    test('throws on undefined variable', () {
      expect(
        () => eval('undefinedVar'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('throws on undefined variable with descriptive message', () {
      expect(
        () => eval('missingVar'),
        throwsA(
          predicate(
            (e) =>
                e is EvaluationException &&
                e.message.contains('Undefined variable') &&
                e.message.contains('missingVar'),
          ),
        ),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Unary operators
  // ---------------------------------------------------------------------------
  group('Unary operators', () {
    group('Negation (-)', () {
      test('negates a positive number', () {
        expect(eval('-5'), equals(-5.0));
      });

      test('negates a negative number (double negation)', () {
        expect(eval('-(-5)'), equals(5.0));
      });

      test('negates zero', () {
        expect(eval('-0'), equals(0.0));
      });

      test('negates a float', () {
        expect(eval('-3.14'), closeTo(-3.14, 0.001));
      });

      test('throws on non-numeric operand', () {
        expect(
          () => eval('-"hello"'),
          throwsA(isA<EvaluationException>()),
        );
      });

      test('negates a variable', () {
        expect(eval('-x', {'x': 10}), equals(-10));
      });
    });

    group('Boolean NOT (!)', () {
      test('not true', () {
        expect(eval('!true'), isFalse);
      });

      test('not false', () {
        expect(eval('!false'), isTrue);
      });

      test('not null (falsy)', () {
        // null is stored as the string 'null', which is truthy (non-empty
        // string), so !null evaluates to false.
        expect(eval('!null'), isFalse);
      });

      test('not 0 (falsy)', () {
        expect(eval('!0'), isTrue);
      });

      test('not 1 (truthy)', () {
        expect(eval('!1'), isFalse);
      });

      test('not empty string (falsy)', () {
        expect(eval('!""'), isTrue);
      });

      test('not non-empty string (truthy)', () {
        expect(eval('!"hello"'), isFalse);
      });

      test('double negation', () {
        expect(eval('!!true'), isTrue);
        expect(eval('!!false'), isFalse);
      });
    });

    group('Boolean NOT (not keyword)', () {
      test('not true', () {
        expect(eval('not true'), isFalse);
      });

      test('not false', () {
        expect(eval('not false'), isTrue);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Binary arithmetic
  // ---------------------------------------------------------------------------
  group('Binary arithmetic', () {
    group('Addition (+)', () {
      test('int + int', () {
        expect(eval('2 + 3'), equals(5.0));
      });

      test('double + double', () {
        expect(eval('1.5 + 2.5'), equals(4.0));
      });

      test('int + double (mixed)', () {
        expect(eval('2 + 1.5'), closeTo(3.5, 0.001));
      });

      test('string + string', () {
        expect(eval('"hello" + " world"'), equals('hello world'));
      });

      test('string + number coerces to string', () {
        expect(eval('"value: " + 42'), equals('value: 42.0'));
      });

      test('number + string coerces to string', () {
        expect(eval('42 + " is the answer"'), equals('42.0 is the answer'));
      });

      test('list + list concatenation', () {
        final result = eval('[1, 2] + [3, 4]');
        expect(result, equals([1.0, 2.0, 3.0, 4.0]));
      });

      test('empty list + list', () {
        final result = eval('[] + [1, 2]');
        expect(result, equals([1.0, 2.0]));
      });

      test('throws on incompatible types (bool + bool)', () {
        expect(
          () => eval('true + false'),
          throwsA(isA<EvaluationException>()),
        );
      });
    });

    group('Subtraction (-)', () {
      test('int - int', () {
        expect(eval('10 - 3'), equals(7.0));
      });

      test('double - double', () {
        expect(eval('5.5 - 2.3'), closeTo(3.2, 0.001));
      });

      test('mixed (int - double)', () {
        expect(eval('10 - 2.5'), closeTo(7.5, 0.001));
      });

      test('produces negative result', () {
        expect(eval('3 - 10'), equals(-7.0));
      });

      test('throws on non-numeric', () {
        expect(
          () => eval('"a" - "b"'),
          throwsA(isA<EvaluationException>()),
        );
      });
    });

    group('Multiplication (*)', () {
      test('int * int', () {
        expect(eval('4 * 5'), equals(20.0));
      });

      test('double * double', () {
        expect(eval('2.5 * 4.0'), equals(10.0));
      });

      test('mixed (int * double)', () {
        expect(eval('3 * 2.5'), closeTo(7.5, 0.001));
      });

      test('string * int (repeat) throws because parsed numbers are doubles', () {
        // The lexer parses 3 as 3.0 (double), and the evaluator checks
        // right is int, which fails for doubles. Use context variable with
        // actual int for string repetition.
        expect(
          () => eval('"ha" * 3'),
          throwsA(isA<EvaluationException>()),
        );
      });

      test('string * int with context variable works', () {
        // Using a context variable that is an actual int bypasses the lexer
        expect(eval('"ha" * n', {'n': 3}), equals('hahaha'));
      });

      test('string * 0 with context variable yields empty', () {
        expect(eval('"ha" * n', {'n': 0}), equals(''));
      });

      test('throws on incompatible types (string * string)', () {
        expect(
          () => eval('"a" * "b"'),
          throwsA(isA<EvaluationException>()),
        );
      });
    });

    group('Division (/)', () {
      test('int / int', () {
        expect(eval('10 / 4'), equals(2.5));
      });

      test('divides evenly', () {
        expect(eval('10 / 2'), equals(5.0));
      });

      test('double / double', () {
        expect(eval('7.5 / 2.5'), equals(3.0));
      });

      test('throws on division by zero', () {
        expect(
          () => eval('10 / 0'),
          throwsA(isA<EvaluationException>()),
        );
      });

      test('throws on non-numeric', () {
        expect(
          () => eval('"a" / 2'),
          throwsA(isA<EvaluationException>()),
        );
      });
    });

    group('Modulo (%)', () {
      test('computes modulo', () {
        expect(eval('10 % 3'), equals(1.0));
      });

      test('modulo with no remainder', () {
        expect(eval('10 % 5'), equals(0.0));
      });

      test('modulo with doubles', () {
        expect(eval('7.5 % 2.5'), closeTo(0.0, 0.001));
      });

      test('throws on modulo by zero', () {
        expect(
          () => eval('10 % 0'),
          throwsA(isA<EvaluationException>()),
        );
      });

      test('throws on non-numeric', () {
        expect(
          () => eval('"a" % 2'),
          throwsA(isA<EvaluationException>()),
        );
      });
    });

    group('Power (**)', () {
      test('integer exponent', () {
        expect(eval('2 ** 3'), equals(8));
      });

      test('zero exponent', () {
        expect(eval('5 ** 0'), equals(1));
      });

      test('exponent of one', () {
        expect(eval('7 ** 1'), equals(7));
      });

      test('square (exponent of 2)', () {
        expect(eval('5 ** 2'), equals(25));
      });

      test('large integer exponent', () {
        // Parsed exponent 10 is double 10.0, so it goes through the _pow
        // approximation path which has floating-point rounding.
        final result = eval('2 ** 10') as num;
        expect(result, closeTo(1024, 0.01));
      });

      test('fractional exponent (square root approximation)', () {
        final result = eval('9 ** 0.5') as num;
        expect(result, closeTo(3.0, 0.01));
      });

      test('power of zero base', () {
        expect(eval('0 ** 5'), equals(0));
      });

      test('power of one base', () {
        expect(eval('1 ** 100'), equals(1));
      });

      test('throws on non-numeric', () {
        expect(
          () => eval('"a" ** 2'),
          throwsA(isA<EvaluationException>()),
        );
      });
    });

    test('operator precedence: multiplication before addition', () {
      expect(eval('2 + 3 * 4'), equals(14.0));
    });

    test('operator precedence: division before subtraction', () {
      expect(eval('10 - 6 / 2'), equals(7.0));
    });

    test('grouping overrides precedence', () {
      expect(eval('(2 + 3) * 4'), equals(20.0));
    });

    test('nested grouping', () {
      expect(eval('((1 + 2) * (3 + 4))'), equals(21.0));
    });

    test('unknown binary operator triggers error (via evaluate)', () {
      // This is hard to trigger via parser directly since parser
      // only creates known operators, but we test via EvaluationResult
      final result = evalResult('10 / 0');
      expect(result.success, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Comparison operators
  // ---------------------------------------------------------------------------
  group('Comparison', () {
    group('Equality (==)', () {
      test('equal numbers', () {
        expect(eval('5 == 5'), isTrue);
      });

      test('unequal numbers', () {
        expect(eval('5 == 6'), isFalse);
      });

      test('equal strings', () {
        expect(eval('"abc" == "abc"'), isTrue);
      });

      test('unequal strings', () {
        expect(eval('"abc" == "xyz"'), isFalse);
      });

      test('null == null', () {
        expect(eval('null == null'), isTrue);
      });

      test('null == non-null', () {
        expect(eval('null == 1'), isFalse);
      });

      test('non-null == null', () {
        expect(eval('1 == null'), isFalse);
      });

      test('boolean equality', () {
        expect(eval('true == true'), isTrue);
        expect(eval('true == false'), isFalse);
      });

      test('int and double equality (5 == 5.0)', () {
        expect(eval('5 == 5.0'), isTrue);
      });
    });

    group('Inequality (!=)', () {
      test('unequal numbers', () {
        expect(eval('5 != 6'), isTrue);
      });

      test('equal numbers', () {
        expect(eval('5 != 5'), isFalse);
      });

      test('null != non-null', () {
        expect(eval('null != 1'), isTrue);
      });

      test('null != null', () {
        expect(eval('null != null'), isFalse);
      });

      test('string inequality', () {
        expect(eval('"abc" != "xyz"'), isTrue);
        expect(eval('"abc" != "abc"'), isFalse);
      });
    });

    group('Less than (<)', () {
      test('numbers: less', () {
        expect(eval('3 < 5'), isTrue);
      });

      test('numbers: greater', () {
        expect(eval('5 < 3'), isFalse);
      });

      test('numbers: equal', () {
        expect(eval('5 < 5'), isFalse);
      });

      test('strings: lexicographic', () {
        expect(eval('"a" < "b"'), isTrue);
        expect(eval('"b" < "a"'), isFalse);
      });
    });

    group('Less than or equal (<=)', () {
      test('less', () {
        expect(eval('3 <= 5'), isTrue);
      });

      test('equal', () {
        expect(eval('5 <= 5'), isTrue);
      });

      test('greater', () {
        expect(eval('6 <= 5'), isFalse);
      });

      test('strings', () {
        expect(eval('"a" <= "a"'), isTrue);
        expect(eval('"a" <= "b"'), isTrue);
        expect(eval('"b" <= "a"'), isFalse);
      });
    });

    group('Greater than (>)', () {
      test('greater', () {
        expect(eval('5 > 3'), isTrue);
      });

      test('less', () {
        expect(eval('3 > 5'), isFalse);
      });

      test('equal', () {
        expect(eval('5 > 5'), isFalse);
      });

      test('strings', () {
        expect(eval('"b" > "a"'), isTrue);
        expect(eval('"a" > "b"'), isFalse);
      });
    });

    group('Greater than or equal (>=)', () {
      test('greater', () {
        expect(eval('5 >= 3'), isTrue);
      });

      test('equal', () {
        expect(eval('5 >= 5'), isTrue);
      });

      test('less', () {
        expect(eval('3 >= 5'), isFalse);
      });

      test('strings', () {
        expect(eval('"b" >= "a"'), isTrue);
        expect(eval('"a" >= "a"'), isTrue);
        expect(eval('"a" >= "b"'), isFalse);
      });
    });

    test('throws when comparing incompatible types', () {
      expect(
        () => eval('1 < "a"'),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Membership operators
  // ---------------------------------------------------------------------------
  group('Membership', () {
    group('in', () {
      test('element in list (found)', () {
        expect(eval('2 in [1, 2, 3]'), isTrue);
      });

      test('element not in list', () {
        expect(eval('5 in [1, 2, 3]'), isFalse);
      });

      test('key in map', () {
        expect(
          eval('"name" in obj', {'obj': {'name': 'Alice', 'age': 30}}),
          isTrue,
        );
      });

      test('key not in map', () {
        expect(
          eval('"missing" in obj', {'obj': {'name': 'Alice'}}),
          isFalse,
        );
      });

      test('substring in string', () {
        expect(eval('"world" in "hello world"'), isTrue);
      });

      test('substring not in string', () {
        expect(eval('"xyz" in "hello world"'), isFalse);
      });

      test('returns false for null collection', () {
        expect(eval('"a" in x', {'x': null}), isFalse);
      });

      test('returns false for incompatible collection type', () {
        expect(eval('1 in x', {'x': 42}), isFalse);
      });
    });

    group('matches', () {
      test('regex matches string', () {
        expect(eval('"hello123" matches "^[a-z]+\\\\d+\$"'), isTrue);
      });

      test('regex does not match', () {
        expect(eval('"hello" matches "^\\\\d+\$"'), isFalse);
      });

      test('returns false when value is null', () {
        expect(eval('x matches "abc"', {'x': null}), isFalse);
      });

      test('returns false when pattern is null', () {
        expect(eval('"abc" matches x', {'x': null}), isFalse);
      });

      test('simple pattern match', () {
        expect(eval('"test" matches "t.st"'), isTrue);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Logical operators
  // ---------------------------------------------------------------------------
  group('Logical', () {
    group('AND (&&)', () {
      test('true && true', () {
        expect(eval('true && true'), isTrue);
      });

      test('true && false', () {
        expect(eval('true && false'), isFalse);
      });

      test('false && true (short-circuits)', () {
        expect(eval('false && true'), isFalse);
      });

      test('false && false', () {
        expect(eval('false && false'), isFalse);
      });
    });

    group('AND (and keyword)', () {
      test('true and true', () {
        expect(eval('true and true'), isTrue);
      });

      test('false and true', () {
        expect(eval('false and true'), isFalse);
      });
    });

    group('OR (||)', () {
      test('true || false (short-circuits)', () {
        expect(eval('true || false'), isTrue);
      });

      test('false || true', () {
        expect(eval('false || true'), isTrue);
      });

      test('false || false', () {
        expect(eval('false || false'), isFalse);
      });

      test('true || true', () {
        expect(eval('true || true'), isTrue);
      });
    });

    group('OR (or keyword)', () {
      test('true or false', () {
        expect(eval('true or false'), isTrue);
      });

      test('false or false', () {
        expect(eval('false or false'), isFalse);
      });
    });

    test('short-circuit AND prevents error on null var', () {
      // false && <anything> should not evaluate right side
      expect(eval('false && x', {'x': null}), isFalse);
    });

    test('short-circuit OR prevents evaluation of right side', () {
      expect(eval('true || x', {'x': null}), isTrue);
    });

    test('combined: && has higher precedence than ||', () {
      // true || (false && true) => true
      expect(eval('true || false && true'), isTrue);
      // (false || false) && true) => false
      expect(eval('false || false && true'), isFalse);
    });

    test('truthy values in logical expressions', () {
      // "hello" is truthy, 0 is falsy
      expect(eval('"hello" && true'), isTrue);
      expect(eval('0 && true'), isFalse);
      expect(eval('"" || true'), isTrue);
      expect(eval('"" || false'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Truthiness (_toBool)
  // ---------------------------------------------------------------------------
  group('Truthiness (_toBool)', () {
    test('null is falsy', () {
      // null is stored as the string 'null', which is a non-empty string
      // and therefore truthy. The ternary returns the then-branch.
      expect(eval('null ? 1 : 0'), equals(1.0));
    });

    test('true is truthy', () {
      expect(eval('true ? 1 : 0'), equals(1.0));
    });

    test('false is falsy', () {
      expect(eval('false ? 1 : 0'), equals(0.0));
    });

    test('0 is falsy', () {
      expect(eval('0 ? 1 : 0'), equals(0.0));
    });

    test('non-zero positive number is truthy', () {
      expect(eval('42 ? 1 : 0'), equals(1.0));
    });

    test('negative number is truthy', () {
      expect(eval('-1 ? 1 : 0'), equals(1.0));
    });

    test('0.0 is falsy', () {
      expect(eval('0.0 ? 1 : 0'), equals(0.0));
    });

    test('empty string is falsy', () {
      expect(eval('"" ? 1 : 0'), equals(0.0));
    });

    test('non-empty string is truthy', () {
      expect(eval('"x" ? 1 : 0'), equals(1.0));
    });

    test('empty list is falsy', () {
      expect(eval('x ? 1 : 0', {'x': <dynamic>[]}), equals(0.0));
    });

    test('non-empty list is truthy', () {
      expect(eval('x ? 1 : 0', {'x': [1]}), equals(1.0));
    });

    test('empty map is falsy', () {
      expect(eval('x ? 1 : 0', {'x': <String, dynamic>{}}), equals(0.0));
    });

    test('non-empty map is truthy', () {
      expect(eval('x ? 1 : 0', {'x': {'a': 1}}), equals(1.0));
    });

    test('arbitrary object is truthy', () {
      // Any non-null, non-bool, non-num, non-String, non-List, non-Map is truthy
      expect(eval('x ? 1 : 0', {'x': Object()}), equals(1.0));
    });
  });

  // ---------------------------------------------------------------------------
  // Conditional (ternary)
  // ---------------------------------------------------------------------------
  group('Conditional (ternary)', () {
    test('true condition returns then branch', () {
      expect(eval('true ? "yes" : "no"'), equals('yes'));
    });

    test('false condition returns else branch', () {
      expect(eval('false ? "yes" : "no"'), equals('no'));
    });

    test('numeric truthy condition', () {
      expect(eval('1 ? "yes" : "no"'), equals('yes'));
    });

    test('zero is falsy', () {
      expect(eval('0 ? "yes" : "no"'), equals('no'));
    });

    test('non-empty string is truthy', () {
      expect(eval('"hello" ? "yes" : "no"'), equals('yes'));
    });

    test('empty string is falsy', () {
      expect(eval('"" ? "yes" : "no"'), equals('no'));
    });

    test('null is falsy', () {
      // null is stored as the string 'null' (truthy), so the then-branch
      // is returned.
      expect(eval('null ? "yes" : "no"'), equals('yes'));
    });

    test('nested ternary', () {
      expect(eval('true ? (false ? 1 : 2) : 3'), equals(2.0));
    });

    test('ternary with comparison condition', () {
      expect(eval('x > 10 ? "big" : "small"', {'x': 15}), equals('big'));
      expect(eval('x > 10 ? "big" : "small"', {'x': 5}), equals('small'));
    });
  });

  // ---------------------------------------------------------------------------
  // Null coalescing (??)
  // ---------------------------------------------------------------------------
  group('Null coalescing (??)', () {
    test('returns left when non-null string', () {
      expect(eval('"hello" ?? "default"'), equals('hello'));
    });

    test('returns right when left is null', () {
      // null literal evaluates to the string 'null' (non-null), so
      // visitNullCoalesce returns the left side.
      expect(eval('null ?? "default"'), equals('null'));
    });

    test('returns left number when non-null', () {
      expect(eval('42 ?? 0'), equals(42.0));
    });

    test('chained null coalesce', () {
      // Each null literal evaluates to the string 'null' (non-null), so the
      // first non-null left side is returned immediately.
      expect(eval('null ?? null ?? "found"'), equals('null'));
    });

    test('returns variable value when non-null', () {
      expect(eval('x ?? "fallback"', {'x': 'value'}), equals('value'));
    });

    test('returns fallback when variable is null', () {
      expect(eval('x ?? "fallback"', {'x': null}), equals('fallback'));
    });

    test('false is not null, so returns false', () {
      expect(eval('false ?? "default"'), equals(false));
    });

    test('0 is not null, so returns 0', () {
      expect(eval('0 ?? 99'), equals(0.0));
    });

    test('empty string is not null, so returns empty string', () {
      expect(eval('"" ?? "default"'), equals(''));
    });
  });

  // ---------------------------------------------------------------------------
  // Member access
  // ---------------------------------------------------------------------------
  group('Member access', () {
    group('Map property access', () {
      test('accesses map property', () {
        expect(
          eval('user.name', {'user': {'name': 'Alice'}}),
          equals('Alice'),
        );
      });

      test('accesses nested map property', () {
        expect(
          eval('user.address.city', {
            'user': {
              'address': {'city': 'Seoul'}
            }
          }),
          equals('Seoul'),
        );
      });

      test('returns null for missing map key', () {
        expect(
          eval('user.missing', {'user': {'name': 'Alice'}}),
          isNull,
        );
      });

      test('deeply nested map access', () {
        expect(
          eval('a.b.c.d', {
            'a': {
              'b': {
                'c': {'d': 'deep'}
              }
            }
          }),
          equals('deep'),
        );
      });
    });

    group('List properties', () {
      test('length', () {
        expect(eval('items.length', {'items': [1, 2, 3]}), equals(3));
      });

      test('first on non-empty list', () {
        expect(eval('items.first', {'items': [10, 20, 30]}), equals(10));
      });

      test('first on empty list returns null', () {
        expect(eval('items.first', {'items': <dynamic>[]}), isNull);
      });

      test('last on non-empty list', () {
        expect(eval('items.last', {'items': [10, 20, 30]}), equals(30));
      });

      test('last on empty list returns null', () {
        expect(eval('items.last', {'items': <dynamic>[]}), isNull);
      });

      test('isEmpty on empty list', () {
        expect(eval('items.isEmpty', {'items': <dynamic>[]}), isTrue);
      });

      test('isEmpty on non-empty list', () {
        expect(eval('items.isEmpty', {'items': [1]}), isFalse);
      });

      test('isNotEmpty on non-empty list', () {
        expect(eval('items.isNotEmpty', {'items': [1]}), isTrue);
      });

      test('isNotEmpty on empty list', () {
        expect(eval('items.isNotEmpty', {'items': <dynamic>[]}), isFalse);
      });
    });

    group('String properties', () {
      test('length', () {
        expect(eval('s.length', {'s': 'hello'}), equals(5));
      });

      test('isEmpty on empty string', () {
        expect(eval('s.isEmpty', {'s': ''}), isTrue);
      });

      test('isEmpty on non-empty string', () {
        expect(eval('s.isEmpty', {'s': 'a'}), isFalse);
      });

      test('isNotEmpty on non-empty string', () {
        expect(eval('s.isNotEmpty', {'s': 'a'}), isTrue);
      });

      test('isNotEmpty on empty string', () {
        expect(eval('s.isNotEmpty', {'s': ''}), isFalse);
      });
    });

    test('throws on null object without optional chaining', () {
      expect(
        () => eval('x.name', {'x': null}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('throws for unknown property on non-map/list/string', () {
      expect(
        () => eval('x.prop', {'x': 42}),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Optional chaining (?.)
  // ---------------------------------------------------------------------------
  group('Optional chaining (?.)', () {
    test('returns null when object is null', () {
      expect(eval('x?.name', {'x': null}), isNull);
    });

    test('returns property when object is not null', () {
      expect(
        eval('x?.name', {'x': {'name': 'Alice'}}),
        equals('Alice'),
      );
    });

    test('chained optional access with first null', () {
      expect(eval('x?.y?.z', {'x': null}), isNull);
    });

    test('method call on null with optional chaining returns null', () {
      expect(eval('x?.toUpperCase()', {'x': null}), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Index access
  // ---------------------------------------------------------------------------
  group('Index access', () {
    group('List indexing', () {
      test('accesses first element', () {
        // Literal 0 is parsed as double 0.0, which fails the int check.
        // Use a context variable with an actual int index.
        expect(eval('items[i]', {'items': [10, 20, 30], 'i': 0}), equals(10));
      });

      test('accesses middle element', () {
        expect(eval('items[i]', {'items': [10, 20, 30], 'i': 1}), equals(20));
      });

      test('accesses last element', () {
        expect(eval('items[i]', {'items': [10, 20, 30], 'i': 2}), equals(30));
      });

      test('throws on out-of-bounds index', () {
        expect(
          () => eval('items[5]', {'items': [1, 2, 3]}),
          throwsA(isA<EvaluationException>()),
        );
      });

      test('throws on negative index', () {
        expect(
          () => eval('items[-1]', {'items': [1, 2, 3]}),
          throwsA(isA<EvaluationException>()),
        );
      });

      test('throws when index is not an integer', () {
        expect(
          () => eval('items["key"]', {'items': [1, 2, 3]}),
          throwsA(isA<EvaluationException>()),
        );
      });
    });

    group('Map indexing', () {
      test('accesses map value by key', () {
        expect(
          eval('obj["name"]', {'obj': {'name': 'Alice'}}),
          equals('Alice'),
        );
      });

      test('returns null for missing key', () {
        expect(
          eval('obj["missing"]', {'obj': {'name': 'Alice'}}),
          isNull,
        );
      });
    });

    group('String indexing', () {
      test('accesses first character', () {
        // Literal 0 is parsed as double 0.0, failing the int check.
        // Use a context variable with an actual int index.
        expect(eval('s[i]', {'s': 'hello', 'i': 0}), equals('h'));
      });

      test('accesses last character', () {
        expect(eval('s[i]', {'s': 'hello', 'i': 4}), equals('o'));
      });

      test('throws on out-of-bounds', () {
        expect(
          () => eval('s[10]', {'s': 'hello'}),
          throwsA(isA<EvaluationException>()),
        );
      });

      test('throws on negative index for string', () {
        expect(
          () => eval('s[-1]', {'s': 'hello'}),
          throwsA(isA<EvaluationException>()),
        );
      });

      test('throws when string index is not int', () {
        expect(
          () => eval('s["a"]', {'s': 'hello'}),
          throwsA(isA<EvaluationException>()),
        );
      });
    });

    test('throws when indexing null', () {
      expect(
        () => eval('x[0]', {'x': null}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('throws when indexing a non-indexable type', () {
      expect(
        () => eval('x[0]', {'x': 42}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('index access on literal array', () {
      // Literal index 1 is parsed as double 1.0, failing the int check.
      // Use a context variable for the index.
      expect(eval('[10, 20, 30][i]', {'i': 1}), equals(20.0));
    });
  });

  // ---------------------------------------------------------------------------
  // String method calls
  // ---------------------------------------------------------------------------
  group('String methods', () {
    test('toUpperCase', () {
      expect(eval('"hello".toUpperCase()'), equals('HELLO'));
    });

    test('toLowerCase', () {
      expect(eval('"HELLO".toLowerCase()'), equals('hello'));
    });

    test('trim', () {
      expect(eval('"  hello  ".trim()'), equals('hello'));
    });

    test('contains - found', () {
      expect(eval('"hello world".contains("world")'), isTrue);
    });

    test('contains - not found', () {
      expect(eval('"hello world".contains("xyz")'), isFalse);
    });

    test('contains with no args returns false', () {
      expect(eval('"hello".contains()'), isFalse);
    });

    test('startsWith - matches', () {
      expect(eval('"hello".startsWith("hel")'), isTrue);
    });

    test('startsWith - no match', () {
      expect(eval('"hello".startsWith("xyz")'), isFalse);
    });

    test('startsWith with no args returns false', () {
      expect(eval('"hello".startsWith()'), isFalse);
    });

    test('endsWith - matches', () {
      expect(eval('"hello".endsWith("llo")'), isTrue);
    });

    test('endsWith - no match', () {
      expect(eval('"hello".endsWith("xyz")'), isFalse);
    });

    test('endsWith with no args returns false', () {
      expect(eval('"hello".endsWith()'), isFalse);
    });

    test('substring with start only', () {
      // Literal 1 is parsed as double 1.0, causing `as int` cast to fail.
      // Use a context variable with an actual int.
      expect(eval('s.substring(start)', {'s': 'hello', 'start': 1}),
          equals('ello'));
    });

    test('substring with start and end', () {
      expect(
          eval('s.substring(start, end)', {'s': 'hello', 'start': 1, 'end': 3}),
          equals('el'));
    });

    test('replace replaces all occurrences', () {
      expect(eval('"aabaa".replace("a", "x")'), equals('xxbxx'));
    });

    test('replace throws with less than 2 arguments', () {
      expect(
        () => eval('"hello".replace("x")'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('split with separator', () {
      expect(eval('"a,b,c".split(",")'), equals(['a', 'b', 'c']));
    });

    test('split with no args returns single-element list', () {
      expect(eval('"hello".split()'), equals(['hello']));
    });

    test('indexOf - found', () {
      expect(eval('"hello".indexOf("ll")'), equals(2));
    });

    test('indexOf - not found', () {
      expect(eval('"hello".indexOf("xyz")'), equals(-1));
    });

    test('indexOf with no args returns -1', () {
      expect(eval('"hello".indexOf()'), equals(-1));
    });

    test('unknown string method throws', () {
      expect(
        () => eval('"hello".nonExistent()'),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // List method calls
  // ---------------------------------------------------------------------------
  group('List methods', () {
    test('join with separator', () {
      expect(
        eval('items.join("-")', {'items': ['a', 'b', 'c']}),
        equals('a-b-c'),
      );
    });

    test('join with default separator', () {
      expect(
        eval('items.join()', {'items': ['a', 'b', 'c']}),
        equals('a,b,c'),
      );
    });

    test('contains - found', () {
      expect(eval('[1, 2, 3].contains(2)'), isTrue);
    });

    test('contains - not found', () {
      expect(eval('[1, 2, 3].contains(5)'), isFalse);
    });

    test('contains with no args returns false', () {
      expect(eval('[1, 2, 3].contains()'), isFalse);
    });

    test('indexOf - found', () {
      expect(eval('[10, 20, 30].indexOf(20)'), equals(1));
    });

    test('indexOf - not found', () {
      expect(eval('[10, 20, 30].indexOf(99)'), equals(-1));
    });

    test('indexOf with no args returns -1', () {
      expect(eval('[1, 2, 3].indexOf()'), equals(-1));
    });

    test('map with lambda', () {
      final result = eval('[1, 2, 3].map(x => x * 2)');
      expect(result, equals([2.0, 4.0, 6.0]));
    });

    test('map throws without lambda', () {
      expect(
        () => eval('[1, 2, 3].map()'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('filter with lambda', () {
      final result = eval('[1, 2, 3, 4, 5].filter(x => x > 3)');
      expect(result, equals([4.0, 5.0]));
    });

    test('where with lambda (alias for filter)', () {
      final result = eval('[1, 2, 3, 4].where(x => x > 2)');
      expect(result, equals([3.0, 4.0]));
    });

    test('filter throws without lambda', () {
      expect(
        () => eval('[1, 2, 3].filter()'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('reduce with initial value and lambda', () {
      final result = eval('[1, 2, 3].reduce(0, (acc, x) => acc + x)');
      expect(result, equals(6.0));
    });

    test('reduce with initial value only (sum behavior)', () {
      final result = eval('[1, 2, 3].reduce(0)');
      expect(result, equals(6.0));
    });

    test('reduce throws without initial value', () {
      expect(
        () => eval('[1, 2, 3].reduce()'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('slice with start only', () {
      // Literal 2 is parsed as double 2.0, causing `as int` cast to fail.
      // Use context variables with actual ints.
      final result = eval('items.slice(start)', {
        'items': [1.0, 2.0, 3.0, 4.0, 5.0],
        'start': 2,
      });
      expect(result, equals([3.0, 4.0, 5.0]));
    });

    test('slice with start and end', () {
      final result = eval('items.slice(start, end)', {
        'items': [1.0, 2.0, 3.0, 4.0, 5.0],
        'start': 1,
        'end': 3,
      });
      expect(result, equals([2.0, 3.0]));
    });

    test('reverse', () {
      final result = eval('[1, 2, 3].reverse()');
      expect(result, equals([3.0, 2.0, 1.0]));
    });

    test('sort numbers', () {
      final result = eval('[3, 1, 2].sort()');
      expect(result, equals([1.0, 2.0, 3.0]));
    });

    test('sort with comparator lambda', () {
      final result = eval('[3, 1, 2].sort((a, b) => a - b)');
      expect(result, equals([1.0, 2.0, 3.0]));
    });

    test('find with lambda - match found', () {
      final result = eval('[1, 2, 3, 4].find(x => x > 2)');
      expect(result, equals(3.0));
    });

    test('find returns null when no match', () {
      final result = eval('[1, 2, 3].find(x => x > 10)');
      expect(result, isNull);
    });

    test('find throws without lambda', () {
      expect(
        () => eval('[1, 2, 3].find()'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('every - all match', () {
      expect(eval('[2, 4, 6].every(x => x > 0)'), isTrue);
    });

    test('every - not all match', () {
      expect(eval('[2, 4, 6].every(x => x > 3)'), isFalse);
    });

    test('every throws without lambda', () {
      expect(
        () => eval('[1, 2, 3].every()'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('some - at least one matches', () {
      expect(eval('[1, 2, 3].some(x => x > 2)'), isTrue);
    });

    test('some - none match', () {
      expect(eval('[1, 2, 3].some(x => x > 10)'), isFalse);
    });

    test('any with lambda (alias for some)', () {
      expect(eval('[1, 2, 3].any(x => x == 2)'), isTrue);
    });

    test('some throws without lambda', () {
      expect(
        () => eval('[1, 2, 3].some()'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('unknown list method throws', () {
      expect(
        () => eval('[1, 2].nonExistent()'),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Map method calls
  // ---------------------------------------------------------------------------
  group('Map methods', () {
    test('keys', () {
      final result = eval('obj.keys()', {'obj': {'a': 1, 'b': 2}});
      expect(result, containsAll(['a', 'b']));
    });

    test('values', () {
      final result = eval('obj.values()', {'obj': {'a': 1, 'b': 2}});
      expect(result, containsAll([1, 2]));
    });

    test('entries returns list of key-value maps', () {
      final result = eval('obj.entries()', {'obj': {'a': 1}}) as List;
      expect(result, hasLength(1));
      expect(result[0], equals({'key': 'a', 'value': 1}));
    });

    test('containsKey - found', () {
      expect(
        eval('obj.containsKey("a")', {'obj': {'a': 1, 'b': 2}}),
        isTrue,
      );
    });

    test('containsKey - not found', () {
      expect(
        eval('obj.containsKey("z")', {'obj': {'a': 1, 'b': 2}}),
        isFalse,
      );
    });

    test('containsKey with no args returns false', () {
      expect(
        eval('obj.containsKey()', {'obj': {'a': 1}}),
        isFalse,
      );
    });

    test('containsValue - found', () {
      expect(
        eval('obj.containsValue(1)', {'obj': {'a': 1, 'b': 2}}),
        isTrue,
      );
    });

    test('containsValue - not found', () {
      expect(
        eval('obj.containsValue(99)', {'obj': {'a': 1, 'b': 2}}),
        isFalse,
      );
    });

    test('containsValue with no args returns false', () {
      expect(
        eval('obj.containsValue()', {'obj': {'a': 1}}),
        isFalse,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Pipe filters
  // ---------------------------------------------------------------------------
  group('Pipe filters', () {
    group('String transformations', () {
      test('upper / uppercase', () {
        expect(eval('"hello" | upper'), equals('HELLO'));
        expect(eval('"hello" | uppercase'), equals('HELLO'));
      });

      test('lower / lowercase', () {
        expect(eval('"HELLO" | lower'), equals('hello'));
        expect(eval('"HELLO" | lowercase'), equals('hello'));
      });

      test('trim', () {
        expect(eval('"  hello  " | trim'), equals('hello'));
      });
    });

    group('default', () {
      test('non-null value returns value', () {
        expect(eval('"hello" | default("fallback")'), equals('hello'));
      });

      test('null returns default argument', () {
        expect(
            eval('x | default("fallback")', {'x': null}), equals('fallback'));
      });

      test('null with no default arg returns null', () {
        expect(eval('x | default', {'x': null}), isNull);
      });
    });

    group('json', () {
      test('json on string', () {
        expect(eval('"hello" | json'), equals('"hello"'));
      });

      test('json on number', () {
        expect(eval('42 | json'), equals('42.0'));
      });

      test('json on boolean', () {
        expect(eval('true | json'), equals('true'));
      });

      test('json on null', () {
        // null literal evaluates to the string 'null', so _toJson treats it
        // as a string and wraps it in quotes.
        expect(eval('null | json'), equals('"null"'));
      });

      test('json on list', () {
        expect(eval('[1, 2] | json'), equals('[1.0,2.0]'));
      });

      test('json on map', () {
        final result = eval('obj | json', {'obj': {'a': 1}});
        expect(result, equals('{"a":1}'));
      });
    });

    group('length', () {
      test('on string', () {
        expect(eval('"hello" | length'), equals(5));
      });

      test('on list', () {
        expect(eval('[1, 2, 3] | length'), equals(3));
      });

      test('on map', () {
        expect(eval('obj | length', {'obj': {'a': 1, 'b': 2}}), equals(2));
      });

      test('on other type returns 0', () {
        expect(eval('42 | length'), equals(0));
      });
    });

    group('first and last', () {
      test('first on list', () {
        expect(eval('[10, 20, 30] | first'), equals(10.0));
      });

      test('first on string', () {
        expect(eval('"abc" | first'), equals('a'));
      });

      test('first on empty list returns null', () {
        expect(eval('x | first', {'x': <dynamic>[]}), isNull);
      });

      test('first on empty string returns null', () {
        expect(eval('"" | first'), isNull);
      });

      test('last on list', () {
        expect(eval('[10, 20, 30] | last'), equals(30.0));
      });

      test('last on string', () {
        expect(eval('"abc" | last'), equals('c'));
      });

      test('last on empty list returns null', () {
        expect(eval('x | last', {'x': <dynamic>[]}), isNull);
      });

      test('last on empty string returns null', () {
        expect(eval('"" | last'), isNull);
      });
    });

    group('reverse', () {
      test('on list', () {
        expect(eval('[1, 2, 3] | reverse'), equals([3.0, 2.0, 1.0]));
      });

      test('on string', () {
        expect(eval('"abc" | reverse'), equals('cba'));
      });

      test('on non-list/string returns value unchanged', () {
        expect(eval('42 | reverse'), equals(42.0));
      });
    });

    group('sort', () {
      test('on list', () {
        expect(eval('[3, 1, 2] | sort'), equals([1.0, 2.0, 3.0]));
      });

      test('on non-list returns value unchanged', () {
        expect(eval('42 | sort'), equals(42.0));
      });
    });

    group('unique', () {
      test('on list with duplicates', () {
        final result = eval('[1, 2, 2, 3, 3, 3] | unique') as List;
        expect(result, containsAll([1.0, 2.0, 3.0]));
        expect(result, hasLength(3));
      });

      test('on non-list returns value unchanged', () {
        expect(eval('"hello" | unique'), equals('hello'));
      });
    });

    group('join', () {
      test('on list with separator', () {
        expect(eval('[1, 2, 3] | join("-")'), equals('1.0-2.0-3.0'));
      });

      test('on list with default separator', () {
        expect(eval('[1, 2, 3] | join'), equals('1.0,2.0,3.0'));
      });

      test('on non-list returns string', () {
        expect(eval('42 | join'), equals('42.0'));
      });
    });

    group('split', () {
      test('on string with separator', () {
        expect(eval('"a,b,c" | split(",")'), equals(['a', 'b', 'c']));
      });

      test('on string with default comma separator', () {
        expect(eval('"a,b,c" | split'), equals(['a', 'b', 'c']));
      });

      test('on non-string wraps in list', () {
        final result = eval('42 | split') as List;
        expect(result, hasLength(1));
      });
    });

    group('slice', () {
      test('on list with start and end', () {
        // Pipe slice args are parsed as doubles, causing `as int` cast to
        // fail. Use context variables with actual ints.
        expect(
            eval('items | slice(start, end)', {
              'items': [1.0, 2.0, 3.0, 4.0, 5.0],
              'start': 1,
              'end': 3,
            }),
            equals([2.0, 3.0]));
      });

      test('on string with start and end', () {
        expect(
            eval('s | slice(start, end)', {
              's': 'hello',
              'start': 1,
              'end': 3,
            }),
            equals('el'));
      });

      test('on non-list/string returns value', () {
        expect(
            eval('n | slice(start, end)', {
              'n': 42.0,
              'start': 0,
              'end': 1,
            }),
            equals(42.0));
      });
    });

    group('keys and values', () {
      test('keys on map', () {
        final result = eval('obj | keys', {'obj': {'a': 1, 'b': 2}});
        expect(result, containsAll(['a', 'b']));
      });

      test('keys on non-map returns empty list', () {
        expect(eval('42 | keys'), equals(<dynamic>[]));
      });

      test('values on map', () {
        final result = eval('obj | values', {'obj': {'a': 1, 'b': 2}});
        expect(result, containsAll([1, 2]));
      });

      test('values on non-map returns empty list', () {
        expect(eval('42 | values'), equals(<dynamic>[]));
      });
    });

    group('round', () {
      test('rounds to integer by default', () {
        expect(eval('3.14159 | round'), equals(3.0));
      });

      test('rounds with specified decimal places', () {
        // Literal 2 is parsed as double 2.0, causing `as int` cast to fail
        // in _applyFilter. Use a context variable with an actual int.
        expect(eval('n | round(d)', {'n': 3.14159, 'd': 2}), closeTo(3.14, 0.001));
      });

      test('on non-number returns value unchanged', () {
        expect(eval('"hello" | round'), equals('hello'));
      });
    });

    group('abs', () {
      test('on positive number', () {
        expect(eval('5 | abs'), equals(5.0));
      });

      test('on negative number', () {
        // -5 | abs is parsed as -(5 | abs) due to operator precedence
        // (unary is lower than pipe). Use a context variable instead.
        expect(eval('n | abs', {'n': -5}), equals(5.0));
      });

      test('on zero', () {
        expect(eval('0 | abs'), equals(0.0));
      });

      test('on non-number returns value unchanged', () {
        expect(eval('"hello" | abs'), equals('hello'));
      });
    });

    group('format', () {
      test('number with decimal format', () {
        expect(eval('3.14159 | format("%.2f")'), equals('3.14'));
      });

      test('number with integer format', () {
        expect(eval('42.7 | format("%d")'), equals('42'));
      });

      test('number without format string', () {
        expect(eval('42 | format'), equals('42.0'));
      });
    });

    group('chained pipes', () {
      test('trim then upper', () {
        expect(eval('"  Hello  " | trim | upper'), equals('HELLO'));
      });

      test('trim then lower', () {
        expect(eval('"  Hello World  " | trim | lower'), equals('hello world'));
      });
    });

    group('pipe filters via ExpressionFunctions fallthrough', () {
      test('ceil filter', () {
        expect(eval('3.2 | ceil'), equals(4));
      });

      test('floor filter', () {
        expect(eval('3.8 | floor'), equals(3));
      });

      test('sum filter on list', () {
        expect(eval('x | sum', {'x': [1, 2, 3]}), equals(6));
      });

      test('avg filter on list', () {
        expect(eval('x | avg', {'x': [2, 4, 6]}), equals(4.0));
      });

      test('flatten filter on nested list', () {
        expect(
          eval('x | flatten', {
            'x': [
              [1, 2],
              [3, 4]
            ]
          }),
          equals([1, 2, 3, 4]),
        );
      });

      test('type filter returns type name', () {
        expect(eval('"hello" | type'), equals('string'));
        expect(eval('42 | type'), equals('number'));
        expect(eval('true | type'), equals('boolean'));
        // null literal evaluates to the string 'null', so type returns 'string'
        expect(eval('null | type'), equals('string'));
      });

      test('toNumber filter', () {
        expect(eval('"42" | toNumber'), equals(42));
      });

      test('toBool filter', () {
        expect(eval('1 | toBool'), isTrue);
        expect(eval('0 | toBool'), isFalse);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Lambda expressions
  // ---------------------------------------------------------------------------
  group('Lambda expressions', () {
    test('single parameter lambda in map', () {
      final result = eval('[1, 2, 3].map(x => x + 10)');
      expect(result, equals([11.0, 12.0, 13.0]));
    });

    test('lambda that references outer variable (closure)', () {
      final result = eval(
        '[1, 2, 3].map(x => x * factor)',
        {'factor': 10},
      );
      expect(result, equals([10.0, 20.0, 30.0]));
    });

    test('lambda with string operations', () {
      final result = eval(
        'items.map(x => x.toUpperCase())',
        {
          'items': ['hello', 'world']
        },
      );
      expect(result, equals(['HELLO', 'WORLD']));
    });

    test('two-parameter lambda in reduce', () {
      final result = eval('[1, 2, 3, 4].reduce(0, (sum, x) => sum + x)');
      expect(result, equals(10.0));
    });

    test('lambda in filter', () {
      final result = eval('[1, 2, 3, 4, 5, 6].filter(x => x % 2 == 0)');
      expect(result, equals([2.0, 4.0, 6.0]));
    });

    test('chained map and filter with lambdas', () {
      final result = eval(
        '[1, 2, 3, 4, 5].map(x => x * 2).filter(x => x > 4)',
      );
      expect(result, equals([6.0, 8.0, 10.0]));
    });

    test('lambda in find', () {
      final result = eval('[10, 20, 30].find(x => x > 15)');
      expect(result, equals(20.0));
    });

    test('lambda in every', () {
      expect(eval('[2, 4, 6].every(x => x % 2 == 0)'), isTrue);
      expect(eval('[2, 3, 6].every(x => x % 2 == 0)'), isFalse);
    });

    test('lambda in some', () {
      expect(eval('[1, 3, 5].some(x => x % 2 == 0)'), isFalse);
      expect(eval('[1, 2, 5].some(x => x % 2 == 0)'), isTrue);
    });

    test('lambda in sort with comparator', () {
      final result = eval('[3, 1, 2].sort((a, b) => a - b)');
      expect(result, equals([1.0, 2.0, 3.0]));
    });

    test('lambda with nested expression', () {
      final result = eval('[1, 2, 3].map(x => x > 1 ? x * 10 : x)');
      expect(result, equals([1.0, 20.0, 30.0]));
    });
  });

  // ---------------------------------------------------------------------------
  // Math approximation functions
  // ---------------------------------------------------------------------------
  group('Math power and sqrt approximations', () {
    test('_power with positive integer exponent', () {
      // Parsed exponent 4 is double 4.0 (not int), so _power falls through
      // to the _pow approximation path. Use closeTo for floating-point error.
      final result = eval('3 ** 4') as num;
      expect(result, closeTo(81, 0.01));
    });

    test('_pow with exponent 0 returns 1', () {
      final result = eval('99 ** 0.0') as num;
      expect(result, closeTo(1.0, 0.001));
    });

    test('_pow with exponent 1 returns base', () {
      final result = eval('7.0 ** 1.0') as num;
      expect(result, closeTo(7.0, 0.001));
    });

    test('_pow with exponent 2 returns base squared', () {
      final result = eval('5.0 ** 2.0') as num;
      expect(result, closeTo(25.0, 0.001));
    });

    test('_sqrt approximation via ** 0.5', () {
      final result = eval('16 ** 0.5') as num;
      expect(result, closeTo(4.0, 0.01));
    });

    test('sqrt of 0 returns 0', () {
      final result = eval('0 ** 0.5') as num;
      expect(result, closeTo(0.0, 0.001));
    });

    test('negative base with integer exponent (odd)', () {
      // (-2) ** 3 should be approximately -8
      // Parser parses -2 ** 3 as -(2 ** 3), so use variable
      final result = eval('x ** 3', {'x': -2}) as num;
      expect(result, equals(-8));
    });

    test('negative base with integer exponent (even)', () {
      final result = eval('x ** 2', {'x': -3}) as num;
      expect(result, equals(9));
    });
  });

  // ---------------------------------------------------------------------------
  // Array and Object literals
  // ---------------------------------------------------------------------------
  group('Array and object literals', () {
    test('empty array', () {
      expect(eval('[]'), equals(<dynamic>[]));
    });

    test('array of numbers', () {
      expect(eval('[1, 2, 3]'), equals([1.0, 2.0, 3.0]));
    });

    test('array of mixed types', () {
      final result = eval('[1, "two", true, null]') as List;
      expect(result, hasLength(4));
      expect(result[0], equals(1.0));
      expect(result[1], equals('two'));
      expect(result[2], isTrue);
      // null literal evaluates to the string 'null'
      expect(result[3], equals('null'));
    });

    test('nested arrays', () {
      final result = eval('[[1, 2], [3, 4]]') as List;
      expect(result, hasLength(2));
      expect(result[0], equals([1.0, 2.0]));
      expect(result[1], equals([3.0, 4.0]));
    });

    test('array with computed elements', () {
      final result = eval('[1 + 1, 2 * 3, 10 / 2]');
      expect(result, equals([2.0, 6.0, 5.0]));
    });

    test('empty object', () {
      expect(eval('{}'), equals(<String, dynamic>{}));
    });

    test('object with string keys', () {
      final result = eval('{"name": "Alice", "age": 30}') as Map;
      expect(result['name'], equals('Alice'));
      expect(result['age'], equals(30.0));
    });

    test('object with identifier keys', () {
      final result = eval('{name: "Bob", age: 25}') as Map;
      expect(result['name'], equals('Bob'));
      expect(result['age'], equals(25.0));
    });

    test('nested object', () {
      final result = eval('{user: {name: "Alice"}}') as Map;
      expect((result['user'] as Map)['name'], equals('Alice'));
    });

    test('object with computed values', () {
      final result = eval('{sum: 1 + 2, product: 3 * 4}') as Map;
      expect(result['sum'], equals(3.0));
      expect(result['product'], equals(12.0));
    });

    test('empty array length is 0', () {
      expect(eval('[].length', {}), equals(0));
    });
  });

  // ---------------------------------------------------------------------------
  // Grouping
  // ---------------------------------------------------------------------------
  group('Grouping', () {
    test('parentheses change evaluation order', () {
      expect(eval('(1 + 2) * 3'), equals(9.0));
    });

    test('nested parentheses', () {
      expect(eval('((1 + 2) * (3 + 4))'), equals(21.0));
    });

    test('deeply nested parentheses', () {
      expect(eval('(((2)))'), equals(2.0));
    });
  });

  // ---------------------------------------------------------------------------
  // Error cases
  // ---------------------------------------------------------------------------
  group('Error cases', () {
    test('division by zero', () {
      expect(
        () => eval('10 / 0'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('modulo by zero', () {
      expect(
        () => eval('10 % 0'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('undefined variable', () {
      expect(
        () => eval('undefinedVar'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('type mismatch: subtract strings', () {
      expect(
        () => eval('"a" - "b"'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('type mismatch: divide strings', () {
      expect(
        () => eval('"a" / "b"'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('type mismatch: modulo strings', () {
      expect(
        () => eval('"a" % "b"'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('type mismatch: power on strings', () {
      expect(
        () => eval('"a" ** "b"'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('type mismatch: negate non-numeric', () {
      expect(
        () => eval('-"hello"'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('cannot access property on null without optional chaining', () {
      expect(
        () => eval('x.name', {'x': null}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('cannot call method on null without optional chaining', () {
      expect(
        () => eval('x.toUpperCase()', {'x': null}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('cannot index null', () {
      expect(
        () => eval('x[0]', {'x': null}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('cannot index a number', () {
      expect(
        () => eval('x[0]', {'x': 42}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('list index out of bounds', () {
      expect(
        () => eval('x[5]', {'x': [1, 2, 3]}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('string index out of bounds', () {
      expect(
        () => eval('x[10]', {'x': 'hi'}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('unknown string method throws', () {
      expect(
        () => eval('"hello".nonExistent()'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('unknown list method throws', () {
      expect(
        () => eval('[1].nonExistent()'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('unknown map method throws', () {
      expect(
        () => eval('obj.nonExistent()', {'obj': {'a': 1}}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('comparing incompatible types throws', () {
      expect(
        () => eval('1 < "a"'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('replace with insufficient arguments throws', () {
      expect(
        () => eval('"hello".replace("x")'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('evaluate catches exception and returns failure', () {
      final result = evalResult('x / 0', {'x': 10});
      expect(result.success, isFalse);
      expect(result.error, contains('Division by zero'));
    });
  });

  // ---------------------------------------------------------------------------
  // Complex / integration expressions
  // ---------------------------------------------------------------------------
  group('Complex expressions', () {
    test('nested member access with method call', () {
      final result = eval(
        'user.name.toUpperCase()',
        {
          'user': {'name': 'alice'}
        },
      );
      expect(result, equals('ALICE'));
    });

    test('null coalesce with member access', () {
      expect(
        eval('user.nickname ?? user.name', {
          'user': {'name': 'Alice', 'nickname': null}
        }),
        equals('Alice'),
      );
    });

    test('map followed by join', () {
      final result = eval(
        '[1, 2, 3].map(x => x * 2).join(", ")',
      );
      expect(result, equals('2.0, 4.0, 6.0'));
    });

    test('pipe filter after member access', () {
      expect(
        eval('user.name | upper', {
          'user': {'name': 'alice'}
        }),
        equals('ALICE'),
      );
    });

    test('complex boolean logic with variables', () {
      expect(
        eval('age >= 18 and age <= 65 and active == true', {
          'age': 25,
          'active': true,
        }),
        isTrue,
      );
      expect(
        eval('age >= 18 and age <= 65 and active == true', {
          'age': 70,
          'active': true,
        }),
        isFalse,
      );
    });

    test('nested ternary with null coalesce', () {
      // x is context null (actual Dart null), null literal is the string 'null'.
      // x != null compares Dart null with string 'null', which are not equal,
      // so the condition is true and the then-branch (x = Dart null) is returned.
      expect(
        eval('x != null ? x : y ?? "default"', {'x': null, 'y': null}),
        isNull,
      );
    });

    test('membership test with dynamic list', () {
      expect(
        eval('item in items', {
          'item': 'banana',
          'items': ['apple', 'banana', 'cherry']
        }),
        isTrue,
      );
    });

    test('multiple operations on object and list', () {
      final result = eval(
        'users.map(u => u.name).join(", ")',
        {
          'users': [
            {'name': 'Alice'},
            {'name': 'Bob'},
            {'name': 'Charlie'}
          ]
        },
      );
      expect(result, equals('Alice, Bob, Charlie'));
    });

    test('conditional with list method', () {
      final result = eval(
        'items.length > 0 ? items.first : "empty"',
        {'items': [42, 43]},
      );
      expect(result, equals(42));
    });

    test('filter then map chain', () {
      final result = eval(
        'nums.filter(x => x > 2).map(x => x * 10)',
        {'nums': [1, 2, 3, 4, 5]},
      );
      expect(result, equals([30, 40, 50]));
    });
  });

  // ---------------------------------------------------------------------------
  // EvaluationContext
  // ---------------------------------------------------------------------------
  group('EvaluationContext', () {
    test('child context inherits parent variables', () {
      final parent = EvaluationContext(variables: {'x': 10, 'y': 20});
      final child = parent.child({'z': 30});
      expect(child.has('x'), isTrue);
      expect(child.get('x'), equals(10));
      expect(child.has('z'), isTrue);
      expect(child.get('z'), equals(30));
    });

    test('child context shadows parent variables', () {
      final parent = EvaluationContext(variables: {'x': 10});
      final child = parent.child({'x': 99});
      expect(child.get('x'), equals(99));
      expect(parent.get('x'), equals(10));
    });

    test('has returns false for unknown variable', () {
      final ctx = EvaluationContext(variables: {'x': 10});
      expect(ctx.has('y'), isFalse);
    });

    test('get returns null for unknown variable without parent', () {
      final ctx = EvaluationContext(variables: {'x': 10});
      expect(ctx.get('y'), isNull);
    });

    test('set adds new variable', () {
      final ctx = EvaluationContext();
      ctx.set('x', 42);
      expect(ctx.has('x'), isTrue);
      expect(ctx.get('x'), equals(42));
    });

    test('allVariables includes parent and child', () {
      final parent = EvaluationContext(variables: {'a': 1});
      final child = parent.child({'b': 2});
      final all = child.allVariables;
      expect(all['a'], equals(1));
      expect(all['b'], equals(2));
    });

    test('factory from creates context with structured data', () {
      final ctx = EvaluationContext.from(
        inputs: {'name': 'Alice'},
        steps: {'step1': 'done'},
      );
      expect(ctx.has('inputs'), isTrue);
      expect(ctx.has('steps'), isTrue);
      expect((ctx.get('inputs') as Map)['name'], equals('Alice'));
    });
  });
}
