/// Validation result types for bundle validation.
library;

/// Result of bundle validation.
class ValidationResult {
  /// Whether validation passed.
  final bool isValid;

  /// List of validation errors.
  final List<ValidationError> errors;

  /// List of validation warnings.
  final List<ValidationWarning> warnings;

  /// Validation metadata.
  final Map<String, dynamic> metadata;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.metadata = const {},
  });

  /// Create a successful validation result.
  factory ValidationResult.valid({List<ValidationWarning>? warnings}) {
    return ValidationResult(
      isValid: true,
      warnings: warnings ?? [],
    );
  }

  /// Create a failed validation result.
  factory ValidationResult.invalid(List<ValidationError> errors, {
    List<ValidationWarning>? warnings,
  }) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings ?? [],
    );
  }

  /// Combine with another result.
  ValidationResult merge(ValidationResult other) {
    return ValidationResult(
      isValid: isValid && other.isValid,
      errors: [...errors, ...other.errors],
      warnings: [...warnings, ...other.warnings],
      metadata: {...metadata, ...other.metadata},
    );
  }

  /// Get all issues (errors and warnings).
  List<ValidationIssue> get allIssues => [...errors, ...warnings];

  /// Check if there are any warnings.
  bool get hasWarnings => warnings.isNotEmpty;

  /// Check if there are any errors.
  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() {
    if (isValid && warnings.isEmpty) {
      return 'ValidationResult: Valid';
    }
    final buffer = StringBuffer('ValidationResult: ');
    buffer.write(isValid ? 'Valid' : 'Invalid');
    if (errors.isNotEmpty) {
      buffer.write('\n  Errors:');
      for (final error in errors) {
        buffer.write('\n    - $error');
      }
    }
    if (warnings.isNotEmpty) {
      buffer.write('\n  Warnings:');
      for (final warning in warnings) {
        buffer.write('\n    - $warning');
      }
    }
    return buffer.toString();
  }
}

/// Base class for validation issues.
abstract class ValidationIssue {
  /// Issue code.
  String get code;

  /// Human-readable message.
  String get message;

  /// Location in the bundle where the issue was found.
  String? get location;

  /// Severity level.
  ValidationSeverity get severity;
}

/// Validation error (blocks validation).
class ValidationError implements ValidationIssue {
  @override
  final String code;

  @override
  final String message;

  @override
  final String? location;

  @override
  ValidationSeverity get severity => ValidationSeverity.error;

  const ValidationError({
    required this.code,
    required this.message,
    this.location,
  });

  /// Create a required field error.
  factory ValidationError.required(String field, {String? location}) {
    return ValidationError(
      code: 'REQUIRED_FIELD',
      message: 'Required field "$field" is missing',
      location: location,
    );
  }

  /// Create an invalid value error.
  factory ValidationError.invalidValue(
    String field,
    dynamic value, {
    String? expected,
    String? location,
  }) {
    final expectedStr = expected != null ? ', expected $expected' : '';
    return ValidationError(
      code: 'INVALID_VALUE',
      message: 'Invalid value for "$field": $value$expectedStr',
      location: location,
    );
  }

  /// Create a type mismatch error.
  factory ValidationError.typeMismatch(
    String field,
    String expectedType,
    String actualType, {
    String? location,
  }) {
    return ValidationError(
      code: 'TYPE_MISMATCH',
      message: 'Type mismatch for "$field": expected $expectedType, got $actualType',
      location: location,
    );
  }

  /// Create a reference error.
  factory ValidationError.unresolvedRef(String ref, {String? location}) {
    return ValidationError(
      code: 'UNRESOLVED_REF',
      message: 'Unresolved reference: $ref',
      location: location,
    );
  }

  /// Create a duplicate error.
  factory ValidationError.duplicate(String field, String value, {String? location}) {
    return ValidationError(
      code: 'DUPLICATE',
      message: 'Duplicate $field: $value',
      location: location,
    );
  }

  /// Create a constraint violation error.
  factory ValidationError.constraint(
    String field,
    String constraint, {
    String? location,
  }) {
    return ValidationError(
      code: 'CONSTRAINT_VIOLATION',
      message: 'Constraint violation for "$field": $constraint',
      location: location,
    );
  }

  @override
  String toString() {
    final loc = location != null ? ' at $location' : '';
    return '[$code] $message$loc';
  }
}

/// Validation warning (non-blocking issue).
class ValidationWarning implements ValidationIssue {
  @override
  final String code;

  @override
  final String message;

  @override
  final String? location;

  @override
  ValidationSeverity get severity => ValidationSeverity.warning;

  const ValidationWarning({
    required this.code,
    required this.message,
    this.location,
  });

  /// Create a deprecation warning.
  factory ValidationWarning.deprecated(
    String field, {
    String? replacement,
    String? location,
  }) {
    final replaceStr = replacement != null ? ', use "$replacement" instead' : '';
    return ValidationWarning(
      code: 'DEPRECATED',
      message: '"$field" is deprecated$replaceStr',
      location: location,
    );
  }

  /// Create a best practice warning.
  factory ValidationWarning.bestPractice(String message, {String? location}) {
    return ValidationWarning(
      code: 'BEST_PRACTICE',
      message: message,
      location: location,
    );
  }

  /// Create a performance warning.
  factory ValidationWarning.performance(String message, {String? location}) {
    return ValidationWarning(
      code: 'PERFORMANCE',
      message: message,
      location: location,
    );
  }

  @override
  String toString() {
    final loc = location != null ? ' at $location' : '';
    return '[$code] $message$loc';
  }
}

/// Severity levels for validation issues.
enum ValidationSeverity {
  /// Informational message.
  info,

  /// Warning (non-blocking).
  warning,

  /// Error (blocks validation).
  error,

  /// Critical error.
  critical,
}

/// Validation context for tracking state during validation.
class ValidationContext {
  final List<ValidationError> _errors = [];
  final List<ValidationWarning> _warnings = [];
  final List<String> _path = [];

  /// Current path in the bundle being validated.
  String get currentPath => _path.join('.');

  /// Push a path segment.
  void pushPath(String segment) => _path.add(segment);

  /// Pop a path segment.
  void popPath() {
    if (_path.isNotEmpty) _path.removeLast();
  }

  /// Add an error.
  void addError(ValidationError error) => _errors.add(error);

  /// Add a warning.
  void addWarning(ValidationWarning warning) => _warnings.add(warning);

  /// Add a required field error.
  void addRequiredError(String field) {
    addError(ValidationError.required(field, location: currentPath));
  }

  /// Add an invalid value error.
  void addInvalidValueError(String field, dynamic value, {String? expected}) {
    addError(ValidationError.invalidValue(
      field,
      value,
      expected: expected,
      location: currentPath,
    ));
  }

  /// Build the validation result.
  ValidationResult toResult() {
    return ValidationResult(
      isValid: _errors.isEmpty,
      errors: List.unmodifiable(_errors),
      warnings: List.unmodifiable(_warnings),
    );
  }

  /// Execute validation within a path context.
  T withPath<T>(String segment, T Function() action) {
    pushPath(segment);
    try {
      return action();
    } finally {
      popPath();
    }
  }
}
