/// Loader options and configuration for bundle loading.
library;

/// Options for loading bundles.
class LoaderOptions {
  /// Whether to validate the bundle after loading.
  final bool validate;

  /// Whether to resolve external content references.
  final bool resolveRefs;

  /// Whether to load dependencies.
  final bool loadDependencies;

  /// Maximum depth for dependency resolution.
  final int maxDepth;

  /// Base path for resolving relative paths.
  final String? basePath;

  /// Custom content resolver.
  final ContentResolver? contentResolver;

  /// Dependency resolver.
  final DependencyResolver? dependencyResolver;

  /// Whether to cache loaded bundles.
  final bool cache;

  /// Whether to allow missing optional dependencies.
  final bool allowMissingOptional;

  const LoaderOptions({
    this.validate = true,
    this.resolveRefs = true,
    this.loadDependencies = true,
    this.maxDepth = 10,
    this.basePath,
    this.contentResolver,
    this.dependencyResolver,
    this.cache = true,
    this.allowMissingOptional = true,
  });

  /// Create options for strict loading.
  factory LoaderOptions.strict() {
    return const LoaderOptions(
      validate: true,
      resolveRefs: true,
      loadDependencies: true,
      allowMissingOptional: false,
    );
  }

  /// Create options for lenient loading.
  factory LoaderOptions.lenient() {
    return const LoaderOptions(
      validate: false,
      resolveRefs: false,
      loadDependencies: false,
    );
  }

  /// Create a copy with modifications.
  LoaderOptions copyWith({
    bool? validate,
    bool? resolveRefs,
    bool? loadDependencies,
    int? maxDepth,
    String? basePath,
    ContentResolver? contentResolver,
    DependencyResolver? dependencyResolver,
    bool? cache,
    bool? allowMissingOptional,
  }) {
    return LoaderOptions(
      validate: validate ?? this.validate,
      resolveRefs: resolveRefs ?? this.resolveRefs,
      loadDependencies: loadDependencies ?? this.loadDependencies,
      maxDepth: maxDepth ?? this.maxDepth,
      basePath: basePath ?? this.basePath,
      contentResolver: contentResolver ?? this.contentResolver,
      dependencyResolver: dependencyResolver ?? this.dependencyResolver,
      cache: cache ?? this.cache,
      allowMissingOptional: allowMissingOptional ?? this.allowMissingOptional,
    );
  }
}

/// Resolves content references to actual content.
abstract class ContentResolver {
  /// Resolve a content reference to its content.
  Future<dynamic> resolve(String ref, {String? basePath});

  /// Check if a reference can be resolved.
  Future<bool> canResolve(String ref);
}

/// Default file-based content resolver.
class FileContentResolver implements ContentResolver {
  final String? rootPath;

  const FileContentResolver({this.rootPath});

  @override
  Future<dynamic> resolve(String ref, {String? basePath}) async {
    // Placeholder - actual implementation would read files
    throw UnimplementedError('File content resolver not implemented');
  }

  @override
  Future<bool> canResolve(String ref) async {
    return ref.startsWith('file://') || !ref.contains('://');
  }
}

/// Resolves bundle dependencies.
abstract class DependencyResolver {
  /// Resolve a dependency to a bundle location.
  Future<String?> resolve(String name, String version);

  /// List available versions of a bundle.
  Future<List<String>> listVersions(String name);
}

/// Load result containing the loaded bundle and any issues.
class LoadResult<T> {
  /// The loaded value.
  final T? value;

  /// Whether loading was successful.
  final bool success;

  /// Error message if loading failed.
  final String? error;

  /// Warning messages.
  final List<String> warnings;

  /// Loading metadata.
  final Map<String, dynamic> metadata;

  const LoadResult({
    this.value,
    required this.success,
    this.error,
    this.warnings = const [],
    this.metadata = const {},
  });

  /// Create a successful result.
  factory LoadResult.ok(T value, {List<String>? warnings}) {
    return LoadResult(
      value: value,
      success: true,
      warnings: warnings ?? [],
    );
  }

  /// Create a failed result.
  factory LoadResult.fail(String error, {List<String>? warnings}) {
    return LoadResult(
      success: false,
      error: error,
      warnings: warnings ?? [],
    );
  }

  /// Map the value to a different type.
  LoadResult<U> map<U>(U Function(T) mapper) {
    if (!success || value == null) {
      return LoadResult<U>(
        success: success,
        error: error,
        warnings: warnings,
        metadata: metadata,
      );
    }
    return LoadResult<U>(
      value: mapper(value as T),
      success: true,
      warnings: warnings,
      metadata: metadata,
    );
  }
}

/// Source type for bundle loading.
enum SourceType {
  /// Load from a file path.
  file,

  /// Load from a URL.
  url,

  /// Load from raw JSON/Map data.
  json,

  /// Load from a string.
  string,

  /// Load from a stream.
  stream,
}

/// Bundle source information.
class BundleSource {
  /// Source type.
  final SourceType type;

  /// Source location or data.
  final dynamic source;

  /// Source metadata.
  final Map<String, dynamic> metadata;

  const BundleSource({
    required this.type,
    required this.source,
    this.metadata = const {},
  });

  /// Create a file source.
  factory BundleSource.file(String path) {
    return BundleSource(
      type: SourceType.file,
      source: path,
    );
  }

  /// Create a URL source.
  factory BundleSource.url(String url) {
    return BundleSource(
      type: SourceType.url,
      source: url,
    );
  }

  /// Create a JSON source.
  factory BundleSource.json(Map<String, dynamic> json) {
    return BundleSource(
      type: SourceType.json,
      source: json,
    );
  }

  /// Create a string source.
  factory BundleSource.string(String content) {
    return BundleSource(
      type: SourceType.string,
      source: content,
    );
  }
}
