/// Integrity and compatibility configuration models.
///
/// Contains integrity verification and compatibility requirements.
/// Design: 02-models-design.md Section 3.3 and Section 5
library;

/// Compatibility configuration for bundle requirements.
class CompatibilityConfig {
  /// Bundle schema version requirement.
  final String? schemaVersion;

  /// Generic requirements (package/version pairs).
  final Map<String, String> requirements;

  /// Minimum MCP runtime version.
  final String? minRuntimeVersion;

  /// Maximum MCP runtime version.
  final String? maxRuntimeVersion;

  /// Required features.
  final List<String> requiredFeatures;

  /// Incompatible with these bundles.
  final List<String> incompatibleWith;

  const CompatibilityConfig({
    this.schemaVersion,
    this.requirements = const {},
    this.minRuntimeVersion,
    this.maxRuntimeVersion,
    this.requiredFeatures = const [],
    this.incompatibleWith = const [],
  });

  /// Create from JSON.
  factory CompatibilityConfig.fromJson(Map<String, dynamic> json) {
    return CompatibilityConfig(
      schemaVersion: json['schemaVersion'] as String?,
      requirements: (json['requirements'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      minRuntimeVersion: json['minRuntimeVersion'] as String?,
      maxRuntimeVersion: json['maxRuntimeVersion'] as String?,
      requiredFeatures: (json['requiredFeatures'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      incompatibleWith: (json['incompatibleWith'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      if (schemaVersion != null) 'schemaVersion': schemaVersion,
      if (requirements.isNotEmpty) 'requirements': requirements,
      if (minRuntimeVersion != null) 'minRuntimeVersion': minRuntimeVersion,
      if (maxRuntimeVersion != null) 'maxRuntimeVersion': maxRuntimeVersion,
      if (requiredFeatures.isNotEmpty) 'requiredFeatures': requiredFeatures,
      if (incompatibleWith.isNotEmpty) 'incompatibleWith': incompatibleWith,
    };
  }

  /// Create a copy with modifications.
  CompatibilityConfig copyWith({
    String? schemaVersion,
    Map<String, String>? requirements,
    String? minRuntimeVersion,
    String? maxRuntimeVersion,
    List<String>? requiredFeatures,
    List<String>? incompatibleWith,
  }) {
    return CompatibilityConfig(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      requirements: requirements ?? this.requirements,
      minRuntimeVersion: minRuntimeVersion ?? this.minRuntimeVersion,
      maxRuntimeVersion: maxRuntimeVersion ?? this.maxRuntimeVersion,
      requiredFeatures: requiredFeatures ?? this.requiredFeatures,
      incompatibleWith: incompatibleWith ?? this.incompatibleWith,
    );
  }

  /// Check if all requirements are satisfied.
  bool checkCompatibility(Map<String, String> availableVersions) {
    for (final entry in requirements.entries) {
      final available = availableVersions[entry.key];
      if (available == null) return false;
      // Simple version check - in production, use semver parsing
      if (!_versionSatisfies(available, entry.value)) return false;
    }
    return true;
  }

  bool _versionSatisfies(String actual, String required) {
    // Basic implementation - should use proper semver in production
    if (required.startsWith('>=')) {
      return actual.compareTo(required.substring(2)) >= 0;
    }
    if (required.startsWith('>')) {
      return actual.compareTo(required.substring(1)) > 0;
    }
    if (required.startsWith('<=')) {
      return actual.compareTo(required.substring(2)) <= 0;
    }
    if (required.startsWith('<')) {
      return actual.compareTo(required.substring(1)) < 0;
    }
    if (required.startsWith('^')) {
      // Caret range - compatible with
      return actual.startsWith(required.substring(1).split('.').first);
    }
    return actual == required || required == '*';
  }
}

/// Integrity configuration for bundle verification.
class IntegrityConfig {
  /// Content hash of the bundle.
  final ContentHash? contentHash;

  /// Individual file hashes.
  final List<FileHash> files;

  /// Digital signatures.
  final List<Signature> signatures;

  /// Timestamp of integrity computation.
  final DateTime? computedAt;

  const IntegrityConfig({
    this.contentHash,
    this.files = const [],
    this.signatures = const [],
    this.computedAt,
  });

  /// Create from JSON.
  factory IntegrityConfig.fromJson(Map<String, dynamic> json) {
    return IntegrityConfig(
      contentHash: json['contentHash'] != null
          ? ContentHash.fromJson(json['contentHash'] as Map<String, dynamic>)
          : null,
      files: (json['files'] as List<dynamic>?)
              ?.map((e) => FileHash.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      signatures: (json['signatures'] as List<dynamic>?)
              ?.map((e) => Signature.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      computedAt: json['computedAt'] != null
          ? DateTime.tryParse(json['computedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      if (contentHash != null) 'contentHash': contentHash!.toJson(),
      if (files.isNotEmpty) 'files': files.map((f) => f.toJson()).toList(),
      if (signatures.isNotEmpty)
        'signatures': signatures.map((s) => s.toJson()).toList(),
      if (computedAt != null) 'computedAt': computedAt!.toIso8601String(),
    };
  }

  /// Create a copy with modifications.
  IntegrityConfig copyWith({
    ContentHash? contentHash,
    List<FileHash>? files,
    List<Signature>? signatures,
    DateTime? computedAt,
  }) {
    return IntegrityConfig(
      contentHash: contentHash ?? this.contentHash,
      files: files ?? this.files,
      signatures: signatures ?? this.signatures,
      computedAt: computedAt ?? this.computedAt,
    );
  }

  /// Check if integrity configuration is valid.
  bool get isValid =>
      contentHash != null || files.isNotEmpty || signatures.isNotEmpty;
}

/// Content hash for bundle verification.
class ContentHash {
  /// Hash algorithm: "sha256", "sha384", "sha512".
  final HashAlgorithm algorithm;

  /// Hash value (hex encoded).
  final String value;

  /// Scope of hash computation.
  final ContentScope scope;

  /// Excluded paths from hash computation.
  final List<String> excludedPaths;

  const ContentHash({
    required this.algorithm,
    required this.value,
    this.scope = ContentScope.canonicalJson,
    this.excludedPaths = const [],
  });

  /// Create from JSON.
  factory ContentHash.fromJson(Map<String, dynamic> json) {
    return ContentHash(
      algorithm: HashAlgorithm.fromString(json['algorithm'] as String?),
      value: json['value'] as String? ?? '',
      scope: ContentScope.fromString(json['scope'] as String?),
      excludedPaths: (json['excludedPaths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'algorithm': algorithm.name,
      'value': value,
      'scope': scope.name,
      if (excludedPaths.isNotEmpty) 'excludedPaths': excludedPaths,
    };
  }

  /// Create a copy with modifications.
  ContentHash copyWith({
    HashAlgorithm? algorithm,
    String? value,
    ContentScope? scope,
    List<String>? excludedPaths,
  }) {
    return ContentHash(
      algorithm: algorithm ?? this.algorithm,
      value: value ?? this.value,
      scope: scope ?? this.scope,
      excludedPaths: excludedPaths ?? this.excludedPaths,
    );
  }

  /// Verify hash against computed value.
  bool verify(String computedHash) {
    return value.toLowerCase() == computedHash.toLowerCase();
  }
}

/// Hash algorithms supported.
enum HashAlgorithm {
  sha256,
  sha384,
  sha512,
  md5,
  unknown;

  static HashAlgorithm fromString(String? value) {
    switch (value?.toLowerCase()) {
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
        return HashAlgorithm.unknown;
    }
  }
}

/// Scope of hash computation.
enum ContentScope {
  /// Hash of canonical JSON representation.
  canonicalJson,

  /// Hash of content sections only.
  contentSections,

  /// Hash of all files.
  allFiles,

  /// Custom scope.
  custom;

  static ContentScope fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'canonical_json':
      case 'canonicaljson':
        return ContentScope.canonicalJson;
      case 'content_sections':
      case 'contentsections':
        return ContentScope.contentSections;
      case 'all_files':
      case 'allfiles':
        return ContentScope.allFiles;
      case 'custom':
        return ContentScope.custom;
      default:
        return ContentScope.canonicalJson;
    }
  }
}

/// Individual file hash.
class FileHash {
  /// File path relative to bundle root.
  final String path;

  /// Hash algorithm.
  final HashAlgorithm algorithm;

  /// Hash value (hex encoded).
  final String value;

  /// File size in bytes.
  final int? size;

  /// Last modified timestamp.
  final DateTime? modifiedAt;

  const FileHash({
    required this.path,
    required this.algorithm,
    required this.value,
    this.size,
    this.modifiedAt,
  });

  /// Create from JSON.
  factory FileHash.fromJson(Map<String, dynamic> json) {
    return FileHash(
      path: json['path'] as String? ?? '',
      algorithm: HashAlgorithm.fromString(json['algorithm'] as String?),
      value: json['value'] as String? ?? '',
      size: json['size'] as int?,
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.tryParse(json['modifiedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'algorithm': algorithm.name,
      'value': value,
      if (size != null) 'size': size,
      if (modifiedAt != null) 'modifiedAt': modifiedAt!.toIso8601String(),
    };
  }

  /// Create a copy with modifications.
  FileHash copyWith({
    String? path,
    HashAlgorithm? algorithm,
    String? value,
    int? size,
    DateTime? modifiedAt,
  }) {
    return FileHash(
      path: path ?? this.path,
      algorithm: algorithm ?? this.algorithm,
      value: value ?? this.value,
      size: size ?? this.size,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  /// Verify hash against computed value.
  bool verify(String computedHash) {
    return value.toLowerCase() == computedHash.toLowerCase();
  }
}

/// Digital signature for bundle.
class Signature {
  /// Key identifier.
  final String keyId;

  /// Signature algorithm.
  final SignatureAlgorithm algorithm;

  /// Signature value (base64 encoded).
  final String value;

  /// Timestamp of signature.
  final DateTime? timestamp;

  /// Reference to signed payload.
  final SignedPayloadRef signedPayload;

  /// Certificate chain (PEM encoded).
  final String? certificate;

  /// Signer identity.
  final String? signer;

  const Signature({
    required this.keyId,
    required this.algorithm,
    required this.value,
    this.timestamp,
    required this.signedPayload,
    this.certificate,
    this.signer,
  });

  /// Create from JSON.
  factory Signature.fromJson(Map<String, dynamic> json) {
    return Signature(
      keyId: json['keyId'] as String? ?? '',
      algorithm: SignatureAlgorithm.fromString(json['algorithm'] as String?),
      value: json['value'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      signedPayload: SignedPayloadRef.fromJson(
        json['signedPayload'] as Map<String, dynamic>? ?? {},
      ),
      certificate: json['certificate'] as String?,
      signer: json['signer'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'keyId': keyId,
      'algorithm': algorithm.name,
      'value': value,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      'signedPayload': signedPayload.toJson(),
      if (certificate != null) 'certificate': certificate,
      if (signer != null) 'signer': signer,
    };
  }

  /// Create a copy with modifications.
  Signature copyWith({
    String? keyId,
    SignatureAlgorithm? algorithm,
    String? value,
    DateTime? timestamp,
    SignedPayloadRef? signedPayload,
    String? certificate,
    String? signer,
  }) {
    return Signature(
      keyId: keyId ?? this.keyId,
      algorithm: algorithm ?? this.algorithm,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      signedPayload: signedPayload ?? this.signedPayload,
      certificate: certificate ?? this.certificate,
      signer: signer ?? this.signer,
    );
  }
}

/// Signature algorithms supported.
enum SignatureAlgorithm {
  rsaSha256,
  rsaSha384,
  rsaSha512,
  ecdsaP256,
  ecdsaP384,
  ed25519,
  unknown;

  static SignatureAlgorithm fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'rsa-sha256':
      case 'rsasha256':
      case 'rs256':
        return SignatureAlgorithm.rsaSha256;
      case 'rsa-sha384':
      case 'rsasha384':
      case 'rs384':
        return SignatureAlgorithm.rsaSha384;
      case 'rsa-sha512':
      case 'rsasha512':
      case 'rs512':
        return SignatureAlgorithm.rsaSha512;
      case 'ecdsa-p256':
      case 'ecdsap256':
      case 'es256':
        return SignatureAlgorithm.ecdsaP256;
      case 'ecdsa-p384':
      case 'ecdsap384':
      case 'es384':
        return SignatureAlgorithm.ecdsaP384;
      case 'ed25519':
        return SignatureAlgorithm.ed25519;
      default:
        return SignatureAlgorithm.unknown;
    }
  }
}

/// Reference to signed payload.
class SignedPayloadRef {
  /// Type of payload reference.
  final PayloadRefType type;

  /// Hash of the signed content.
  final String? hash;

  /// Hash algorithm used.
  final HashAlgorithm? hashAlgorithm;

  /// URL to the payload (for external payloads).
  final String? url;

  const SignedPayloadRef({
    required this.type,
    this.hash,
    this.hashAlgorithm,
    this.url,
  });

  /// Create from JSON.
  factory SignedPayloadRef.fromJson(Map<String, dynamic> json) {
    return SignedPayloadRef(
      type: PayloadRefType.fromString(json['type'] as String?),
      hash: json['hash'] as String?,
      hashAlgorithm: json['hashAlgorithm'] != null
          ? HashAlgorithm.fromString(json['hashAlgorithm'] as String?)
          : null,
      url: json['url'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (hash != null) 'hash': hash,
      if (hashAlgorithm != null) 'hashAlgorithm': hashAlgorithm!.name,
      if (url != null) 'url': url,
    };
  }

  /// Create a copy with modifications.
  SignedPayloadRef copyWith({
    PayloadRefType? type,
    String? hash,
    HashAlgorithm? hashAlgorithm,
    String? url,
  }) {
    return SignedPayloadRef(
      type: type ?? this.type,
      hash: hash ?? this.hash,
      hashAlgorithm: hashAlgorithm ?? this.hashAlgorithm,
      url: url ?? this.url,
    );
  }
}

/// Type of payload reference.
enum PayloadRefType {
  /// Content hash reference.
  contentHash,

  /// Manifest only.
  manifest,

  /// All sections.
  allSections,

  /// External URL.
  external,

  /// Unknown type.
  unknown;

  static PayloadRefType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'content_hash':
      case 'contenthash':
        return PayloadRefType.contentHash;
      case 'manifest':
        return PayloadRefType.manifest;
      case 'all_sections':
      case 'allsections':
        return PayloadRefType.allSections;
      case 'external':
        return PayloadRefType.external;
      default:
        return PayloadRefType.unknown;
    }
  }
}
