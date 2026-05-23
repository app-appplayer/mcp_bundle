/// `WiringSection` — the bundle's chrome-host binding surface (spec §06).
///
/// Top-level section on `McpBundle.wiring`. Three sub-lists bind
/// bundle-declared tools to host chrome slots: row-2 domain icons,
/// system lifecycle slots, settings dialog action rows. Hosts that
/// do not surface chrome MAY ignore this section.
library;

/// Discriminator for `domainActions[]` entries.
enum DomainActionKind { button, selectGroup }

/// `kind: "selectGroup"` item.
class DomainActionSelectItem {
  const DomainActionSelectItem({
    required this.icon,
    required this.tool,
    required this.value,
    this.tooltip,
    this.args,
  });

  final String icon;
  final String tool;
  final dynamic value;
  final String? tooltip;
  final Map<String, dynamic>? args;

  factory DomainActionSelectItem.fromJson(Map<String, dynamic> json) {
    final args = json['args'] ?? json['arguments'];
    return DomainActionSelectItem(
      icon: (json['icon'] as String?) ?? '',
      tool: (json['tool'] as String?) ?? '',
      value: json['value'],
      tooltip: json['tooltip'] as String?,
      args: args is Map<String, dynamic> ? args : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'icon': icon,
        'tool': tool,
        'value': value,
        if (tooltip != null) 'tooltip': tooltip,
        if (args != null && args!.isNotEmpty) 'args': args,
      };
}

/// `domainActions[]` entry — discriminated by [kind]. Either a
/// single-click [button] (carries `tool`/`icon`/`tooltip`/`args`) or a
/// [selectGroup] (carries `stateKey`/`items`). Hosts switch on
/// [kind] to render.
class DomainAction {
  const DomainAction({
    required this.kind,
    this.tool,
    this.icon,
    this.tooltip,
    this.args,
    this.stateKey,
    this.items = const [],
  });

  final DomainActionKind kind;
  // button-mode fields
  final String? tool;
  final String? icon;
  final String? tooltip;
  final Map<String, dynamic>? args;
  // selectGroup-mode fields
  final String? stateKey;
  final List<DomainActionSelectItem> items;

  factory DomainAction.fromJson(Map<String, dynamic> json) {
    final kindRaw = json['kind'] as String?;
    final kind = kindRaw == 'selectGroup'
        ? DomainActionKind.selectGroup
        : DomainActionKind.button;
    if (kind == DomainActionKind.selectGroup) {
      final raw = json['items'];
      return DomainAction(
        kind: kind,
        stateKey: json['stateKey'] as String?,
        items: raw is List
            ? raw
                .whereType<Map<String, dynamic>>()
                .map(DomainActionSelectItem.fromJson)
                .toList()
            : const [],
      );
    }
    final args = json['args'] ?? json['arguments'];
    return DomainAction(
      kind: kind,
      tool: json['tool'] as String?,
      icon: json['icon'] as String?,
      tooltip: json['tooltip'] as String?,
      args: args is Map<String, dynamic> ? args : null,
    );
  }

  Map<String, dynamic> toJson() {
    if (kind == DomainActionKind.selectGroup) {
      return {
        'kind': 'selectGroup',
        if (stateKey != null) 'stateKey': stateKey,
        'items': items.map((e) => e.toJson()).toList(),
      };
    }
    return {
      'kind': 'button',
      if (tool != null) 'tool': tool,
      if (icon != null) 'icon': icon,
      if (tooltip != null) 'tooltip': tooltip,
      if (args != null && args!.isNotEmpty) 'args': args,
    };
  }
}

/// `lifecycle[]` entry — binds a host-defined slot (e.g. `project.save`)
/// to a tool dispatch (optionally with fixed args).
class LifecycleBinding {
  const LifecycleBinding({
    required this.slot,
    required this.tool,
    this.args,
  });

  final String slot;
  final String tool;
  final Map<String, dynamic>? args;

  factory LifecycleBinding.fromJson(Map<String, dynamic> json) {
    final args = json['args'];
    return LifecycleBinding(
      slot: (json['slot'] as String?) ?? '',
      tool: (json['tool'] as String?) ?? '',
      args: args is Map<String, dynamic> ? args : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'slot': slot,
        'tool': tool,
        if (args != null && args!.isNotEmpty) 'args': args,
      };
}

/// `settings[]` entry — row rendered in the settings dialog footer
/// area. Distinct from the form-schema [SettingsSection]; this is
/// the trigger-action row.
class SettingsAction {
  const SettingsAction({
    required this.label,
    required this.tool,
    this.icon,
    this.args,
    this.tooltip,
  });

