/// Bundle loader for loading and parsing MCP bundles.
library;

import 'dart:convert';

import '../schema/bundle_schema.dart';
import 'loader_options.dart';

/// Loads and parses MCP bundles from various sources.
class BundleLoader {
  final LoaderOptions options;
  final Map<String, Bundle> _cache = {};

  BundleLoader({this.options = const LoaderOptions()});

  /// Load a bundle from a source.
  Future<LoadResult<Bundle>> load(BundleSource source) async {
    try {
      final json = await _parseSource(source);
      final bundle = Bundle.fromJson(json);

      // Validate if requested
      if (options.validate) {
        final validationErrors = _validateBundle(bundle);
        if (validationErrors.isNotEmpty) {
          return LoadResult.fail(
            'Validation failed: ${validationErrors.join(', ')}',
            warnings: validationErrors,
          );
        }
      }

      // Resolve external references if requested
      final resolvedBundle = options.resolveRefs
          ? await _resolveReferences(bundle, source)
          : bundle;

      // Cache if enabled
      if (options.cache) {
        _cache[resolvedBundle.manifest.name] = resolvedBundle;
      }

      return LoadResult.ok(resolvedBundle);
    } catch (e) {
      return LoadResult.fail('Failed to load bundle: $e');
    }
  }

  /// Load a bundle from JSON data.
  Future<LoadResult<Bundle>> loadFromJson(Map<String, dynamic> json) {
    return load(BundleSource.json(json));
  }

  /// Load a bundle from a JSON string.
  Future<LoadResult<Bundle>> loadFromString(String content) {
    return load(BundleSource.string(content));
  }

  /// Get a cached bundle by name.
  Bundle? getCached(String name) => _cache[name];

  /// Check if a bundle is cached.
  bool isCached(String name) => _cache.containsKey(name);

  /// Clear the cache.
  void clearCache() => _cache.clear();

  /// Remove a bundle from cache.
  void removeFromCache(String name) => _cache.remove(name);

  /// Parse source to JSON map.
  Future<Map<String, dynamic>> _parseSource(BundleSource source) async {
    switch (source.type) {
      case SourceType.json:
        return source.source as Map<String, dynamic>;

      case SourceType.string:
        return jsonDecode(source.source as String) as Map<String, dynamic>;

      case SourceType.file:
        // Placeholder - actual implementation would read file
        throw UnimplementedError('File loading not implemented');

      case SourceType.url:
        // Placeholder - actual implementation would fetch URL
        throw UnimplementedError('URL loading not implemented');

      case SourceType.stream:
        // Placeholder - actual implementation would read stream
        throw UnimplementedError('Stream loading not implemented');
    }
  }

  /// Basic bundle validation.
  List<String> _validateBundle(Bundle bundle) {
    final errors = <String>[];

    // Validate manifest
    if (bundle.manifest.name.isEmpty) {
      errors.add('Bundle name is required');
    }

    if (bundle.manifest.version.isEmpty) {
      errors.add('Bundle version is required');
    }

    // Validate version format (basic semver check)
    if (!_isValidVersion(bundle.manifest.version)) {
      errors.add('Invalid version format: ${bundle.manifest.version}');
    }

    // Validate resources
    for (final resource in bundle.resources) {
      if (resource.path.isEmpty) {
        errors.add('Resource path is required');
      }

      if (!resource.hasInlineContent && !resource.hasExternalContent) {
        errors.add('Resource ${resource.path} has no content');
      }
    }

    // Validate dependencies
    for (final dep in bundle.dependencies) {
      if (dep.name.isEmpty) {
        errors.add('Dependency name is required');
      }
    }

    return errors;
  }

