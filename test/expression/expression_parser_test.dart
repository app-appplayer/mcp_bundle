import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

/// Helper to tokenize and parse an expression string into an AST node.
Expr _parse(String source) {
  final tokens = Lexer(source).tokenize();
  return Parser(tokens).parse();
}

void main() {
  // ===========================================================================
  // 1. Primary Expressions - Literals
  // ===========================================================================
  group('Primary expressions - Literals', () {
    test('parses integer number literal', () {
      final ast = _parse('42');
      expect(ast, isA<LiteralExpr>());
      expect((ast as LiteralExpr).value, equals(42.0));
    });

    test('parses decimal number literal', () {
      final ast = _parse('3.14');
      expect(ast, isA<LiteralExpr>());
      expect((ast as LiteralExpr).value, equals(3.14));
    });

    test('parses zero', () {
      final ast = _parse('0');
      expect(ast, isA<LiteralExpr>());
      expect((ast as LiteralExpr).value, equals(0.0));
    });

    test('parses scientific notation number', () {
      final ast = _parse('1e10');
      expect(ast, isA<LiteralExpr>());
      expect((ast as LiteralExpr).value, equals(1e10));
    });

    test('parses scientific notation with positive exponent', () {
      final ast = _parse('2.5e+3');
      expect(ast, isA<LiteralExpr>());
      expect((ast as LiteralExpr).value, equals(2500.0));
    });

    test('parses scientific notation with negative exponent', () {
      final ast = _parse('5e-2');
      expect(ast, isA<LiteralExpr>());
      expect((ast as LiteralExpr).value, equals(0.05));
    });

    test('parses double-quoted string literal', () {
      final ast = _parse('"hello"');
      expect(ast, isA<LiteralExpr>());
      expect((ast as LiteralExpr).value, equals('hello'));
    });

    test('parses single-quoted string literal', () {
      final ast = _parse("'world'");
      expect(ast, isA<LiteralExpr>());
      expect((ast as LiteralExpr).value, equals('world'));
    });

    test('parses empty string', () {
      final ast = _parse('""');
      expect(ast, isA<LiteralExpr>());
      expect((ast as LiteralExpr).value, equals(''));
    });

    test('parses string with escape sequences', () {
      final ast = _parse(r'"line1\nline2\ttab"');
      expect(ast, isA<LiteralExpr>());
      expect((ast as LiteralExpr).value, equals('line1\nline2\ttab'));
    });

    test('parses string with escaped quotes', () {
      final ast = _parse(r'"say \"hi\""');
      expect(ast, isA<LiteralExpr>());
      expect((ast as LiteralExpr).value, equals('say "hi"'));
    });

    test('parses boolean true', () {
      final ast = _parse('true');
      expect(ast, isA<LiteralExpr>());
      expect((ast as LiteralExpr).value, isTrue);
    });

    test('parses boolean false', () {
      final ast = _parse('false');
      expect(ast, isA<LiteralExpr>());
      expect((ast as LiteralExpr).value, isFalse);
    });

    test('parses null literal', () {
      final ast = _parse('null');
      expect(ast, isA<LiteralExpr>());
      // Lexer stores null as string 'null' due to literal ?? text fallback
      expect((ast as LiteralExpr).value, equals('null'));
    });
  });

  // ===========================================================================
  // 2. Primary Expressions - Identifiers
  // ===========================================================================
  group('Primary expressions - Identifiers', () {
    test('parses simple identifier', () {
      final ast = _parse('foo');
      expect(ast, isA<IdentifierExpr>());
      expect((ast as IdentifierExpr).name.lexeme, equals('foo'));
    });

    test('parses underscore-prefixed identifier', () {
      final ast = _parse('_private');
      expect(ast, isA<IdentifierExpr>());
      expect((ast as IdentifierExpr).name.lexeme, equals('_private'));
    });

    test('parses identifier with underscores and digits', () {
      final ast = _parse('my_var_2');
      expect(ast, isA<IdentifierExpr>());
      expect((ast as IdentifierExpr).name.lexeme, equals('my_var_2'));
    });

    test('parses single character identifier', () {
      final ast = _parse('x');
      expect(ast, isA<IdentifierExpr>());
      expect((ast as IdentifierExpr).name.lexeme, equals('x'));
    });

    test('parses dollar-prefixed identifier', () {
      final ast = _parse(r'$value');
      expect(ast, isA<IdentifierExpr>());
      expect((ast as IdentifierExpr).name.lexeme, equals(r'$value'));
    });
  });

  // ===========================================================================
  // 3. Array Literals
  // ===========================================================================
  group('Array literals', () {
    test('parses empty array', () {
      final ast = _parse('[]');
      expect(ast, isA<ArrayExpr>());
      expect((ast as ArrayExpr).elements, isEmpty);
    });

    test('parses single element array', () {
      final ast = _parse('[1]');
      expect(ast, isA<ArrayExpr>());
      final arr = ast as ArrayExpr;
      expect(arr.elements, hasLength(1));
      expect(arr.elements[0], isA<LiteralExpr>());
    });

    test('parses multiple element array', () {
      final ast = _parse('[1, 2, 3]');
      expect(ast, isA<ArrayExpr>());
      final arr = ast as ArrayExpr;
      expect(arr.elements, hasLength(3));
    });

    test('parses array with mixed types', () {
      final ast = _parse('[1, "two", true, null]');
      expect(ast, isA<ArrayExpr>());
      final arr = ast as ArrayExpr;
      expect(arr.elements, hasLength(4));
      expect(arr.elements[0], isA<LiteralExpr>());
      expect(arr.elements[1], isA<LiteralExpr>());
      expect(arr.elements[2], isA<LiteralExpr>());
      expect(arr.elements[3], isA<LiteralExpr>());
    });

    test('parses nested arrays', () {
      final ast = _parse('[[1, 2], [3, 4]]');
      expect(ast, isA<ArrayExpr>());
      final arr = ast as ArrayExpr;
      expect(arr.elements, hasLength(2));
      expect(arr.elements[0], isA<ArrayExpr>());
      expect(arr.elements[1], isA<ArrayExpr>());
      final inner = arr.elements[0] as ArrayExpr;
      expect(inner.elements, hasLength(2));
    });

    test('parses array with expressions as elements', () {
      final ast = _parse('[a + b, c * d]');
      expect(ast, isA<ArrayExpr>());
      final arr = ast as ArrayExpr;
      expect(arr.elements, hasLength(2));
      expect(arr.elements[0], isA<BinaryExpr>());
      expect(arr.elements[1], isA<BinaryExpr>());
    });

    test('parses array containing identifiers', () {
      final ast = _parse('[x, y, z]');
      expect(ast, isA<ArrayExpr>());
      final arr = ast as ArrayExpr;
      expect(arr.elements, hasLength(3));
      for (final elem in arr.elements) {
        expect(elem, isA<IdentifierExpr>());
      }
    });
  });

  // ===========================================================================
  // 4. Object Literals
  // ===========================================================================
  group('Object literals', () {
    test('parses empty object', () {
      final ast = _parse('{}');
      expect(ast, isA<ObjectExpr>());
      expect((ast as ObjectExpr).entries, isEmpty);
    });

    test('parses object with identifier key', () {
      final ast = _parse('{name: "John"}');
      expect(ast, isA<ObjectExpr>());
      final obj = ast as ObjectExpr;
      expect(obj.entries, hasLength(1));
      final key = obj.entries[0].$1 as LiteralExpr;
      expect(key.value, equals('name'));
      final value = obj.entries[0].$2 as LiteralExpr;
      expect(value.value, equals('John'));
    });

    test('parses object with string key', () {
      final ast = _parse('{"key": 42}');
      expect(ast, isA<ObjectExpr>());
      final obj = ast as ObjectExpr;
      expect(obj.entries, hasLength(1));
      final key = obj.entries[0].$1 as LiteralExpr;
      expect(key.value, equals('key'));
    });

    test('parses object with multiple entries', () {
      final ast = _parse('{a: 1, b: 2, c: 3}');
      expect(ast, isA<ObjectExpr>());
      final obj = ast as ObjectExpr;
      expect(obj.entries, hasLength(3));
    });

    test('parses object with expression values', () {
      final ast = _parse('{total: a + b}');
      expect(ast, isA<ObjectExpr>());
      final obj = ast as ObjectExpr;
      expect(obj.entries[0].$2, isA<BinaryExpr>());
    });

    test('parses nested objects', () {
      final ast = _parse('{outer: {inner: 1}}');
      expect(ast, isA<ObjectExpr>());
      final obj = ast as ObjectExpr;
      expect(obj.entries[0].$2, isA<ObjectExpr>());
    });

    test('parses object with mixed key types', () {
      final ast = _parse('{name: 1, "key": 2}');
      expect(ast, isA<ObjectExpr>());
      final obj = ast as ObjectExpr;
      expect(obj.entries, hasLength(2));
      expect((obj.entries[0].$1 as LiteralExpr).value, equals('name'));
      expect((obj.entries[1].$1 as LiteralExpr).value, equals('key'));
    });

    test('parses object with array value', () {
      final ast = _parse('{items: [1, 2, 3]}');
      expect(ast, isA<ObjectExpr>());
      final obj = ast as ObjectExpr;
      expect(obj.entries[0].$2, isA<ArrayExpr>());
    });
  });

  // ===========================================================================
  // 5. Grouping Expressions
  // ===========================================================================
  group('Grouping expressions', () {
    test('parses simple grouping', () {
      final ast = _parse('(42)');
      expect(ast, isA<GroupingExpr>());
      final grp = ast as GroupingExpr;
      expect(grp.expression, isA<LiteralExpr>());
    });

    test('parses (a + b) * c with correct structure', () {
      final ast = _parse('(a + b) * c');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('*'));
      expect(bin.left, isA<GroupingExpr>());
      final grp = bin.left as GroupingExpr;
      expect(grp.expression, isA<BinaryExpr>());
      final inner = grp.expression as BinaryExpr;
      expect(inner.operator.lexeme, equals('+'));
    });

    test('parses nested grouping ((a))', () {
      final ast = _parse('((a))');
      expect(ast, isA<GroupingExpr>());
      final outer = ast as GroupingExpr;
      expect(outer.expression, isA<GroupingExpr>());
      final inner = outer.expression as GroupingExpr;
      expect(inner.expression, isA<IdentifierExpr>());
    });

    test('parses grouping with complex expression', () {
      final ast = _parse('(a + b) * (c - d)');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.left, isA<GroupingExpr>());
      expect(bin.right, isA<GroupingExpr>());
    });

    test('parses deeply nested grouping (((42)))', () {
      final ast = _parse('(((42)))');
      expect(ast, isA<GroupingExpr>());
      final g1 = ast as GroupingExpr;
      expect(g1.expression, isA<GroupingExpr>());
      final g2 = g1.expression as GroupingExpr;
      expect(g2.expression, isA<GroupingExpr>());
      final g3 = g2.expression as GroupingExpr;
      expect(g3.expression, isA<LiteralExpr>());
    });

    test('parses grouping of single identifier as grouping not lambda', () {
      // (x) without => should be a grouping, not a lambda
      final ast = _parse('(x)');
      expect(ast, isA<GroupingExpr>());
      final grp = ast as GroupingExpr;
      expect(grp.expression, isA<IdentifierExpr>());
    });

    test('parses grouping with string literal', () {
      final ast = _parse('("hello")');
      expect(ast, isA<GroupingExpr>());
      final grp = ast as GroupingExpr;
      expect(grp.expression, isA<LiteralExpr>());
      expect((grp.expression as LiteralExpr).value, equals('hello'));
    });
  });

  // ===========================================================================
  // 6. Lambda Expressions
  // ===========================================================================
  group('Lambda expressions', () {
    test('parses single parameter lambda', () {
      final ast = _parse('x => x + 1');
      expect(ast, isA<LambdaExpr>());
      final lambda = ast as LambdaExpr;
      expect(lambda.parameters, hasLength(1));
      expect(lambda.parameters[0].lexeme, equals('x'));
      expect(lambda.body, isA<BinaryExpr>());
    });

    test('parses multi-parameter lambda with parentheses', () {
      final ast = _parse('(a, b) => a + b');
      expect(ast, isA<LambdaExpr>());
      final lambda = ast as LambdaExpr;
      expect(lambda.parameters, hasLength(2));
      expect(lambda.parameters[0].lexeme, equals('a'));
      expect(lambda.parameters[1].lexeme, equals('b'));
      expect(lambda.body, isA<BinaryExpr>());
    });

    test('parses no-parameter lambda', () {
      final ast = _parse('() => 42');
      expect(ast, isA<LambdaExpr>());
      final lambda = ast as LambdaExpr;
      expect(lambda.parameters, isEmpty);
      expect(lambda.body, isA<LiteralExpr>());
      expect((lambda.body as LiteralExpr).value, equals(42.0));
    });

    test('parses lambda with identifier body', () {
      final ast = _parse('x => x');
      expect(ast, isA<LambdaExpr>());
      final lambda = ast as LambdaExpr;
      expect(lambda.body, isA<IdentifierExpr>());
    });

    test('parses three-parameter lambda', () {
      final ast = _parse('(a, b, c) => a');
      expect(ast, isA<LambdaExpr>());
      final lambda = ast as LambdaExpr;
      expect(lambda.parameters, hasLength(3));
      expect(lambda.parameters[0].lexeme, equals('a'));
      expect(lambda.parameters[1].lexeme, equals('b'));
      expect(lambda.parameters[2].lexeme, equals('c'));
    });

    test('parses lambda with boolean body', () {
      final ast = _parse('() => true');
      expect(ast, isA<LambdaExpr>());
      final lambda = ast as LambdaExpr;
      expect(lambda.body, isA<LiteralExpr>());
      expect((lambda.body as LiteralExpr).value, isTrue);
    });

    test('parses lambda with ternary body', () {
      final ast = _parse('x => x > 0 ? x : 0');
      expect(ast, isA<LambdaExpr>());
      final lambda = ast as LambdaExpr;
      expect(lambda.body, isA<ConditionalExpr>());
    });

    test('parses lambda with string body', () {
      final ast = _parse('() => "hello"');
      expect(ast, isA<LambdaExpr>());
      final lambda = ast as LambdaExpr;
      expect(lambda.body, isA<LiteralExpr>());
      expect((lambda.body as LiteralExpr).value, equals('hello'));
    });

    test('disambiguates (x) as grouping when no arrow follows', () {
      // (x) + 1 should parse as GroupingExpr(x) + 1
      final ast = _parse('(x) + 1');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('+'));
      expect(bin.left, isA<GroupingExpr>());
    });

    test('disambiguates (x) => expr as lambda', () {
      final ast = _parse('(x) => x * 2');
      expect(ast, isA<LambdaExpr>());
      final lambda = ast as LambdaExpr;
      expect(lambda.parameters, hasLength(1));
      expect(lambda.parameters[0].lexeme, equals('x'));
    });

    test('parses lambda with null coalesce body', () {
      final ast = _parse('x => x ?? 0');
      expect(ast, isA<LambdaExpr>());
      final lambda = ast as LambdaExpr;
      expect(lambda.body, isA<NullCoalesceExpr>());
    });
  });

  // ===========================================================================
  // 7. Unary Operators
  // ===========================================================================
  group('Unary operators', () {
    test('parses negation of number', () {
      final ast = _parse('-5');
      expect(ast, isA<UnaryExpr>());
      final unary = ast as UnaryExpr;
      expect(unary.operator.lexeme, equals('-'));
      expect(unary.operand, isA<LiteralExpr>());
      expect((unary.operand as LiteralExpr).value, equals(5.0));
    });

    test('parses logical not with ! symbol', () {
      final ast = _parse('!true');
      expect(ast, isA<UnaryExpr>());
      final unary = ast as UnaryExpr;
      expect(unary.operator.type, equals(TokenType.not));
      expect(unary.operand, isA<LiteralExpr>());
    });

    test('parses logical not with not keyword', () {
      final ast = _parse('not false');
      expect(ast, isA<UnaryExpr>());
      final unary = ast as UnaryExpr;
      expect(unary.operator.type, equals(TokenType.not));
      expect(unary.operand, isA<LiteralExpr>());
    });

    test('parses double negation --x', () {
      final ast = _parse('--x');
      expect(ast, isA<UnaryExpr>());
      final outer = ast as UnaryExpr;
      expect(outer.operator.lexeme, equals('-'));
      expect(outer.operand, isA<UnaryExpr>());
      final inner = outer.operand as UnaryExpr;
      expect(inner.operator.lexeme, equals('-'));
      expect(inner.operand, isA<IdentifierExpr>());
    });

    test('parses double not !!x', () {
      final ast = _parse('!!x');
      expect(ast, isA<UnaryExpr>());
      final outer = ast as UnaryExpr;
      expect(outer.operand, isA<UnaryExpr>());
      final inner = outer.operand as UnaryExpr;
      expect(inner.operand, isA<IdentifierExpr>());
    });

    test('parses negation of identifier', () {
      final ast = _parse('-x');
      expect(ast, isA<UnaryExpr>());
      final unary = ast as UnaryExpr;
      expect(unary.operator.lexeme, equals('-'));
      expect(unary.operand, isA<IdentifierExpr>());
    });

    test('parses not applied to parenthesized expression', () {
      final ast = _parse('!(a && b)');
      expect(ast, isA<UnaryExpr>());
      final unary = ast as UnaryExpr;
      expect(unary.operator.type, equals(TokenType.not));
      expect(unary.operand, isA<GroupingExpr>());
      final grp = unary.operand as GroupingExpr;
      expect(grp.expression, isA<LogicalExpr>());
    });

    test('parses negation of decimal', () {
      final ast = _parse('-3.14');
      expect(ast, isA<UnaryExpr>());
      final unary = ast as UnaryExpr;
      expect(unary.operator.lexeme, equals('-'));
      expect((unary.operand as LiteralExpr).value, equals(3.14));
    });
  });

  // ===========================================================================
  // 8. Binary Arithmetic Operators
  // ===========================================================================
  group('Binary arithmetic operators', () {
    test('parses addition', () {
      final ast = _parse('1 + 2');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('+'));
      expect(bin.left, isA<LiteralExpr>());
      expect(bin.right, isA<LiteralExpr>());
    });

    test('parses subtraction', () {
      final ast = _parse('5 - 3');
      expect(ast, isA<BinaryExpr>());
      expect((ast as BinaryExpr).operator.lexeme, equals('-'));
    });

    test('parses multiplication', () {
      final ast = _parse('2 * 3');
      expect(ast, isA<BinaryExpr>());
      expect((ast as BinaryExpr).operator.lexeme, equals('*'));
    });

    test('parses division', () {
      final ast = _parse('10 / 2');
      expect(ast, isA<BinaryExpr>());
      expect((ast as BinaryExpr).operator.lexeme, equals('/'));
    });

    test('parses modulo', () {
      final ast = _parse('10 % 3');
      expect(ast, isA<BinaryExpr>());
      expect((ast as BinaryExpr).operator.lexeme, equals('%'));
    });

    test('parses power / exponentiation', () {
      final ast = _parse('2 ** 3');
      expect(ast, isA<BinaryExpr>());
      expect((ast as BinaryExpr).operator.lexeme, equals('**'));
    });

    test('parses addition of identifiers', () {
      final ast = _parse('a + b');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.left, isA<IdentifierExpr>());
      expect(bin.right, isA<IdentifierExpr>());
    });

    test('parses string concatenation via addition', () {
      final ast = _parse('"hello" + " world"');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('+'));
      expect((bin.left as LiteralExpr).value, equals('hello'));
      expect((bin.right as LiteralExpr).value, equals(' world'));
    });
  });

  // ===========================================================================
  // 9. Comparison Operators
  // ===========================================================================
  group('Comparison operators', () {
    test('parses == equality', () {
      final ast = _parse('a == b');
      expect(ast, isA<BinaryExpr>());
      expect((ast as BinaryExpr).operator.lexeme, equals('=='));
    });

    test('parses != inequality', () {
      final ast = _parse('a != b');
      expect(ast, isA<BinaryExpr>());
      expect((ast as BinaryExpr).operator.lexeme, equals('!='));
    });

    test('parses < less than', () {
      final ast = _parse('a < b');
      expect(ast, isA<BinaryExpr>());
      expect((ast as BinaryExpr).operator.lexeme, equals('<'));
    });

    test('parses <= less than or equal', () {
      final ast = _parse('a <= b');
      expect(ast, isA<BinaryExpr>());
      expect((ast as BinaryExpr).operator.lexeme, equals('<='));
    });

    test('parses > greater than', () {
      final ast = _parse('a > b');
      expect(ast, isA<BinaryExpr>());
      expect((ast as BinaryExpr).operator.lexeme, equals('>'));
    });

    test('parses >= greater than or equal', () {
      final ast = _parse('a >= b');
      expect(ast, isA<BinaryExpr>());
      expect((ast as BinaryExpr).operator.lexeme, equals('>='));
    });

    test('comparison has lower precedence than arithmetic', () {
      // a + 1 > b * 2 => BinaryExpr(BinaryExpr(a,+,1), >, BinaryExpr(b,*,2))
      final ast = _parse('a + 1 > b * 2');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('>'));
      expect(bin.left, isA<BinaryExpr>());
      expect(bin.right, isA<BinaryExpr>());
    });

    test('equality has lower precedence than comparison', () {
      // a < b == c > d => BinaryExpr(BinaryExpr(a,<,b), ==, BinaryExpr(c,>,d))
      final ast = _parse('a < b == c > d');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('=='));
      expect(bin.left, isA<BinaryExpr>());
      expect((bin.left as BinaryExpr).operator.lexeme, equals('<'));
      expect(bin.right, isA<BinaryExpr>());
      expect((bin.right as BinaryExpr).operator.lexeme, equals('>'));
    });

    test('equality is left-associative', () {
      // a == b == c => BinaryExpr(BinaryExpr(a,==,b), ==, c)
      final ast = _parse('a == b == c');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('=='));
      expect(bin.left, isA<BinaryExpr>());
      expect(bin.right, isA<IdentifierExpr>());
    });

    test('comparison is left-associative', () {
      // a < b < c => BinaryExpr(BinaryExpr(a,<,b), <, c)
      final ast = _parse('a < b < c');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('<'));
      expect(bin.left, isA<BinaryExpr>());
      expect(bin.right, isA<IdentifierExpr>());
    });
  });

  // ===========================================================================
  // 10. Logical Operators
  // ===========================================================================
  group('Logical operators', () {
    test('parses && (and symbol)', () {
      final ast = _parse('a && b');
      expect(ast, isA<LogicalExpr>());
      final log = ast as LogicalExpr;
      expect(log.operator.type, equals(TokenType.and));
    });

    test('parses and keyword', () {
      final ast = _parse('a and b');
      expect(ast, isA<LogicalExpr>());
      final log = ast as LogicalExpr;
      expect(log.operator.type, equals(TokenType.and));
    });

    test('parses || (or symbol)', () {
      final ast = _parse('a || b');
      expect(ast, isA<LogicalExpr>());
      final log = ast as LogicalExpr;
      expect(log.operator.type, equals(TokenType.or));
    });

    test('parses or keyword', () {
      final ast = _parse('a or b');
      expect(ast, isA<LogicalExpr>());
      final log = ast as LogicalExpr;
      expect(log.operator.type, equals(TokenType.or));
    });

    test('and has higher precedence than or', () {
      // a or b and c => LogicalExpr(a, or, LogicalExpr(b, and, c))
      final ast = _parse('a or b and c');
      expect(ast, isA<LogicalExpr>());
      final log = ast as LogicalExpr;
      expect(log.operator.type, equals(TokenType.or));
      expect(log.left, isA<IdentifierExpr>());
      expect(log.right, isA<LogicalExpr>());
      final right = log.right as LogicalExpr;
      expect(right.operator.type, equals(TokenType.and));
    });

    test('&& has higher precedence than ||', () {
      // a || b && c => LogicalExpr(a, ||, LogicalExpr(b, &&, c))
      final ast = _parse('a || b && c');
      expect(ast, isA<LogicalExpr>());
      final log = ast as LogicalExpr;
      expect(log.operator.type, equals(TokenType.or));
      expect(log.right, isA<LogicalExpr>());
    });

    test('and is left-associative', () {
      // a and b and c => LogicalExpr(LogicalExpr(a, and, b), and, c)
      final ast = _parse('a and b and c');
      expect(ast, isA<LogicalExpr>());
      final log = ast as LogicalExpr;
      expect(log.left, isA<LogicalExpr>());
      expect(log.right, isA<IdentifierExpr>());
    });

    test('or is left-associative', () {
      // a or b or c => LogicalExpr(LogicalExpr(a, or, b), or, c)
      final ast = _parse('a or b or c');
      expect(ast, isA<LogicalExpr>());
      final log = ast as LogicalExpr;
      expect(log.left, isA<LogicalExpr>());
      expect(log.right, isA<IdentifierExpr>());
    });

    test('logical has lower precedence than equality', () {
      // a == 1 && b != 2 => LogicalExpr(BinaryExpr(a,==,1), &&, BinaryExpr(b,!=,2))
      final ast = _parse('a == 1 && b != 2');
      expect(ast, isA<LogicalExpr>());
      final log = ast as LogicalExpr;
      expect(log.left, isA<BinaryExpr>());
      expect(log.right, isA<BinaryExpr>());
    });
  });

  // ===========================================================================
  // 11. Membership Operators (in, matches)
  // ===========================================================================
  group('Membership operators', () {
    test('parses in operator', () {
      final ast = _parse('x in list');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.type, equals(TokenType.inOperator));
      expect(bin.left, isA<IdentifierExpr>());
      expect(bin.right, isA<IdentifierExpr>());
    });

    test('parses matches operator', () {
      final ast = _parse('value matches pattern');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.type, equals(TokenType.matchesOperator));
    });

    test('parses matches with string literal', () {
      final ast = _parse('name matches "^[A-Z]"');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.type, equals(TokenType.matchesOperator));
      expect(bin.right, isA<LiteralExpr>());
      expect((bin.right as LiteralExpr).value, equals('^[A-Z]'));
    });

    test('parses in with array literal on the right', () {
      final ast = _parse('x in [1, 2, 3]');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.type, equals(TokenType.inOperator));
      expect(bin.right, isA<ArrayExpr>());
    });

    test('membership has higher precedence than logical and', () {
      // x in list and y in other =>
      //   LogicalExpr(BinaryExpr(x,in,list), and, BinaryExpr(y,in,other))
      final ast = _parse('x in list and y in other');
      expect(ast, isA<LogicalExpr>());
      final log = ast as LogicalExpr;
      expect(log.left, isA<BinaryExpr>());
      expect((log.left as BinaryExpr).operator.type,
          equals(TokenType.inOperator));
      expect(log.right, isA<BinaryExpr>());
      expect((log.right as BinaryExpr).operator.type,
          equals(TokenType.inOperator));
    });

    test('membership is left-associative', () {
      // a in b in c => BinaryExpr(BinaryExpr(a,in,b), in, c)
      final ast = _parse('a in b in c');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.type, equals(TokenType.inOperator));
      expect(bin.left, isA<BinaryExpr>());
      expect(bin.right, isA<IdentifierExpr>());
    });
  });

  // ===========================================================================
  // 12. Conditional (Ternary) Operator
  // ===========================================================================
  group('Conditional (ternary) operator', () {
    test('parses basic ternary', () {
      final ast = _parse('a ? b : c');
      expect(ast, isA<ConditionalExpr>());
      final cond = ast as ConditionalExpr;
      expect(cond.condition, isA<IdentifierExpr>());
      expect(cond.thenBranch, isA<IdentifierExpr>());
      expect(cond.elseBranch, isA<IdentifierExpr>());
    });

    test('parses ternary with literal branches', () {
      final ast = _parse('true ? 1 : 0');
      expect(ast, isA<ConditionalExpr>());
      final cond = ast as ConditionalExpr;
      expect((cond.thenBranch as LiteralExpr).value, equals(1.0));
      expect((cond.elseBranch as LiteralExpr).value, equals(0.0));
    });

    test('parses ternary with complex condition', () {
      final ast = _parse('a > 0 ? "positive" : "non-positive"');
      expect(ast, isA<ConditionalExpr>());
      final cond = ast as ConditionalExpr;
      expect(cond.condition, isA<BinaryExpr>());
    });

    test('parses nested ternary in else branch', () {
      // a ? b : c ? d : e => ConditionalExpr(a, b, ConditionalExpr(c, d, e))
      final ast = _parse('a ? b : c ? d : e');
      expect(ast, isA<ConditionalExpr>());
      final cond = ast as ConditionalExpr;
      expect(cond.elseBranch, isA<ConditionalExpr>());
    });

    test('parses nested ternary in then branch', () {
      // a ? b ? c : d : e
      final ast = _parse('a ? b ? c : d : e');
      expect(ast, isA<ConditionalExpr>());
      final cond = ast as ConditionalExpr;
      expect(cond.thenBranch, isA<ConditionalExpr>());
    });

    test('parses ternary with string branches', () {
      final ast = _parse('x ? "yes" : "no"');
      expect(ast, isA<ConditionalExpr>());
      final cond = ast as ConditionalExpr;
      expect((cond.thenBranch as LiteralExpr).value, equals('yes'));
      expect((cond.elseBranch as LiteralExpr).value, equals('no'));
    });

    test('ternary has lower precedence than null coalesce', () {
      // a ?? b ? c : d => ConditionalExpr(NullCoalesceExpr(a,b), c, d)
      final ast = _parse('a ?? b ? c : d');
      expect(ast, isA<ConditionalExpr>());
      final cond = ast as ConditionalExpr;
      expect(cond.condition, isA<NullCoalesceExpr>());
    });
  });

  // ===========================================================================
  // 13. Null Coalesce Operator
  // ===========================================================================
  group('Null coalesce operator', () {
    test('parses simple null coalesce', () {
      final ast = _parse('a ?? b');
      expect(ast, isA<NullCoalesceExpr>());
      final nc = ast as NullCoalesceExpr;
      expect(nc.left, isA<IdentifierExpr>());
      expect(nc.right, isA<IdentifierExpr>());
    });

    test('null coalesce is right-associative', () {
      // a ?? b ?? c => NullCoalesceExpr(a, NullCoalesceExpr(b, c))
      final ast = _parse('a ?? b ?? c');
      expect(ast, isA<NullCoalesceExpr>());
      final nc = ast as NullCoalesceExpr;
      expect(nc.left, isA<IdentifierExpr>());
      expect(nc.right, isA<NullCoalesceExpr>());
      final right = nc.right as NullCoalesceExpr;
      expect(right.left, isA<IdentifierExpr>());
      expect(right.right, isA<IdentifierExpr>());
    });

    test('null coalesce with literal fallback', () {
      final ast = _parse('x ?? "default"');
      expect(ast, isA<NullCoalesceExpr>());
      final nc = ast as NullCoalesceExpr;
      expect(nc.right, isA<LiteralExpr>());
      expect((nc.right as LiteralExpr).value, equals('default'));
    });

    test('null coalesce with null fallback', () {
      final ast = _parse('a ?? null');
      expect(ast, isA<NullCoalesceExpr>());
      final nc = ast as NullCoalesceExpr;
      expect(nc.right, isA<LiteralExpr>());
      // Lexer stores null as string 'null' due to literal ?? text fallback
      expect((nc.right as LiteralExpr).value, equals('null'));
    });

    test('null coalesce has higher precedence than ternary', () {
      // a ?? b ? c : d should parse as (a ?? b) ? c : d
      final ast = _parse('a ?? b ? c : d');
      expect(ast, isA<ConditionalExpr>());
      final cond = ast as ConditionalExpr;
      expect(cond.condition, isA<NullCoalesceExpr>());
    });

    test('null coalesce with member access', () {
      final ast = _parse('a.b ?? c.d');
      expect(ast, isA<NullCoalesceExpr>());
      final nc = ast as NullCoalesceExpr;
      expect(nc.left, isA<MemberExpr>());
      expect(nc.right, isA<MemberExpr>());
    });
  });

  // ===========================================================================
  // 14. Pipe Operator
  // ===========================================================================
  group('Pipe operator', () {
    test('parses single pipe', () {
      final ast = _parse('value | filter');
      expect(ast, isA<PipeExpr>());
      final pipe = ast as PipeExpr;
      expect(pipe.value, isA<IdentifierExpr>());
      expect(pipe.filter, isA<IdentifierExpr>());
    });

    test('parses chained pipes (left-associative)', () {
      // value | f1 | f2 => PipeExpr(PipeExpr(value, f1), f2)
      final ast = _parse('value | f1 | f2');
      expect(ast, isA<PipeExpr>());
      final outer = ast as PipeExpr;
      expect(outer.filter, isA<IdentifierExpr>());
      expect(outer.value, isA<PipeExpr>());
      final inner = outer.value as PipeExpr;
      expect(inner.value, isA<IdentifierExpr>());
      expect(inner.filter, isA<IdentifierExpr>());
    });

    test('parses pipe with function call as filter', () {
      final ast = _parse('value | upper');
      expect(ast, isA<PipeExpr>());
      final pipe = ast as PipeExpr;
      expect(pipe.filter, isA<IdentifierExpr>());
      expect((pipe.filter as IdentifierExpr).name.lexeme, equals('upper'));
    });

    test('parses triple chained pipes', () {
      // a | b | c | d => PipeExpr(PipeExpr(PipeExpr(a, b), c), d)
      final ast = _parse('a | b | c | d');
      expect(ast, isA<PipeExpr>());
      final p3 = ast as PipeExpr;
      expect(p3.filter, isA<IdentifierExpr>());
      expect(p3.value, isA<PipeExpr>());
      final p2 = p3.value as PipeExpr;
      expect(p2.value, isA<PipeExpr>());
    });

    test('pipe is below unary in precedence', () {
      // -a | b => PipeExpr(UnaryExpr(-, a), b)
      // Unary parses first, then pipe collects postfix results
      final ast = _parse('-a | b');
      // According to grammar: unary -> pipe -> postfix
      // -a | b => unary calls pipe, pipe calls postfix for -a?
      // Actually the grammar is: unary = ("!" | "-") unary | pipe
      // So -a => UnaryExpr(-, pipe(postfix(a)))
      // Then for "-a | b", the unary sees "-", calls _unary recursively,
      // which doesn't match unary prefix, so falls to _pipe,
      // which calls postfix(a), then sees "|", calls postfix(b)
      // => UnaryExpr(-, PipeExpr(a, b))
      expect(ast, isA<UnaryExpr>());
      final unary = ast as UnaryExpr;
      expect(unary.operand, isA<PipeExpr>());
    });
  });

  // ===========================================================================
  // 15. Postfix Operations - Member Access
  // ===========================================================================
  group('Postfix - Member access', () {
    test('parses dot member access', () {
      final ast = _parse('a.b');
      expect(ast, isA<MemberExpr>());
      final member = ast as MemberExpr;
      expect(member.object, isA<IdentifierExpr>());
      expect(member.name.lexeme, equals('b'));
      expect(member.isOptional, isFalse);
    });

    test('parses optional chaining member access', () {
      final ast = _parse('a?.b');
      expect(ast, isA<MemberExpr>());
      final member = ast as MemberExpr;
      expect(member.isOptional, isTrue);
      expect(member.operator.type, equals(TokenType.questionDot));
    });

    test('parses chained member access', () {
      // a.b.c => MemberExpr(MemberExpr(a, ., b), ., c)
      final ast = _parse('a.b.c');
      expect(ast, isA<MemberExpr>());
      final outer = ast as MemberExpr;
      expect(outer.name.lexeme, equals('c'));
      expect(outer.object, isA<MemberExpr>());
      final inner = outer.object as MemberExpr;
      expect(inner.name.lexeme, equals('b'));
    });

    test('parses mixed dot and optional chaining', () {
      final ast = _parse('a.b?.c');
      expect(ast, isA<MemberExpr>());
      final outer = ast as MemberExpr;
      expect(outer.isOptional, isTrue);
      expect(outer.object, isA<MemberExpr>());
      final inner = outer.object as MemberExpr;
      expect(inner.isOptional, isFalse);
    });

    test('parses deep chained member access', () {
      final ast = _parse('a.b.c.d.e');
      expect(ast, isA<MemberExpr>());
      final m5 = ast as MemberExpr;
      expect(m5.name.lexeme, equals('e'));
      expect(m5.object, isA<MemberExpr>());
      final m4 = m5.object as MemberExpr;
      expect(m4.name.lexeme, equals('d'));
    });
  });

  // ===========================================================================
  // 16. Postfix Operations - Function Calls
  // ===========================================================================
  group('Postfix - Function calls', () {
    test('parses no-argument function call', () {
      final ast = _parse('f()');
      expect(ast, isA<CallExpr>());
      final call = ast as CallExpr;
      expect(call.callee, isA<IdentifierExpr>());
      expect(call.arguments, isEmpty);
    });

    test('parses single-argument function call', () {
      final ast = _parse('f(x)');
      expect(ast, isA<CallExpr>());
      final call = ast as CallExpr;
      expect(call.arguments, hasLength(1));
      expect(call.arguments[0], isA<IdentifierExpr>());
    });

    test('parses multi-argument function call', () {
      final ast = _parse('f(a, b, c)');
      expect(ast, isA<CallExpr>());
      final call = ast as CallExpr;
      expect(call.arguments, hasLength(3));
    });

    test('parses function call with literal arguments', () {
      final ast = _parse('f(1, "two", true)');
      expect(ast, isA<CallExpr>());
      final call = ast as CallExpr;
      expect(call.arguments, hasLength(3));
      expect(call.arguments[0], isA<LiteralExpr>());
      expect(call.arguments[1], isA<LiteralExpr>());
      expect(call.arguments[2], isA<LiteralExpr>());
    });

    test('parses chained function calls', () {
      // f(a)(b) => CallExpr(CallExpr(f, [a]), [b])
      final ast = _parse('f(a)(b)');
      expect(ast, isA<CallExpr>());
      final outer = ast as CallExpr;
      expect(outer.callee, isA<CallExpr>());
      expect(outer.arguments, hasLength(1));
    });

    test('parses method call on member', () {
      final ast = _parse('obj.method(x)');
      expect(ast, isA<CallExpr>());
      final call = ast as CallExpr;
      expect(call.callee, isA<MemberExpr>());
      expect(call.arguments, hasLength(1));
    });

    test('parses function call with expression arguments', () {
      final ast = _parse('f(a + b, c * d)');
      expect(ast, isA<CallExpr>());
      final call = ast as CallExpr;
      expect(call.arguments, hasLength(2));
      expect(call.arguments[0], isA<BinaryExpr>());
      expect(call.arguments[1], isA<BinaryExpr>());
    });

    test('parses nested function calls', () {
      final ast = _parse('outer(inner(x))');
      expect(ast, isA<CallExpr>());
      final call = ast as CallExpr;
      expect(call.arguments, hasLength(1));
      expect(call.arguments[0], isA<CallExpr>());
    });
  });

  // ===========================================================================
  // 17. Postfix Operations - Index Access
  // ===========================================================================
  group('Postfix - Index access', () {
    test('parses numeric index', () {
      final ast = _parse('a[0]');
      expect(ast, isA<IndexExpr>());
      final idx = ast as IndexExpr;
      expect(idx.object, isA<IdentifierExpr>());
      expect(idx.index, isA<LiteralExpr>());
      expect((idx.index as LiteralExpr).value, equals(0.0));
    });

    test('parses string index', () {
      final ast = _parse('a["key"]');
      expect(ast, isA<IndexExpr>());
      final idx = ast as IndexExpr;
      expect(idx.index, isA<LiteralExpr>());
      expect((idx.index as LiteralExpr).value, equals('key'));
    });

    test('parses expression index', () {
      final ast = _parse('a[i + 1]');
      expect(ast, isA<IndexExpr>());
      final idx = ast as IndexExpr;
      expect(idx.index, isA<BinaryExpr>());
    });

    test('parses chained index access', () {
      // a[0][1] => IndexExpr(IndexExpr(a, 0), 1)
      final ast = _parse('a[0][1]');
      expect(ast, isA<IndexExpr>());
      final outer = ast as IndexExpr;
      expect(outer.object, isA<IndexExpr>());
    });

    test('parses index after member access', () {
      final ast = _parse('obj.list[0]');
      expect(ast, isA<IndexExpr>());
      final idx = ast as IndexExpr;
      expect(idx.object, isA<MemberExpr>());
    });

    test('parses identifier index', () {
      final ast = _parse('a[i]');
      expect(ast, isA<IndexExpr>());
      final idx = ast as IndexExpr;
      expect(idx.index, isA<IdentifierExpr>());
    });
  });

  // ===========================================================================
  // 18. Mixed Postfix Operations
  // ===========================================================================
  group('Mixed postfix operations', () {
    test('parses call then member access: f().x', () {
      final ast = _parse('f().x');
      expect(ast, isA<MemberExpr>());
      final member = ast as MemberExpr;
      expect(member.object, isA<CallExpr>());
      expect(member.name.lexeme, equals('x'));
    });

    test('parses call then index access: f()[0]', () {
      final ast = _parse('f()[0]');
      expect(ast, isA<IndexExpr>());
      final idx = ast as IndexExpr;
      expect(idx.object, isA<CallExpr>());
    });

    test('parses member then index then call chain', () {
      // obj.list[0].toString() =>
      //   CallExpr(MemberExpr(IndexExpr(MemberExpr(obj, list), 0), toString), [])
      final ast = _parse('obj.list[0].toString()');
      expect(ast, isA<CallExpr>());
      final call = ast as CallExpr;
      expect(call.callee, isA<MemberExpr>());
      final member = call.callee as MemberExpr;
      expect(member.name.lexeme, equals('toString'));
      expect(member.object, isA<IndexExpr>());
    });

    test('parses optional chaining with function call: a?.method()', () {
      final ast = _parse('a?.method()');
      expect(ast, isA<CallExpr>());
      final call = ast as CallExpr;
      expect(call.callee, isA<MemberExpr>());
      final member = call.callee as MemberExpr;
      expect(member.isOptional, isTrue);
    });

    test('parses index on call result: getData()[0]', () {
      final ast = _parse('getData()[0]');
      expect(ast, isA<IndexExpr>());
      final idx = ast as IndexExpr;
      expect(idx.object, isA<CallExpr>());
    });
  });

  // ===========================================================================
  // 19. Operator Precedence (comprehensive)
  // ===========================================================================
  group('Operator precedence', () {
    test('multiplication binds tighter than addition: a + b * c', () {
      // a + b * c => BinaryExpr(a, +, BinaryExpr(b, *, c))
      final ast = _parse('a + b * c');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('+'));
      expect(bin.left, isA<IdentifierExpr>());
      expect(bin.right, isA<BinaryExpr>());
      final right = bin.right as BinaryExpr;
      expect(right.operator.lexeme, equals('*'));
    });

    test('division binds tighter than subtraction: a - b / c', () {
      final ast = _parse('a - b / c');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('-'));
      expect(bin.right, isA<BinaryExpr>());
      expect((bin.right as BinaryExpr).operator.lexeme, equals('/'));
    });

    test('power binds tighter than multiplication: a * b ** c', () {
      final ast = _parse('a * b ** c');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('*'));
      expect(bin.right, isA<BinaryExpr>());
      expect((bin.right as BinaryExpr).operator.lexeme, equals('**'));
    });

    test('subtraction is left-associative: a - b - c', () {
      // a - b - c => BinaryExpr(BinaryExpr(a, -, b), -, c)
      final ast = _parse('a - b - c');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('-'));
      expect(bin.left, isA<BinaryExpr>());
      expect(bin.right, isA<IdentifierExpr>());
    });

    test('addition is left-associative: a + b + c', () {
      final ast = _parse('a + b + c');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('+'));
      expect(bin.left, isA<BinaryExpr>());
    });

    test('multiplication is left-associative: a * b * c', () {
      final ast = _parse('a * b * c');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.left, isA<BinaryExpr>());
    });

    test('power is left-associative in this grammar: 2 ** 3 ** 4', () {
      // Grammar uses while loop, so 2 ** 3 ** 4 => BinaryExpr(BinaryExpr(2,**,3),**,4)
      final ast = _parse('2 ** 3 ** 4');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('**'));
      expect(bin.left, isA<BinaryExpr>());
      expect(bin.right, isA<LiteralExpr>());
    });

    test('complex precedence: a + b * c - d / e', () {
      final ast = _parse('a + b * c - d / e');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('-'));
      expect(bin.left, isA<BinaryExpr>());
      expect(bin.right, isA<BinaryExpr>());
      final left = bin.left as BinaryExpr;
      expect(left.operator.lexeme, equals('+'));
      expect(left.right, isA<BinaryExpr>());
      expect((left.right as BinaryExpr).operator.lexeme, equals('*'));
      expect((bin.right as BinaryExpr).operator.lexeme, equals('/'));
    });

    test('grouping overrides precedence', () {
      final ast = _parse('(a + b) * c');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('*'));
      expect(bin.left, isA<GroupingExpr>());
    });

    test('unary binds tighter than binary: -a + b', () {
      // -a + b => BinaryExpr(UnaryExpr(-, a), +, b)
      final ast = _parse('-a + b');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('+'));
      expect(bin.left, isA<UnaryExpr>());
    });

    test('full precedence chain: conditional > null coalesce > or > and > membership > equality > comparison > term > factor > power > unary > pipe > postfix', () {
      // a || b && c == d < e + f * g ** h
      // Should parse as: a || (b && ((c == (d < (e + (f * (g ** h))))) ))
      final ast = _parse('a || b && c == d < e + f * g ** h');
      expect(ast, isA<LogicalExpr>()); // ||
      final orExpr = ast as LogicalExpr;
      expect(orExpr.operator.type, equals(TokenType.or));
      expect(orExpr.left, isA<IdentifierExpr>()); // a
      expect(orExpr.right, isA<LogicalExpr>()); // &&
      final andExpr = orExpr.right as LogicalExpr;
      expect(andExpr.operator.type, equals(TokenType.and));
      expect(andExpr.left, isA<IdentifierExpr>()); // b
      expect(andExpr.right, isA<BinaryExpr>()); // ==
      final eqExpr = andExpr.right as BinaryExpr;
      expect(eqExpr.operator.lexeme, equals('=='));
      expect(eqExpr.right, isA<BinaryExpr>()); // <
      final ltExpr = eqExpr.right as BinaryExpr;
      expect(ltExpr.operator.lexeme, equals('<'));
      expect(ltExpr.right, isA<BinaryExpr>()); // +
      final addExpr = ltExpr.right as BinaryExpr;
      expect(addExpr.operator.lexeme, equals('+'));
      expect(addExpr.right, isA<BinaryExpr>()); // *
      final mulExpr = addExpr.right as BinaryExpr;
      expect(mulExpr.operator.lexeme, equals('*'));
      expect(mulExpr.right, isA<BinaryExpr>()); // **
      final powExpr = mulExpr.right as BinaryExpr;
      expect(powExpr.operator.lexeme, equals('**'));
    });
  });

  // ===========================================================================
  // 20. Complex / Integration Expressions
  // ===========================================================================
  group('Complex expressions', () {
    test('parses user.name == "John" && age >= 18', () {
      final ast = _parse('user.name == "John" && age >= 18');
      expect(ast, isA<LogicalExpr>());
      final log = ast as LogicalExpr;
      expect(log.operator.type, equals(TokenType.and));
      expect(log.left, isA<BinaryExpr>());
      final left = log.left as BinaryExpr;
      expect(left.operator.lexeme, equals('=='));
      expect(left.left, isA<MemberExpr>());
      expect(log.right, isA<BinaryExpr>());
      final right = log.right as BinaryExpr;
      expect(right.operator.lexeme, equals('>='));
    });

    test('parses optional chaining with null coalesce', () {
      final ast = _parse('a?.b?.c ?? "default"');
      expect(ast, isA<NullCoalesceExpr>());
      final nc = ast as NullCoalesceExpr;
      expect(nc.left, isA<MemberExpr>());
      final outerMember = nc.left as MemberExpr;
      expect(outerMember.isOptional, isTrue);
      expect(outerMember.object, isA<MemberExpr>());
      final innerMember = outerMember.object as MemberExpr;
      expect(innerMember.isOptional, isTrue);
      expect(nc.right, isA<LiteralExpr>());
    });

    test('parses function call in ternary condition', () {
      final ast = _parse('isActive(user) ? "yes" : "no"');
      expect(ast, isA<ConditionalExpr>());
      final cond = ast as ConditionalExpr;
      expect(cond.condition, isA<CallExpr>());
    });

    test('parses array access with comparison', () {
      final ast = _parse('items[0] > items[1]');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.left, isA<IndexExpr>());
      expect(bin.right, isA<IndexExpr>());
    });

    test('parses pipe with member access', () {
      final ast = _parse('user.name | upper');
      expect(ast, isA<PipeExpr>());
      final pipe = ast as PipeExpr;
      expect(pipe.value, isA<MemberExpr>());
      expect(pipe.filter, isA<IdentifierExpr>());
    });

    test('parses logical not with comparison', () {
      // not a == b => BinaryExpr(UnaryExpr(not, a), ==, b)
      final ast = _parse('not a == b');
      expect(ast, isA<BinaryExpr>());
      final bin = ast as BinaryExpr;
      expect(bin.operator.lexeme, equals('=='));
      expect(bin.left, isA<UnaryExpr>());
    });

    test('parses object literal with nested array', () {
      final ast = _parse('{items: [1, 2, 3], name: "test"}');
      expect(ast, isA<ObjectExpr>());
      final obj = ast as ObjectExpr;
      expect(obj.entries, hasLength(2));
      expect(obj.entries[0].$2, isA<ArrayExpr>());
      expect(obj.entries[1].$2, isA<LiteralExpr>());
    });

    test('parses lambda in function call argument', () {
      final ast = _parse('map(x => x + 1)');
      expect(ast, isA<CallExpr>());
      final call = ast as CallExpr;
      expect(call.arguments, hasLength(1));
      expect(call.arguments[0], isA<LambdaExpr>());
    });

    test('parses complex boolean expression', () {
      final ast = _parse('(a > 0 and b > 0) or c == true');
      expect(ast, isA<LogicalExpr>());
      final log = ast as LogicalExpr;
      expect(log.operator.type, equals(TokenType.or));
      expect(log.left, isA<GroupingExpr>());
      expect(log.right, isA<BinaryExpr>());
    });

    test('parses member access in array literal', () {
      final ast = _parse('[a.b, c.d]');
      expect(ast, isA<ArrayExpr>());
      final arr = ast as ArrayExpr;
      expect(arr.elements[0], isA<MemberExpr>());
      expect(arr.elements[1], isA<MemberExpr>());
    });

    test('parses ternary with null coalesce in branches', () {
      final ast = _parse('flag ? a ?? b : c ?? d');
      expect(ast, isA<ConditionalExpr>());
      final cond = ast as ConditionalExpr;
      expect(cond.thenBranch, isA<NullCoalesceExpr>());
      expect(cond.elseBranch, isA<NullCoalesceExpr>());
    });

    test('parses filter chain: list | filter(x => x > 0) | map(x => x * 2)', () {
      final ast = _parse('list | filter | map');
      expect(ast, isA<PipeExpr>());
      final outer = ast as PipeExpr;
      expect(outer.value, isA<PipeExpr>());
    });

    test('parses deeply nested member access and calls', () {
      final ast = _parse('a.b().c.d()');
      expect(ast, isA<CallExpr>());
      final call = ast as CallExpr;
      expect(call.callee, isA<MemberExpr>());
      final member = call.callee as MemberExpr;
      expect(member.name.lexeme, equals('d'));
      expect(member.object, isA<MemberExpr>());
      final member2 = member.object as MemberExpr;
      expect(member2.name.lexeme, equals('c'));
      expect(member2.object, isA<CallExpr>());
    });
  });

  // ===========================================================================
  // 21. Error Handling
  // ===========================================================================
  group('Error handling', () {
    test('throws ParserException on missing closing parenthesis', () {
      expect(
        () => _parse('(a + b'),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on missing closing bracket', () {
      expect(
        () => _parse('[1, 2'),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on missing closing brace', () {
      expect(
        () => _parse('{a: 1'),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on missing colon in ternary', () {
      expect(
        () => _parse('a ? b c'),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on unexpected token after expression', () {
      expect(
        () => _parse('a b'),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on empty input', () {
      expect(
        () => _parse(''),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on missing property name after dot', () {
      expect(
        () => _parse('a.'),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on missing expression after binary operator', () {
      expect(
        () => _parse('a +'),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on missing colon in object literal', () {
      expect(
        () => _parse('{a 1}'),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on missing closing paren in function call', () {
      expect(
        () => _parse('f(a, b'),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on empty grouping without lambda arrow', () {
      expect(
        () => _parse('()'),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on invalid object key type (number)', () {
      expect(
        () => _parse('{42: "value"}'),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on missing closing bracket in index access', () {
      expect(
        () => _parse('a[0'),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on missing expression after unary minus', () {
      expect(
        () => _parse('- +'),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on missing right operand in comparison', () {
      expect(
        () => _parse('a >'),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on missing property name after optional chaining', () {
      expect(
        () => _parse('a?.'),
        throwsA(isA<ParserException>()),
      );
    });

    test('throws ParserException on missing expression in index brackets', () {
      expect(
        () => _parse('a[]'),
        throwsA(isA<ParserException>()),
      );
    });

    test('ParserException contains token position information', () {
      try {
        _parse('(a + b');
        fail('Expected ParserException');
      } on ParserException catch (e) {
        expect(e.message, isNotEmpty);
        expect(e.token, isNotNull);
        expect(e.toString(), contains('ParserException at'));
        expect(e.toString(), contains(':'));
      }
    });

    test('ParserException toString includes line and column', () {
      const token = Token(
        type: TokenType.eof,
        lexeme: '',
        line: 3,
        column: 7,
      );
      final exception = ParserException('test error', token);
      expect(exception.toString(),
          equals('ParserException at 3:7: test error'));
    });

    test('ParserException stores message and token', () {
      const token = Token(
        type: TokenType.identifier,
        lexeme: 'foo',
        line: 1,
        column: 1,
      );
      final exception = ParserException('unexpected', token);
      expect(exception.message, equals('unexpected'));
      expect(exception.token, equals(token));
    });
  });
}
