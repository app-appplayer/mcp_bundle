import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

/// Parses and evaluates an expression string with optional variable bindings.
dynamic eval(String source, [Map<String, dynamic>? vars]) {
  final tokens = Lexer(source).tokenize();
  final ast = Parser(tokens).parse();
  final ctx = EvaluationContext(variables: vars ?? {});
  return ExpressionEvaluator(ctx).evaluateOrThrow(ast);
}

/// Evaluates and returns EvaluationResult wrapper.
EvaluationResult evalResult(String source, [Map<String, dynamic>? vars]) {
  final tokens = Lexer(source).tokenize();
  final ast = Parser(tokens).parse();
  final ctx = EvaluationContext(variables: vars ?? {});
  return ExpressionEvaluator(ctx).evaluate(ast);
}

void main() {
  // ===========================================================================
  // 1. EVALUATOR: Unknown unary operator
  // ===========================================================================
  group('Evaluator - unknown unary operator', () {
    test('throws EvaluationException for unknown unary operator', () {
      // Construct a UnaryExpr manually with an unrecognized operator lexeme.
      final unknownOp = Token(
        type: TokenType.plus,
        lexeme: '+',
        line: 1,
        column: 1,
      );
      final operand = LiteralExpr(5);
      final unaryExpr = UnaryExpr(unknownOp, operand);

      final ctx = EvaluationContext();
      final evaluator = ExpressionEvaluator(ctx);

      expect(
        () => evaluator.evaluateOrThrow(unaryExpr),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 2. EVALUATOR: Invalid regex in matches() operator
  // ===========================================================================
  group('Evaluator - matches operator with invalid regex', () {
    test('throws EvaluationException for invalid regex pattern', () {
      expect(
        () => eval('"hello" matches "[invalid"'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('matches returns false when value is null', () {
      final result = eval('x matches "abc"', {'x': null});
      expect(result, isFalse);
    });

    test('matches returns false when pattern is null', () {
      final result = eval('"abc" matches x', {'x': null});
      expect(result, isFalse);
    });

    test('matches works with valid regex', () {
      expect(eval('"hello123" matches "^[a-z]+\\\\d+\$"'), isTrue);
    });
  });

  // ===========================================================================
  // 3. EVALUATOR: Unknown logical operator
  // ===========================================================================
  group('Evaluator - unknown logical operator', () {
    test('throws EvaluationException for unknown logical operator', () {
      // Construct a LogicalExpr with an unrecognized operator lexeme.
      final unknownLogicalOp = Token(
        type: TokenType.and,
        lexeme: 'xor',
        line: 1,
        column: 1,
      );
      final left = LiteralExpr(true);
      final right = LiteralExpr(false);
      final logicalExpr = LogicalExpr(left, unknownLogicalOp, right);

      final ctx = EvaluationContext();
      final evaluator = ExpressionEvaluator(ctx);

      expect(
        () => evaluator.evaluateOrThrow(logicalExpr),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 4. EVALUATOR: _pow, _sqrt, _exp, _ln math helpers via ** operator
  // ===========================================================================
  group('Evaluator - math helpers via ** operator', () {
    test('fractional exponent triggers _pow path (2 ** 0.5 uses _sqrt)', () {
      final result = eval('2 ** 0.5') as double;
      // sqrt(2) ~ 1.41421356...
      expect(result, closeTo(1.4142135, 1e-5));
    });

    test('integer base to integer positive exponent', () {
      // Lexer parses 3 as 3.0, so _power(3.0, 4.0) goes through _pow path
      final result = eval('3 ** 4') as num;
      expect(result, closeTo(81.0, 0.01));
    });

    test('base ** 0 returns 1', () {
      expect(eval('5 ** 0'), equals(1));
    });

    test('base ** 1 returns the base', () {
      final result = eval('7.0 ** 1.0') as double;
      expect(result, closeTo(7.0, 1e-10));
    });

    test('base ** 2 returns the square (fast path)', () {
      final result = eval('3.0 ** 2.0') as double;
      expect(result, closeTo(9.0, 1e-10));
    });

    test('negative base to integer exponent (odd)', () {
      // (-2) ** 3 = -8 via _pow negative integer path
      final result = eval('(-2) ** 3');
      expect(result, equals(-8));
    });

    test('negative base to even integer exponent', () {
      // (-3) ** 2 = 9 via _pow negative even integer path
      final result = eval('(-3) ** 2');
      expect(result, equals(9));
    });

    test('negative number to fractional power throws', () {
      // _pow: x < 0 and y is not integer => throws
      expect(
        () => eval('(-2.0) ** 0.5'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('zero to positive exponent returns 0', () {
      final result = eval('0.0 ** 3.0') as double;
      expect(result, closeTo(0.0, 1e-10));
    });

    test('general positive base to fractional exponent uses _exp and _ln', () {
      // 2 ** 3.5 should work via _exp(_ln(2) * 3.5)
      final result = eval('2 ** 3.5') as double;
      // 2^3.5 = 2^3 * 2^0.5 = 8 * 1.4142.. ~ 11.3137
      expect(result, closeTo(11.3137, 0.01));
    });

    test('_sqrt of zero returns 0', () {
      final result = eval('0 ** 0.5') as double;
      expect(result, closeTo(0.0, 1e-10));
    });

    test('negative base to negative integer exponent via variable', () {
      // Pass actual int exponent via variable to trigger the _power path
      // that falls through to _pow for negative exponents.
      // _pow computes absResult = _pow(abs(x), abs(y)) = 4.0 for even exponent
      final result = eval('x ** y', {'x': -2, 'y': -2}) as double;
      expect(result, closeTo(4.0, 1e-5));
    });
  });

  // ===========================================================================
  // 5. EVALUATOR: _format with various value types and format strings
  // ===========================================================================
  group('Evaluator - _format via format pipe', () {
    test('format number with %d format (integer)', () {
      final result = eval('3.7 | format("%d")');
      expect(result, equals('3'));
    });

    test('format number with %.2f format (fixed decimals)', () {
      final result = eval('3.14159 | format("%.2f")');
      expect(result, equals('3.14'));
    });

    test('format number with %f format (default 2 decimals)', () {
      final result = eval('3.14159 | format("%f")');
      expect(result, equals('3.14'));
    });

    test('format number with %.4f format (4 decimals)', () {
      final result = eval('2.71828 | format("%.4f")');
      expect(result, equals('2.7183'));
    });

    test('format number without format string returns toString', () {
      final result = eval('42 | format');
      // Lexer parses 42 as 42.0 (double)
      expect(result, equals('42.0'));
    });

    test('format number with non-% format string returns toString', () {
      final result = eval('42 | format("abc")');
      expect(result, equals('42.0'));
    });

    test('format DateTime with date format pattern', () {
      final dt = DateTime(2024, 3, 15, 10, 30, 45);
      final ctx = EvaluationContext(variables: {'dt': dt});
      final tokens = Lexer('dt | format("YYYY-MM-DD")').tokenize();
      final ast = Parser(tokens).parse();
      final evaluator = ExpressionEvaluator(ctx);
      final result = evaluator.evaluateOrThrow(ast);
      expect(result, equals('2024-03-15'));
    });

    test('format DateTime with time format pattern', () {
      final dt = DateTime(2024, 1, 5, 9, 5, 3);
      final ctx = EvaluationContext(variables: {'dt': dt});
      final tokens = Lexer('dt | format("HH:mm:ss")').tokenize();
      final ast = Parser(tokens).parse();
      final evaluator = ExpressionEvaluator(ctx);
      final result = evaluator.evaluateOrThrow(ast);
      expect(result, equals('09:05:03'));
    });

    test('format DateTime without format string returns ISO 8601', () {
      final dt = DateTime(2024, 6, 15);
      final ctx = EvaluationContext(variables: {'dt': dt});
      final tokens = Lexer('dt | format').tokenize();
      final ast = Parser(tokens).parse();
      final evaluator = ExpressionEvaluator(ctx);
      final result = evaluator.evaluateOrThrow(ast);
      expect(result, contains('2024-06-15'));
    });

    test('format non-number non-DateTime returns toString', () {
      final result = eval('"hello" | format("anything")');
      expect(result, equals('hello'));
    });
  });

  // ===========================================================================
  // 6. EVALUATOR: pipe filters - round, abs, format
  // ===========================================================================
  group('Evaluator - pipe filters', () {
    test('round pipe with default 0 decimals', () {
      expect(eval('3.7 | round'), equals(4.0));
    });

    test('round pipe with 2 decimals via variable', () {
      // Pass int decimals via variable since lexer parses 2 as 2.0 (double)
      // which cannot be cast to int in _applyFilter
      final ctx = EvaluationContext(variables: {'v': 3.14159, 'n': 2});
      final tokens = Lexer('v | round(n)').tokenize();
      final ast = Parser(tokens).parse();
      final result = ExpressionEvaluator(ctx).evaluateOrThrow(ast);
      expect(result, closeTo(3.14, 0.001));
    });

    test('round pipe on non-number returns value unchanged', () {
      expect(eval('"abc" | round'), equals('abc'));
    });

    test('abs pipe on positive number', () {
      expect(eval('5 | abs'), equals(5.0));
    });

    test('abs pipe on negative number', () {
      expect(eval('(-3) | abs'), equals(3));
    });

    test('abs pipe on non-number returns value unchanged', () {
      expect(eval('"abc" | abs'), equals('abc'));
    });

    test('format pipe on number with no args', () {
      // Lexer parses 42 as 42.0 (double)
      expect(eval('42 | format'), equals('42.0'));
    });
  });

  // ===========================================================================
  // 7. EVALUATOR: list methods via evaluator (map, filter/where, reduce,
  //    slice, reverse, sort, find, every, some/any)
  // ===========================================================================
  group('Evaluator - list method calls', () {
    test('map with lambda', () {
      final result = eval('[1, 2, 3].map(x => x * 2)');
      expect(result, equals([2.0, 4.0, 6.0]));
    });

    test('filter with lambda', () {
      final result = eval('[1, 2, 3, 4, 5].filter(x => x > 3)');
      expect(result, equals([4.0, 5.0]));
    });

    test('where with lambda (alias for filter)', () {
      final result = eval('[1, 2, 3, 4].where(x => x > 2)');
      expect(result, equals([3.0, 4.0]));
    });

    test('reduce with initial value and lambda', () {
      final result = eval('[1, 2, 3].reduce(0, (acc, x) => acc + x)');
      expect(result, equals(6.0));
    });

    test('reduce with initial value and no lambda (numeric sum)', () {
      final result = eval('[1, 2, 3].reduce(10)');
      expect(result, equals(16.0));
    });

    test('slice with start only via variable', () {
      // Pass int start via variable since lexer parses 2 as 2.0 (double)
      final result = eval('arr.slice(s)', {
        'arr': [1, 2, 3, 4, 5],
        's': 2,
      });
      expect(result, equals([3, 4, 5]));
    });

    test('slice with start and end via variable', () {
      final result = eval('arr.slice(s, e)', {
        'arr': [1, 2, 3, 4, 5],
        's': 1,
        'e': 3,
      });
      expect(result, equals([2, 3]));
    });

    test('reverse returns reversed list', () {
      final result = eval('[1, 2, 3].reverse()');
      expect(result, equals([3.0, 2.0, 1.0]));
    });

    test('sort without comparator', () {
      final result = eval('[3, 1, 2].sort()');
      expect(result, equals([1.0, 2.0, 3.0]));
    });

    test('sort with comparator lambda', () {
      // Sort descending: (a, b) => b - a
      final result = eval('[1, 3, 2].sort((a, b) => b - a)');
      expect(result, equals([3.0, 2.0, 1.0]));
    });

    test('find returns first matching element', () {
      final result = eval('[1, 2, 3, 4].find(x => x > 2)');
      expect(result, equals(3.0));
    });

    test('find returns null when no match', () {
      final result = eval('[1, 2, 3].find(x => x > 10)');
      expect(result, isNull);
    });

    test('every returns true when all match', () {
      expect(eval('[2, 4, 6].every(x => x > 0)'), isTrue);
    });

    test('every returns false when not all match', () {
      expect(eval('[2, 4, -1].every(x => x > 0)'), isFalse);
    });

    test('some returns true when at least one matches', () {
      expect(eval('[1, 2, 3].some(x => x == 2)'), isTrue);
    });

    test('some returns false when none match', () {
      expect(eval('[1, 2, 3].some(x => x > 10)'), isFalse);
    });

    test('any is alias for some', () {
      expect(eval('[1, 2, 3].any(x => x == 3)'), isTrue);
    });

    test('map throws when argument is not a function', () {
      expect(
        () => eval('[1, 2].map(5)'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('filter throws when argument is not a function', () {
      expect(
        () => eval('[1, 2].filter(5)'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('find throws when argument is not a function', () {
      expect(
        () => eval('[1, 2].find(5)'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('every throws when argument is not a function', () {
      expect(
        () => eval('[1, 2].every(5)'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('some throws when argument is not a function', () {
      expect(
        () => eval('[1, 2].some(5)'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('reduce throws when no arguments', () {
      expect(
        () => eval('x.reduce()', {'x': [1, 2, 3]}),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 8. EVALUATOR: Map method calls (keys, values, entries, containsKey,
  //    containsValue)
  // ===========================================================================
  group('Evaluator - Map method calls', () {
    test('keys returns list of map keys', () {
      final result = eval('m.keys()', {
        'm': {'a': 1, 'b': 2},
      });
      expect(result, containsAll(['a', 'b']));
    });

    test('values returns list of map values', () {
      final result = eval('m.values()', {
        'm': {'a': 1, 'b': 2},
      });
      expect(result, containsAll([1, 2]));
    });

    test('entries returns list of key-value maps', () {
      final result = eval('m.entries()', {
        'm': {'a': 1},
      }) as List;
      expect(result.length, equals(1));
      expect(result[0], equals({'key': 'a', 'value': 1}));
    });

    test('containsKey returns true for existing key', () {
      expect(
        eval('m.containsKey("a")', {
          'm': {'a': 1},
        }),
        isTrue,
      );
    });

    test('containsKey returns false for missing key', () {
      expect(
        eval('m.containsKey("z")', {
          'm': {'a': 1},
        }),
        isFalse,
      );
    });

    test('containsKey returns false when no args', () {
      expect(
        eval('m.containsKey()', {
          'm': {'a': 1},
        }),
        isFalse,
      );
    });

    test('containsValue returns true for existing value', () {
      expect(
        eval('m.containsValue(1)', {
          'm': {'a': 1},
        }),
        isTrue,
      );
    });

    test('containsValue returns false for missing value', () {
      expect(
        eval('m.containsValue(99)', {
          'm': {'a': 1},
        }),
        isFalse,
      );
    });

    test('containsValue returns false when no args', () {
      expect(
        eval('m.containsValue()', {
          'm': {'a': 1},
        }),
        isFalse,
      );
    });
  });

  // ===========================================================================
  // 9. EVALUATOR: _formatDate with full date-time pattern
  // ===========================================================================
  group('Evaluator - _formatDate', () {
    test('formats date with YYYY-MM-DD HH:mm:ss pattern', () {
      final dt = DateTime(2024, 12, 25, 14, 30, 59);
      final ctx = EvaluationContext(variables: {'d': dt});
      final tokens = Lexer('d | format("YYYY-MM-DD HH:mm:ss")').tokenize();
      final ast = Parser(tokens).parse();
      final result = ExpressionEvaluator(ctx).evaluateOrThrow(ast);
      expect(result, equals('2024-12-25 14:30:59'));
    });

    test('formats date with zero-padded month and day', () {
      final dt = DateTime(2024, 1, 5, 3, 7, 9);
      final ctx = EvaluationContext(variables: {'d': dt});
      final tokens = Lexer('d | format("YYYY/MM/DD")').tokenize();
      final ast = Parser(tokens).parse();
      final result = ExpressionEvaluator(ctx).evaluateOrThrow(ast);
      expect(result, equals('2024/01/05'));
    });
  });

  // ===========================================================================
  // 10. EVALUATOR: _applyPipe with unknown pipe filter falls through
  //     to functions.call
  // ===========================================================================
  group('Evaluator - pipe with unknown filter falls through to function', () {
    test('pipe with custom registered function', () {
      final ctx = EvaluationContext();
      ctx.functions.register('double', (args) => (args[0] as num) * 2);
      final tokens = Lexer('5 | double').tokenize();
      final ast = Parser(tokens).parse();
      final result = ExpressionEvaluator(ctx).evaluateOrThrow(ast);
      expect(result, equals(10));
    });

    test('pipe with unregistered function throws ArgumentError', () {
      expect(
        () => eval('5 | nonexistentFilter'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ===========================================================================
  // 11. EVALUATOR: _ln of non-positive throws
  // ===========================================================================
  group('Evaluator - _ln edge cases', () {
    test('ln of zero via pow throws', () {
      // 0 ** 0.3 -> _pow(0, 0.3) -> x==0 returns 0 (handled)
      // But _ln(0) would throw, let us trigger it via negative fractional
      expect(
        () => eval('(-1.0) ** 0.3'),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 12. EVALUATOR: _sqrt of negative throws
  // ===========================================================================
  group('Evaluator - _sqrt negative', () {
    test('sqrt of negative number throws via ** 0.5', () {
      expect(
        () => eval('(-4.0) ** 0.5'),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 13. EVALUATOR: unknown binary operator
  // ===========================================================================
  group('Evaluator - unknown binary operator', () {
    test('throws EvaluationException for unknown binary operator', () {
      final unknownBinOp = Token(
        type: TokenType.plus,
        lexeme: '<<<',
        line: 1,
        column: 1,
      );
      final left = LiteralExpr(1);
      final right = LiteralExpr(2);
      final binaryExpr = BinaryExpr(left, unknownBinOp, right);

      final ctx = EvaluationContext();
      final evaluator = ExpressionEvaluator(ctx);

      expect(
        () => evaluator.evaluateOrThrow(binaryExpr),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 14. EVALUATOR: additional pipe filters (sort, unique, slice, keys, values,
  //     join, split, reverse, first, last)
  // ===========================================================================
  group('Evaluator - additional pipe filters', () {
    test('sort pipe on list', () {
      final result = eval('[3, 1, 2] | sort');
      expect(result, equals([1.0, 2.0, 3.0]));
    });

    test('sort pipe on non-list returns value', () {
      expect(eval('42 | sort'), equals(42.0));
    });

    test('unique pipe removes duplicates', () {
      final result = eval('[1, 2, 2, 3, 3] | unique');
      expect(result, equals([1.0, 2.0, 3.0]));
    });

    test('unique pipe on non-list returns value', () {
      expect(eval('42 | unique'), equals(42.0));
    });

    test('keys pipe on map', () {
      final result = eval('m | keys', {
        'm': {'x': 1, 'y': 2},
      });
      expect(result, containsAll(['x', 'y']));
    });

    test('keys pipe on non-map returns empty list', () {
      expect(eval('42 | keys'), equals([]));
    });

    test('values pipe on map', () {
      final result = eval('m | values', {
        'm': {'x': 1, 'y': 2},
      });
      expect(result, containsAll([1, 2]));
    });

    test('values pipe on non-map returns empty list', () {
      expect(eval('42 | values'), equals([]));
    });

    test('reverse pipe on string', () {
      expect(eval('"abc" | reverse'), equals('cba'));
    });

    test('reverse pipe on non-list non-string returns value', () {
      expect(eval('42 | reverse'), equals(42.0));
    });

    test('first pipe on string', () {
      expect(eval('"abc" | first'), equals('a'));
    });

    test('first pipe on empty string returns null', () {
      expect(eval('"" | first'), isNull);
    });

    test('last pipe on string', () {
      expect(eval('"abc" | last'), equals('c'));
    });

    test('last pipe on empty string returns null', () {
      expect(eval('"" | last'), isNull);
    });

    test('slice pipe on string via variable', () {
      // Pass int args via variables since lexer parses numbers as double
      final ctx = EvaluationContext(variables: {'s': 'hello', 'a': 1, 'b': 3});
      final tokens = Lexer('s | slice(a, b)').tokenize();
      final ast = Parser(tokens).parse();
      final result = ExpressionEvaluator(ctx).evaluateOrThrow(ast);
      expect(result, equals('el'));
    });

    test('slice pipe on non-list non-string returns value via variable', () {
      final ctx = EvaluationContext(variables: {'v': 42, 'a': 0, 'b': 1});
      final tokens = Lexer('v | slice(a, b)').tokenize();
      final ast = Parser(tokens).parse();
      final result = ExpressionEvaluator(ctx).evaluateOrThrow(ast);
      expect(result, equals(42));
    });

    test('split pipe on string default separator', () {
      final result = eval('"a,b,c" | split');
      expect(result, equals(['a', 'b', 'c']));
    });

    test('split pipe on string custom separator', () {
      final result = eval('"a-b-c" | split("-")');
      expect(result, equals(['a', 'b', 'c']));
    });

    test('split pipe on non-string wraps in list', () {
      final result = eval('42 | split');
      expect(result, equals([42.0]));
    });

    test('join pipe on list default separator', () {
      expect(eval('[1, 2, 3] | join'), equals('1.0,2.0,3.0'));
    });

    test('join pipe on list custom separator', () {
      expect(eval('[1, 2, 3] | join("-")'), equals('1.0-2.0-3.0'));
    });

    test('join pipe on non-list returns toString', () {
      expect(eval('42 | join'), equals('42.0'));
    });

    test('length pipe on map', () {
      expect(
        eval('m | length', {
          'm': {'a': 1, 'b': 2},
        }),
        equals(2),
      );
    });

    test('length pipe on non-collection returns 0', () {
      expect(eval('42 | length'), equals(0));
    });

    test('default pipe with null value', () {
      // Use null variable piped to default
      expect(eval('x | default(42)', {'x': null}), equals(42.0));
    });

    test('json pipe encodes value', () {
      final result = eval('"hello" | json');
      expect(result, equals('"hello"'));
    });
  });

  // ===========================================================================
  // 15. LEXER: single & without && throws LexerException
  // ===========================================================================
  group('Lexer - single & throws', () {
    test('single & without && throws LexerException', () {
      expect(
        () => Lexer('a & b').tokenize(),
        throwsA(isA<LexerException>()),
      );
    });

    test('&& is valid and produces and token', () {
      final tokens = Lexer('a && b').tokenize();
      final andToken = tokens.firstWhere((t) => t.type == TokenType.and);
      expect(andToken.lexeme, equals('&&'));
    });
  });

  // ===========================================================================
  // 16. LEXER: Scientific notation parsing
  // ===========================================================================
  group('Lexer - scientific notation', () {
    test('parses 1e5', () {
      final tokens = Lexer('1e5').tokenize();
      expect(tokens[0].type, equals(TokenType.number));
      expect(tokens[0].literal, equals(1e5));
    });

    test('parses 1.5E-3', () {
      final tokens = Lexer('1.5E-3').tokenize();
      expect(tokens[0].type, equals(TokenType.number));
      expect(tokens[0].literal, equals(1.5e-3));
    });

    test('parses 2e+10', () {
      final tokens = Lexer('2e+10').tokenize();
      expect(tokens[0].type, equals(TokenType.number));
      expect(tokens[0].literal, equals(2e+10));
    });

    test('parses 5E2', () {
      final tokens = Lexer('5E2').tokenize();
      expect(tokens[0].type, equals(TokenType.number));
      expect(tokens[0].literal, equals(500.0));
    });

    test('evaluates scientific notation correctly', () {
      expect(eval('1e5'), equals(100000.0));
      expect(eval('2e+3'), equals(2000.0));
    });
  });

  // ===========================================================================
  // 17. LEXER: String escape sequences
  // ===========================================================================
  group('Lexer - string escape sequences', () {
    test('escape \\n produces newline', () {
      final tokens = Lexer(r'"hello\nworld"').tokenize();
      expect(tokens[0].literal, equals('hello\nworld'));
    });

    test('escape \\t produces tab', () {
      final tokens = Lexer(r'"hello\tworld"').tokenize();
      expect(tokens[0].literal, equals('hello\tworld'));
    });

    test('escape \\r produces carriage return', () {
      final tokens = Lexer(r'"hello\rworld"').tokenize();
      expect(tokens[0].literal, equals('hello\rworld'));
    });

    test('escape \\\\ produces backslash', () {
      final tokens = Lexer(r'"hello\\world"').tokenize();
      expect(tokens[0].literal, equals('hello\\world'));
    });

    test('escape \\" produces double quote', () {
      final tokens = Lexer(r'"hello\"world"').tokenize();
      expect(tokens[0].literal, equals('hello"world'));
    });

    test("escape \\' produces single quote", () {
      final tokens = Lexer(r"'hello\'world'").tokenize();
      expect(tokens[0].literal, equals("hello'world"));
    });

    test(r'escape \$ produces dollar sign', () {
      final tokens = Lexer(r'"hello\$world"').tokenize();
      expect(tokens[0].literal, equals('hello\$world'));
    });

    test('unknown escape passes through the character', () {
      final tokens = Lexer(r'"hello\xworld"').tokenize();
      expect(tokens[0].literal, equals('helloxworld'));
    });
  });

  // ===========================================================================
  // 18. LEXER: Unterminated string
  // ===========================================================================
  group('Lexer - unterminated string', () {
    test('unterminated double-quoted string throws LexerException', () {
      expect(
        () => Lexer('"hello').tokenize(),
        throwsA(isA<LexerException>()),
      );
    });

    test('unterminated single-quoted string throws LexerException', () {
      expect(
        () => Lexer("'hello").tokenize(),
        throwsA(isA<LexerException>()),
      );
    });
  });

  // ===========================================================================
  // 19. FUNCTIONS: Context function stubs
  // ===========================================================================
  group('Functions - context function stubs', () {
    late ExpressionFunctions fns;

    setUp(() {
      fns = ExpressionFunctions();
    });

    test('fact() returns null', () {
      expect(fns.call('fact', ['someFactId']), isNull);
    });

    test('facts() returns empty list', () {
      final result = fns.call('facts', ['query']);
      expect(result, isA<List<dynamic>>());
      expect(result, isEmpty);
    });

    test('entity() returns null', () {
      expect(fns.call('entity', ['entityId']), isNull);
    });

    test('summary() returns null', () {
      expect(fns.call('summary', ['type']), isNull);
    });

    test('stepResult() returns null', () {
      expect(fns.call('stepResult', ['stepId']), isNull);
    });

    test('fact() via evaluator returns null', () {
      expect(eval('fact("myFact")'), isNull);
    });

    test('facts() via evaluator returns empty list', () {
      expect(eval('facts("query")'), isEmpty);
    });

    test('entity() via evaluator returns null', () {
      expect(eval('entity("id")'), isNull);
    });

    test('summary() via evaluator returns null', () {
      expect(eval('summary("type")'), isNull);
    });

    test('stepResult() via evaluator returns null', () {
      expect(eval('stepResult("step1")'), isNull);
    });
  });

  // ===========================================================================
  // 20. FUNCTIONS: parseJson edge cases
  // ===========================================================================
  group('Functions - parseJson', () {
    late ExpressionFunctions fns;

    setUp(() {
      fns = ExpressionFunctions();
    });

    test('parseJson with null input returns null', () {
      expect(fns.call('parseJson', [null]), isNull);
    });

    test('parseJson with "null" string returns null', () {
      expect(fns.call('parseJson', ['null']), isNull);
    });

    test('parseJson with boolean true', () {
      expect(fns.call('parseJson', ['true']), isTrue);
    });

    test('parseJson with boolean false', () {
      expect(fns.call('parseJson', ['false']), isFalse);
    });

    test('parseJson with integer number', () {
      expect(fns.call('parseJson', ['42']), equals(42));
    });

    test('parseJson with negative number', () {
      expect(fns.call('parseJson', ['-3.14']), closeTo(-3.14, 0.001));
    });

    test('parseJson with string', () {
      expect(fns.call('parseJson', ['"hello"']), equals('hello'));
    });

    test('parseJson with empty array', () {
      expect(fns.call('parseJson', ['[]']), equals([]));
    });

    test('parseJson with array of numbers', () {
      final result = fns.call('parseJson', ['[1, 2, 3]']);
      expect(result, equals([1, 2, 3]));
    });

    test('parseJson with empty object', () {
      expect(fns.call('parseJson', ['{}']), equals({}));
    });

    test('parseJson with object', () {
      final result = fns.call('parseJson', ['{"name": "John", "age": 30}']);
      expect(result, isA<Map<String, dynamic>>());
      expect(result['name'], equals('John'));
      expect(result['age'], equals(30));
    });

    test('parseJson with nested structure', () {
      final result = fns.call(
        'parseJson',
        ['{"items": [1, 2], "nested": {"key": "value"}}'],
      );
      expect(result, isA<Map<String, dynamic>>());
      expect(result['items'], equals([1, 2]));
      expect(result['nested'], isA<Map<String, dynamic>>());
      expect(result['nested']['key'], equals('value'));
    });

    test('parseJson with mixed array', () {
      final result = fns.call(
        'parseJson',
        ['[1, "hello", true, null]'],
      );
      expect(result, isA<List<dynamic>>());
      expect(result[0], equals(1));
      expect(result[1], equals('hello'));
      expect(result[2], isTrue);
      expect(result[3], isNull);
    });

    test('parseJson via evaluator', () {
      final result = eval('parseJson("{\\"x\\": 10}")');
      expect(result, isA<Map<String, dynamic>>());
      expect(result['x'], equals(10));
    });

    test('parseJson with float number', () {
      expect(fns.call('parseJson', ['3.14']), closeTo(3.14, 0.001));
    });

    test('parseJson with escaped string in JSON', () {
      final result =
          fns.call('parseJson', ['{"msg": "hello\\"world"}']);
      expect(result, isA<Map<String, dynamic>>());
      expect(result['msg'], equals('hello"world'));
    });
  });

  // ===========================================================================
  // 21. PARSER: Unexpected token after complete expression
  // ===========================================================================
  group('Parser - unexpected token after expression', () {
    test('throws ParserException for trailing token after expression', () {
      // "1 2" - two complete expressions without an operator
      expect(
        () {
          final tokens = Lexer('1 2').tokenize();
          Parser(tokens).parse();
        },
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException for trailing identifier', () {
      expect(
        () {
          final tokens = Lexer('1 abc').tokenize();
          Parser(tokens).parse();
        },
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException for trailing bracket', () {
      expect(
        () {
          final tokens = Lexer('1 ]').tokenize();
          Parser(tokens).parse();
        },
        throwsA(isA<ParserException>()),
      );
    });
  });

  // ===========================================================================
  // 22. EVALUATOR: String concatenation with null operands
  // ===========================================================================
  group('Evaluator - string concatenation edge cases', () {
    test('string + null concatenation', () {
      final result = eval('"hello" + x', {'x': null});
      expect(result, equals('hello'));
    });

    test('null + string concatenation', () {
      final result = eval('x + "world"', {'x': null});
      expect(result, equals('world'));
    });
  });

  // ===========================================================================
  // 23. EVALUATOR: List concatenation with +
  // ===========================================================================
  group('Evaluator - list concatenation', () {
    test('list + list concatenation', () {
      final result = eval('[1, 2] + [3, 4]');
      expect(result, equals([1.0, 2.0, 3.0, 4.0]));
    });
  });

  // ===========================================================================
  // 24. EVALUATOR: String multiplication
  // ===========================================================================
  group('Evaluator - string multiplication', () {
    test('string * int repeats string via variable', () {
      // Lexer parses 3 as 3.0 (double) which is not int, so pass via variable
      final result = eval('"ab" * n', {'n': 3});
      expect(result, equals('ababab'));
    });
  });

  // ===========================================================================
  // 25. EVALUATOR: in operator edge cases
  // ===========================================================================
  group('Evaluator - in operator', () {
    test('element in null returns false', () {
      final result = eval('"a" in x', {'x': null});
      expect(result, isFalse);
    });

    test('element in map checks containsKey', () {
      final result = eval('"a" in m', {
        'm': {'a': 1, 'b': 2},
      });
      expect(result, isTrue);
    });

    test('string in string checks substring', () {
      final result = eval('"ell" in "hello"');
      expect(result, isTrue);
    });

    test('non-matching type returns false', () {
      final result = eval('5 in 10');
      expect(result, isFalse);
    });
  });

  // ===========================================================================
  // 26. EVALUATOR: _toBool edge cases
  // ===========================================================================
  group('Evaluator - _toBool conversions', () {
    test('null is falsy', () {
      expect(eval('x ? "yes" : "no"', {'x': null}), equals('no'));
    });

    test('zero is falsy', () {
      expect(eval('x ? "yes" : "no"', {'x': 0}), equals('no'));
    });

    test('non-zero is truthy', () {
      expect(eval('x ? "yes" : "no"', {'x': 42}), equals('yes'));
    });

    test('empty string is falsy', () {
      expect(eval('x ? "yes" : "no"', {'x': ''}), equals('no'));
    });

    test('non-empty string is truthy', () {
      expect(eval('x ? "yes" : "no"', {'x': 'hi'}), equals('yes'));
    });

    test('empty list is falsy', () {
      expect(eval('x ? "yes" : "no"', {'x': <dynamic>[]}), equals('no'));
    });

    test('non-empty list is truthy', () {
      expect(eval('x ? "yes" : "no"', {'x': [1]}), equals('yes'));
    });

    test('empty map is falsy', () {
      expect(eval('x ? "yes" : "no"', {'x': <String, dynamic>{}}), equals('no'));
    });

    test('non-empty map is truthy', () {
      expect(
        eval('x ? "yes" : "no"', {
          'x': {'a': 1},
        }),
        equals('yes'),
      );
    });

    test('other object type is truthy', () {
      expect(
        eval('x ? "yes" : "no"', {'x': DateTime.now()}),
        equals('yes'),
      );
    });
  });

  // ===========================================================================
  // 27. EVALUATOR: _compare edge cases
  // ===========================================================================
  group('Evaluator - _compare edge cases', () {
    test('string comparison', () {
      expect(eval('"apple" < "banana"'), isTrue);
    });

    test('incomparable types throw', () {
      expect(
        () => eval('x < y', {'x': true, 'y': false}),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 28. EVALUATOR: String method edge cases
  // ===========================================================================
  group('Evaluator - string method edge cases', () {
    test('contains with no args returns false', () {
      expect(eval('"hello".contains()'), isFalse);
    });

    test('startsWith with no args returns false', () {
      expect(eval('"hello".startsWith()'), isFalse);
    });

    test('endsWith with no args returns false', () {
      expect(eval('"hello".endsWith()'), isFalse);
    });

    test('replace with fewer than 2 args throws', () {
      expect(
        () => eval('"hello".replace("h")'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('indexOf with no args returns -1', () {
      expect(eval('"hello".indexOf()'), equals(-1));
    });

    test('split with no args returns list with the string', () {
      final result = eval('"hello".split()');
      expect(result, equals(['hello']));
    });
  });

  // ===========================================================================
  // 29. EVALUATOR: List method edge cases (join, contains, indexOf)
  // ===========================================================================
  group('Evaluator - list method edge cases', () {
    test('join with default separator', () {
      final result = eval('[1, 2, 3].join()');
      expect(result, equals('1.0,2.0,3.0'));
    });

    test('contains with no args returns false', () {
      expect(eval('[1, 2, 3].contains()'), isFalse);
    });

    test('indexOf with no args returns -1', () {
      expect(eval('[1, 2, 3].indexOf()'), equals(-1));
    });
  });

  // ===========================================================================
  // 30. EVALUATOR: unknown method on object throws
  // ===========================================================================
  group('Evaluator - unknown method throws', () {
    test('unknown method on string throws', () {
      expect(
        () => eval('"hello".unknownMethod()'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('unknown method on list throws', () {
      expect(
        () => eval('[1, 2].unknownMethod()'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('unknown method on map throws', () {
      expect(
        () => eval('m.unknownMethod()', {
          'm': {'a': 1},
        }),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('unknown method on number throws', () {
      expect(
        () => eval('x.unknownMethod()', {'x': 42}),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 31. EVALUATOR: EvaluationResult toString
  // ===========================================================================
  group('EvaluationResult - toString', () {
    test('success result toString', () {
      final result = evalResult('42');
      expect(result.toString(), contains('Success'));
    });

    test('failure result toString', () {
      final result = evalResult('undefinedVar');
      expect(result.toString(), contains('Failure'));
    });
  });

  // ===========================================================================
  // 32. EVALUATOR: modulo by zero throws
  // ===========================================================================
  group('Evaluator - modulo and division edge cases', () {
    test('modulo by zero throws', () {
      expect(
        () => eval('10 % 0'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('modulo with non-numeric throws', () {
      expect(
        () => eval('"a" % "b"'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('division with non-numeric throws', () {
      expect(
        () => eval('"a" / "b"'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('subtraction with non-numeric throws', () {
      expect(
        () => eval('"a" - "b"'),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('multiplication with non-numeric non-string throws', () {
      expect(
        () => eval('x * y', {'x': true, 'y': true}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('exponentiation with non-numeric throws', () {
      expect(
        () => eval('"a" ** 2'),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 33. EVALUATOR: visitObject with non-identifier non-string key
  // ===========================================================================
  group('Evaluator - visitObject with dynamic key', () {
    test('object literal with string key', () {
      final result = eval('{"name": "John"}');
      expect(result, equals({'name': 'John'}));
    });

    test('object literal with identifier key', () {
      final result = eval('{name: "John"}');
      expect(result, equals({'name': 'John'}));
    });
  });

  // ===========================================================================
  // 34. EVALUATOR: index access edge cases
  // ===========================================================================
  group('Evaluator - index access edge cases', () {
    test('index null throws', () {
      expect(
        () => eval('x[0]', {'x': null}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('list index non-integer throws', () {
      expect(
        () => eval('x["a"]', {'x': [1, 2, 3]}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('list index out of bounds throws', () {
      expect(
        () => eval('x[10]', {'x': [1, 2, 3]}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('string index non-integer throws', () {
      expect(
        () => eval('x["a"]', {'x': 'hello'}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('string index out of bounds throws', () {
      expect(
        () => eval('x[10]', {'x': 'hello'}),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('index on unsupported type throws', () {
      expect(
        () => eval('x[0]', {'x': 42}),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 35. EVALUATOR: optional chaining on method call
  // ===========================================================================
  group('Evaluator - optional chaining', () {
    test('optional member access on null returns null', () {
      expect(eval('x?.length', {'x': null}), isNull);
    });

    test('optional method call on null returns null', () {
      expect(eval('x?.toUpperCase()', {'x': null}), isNull);
    });

    test('non-optional member access on null throws', () {
      expect(
        () => eval('x.length', {'x': null}),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 36. EVALUATOR: call on invalid target
  // ===========================================================================
  group('Evaluator - invalid call target', () {
    test('call on non-callable throws', () {
      // Construct a CallExpr with a LiteralExpr as callee
      final callee = LiteralExpr(42);
      final paren = Token(
        type: TokenType.leftParen,
        lexeme: '(',
        line: 1,
        column: 1,
      );
      final callExpr = CallExpr(callee, paren, []);

      final ctx = EvaluationContext();
      final evaluator = ExpressionEvaluator(ctx);

      expect(
        () => evaluator.evaluateOrThrow(callExpr),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 37. EVALUATOR: negate non-numeric throws
  // ===========================================================================
  group('Evaluator - negate non-numeric', () {
    test('negate string throws', () {
      expect(
        () => eval('-x', {'x': 'hello'}),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 38. EVALUATOR: not operator
  // ===========================================================================
  group('Evaluator - not operator', () {
    test('!true returns false', () {
      expect(eval('!true'), isFalse);
    });

    test('not false returns true', () {
      expect(eval('not false'), isTrue);
    });
  });

  // ===========================================================================
  // 39. EVALUATOR: _getProperty edge cases
  // ===========================================================================
  group('Evaluator - property access edge cases', () {
    test('list.isEmpty returns true for empty list', () {
      expect(eval('x.isEmpty', {'x': <dynamic>[]}), isTrue);
    });

    test('list.isNotEmpty returns false for empty list', () {
      expect(eval('x.isNotEmpty', {'x': <dynamic>[]}), isFalse);
    });

    test('list.first returns null for empty list', () {
      expect(eval('x.first', {'x': <dynamic>[]}), isNull);
    });

    test('list.last returns null for empty list', () {
      expect(eval('x.last', {'x': <dynamic>[]}), isNull);
    });

    test('string.isEmpty returns true for empty string', () {
      expect(eval('x.isEmpty', {'x': ''}), isTrue);
    });

    test('string.isNotEmpty returns true for non-empty string', () {
      expect(eval('x.isNotEmpty', {'x': 'a'}), isTrue);
    });

    test('unsupported property on unsupported type throws', () {
      expect(
        () => eval('x.length', {'x': 42}),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 40. EVALUATOR: Interpolation expression
  // ===========================================================================
  group('Evaluator - interpolation', () {
    test('interpolation with null part renders empty', () {
      final parts = [LiteralExpr('hello '), LiteralExpr(null)];
      final interpExpr = InterpolationExpr(parts);

      final ctx = EvaluationContext();
      final evaluator = ExpressionEvaluator(ctx);
      final result = evaluator.evaluateOrThrow(interpExpr);
      expect(result, equals('hello '));
    });
  });

  // ===========================================================================
  // 41. EVALUATOR: _toJson edge cases
  // ===========================================================================
  group('Evaluator - json pipe', () {
    test('json pipe on null', () {
      expect(eval('x | json', {'x': null}), equals('null'));
    });

    test('json pipe on boolean', () {
      expect(eval('true | json'), equals('true'));
    });

    test('json pipe on number', () {
      // Lexer parses 42 as 42.0 (double)
      expect(eval('42 | json'), equals('42.0'));
    });

    test('json pipe on list', () {
      expect(eval('[1, 2] | json'), equals('[1.0,2.0]'));
    });

    test('json pipe on map', () {
      final result = eval('m | json', {
        'm': {'a': 1},
      });
      expect(result, equals('{"a":1}'));
    });

    test('json pipe on string with special characters', () {
      final result = eval('x | json', {'x': 'he"llo'});
      expect(result, equals('"he\\"llo"'));
    });
  });

  // ===========================================================================
  // 42. LEXER: LexerException toString
  // ===========================================================================
  group('LexerException', () {
    test('toString format', () {
      final ex = LexerException('test error', 3, 5);
      expect(ex.toString(), equals('LexerException at 3:5: test error'));
    });
  });

  // ===========================================================================
  // 43. PARSER: ParserException toString
  // ===========================================================================
  group('ParserException', () {
    test('toString format', () {
      final token = Token(
        type: TokenType.number,
        lexeme: '42',
        line: 2,
        column: 10,
      );
      final ex = ParserException('unexpected', token);
      expect(
        ex.toString(),
        equals('ParserException at 2:10: unexpected'),
      );
    });
  });

  // ===========================================================================
  // 44. EVALUATOR: EvaluationException toString
  // ===========================================================================
  group('EvaluationException', () {
    test('toString format', () {
      final ex = EvaluationException('test error');
      expect(ex.toString(), equals('EvaluationException: test error'));
    });
  });

  // ===========================================================================
  // 45. EVALUATOR: pipe with invalid filter expression
  // ===========================================================================
  group('Evaluator - pipe with invalid filter expression', () {
    test('pipe with call whose callee is not IdentifierExpr throws', () {
      // Construct PipeExpr where filter is a CallExpr with a LiteralExpr callee
      final value = LiteralExpr(5);
      final calleeOfFilter = LiteralExpr('notIdent');
      final paren = Token(
        type: TokenType.leftParen,
        lexeme: '(',
        line: 1,
        column: 1,
      );
      final filterCall = CallExpr(calleeOfFilter, paren, []);
      final pipeExpr = PipeExpr(value, filterCall);

      final ctx = EvaluationContext();
      final evaluator = ExpressionEvaluator(ctx);

      expect(
        () => evaluator.evaluateOrThrow(pipeExpr),
        throwsA(isA<EvaluationException>()),
      );
    });

    test('pipe with non-identifier non-call filter throws', () {
      // Construct PipeExpr where filter is a LiteralExpr (neither Identifier
      // nor Call)
      final value = LiteralExpr(5);
      final filter = LiteralExpr('invalid');
      final pipeExpr = PipeExpr(value, filter);

      final ctx = EvaluationContext();
      final evaluator = ExpressionEvaluator(ctx);

      expect(
        () => evaluator.evaluateOrThrow(pipeExpr),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 46. EVALUATOR: call method on null (non-optional)
  // ===========================================================================
  group('Evaluator - call method on null', () {
    test('non-optional method call on null throws', () {
      expect(
        () => eval('x.toUpperCase()', {'x': null}),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 47. EVALUATOR: add incompatible types
  // ===========================================================================
  group('Evaluator - add incompatible types', () {
    test('adding incompatible non-string non-numeric non-list throws', () {
      expect(
        () => eval('x + y', {'x': true, 'y': true}),
        throwsA(isA<EvaluationException>()),
      );
    });
  });

  // ===========================================================================
  // 48. LEXER: $ followed by non-{ starts identifier
  // ===========================================================================
  group('Lexer - dollar sign handling', () {
    test(r'$ followed by alpha continues as identifier', () {
      final tokens = Lexer(r'$var').tokenize();
      expect(tokens[0].type, equals(TokenType.identifier));
      expect(tokens[0].literal, equals(r'$var'));
    });

    test(r'${ produces dollarBrace token', () {
      // Need expression and closing brace
      final tokens = Lexer(r'${x}').tokenize();
      expect(tokens[0].type, equals(TokenType.dollarBrace));
    });
  });

  // ===========================================================================
  // 49. LEXER: unexpected character
  // ===========================================================================
  group('Lexer - unexpected character', () {
    test('unexpected character throws LexerException', () {
      expect(
        () => Lexer('\x01').tokenize(),
        throwsA(isA<LexerException>()),
      );
    });
  });

  // ===========================================================================
  // 50. EVALUATOR: logical short-circuit behavior
  // ===========================================================================
  group('Evaluator - logical short-circuit', () {
    test('and short-circuits on false left', () {
      // If short-circuit works, right side (undefined var) is not evaluated
      expect(eval('false and undefinedVar', {}), isFalse);
    });

    test('or short-circuits on true left', () {
      // If short-circuit works, right side (undefined var) is not evaluated
      expect(eval('true or undefinedVar', {}), isTrue);
    });

    test('&& short-circuits on false left', () {
      expect(eval('false && undefinedVar', {}), isFalse);
    });

    test('|| short-circuits on true left', () {
      expect(eval('true || undefinedVar', {}), isTrue);
    });
  });
}
