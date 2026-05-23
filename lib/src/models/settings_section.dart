/// `SettingsSection` — the bundle's user-settings form schema (spec §06).
///
/// Top-level section on `McpBundle.settingsSection`. Distinct from
/// `WiringSection.settings[]` which carries trigger actions surfaced
/// in the settings dialog footer; this section carries the form
/// schema itself (sections × fields). Hosts that do not render a
/// settings UI MAY ignore this section.
library;

/// One form field inside a settings section. Field types are
/// host-defined; common values seen in workspace bundles: `text`,
/// `bool`, `menu`, `folder`, `file`, `number`. Hosts MAY add more.
class SettingsField {
  const SettingsField({
    required this.key,
    required this.label,
    required this.type,
    this.description,
    this.options,
    this.value,
    this.extra = const {},
  });

  final String key;
  final String label;
  final String type;
  final String? description;
  final List<String>? options;
  final dynamic value;

  /// Free-form pass-through for host-specific field properties (min /
  /// max / placeholder / etc.). Preserves anything the loader does not
  /// recognise so authoring round-trip never loses fields.
  final Map<String, dynamic> extra;

  factory SettingsField.fromJson(Map<String, dynamic> json) {
    final known = const {
      'key', 'label', 'type', 'description', 'options', 'value',
    };
    final extra = <String, dynamic>{
      for (final e in json.entries)
        if (!known.contains(e.key)) e.key: e.value,
    };
    final opts = json['options'];
    return SettingsField(
      key: (json['key'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'text',
      description: json['description'] as String?,
      options: opts is List ? opts.map((e) => e.toString()).toList() : null,
      value: json['value'],
      extra: extra,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'type': type,
        if (description != null) 'description': description,
        if (options != null) 'options': options,
        if (value != null) 'value': value,
        ...extra,
      };

  SettingsField copyWith({
    String? key,
    String? label,
    String? type,
    String? description,
    List<String>? options,
    dynamic value,
    Map<String, dynamic>? extra,
  }) =>
      SettingsField(
        key: key ?? this.key,
        label: label ?? this.label,
        type: type ?? this.type,
        description: description ?? this.description,
        options: options ?? this.options,
        value: value ?? this.value,
        extra: extra ?? this.extra,
      );
}

class SettingsSectionEntry {
  const SettingsSectionEntry({
    required this.key,
    required this.label,
    this.fields = const [],
  });

  final String key;
  final String label;
  final List<SettingsField> fields;

  factory SettingsSectionEntry.fromJson(Map<String, dynamic> json) {
    final raw = json['fields'];
    return SettingsSectionEntry(
      key: (json['key'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      fields: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(SettingsField.fromJson)
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'fields': fields.map((f) => f.toJson()).toList(),
      };

  SettingsSectionEntry copyWith({
    String? key,
    String? label,
    List<SettingsField>? fields,
  }) =>
      SettingsSectionEntry(
        key: key ?? this.key,
        label: label ?? this.label,
        fields: fields ?? this.fields,
      );
}

class SettingsSection {
  const SettingsSection({
    this.schemaVersion = '1.0.0',
    this.sections = const [],
  });

  final String schemaVersion;
  final List<SettingsSectionEntry> sections;

  factory SettingsSection.fromJson(Map<String, dynamic> json) {
    final raw = json['sections'];
    return SettingsSection(
      schemaVersion: (json['schemaVersion'] as String?) ?? '1.0.0',
      sections: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(SettingsSectionEntry.fromJson)
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'sections': sections.map((s) => s.toJson()).toList(),
      };

  SettingsSection copyWith({
    String? schemaVersion,
    List<SettingsSectionEntry>? sections,
  }) =>
      SettingsSection(
        schemaVersion: schemaVersion ?? this.schemaVersion,
        sections: sections ?? this.sections,
      );
}
