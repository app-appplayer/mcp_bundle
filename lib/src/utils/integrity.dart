/// Integrity utilities for MCP Bundle.
///
/// Provides content hashing and verification.
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import 'canonicalization.dart';

/// Supported hash algorithms.
enum HashAlgorithm {
  /// SHA-256 (default, recommended).
  sha256,

  /// SHA-384.
  sha384,

  /// SHA-512.
  sha512,

  /// MD5 (not recommended, for legacy support).
  md5,
}

/// Content hash with algorithm information.
class ContentHash {
  /// Hash algorithm used.
  final HashAlgorithm algorithm;

  /// Hash bytes.
  final Uint8List bytes;

  const ContentHash._({
    required this.algorithm,
    required this.bytes,
  });

  /// Create from bytes.
  factory ContentHash.fromBytes(
    HashAlgorithm algorithm,
    List<int> bytes,
  ) {
    return ContentHash._(
      algorithm: algorithm,
      bytes: Uint8List.fromList(bytes),
    );
  }

  /// Parse from string representation (algorithm:hex).
  factory ContentHash.parse(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid hash format: $value');
    }

    final algorithm = _parseAlgorithm(parts[0]);
    final bytes = _hexDecode(parts[1]);

    return ContentHash._(
      algorithm: algorithm,
      bytes: bytes,
    );
  }

  /// Get hex string representation.
  String get hex => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Get full string representation (algorithm:hex).
  @override
  String toString() => '${algorithm.name}:$hex';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ContentHash) return false;
    if (algorithm != other.algorithm) return false;
    if (bytes.length != other.bytes.length) return false;

    // Constant-time comparison for security
    var result = 0;
    for (var i = 0; i < bytes.length; i++) {
      result |= bytes[i] ^ other.bytes[i];
    }
    return result == 0;
  }

  @override
  int get hashCode => Object.hash(algorithm, hex);

  static HashAlgorithm _parseAlgorithm(String name) {
    switch (name.toLowerCase()) {
      case 'sha256':
      case 'sha-256':
        return HashAlgorithm.sha256;
      case 'sha384':
      case 'sha-384':
        return HashAlgorithm.sha384;
      case 'sha512':
      case 'sha-512':
        return HashAlgorithm.sha512;
      case 'md5':
        return HashAlgorithm.md5;
      default:
        throw FormatException('Unknown hash algorithm: $name');
    }
  }

  static Uint8List _hexDecode(String hex) {
    if (hex.length % 2 != 0) {
      throw FormatException('Invalid hex string length');
    }

    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }
}

/// Integrity checker for MCP bundles.
class IntegrityChecker {
  /// Hash algorithm to use.
  final HashAlgorithm algorithm;

  /// Canonicalizer for JSON normalization.
  final Canonicalizer _canonicalizer;

  const IntegrityChecker({
    this.algorithm = HashAlgorithm.sha256,
    Canonicalizer canonicalizer = const Canonicalizer(),
  }) : _canonicalizer = canonicalizer;

  /// Compute hash of raw bytes.
  ContentHash hashBytes(List<int> bytes) {
    final digest = _getDigest(algorithm);
    final hash = digest.convert(bytes);
    return ContentHash.fromBytes(algorithm, hash.bytes);
  }

  /// Compute hash of string content.
  ContentHash hashString(String content) {
    return hashBytes(utf8.encode(content));
  }

  /// Compute hash of JSON value (canonicalized).
  ContentHash hashJson(dynamic value) {
    final canonical = _canonicalizer.canonicalizeToBytes(value);
    return hashBytes(canonical);
  }

  /// Verify content against expected hash.
  bool verifyBytes(List<int> bytes, ContentHash expected) {
    final actual = ContentHash.fromBytes(
      expected.algorithm,
      _getDigest(expected.algorithm).convert(bytes).bytes,
    );
    return actual == expected;
  }

  /// Verify string content against expected hash.
  bool verifyString(String content, ContentHash expected) {
    return verifyBytes(utf8.encode(content), expected);
  }

  /// Verify JSON value against expected hash.
  bool verifyJson(dynamic value, ContentHash expected) {
    final canonical = _canonicalizer.canonicalizeToBytes(value);
    return verifyBytes(canonical, expected);
  }

  /// Verify hash string format.
  bool verifyHashString(List<int> bytes, String hashString) {
    try {
      final expected = ContentHash.parse(hashString);
      return verifyBytes(bytes, expected);
    } catch (_) {
      return false;
    }
  }

  Hash _getDigest(HashAlgorithm algo) {
    switch (algo) {
      case HashAlgorithm.sha256:
        return sha256;
      case HashAlgorithm.sha384:
        return sha384;
      case HashAlgorithm.sha512:
        return sha512;
      case HashAlgorithm.md5:
        return md5;
    }
  }
}

/// Bundle integrity verification result.
class IntegrityResult {
  /// Whether the bundle is valid.
  final bool isValid;

  /// List of integrity errors.
  final List<IntegrityError> errors;

  /// Computed hashes.
  final Map<String, ContentHash> hashes;

  const IntegrityResult({
    required this.isValid,
    this.errors = const [],
    this.hashes = const {},
  });

  /// Create a valid result.
  const IntegrityResult.valid({
    this.hashes = const {},
  })  : isValid = true,
        errors = const [];

  /// Create an invalid result.
  const IntegrityResult.invalid({
    required this.errors,
    this.hashes = const {},
  }) : isValid = false;
}

/// Integrity error.
class IntegrityError {
  /// Error type.
  final IntegrityErrorType type;

  /// Resource path with the error.
  final String? path;

  /// Error message.
  final String message;

  /// Expected hash.
  final String? expectedHash;

  /// Actual hash.
  final String? actualHash;

  const IntegrityError({
    required this.type,
    this.path,
    required this.message,
    this.expectedHash,
    this.actualHash,
  });

  @override
  String toString() {
    final buffer = StringBuffer('IntegrityError: $message');
    if (path != null) buffer.write(' (path: $path)');
    return buffer.toString();
  }
}

/// Types of integrity errors.
enum IntegrityErrorType {
  /// Hash mismatch.
  hashMismatch,

  /// Missing hash.
  missingHash,

  /// Invalid hash format.
  invalidHashFormat,

  /// Missing content.
  missingContent,

  /// Invalid content.
  invalidContent,
}

/// Default integrity checker instance.
const integrityChecker = IntegrityChecker();

/// Compute SHA-256 hash of bytes.
ContentHash sha256Hash(List<int> bytes) => integrityChecker.hashBytes(bytes);

/// Compute SHA-256 hash of string.
ContentHash sha256HashString(String content) =>
    integrityChecker.hashString(content);

/// Compute SHA-256 hash of JSON value.
ContentHash sha256HashJson(dynamic value) => integrityChecker.hashJson(value);

/// Verify content against hash.
bool verifyIntegrity(List<int> bytes, String hashString) =>
    integrityChecker.verifyHashString(bytes, hashString);
