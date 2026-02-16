/// Parser for Expression Language.
///
/// Converts tokens into an Abstract Syntax Tree.
library;

import 'ast.dart';
import 'token.dart';

/// Parser exception for syntax errors.
class ParserException implements Exception {
  final String message;
  final Token token;

  ParserException(this.message, this.token);

  @override
  String toString() =>
      'ParserException at ${token.line}:${token.column}: $message';
}

/// Parser for the MCP Expression Language.
///
/// Grammar (EBNF):
/// ```
/// expression     → conditional
/// conditional    → logicalOr ( "?" expression ":" expression )?
/// logicalOr      → logicalAnd ( ( "||" | "or" ) logicalAnd )*
/// logicalAnd     → equality ( ( "&&" | "and" ) equality )*
/// equality       → comparison ( ( "==" | "!=" ) comparison )*
/// comparison     → term ( ( "<" | "<=" | ">" | ">=" ) term )*
/// term           → factor ( ( "+" | "-" ) factor )*
/// factor         → power ( ( "*" | "/" | "%" ) power )*
/// power          → unary ( "**" unary )*
/// unary          → ( "!" | "-" | "not" ) unary | pipe
/// pipe           → postfix ( "|" postfix )*
/// postfix        → primary ( call | member | index )*
/// call           → "(" arguments? ")"
/// member         → ( "." | "?." ) IDENTIFIER
/// index          → "[" expression "]"
/// primary        → NUMBER | STRING | BOOLEAN | NULL | IDENTIFIER
///                | array | object | grouping | interpolation | lambda
/// array          → "[" ( expression ( "," expression )* )? "]"
/// object         → "{" ( property ( "," property )* )? "}"
/// property       → ( IDENTIFIER | STRING ) ":" expression
/// grouping       → "(" expression ")"
/// interpolation  → "\${" expression "}"
/// lambda         → IDENTIFIER "=>" expression
///                | "(" parameters? ")" "=>" expression
/// ```
class Parser {
  final List<Token> tokens;
  int _current = 0;

  Parser(this.tokens);

  /// Parse the tokens into an expression AST.
  Expr parse() {
    final expr = _expression();
    if (!_isAtEnd) {
      throw ParserException('Unexpected token after expression', _peek());
    }
    return expr;
  }

  Expr _expression() => _conditional();

  Expr _conditional() {
    var expr = _logicalOr();

    if (_match([TokenType.question])) {
      final thenBranch = _expression();
      _consume(TokenType.colon, "Expected ':' in conditional expression");
      final elseBranch = _expression();
      expr = ConditionalExpr(expr, thenBranch, elseBranch);
    }

    return expr;
  }

  Expr _logicalOr() {
    var expr = _logicalAnd();

    while (_match([TokenType.or])) {
      final operator = _previous();
      final right = _logicalAnd();
      expr = LogicalExpr(expr, operator, right);
    }

    return expr;
  }

  Expr _logicalAnd() {
    var expr = _equality();

    while (_match([TokenType.and])) {
      final operator = _previous();
      final right = _equality();
      expr = LogicalExpr(expr, operator, right);
    }

    return expr;
  }

  Expr _equality() {
    var expr = _comparison();

    while (_match([TokenType.equal, TokenType.notEqual])) {
      final operator = _previous();
      final right = _comparison();
      expr = BinaryExpr(expr, operator, right);
    }

    return expr;
  }

  Expr _comparison() {
    var expr = _term();

    while (_match([
      TokenType.lessThan,
      TokenType.lessThanOrEqual,
      TokenType.greaterThan,
      TokenType.greaterThanOrEqual,
    ])) {
      final operator = _previous();
      final right = _term();
      expr = BinaryExpr(expr, operator, right);
    }

    return expr;
  }

  Expr _term() {
    var expr = _factor();

    while (_match([TokenType.plus, TokenType.minus])) {
      final operator = _previous();
      final right = _factor();
      expr = BinaryExpr(expr, operator, right);
    }

    return expr;
  }

  Expr _factor() {
    var expr = _power();

    while (_match([TokenType.multiply, TokenType.divide, TokenType.modulo])) {
      final operator = _previous();
      final right = _power();
      expr = BinaryExpr(expr, operator, right);
    }

    return expr;
  }

  Expr _power() {
    var expr = _unary();

    while (_match([TokenType.power])) {
      final operator = _previous();
      final right = _unary();
      expr = BinaryExpr(expr, operator, right);
    }

    return expr;
  }

  Expr _unary() {
    if (_match([TokenType.not, TokenType.minus])) {
      final operator = _previous();
      final operand = _unary();
      return UnaryExpr(operator, operand);
    }

    return _pipe();
  }

  Expr _pipe() {
    var expr = _postfix();

    while (_match([TokenType.pipe])) {
      final filter = _postfix();
      expr = PipeExpr(expr, filter);
    }

    return expr;
  }

