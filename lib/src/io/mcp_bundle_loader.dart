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

import 'bundle_file_store.dart';
import '../models/agent_section.dart';
import '../models/asset.dart';
import '../models/binding.dart';
import '../models/bundle.dart';
import '../models/chat_section.dart';
import '../models/fact_graph_schema.dart';
import '../models/fact_graph_section.dart';
import '../models/facts_section.dart';
import '../models/flow_section.dart';
import '../models/integrity.dart';
import '../models/knowledge.dart';
import '../models/manifest.dart';
import '../models/philosophy_section.dart';
import '../models/pipelines_section.dart';
import '../models/policy.dart';
import '../models/profile_section.dart';
import '../models/requires_section.dart';
import '../models/runbooks_section.dart';
import '../models/settings_section.dart';
import '../models/skill_section.dart';
import '../models/test_section.dart';
import '../models/tools_section.dart';
import '../models/ui_section.dart';
import '../models/wiring_section.dart';
import '../models/workflows_section.dart';
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
///
/// Holds every typed top-level section that `McpBundle` carries. Loader
/// `fromJson` forwards each present section into the assembled bundle so
/// callers see the same surface as `McpBundle.fromJson`.
class _ParsedSections {
  final UiSection? ui;
  final FlowSection? flow;
  final SkillSection? skills;
  final AssetSection? assets;
  final KnowledgeSection? knowledge;
  final BindingSection? bindings;
  final TestSection? tests;
  final PolicySection? policies;
  final ProfilesSection? profiles;
  final PhilosophySection? philosophy;
  final AgentsSection? agents;
  final FactsSection? facts;
  final WorkflowsSection? workflows;
  final PipelinesSection? pipelines;
  final RunbooksSection? runbooks;
  final ToolsSection? tools;
  final RequiresSection? requires;
  final FactGraphSchema? factGraphSchema;
  final FactGraphSection? factGraphSection;
  final CompatibilityConfig? compatibility;
  final IntegrityConfig? integrity;
  final ChatSection? chat;
  final WiringSection? wiring;
  final SettingsSection? settingsSection;

  _ParsedSections({
    this.ui,
    this.flow,
    this.skills,
    this.assets,
    this.knowledge,
    this.bindings,
    this.tests,
    this.policies,
    this.profiles,
    this.philosophy,
    this.agents,
    this.facts,
    this.workflows,
    this.pipelines,
    this.runbooks,
    this.tools,
    this.requires,
    this.factGraphSchema,
    this.factGraphSection,
    this.compatibility,
    this.integrity,
    this.chat,
    this.wiring,
    this.settingsSection,
  });
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
    // Capture any top-level key the model does not yet recognise into
    // a reserved `_unmodeledTopLevel` sub-map on extensions. Forward
    // compatibility — bundles authored against a future spec extension
    // round-trip through an older loader without silent loss. The
    // emitter (`McpBundle.toJson`) re-spreads these keys back to the
    // top level on write. Keep this set in sync with the typed slots
    // McpBundle exposes (plus the reserved `extensions` channel).
    const knownTopLevel = <String>{
      'schemaVersion', 'manifest', 'ui', 'flow', 'skills', 'assets',
      'knowledge', 'bindings', 'tests', 'policies', 'profiles',
      'philosophy', 'agents', 'facts', 'workflows', 'pipelines',
      'runbooks', 'tools', 'requires', 'factGraphSchema',
      'factGraphSection', 'compatibility', 'integrity', 'chat',
      'wiring', 'settings', 'extensions',
    };
    final unmodeled = <String, dynamic>{
      for (final e in json.entries)
        if (!knownTopLevel.contains(e.key) && !e.key.startsWith('_'))
          e.key: e.value,
    };
    final extensions = <String, dynamic>{
      if (rawExtensions is Map<String, dynamic>) ...rawExtensions,
      if (unmodeled.isNotEmpty) '_unmodeledTopLevel': unmodeled,
      if (warnings.isNotEmpty) '_loadWarnings': warnings,
      if (errors.isNotEmpty)
        '_loadErrors': errors.map((e) => e.toString()).toList(),
    };

