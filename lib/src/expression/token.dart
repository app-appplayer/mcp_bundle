/// Token types and definitions for Expression Language lexer.
library;

/// Token types for the expression language.
enum TokenType {
  // Literals
  number,
  string,
  boolean,
  nullLiteral,

  // Identifiers and keywords
  identifier,

  // Operators
  plus,
  minus,
  multiply,
  divide,
  modulo,
  power,

  // Comparison
  equal,
  notEqual,
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,

  // Logical
  and,
  or,
  not,

  // Delimiters
  leftParen,
  rightParen,
  leftBracket,
  rightBracket,
  leftBrace,
  rightBrace,
  comma,
  colon,
  dot,
  questionDot,
  question,
  pipe,

  // Special
  dollarBrace,
  arrow,

  // End
  eof,
}

/// A token produced by the lexer.
class Token {
  final TokenType type;
  final String lexeme;
  final dynamic literal;
  final int line;
  final int column;

  const Token({
    required this.type,
    required this.lexeme,
    this.literal,
    required this.line,
    required this.column,
  });

  @override
  String toString() => 'Token($type, "$lexeme", $literal)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Token &&
          type == other.type &&
          lexeme == other.lexeme &&
          literal == other.literal;

  @override
  int get hashCode => Object.hash(type, lexeme, literal);
}

/// Keywords map.
const Map<String, TokenType> keywords = {
  'true': TokenType.boolean,
  'false': TokenType.boolean,
  'null': TokenType.nullLiteral,
  'and': TokenType.and,
  'or': TokenType.or,
  'not': TokenType.not,
};
