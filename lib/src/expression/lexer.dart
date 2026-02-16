/// Lexer for Expression Language.
///
/// Converts source text into a list of tokens.
library;

import 'token.dart';

/// Lexer exception for invalid input.
class LexerException implements Exception {
  final String message;
  final int line;
  final int column;

  LexerException(this.message, this.line, this.column);

  @override
  String toString() => 'LexerException at $line:$column: $message';
}

/// Lexer for the MCP Expression Language.
class Lexer {
  final String source;
  final List<Token> _tokens = [];

  int _start = 0;
  int _current = 0;
  int _line = 1;
  int _column = 1;
  int _startColumn = 1;

  Lexer(this.source);

  /// Tokenize the source string.
  List<Token> tokenize() {
    while (!_isAtEnd) {
      _start = _current;
      _startColumn = _column;
      _scanToken();
    }

    _tokens.add(Token(
      type: TokenType.eof,
      lexeme: '',
      line: _line,
      column: _column,
    ));

    return _tokens;
  }

  bool get _isAtEnd => _current >= source.length;

  void _scanToken() {
    final c = _advance();

    switch (c) {
      case '(':
        _addToken(TokenType.leftParen);
      case ')':
        _addToken(TokenType.rightParen);
      case '[':
        _addToken(TokenType.leftBracket);
      case ']':
        _addToken(TokenType.rightBracket);
      case '{':
        _addToken(TokenType.leftBrace);
      case '}':
        _addToken(TokenType.rightBrace);
      case ',':
        _addToken(TokenType.comma);
      case ':':
        _addToken(TokenType.colon);
      case '+':
        _addToken(TokenType.plus);
      case '-':
        _addToken(TokenType.minus);
      case '*':
        if (_match('*')) {
          _addToken(TokenType.power);
        } else {
          _addToken(TokenType.multiply);
        }
      case '/':
        _addToken(TokenType.divide);
      case '%':
        _addToken(TokenType.modulo);
      case '?':
        if (_match('.')) {
          _addToken(TokenType.questionDot);
        } else {
          _addToken(TokenType.question);
        }
      case '.':
        _addToken(TokenType.dot);
      case '|':
        if (_match('|')) {
          _addToken(TokenType.or);
        } else {
          _addToken(TokenType.pipe);
        }
      case '&':
        if (_match('&')) {
          _addToken(TokenType.and);
        } else {
          throw LexerException('Unexpected character: &', _line, _column);
        }
      case '!':
        if (_match('=')) {
          _addToken(TokenType.notEqual);
        } else {
          _addToken(TokenType.not);
        }
      case '=':
        if (_match('=')) {
          _addToken(TokenType.equal);
        } else if (_match('>')) {
          _addToken(TokenType.arrow);
        } else {
          _addToken(TokenType.equal);
        }
      case '<':
        if (_match('=')) {
          _addToken(TokenType.lessThanOrEqual);
        } else {
          _addToken(TokenType.lessThan);
        }
      case '>':
        if (_match('=')) {
          _addToken(TokenType.greaterThanOrEqual);
        } else {
          _addToken(TokenType.greaterThan);
        }
      case '\$':
        if (_match('{')) {
          _addToken(TokenType.dollarBrace);
        } else {
          _identifier();
        }
      case ' ':
      case '\t':
      case '\r':
        // Ignore whitespace
        break;
      case '\n':
        _line++;
        _column = 1;
      case '"':
        _string('"');
      case "'":
        _string("'");
      default:
        if (_isDigit(c)) {
          _number();
        } else if (_isAlpha(c)) {
          _identifier();
        } else {
          throw LexerException('Unexpected character: $c', _line, _startColumn);
        }
    }
  }

  String _advance() {
    final c = source[_current];
    _current++;
    _column++;
    return c;
  }

  bool _match(String expected) {
    if (_isAtEnd) return false;
    if (source[_current] != expected) return false;
    _current++;
    _column++;
    return true;
  }

  String _peek() {
    if (_isAtEnd) return '\x00';
    return source[_current];
  }

  String _peekNext() {
    if (_current + 1 >= source.length) return '\x00';
    return source[_current + 1];
  }

  void _string(String quote) {
    final buffer = StringBuffer();

    while (_peek() != quote && !_isAtEnd) {
      if (_peek() == '\n') {
        _line++;
        _column = 1;
      }
      if (_peek() == '\\') {
        _advance();
        if (!_isAtEnd) {
          final escaped = _advance();
          switch (escaped) {
            case 'n':
              buffer.write('\n');
            case 't':
              buffer.write('\t');
            case 'r':
              buffer.write('\r');
            case '\\':
              buffer.write('\\');
            case '"':
              buffer.write('"');
            case "'":
              buffer.write("'");
            default:
              buffer.write(escaped);
          }
        }
      } else {
        buffer.write(_advance());
      }
    }

    if (_isAtEnd) {
      throw LexerException('Unterminated string', _line, _startColumn);
    }

    _advance(); // Closing quote

    _addToken(TokenType.string, buffer.toString());
  }

  void _number() {
    while (_isDigit(_peek())) {
      _advance();
    }

    // Look for decimal part
    if (_peek() == '.' && _isDigit(_peekNext())) {
      _advance(); // Consume '.'
      while (_isDigit(_peek())) {
        _advance();
      }
    }

    // Look for exponent
    if (_peek() == 'e' || _peek() == 'E') {
      _advance();
      if (_peek() == '+' || _peek() == '-') {
        _advance();
      }
      while (_isDigit(_peek())) {
        _advance();
      }
    }

    final value = double.parse(source.substring(_start, _current));
    _addToken(TokenType.number, value);
  }

  void _identifier() {
    while (_isAlphaNumeric(_peek())) {
      _advance();
    }

    final text = source.substring(_start, _current);
    final type = keywords[text];

    if (type == null) {
      _addToken(TokenType.identifier, text);
    } else if (type == TokenType.boolean) {
      _addToken(type, text == 'true');
    } else if (type == TokenType.nullLiteral) {
      _addToken(type, null);
    } else {
      _addToken(type);
    }
  }

  bool _isDigit(String c) {
    return c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57; // '0'-'9'
  }

  bool _isAlpha(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) || // 'A'-'Z'
        (code >= 97 && code <= 122) || // 'a'-'z'
        c == '_' ||
        c == '\$';
  }

  bool _isAlphaNumeric(String c) {
    return _isAlpha(c) || _isDigit(c);
  }

  void _addToken(TokenType type, [dynamic literal]) {
    final text = source.substring(_start, _current);
    _tokens.add(Token(
      type: type,
      lexeme: text,
      literal: literal ?? text,
      line: _line,
      column: _startColumn,
    ));
  }
}