    return McpBundle(
      manifest: manifest.copyWith(
        schemaVersion: schemaVersion ?? defaultSchemaVersion,
      ),
      ui: sections.ui,
      flow: sections.flow,
      skills: sections.skills,
      assets: sections.assets,
      knowledge: sections.knowledge,
      bindings: sections.bindings,
      tests: sections.tests,
      policies: sections.policies,
      profiles: sections.profiles,
      philosophy: sections.philosophy,
      agents: sections.agents,
      facts: sections.facts,
      workflows: sections.workflows,
      pipelines: sections.pipelines,
      runbooks: sections.runbooks,
      tools: sections.tools,
      requires: sections.requires,
      factGraphSchema: sections.factGraphSchema,
      factGraphSection: sections.factGraphSection,
      compatibility: sections.compatibility,
      integrity: sections.integrity,
      chat: sections.chat,
      wiring: sections.wiring,
      settingsSection: sections.settingsSection,
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

  /// Load a bundle whose files live in [store].
  ///
  /// The store-shaped counterpart to [loadDirectory]: same `manifest.json`
  /// at the bundle root, same parse path, no filesystem assumption.
  ///
  /// Asset `contentRef`s are deliberately left relative. [loadDirectory]
  /// rewrites them to absolute paths because a consumer holding only the
  /// asset can still open it with `dart:io`; here there is no such path
  /// to rewrite to, and the store already resolves bundle-relative names.
  static Future<McpBundle> loadStore(
    BundleFileStore store, {
    McpLoaderOptions? options,
  }) async {
    final manifest = await store.read('manifest.json');
    if (manifest == null) {
      throw BundleLoadException('manifest.json not found in bundle store');
    }
    final bundle = fromJsonString(utf8.decode(manifest), options: options);
    return bundle.copyWith(store: store);
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
        for (final page in ui.pages.values) {
          registry.registerPage(page.id);
        }
      } catch (e) {
        errors.add(BundleLoadException('Failed to parse UI section: $e'));
        warnings.add('UI section skipped due to parsing error');
      }
    }

    // 3d. Parse the remaining typed top-level sections. Each follows the
    // same lenient pattern: presence check → fromJson → on failure record
    // an error + warning, leave the field null. Mirrors the canonical
    // shape in `models/bundle.dart` `McpBundle.fromJson`.
    final flow = _parseSection<FlowSection>(
      json,
      'flow',
      FlowSection.fromJson,
      errors,
      warnings,
    );
    final knowledge = _parseSection<KnowledgeSection>(
      json,
      'knowledge',
      KnowledgeSection.fromJson,
      errors,
      warnings,
    );
    final bindings = _parseSection<BindingSection>(
      json,
      'bindings',
      BindingSection.fromJson,
      errors,
      warnings,
    );
    final tests = _parseSection<TestSection>(
      json,
      'tests',
      TestSection.fromJson,
      errors,
      warnings,
    );
    final policies = _parseSection<PolicySection>(
      json,
      'policies',
      PolicySection.fromJson,
      errors,
      warnings,
    );
    final profiles = _parseSection<ProfilesSection>(
      json,
      'profiles',
      ProfilesSection.fromJson,
      errors,
      warnings,
    );
    final philosophy = _parseSection<PhilosophySection>(
      json,
      'philosophy',
      PhilosophySection.fromJson,
      errors,
      warnings,
    );
    final agents = _parseSection<AgentsSection>(
      json,
      'agents',
      AgentsSection.fromJson,
      errors,
      warnings,
    );
    final facts = _parseSection<FactsSection>(
      json,
      'facts',
      FactsSection.fromJson,
      errors,
      warnings,
    );
    final workflows = _parseSection<WorkflowsSection>(
      json,
      'workflows',
      WorkflowsSection.fromJson,
      errors,
      warnings,
    );
    final pipelines = _parseSection<PipelinesSection>(
      json,
      'pipelines',
      PipelinesSection.fromJson,
      errors,
      warnings,
    );
    final runbooks = _parseSection<RunbooksSection>(
      json,
      'runbooks',
      RunbooksSection.fromJson,
      errors,
      warnings,
    );
    final tools = _parseSection<ToolsSection>(
      json,
      'tools',
      ToolsSection.fromJson,
      errors,
      warnings,
    );
    final requires = _parseSection<RequiresSection>(
      json,
      'requires',
      RequiresSection.fromJson,
      errors,
      warnings,
    );
    final factGraphSchema = _parseSection<FactGraphSchema>(
      json,
      'factGraphSchema',
      FactGraphSchema.fromJson,
      errors,
      warnings,
    );
    final factGraphSection = _parseSection<FactGraphSection>(
      json,
      'factGraphSection',
      FactGraphSection.fromJson,
      errors,
      warnings,
    );
    final compatibility = _parseSection<CompatibilityConfig>(
      json,
      'compatibility',
      CompatibilityConfig.fromJson,
      errors,
      warnings,
    );
    final integrity = _parseSection<IntegrityConfig>(
      json,
      'integrity',
      IntegrityConfig.fromJson,
      errors,
      warnings,
    );
    // Spec §06 dual location — top-level wins, `manifest.<key>`
    // accepted as legacy alias.
    final chat = _parseDualLocationSection<ChatSection>(
      json,
      'chat',
      ChatSection.fromJson,
      errors,
      warnings,
    );
    final wiring = _parseDualLocationSection<WiringSection>(
      json,
      'wiring',
      WiringSection.fromJson,
      errors,
      warnings,
    );
    final settingsSection = _parseDualLocationSection<SettingsSection>(
      json,
      'settings',
      SettingsSection.fromJson,
      errors,
      warnings,
    );

