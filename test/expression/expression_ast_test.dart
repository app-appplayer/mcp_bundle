import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

/// A simple visitor that returns the visitor method name for dispatch verification.
class _TestVisitor implements ExprVisitor<String> {
  @override
  String visitLiteral(LiteralExpr expr) => 'literal';

  @override
  String visitIdentifier(IdentifierExpr expr) => 'identifier';

  @override
  String visitUnary(UnaryExpr expr) => 'unary';

  @override
  String visitBinary(BinaryExpr expr) => 'binary';

  @override
  String visitLogical(LogicalExpr expr) => 'logical';

  @override
  String visitGrouping(GroupingExpr expr) => 'grouping';

  @override
  String visitCall(CallExpr expr) => 'call';

  @override
  String visitMember(MemberExpr expr) => 'member';

  @override
  String visitIndex(IndexExpr expr) => 'index';

  @override
  String visitConditional(ConditionalExpr expr) => 'conditional';

  @override
  String visitNullCoalesce(NullCoalesceExpr expr) => 'nullCoalesce';

  @override
  String visitArray(ArrayExpr expr) => 'array';

  @override
  String visitObject(ObjectExpr expr) => 'object';

  @override
  String visitInterpolation(InterpolationExpr expr) => 'interpolation';

  @override
  String visitPipe(PipeExpr expr) => 'pipe';

  @override
  String visitLambda(LambdaExpr expr) => 'lambda';
}

// Helper to create tokens concisely.
Token _token(TokenType type, String lexeme, {dynamic literal}) =>
    Token(type: type, lexeme: lexeme, literal: literal, line: 1, column: 1);

