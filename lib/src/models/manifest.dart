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

  /// App icon asset reference (asset ID or URL).
  final String? icon;

  /// Splash screen configuration.
  final SplashConfig? splash;

  /// Preview image references.
  final List<String> screenshots;

  /// Structured app category.
  final AppCategory? category;

  /// Publisher details.
  final PublisherInfo? publisher;

  /// Bundle creation timestamp.
  final DateTime? createdAt;

  /// Last update timestamp.
  final DateTime? updatedAt;

  /// Publication timestamp.
  final DateTime? publishedAt;

  /// Minimum AppPlayer/runtime version required.
  final String? minRuntimeVersion;

  /// Localized name/description per locale.
  final Map<String, LocalizedInfo>? localization;

  /// Age rating (e.g. "everyone", "teen", "mature").
  final String? ageRating;

  /// Privacy policy URL.
  final String? privacyPolicy;

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
    this.icon,
    this.splash,
    this.screenshots = const [],
    this.category,
    this.publisher,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.minRuntimeVersion,
    this.localization,
    this.ageRating,
    this.privacyPolicy,
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
      icon: json['icon'] as String?,
      splash: json['splash'] != null
          ? SplashConfig.fromJson(json['splash'] as Map<String, dynamic>)
          : null,
      screenshots: _parseStringList(json['screenshots']),
      category: json['category'] != null
          ? AppCategory.fromString(json['category'] as String)
          : null,
      publisher: json['publisher'] != null
          ? PublisherInfo.fromJson(json['publisher'] as Map<String, dynamic>)
          : null,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      publishedAt: _parseDateTime(json['publishedAt']),
      minRuntimeVersion: json['minRuntimeVersion'] as String?,
      localization: _parseLocalizationMap(json['localization']),
      ageRating: json['ageRating'] as String?,
      privacyPolicy: json['privacyPolicy'] as String?,
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
      if (icon != null) 'icon': icon,
      if (splash != null) 'splash': splash!.toJson(),
      if (screenshots.isNotEmpty) 'screenshots': screenshots,
      if (category != null) 'category': category!.name,
      if (publisher != null) 'publisher': publisher!.toJson(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
      if (minRuntimeVersion != null) 'minRuntimeVersion': minRuntimeVersion,
      if (localization != null)
        'localization': localization!.map((k, v) => MapEntry(k, v.toJson())),
      if (ageRating != null) 'ageRating': ageRating,
      if (privacyPolicy != null) 'privacyPolicy': privacyPolicy,
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
    String? icon,
    SplashConfig? splash,
    List<String>? screenshots,
    AppCategory? category,
    PublisherInfo? publisher,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    String? minRuntimeVersion,
    Map<String, LocalizedInfo>? localization,
    String? ageRating,
    String? privacyPolicy,
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
      icon: icon ?? this.icon,
      splash: splash ?? this.splash,
      screenshots: screenshots ?? this.screenshots,
      category: category ?? this.category,
      publisher: publisher ?? this.publisher,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      minRuntimeVersion: minRuntimeVersion ?? this.minRuntimeVersion,
      localization: localization ?? this.localization,
      ageRating: ageRating ?? this.ageRating,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
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

/// App categories for marketplace listing and categorization.
enum AppCategory {
  productivity,
  education,
  entertainment,
  social,
  business,
  utilities,
  health,
  finance,
  lifestyle,
  news,
  travel,
  food,
  sports,
  music,
  photo,
  video,
  communication,
  developer,
  reference,
  other;

  /// Parse from string, returning [other] for unrecognized values.
  static AppCategory fromString(String value) {
    return AppCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppCategory.other,
    );
  }
}

/// Publisher identity information.
class PublisherInfo {
  /// Publisher display name (required).
  final String name;

  /// Publisher logo asset reference or URL.
  final String? logo;

  /// Publisher website URL.
  final String? url;

  /// Contact email.
  final String? email;

  const PublisherInfo({
    required this.name,
    this.logo,
    this.url,
    this.email,
  });

  factory PublisherInfo.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null || name.isEmpty) {
      throw FormatException('PublisherInfo requires a non-empty "name" field');
    }
    return PublisherInfo(
      name: name,
      logo: json['logo'] as String?,
      url: json['url'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (logo != null) 'logo': logo,
      if (url != null) 'url': url,
      if (email != null) 'email': email,
    };
  }

  PublisherInfo copyWith({
    String? name,
    String? logo,
    String? url,
    String? email,
  }) {
    return PublisherInfo(
      name: name ?? this.name,
      logo: logo ?? this.logo,
      url: url ?? this.url,
      email: email ?? this.email,
    );
  }
}

/// Splash screen configuration.
class SplashConfig {
  /// Splash image asset reference or URL.
  final String? image;

  /// Background color as hex string (e.g. '#FFFFFF').
  final String? backgroundColor;

  /// Display duration in milliseconds.
  final int? duration;

  const SplashConfig({
    this.image,
    this.backgroundColor,
    this.duration,
  });

  factory SplashConfig.fromJson(Map<String, dynamic> json) {
    return SplashConfig(
      image: json['image'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      duration: json['duration'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (image != null) 'image': image,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (duration != null) 'duration': duration,
    };
  }

  SplashConfig copyWith({
    String? image,
    String? backgroundColor,
    int? duration,
  }) {
    return SplashConfig(
      image: image ?? this.image,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      duration: duration ?? this.duration,
    );
  }
}

/// Localized name, description, and icon for a specific locale.
class LocalizedInfo {
  /// Localized app name (required).
  final String name;

  /// Localized description.
  final String? description;

  /// Locale-specific icon override.
  final String? icon;

  const LocalizedInfo({
    required this.name,
    this.description,
    this.icon,
  });

  factory LocalizedInfo.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null || name.isEmpty) {
      throw FormatException('LocalizedInfo requires a non-empty "name" field');
    }
    return LocalizedInfo(
      name: name,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
    };
  }

  LocalizedInfo copyWith({
    String? name,
    String? description,
    String? icon,
  }) {
    return LocalizedInfo(
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
    );
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

/// Helper to parse DateTime from JSON (ISO 8601 string).
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

/// Helper to parse localization map from JSON.
Map<String, LocalizedInfo>? _parseLocalizationMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) {
    return value.map(
      (k, v) => MapEntry(k, LocalizedInfo.fromJson(v as Map<String, dynamic>)),
    );
  }
  return null;
}
