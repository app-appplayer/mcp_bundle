/// Expression evaluator implementing the visitor pattern.
///
/// Evaluates AST nodes to produce values.
library;

import 'ast.dart';
import 'context.dart';

/// Evaluates expressions in a given context.
class ExpressionEvaluator implements ExprVisitor<dynamic> {
  ExpressionEvaluator(this.context);

  final EvaluationContext context;

  /// Evaluate an expression and return the result.
  EvaluationResult evaluate(Expr expr) {
    try {
      final value = expr.accept(this);
      return EvaluationResult.success(value);
    } catch (e) {
      return EvaluationResult.failure(e.toString());
    }
  }

  /// Evaluate an expression, throwing on error.
  dynamic evaluateOrThrow(Expr expr) {
    return expr.accept(this);
  }

  @override
  dynamic visitLiteral(LiteralExpr expr) => expr.value;

  @override
  dynamic visitIdentifier(IdentifierExpr expr) {
    final name = expr.name.lexeme;
    if (!context.has(name)) {
      throw EvaluationException('Undefined variable: $name');
    }
    return context.get(name);
  }

  @override
  dynamic visitUnary(UnaryExpr expr) {
    final operand = expr.operand.accept(this);
    final op = expr.operator.lexeme;

    switch (op) {
      case '-':
        if (operand is num) return -operand;
        throw EvaluationException('Cannot negate non-numeric value: $operand');
      case '!':
      case 'not':
        return !_toBool(operand);
      default:
        throw EvaluationException('Unknown unary operator: $op');
    }
  }

  @override
  dynamic visitBinary(BinaryExpr expr) {
    final left = expr.left.accept(this);
    final right = expr.right.accept(this);
    final op = expr.operator.lexeme;

    switch (op) {
      // Arithmetic
      case '+':
        if (left is num && right is num) return left + right;
        if (left is String || right is String) {
          return '${left ?? ''}${right ?? ''}';
        }
        if (left is List && right is List) return [...left, ...right];
        throw EvaluationException('Cannot add $left and $right');

      case '-':
        if (left is num && right is num) return left - right;
        throw EvaluationException('Cannot subtract $left and $right');

      case '*':
        if (left is num && right is num) return left * right;
        if (left is String && right is int) return left * right;
        throw EvaluationException('Cannot multiply $left and $right');

      case '/':
        if (left is num && right is num) {
          if (right == 0) throw EvaluationException('Division by zero');
          return left / right;
        }
        throw EvaluationException('Cannot divide $left by $right');

      case '%':
        if (left is num && right is num) {
          if (right == 0) throw EvaluationException('Modulo by zero');
          return left % right;
        }
        throw EvaluationException('Cannot modulo $left by $right');

      case '**':
        if (left is num && right is num) {
          return _power(left, right);
        }
        throw EvaluationException('Cannot exponentiate $left by $right');

      // Comparison
      case '==':
        return _equals(left, right);

      case '!=':
        return !_equals(left, right);

      case '<':
        return _compare(left, right) < 0;

      case '<=':
        return _compare(left, right) <= 0;

      case '>':
        return _compare(left, right) > 0;

      case '>=':
        return _compare(left, right) >= 0;

      default:
        throw EvaluationException('Unknown binary operator: $op');
    }
  }

  @override
  dynamic visitLogical(LogicalExpr expr) {
    final op = expr.operator.lexeme;

    // Short-circuit evaluation
    if (op == 'and' || op == '&&') {
      final left = _toBool(expr.left.accept(this));
      if (!left) return false;
      return _toBool(expr.right.accept(this));
    }

    if (op == 'or' || op == '||') {
      final left = _toBool(expr.left.accept(this));
      if (left) return true;
      return _toBool(expr.right.accept(this));
    }

    throw EvaluationException('Unknown logical operator: $op');
  }

  @override
  dynamic visitConditional(ConditionalExpr expr) {
    final condition = _toBool(expr.condition.accept(this));
    return condition
        ? expr.thenBranch.accept(this)
        : expr.elseBranch.accept(this);
  }

