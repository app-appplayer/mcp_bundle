/// Main MCP Bundle model.
///
/// Represents a complete MCP Bundle containing all sections.
library;

import 'manifest.dart';
import 'ui_section.dart';
import 'flow_section.dart';
import 'skill_section.dart';
import 'asset.dart';
import 'knowledge.dart';
import 'binding.dart';
import 'test_section.dart';

/// A complete MCP Bundle containing all packaged resources.
class McpBundle {
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

  /// Extensions for custom data.
  final Map<String, dynamic> extensions;

  const McpBundle({
    required this.manifest,
    this.ui,
    this.flow,
    this.skills,
    this.assets,
    this.knowledge,
    this.bindings,
    this.tests,
    this.extensions = const {},
  });

  /// Create from JSON.
  factory McpBundle.fromJson(Map<String, dynamic> json) {
    return McpBundle(
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
      extensions: json['extensions'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'manifest': manifest.toJson(),
      if (ui != null) 'ui': ui!.toJson(),
      if (flow != null) 'flow': flow!.toJson(),
      if (skills != null) 'skills': skills!.toJson(),
      if (assets != null) 'assets': assets!.toJson(),
      if (knowledge != null) 'knowledge': knowledge!.toJson(),
      if (bindings != null) 'bindings': bindings!.toJson(),
      if (tests != null) 'tests': tests!.toJson(),
      if (extensions.isNotEmpty) 'extensions': extensions,
    };
  }

  /// Create a copy with modifications.
  McpBundle copyWith({
    BundleManifest? manifest,
    UiSection? ui,
    FlowSection? flow,
    SkillSection? skills,
    AssetSection? assets,
    KnowledgeSection? knowledge,
    BindingSection? bindings,
    TestSection? tests,
    Map<String, dynamic>? extensions,
  }) {
    return McpBundle(
      manifest: manifest ?? this.manifest,
      ui: ui ?? this.ui,
      flow: flow ?? this.flow,
      skills: skills ?? this.skills,
      assets: assets ?? this.assets,
      knowledge: knowledge ?? this.knowledge,
      bindings: bindings ?? this.bindings,
      tests: tests ?? this.tests,
      extensions: extensions ?? this.extensions,
    );
  }

  /// Check if bundle has any content sections.
  bool get hasContent =>
      ui != null ||
      flow != null ||
      skills != null ||
      assets != null ||
      knowledge != null;

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
    return sections;
  }
}