  Expr _postfix() {
    var expr = _primary();

    while (true) {
      if (_match([TokenType.leftParen])) {
        expr = _finishCall(expr);
      } else if (_match([TokenType.dot, TokenType.questionDot])) {
        final operator = _previous();
        final name =
            _consume(TokenType.identifier, "Expected property name after '.'");
        expr = MemberExpr(expr, operator, name);
      } else if (_match([TokenType.leftBracket])) {
        final bracket = _previous();
        final index = _expression();
        _consume(TokenType.rightBracket, "Expected ']' after index");
        expr = IndexExpr(expr, bracket, index);
      } else {
        break;
      }
    }

    return expr;
  }

  Expr _finishCall(Expr callee) {
    final paren = _previous();
    final arguments = <Expr>[];

    if (!_check(TokenType.rightParen)) {
      do {
        arguments.add(_expression());
      } while (_match([TokenType.comma]));
    }

    _consume(TokenType.rightParen, "Expected ')' after arguments");
    return CallExpr(callee, paren, arguments);
  }

  Expr _primary() {
    // Literals
    if (_match([TokenType.boolean, TokenType.nullLiteral])) {
      return LiteralExpr(_previous().literal);
    }
    if (_match([TokenType.number])) {
      return LiteralExpr(_previous().literal);
    }
    if (_match([TokenType.string])) {
      return LiteralExpr(_previous().literal);
    }

    // Identifier (potentially lambda)
    if (_match([TokenType.identifier])) {
      final name = _previous();

      // Check for lambda: x => expr
      if (_match([TokenType.arrow])) {
        final body = _expression();
        return LambdaExpr([name], body);
      }

      return IdentifierExpr(name);
    }

    // Interpolation: \${...}
    if (_match([TokenType.dollarBrace])) {
      final expr = _expression();
      _consume(TokenType.rightBrace, "Expected '}' after interpolation");
      return InterpolationExpr([expr]);
    }

    // Array literal: [...]
    if (_match([TokenType.leftBracket])) {
      return _array();
    }

    // Object literal: {...}
    if (_match([TokenType.leftBrace])) {
      return _object();
    }

    // Grouping or lambda: (...)
    if (_match([TokenType.leftParen])) {
      return _groupingOrLambda();
    }

    throw ParserException('Expected expression', _peek());
  }

  Expr _array() {
    final elements = <Expr>[];

    if (!_check(TokenType.rightBracket)) {
      do {
        elements.add(_expression());
      } while (_match([TokenType.comma]));
    }

    _consume(TokenType.rightBracket, "Expected ']' after array");
    return ArrayExpr(elements);
  }

  Expr _object() {
    final entries = <(Expr, Expr)>[];

    if (!_check(TokenType.rightBrace)) {
      do {
        Expr key;
        if (_match([TokenType.identifier])) {
          key = LiteralExpr(_previous().lexeme);
        } else if (_match([TokenType.string])) {
          key = LiteralExpr(_previous().literal);
        } else {
          throw ParserException('Expected property name', _peek());
        }

        _consume(TokenType.colon, "Expected ':' after property name");
        final value = _expression();
        entries.add((key, value));
      } while (_match([TokenType.comma]));
    }

    _consume(TokenType.rightBrace, "Expected '}' after object");
    return ObjectExpr(entries);
  }

  Expr _groupingOrLambda() {
    // Empty parens followed by => is a lambda
    if (_check(TokenType.rightParen)) {
      _advance();
      if (_match([TokenType.arrow])) {
        final body = _expression();
        return LambdaExpr([], body);
      }
      // Empty grouping is an error
      throw ParserException('Empty grouping', _previous());
    }

    // Could be lambda parameters or grouping
    final firstToken = _peek();

    // If starts with identifier, might be lambda
    if (firstToken.type == TokenType.identifier) {
      // Look ahead for comma or ) =>
      final start = _current;
      final parameters = <Token>[];

      // Try to parse as lambda parameters
      bool isLambda = false;
      try {
        do {
          if (!_check(TokenType.identifier)) break;
          parameters.add(_advance());
        } while (_match([TokenType.comma]));

        if (_match([TokenType.rightParen]) && _match([TokenType.arrow])) {
          isLambda = true;
        }
      } catch (_) {
        // Not a lambda, backtrack
      }

      if (isLambda) {
        final body = _expression();
        return LambdaExpr(parameters, body);
      }

      // Backtrack and parse as grouping
      _current = start;
    }

    // Parse as grouping
    final expr = _expression();
    _consume(TokenType.rightParen, "Expected ')' after expression");
    return GroupingExpr(expr);
  }

  // Helper methods

  bool _match(List<TokenType> types) {
    for (final type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }
    return false;
  }

  bool _check(TokenType type) {
    if (_isAtEnd) return false;
    return _peek().type == type;
  }

  Token _advance() {
    if (!_isAtEnd) _current++;
    return _previous();
  }

  bool get _isAtEnd => _peek().type == TokenType.eof;

  Token _peek() => tokens[_current];

  Token _previous() => tokens[_current - 1];

  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();
    throw ParserException(message, _peek());
  }
}