  @override
  dynamic visitMember(MemberExpr expr) {
    final object = expr.object.accept(this);
    final member = expr.name.lexeme;

    if (object == null) {
      if (expr.isOptional) return null;
      throw EvaluationException('Cannot access property on null');
    }

    return _getProperty(object, member);
  }

  @override
  dynamic visitIndex(IndexExpr expr) {
    final object = expr.object.accept(this);
    final index = expr.index.accept(this);

    if (object == null) {
      throw EvaluationException('Cannot index null');
    }

    if (object is List) {
      if (index is! int) {
        throw EvaluationException('List index must be an integer');
      }
      if (index < 0 || index >= object.length) {
        throw EvaluationException('Index out of bounds: $index');
      }
      return object[index];
    }

    if (object is Map) {
      return object[index];
    }

    if (object is String) {
      if (index is! int) {
        throw EvaluationException('String index must be an integer');
      }
      if (index < 0 || index >= object.length) {
        throw EvaluationException('Index out of bounds: $index');
      }
      return object[index];
    }

    throw EvaluationException('Cannot index ${object.runtimeType}');
  }

  @override
  dynamic visitCall(CallExpr expr) {
    final callee = expr.callee;
    final args = expr.arguments.map((a) => a.accept(this)).toList();

    // Method call on object
    if (callee is MemberExpr) {
      final object = callee.object.accept(this);
      final methodName = callee.name.lexeme;
      if (object == null) {
        if (callee.isOptional) return null;
        throw EvaluationException('Cannot call method on null');
      }
      return _callMethod(object, methodName, args);
    }

    // Function call
    if (callee is IdentifierExpr) {
      return context.functions.call(callee.name.lexeme, args);
    }

    throw EvaluationException('Invalid call target: $callee');
  }

  @override
  dynamic visitArray(ArrayExpr expr) {
    return expr.elements.map((e) => e.accept(this)).toList();
  }

  @override
  dynamic visitObject(ObjectExpr expr) {
    final result = <String, dynamic>{};
    for (final (key, value) in expr.entries) {
      // Key can be identifier or string literal
      String keyStr;
      if (key is IdentifierExpr) {
        keyStr = key.name.lexeme;
      } else if (key is LiteralExpr && key.value is String) {
        keyStr = key.value as String;
      } else {
        keyStr = key.accept(this).toString();
      }
      result[keyStr] = value.accept(this);
    }
    return result;
  }

  @override
  dynamic visitPipe(PipeExpr expr) {
    final value = expr.value.accept(this);
    return _applyPipe(value, expr.filter);
  }

  @override
  dynamic visitLambda(LambdaExpr expr) {
    // Lambda expressions create closures for use in higher-order functions
    final paramNames = expr.parameters.map((p) => p.lexeme).toList();
    return _LambdaClosure(paramNames, expr.body, context);
  }

  @override
  dynamic visitInterpolation(InterpolationExpr expr) {
    final buffer = StringBuffer();
    for (final part in expr.parts) {
      final value = part.accept(this);
      buffer.write(value ?? '');
    }
    return buffer.toString();
  }

  @override
  dynamic visitGrouping(GroupingExpr expr) {
    return expr.expression.accept(this);
  }

  // Helper methods

  bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  bool _equals(dynamic left, dynamic right) {
    if (left == null && right == null) return true;
    if (left == null || right == null) return false;
    if (left is num && right is num) {
      return left == right;
    }
    return left == right;
  }

  int _compare(dynamic left, dynamic right) {
    if (left is num && right is num) {
      return left.compareTo(right);
    }
    if (left is String && right is String) {
      return left.compareTo(right);
    }
    if (left is DateTime && right is DateTime) {
      return left.compareTo(right);
    }
    throw EvaluationException('Cannot compare $left and $right');
  }

  num _power(num base, num exponent) {
    if (exponent is int && exponent >= 0) {
      num result = 1;
      for (var i = 0; i < exponent; i++) {
        result *= base;
      }
      return result;
    }
    // Use approximation for fractional/negative exponents
    return _pow(base.toDouble(), exponent.toDouble());
  }