void main() {
  final visitor = _TestVisitor();

  // ── LiteralExpr ──────────────────────────────────────────────────────

  group('LiteralExpr', () {
    test('stores numeric value', () {
      const expr = LiteralExpr(42);
      expect(expr.value, 42);
    });

    test('stores string value', () {
      const expr = LiteralExpr('hello');
      expect(expr.value, 'hello');
    });

    test('stores boolean value', () {
      const expr = LiteralExpr(true);
      expect(expr.value, true);
    });

    test('stores null value', () {
      const expr = LiteralExpr(null);
      expect(expr.value, isNull);
    });

    test('accept dispatches to visitLiteral', () {
      const expr = LiteralExpr(1);
      expect(expr.accept(visitor), 'literal');
    });

    test('toString returns Literal(value)', () {
      const expr = LiteralExpr(42);
      expect(expr.toString(), 'Literal(42)');
    });

    test('toString for string value', () {
      const expr = LiteralExpr('abc');
      expect(expr.toString(), 'Literal(abc)');
    });

    test('toString for null value', () {
      const expr = LiteralExpr(null);
      expect(expr.toString(), 'Literal(null)');
    });
  });

  // ── IdentifierExpr ───────────────────────────────────────────────────

  group('IdentifierExpr', () {
    test('stores name token', () {
      final token = _token(TokenType.identifier, 'myVar');
      final expr = IdentifierExpr(token);
      expect(expr.name, token);
      expect(expr.name.lexeme, 'myVar');
    });

    test('accept dispatches to visitIdentifier', () {
      final expr = IdentifierExpr(_token(TokenType.identifier, 'x'));
      expect(expr.accept(visitor), 'identifier');
    });

    test('toString returns Identifier(lexeme)', () {
      final expr = IdentifierExpr(_token(TokenType.identifier, 'count'));
      expect(expr.toString(), 'Identifier(count)');
    });
  });

  // ── UnaryExpr ────────────────────────────────────────────────────────

  group('UnaryExpr', () {
    test('stores operator and operand', () {
      final op = _token(TokenType.minus, '-');
      const operand = LiteralExpr(5);
      final expr = UnaryExpr(op, operand);
      expect(expr.operator, op);
      expect(expr.operand, operand);
    });

    test('accept dispatches to visitUnary', () {
      final expr = UnaryExpr(_token(TokenType.not, 'not'), const LiteralExpr(true));
      expect(expr.accept(visitor), 'unary');
    });

    test('toString format', () {
      final expr = UnaryExpr(_token(TokenType.minus, '-'), const LiteralExpr(10));
      expect(expr.toString(), 'Unary(- Literal(10))');
    });
  });

  // ── BinaryExpr ───────────────────────────────────────────────────────

  group('BinaryExpr', () {
    test('stores left, operator, and right', () {
      const left = LiteralExpr(1);
      final op = _token(TokenType.plus, '+');
      const right = LiteralExpr(2);
      final expr = BinaryExpr(left, op, right);
      expect(expr.left, left);
      expect(expr.operator, op);
      expect(expr.right, right);
    });

    test('accept dispatches to visitBinary', () {
      final expr = BinaryExpr(
        const LiteralExpr(1),
        _token(TokenType.plus, '+'),
        const LiteralExpr(2),
      );
      expect(expr.accept(visitor), 'binary');
    });

    test('toString format', () {
      final expr = BinaryExpr(
        const LiteralExpr(3),
        _token(TokenType.multiply, '*'),
        const LiteralExpr(4),
      );
      expect(expr.toString(), 'Binary(Literal(3) * Literal(4))');
    });
  });

  // ── LogicalExpr ──────────────────────────────────────────────────────

  group('LogicalExpr', () {
    test('stores left, operator, and right', () {
      const left = LiteralExpr(true);
      final op = _token(TokenType.and, 'and');
      const right = LiteralExpr(false);
      final expr = LogicalExpr(left, op, right);
      expect(expr.left, left);
      expect(expr.operator, op);
      expect(expr.right, right);
    });

    test('accept dispatches to visitLogical', () {
      final expr = LogicalExpr(
        const LiteralExpr(true),
        _token(TokenType.or, 'or'),
        const LiteralExpr(false),
      );
      expect(expr.accept(visitor), 'logical');
    });

    test('toString format', () {
      final expr = LogicalExpr(
        const LiteralExpr(true),
        _token(TokenType.and, 'and'),
        const LiteralExpr(false),
      );
      expect(expr.toString(), 'Logical(Literal(true) and Literal(false))');
    });
  });

  // ── GroupingExpr ─────────────────────────────────────────────────────

  group('GroupingExpr', () {
    test('stores inner expression', () {
      const inner = LiteralExpr(42);
      const expr = GroupingExpr(inner);
      expect(expr.expression, inner);
    });

    test('accept dispatches to visitGrouping', () {
      const expr = GroupingExpr(LiteralExpr(1));
      expect(expr.accept(visitor), 'grouping');
    });

    test('toString format', () {
      const expr = GroupingExpr(LiteralExpr(99));
      expect(expr.toString(), 'Grouping(Literal(99))');
    });
  });

  // ── CallExpr ─────────────────────────────────────────────────────────

  group('CallExpr', () {
    test('stores callee, paren, and arguments', () {
      final callee = IdentifierExpr(_token(TokenType.identifier, 'fn'));
      final paren = _token(TokenType.leftParen, '(');
      const args = [LiteralExpr(1), LiteralExpr(2)];
      final expr = CallExpr(callee, paren, args);
      expect(expr.callee, callee);
      expect(expr.paren, paren);
      expect(expr.arguments, args);
      expect(expr.arguments.length, 2);
    });

    test('accept dispatches to visitCall', () {
      final expr = CallExpr(
        IdentifierExpr(_token(TokenType.identifier, 'test')),
        _token(TokenType.leftParen, '('),
        const [],
      );
      expect(expr.accept(visitor), 'call');
    });

    test('toString format', () {
      final expr = CallExpr(
        IdentifierExpr(_token(TokenType.identifier, 'sum')),
        _token(TokenType.leftParen, '('),
        const [LiteralExpr(1)],
      );
      expect(expr.toString(), 'Call(Identifier(sum), [Literal(1)])');
    });
  });

  // ── MemberExpr ───────────────────────────────────────────────────────

  group('MemberExpr', () {
    test('stores object, operator, and name', () {
      final obj = IdentifierExpr(_token(TokenType.identifier, 'user'));
      final op = _token(TokenType.dot, '.');
      final name = _token(TokenType.identifier, 'name');
      final expr = MemberExpr(obj, op, name);
      expect(expr.object, obj);
      expect(expr.operator, op);
      expect(expr.name, name);
    });

    test('isOptional returns false for dot operator', () {
      final expr = MemberExpr(
        IdentifierExpr(_token(TokenType.identifier, 'obj')),
        _token(TokenType.dot, '.'),
        _token(TokenType.identifier, 'field'),
      );
      expect(expr.isOptional, isFalse);
    });

    test('isOptional returns true for questionDot operator', () {
      final expr = MemberExpr(
        IdentifierExpr(_token(TokenType.identifier, 'obj')),
        _token(TokenType.questionDot, '?.'),
        _token(TokenType.identifier, 'field'),
      );
      expect(expr.isOptional, isTrue);
    });

    test('accept dispatches to visitMember', () {
      final expr = MemberExpr(
        IdentifierExpr(_token(TokenType.identifier, 'a')),
        _token(TokenType.dot, '.'),
        _token(TokenType.identifier, 'b'),
      );
      expect(expr.accept(visitor), 'member');
    });

    test('toString format with dot', () {
      final expr = MemberExpr(
        IdentifierExpr(_token(TokenType.identifier, 'user')),
        _token(TokenType.dot, '.'),
        _token(TokenType.identifier, 'age'),
      );
      expect(expr.toString(), 'Member(Identifier(user).age)');
    });

    test('toString format with questionDot', () {
      final expr = MemberExpr(
        IdentifierExpr(_token(TokenType.identifier, 'user')),
        _token(TokenType.questionDot, '?.'),
        _token(TokenType.identifier, 'age'),
      );
      expect(expr.toString(), 'Member(Identifier(user)?.age)');
    });
  });

  // ── IndexExpr ────────────────────────────────────────────────────────

  group('IndexExpr', () {
    test('stores object, bracket, and index', () {
      final obj = IdentifierExpr(_token(TokenType.identifier, 'arr'));
      final bracket = _token(TokenType.leftBracket, '[');
      const index = LiteralExpr(0);
      final expr = IndexExpr(obj, bracket, index);
      expect(expr.object, obj);
      expect(expr.bracket, bracket);
      expect(expr.index, index);
    });

    test('accept dispatches to visitIndex', () {
      final expr = IndexExpr(
        IdentifierExpr(_token(TokenType.identifier, 'list')),
        _token(TokenType.leftBracket, '['),
        const LiteralExpr(3),
      );
      expect(expr.accept(visitor), 'index');
    });

    test('toString format', () {
      final expr = IndexExpr(
        IdentifierExpr(_token(TokenType.identifier, 'items')),
        _token(TokenType.leftBracket, '['),
        const LiteralExpr(2),
      );
      expect(expr.toString(), 'Index(Identifier(items)[Literal(2)])');
    });
  });

  // ── ConditionalExpr ──────────────────────────────────────────────────

  group('ConditionalExpr', () {
    test('stores condition, thenBranch, and elseBranch', () {
      const condition = LiteralExpr(true);
      const thenBranch = LiteralExpr('yes');
      const elseBranch = LiteralExpr('no');
      const expr = ConditionalExpr(condition, thenBranch, elseBranch);
      expect(expr.condition, condition);
      expect(expr.thenBranch, thenBranch);
      expect(expr.elseBranch, elseBranch);
    });

    test('accept dispatches to visitConditional', () {
      const expr = ConditionalExpr(
        LiteralExpr(true),
        LiteralExpr(1),
        LiteralExpr(0),
      );
      expect(expr.accept(visitor), 'conditional');
    });

    test('toString format', () {
      const expr = ConditionalExpr(
        LiteralExpr(true),
        LiteralExpr('a'),
        LiteralExpr('b'),
      );
      expect(
        expr.toString(),
        'Conditional(Literal(true) ? Literal(a) : Literal(b))',
      );
    });
  });

  // ── NullCoalesceExpr ─────────────────────────────────────────────────

  group('NullCoalesceExpr', () {
    test('stores left and right', () {
      const left = LiteralExpr(null);
      const right = LiteralExpr('default');
      const expr = NullCoalesceExpr(left, right);
      expect(expr.left, left);
      expect(expr.right, right);
    });

    test('accept dispatches to visitNullCoalesce', () {
      const expr = NullCoalesceExpr(LiteralExpr(null), LiteralExpr(0));
      expect(expr.accept(visitor), 'nullCoalesce');
    });

    test('toString format', () {
      const expr = NullCoalesceExpr(LiteralExpr(null), LiteralExpr(42));
      expect(expr.toString(), 'NullCoalesce(Literal(null) ?? Literal(42))');
    });
  });

  // ── ArrayExpr ────────────────────────────────────────────────────────

  group('ArrayExpr', () {
    test('stores elements list', () {
      const elements = [LiteralExpr(1), LiteralExpr(2), LiteralExpr(3)];
      const expr = ArrayExpr(elements);
      expect(expr.elements, elements);
      expect(expr.elements.length, 3);
    });

    test('stores empty elements list', () {
      const expr = ArrayExpr([]);
      expect(expr.elements, isEmpty);
    });

    test('accept dispatches to visitArray', () {
      const expr = ArrayExpr([LiteralExpr(1)]);
      expect(expr.accept(visitor), 'array');
    });

    test('toString format', () {
      const expr = ArrayExpr([LiteralExpr(1), LiteralExpr(2)]);
      expect(expr.toString(), 'Array([Literal(1), Literal(2)])');
    });
  });

  // ── ObjectExpr ───────────────────────────────────────────────────────

  group('ObjectExpr', () {
    test('stores entries list', () {
      const entries = [
        (LiteralExpr('key') as Expr, LiteralExpr('value') as Expr),
      ];
      const expr = ObjectExpr(entries);
      expect(expr.entries.length, 1);
      expect((expr.entries[0].$1 as LiteralExpr).value, 'key');
      expect((expr.entries[0].$2 as LiteralExpr).value, 'value');
    });

    test('stores empty entries list', () {
      const expr = ObjectExpr([]);
      expect(expr.entries, isEmpty);
    });

    test('accept dispatches to visitObject', () {
      const expr = ObjectExpr([]);
      expect(expr.accept(visitor), 'object');
    });

    test('toString format', () {
      const expr = ObjectExpr([
        (LiteralExpr('a') as Expr, LiteralExpr(1) as Expr),
      ]);
      expect(expr.toString(), 'Object([(Literal(a), Literal(1))])');
    });
  });

  // ── InterpolationExpr ────────────────────────────────────────────────

  group('InterpolationExpr', () {
    test('stores parts list', () {
      const parts = [LiteralExpr('Hello '), LiteralExpr('world')];
      const expr = InterpolationExpr(parts);
      expect(expr.parts, parts);
      expect(expr.parts.length, 2);
    });

    test('accept dispatches to visitInterpolation', () {
      const expr = InterpolationExpr([LiteralExpr('text')]);
      expect(expr.accept(visitor), 'interpolation');
    });

    test('toString format', () {
      const expr = InterpolationExpr([LiteralExpr('hi')]);
      expect(expr.toString(), 'Interpolation([Literal(hi)])');
    });
  });

  // ── PipeExpr ─────────────────────────────────────────────────────────

  group('PipeExpr', () {
    test('stores value and filter', () {
      const value = LiteralExpr('hello');
      final filter = IdentifierExpr(_token(TokenType.identifier, 'upper'));
      final expr = PipeExpr(value, filter);
      expect(expr.value, value);
      expect(expr.filter, filter);
    });

    test('accept dispatches to visitPipe', () {
      final expr = PipeExpr(
        const LiteralExpr('data'),
        IdentifierExpr(_token(TokenType.identifier, 'transform')),
      );
      expect(expr.accept(visitor), 'pipe');
    });

    test('toString format', () {
      final expr = PipeExpr(
        const LiteralExpr('text'),
        IdentifierExpr(_token(TokenType.identifier, 'upper')),
      );
      expect(expr.toString(), 'Pipe(Literal(text) | Identifier(upper))');
    });
  });

  // ── LambdaExpr ───────────────────────────────────────────────────────

  group('LambdaExpr', () {
    test('stores parameters and body', () {
      final params = [_token(TokenType.identifier, 'x')];
      const body = LiteralExpr(42);
      final expr = LambdaExpr(params, body);
      expect(expr.parameters.length, 1);
      expect(expr.parameters[0].lexeme, 'x');
      expect(expr.body, body);
    });

    test('stores multiple parameters', () {
      final params = [
        _token(TokenType.identifier, 'a'),
        _token(TokenType.identifier, 'b'),
      ];
      const body = LiteralExpr(0);
      final expr = LambdaExpr(params, body);
      expect(expr.parameters.length, 2);
      expect(expr.parameters[0].lexeme, 'a');
      expect(expr.parameters[1].lexeme, 'b');
    });

    test('accept dispatches to visitLambda', () {
      final expr = LambdaExpr(
        [_token(TokenType.identifier, 'x')],
        const LiteralExpr(1),
      );
      expect(expr.accept(visitor), 'lambda');
    });

    test('toString format with single parameter', () {
      final expr = LambdaExpr(
        [_token(TokenType.identifier, 'x')],
        const LiteralExpr(99),
      );
      expect(expr.toString(), 'Lambda(x => Literal(99))');
    });

    test('toString format with multiple parameters', () {
      final expr = LambdaExpr(
        [
          _token(TokenType.identifier, 'a'),
          _token(TokenType.identifier, 'b'),
        ],
        const LiteralExpr(0),
      );
      expect(expr.toString(), 'Lambda(a, b => Literal(0))');
    });
  });

  // ── ExprVisitor dispatch completeness ────────────────────────────────

  group('ExprVisitor dispatch', () {
    test('all 16 node types dispatch to correct visitor method', () {
      final dotToken = _token(TokenType.dot, '.');
      final idToken = _token(TokenType.identifier, 'x');
      final parenToken = _token(TokenType.leftParen, '(');
      final bracketToken = _token(TokenType.leftBracket, '[');
      final plusToken = _token(TokenType.plus, '+');
      final andToken = _token(TokenType.and, 'and');
      final minusToken = _token(TokenType.minus, '-');

      final cases = <(Expr, String)>[
        (const LiteralExpr(1), 'literal'),
        (IdentifierExpr(idToken), 'identifier'),
        (UnaryExpr(minusToken, const LiteralExpr(1)), 'unary'),
        (
          BinaryExpr(const LiteralExpr(1), plusToken, const LiteralExpr(2)),
          'binary',
        ),
        (
          LogicalExpr(
            const LiteralExpr(true),
            andToken,
            const LiteralExpr(false),
          ),
          'logical',
        ),
        (const GroupingExpr(LiteralExpr(1)), 'grouping'),
        (CallExpr(IdentifierExpr(idToken), parenToken, const []), 'call'),
        (MemberExpr(IdentifierExpr(idToken), dotToken, idToken), 'member'),
        (
          IndexExpr(
            IdentifierExpr(idToken),
            bracketToken,
            const LiteralExpr(0),
          ),
          'index',
        ),
        (
          const ConditionalExpr(
            LiteralExpr(true),
            LiteralExpr(1),
            LiteralExpr(0),
          ),
          'conditional',
        ),
        (
          const NullCoalesceExpr(LiteralExpr(null), LiteralExpr(0)),
          'nullCoalesce',
        ),
        (const ArrayExpr([LiteralExpr(1)]), 'array'),
        (const ObjectExpr([]), 'object'),
        (const InterpolationExpr([LiteralExpr('a')]), 'interpolation'),
        (PipeExpr(const LiteralExpr(1), IdentifierExpr(idToken)), 'pipe'),
        (LambdaExpr([idToken], const LiteralExpr(1)), 'lambda'),
      ];

      for (final (expr, expected) in cases) {
        expect(expr.accept(visitor), expected,
            reason: '${expr.runtimeType} should dispatch to $expected');
      }
    });
  });

  // ── Sealed class verification ────────────────────────────────────────

  group('Expr sealed class', () {
    test('all node types are subtypes of Expr', () {
      final idToken = _token(TokenType.identifier, 'x');

      final nodes = <Expr>[
        const LiteralExpr(1),
        IdentifierExpr(idToken),
        UnaryExpr(_token(TokenType.minus, '-'), const LiteralExpr(1)),
        BinaryExpr(
          const LiteralExpr(1),
          _token(TokenType.plus, '+'),
          const LiteralExpr(2),
        ),
        LogicalExpr(
          const LiteralExpr(true),
          _token(TokenType.and, 'and'),
          const LiteralExpr(false),
        ),
        const GroupingExpr(LiteralExpr(1)),
        CallExpr(
          IdentifierExpr(idToken),
          _token(TokenType.leftParen, '('),
          const [],
        ),
        MemberExpr(
          IdentifierExpr(idToken),
          _token(TokenType.dot, '.'),
          idToken,
        ),
        IndexExpr(
          IdentifierExpr(idToken),
          _token(TokenType.leftBracket, '['),
          const LiteralExpr(0),
        ),
        const ConditionalExpr(
          LiteralExpr(true),
          LiteralExpr(1),
          LiteralExpr(0),
        ),
        const NullCoalesceExpr(LiteralExpr(null), LiteralExpr(0)),
        const ArrayExpr([]),
        const ObjectExpr([]),
        const InterpolationExpr([]),
        PipeExpr(const LiteralExpr(1), IdentifierExpr(idToken)),
        LambdaExpr([idToken], const LiteralExpr(1)),
      ];

      expect(nodes.length, 16);
      for (final node in nodes) {
        expect(node, isA<Expr>());
      }
    });
  });
}
