/// Main MCP Bundle model.
///
/// Represents a complete MCP Bundle containing all sections.
library;

import '../io/bundle_resources.dart';
import 'agent_section.dart';
import 'asset.dart';
import 'binding.dart';
import 'chat_section.dart';
import 'fact_graph_schema.dart';
import 'fact_graph_section.dart';
import 'facts_section.dart';
import 'flow_section.dart';
import 'integrity.dart';
import 'knowledge.dart';
import 'manifest.dart';
import 'philosophy_section.dart';
import 'pipelines_section.dart';
import 'policy.dart';
import 'profile_section.dart';
import 'requires_section.dart';
import 'runbooks_section.dart';
import 'settings_section.dart';
import 'skill_section.dart';
import 'test_section.dart';
import 'tools_section.dart';
import 'ui_section.dart';
import 'wiring_section.dart';
import 'workflows_section.dart';

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

  /// Philosophy section with guiding principles + examples.
  final PhilosophySection? philosophy;

  /// Agents section with agent definitions (4-axis bindings + runtime cfg).
  final AgentsSection? agents;

  /// Facts section — atomic subject-predicate-object triples carried
  /// inline in `manifest.json` under the `facts` key.
  final FactsSection? facts;

  /// Workflows section — ordered step sequences carried inline in
  /// `manifest.json` under the `workflows` key.
  final WorkflowsSection? workflows;

  /// Pipelines section — ordered stage sequences carried inline in
  /// `manifest.json` under the `pipelines` key.
  final PipelinesSection? pipelines;

  /// Runbooks section — ordered procedure sequences carried inline in
  /// `manifest.json` under the `runbooks` key.
  final RunbooksSection? runbooks;

  /// Tools section — host-callable tool entries (host builtin / MCP /
  /// cloud / bundled JS) carried inline in `manifest.json` under the
  /// `tools` key. Studio · AppPlayer read this to discover what tools a
  /// bundle exposes and how to dispatch them.
  final ToolsSection? tools;

  /// Portability contract — declares which host capabilities the
  /// bundle needs (atom categories + specific host-tool names).
  /// Carried inline in `manifest.json` under the `requires` key. Both
  /// Studio and AppPlayer enforce this gate at activation: bundles
  /// requiring atoms / tools the host doesn't advertise are refused.
  /// `null` = no declared requirements (fully portable).
  final RequiresSection? requires;

  /// FactGraph schema definitions.
  final FactGraphSchema? factGraphSchema;

  /// FactGraph instance data (entities, facts, relations) — embedded
  /// inline or referenced externally per [FactGraphSection.mode].
  final FactGraphSection? factGraphSection;

  /// Compatibility configuration.
  final CompatibilityConfig? compatibility;

  /// Integrity configuration.
  final IntegrityConfig? integrity;

  /// Chat-UI binding surface — slash commands + default agent
  /// (spec §06.5). Top-level per the wiring spec; loaders accept
  /// legacy `manifest.chat` as alias.
  final ChatSection? chat;

  /// Chrome wiring surface — domainActions / lifecycle / settings
  /// (spec §06.2 – §06.4). Top-level per the wiring spec; loaders
  /// accept legacy `manifest.wiring` as alias.
  final WiringSection? wiring;

  /// User settings form schema — sections × fields. Distinct from
  /// `WiringSection.settings[]` which carries trigger actions.
  /// Top-level per the wiring spec; loaders accept legacy
  /// `manifest.settings` as alias.
  final SettingsSection? settingsSection;

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
      philosophy: json['philosophy'] != null
          ? PhilosophySection.fromJson(
              json['philosophy'] as Map<String, dynamic>)
          : null,
      agents: json['agents'] != null
          ? AgentsSection.fromJson(json['agents'] as Map<String, dynamic>)
          : null,
      facts: json['facts'] != null
          ? FactsSection.fromJson(json['facts'] as Map<String, dynamic>)
          : null,
      workflows: json['workflows'] != null
          ? WorkflowsSection.fromJson(json['workflows'] as Map<String, dynamic>)
          : null,
      pipelines: json['pipelines'] != null
          ? PipelinesSection.fromJson(json['pipelines'] as Map<String, dynamic>)
          : null,
      runbooks: json['runbooks'] != null
          ? RunbooksSection.fromJson(json['runbooks'] as Map<String, dynamic>)
          : null,
      tools: json['tools'] != null
          ? ToolsSection.fromJson(json['tools'] as Map<String, dynamic>)
          : null,
      requires: json['requires'] != null
          ? RequiresSection.fromJson(json['requires'] as Map<String, dynamic>)
          : null,
      factGraphSchema: json['factGraphSchema'] != null
          ? FactGraphSchema.fromJson(json['factGraphSchema'] as Map<String, dynamic>)
          : null,
      factGraphSection: json['factGraphSection'] != null
          ? FactGraphSection.fromJson(json['factGraphSection'] as Map<String, dynamic>)
          : null,
      compatibility: json['compatibility'] != null
          ? CompatibilityConfig.fromJson(json['compatibility'] as Map<String, dynamic>)
          : null,
      integrity: json['integrity'] != null
          ? IntegrityConfig.fromJson(json['integrity'] as Map<String, dynamic>)
          : null,
      chat: _resolveSection(
        json,
        key: 'chat',
        fromJson: ChatSection.fromJson,
      ),
      wiring: _resolveSection(
        json,
        key: 'wiring',
        fromJson: WiringSection.fromJson,
      ),
      settingsSection: _resolveSection(
        json,
        key: 'settings',
        fromJson: SettingsSection.fromJson,
      ),
      extensions: _absorbExtensions(json),
    );
  }

  /// Merge author-declared `extensions` with any top-level key the
  /// model does not yet recognise (forward-compat — bundles
  /// authored against a future spec extension round-trip through
  /// today's loader without silent loss). The captured unknowns
  /// land under reserved `_unmodeledTopLevel` and are re-spread
  /// back to the top level by [toJson].
  static Map<String, dynamic> _absorbExtensions(Map<String, dynamic> json) {
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
    final raw = json['extensions'];
    return <String, dynamic>{
      if (raw is Map<String, dynamic>) ...raw,
      if (unmodeled.isNotEmpty) '_unmodeledTopLevel': unmodeled,
    };
  }

  /// Spec §06 location resolution: top-level wins; manifest-nested
  /// (legacy `manifest.<key>`) accepted as fallback so older bundles
  /// that embedded chat / wiring / settings inline keep loading.
  static T? _resolveSection<T>(
    Map<String, dynamic> json, {
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    final top = json[key];
    if (top is Map<String, dynamic>) return fromJson(top);
    final manifest = json['manifest'];
    if (manifest is Map<String, dynamic>) {
      final nested = manifest[key];
      if (nested is Map<String, dynamic>) return fromJson(nested);
    }
    return null;
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
      if (philosophy != null) 'philosophy': philosophy!.toJson(),
      if (agents != null) 'agents': agents!.toJson(),
      if (facts != null) 'facts': facts!.toJson(),
      if (workflows != null) 'workflows': workflows!.toJson(),
      if (pipelines != null) 'pipelines': pipelines!.toJson(),
      if (runbooks != null) 'runbooks': runbooks!.toJson(),
      if (tools != null) 'tools': tools!.toJson(),
      if (requires != null) 'requires': requires!.toJson(),
      if (factGraphSchema != null) 'factGraphSchema': factGraphSchema!.toJson(),
      if (factGraphSection != null) 'factGraphSection': factGraphSection!.toJson(),
      if (compatibility != null) 'compatibility': compatibility!.toJson(),
      if (integrity != null) 'integrity': integrity!.toJson(),
      if (chat != null) 'chat': chat!.toJson(),
      if (wiring != null) 'wiring': wiring!.toJson(),
      if (settingsSection != null) 'settings': settingsSection!.toJson(),
      // Forward-compat: re-spread any keys the loader captured into
      // `extensions._unmodeledTopLevel` back at the top level so
      // round-trip through an older loader does not erase keys an
      // newer spec extension may have introduced.
      ..._spreadUnmodeled(),
      if (_extensionsWithoutReserved().isNotEmpty)
        'extensions': _extensionsWithoutReserved(),
    };
  }

  Map<String, dynamic> _spreadUnmodeled() {
    final um = extensions['_unmodeledTopLevel'];
    if (um is Map<String, dynamic>) return um;
    return const {};
  }

  Map<String, dynamic> _extensionsWithoutReserved() {
    return <String, dynamic>{
      for (final e in extensions.entries)
        if (e.key != '_unmodeledTopLevel') e.key: e.value,
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
    PhilosophySection? philosophy,
    AgentsSection? agents,
    FactsSection? facts,
    WorkflowsSection? workflows,
    PipelinesSection? pipelines,
    RunbooksSection? runbooks,
    ToolsSection? tools,
    RequiresSection? requires,
    FactGraphSchema? factGraphSchema,
    FactGraphSection? factGraphSection,
    CompatibilityConfig? compatibility,
    IntegrityConfig? integrity,
    ChatSection? chat,
    WiringSection? wiring,
    SettingsSection? settingsSection,
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
      philosophy: philosophy ?? this.philosophy,
      agents: agents ?? this.agents,
      facts: facts ?? this.facts,
      workflows: workflows ?? this.workflows,
      pipelines: pipelines ?? this.pipelines,
      runbooks: runbooks ?? this.runbooks,
      tools: tools ?? this.tools,
      requires: requires ?? this.requires,
      factGraphSchema: factGraphSchema ?? this.factGraphSchema,
      factGraphSection: factGraphSection ?? this.factGraphSection,
      compatibility: compatibility ?? this.compatibility,
      integrity: integrity ?? this.integrity,
      chat: chat ?? this.chat,
      wiring: wiring ?? this.wiring,
      settingsSection: settingsSection ?? this.settingsSection,
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
      philosophy != null ||
      agents != null ||
      facts != null ||
      workflows != null ||
      pipelines != null ||
      runbooks != null ||
      tools != null ||
      requires != null ||
      factGraphSchema != null ||
      factGraphSection != null ||
      chat != null ||
      wiring != null ||
      settingsSection != null;

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
    if (philosophy != null) sections.add('philosophy');
    if (agents != null) sections.add('agents');
    if (facts != null) sections.add('facts');
    if (workflows != null) sections.add('workflows');
    if (pipelines != null) sections.add('pipelines');
    if (runbooks != null) sections.add('runbooks');
    if (tools != null) sections.add('tools');
    if (requires != null) sections.add('requires');
    if (factGraphSchema != null) sections.add('factGraphSchema');
    if (factGraphSection != null) sections.add('factGraphSection');
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
  // Reserved-folder I/O.
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

  /// Atomic subject-predicate-object fact records under `<bundle>/facts/`.
  /// Companion to the inline `manifest.facts[]` carry.
  BundleResources get factsResources => resources(BundleFolder.facts);

  /// Workflow definitions (ordered step sequences) under
  /// `<bundle>/workflows/`. Companion to the inline `manifest.workflows[]`
  /// carry.
  BundleResources get workflowsResources => resources(BundleFolder.workflows);

  /// Pipeline definitions (ordered stage sequences) under
  /// `<bundle>/pipelines/`. Companion to the inline `manifest.pipelines[]`
  /// carry.
  BundleResources get pipelinesResources => resources(BundleFolder.pipelines);

  /// Runbook definitions (ordered procedure sequences) under
  /// `<bundle>/runbooks/`. Companion to the inline `manifest.runbooks[]`
  /// carry.
  BundleResources get runbooksResources => resources(BundleFolder.runbooks);

  /// Tool definitions (host-callable tool entries) under
  /// `<bundle>/tools/`. Companion to the inline `manifest.tools[]` carry.
  BundleResources get toolsResources => resources(BundleFolder.tools);

  /// Profile definitions under `<bundle>/profiles/`.
  BundleResources get profileResources => resources(BundleFolder.profiles);

  /// Philosophy / ethos definitions under `<bundle>/philosophy/`.
  BundleResources get philosophyResources =>
      resources(BundleFolder.philosophy);

  /// Agent definitions under `<bundle>/agents/`.
  BundleResources get agentResources => resources(BundleFolder.agents);
}
