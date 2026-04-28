/// Main MCP Bundle model.
///
/// Represents a complete MCP Bundle containing all sections.
library;

import '../io/bundle_resources.dart';
import 'asset.dart';
import 'binding.dart';
import 'fact_graph_schema.dart';
import 'flow_section.dart';
import 'integrity.dart';
import 'knowledge.dart';
import 'manifest.dart';
import 'policy.dart';
import 'profile_section.dart';
import 'skill_section.dart';
import 'test_section.dart';
import 'ui_section.dart';

/// A complete MCP Bundle containing all packaged resources.
class McpBundle {
  /// Schema version this bundle conforms to.
  final String schemaVersion;

  /// Bundle manifest with metadata.
  final BundleManifest manifest;

  /// UI section with screens and widgets.
  final UiSection? ui;

  /// Flow section with flow definitions.
  final FlowSection? flow;

  /// Skill section with skill modules.
  final SkillSection? skills;

  /// Assets section with static resources.
  final AssetSection? assets;

  /// Knowledge section with RAG sources.
  final KnowledgeSection? knowledge;

  /// Bindings section with data bindings.
  final BindingSection? bindings;

  /// Test section with test definitions.
  final TestSection? tests;

  /// Policy section with decision/validation rules.
  final PolicySection? policies;

  /// Profiles section with profile definitions.
  final ProfilesSection? profiles;

  /// FactGraph schema definitions.
  final FactGraphSchema? factGraphSchema;

  /// Compatibility configuration.
  final CompatibilityConfig? compatibility;

  /// Integrity configuration.
  final IntegrityConfig? integrity;

  /// Extensions for custom data.
  final Map<String, dynamic> extensions;

  /// Filesystem path to the `.mbd` directory the bundle was loaded
  /// from, or `null` when the bundle came from an inline map or remote
  /// fetch. Consumers that need to read raw UI / asset files — the
  /// runtime's bundle adapter, a bundle-backed MCP server — resolve
  /// paths relative to this root.
  final String? directory;

  const McpBundle({
    this.schemaVersion = '1.0.0',
    required this.manifest,
    this.ui,
    this.flow,
    this.skills,
    this.assets,
    this.knowledge,
    this.bindings,
    this.tests,
    this.policies,
    this.profiles,
    this.factGraphSchema,
    this.compatibility,
    this.integrity,
    this.extensions = const {},
    this.directory,
  });

