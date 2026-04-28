/// Bundle loading exceptions.
///
/// Provides a hierarchy of exceptions for bundle loading errors.
library;

/// Base exception for bundle loading errors.
class BundleLoadException implements Exception {
  /// Error message.
  final String message;

  /// Underlying cause of the error.
  final dynamic cause;

  BundleLoadException(this.message, [this.cause]);

  @override
  String toString() => 'BundleLoadException: $message';
}

/// JSON parsing error with location information.
class BundleParseException extends BundleLoadException {
  /// Line number where error occurred.
  final int? line;

  /// Column number where error occurred.
  final int? column;

  BundleParseException(
    super.message, {
    this.line,
    this.column,
  });

  @override
  String toString() {
    final location = line != null ? ' at line $line' : '';
    return 'BundleParseException: $message$location';
  }
}

/// Missing required field error.
class BundleMissingFieldException extends BundleLoadException {
  /// Path to the missing field.
  final String fieldPath;

  BundleMissingFieldException(this.fieldPath)
      : super('Missing required field: $fieldPath');

  @override
  String toString() => 'BundleMissingFieldException: Missing field "$fieldPath"';
}

/// Invalid field value error.
class BundleInvalidValueException extends BundleLoadException {
  /// Path to the field with invalid value.
  final String fieldPath;

  /// The invalid value.
  final dynamic value;

  /// Expected type description.
  final String expectedType;

  BundleInvalidValueException(this.fieldPath, this.value, this.expectedType)
      : super('Invalid value at $fieldPath: expected $expectedType, got ${value.runtimeType}');

  @override
  String toString() =>
      'BundleInvalidValueException: Invalid value at "$fieldPath": expected $expectedType';
}

/// Schema version incompatibility error.
class BundleSchemaVersionException extends BundleLoadException {
  /// Schema version found in bundle.
  final String foundVersion;

  /// Supported schema versions.
  final List<String> supportedVersions;

  BundleSchemaVersionException(this.foundVersion, this.supportedVersions)
      : super('Unsupported schema version: $foundVersion');

  @override
  String toString() =>
      'BundleSchemaVersionException: Schema version "$foundVersion" not supported. '
      'Supported: ${supportedVersions.join(", ")}';
}

/// Reference validation error.
class BundleReferenceException extends BundleLoadException {
  /// The unresolved reference.
  final String reference;

  /// Type of reference (asset, skill, profile, etc.).
  final String referenceType;

  BundleReferenceException(this.reference, this.referenceType)
      : super('Unresolved $referenceType reference: $reference');

  @override
  String toString() =>
      'BundleReferenceException: Unresolved $referenceType reference "$reference"';
}

/// Validation exception with multiple errors.
class BundleValidationException extends BundleLoadException {
  /// List of validation errors.
  final List<BundleLoadException> errors;

  /// List of validation warnings.
  final List<String> warnings;

  BundleValidationException(
    super.message, {
    this.errors = const [],
    this.warnings = const [],
  });

  @override
  String toString() {
    final errorCount = errors.length;
    final warningCount = warnings.length;
    return 'BundleValidationException: $message '
        '($errorCount errors, $warningCount warnings)';
  }
}

/// Bundle not found exception.
class BundleNotFoundException extends BundleLoadException {
  /// URI of the bundle that was not found.
  final Uri uri;

  BundleNotFoundException(this.uri) : super('Bundle not found: $uri');

  @override
  String toString() => 'BundleNotFoundException: Bundle not found at "$uri"';
}

/// Asset not found exception.
class AssetNotFoundException extends BundleLoadException {
  /// URI of the asset that was not found.
  final Uri uri;

  AssetNotFoundException(this.uri) : super('Asset not found: $uri');

  @override
  String toString() => 'AssetNotFoundException: Asset not found at "$uri"';
}

/// Bundle write exception.
class BundleWriteException extends BundleLoadException {
  /// URI where the write failed.
  final Uri? uri;

  BundleWriteException(super.message, {this.uri});

  @override
  String toString() {
    final location = uri != null ? ' at "$uri"' : '';
    return 'BundleWriteException: $message$location';
  }
}

/// Bundle read exception.
class BundleReadException extends BundleLoadException {
  /// URI where the read failed.
  final Uri? uri;

  BundleReadException(super.message, {this.uri});

  @override
  String toString() {
    final location = uri != null ? ' at "$uri"' : '';
    return 'BundleReadException: $message$location';
  }
}

/// Raised when a `.mcpb` does not start with the ZIP magic bytes or is
/// otherwise not a parseable container.
class BundleFormatException extends BundleLoadException {
  BundleFormatException(super.message);

  @override
  String toString() => 'BundleFormatException: $message';
}

/// Raised when the install lock cannot be acquired (another installer is
/// running against the same `installRoot`).
class BundleBusyException extends BundleLoadException {
  /// The installRoot that could not be locked.
  final String installRoot;

  BundleBusyException(this.installRoot)
      : super('Install root is busy: $installRoot');

  @override
  String toString() =>
      'BundleBusyException: Install root is busy: $installRoot';
}

/// Raised when a bundle with the same id is already installed and the
/// caller requested `InstallConflictPolicy.failIfExists`.
class BundleAlreadyInstalledException extends BundleLoadException {
  /// Installed bundle id.
  final String id;

  /// Version currently on disk.
  final String existingVersion;

  BundleAlreadyInstalledException(this.id, this.existingVersion)
      : super('Bundle already installed: $id @ $existingVersion');

  @override
  String toString() =>
      'BundleAlreadyInstalledException: $id @ $existingVersion';
}

/// Raised when a declared signature cannot be verified or when an
/// installation policy requires a signature that is missing.
class BundleSignatureException extends BundleLoadException {
  /// Key identifier referenced by the rejected signature.
  final String? keyId;

  BundleSignatureException(super.message, {this.keyId});

  @override
  String toString() {
    final key = keyId != null ? ' (keyId: $keyId)' : '';
    return 'BundleSignatureException: $message$key';
  }
}

/// Raised when a bundle's `CompatibilityConfig` is not satisfied by the
/// runtime supplied at install time.
class BundleCompatibilityException extends BundleLoadException {
  /// Reason code: `schemaVersion`, `runtimeVersion`, `requiredFeature`,
  /// `incompatibleWith`.
  final String reason;

  BundleCompatibilityException(super.message, {required this.reason});

  @override
  String toString() => 'BundleCompatibilityException[$reason]: $message';
}

/// Raised when a `.mcpb` exceeds a `InstallLimits` cap.
class BundleLimitException extends BundleLoadException {
  /// Name of the violated limit.
  final String limit;

  /// Observed value.
  final int observed;

  /// Declared cap.
  final int cap;

  BundleLimitException({
    required this.limit,
    required this.observed,
    required this.cap,
  }) : super('Install limit exceeded: $limit ($observed > $cap)');

  @override
  String toString() =>
      'BundleLimitException: $limit exceeded ($observed > $cap)';
}

/// Bundle integrity verification exception.
class BundleIntegrityException extends BundleLoadException {
  /// Type of integrity check that failed.
  final String checkType;

  /// Expected value.
  final String? expected;

  /// Actual value found.
  final String? actual;

  BundleIntegrityException(
    super.message, {
    required this.checkType,
    this.expected,
    this.actual,
  });

  @override
  String toString() {
    final details = expected != null && actual != null
        ? ' (expected: $expected, actual: $actual)'
        : '';
    return 'BundleIntegrityException: $checkType check failed$details - $message';
  }
}
