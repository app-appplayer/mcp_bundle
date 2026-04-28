/// MCP Bundle Loader - Loads and parses MCP bundles.
///
/// Implements the 5-phase parsing algorithm from the design document:
/// 1. Schema Version Check
/// 2. Manifest Parsing
/// 3. Section Parsing (dependency order)
/// 4. Reference Validation
/// 5. Result Assembly
library;

import 'dart:convert';
import 'dart:io';

import '../models/bundle.dart';
import '../models/manifest.dart';
import '../models/ui_section.dart';
import '../models/skill_section.dart';
import '../models/asset.dart';
import 'exceptions.dart';
import 'type_coercion.dart';

/// Supported schema versions.
const List<String> supportedSchemaVersions = ['1.0.0'];

/// Default schema version.
const String defaultSchemaVersion = '1.0.0';

/// Loader configuration options aligned with design document.
class McpLoaderOptions {
  /// Require schemaVersion field (default: true).
  final bool requireSchemaVersion;

  /// Validate cross-section references (default: true).
  final bool validateReferences;

  /// Allow partial load even with errors (default: false).
  final bool allowPartialLoad;

  /// Type coercion rules.
  final TypeCoercionRules coercion;

  /// Maximum nesting depth for recursive structures.
  final int maxNestingDepth;

  const McpLoaderOptions({
    this.requireSchemaVersion = true,
    this.validateReferences = true,
    this.allowPartialLoad = false,
    this.coercion = const TypeCoercionRules(),
    this.maxNestingDepth = 50,
  });

  /// Strict mode: all validations enabled, no partial loads.
  const McpLoaderOptions.strict()
      : requireSchemaVersion = true,
        validateReferences = true,
        allowPartialLoad = false,
        coercion = const TypeCoercionRules(),
        maxNestingDepth = 50;

  /// Lenient mode: allows partial loads, basic coercion.
  const McpLoaderOptions.lenient()
      : requireSchemaVersion = false,
        validateReferences = false,
        allowPartialLoad = true,
        coercion = const TypeCoercionRules.lenient(),
        maxNestingDepth = 50;
}

/// Reference registry for cross-section validation.
class _ReferenceRegistry {
  final Set<String> _assets = {};
  final Set<String> _profiles = {};
  final Set<String> _skills = {};
  final Set<String> _procedures = {};
  final Set<String> _pages = {};

  void registerAsset(String id) => _assets.add(id);
  void registerProfile(String id) => _profiles.add(id);
  void registerSkill(String id) => _skills.add(id);
  void registerProcedure(String id) => _procedures.add(id);
  void registerPage(String id) => _pages.add(id);

  bool hasAsset(String id) => _assets.contains(id);
  bool hasProfile(String id) => _profiles.contains(id);
  bool hasSkill(String id) => _skills.contains(id);
  bool hasProcedure(String id) => _procedures.contains(id);
  bool hasPage(String id) => _pages.contains(id);

  Set<String> get assets => Set.unmodifiable(_assets);
  Set<String> get profiles => Set.unmodifiable(_profiles);
  Set<String> get skills => Set.unmodifiable(_skills);
}

/// Parsed sections container.
class _ParsedSections {
  final UiSection? ui;
  final SkillSection? skills;
  final AssetSection? assets;

  _ParsedSections({this.ui, this.skills, this.assets});
}

/// Main entry point for loading MCP bundles.
///
/// Implements the 5-phase parsing algorithm.
class McpBundleLoader {
  /// Load from JSON Map with full validation and error recovery.
  static McpBundle fromJson(
    Map<String, dynamic> json, {
    McpLoaderOptions? options,
  }) {
    final opts = options ?? const McpLoaderOptions.strict();
    final errors = <BundleLoadException>[];
    final warnings = <String>[];

    // Phase 1: Schema Version Check
    final schemaVersion = _parseSchemaVersion(json, errors, warnings, opts);

    // Phase 2: Manifest Parsing (Required)
    final manifest = _parseManifest(json, errors, warnings, opts);

    // Phase 3: Section Parsing (in dependency order)
    final sections = _parseSections(json, errors, warnings, opts);

    // Phase 4: Reference Validation
    if (opts.validateReferences) {
      _validateReferences(sections, errors, warnings);
    }

    // Phase 5: Result Assembly
    if (errors.isNotEmpty && !opts.allowPartialLoad) {
      throw BundleValidationException(
        'Bundle validation failed with ${errors.length} errors',
        errors: errors,
        warnings: warnings,
      );
    }

    // Preserve the original `extensions` map from the JSON so bundle
    // authors can use it as a pass-through channel for host-specific
    // metadata (e.g. runtime navigation that doesn't fit mcp_bundle's
    // typed UiSection.NavigationConfig schema). Load diagnostics are
    // merged under reserved underscore-prefixed keys so they never
    // collide with author-supplied entries.
    final rawExtensions = json['extensions'];
    final extensions = <String, dynamic>{
      if (rawExtensions is Map<String, dynamic>) ...rawExtensions,
      if (warnings.isNotEmpty) '_loadWarnings': warnings,
      if (errors.isNotEmpty)
        '_loadErrors': errors.map((e) => e.toString()).toList(),
    };

    return McpBundle(
      manifest: manifest.copyWith(
        schemaVersion: schemaVersion ?? defaultSchemaVersion,
      ),
      ui: sections.ui,
      skills: sections.skills,
      assets: sections.assets,
      extensions: extensions,
    );
  }

