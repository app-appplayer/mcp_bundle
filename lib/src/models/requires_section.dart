/// Portability contract — declares which host capabilities the bundle
/// needs to function. Hosts read this section to refuse activation when
/// the bundle's requirements exceed the host's advertised surface.
///
/// Two parallel lists:
///
/// * [builtinAtoms] — coarse capability categories (e.g. `mcp`, `fs`,
///   `ui`, `workspace`, `kb`, `agent`, `bus`, `bundle`). Each entry
///   names an atom group the bundle's JS / DSL surface may call.
///   Studio advertises a superset; AppPlayer advertises a smaller set.
///   A bundle declaring `['workspace', 'kb', 'agent']` is Studio-only.
/// * [builtinTools] — fine-grained host tool names (e.g.
///   `studio.fs.read`, `studio.workspace.save`). Each entry names a
///   specific tool that must be present on the host's MCP server for
///   the bundle to activate. Strict gate — missing entries cause
///   activation refusal at install time.
///
/// Authoring convention: leave both empty when the bundle has no host
/// dependency (pure DSL + content). Declare only what the bundle
/// actually uses — over-declaring reduces portability across hosts.
library;

class RequiresSection {
  /// Schema version for this section. Default `'1.0.0'`.
  final String schemaVersion;

  /// Coarse atom-category requirements (`mcp`, `fs`, `ui`, ...).
  final List<String> builtinAtoms;

  /// Specific host-tool name requirements (`studio.workspace.save`, ...).
  final List<String> builtinTools;

  const RequiresSection({
    this.schemaVersion = '1.0.0',
    this.builtinAtoms = const <String>[],
    this.builtinTools = const <String>[],
    bool hadExplicitAtoms = false,
    bool hadExplicitTools = false,
  })  : _hadExplicitAtoms = hadExplicitAtoms,
        _hadExplicitTools = hadExplicitTools;

  /// True when the bundle declares no host dependencies — fully
  /// portable, runs on any host.
  bool get isEmpty => builtinAtoms.isEmpty && builtinTools.isEmpty;

  bool get isNotEmpty => !isEmpty;

  factory RequiresSection.fromJson(Map<String, dynamic> json) {
    return RequiresSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      builtinAtoms: <String>[
        if (json['builtinAtoms'] is List)
          for (final a in json['builtinAtoms'] as List)
            if (a is String) a,
      ],
      builtinTools: <String>[
        if (json['builtinTools'] is List)
          for (final t in json['builtinTools'] as List)
            if (t is String) t,
      ],
      hadExplicitAtoms: json.containsKey('builtinAtoms'),
      hadExplicitTools: json.containsKey('builtinTools'),
    );
  }

  /// Whether the source JSON carried an explicit `builtinAtoms`
  /// key (even when empty). Distinguishes "author declared []
  /// — bundle is fully portable in their intent" from "field
  /// absent — author did not declare anything". Preserved across
  /// round-trip so author intent survives.
  final bool _hadExplicitAtoms;
  final bool _hadExplicitTools;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        if (builtinAtoms.isNotEmpty || _hadExplicitAtoms)
          'builtinAtoms': builtinAtoms,
        if (builtinTools.isNotEmpty || _hadExplicitTools)
          'builtinTools': builtinTools,
      };

  RequiresSection copyWith({
    String? schemaVersion,
    List<String>? builtinAtoms,
    List<String>? builtinTools,
  }) =>
      RequiresSection(
        schemaVersion: schemaVersion ?? this.schemaVersion,
        builtinAtoms: builtinAtoms ?? this.builtinAtoms,
        builtinTools: builtinTools ?? this.builtinTools,
      );
}
