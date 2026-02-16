/// Bundle manifest model.
///
/// Contains metadata and configuration for the bundle.
library;

/// Version of the bundle schema.
const String currentSchemaVersion = '1.0.0';

/// Bundle manifest containing metadata and configuration.
class BundleManifest {
  /// Bundle identifier (unique).
  final String id;

  /// Human-readable name.
  final String name;

  /// Semantic version string.
  final String version;

  /// Provider/author identifier.
  final String? provider;

  /// Human-readable description.
  final String? description;

  /// Schema version this bundle conforms to.
  final String schemaVersion;

  /// Bundle type.
  final BundleType type;

  /// Main entry point.
  final String? entryPoint;

  /// License identifier (SPDX).
  final String? license;

  /// Homepage URL.
  final String? homepage;

  /// Repository URL.
  final String? repository;

  /// Required capabilities.
  final List<String> capabilities;

  /// Tags for categorization.
  final List<String> tags;

  /// Dependencies on other bundles.
  final List<BundleDependency> dependencies;

  /// Platform requirements.
  final PlatformRequirements? platform;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const BundleManifest({
    required this.id,
    required this.name,
    required this.version,
    this.provider,
    this.description,
    this.schemaVersion = currentSchemaVersion,
    this.type = BundleType.application,
    this.entryPoint,
    this.license,
    this.homepage,
    this.repository,
    this.capabilities = const [],
    this.tags = const [],
    this.dependencies = const [],
    this.platform,
    this.metadata = const {},
  });

  /// Create from JSON.
  factory BundleManifest.fromJson(Map<String, dynamic> json) {
    return BundleManifest(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '0.0.0',
      provider: json['provider'] as String?,
      description: json['description'] as String?,
      schemaVersion: json['schemaVersion'] as String? ?? currentSchemaVersion,
      type: BundleType.fromString(json['type'] as String? ?? 'application'),
      entryPoint: json['entryPoint'] as String?,
      license: json['license'] as String?,
      homepage: json['homepage'] as String?,
      repository: json['repository'] as String?,
      capabilities: _parseStringList(json['capabilities']),
      tags: _parseStringList(json['tags']),
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((e) => BundleDependency.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      platform: json['platform'] != null
          ? PlatformRequirements.fromJson(
              json['platform'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      if (provider != null) 'provider': provider,
      if (description != null) 'description': description,
      'schemaVersion': schemaVersion,
      'type': type.name,
      if (entryPoint != null) 'entryPoint': entryPoint,
      if (license != null) 'license': license,
      if (homepage != null) 'homepage': homepage,
      if (repository != null) 'repository': repository,
      if (capabilities.isNotEmpty) 'capabilities': capabilities,
      if (tags.isNotEmpty) 'tags': tags,
      if (dependencies.isNotEmpty)
        'dependencies': dependencies.map((d) => d.toJson()).toList(),
      if (platform != null) 'platform': platform!.toJson(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  /// Create a copy with modifications.
  BundleManifest copyWith({
    String? id,
    String? name,
    String? version,
    String? provider,
    String? description,
    String? schemaVersion,
    BundleType? type,
    String? entryPoint,
    String? license,
    String? homepage,
    String? repository,
    List<String>? capabilities,
    List<String>? tags,
    List<BundleDependency>? dependencies,
    PlatformRequirements? platform,
    Map<String, dynamic>? metadata,
  }) {
    return BundleManifest(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      provider: provider ?? this.provider,
      description: description ?? this.description,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      type: type ?? this.type,
      entryPoint: entryPoint ?? this.entryPoint,
      license: license ?? this.license,
      homepage: homepage ?? this.homepage,
      repository: repository ?? this.repository,
      capabilities: capabilities ?? this.capabilities,
      tags: tags ?? this.tags,
      dependencies: dependencies ?? this.dependencies,
      platform: platform ?? this.platform,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Bundle types.
enum BundleType {
  /// Full application bundle.
  application,

  /// Library/component bundle.
  library,

  /// Skill-only bundle.
  skill,

  /// Profile-only bundle.
  profile,

  /// Extension bundle.
  extension,

  /// Unknown type.
  unknown;

  static BundleType fromString(String value) {
    return BundleType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BundleType.unknown,
    );
  }
}

/// Dependency on another bundle.
class BundleDependency {
  /// Bundle identifier.
  final String id;

  /// Version constraint (semver).
  final String version;

  /// Whether this dependency is optional.
  final bool optional;

  /// Required features from the dependency.
  final List<String> features;

  const BundleDependency({
    required this.id,
    required this.version,
    this.optional = false,
    this.features = const [],
  });

  factory BundleDependency.fromJson(Map<String, dynamic> json) {
    return BundleDependency(
      id: json['id'] as String? ?? json['name'] as String? ?? '',
      version: json['version'] as String? ?? '*',
      optional: json['optional'] as bool? ?? false,
      features: _parseStringList(json['features']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      if (optional) 'optional': optional,
      if (features.isNotEmpty) 'features': features,
    };
  }
}

/// Platform requirements for the bundle.
class PlatformRequirements {
  /// Minimum Dart SDK version.
  final String? dartSdk;

  /// Minimum Flutter SDK version.
  final String? flutterSdk;

  /// Supported operating systems.
  final List<String> os;

  /// Required environment variables.
  final List<String> envVars;

  const PlatformRequirements({
    this.dartSdk,
    this.flutterSdk,
    this.os = const [],
    this.envVars = const [],
  });

  factory PlatformRequirements.fromJson(Map<String, dynamic> json) {
    return PlatformRequirements(
      dartSdk: json['dartSdk'] as String?,
      flutterSdk: json['flutterSdk'] as String?,
      os: _parseStringList(json['os']),
      envVars: _parseStringList(json['envVars']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (dartSdk != null) 'dartSdk': dartSdk,
      if (flutterSdk != null) 'flutterSdk': flutterSdk,
      if (os.isNotEmpty) 'os': os,
      if (envVars.isNotEmpty) 'envVars': envVars,
    };
  }
}

/// Helper to parse string lists from JSON.
List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return [];
}