  /// Load from JSON string with encoding detection.
  static McpBundle fromJsonString(String jsonString, {McpLoaderOptions? options}) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(json, options: options);
    } on FormatException catch (e) {
      throw BundleParseException(
        'Invalid JSON: ${e.message}',
        line: e.offset != null ? _getLineFromOffset(jsonString, e.offset!) : null,
      );
    }
  }

  /// Load from file path with async I/O.
  static Future<McpBundle> loadFile(String path, {McpLoaderOptions? options}) async {
    final file = File(path);

    if (!await file.exists()) {
      throw BundleLoadException('File not found: $path');
    }

    final content = await file.readAsString();
    return fromJsonString(content, options: options);
  }

  /// Load from directory (.mbd/) with asset resolution.
  static Future<McpBundle> loadDirectory(String dirPath, {McpLoaderOptions? options}) async {
    final dir = Directory(dirPath);
    final bundleFile = File('${dir.path}/manifest.json');

    if (!await bundleFile.exists()) {
      throw BundleLoadException('manifest.json not found in $dirPath');
    }

    final bundle = await loadFile(bundleFile.path, options: options);

    // Tag the bundle with its on-disk root so consumers can read
    // `ui/**` / `assets/**` files directly (e.g. the runtime's bundle
    // adapter, a bundle-backed MCP server).
    final withDir = bundle.copyWith(directory: dir.absolute.path);

    // Resolve embedded asset paths relative to directory
    return _resolveAssetPaths(withDir, withDir.directory!);
  }

  /// Load an installed bundle by id from the caller's `installRoot`.
  ///
  /// Resolves `<installRoot>/<id>/` and delegates to [loadDirectory].
  /// Throws [BundleNotFoundException] when the id is not installed.
  static Future<McpBundle> loadInstalled(
    String installRoot,
    String id, {
    McpLoaderOptions? options,
  }) async {
    final target = Directory('$installRoot${Platform.pathSeparator}$id');
    if (!await target.exists()) {
      throw BundleNotFoundException(Uri.directory(target.path));
    }
    return loadDirectory(target.path, options: options);
  }

  // ==================== Phase 1: Schema Version ====================

  static String? _parseSchemaVersion(
    Map<String, dynamic> json,
    List<BundleLoadException> errors,
    List<String> warnings,
    McpLoaderOptions opts,
  ) {
    final version = json['schemaVersion'] as String?;

    if (version == null) {
      if (opts.requireSchemaVersion) {
        errors.add(BundleMissingFieldException('schemaVersion'));
      } else {
        warnings.add('schemaVersion not specified, using default: $defaultSchemaVersion');
      }
      return null;
    }

    // Validate semver format
    if (!_isValidSemver(version)) {
      errors.add(BundleInvalidValueException(
        'schemaVersion',
        version,
        'semver (MAJOR.MINOR.PATCH)',
      ));
      return null;
    }

    // Check compatibility
    if (!supportedSchemaVersions.contains(version)) {
      final majorVersion = version.split('.').first;
      final supportedMajor = supportedSchemaVersions
          .map((v) => v.split('.').first)
          .toSet();

      if (!supportedMajor.contains(majorVersion)) {
        errors.add(BundleSchemaVersionException(version, supportedSchemaVersions));
      } else {
        warnings.add('Schema version $version not explicitly supported, '
            'attempting to load with compatible version');
      }
    }

    return version;
  }

  // ==================== Phase 2: Manifest Parsing ====================

  static BundleManifest _parseManifest(
    Map<String, dynamic> json,
    List<BundleLoadException> errors,
    List<String> warnings,
    McpLoaderOptions opts,
  ) {
    final manifestJson = json['manifest'];

    if (manifestJson == null) {
      errors.add(BundleMissingFieldException('manifest'));
      if (!opts.allowPartialLoad) {
        throw BundleValidationException(
          'Manifest is required',
          errors: errors,
        );
      }
      // Return minimal manifest for partial load
      return const BundleManifest(
        id: 'unknown',
        name: 'Unknown Bundle',
        version: '0.0.0',
      );
    }

    if (manifestJson is! Map<String, dynamic>) {
      errors.add(BundleInvalidValueException('manifest', manifestJson, 'object'));
      if (!opts.allowPartialLoad) {
        throw BundleValidationException(
          'Manifest must be an object',
          errors: errors,
        );
      }
      return const BundleManifest(
        id: 'unknown',
        name: 'Unknown Bundle',
        version: '0.0.0',
      );
    }

    try {
      final manifest = BundleManifest.fromJson(manifestJson);

      // Validate required fields
      if (manifest.id.isEmpty) {
        errors.add(BundleMissingFieldException('manifest.id'));
      }
      if (manifest.name.isEmpty) {
        errors.add(BundleMissingFieldException('manifest.name'));
      }
      if (manifest.version.isEmpty || manifest.version == '0.0.0') {
        warnings.add('manifest.version not specified or invalid');
      }

      return manifest;
    } catch (e) {
      errors.add(BundleLoadException('Failed to parse manifest: $e'));
      return const BundleManifest(
        id: 'unknown',
        name: 'Unknown Bundle',
        version: '0.0.0',
      );
    }
  }

  // ==================== Phase 3: Section Parsing ====================

  static _ParsedSections _parseSections(
    Map<String, dynamic> json,
    List<BundleLoadException> errors,
    List<String> warnings,
    McpLoaderOptions opts,
  ) {
    final registry = _ReferenceRegistry();

    // 3a. Parse assets first (no dependencies)
    AssetSection? assets;
    if (json.containsKey('assets')) {
      try {
        assets = AssetSection.fromJson(json['assets'] as Map<String, dynamic>);
        for (final asset in assets.assets) {
          if (asset.id != null) {
            registry.registerAsset(asset.id!);
          }
        }
      } catch (e) {
        errors.add(BundleLoadException('Failed to parse assets section: $e'));
        warnings.add('Assets section skipped due to parsing error');
      }
    }

    // 3b. Parse skills (may reference assets)
    SkillSection? skills;
    if (json.containsKey('skills')) {
      try {
        skills = SkillSection.fromJson(json['skills'] as Map<String, dynamic>);
        for (final module in skills.modules) {
          registry.registerSkill(module.id);
          // Register procedures if available
          for (final proc in module.procedures) {
            registry.registerProcedure('${module.id}/${proc.id}');
          }
        }
      } catch (e) {
        errors.add(BundleLoadException('Failed to parse skills section: $e'));
        warnings.add('Skills section skipped due to parsing error');
      }
    }

    // 3c. Parse UI last (may reference everything)
    UiSection? ui;
    if (json.containsKey('ui')) {
      try {
        ui = UiSection.fromJson(json['ui'] as Map<String, dynamic>);
        for (final page in ui.pages) {
          registry.registerPage(page.id);
        }
      } catch (e) {
        errors.add(BundleLoadException('Failed to parse UI section: $e'));
        warnings.add('UI section skipped due to parsing error');
      }
    }

    return _ParsedSections(
      ui: ui,
      skills: skills,
      assets: assets,
    );
  }

  // ==================== Phase 4: Reference Validation ====================

  static void _validateReferences(
    _ParsedSections sections,
    List<BundleLoadException> errors,
    List<String> warnings,
  ) {
    // Validate UI references to skills
    if (sections.ui != null && sections.skills != null) {
      final skillIds = sections.skills!.modules.map((m) => m.id).toSet();

      for (final page in sections.ui!.pages) {
        // Check action references in root widget
        _validateWidgetActions(page.root, skillIds, errors);
      }
    }

    // Validate asset references
    if (sections.assets != null) {
      final assetIds = sections.assets!.assets
          .where((a) => a.id != null)
          .map((a) => a.id!)
          .toSet();

      // Check skill MCP tool and knowledge source references
      if (sections.skills != null) {
        for (final module in sections.skills!.modules) {
          // Validate knowledge source references if they point to assets
          for (final ks in module.knowledgeSources) {
            if (ks.sourceId.startsWith('asset:')) {
              final assetRef = ks.sourceId.substring(6);
              if (!assetIds.contains(assetRef)) {
                warnings.add('Skill ${module.id} references unknown asset: $assetRef');
              }
            }
          }
        }
      }
    }
  }

  /// Recursively validate widget action references.
  static void _validateWidgetActions(
    WidgetNode widget,
    Set<String> skillIds,
    List<BundleLoadException> errors,
  ) {
    // Check actions in current widget
    for (final action in widget.actions.values) {
      if (action.type == ActionType.callSkill && action.target != null) {
        if (!skillIds.contains(action.target)) {
          errors.add(BundleReferenceException(action.target!, 'skill'));
        }
      }
    }

    // Recursively check children
    for (final child in widget.children) {
      _validateWidgetActions(child, skillIds, errors);
    }
  }

  // ==================== Utilities ====================

  static bool _isValidSemver(String version) {
    final pattern = RegExp(
      r'^\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$',
    );
    return pattern.hasMatch(version);
  }

  static int _getLineFromOffset(String content, int offset) {
    return content.substring(0, offset).split('\n').length;
  }

  static McpBundle _resolveAssetPaths(McpBundle bundle, String basePath) {
    if (bundle.assets == null) return bundle;

    final resolvedAssets = bundle.assets!.assets.map((Asset asset) {
      // If asset has external content reference, resolve the path
      if (asset.hasExternalContent && asset.contentRef != null) {
        // Only resolve relative paths
        if (!asset.contentRef!.startsWith('/') &&
            !asset.contentRef!.contains('://')) {
          final absolutePath = '$basePath/${asset.contentRef}';
          return Asset(
            id: asset.id,
            path: asset.path,
            type: asset.type,
            name: asset.name,
            description: asset.description,
            mimeType: asset.mimeType,
            encoding: asset.encoding,
            content: asset.content,
            contentRef: absolutePath,
            hash: asset.hash,
            size: asset.size,
            metadata: asset.metadata,
          );
        }
      }
      return asset;
    }).toList();

    return McpBundle(
      manifest: bundle.manifest,
      ui: bundle.ui,
      flow: bundle.flow,
      skills: bundle.skills,
      assets: AssetSection(
        schemaVersion: bundle.assets!.schemaVersion,
        assets: resolvedAssets,
        directories: bundle.assets!.directories,
        bundles: bundle.assets!.bundles,
      ),
      knowledge: bundle.knowledge,
      bindings: bundle.bindings,
      tests: bundle.tests,
      extensions: bundle.extensions,
    );
  }
}