  /// Create from JSON.
  factory McpBundle.fromJson(Map<String, dynamic> json) {
    return McpBundle(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      manifest: BundleManifest.fromJson(
        json['manifest'] as Map<String, dynamic>? ?? {},
      ),
      ui: json['ui'] != null
          ? UiSection.fromJson(json['ui'] as Map<String, dynamic>)
          : null,
      flow: json['flow'] != null
          ? FlowSection.fromJson(json['flow'] as Map<String, dynamic>)
          : null,
      skills: json['skills'] != null
          ? SkillSection.fromJson(json['skills'] as Map<String, dynamic>)
          : null,
      assets: json['assets'] != null
          ? AssetSection.fromJson(json['assets'] as Map<String, dynamic>)
          : null,
      knowledge: json['knowledge'] != null
          ? KnowledgeSection.fromJson(json['knowledge'] as Map<String, dynamic>)
          : null,
      bindings: json['bindings'] != null
          ? BindingSection.fromJson(json['bindings'] as Map<String, dynamic>)
          : null,
      tests: json['tests'] != null
          ? TestSection.fromJson(json['tests'] as Map<String, dynamic>)
          : null,
      policies: json['policies'] != null
          ? PolicySection.fromJson(json['policies'] as Map<String, dynamic>)
          : null,
      profiles: json['profiles'] != null
          ? ProfilesSection.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
      factGraphSchema: json['factGraphSchema'] != null
          ? FactGraphSchema.fromJson(json['factGraphSchema'] as Map<String, dynamic>)
          : null,
      compatibility: json['compatibility'] != null
          ? CompatibilityConfig.fromJson(json['compatibility'] as Map<String, dynamic>)
          : null,
      integrity: json['integrity'] != null
          ? IntegrityConfig.fromJson(json['integrity'] as Map<String, dynamic>)
          : null,
      extensions: json['extensions'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'manifest': manifest.toJson(),
      if (ui != null) 'ui': ui!.toJson(),
      if (flow != null) 'flow': flow!.toJson(),
      if (skills != null) 'skills': skills!.toJson(),
      if (assets != null) 'assets': assets!.toJson(),
      if (knowledge != null) 'knowledge': knowledge!.toJson(),
      if (bindings != null) 'bindings': bindings!.toJson(),
      if (tests != null) 'tests': tests!.toJson(),
      if (policies != null) 'policies': policies!.toJson(),
      if (profiles != null) 'profiles': profiles!.toJson(),
      if (factGraphSchema != null) 'factGraphSchema': factGraphSchema!.toJson(),
      if (compatibility != null) 'compatibility': compatibility!.toJson(),
      if (integrity != null) 'integrity': integrity!.toJson(),
      if (extensions.isNotEmpty) 'extensions': extensions,
    };
  }

  /// Create a copy with modifications.
  McpBundle copyWith({
    String? schemaVersion,
    BundleManifest? manifest,
    UiSection? ui,
    FlowSection? flow,
    SkillSection? skills,
    AssetSection? assets,
    KnowledgeSection? knowledge,
    BindingSection? bindings,
    TestSection? tests,
    PolicySection? policies,
    ProfilesSection? profiles,
    FactGraphSchema? factGraphSchema,
    CompatibilityConfig? compatibility,
    IntegrityConfig? integrity,
    Map<String, dynamic>? extensions,
    String? directory,
  }) {
    return McpBundle(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      manifest: manifest ?? this.manifest,
      ui: ui ?? this.ui,
      flow: flow ?? this.flow,
      skills: skills ?? this.skills,
      assets: assets ?? this.assets,
      knowledge: knowledge ?? this.knowledge,
      bindings: bindings ?? this.bindings,
      tests: tests ?? this.tests,
      policies: policies ?? this.policies,
      profiles: profiles ?? this.profiles,
      factGraphSchema: factGraphSchema ?? this.factGraphSchema,
      compatibility: compatibility ?? this.compatibility,
      integrity: integrity ?? this.integrity,
      extensions: extensions ?? this.extensions,
      directory: directory ?? this.directory,
    );
  }

  /// Check if bundle has any content sections.
  bool get hasContent =>
      ui != null ||
      flow != null ||
      skills != null ||
      assets != null ||
      knowledge != null ||
      bindings != null ||
      tests != null ||
      policies != null ||
      profiles != null ||
      factGraphSchema != null;

  /// Get all section names that are present.
  List<String> get presentSections {
    final sections = <String>[];
    if (ui != null) sections.add('ui');
    if (flow != null) sections.add('flow');
    if (skills != null) sections.add('skills');
    if (assets != null) sections.add('assets');
    if (knowledge != null) sections.add('knowledge');
    if (bindings != null) sections.add('bindings');
    if (tests != null) sections.add('tests');
    if (policies != null) sections.add('policies');
    if (profiles != null) sections.add('profiles');
    if (factGraphSchema != null) sections.add('factGraphSchema');
    if (compatibility != null) sections.add('compatibility');
    if (integrity != null) sections.add('integrity');
    if (extensions.isNotEmpty) sections.add('extensions');
    return sections;
  }

  /// Check if bundle has policies.
  bool get hasPolicies => policies != null && policies!.policies.isNotEmpty;

  /// Check if bundle has FactGraph schema.
  bool get hasFactGraphSchema => factGraphSchema != null && factGraphSchema!.isNotEmpty;

  /// Check if bundle has integrity configuration.
  bool get hasIntegrity => integrity != null && integrity!.isValid;

  // ---------------------------------------------------------------------------
  // Reserved-folder I/O — see `docs/bundle_resource_io.md`.
  //
  // mcp_bundle is the single owner of bundle file I/O. Every consumer
  // (renderer, MCP server, designer, installer) reads / writes through
  // these accessors instead of `dart:io` directly so there is one parse
  // path, one set of safety checks, and one place that knows the on-disk
  // layout. Each reserved folder maps 1:1 to a sub-directory under the
  // bundle root.
  // ---------------------------------------------------------------------------

  /// Generic accessor — open the reserved sub-folder named [folder]
  /// (e.g. `'ui'`, `'assets'`, `'philosophy'`). Throws [StateError]
  /// when the bundle has no [directory] (loaded from inline JSON or
  /// remote fetch — there is nowhere to read from).
  BundleResources resources(BundleFolder folder) {
    final dir = directory;
    if (dir == null) {
      throw StateError(
        'Bundle has no on-disk directory — load it via '
        'McpBundleLoader.loadDirectory or .loadInstalled before reading '
        'reserved-folder resources.',
      );
    }
    return BundleResources(bundleRoot: dir, folder: folder);
  }

  /// UI definition files (mcp_ui_dsl JSON) under `<bundle>/ui/`.
  BundleResources get uiResources => resources(BundleFolder.ui);

  /// Binary or text assets under `<bundle>/assets/` (icons, splash, fonts).
  BundleResources get assetResources => resources(BundleFolder.assets);

  /// Skill / capability module definitions under `<bundle>/skills/`.
  BundleResources get skillResources => resources(BundleFolder.skills);

  /// Knowledge sources / retriever configs under `<bundle>/knowledge/`.
  BundleResources get knowledgeResources => resources(BundleFolder.knowledge);

  /// Profile definitions under `<bundle>/profiles/`.
  BundleResources get profileResources => resources(BundleFolder.profiles);

  /// Philosophy / ethos definitions under `<bundle>/philosophy/`.
  BundleResources get philosophyResources =>
      resources(BundleFolder.philosophy);
}
