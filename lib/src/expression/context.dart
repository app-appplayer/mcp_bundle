/// Evaluation context for Expression Language.
///
/// Provides variable bindings and function registry for expression evaluation.
library;

import 'functions.dart';

/// Context for expression evaluation.
class EvaluationContext {
  final Map<String, dynamic> _variables;
  final EvaluationContext? _parent;
  final ExpressionFunctions functions;

  EvaluationContext({
    Map<String, dynamic>? variables,
    EvaluationContext? parent,
    ExpressionFunctions? functions,
  })  : _variables = variables ?? {},
        _parent = parent,
        functions = functions ?? ExpressionFunctions();

  /// Create a child context with additional variables.
  EvaluationContext child([Map<String, dynamic>? variables]) {
    return EvaluationContext(
      variables: variables,
      parent: this,
      functions: functions,
    );
  }

  /// Get a variable value by name.
  dynamic get(String name) {
    if (_variables.containsKey(name)) {
      return _variables[name];
    }
    final parent = _parent;
    if (parent != null) {
      return parent.get(name);
    }
    return null;
  }

  /// Check if a variable exists.
  bool has(String name) {
    if (_variables.containsKey(name)) {
      return true;
    }
    final parent = _parent;
    if (parent != null) {
      return parent.has(name);
    }
    return false;
  }

  /// Set a variable value.
  void set(String name, dynamic value) {
    _variables[name] = value;
  }

  /// Get all variables (including parent).
  Map<String, dynamic> get allVariables {
    final result = <String, dynamic>{};
    final parent = _parent;
    if (parent != null) {
      result.addAll(parent.allVariables);
    }
    result.addAll(_variables);
    return result;
  }

  /// Create context from common structures.
  factory EvaluationContext.from({
    Map<String, dynamic>? inputs,
    Map<String, dynamic>? steps,
    Map<String, dynamic>? context,
    Map<String, dynamic>? state,
    Map<String, dynamic>? extra,
  }) {
    return EvaluationContext(
      variables: {
        if (inputs != null) 'inputs': inputs,
        if (steps != null) 'steps': steps,
        if (context != null) 'context': context,
        if (state != null) 'state': state,
        ...?extra,
      },
    );
  }
}

/// Result of expression evaluation.
class EvaluationResult {
  final dynamic value;
  final bool success;
  final String? error;

  const EvaluationResult.success(this.value)
      : success = true,
        error = null;

  const EvaluationResult.failure(this.error)
      : value = null,
        success = false;

  @override
  String toString() => success ? 'Success($value)' : 'Failure($error)';
}
