import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  group('Token', () {
    test('creates token with required fields', () {
      const token = Token(
        type: TokenType.number,
        lexeme: '42',
        literal: 42.0,
        line: 1,
        column: 1,
      );

      expect(token.type, equals(TokenType.number));
      expect(token.lexeme, equals('42'));
      expect(token.literal, equals(42.0));
      expect(token.line, equals(1));
      expect(token.column, equals(1));
    });

    test('equality based on type, lexeme, and literal', () {
      const token1 = Token(
        type: TokenType.string,
        lexeme: '"hello"',
        literal: 'hello',
        line: 1,
        column: 1,
      );
      const token2 = Token(
        type: TokenType.string,
        lexeme: '"hello"',
        literal: 'hello',
        line: 2,
        column: 5,
      );
      const token3 = Token(
        type: TokenType.string,
        lexeme: '"world"',
        literal: 'world',
        line: 1,
        column: 1,
      );

      expect(token1, equals(token2));
      expect(token1, isNot(equals(token3)));
    });
  });

  group('Lexer', () {
    test('tokenizes numbers', () {
      final lexer = Lexer('42 3.14 1e10');
      final tokens = lexer.tokenize();

      expect(tokens.length, equals(4)); // 3 numbers + EOF
      expect(tokens[0].type, equals(TokenType.number));
      expect(tokens[0].literal, equals(42.0));
      expect(tokens[1].type, equals(TokenType.number));
      expect(tokens[1].literal, equals(3.14));
      expect(tokens[2].type, equals(TokenType.number));
    });

    test('tokenizes strings', () {
      final lexer = Lexer('"hello" \'world\'');
      final tokens = lexer.tokenize();

      expect(tokens.length, equals(3)); // 2 strings + EOF
      expect(tokens[0].type, equals(TokenType.string));
      expect(tokens[0].literal, equals('hello'));
      expect(tokens[1].type, equals(TokenType.string));
      expect(tokens[1].literal, equals('world'));
    });

    test('tokenizes escape sequences in strings', () {
      final lexer = Lexer(r'"hello\nworld"');
      final tokens = lexer.tokenize();

      expect(tokens[0].literal, equals('hello\nworld'));
    });

    test('tokenizes booleans and null', () {
      final lexer = Lexer('true false null');
      final tokens = lexer.tokenize();

      expect(tokens[0].type, equals(TokenType.boolean));
      expect(tokens[0].literal, equals(true));
      expect(tokens[1].type, equals(TokenType.boolean));
      expect(tokens[1].literal, equals(false));
      expect(tokens[2].type, equals(TokenType.nullLiteral));
      // null literal stores 'null' string as literal, type identifies it as null
      expect(tokens[2].lexeme, equals('null'));
    });

    test('tokenizes identifiers', () {
      final lexer = Lexer('foo bar_baz');
      final tokens = lexer.tokenize();

      expect(tokens[0].type, equals(TokenType.identifier));
      expect(tokens[0].literal, equals('foo'));
      expect(tokens[1].type, equals(TokenType.identifier));
      expect(tokens[1].literal, equals('bar_baz'));
    });

    test('tokenizes operators', () {
      final lexer = Lexer('+ - * / % **');
      final tokens = lexer.tokenize();

      expect(tokens[0].type, equals(TokenType.plus));
      expect(tokens[1].type, equals(TokenType.minus));
      expect(tokens[2].type, equals(TokenType.multiply));
      expect(tokens[3].type, equals(TokenType.divide));
      expect(tokens[4].type, equals(TokenType.modulo));
      expect(tokens[5].type, equals(TokenType.power));
    });

    test('tokenizes comparison operators', () {
      final lexer = Lexer('== != < <= > >=');
      final tokens = lexer.tokenize();

      expect(tokens[0].type, equals(TokenType.equal));
      expect(tokens[1].type, equals(TokenType.notEqual));
      expect(tokens[2].type, equals(TokenType.lessThan));
      expect(tokens[3].type, equals(TokenType.lessThanOrEqual));
      expect(tokens[4].type, equals(TokenType.greaterThan));
      expect(tokens[5].type, equals(TokenType.greaterThanOrEqual));
    });

    test('tokenizes logical operators', () {
      final lexer = Lexer('and or not && || !');
      final tokens = lexer.tokenize();

      expect(tokens[0].type, equals(TokenType.and));
      expect(tokens[1].type, equals(TokenType.or));
      expect(tokens[2].type, equals(TokenType.not));
      expect(tokens[3].type, equals(TokenType.and));
      expect(tokens[4].type, equals(TokenType.or));
      expect(tokens[5].type, equals(TokenType.not));
    });

    test('tokenizes delimiters', () {
      final lexer = Lexer('()[]{},:.');
      final tokens = lexer.tokenize();

      expect(tokens[0].type, equals(TokenType.leftParen));
      expect(tokens[1].type, equals(TokenType.rightParen));
      expect(tokens[2].type, equals(TokenType.leftBracket));
      expect(tokens[3].type, equals(TokenType.rightBracket));
      expect(tokens[4].type, equals(TokenType.leftBrace));
      expect(tokens[5].type, equals(TokenType.rightBrace));
      expect(tokens[6].type, equals(TokenType.comma));
      expect(tokens[7].type, equals(TokenType.colon));
      expect(tokens[8].type, equals(TokenType.dot));
    });

    test('tokenizes special tokens', () {
      final lexer = Lexer(r'${ => ?. ? |');
      final tokens = lexer.tokenize();

      expect(tokens[0].type, equals(TokenType.dollarBrace));
      expect(tokens[1].type, equals(TokenType.arrow));
      expect(tokens[2].type, equals(TokenType.questionDot));
      expect(tokens[3].type, equals(TokenType.question));
      expect(tokens[4].type, equals(TokenType.pipe));
    });

    test('handles whitespace and newlines', () {
      final lexer = Lexer('a\n  b\t c');
      final tokens = lexer.tokenize();

      expect(tokens.length, equals(4)); // 3 identifiers + EOF
      expect(tokens[0].line, equals(1));
      expect(tokens[1].line, equals(2));
    });

    test('throws on unterminated string', () {
      final lexer = Lexer('"unterminated');

      expect(() => lexer.tokenize(), throwsA(isA<LexerException>()));
    });

    test('throws on unexpected character', () {
      final lexer = Lexer('@');

      expect(() => lexer.tokenize(), throwsA(isA<LexerException>()));
    });

    test('tokenizes complex expression', () {
      final lexer = Lexer('user.name == "John" and age >= 18');
      final tokens = lexer.tokenize();

      // user . name == "John" and age >= 18 EOF
      expect(tokens.length, equals(10)); // 9 tokens + EOF
      expect(tokens[0].type, equals(TokenType.identifier));
      expect(tokens[1].type, equals(TokenType.dot));
      expect(tokens[2].type, equals(TokenType.identifier));
      expect(tokens[3].type, equals(TokenType.equal));
      expect(tokens[4].type, equals(TokenType.string));
      expect(tokens[5].type, equals(TokenType.and));
      expect(tokens[6].type, equals(TokenType.identifier));
      expect(tokens[7].type, equals(TokenType.greaterThanOrEqual));
      expect(tokens[8].type, equals(TokenType.number));
      expect(tokens[9].type, equals(TokenType.eof));
    });
  });

  group('LexerException', () {
    test('contains line and column info', () {
      final exception = LexerException('Test error', 5, 10);

      expect(exception.message, equals('Test error'));
      expect(exception.line, equals(5));
      expect(exception.column, equals(10));
      expect(exception.toString(), contains('5:10'));
    });
  });
}