/// Lazy bundle that loads sections on demand.
class LazyMcpBundle {
  final String _basePath;

  /// Bundle manifest (always loaded).
  final BundleManifest manifest;

  McpBundle? _fullBundle;
  UiSection? _ui;
  SkillSection? _skills;
  AssetSection? _assets;

  LazyMcpBundle._(this._basePath, this.manifest);

  /// Load only manifest first.
  static Future<LazyMcpBundle> load(String path, {McpLoaderOptions? options}) async {
    final file = File(path);
    if (!await file.exists()) {
      throw BundleLoadException('File not found: $path');
    }

    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final manifest = BundleManifest.fromJson(
      json['manifest'] as Map<String, dynamic>? ?? {},
    );

    return LazyMcpBundle._(path, manifest);
  }

  /// Load UI section on demand.
  Future<UiSection?> get ui async {
    if (_ui != null) return _ui;
    final full = await _loadFull();
    _ui = full.ui;
    return _ui;
  }

  /// Load skills section on demand.
  Future<SkillSection?> get skills async {
    if (_skills != null) return _skills;
    final full = await _loadFull();
    _skills = full.skills;
    return _skills;
  }

  /// Load assets section on demand.
  Future<AssetSection?> get assets async {
    if (_assets != null) return _assets;
    final full = await _loadFull();
    _assets = full.assets;
    return _assets;
  }

  /// Get full bundle.
  Future<McpBundle> get fullBundle => _loadFull();

  Future<McpBundle> _loadFull() async {
    _fullBundle ??= await McpBundleLoader.loadFile(_basePath);
    return _fullBundle!;
  }
}