  final String label;
  final String tool;
  final String? icon;
  final Map<String, dynamic>? args;
  final String? tooltip;

  factory SettingsAction.fromJson(Map<String, dynamic> json) {
    final args = json['args'];
    return SettingsAction(
      label: (json['label'] as String?) ?? '',
      tool: (json['tool'] as String?) ?? '',
      icon: json['icon'] as String?,
      args: args is Map<String, dynamic> ? args : null,
      tooltip: json['tooltip'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'tool': tool,
        if (icon != null) 'icon': icon,
        if (args != null && args!.isNotEmpty) 'args': args,
        if (tooltip != null) 'tooltip': tooltip,
      };
}

class WiringSection {
  const WiringSection({
    this.schemaVersion = '1.0.0',
    this.domainActions = const [],
    this.lifecycle = const [],
    this.settings = const [],
    this.lifecycleStateBindings = const {},
    this.titlebar,
    this.statusbar,
  });

  final String schemaVersion;
  final List<DomainAction> domainActions;
  final List<LifecycleBinding> lifecycle;
  final List<SettingsAction> settings;

  /// Optional map from lifecycle slot name (e.g. `project.save`) to
  /// a runtime state key the chrome should mirror when the slot
  /// fires. Hosts that do not implement state binding may ignore.
  final Map<String, String> lifecycleStateBindings;

  /// Single payload string rendered in the host chrome's titlebar
  /// user-zone (after fixed server / status / version pills). The
  /// bundle's tools combine multiple pieces before assigning — the
  /// host never splits this zone. `{{key}}` tokens resolve against
  /// the active tab's runtime state by host policy. Hosts that do
  /// not surface a titlebar user-zone MAY ignore.
  final String? titlebar;

  /// Same payload pattern as [titlebar] but rendered in the host's
  /// statusbar user-zone (between fixed lint group and right-edge
  /// spec / locale). Hosts MAY ignore.
  final String? statusbar;

  factory WiringSection.fromJson(Map<String, dynamic> json) {
    List<T> listOf<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
      return raw is List
          ? raw.whereType<Map<String, dynamic>>().map(f).toList()
          : <T>[];
    }

    final lsb = json['lifecycleStateBindings'];
    return WiringSection(
      schemaVersion: (json['schemaVersion'] as String?) ?? '1.0.0',
      domainActions:
          listOf<DomainAction>(json['domainActions'], DomainAction.fromJson),
      lifecycle: listOf<LifecycleBinding>(
          json['lifecycle'], LifecycleBinding.fromJson),
      settings:
          listOf<SettingsAction>(json['settings'], SettingsAction.fromJson),
      lifecycleStateBindings: lsb is Map
          ? {
              for (final e in lsb.entries)
                if (e.key is String && e.value is String)
                  e.key as String: e.value as String,
            }
          : const {},
      titlebar: json['titlebar'] is String ? json['titlebar'] as String : null,
      statusbar:
          json['statusbar'] is String ? json['statusbar'] as String : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'domainActions': domainActions.map((e) => e.toJson()).toList(),
        'lifecycle': lifecycle.map((e) => e.toJson()).toList(),
        if (settings.isNotEmpty)
          'settings': settings.map((e) => e.toJson()).toList(),
        if (lifecycleStateBindings.isNotEmpty)
          'lifecycleStateBindings': lifecycleStateBindings,
        if (titlebar != null) 'titlebar': titlebar,
        if (statusbar != null) 'statusbar': statusbar,
      };

  WiringSection copyWith({
    String? schemaVersion,
    List<DomainAction>? domainActions,
    List<LifecycleBinding>? lifecycle,
    List<SettingsAction>? settings,
    Map<String, String>? lifecycleStateBindings,
    String? titlebar,
    String? statusbar,
  }) =>
      WiringSection(
        schemaVersion: schemaVersion ?? this.schemaVersion,
        domainActions: domainActions ?? this.domainActions,
        lifecycle: lifecycle ?? this.lifecycle,
        settings: settings ?? this.settings,
        lifecycleStateBindings:
            lifecycleStateBindings ?? this.lifecycleStateBindings,
        titlebar: titlebar ?? this.titlebar,
        statusbar: statusbar ?? this.statusbar,
      );
}
