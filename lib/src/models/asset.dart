/// Asset Section model for MCP Bundle.
///
/// Contains static asset definitions (images, fonts, files, etc.).
library;

/// Asset section containing static resources.
class AssetSection {
  /// Schema version for asset section.
  final String schemaVersion;

  /// List of assets.
  final List<Asset> assets;

  /// Asset directories.
  final List<AssetDirectory> directories;

  /// Asset bundles.
  final List<AssetBundle> bundles;

  const AssetSection({
    this.schemaVersion = '1.0.0',
    this.assets = const [],
    this.directories = const [],
    this.bundles = const [],
  });

  factory AssetSection.fromJson(Map<String, dynamic> json) {
    return AssetSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      assets: (json['assets'] as List<dynamic>?)
              ?.map((e) => Asset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      directories: (json['directories'] as List<dynamic>?)
              ?.map((e) => AssetDirectory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bundles: (json['bundles'] as List<dynamic>?)
              ?.map((e) => AssetBundle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      if (assets.isNotEmpty) 'assets': assets.map((a) => a.toJson()).toList(),
      if (directories.isNotEmpty)
        'directories': directories.map((d) => d.toJson()).toList(),
      if (bundles.isNotEmpty)
        'bundles': bundles.map((b) => b.toJson()).toList(),
    };
  }

  /// Get asset by path.
  Asset? getAsset(String path) {
    return assets.where((a) => a.path == path).firstOrNull;
  }

  /// Get all assets of a specific type.
  List<Asset> getAssetsByType(AssetType type) {
    return assets.where((a) => a.type == type).toList();
  }
}

/// Individual asset definition.
class Asset {
  /// Asset identifier.
  final String? id;

  /// Asset path within bundle.
  final String path;

  /// Asset type.
  final AssetType type;

  /// Asset name.
  final String? name;

  /// Asset description.
  final String? description;

  /// MIME type.
  final String? mimeType;

  /// Content encoding.
  final String encoding;

  /// Inline content (for small assets).
  final String? content;

  /// Content reference (URL or file path).
  final String? contentRef;

  /// Content hash for integrity.
  final String? hash;

  /// Asset size in bytes.
  final int? size;

  /// Asset metadata.
  final Map<String, dynamic> metadata;

  const Asset({
    this.id,
    required this.path,
    required this.type,
    this.name,
    this.description,
    this.mimeType,
    this.encoding = 'utf-8',
    this.content,
    this.contentRef,
    this.hash,
    this.size,
    this.metadata = const {},
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String?,
      path: json['path'] as String? ?? '',
      type: AssetType.fromString(json['type'] as String? ?? 'file'),
      name: json['name'] as String?,
      description: json['description'] as String?,
      mimeType: json['mimeType'] as String?,
      encoding: json['encoding'] as String? ?? 'utf-8',
      content: json['content'] as String?,
      contentRef: json['contentRef'] as String?,
      hash: json['hash'] as String?,
      size: json['size'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'path': path,
      'type': type.name,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (mimeType != null) 'mimeType': mimeType,
      'encoding': encoding,
      if (content != null) 'content': content,
      if (contentRef != null) 'contentRef': contentRef,
      if (hash != null) 'hash': hash,
      if (size != null) 'size': size,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  /// Check if asset has inline content.
  bool get hasInlineContent => content != null;

  /// Check if asset references external content.
  bool get hasExternalContent => contentRef != null;
}

/// Asset types.
enum AssetType {
  /// Image asset.
  image,

  /// Icon asset.
  icon,

  /// Font asset.
  font,

  /// Audio asset.
  audio,

  /// Video asset.
  video,

  /// JSON data asset.
  json,

  /// Text file asset.
  text,

  /// Binary file asset.
  binary,

  /// Template asset.
  template,

  /// Style/CSS asset.
  style,

  /// Generic file asset.
  file,

  /// Unknown type.
  unknown;

  static AssetType fromString(String value) {
    return AssetType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AssetType.unknown,
    );
  }

  /// Get common MIME types for this asset type.
  List<String> get commonMimeTypes {
    switch (this) {
      case AssetType.image:
        return ['image/png', 'image/jpeg', 'image/gif', 'image/svg+xml', 'image/webp'];
      case AssetType.icon:
        return ['image/png', 'image/svg+xml', 'image/x-icon'];
      case AssetType.font:
        return ['font/ttf', 'font/otf', 'font/woff', 'font/woff2'];
      case AssetType.audio:
        return ['audio/mpeg', 'audio/wav', 'audio/ogg'];
      case AssetType.video:
        return ['video/mp4', 'video/webm', 'video/ogg'];
      case AssetType.json:
        return ['application/json'];
      case AssetType.text:
        return ['text/plain', 'text/markdown'];
      case AssetType.template:
        return ['text/html', 'text/plain'];
      case AssetType.style:
        return ['text/css'];
      default:
        return ['application/octet-stream'];
    }
  }
}

/// Asset directory definition.
class AssetDirectory {
  /// Directory path.
  final String path;

  /// Include pattern.
  final String pattern;

  /// Asset type for contents.
  final AssetType type;

  /// Whether to include subdirectories.
  final bool recursive;

  const AssetDirectory({
    required this.path,
    this.pattern = '*',
    this.type = AssetType.file,
    this.recursive = false,
  });

  factory AssetDirectory.fromJson(Map<String, dynamic> json) {
    return AssetDirectory(
      path: json['path'] as String? ?? '',
      pattern: json['pattern'] as String? ?? '*',
      type: AssetType.fromString(json['type'] as String? ?? 'file'),
      recursive: json['recursive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'pattern': pattern,
      'type': type.name,
      if (recursive) 'recursive': recursive,
    };
  }
}

/// Asset bundle for grouped assets.
class AssetBundle {
  /// Bundle identifier.
  final String id;

  /// Bundle name.
  final String name;

  /// Asset paths in bundle.
  final List<String> assets;

  /// Load strategy.
  final LoadStrategy loadStrategy;

  const AssetBundle({
    required this.id,
    required this.name,
    this.assets = const [],
    this.loadStrategy = LoadStrategy.lazy,
  });

  factory AssetBundle.fromJson(Map<String, dynamic> json) {
    return AssetBundle(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      assets: (json['assets'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      loadStrategy: LoadStrategy.fromString(
          json['loadStrategy'] as String? ?? 'lazy'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (assets.isNotEmpty) 'assets': assets,
      'loadStrategy': loadStrategy.name,
    };
  }
}

/// Asset load strategies.
enum LoadStrategy {
  /// Load immediately at startup.
  eager,

  /// Load when first needed.
  lazy,

  /// Preload in background.
  preload,

  /// Unknown strategy.
  unknown;

  static LoadStrategy fromString(String value) {
    return LoadStrategy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LoadStrategy.unknown,
    );
  }
}