  /// Check if version string is valid semver.
  bool _isValidVersion(String version) {
    // Basic semver pattern
    final pattern = RegExp(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$');
    return pattern.hasMatch(version);
  }

  /// Resolve external content references.
  Future<Bundle> _resolveReferences(
    Bundle bundle,
    BundleSource source,
  ) async {
    final resolver = options.contentResolver ?? const FileContentResolver();
    final basePath = options.basePath ?? _getBasePath(source);

    final resolvedResources = <BundleResource>[];

    for (final resource in bundle.resources) {
      if (resource.hasExternalContent && !resource.hasInlineContent) {
        try {
          final content = await resolver.resolve(
            resource.contentRef!,
            basePath: basePath,
          );
          resolvedResources.add(BundleResource(
            path: resource.path,
            type: resource.type,
            content: content,
            encoding: resource.encoding,
            metadata: resource.metadata,
          ));
        } catch (e) {
          // Keep original resource if resolution fails
          resolvedResources.add(resource);
        }
      } else {
        resolvedResources.add(resource);
      }
    }

    return bundle.copyWith(resources: resolvedResources);
  }

  /// Extract base path from source.
  String? _getBasePath(BundleSource source) {
    switch (source.type) {
      case SourceType.file:
        final path = source.source as String;
        final lastSlash = path.lastIndexOf('/');
        return lastSlash > 0 ? path.substring(0, lastSlash) : null;

      case SourceType.url:
        final url = source.source as String;
        final lastSlash = url.lastIndexOf('/');
        return lastSlash > 0 ? url.substring(0, lastSlash) : null;

      default:
        return null;
    }
  }
}

/// Builder for creating bundles programmatically.
class BundleBuilder {
  String _name = 'unnamed';
  String _version = '0.0.1';
  String? _description;
  String? _author;
  String? _license;
  final List<BundleResource> _resources = [];
  final List<BundleDependency> _dependencies = [];
  final Map<String, dynamic> _metadata = {};

  /// Set the bundle name.
  BundleBuilder name(String name) {
    _name = name;
    return this;
  }

  /// Set the bundle version.
  BundleBuilder version(String version) {
    _version = version;
    return this;
  }

  /// Set the bundle description.
  BundleBuilder description(String description) {
    _description = description;
    return this;
  }

  /// Set the bundle author.
  BundleBuilder author(String author) {
    _author = author;
    return this;
  }

  /// Set the bundle license.
  BundleBuilder license(String license) {
    _license = license;
    return this;
  }

  /// Add a resource.
  BundleBuilder addResource(BundleResource resource) {
    _resources.add(resource);
    return this;
  }

  /// Add a dependency.
  BundleBuilder addDependency(BundleDependency dependency) {
    _dependencies.add(dependency);
    return this;
  }

  /// Add metadata.
  BundleBuilder addMetadata(String key, dynamic value) {
    _metadata[key] = value;
    return this;
  }

  /// Build the bundle.
  Bundle build() {
    return Bundle(
      manifest: BundleManifest(
        name: _name,
        version: _version,
        description: _description,
        author: _author,
        license: _license,
      ),
      resources: List.unmodifiable(_resources),
      dependencies: List.unmodifiable(_dependencies),
      metadata: Map.unmodifiable(_metadata),
    );
  }
}

/// Utility functions for working with bundles.
extension BundleExtensions on Bundle {
  /// Get a resource by path.
  BundleResource? getResource(String path) {
    return resources.where((r) => r.path == path).firstOrNull;
  }

  /// Get resources by type.
  List<BundleResource> getResourcesByType(ResourceType type) {
    return resources.where((r) => r.type == type).toList();
  }

  /// Check if bundle has a specific capability.
  bool hasCapability(String capability) {
    return manifest.capabilities.contains(capability);
  }

  /// Get all skill resources.
  List<BundleResource> get skills => getResourcesByType(ResourceType.skill);

  /// Get all profile resources.
  List<BundleResource> get profiles => getResourcesByType(ResourceType.profile);

  /// Get all fact graph resources.
  List<BundleResource> get factGraphs =>
      getResourcesByType(ResourceType.factGraph);
}
