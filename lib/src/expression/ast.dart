/// Abstract Syntax Tree nodes for Expression Language.
library;

import 'token.dart';

/// Base class for all AST nodes.
sealed class Expr {
  const Expr();

  /// Accept a visitor.
  T accept<T>(ExprVisitor<T> visitor);
}

/// Visitor pattern for AST traversal.
abstract class ExprVisitor<T> {
  T visitLiteral(LiteralExpr expr);
  T visitIdentifier(IdentifierExpr expr);
  T visitUnary(UnaryExpr expr);
  T visitBinary(BinaryExpr expr);
  T visitLogical(LogicalExpr expr);
  T visitGrouping(GroupingExpr expr);
  T visitCall(CallExpr expr);
  T visitMember(MemberExpr expr);
  T visitIndex(IndexExpr expr);
  T visitConditional(ConditionalExpr expr);
  T visitArray(ArrayExpr expr);
  T visitObject(ObjectExpr expr);
  T visitInterpolation(InterpolationExpr expr);
  T visitPipe(PipeExpr expr);
  T visitLambda(LambdaExpr expr);
}

/// Literal value (number, string, boolean, null).
class LiteralExpr extends Expr {
  final dynamic value;

  const LiteralExpr(this.value);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitLiteral(this);

  @override
  String toString() => 'Literal($value)';
}

/// Identifier reference (variable name).
class IdentifierExpr extends Expr {
  final Token name;

  const IdentifierExpr(this.name);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitIdentifier(this);

  @override
  String toString() => 'Identifier(${name.lexeme})';
}

/// Unary expression (!, -, not).
class UnaryExpr extends Expr {
  final Token operator;
  final Expr operand;

  const UnaryExpr(this.operator, this.operand);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitUnary(this);

  @override
  String toString() => 'Unary(${operator.lexeme} $operand)';
}

/// Binary expression (+, -, *, /, ==, !=, etc.).
class BinaryExpr extends Expr {
  final Expr left;
  final Token operator;
  final Expr right;

  const BinaryExpr(this.left, this.operator, this.right);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitBinary(this);

  @override
  String toString() => 'Binary($left ${operator.lexeme} $right)';
}

/// Logical expression (and, or, &&, ||).
class LogicalExpr extends Expr {
  final Expr left;
  final Token operator;
  final Expr right;

  const LogicalExpr(this.left, this.operator, this.right);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitLogical(this);

  @override
  String toString() => 'Logical($left ${operator.lexeme} $right)';
}

/// Grouping expression (parentheses).
class GroupingExpr extends Expr {
  final Expr expression;

  const GroupingExpr(this.expression);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitGrouping(this);

  @override
  String toString() => 'Grouping($expression)';
}

/// Function call expression.
class CallExpr extends Expr {
  final Expr callee;
  final Token paren;
  final List<Expr> arguments;

  const CallExpr(this.callee, this.paren, this.arguments);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitCall(this);

  @override
  String toString() => 'Call($callee, $arguments)';
}

/// Member access expression (obj.field or obj?.field).
class MemberExpr extends Expr {
  final Expr object;
  final Token operator;
  final Token name;

  const MemberExpr(this.object, this.operator, this.name);

  bool get isOptional => operator.type == TokenType.questionDot;

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitMember(this);

  @override
  String toString() => 'Member($object${operator.lexeme}${name.lexeme})';
}

/// Index access expression (arr[index]).
class IndexExpr extends Expr {
  final Expr object;
  final Token bracket;
  final Expr index;

  const IndexExpr(this.object, this.bracket, this.index);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitIndex(this);

  @override
  String toString() => 'Index($object[$index])';
}

/// Conditional/ternary expression (cond ? then : else).
class ConditionalExpr extends Expr {
  final Expr condition;
  final Expr thenBranch;
  final Expr elseBranch;

  const ConditionalExpr(this.condition, this.thenBranch, this.elseBranch);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitConditional(this);

  @override
  String toString() => 'Conditional($condition ? $thenBranch : $elseBranch)';
}

/// Array literal expression.
class ArrayExpr extends Expr {
  final List<Expr> elements;

  const ArrayExpr(this.elements);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitArray(this);

  @override
  String toString() => 'Array($elements)';
}

/// Object literal expression.
class ObjectExpr extends Expr {
  final List<(Expr key, Expr value)> entries;

  const ObjectExpr(this.entries);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitObject(this);

  @override
  String toString() => 'Object($entries)';
}

/// String interpolation expression (\${...}).
class InterpolationExpr extends Expr {
  final List<Expr> parts;

  const InterpolationExpr(this.parts);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitInterpolation(this);

  @override
  String toString() => 'Interpolation($parts)';
}

/// Pipe expression (value | filter).
class PipeExpr extends Expr {
  final Expr value;
  final Expr filter;

  const PipeExpr(this.value, this.filter);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitPipe(this);

  @override
  String toString() => 'Pipe($value | $filter)';
}

/// Lambda/arrow function expression (x => x * 2).
class LambdaExpr extends Expr {
  final List<Token> parameters;
  final Expr body;

  const LambdaExpr(this.parameters, this.body);

  @override
  T accept<T>(ExprVisitor<T> visitor) => visitor.visitLambda(this);

  @override
  String toString() => 'Lambda(${parameters.map((p) => p.lexeme).join(', ')} => $body)';
}
