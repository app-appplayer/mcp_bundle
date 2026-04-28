/// Type coercion rules and utilities for flexible JSON parsing.
library;

import 'exceptions.dart';

/// Type coercion rules for flexible parsing.
class TypeCoercionRules {
  /// Coerce string numbers to num: "42" -> 42.
  final bool stringToNumber;

  /// Coerce string "true"/"false" to bool.
  final bool stringToBool;

  /// Coerce number to bool: 1 -> true, 0 -> false.
  final bool numberToBool;

  /// Coerce single items to list: value -> [value].
  final bool singleToList;

  const TypeCoercionRules({
    this.stringToNumber = false,
    this.stringToBool = false,
    this.numberToBool = false,
    this.singleToList = false,
  });

  /// Strict coercion rules - no coercions enabled.
  const TypeCoercionRules.strict()
      : stringToNumber = false,
        stringToBool = false,
        numberToBool = false,
        singleToList = false;

  /// Lenient coercion rules - all coercions enabled.
  const TypeCoercionRules.lenient()
      : stringToNumber = true,
        stringToBool = true,
        numberToBool = true,
        singleToList = true;
}

/// Type coercion utility for parsing values.
class TypeCoercer {
  final TypeCoercionRules rules;

  TypeCoercer(this.rules);

  /// Coerce value to expected type.
  T? coerce<T>(dynamic value, {T? defaultValue}) {
    if (value == null) {
      return defaultValue;
    }

    if (value is T) return value;

    // String to bool
    if (T == bool && value is String && rules.stringToBool) {
      final lower = value.toLowerCase();
      if (lower == 'true') return true as T;
      if (lower == 'false') return false as T;
    }

    // Number to bool
    if (T == bool && value is num && rules.numberToBool) {
      if (value == 1) return true as T;
      if (value == 0) return false as T;
    }

    // String to number
    if ((T == int || T == double || T == num) &&
        value is String &&
        rules.stringToNumber) {
      final parsed = num.tryParse(value);
      if (parsed != null) {
        if (T == int) return parsed.toInt() as T;
        if (T == double) return parsed.toDouble() as T;
        return parsed as T;
      }
    }

    // Single to array
    if (rules.singleToList) {
      if (_isListType<T>() && value is! List) {
        return [value] as T;
      }
    }

    return null;
  }

  /// Parse required field with coercion.
  T parseRequired<T>(
    Map<String, dynamic> json,
    String field,
    List<BundleLoadException> errors, {
    T? defaultValue,
  }) {
    final value = json[field];

    // Record error if the field is missing from the source JSON
    if (!json.containsKey(field) || value == null) {
      final error = BundleMissingFieldException(field);
      errors.add(error);
      if (defaultValue != null) return defaultValue;
      throw error;
    }

    final coerced = coerce<T>(value);
    if (coerced == null) {
      final error = BundleMissingFieldException(field);
      errors.add(error);
      if (defaultValue != null) return defaultValue;
      throw error;
    }

    return coerced;
  }

  /// Parse optional field with coercion.
  T? parseOptional<T>(
    Map<String, dynamic> json,
    String field, {
    T? defaultValue,
  }) {
    final value = json[field];
    return coerce<T>(value, defaultValue: defaultValue) ?? defaultValue;
  }

  /// Parse list field with coercion.
  List<T> parseList<T>(
    Map<String, dynamic> json,
    String field, {
    List<T>? defaultValue,
    T Function(dynamic)? itemParser,
  }) {
    final value = json[field];
    if (value == null) {
      return defaultValue ?? [];
    }

    List<dynamic> items;
    if (value is List) {
      items = value;
    } else if (rules.singleToList) {
      items = [value];
    } else {
      return defaultValue ?? [];
    }

    if (itemParser != null) {
      return items.map(itemParser).toList();
    }

    return items.whereType<T>().toList();
  }

  bool _isListType<T>() {
    return T.toString().startsWith('List<');
  }
}

/// Error recovery strategy.
enum RecoveryStrategy {
  /// Skip the problematic field/section.
  skip,

  /// Use default value.
  useDefault,

  /// Attempt repair (e.g., type coercion).
  repair,

  /// Fail immediately.
  fail,
}

/// Error recovery handler for bundle loading.
class ErrorRecoveryHandler {
  final TypeCoercionRules coercionRules;
  final bool allowPartialLoad;

  ErrorRecoveryHandler({
    required this.coercionRules,
    required this.allowPartialLoad,
  });

  /// Handle missing required field.
  T? handleMissingField<T>(
    String fieldPath,
    List<BundleLoadException> errors,
    List<String> warnings, {
    T? defaultValue,
    RecoveryStrategy strategy = RecoveryStrategy.fail,
  }) {
    final error = BundleMissingFieldException(fieldPath);

    switch (strategy) {
      case RecoveryStrategy.skip:
        warnings.add('Missing field $fieldPath - skipped');
        return null;

      case RecoveryStrategy.useDefault:
        if (defaultValue != null) {
          warnings.add('Missing field $fieldPath - using default: $defaultValue');
          return defaultValue;
        }
        errors.add(error);
        return null;

      case RecoveryStrategy.repair:
        warnings.add('Missing field $fieldPath - repair attempted');
        return defaultValue;

      case RecoveryStrategy.fail:
        errors.add(error);
        if (!allowPartialLoad) throw error;
        return null;
    }
  }

  /// Handle invalid value.
  T? handleInvalidValue<T>(
    String fieldPath,
    dynamic value,
    String expectedType,
    List<BundleLoadException> errors,
    List<String> warnings, {
    T? defaultValue,
    RecoveryStrategy strategy = RecoveryStrategy.fail,
  }) {
    final error = BundleInvalidValueException(fieldPath, value, expectedType);

    switch (strategy) {
      case RecoveryStrategy.skip:
        warnings.add('Invalid value at $fieldPath - skipped');
        return null;

      case RecoveryStrategy.useDefault:
        warnings.add('Invalid value at $fieldPath - using default: $defaultValue');
        return defaultValue;

      case RecoveryStrategy.repair:
        final coercer = TypeCoercer(coercionRules);
        final coerced = coercer.coerce<T>(value, defaultValue: defaultValue);
        if (coerced != null) {
          warnings.add('Invalid value at $fieldPath - coerced to $coerced');
          return coerced;
        }
        errors.add(error);
        return defaultValue;

      case RecoveryStrategy.fail:
        errors.add(error);
        if (!allowPartialLoad) throw error;
        return null;
    }
  }
}