    return _ParsedSections(
      ui: ui,
      flow: flow,
      skills: skills,
      assets: assets,
      knowledge: knowledge,
      bindings: bindings,
      tests: tests,
      policies: policies,
      profiles: profiles,
      philosophy: philosophy,
      agents: agents,
      facts: facts,
      workflows: workflows,
      pipelines: pipelines,
      runbooks: runbooks,
      tools: tools,
      requires: requires,
      factGraphSchema: factGraphSchema,
      factGraphSection: factGraphSection,
      compatibility: compatibility,
      integrity: integrity,
      chat: chat,
      wiring: wiring,
      settingsSection: settingsSection,
    );
  }

  /// Like [_parseSection] but resolves spec §06's dual location —
  /// top-level wins, `manifest.<key>` accepted as legacy alias for
  /// bundles authored before the canonical position was finalised.
  static T? _parseDualLocationSection<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) fromJson,
    List<BundleLoadException> errors,
    List<String> warnings,
  ) {
    final top = _parseSection<T>(json, key, fromJson, errors, warnings);
    if (top != null) return top;
    final manifest = json['manifest'];
    if (manifest is Map<String, dynamic>) {
      return _parseSection<T>(manifest, key, fromJson, errors, warnings);
    }
    return null;
  }

  /// Generic Section parser. Returns null if [key] absent. On `fromJson`
  /// failure records an error + skip warning and returns null so the
  /// load continues — same recovery posture as the assets / skills / ui
  /// arms above.
  static T? _parseSection<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) fromJson,
    List<BundleLoadException> errors,
    List<String> warnings,
  ) {
    if (!json.containsKey(key)) return null;
    final raw = json[key];
    if (raw is! Map<String, dynamic>) {
      errors.add(BundleInvalidValueException(key, raw, 'object'));
      warnings.add('$key section skipped — expected object');
      return null;
    }
    try {
      return fromJson(raw);
    } catch (e) {
      errors.add(BundleLoadException('Failed to parse $key section: $e'));
      warnings.add('$key section skipped due to parsing error');
      return null;
    }
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

      for (final page in sections.ui!.pages.values) {
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

    // Use copyWith so every other Section the loader assembled survives
    // path-resolution. Manual constructor list-out drops anything the
    // caller forgets to enumerate (the historical loader bug — see
    // CHANGELOG 0.3.3 Fixed).
    return bundle.copyWith(
      assets: AssetSection(
        schemaVersion: bundle.assets!.schemaVersion,
        assets: resolvedAssets,
        directories: bundle.assets!.directories,
        bundles: bundle.assets!.bundles,
      ),
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