  double _pow(double x, double y) {
    if (y == 0) return 1;
    if (y == 1) return x;
    if (y == 2) return x * x;
    if (y == 0.5) return _sqrt(x);

    if (x <= 0) {
      if (y == y.truncateToDouble()) {
        final intExp = y.toInt();
        if (x == 0) return 0;
        final absResult = _pow(-x, y.abs());
        return intExp.isOdd ? -absResult : absResult;
      }
      throw EvaluationException(
          'Cannot raise negative number to fractional power');
    }
    return _exp(y * _ln(x));
  }

  double _sqrt(double x) {
    if (x < 0) throw EvaluationException('Cannot take sqrt of negative number');
    if (x == 0) return 0;
    var guess = x / 2;
    for (var i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _exp(double x) {
    double result = 1;
    double term = 1;
    for (var i = 1; i <= 30; i++) {
      term *= x / i;
      result += term;
      if (term.abs() < 1e-15) break;
    }
    return result;
  }

  double _ln(double x) {
    if (x <= 0) throw EvaluationException('Cannot take ln of non-positive');
    var exp = 0;
    var y = x;
    while (y >= 2) {
      y /= 2;
      exp++;
    }
    while (y < 1) {
      y *= 2;
      exp--;
    }
    final z = y - 1;
    double result = 0;
    double term = z;
    for (var i = 1; i <= 50; i++) {
      result += term / i;
      term *= -z;
      if (term.abs() < 1e-15) break;
    }
    return result + exp * 0.6931471805599453; // ln(2)
  }

  dynamic _getProperty(dynamic object, String property) {
    if (object is Map) {
      return object[property];
    }

    if (object is List) {
      switch (property) {
        case 'length':
          return object.length;
        case 'first':
          return object.isNotEmpty ? object.first : null;
        case 'last':
          return object.isNotEmpty ? object.last : null;
        case 'isEmpty':
          return object.isEmpty;
        case 'isNotEmpty':
          return object.isNotEmpty;
      }
    }

    if (object is String) {
      switch (property) {
        case 'length':
          return object.length;
        case 'isEmpty':
          return object.isEmpty;
        case 'isNotEmpty':
          return object.isNotEmpty;
      }
    }

    throw EvaluationException(
        'Cannot access property "$property" on ${object.runtimeType}');
  }

  dynamic _callMethod(dynamic object, String method, List<dynamic> args) {
    // String methods
    if (object is String) {
      switch (method) {
        case 'toUpperCase':
          return object.toUpperCase();
        case 'toLowerCase':
          return object.toLowerCase();
        case 'trim':
          return object.trim();
        case 'split':
          if (args.isEmpty) return [object];
          return object.split(args[0].toString());
        case 'substring':
          final start = args.isNotEmpty ? args[0] as int : 0;
          final end = args.length > 1 ? args[1] as int : null;
          return object.substring(start, end);
        case 'contains':
          if (args.isEmpty) return false;
          return object.contains(args[0].toString());
        case 'startsWith':
          if (args.isEmpty) return false;
          return object.startsWith(args[0].toString());
        case 'endsWith':
          if (args.isEmpty) return false;
          return object.endsWith(args[0].toString());
        case 'replace':
          if (args.length < 2) {
            throw EvaluationException('replace requires 2 arguments');
          }
          return object.replaceAll(args[0].toString(), args[1].toString());
        case 'indexOf':
          if (args.isEmpty) return -1;
          return object.indexOf(args[0].toString());
      }
    }

    // List methods
    if (object is List) {
      switch (method) {
        case 'join':
          final separator = args.isNotEmpty ? args[0].toString() : ',';
          return object.join(separator);
        case 'contains':
          if (args.isEmpty) return false;
          return object.contains(args[0]);
        case 'indexOf':
          if (args.isEmpty) return -1;
          return object.indexOf(args[0]);
        case 'map':
          if (args.isEmpty || args[0] is! _LambdaClosure) {
            throw EvaluationException('map requires a function argument');
          }
          final closure = args[0] as _LambdaClosure;
          return object.map((e) => closure.call([e])).toList();
        case 'filter':
        case 'where':
          if (args.isEmpty || args[0] is! _LambdaClosure) {
            throw EvaluationException('filter requires a function argument');
          }
          final closure = args[0] as _LambdaClosure;
          return object.where((e) => _toBool(closure.call([e]))).toList();
        case 'reduce':
          if (args.isEmpty) {
            throw EvaluationException('reduce requires initial value');
          }
          var accumulator = args[0];
          final closure = args.length > 1 ? args[1] as _LambdaClosure : null;
          for (final element in object) {
            if (closure != null) {
              accumulator = closure.call([accumulator, element]);
            } else {
              if (accumulator is num && element is num) {
                accumulator = accumulator + element;
              }
            }
          }
          return accumulator;
        case 'slice':
          final start = args.isNotEmpty ? args[0] as int : 0;
          final end = args.length > 1 ? args[1] as int : object.length;
          return object.sublist(start, end);
        case 'reverse':
          return object.reversed.toList();
        case 'sort':
          final copy = List<dynamic>.from(object);
          if (args.isNotEmpty && args[0] is _LambdaClosure) {
            final closure = args[0] as _LambdaClosure;
            copy.sort((a, b) {
              final result = closure.call([a, b]);
              return (result as num).toInt();
            });
          } else {
            copy.sort((a, b) => _compare(a, b));
          }
          return copy;
        case 'find':
          if (args.isEmpty || args[0] is! _LambdaClosure) {
            throw EvaluationException('find requires a function argument');
          }
          final closure = args[0] as _LambdaClosure;
          for (final element in object) {
            if (_toBool(closure.call([element]))) {
              return element;
            }
          }
          return null;
        case 'every':
          if (args.isEmpty || args[0] is! _LambdaClosure) {
            throw EvaluationException('every requires a function argument');
          }
          final closure = args[0] as _LambdaClosure;
          return object.every((e) => _toBool(closure.call([e])));
        case 'some':
        case 'any':
          if (args.isEmpty || args[0] is! _LambdaClosure) {
            throw EvaluationException('some requires a function argument');
          }
          final closure = args[0] as _LambdaClosure;
          return object.any((e) => _toBool(closure.call([e])));
      }
    }

    // Map methods
    if (object is Map) {
      switch (method) {
        case 'keys':
          return object.keys.toList();
        case 'values':
          return object.values.toList();
        case 'entries':
          return object.entries
              .map((e) => {'key': e.key, 'value': e.value})
              .toList();
        case 'containsKey':
          if (args.isEmpty) return false;
          return object.containsKey(args[0]);
        case 'containsValue':
          if (args.isEmpty) return false;
          return object.containsValue(args[0]);
      }
    }

    throw EvaluationException(
        'Unknown method "$method" on ${object.runtimeType}');
  }

  dynamic _applyPipe(dynamic value, Expr filter) {
    // Pipe filter can be identifier (simple filter) or call (filter with args)
    if (filter is IdentifierExpr) {
      final filterName = filter.name.lexeme;
      return _applyFilter(value, filterName, <dynamic>[]);
    }

    if (filter is CallExpr) {
      if (filter.callee is IdentifierExpr) {
        final filterName = (filter.callee as IdentifierExpr).name.lexeme;
        final args = filter.arguments.map((a) => a.accept(this)).toList();
        return _applyFilter(value, filterName, args);
      }
    }

    throw EvaluationException('Invalid pipe filter: $filter');
  }

  dynamic _applyFilter(dynamic value, String filter, List<dynamic> args) {
    switch (filter) {
      case 'uppercase':
      case 'upper':
        return value?.toString().toUpperCase();

      case 'lowercase':
      case 'lower':
        return value?.toString().toLowerCase();

      case 'trim':
        return value?.toString().trim();

      case 'default':
        return value ?? (args.isNotEmpty ? args[0] : null);

      case 'json':
        return _toJson(value);

      case 'length':
        if (value is String) return value.length;
        if (value is List) return value.length;
        if (value is Map) return value.length;
        return 0;

      case 'first':
        if (value is List && value.isNotEmpty) return value.first;
        if (value is String && value.isNotEmpty) return value[0];
        return null;

      case 'last':
        if (value is List && value.isNotEmpty) return value.last;
        if (value is String && value.isNotEmpty) {
          return value[value.length - 1];
        }
        return null;

      case 'reverse':
        if (value is List) return value.reversed.toList();
        if (value is String) {
          return value.split('').reversed.join();
        }
        return value;

      case 'sort':
        if (value is List) {
          final copy = List<dynamic>.from(value);
          copy.sort((a, b) => _compare(a, b));
          return copy;
        }
        return value;

      case 'unique':
        if (value is List) return value.toSet().toList();
        return value;

      case 'join':
        if (value is List) {
          final separator = args.isNotEmpty ? args[0].toString() : ',';
          return value.join(separator);
        }
        return value?.toString();

      case 'split':
        if (value is String) {
          final separator = args.isNotEmpty ? args[0].toString() : ',';
          return value.split(separator);
        }
        return <dynamic>[value];

      case 'slice':
        final start = args.isNotEmpty ? args[0] as int : 0;
        final end = args.length > 1 ? args[1] as int? : null;
        if (value is List) {
          return value.sublist(start, end ?? value.length);
        }
        if (value is String) {
          return value.substring(start, end);
        }
        return value;

      case 'keys':
        if (value is Map) return value.keys.toList();
        return <dynamic>[];

      case 'values':
        if (value is Map) return value.values.toList();
        return <dynamic>[];

      case 'round':
        if (value is num) {
          final decimals = args.isNotEmpty ? args[0] as int : 0;
          final factor = _power(10, decimals);
          return (value * factor).round() / factor;
        }
        return value;

      case 'abs':
        if (value is num) return value.abs();
        return value;

      case 'format':
        return _format(value, args);

      default:
        // Try as a function call
        return context.functions.call(filter, [value, ...args]);
    }
  }

  String _toJson(dynamic value) {
    if (value == null) return 'null';
    if (value is bool) return value.toString();
    if (value is num) return value.toString();
    if (value is String) return '"${_escapeJson(value)}"';
    if (value is List) {
      return '[${value.map(_toJson).join(',')}]';
    }
    if (value is Map) {
      final entries = value.entries
          .map((e) => '"${_escapeJson(e.key.toString())}":${_toJson(e.value)}')
          .join(',');
      return '{$entries}';
    }
    return '"${_escapeJson(value.toString())}"';
  }

  String _escapeJson(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  String _format(dynamic value, List<dynamic> args) {
    if (value is num) {
      if (args.isNotEmpty && args[0] is String) {
        final format = args[0] as String;
        if (format.startsWith('%')) {
          if (format.contains('d')) {
            return value.toInt().toString();
          }
          if (format.contains('f')) {
            final match = RegExp(r'\.(\d+)').firstMatch(format);
            final decimals = match != null ? int.parse(match.group(1)!) : 2;
            return value.toStringAsFixed(decimals);
          }
        }
      }
      return value.toString();
    }
    if (value is DateTime) {
      if (args.isNotEmpty && args[0] is String) {
        return _formatDate(value, args[0] as String);
      }
      return value.toIso8601String();
    }
    return value.toString();
  }

  String _formatDate(DateTime date, String format) {
    var result = format;
    result = result.replaceAll('YYYY', date.year.toString().padLeft(4, '0'));
    result = result.replaceAll('MM', date.month.toString().padLeft(2, '0'));
    result = result.replaceAll('DD', date.day.toString().padLeft(2, '0'));
    result = result.replaceAll('HH', date.hour.toString().padLeft(2, '0'));
    result = result.replaceAll('mm', date.minute.toString().padLeft(2, '0'));
    result = result.replaceAll('ss', date.second.toString().padLeft(2, '0'));
    return result;
  }
}

/// Exception thrown during expression evaluation.
class EvaluationException implements Exception {
  EvaluationException(this.message);

  final String message;

  @override
  String toString() => 'EvaluationException: $message';
}

/// Internal closure representation for lambda expressions.
class _LambdaClosure {
  _LambdaClosure(this.parameters, this.body, this.parentContext);

  final List<String> parameters;
  final Expr body;
  final EvaluationContext parentContext;

  dynamic call(List<dynamic> arguments) {
    final localVars = <String, dynamic>{};
    for (var i = 0; i < parameters.length && i < arguments.length; i++) {
      localVars[parameters[i]] = arguments[i];
    }

    final childContext = parentContext.child(localVars);
    final evaluator = ExpressionEvaluator(childContext);
    return evaluator.evaluateOrThrow(body);
  }
}
