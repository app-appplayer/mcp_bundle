/// Bundle schema definitions for MCP Bundle format.
///
/// Defines the structure of bundle files including metadata,
/// resources, and configuration.
library;

/// Version of the bundle schema.
const String bundleSchemaVersion = '1.0.0';

/// A bundle containing packaged MCP resources.
class Bundle {
  /// Bundle manifest with metadata and configuration.
  final BundleManifest manifest;

  /// List of resources included in the bundle.
  final List<BundleResource> resources;

  /// Dependencies on other bundles.
  final List<BundleDependency> dependencies;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const Bundle({
    required this.manifest,
    this.resources = const [],
    this.dependencies = const [],
    this.metadata = const {},
  });

  /// Create a Bundle from JSON.
  factory Bundle.fromJson(Map<String, dynamic> json) {
    return Bundle(
      manifest: BundleManifest.fromJson(
        json['manifest'] as Map<String, dynamic>? ?? {},
      ),
      resources: (json['resources'] as List<dynamic>?)
              ?.map((e) => BundleResource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((e) => BundleDependency.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'manifest': manifest.toJson(),
        'resources': resources.map((r) => r.toJson()).toList(),
        'dependencies': dependencies.map((d) => d.toJson()).toList(),
        'metadata': metadata,
      };

  /// Create a copy with modifications.
  Bundle copyWith({
    BundleManifest? manifest,
    List<BundleResource>? resources,
    List<BundleDependency>? dependencies,
    Map<String, dynamic>? metadata,
  }) {
    return Bundle(
      manifest: manifest ?? this.manifest,
      resources: resources ?? this.resources,
      dependencies: dependencies ?? this.dependencies,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Bundle manifest containing metadata and configuration.
class BundleManifest {
  /// Bundle name (unique identifier).
  final String name;

  /// Semantic version string.
  final String version;

  /// Human-readable description.
  final String? description;

  /// Author information.
  final String? author;

  /// License identifier (SPDX).
  final String? license;

  /// Homepage URL.
  final String? homepage;

  /// Repository URL.
  final String? repository;

  /// Schema version this bundle conforms to.
  final String schemaVersion;

  /// Main entry point resource.
  final String? entryPoint;

  /// Exported symbols/resources.
  final List<String> exports;

  /// Declared capabilities.
  final List<String> capabilities;

  const BundleManifest({
    required this.name,
    required this.version,
    this.description,
    this.author,
    this.license,
    this.homepage,
    this.repository,
    this.schemaVersion = bundleSchemaVersion,
    this.entryPoint,
    this.exports = const [],
    this.capabilities = const [],
  });

  /// Create from JSON.
  factory BundleManifest.fromJson(Map<String, dynamic> json) {
    return BundleManifest(
      name: json['name'] as String? ?? 'unnamed',
      version: json['version'] as String? ?? '0.0.0',
      description: json['description'] as String?,
      author: json['author'] as String?,
      license: json['license'] as String?,
      homepage: json['homepage'] as String?,
      repository: json['repository'] as String?,
      schemaVersion: json['schemaVersion'] as String? ?? bundleSchemaVersion,
      entryPoint: json['entryPoint'] as String?,
      exports: (json['exports'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        if (description != null) 'description': description,
        if (author != null) 'author': author,
        if (license != null) 'license': license,
        if (homepage != null) 'homepage': homepage,
        if (repository != null) 'repository': repository,
        'schemaVersion': schemaVersion,
        if (entryPoint != null) 'entryPoint': entryPoint,
        if (exports.isNotEmpty) 'exports': exports,
        if (capabilities.isNotEmpty) 'capabilities': capabilities,
      };
}

/// A resource within a bundle.
class BundleResource {
  /// Resource path within the bundle.
  final String path;

  /// Resource type (e.g., 'skill', 'profile', 'fact_graph').
  final ResourceType type;

  /// Inline content (for small resources).
  final dynamic content;

  /// Reference to external content (file path or URL).
  final String? contentRef;

  /// Content encoding.
  final String encoding;

  /// Resource-specific metadata.
  final Map<String, dynamic> metadata;

  const BundleResource({
    required this.path,
    required this.type,
    this.content,
    this.contentRef,
    this.encoding = 'utf-8',
    this.metadata = const {},
  });

  /// Create from JSON.
  factory BundleResource.fromJson(Map<String, dynamic> json) {
    return BundleResource(
      path: json['path'] as String? ?? '',
      type: ResourceType.fromString(json['type'] as String? ?? 'unknown'),
      content: json['content'],
      contentRef: json['contentRef'] as String?,
      encoding: json['encoding'] as String? ?? 'utf-8',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'path': path,
        'type': type.name,
        if (content != null) 'content': content,
        if (contentRef != null) 'contentRef': contentRef,
        'encoding': encoding,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Check if resource has inline content.
  bool get hasInlineContent => content != null;

  /// Check if resource references external content.
  bool get hasExternalContent => contentRef != null;
}

/// Types of resources that can be in a bundle.
enum ResourceType {
  /// Skill definition.
  skill,

  /// Profile definition.
  profile,

  /// Fact graph data.
  factGraph,

  /// Knowledge operations.
  knowledgeOps,

  /// Raw data file.
  data,

  /// Configuration file.
  config,

  /// Template file.
  template,

  /// Schema definition.
  schema,

  /// Unknown resource type.
  unknown;

  /// Parse from string.
  static ResourceType fromString(String value) {
    return ResourceType.values.firstWhere(
      (e) => e.name == value || e.name == _camelToSnake(value),
      orElse: () => ResourceType.unknown,
    );
  }
}

/// Dependency on another bundle.
class BundleDependency {
  /// Name of the dependent bundle.
  final String name;

  /// Version constraint (semver).
  final String version;

  /// Whether this dependency is optional.
  final bool optional;

  /// Required features from the dependency.
  final List<String> features;

  const BundleDependency({
    required this.name,
    required this.version,
    this.optional = false,
    this.features = const [],
  });

  /// Create from JSON.
  factory BundleDependency.fromJson(Map<String, dynamic> json) {
    return BundleDependency(
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '*',
      optional: json['optional'] as bool? ?? false,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        if (optional) 'optional': optional,
        if (features.isNotEmpty) 'features': features,
      };
}

/// Convert camelCase to snake_case.
String _camelToSnake(String input) {
  return input.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}
