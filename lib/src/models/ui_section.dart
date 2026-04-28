/// UI Section model for MCP Bundle.
///
/// The canonical representation of UI in a bundle is the on-disk
/// `ui/` reserved folder, accessed through `BundleResources`
/// (`bundle.uiResources.list/readJson/...`). Each `ui/<rel>.json` maps
/// to a `ui://<rel>` MCP resource URI — the bundle is a filesystem
/// snapshot of the URI space an MCP server would expose.
///
/// The typed fields (`pages`, `widgets`, `theme`, `navigation`,
/// `state`) on this class are deprecated. They exist only as a
/// forward-compat round-trip channel for legacy bundles whose
/// `manifest.json` carries inline `ui` data. New bundle authoring
/// tools must write content under `ui/` instead. Targeted for full
/// removal in 0.6.0.
library;

/// UI section. Typed fields are deprecated; consumers must read the
/// `ui/` reserved folder via `BundleResources`. The original `ui:`
/// JSON map is preserved verbatim under [raw] so `toJson` round-trips.
class UiSection {
  /// Schema version for UI section.
  final String schemaVersion;

  /// List of pages in the application.
  ///
  /// Deprecated: read `ui/<rel>.json` files via `BundleResources`
  /// instead of consulting this typed list.
  @Deprecated(
    'Read ui/ folder via BundleResources. UiSection typed fields '
    'remain only for forward-compat round-trip. Removal target 0.6.0.',
  )
  final List<PageDefinition> pages;

  /// Reusable widget definitions.
  @Deprecated(
    'Read ui/ folder via BundleResources. UiSection typed fields '
    'remain only for forward-compat round-trip. Removal target 0.6.0.',
  )
  final Map<String, WidgetDefinition> widgets;

  /// Theme configuration.
  @Deprecated(
    'Read ui/ folder via BundleResources. UiSection typed fields '
    'remain only for forward-compat round-trip. Removal target 0.6.0.',
  )
  final ThemeConfig? theme;

  /// Navigation configuration.
  @Deprecated(
    'Read ui/ folder via BundleResources. UiSection typed fields '
    'remain only for forward-compat round-trip. Removal target 0.6.0.',
  )
  final NavigationConfig? navigation;

  /// Global UI state definitions.
  @Deprecated(
    'Read ui/ folder via BundleResources. UiSection typed fields '
    'remain only for forward-compat round-trip. Removal target 0.6.0.',
  )
  final Map<String, StateDefinition> state;

  /// The original `ui:` JSON map preserved verbatim for round-trip
  /// safety. `fromJson` populates this from the raw input;
  /// `toJson` re-emits it (instead of the deprecated typed fields)
  /// so unknown keys and ordering survive a load/save cycle.
  final Map<String, dynamic> raw;

  // ignore: deprecated_member_use_from_same_package
  const UiSection({
    this.schemaVersion = '1.0.0',
    this.pages = const [],
    this.widgets = const {},
    this.theme,
    this.navigation,
    this.state = const {},
    this.raw = const {},
  });

  factory UiSection.fromJson(Map<String, dynamic> json) {
    // Accept both 'pages' and 'screens' (backward compat) keys
    final pagesList = json['pages'] ?? json['screens'];
    return UiSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      pages: (pagesList as List<dynamic>?)
              ?.map((e) => PageDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      widgets: (json['widgets'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              WidgetDefinition.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      theme: json['theme'] != null
          ? ThemeConfig.fromJson(json['theme'] as Map<String, dynamic>)
          : null,
      navigation: json['navigation'] != null
          ? NavigationConfig.fromJson(json['navigation'] as Map<String, dynamic>)
          : null,
      state: (json['state'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              StateDefinition.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }

  /// Re-emits [raw] verbatim (the original input) so unknown keys and
  /// ordering survive a load → toJson cycle. When [raw] is empty
  /// (constructed in code), falls back to serialising the typed
  /// fields for backward compatibility.
  Map<String, dynamic> toJson() {
    if (raw.isNotEmpty) {
      return Map<String, dynamic>.from(raw);
    }
    return {
      'schemaVersion': schemaVersion,
      // ignore: deprecated_member_use_from_same_package
      if (pages.isNotEmpty) 'pages': pages.map((s) => s.toJson()).toList(),
      // ignore: deprecated_member_use_from_same_package
      if (widgets.isNotEmpty)
        // ignore: deprecated_member_use_from_same_package
        'widgets': widgets.map((k, v) => MapEntry(k, v.toJson())),
      // ignore: deprecated_member_use_from_same_package
      if (theme != null) 'theme': theme!.toJson(),
      // ignore: deprecated_member_use_from_same_package
      if (navigation != null) 'navigation': navigation!.toJson(),
      // ignore: deprecated_member_use_from_same_package
      if (state.isNotEmpty)
        // ignore: deprecated_member_use_from_same_package
        'state': state.map((k, v) => MapEntry(k, v.toJson())),
    };
  }
}

/// Page definition.
class PageDefinition {
  /// Page identifier.
  final String id;

  /// Page name.
  final String name;

  /// Route path.
  final String? route;

  /// Root widget for the page.
  final WidgetNode root;

  /// Page parameters.
  final List<ParameterDef> parameters;

  /// Page-level state.
  final Map<String, StateDefinition> state;

  /// Page lifecycle hooks.
  final LifecycleHooks? lifecycle;

  const PageDefinition({
    required this.id,
    required this.name,
    this.route,
    required this.root,
    this.parameters = const [],
    this.state = const {},
    this.lifecycle,
  });

  factory PageDefinition.fromJson(Map<String, dynamic> json) {
    return PageDefinition(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      route: json['route'] as String?,
      root: WidgetNode.fromJson(json['root'] as Map<String, dynamic>? ?? {}),
      parameters: (json['parameters'] as List<dynamic>?)
              ?.map((e) => ParameterDef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      state: (json['state'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              StateDefinition.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      lifecycle: json['lifecycle'] != null
          ? LifecycleHooks.fromJson(json['lifecycle'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (route != null) 'route': route,
      'root': root.toJson(),
      if (parameters.isNotEmpty)
        'parameters': parameters.map((p) => p.toJson()).toList(),
      if (state.isNotEmpty)
        'state': state.map((k, v) => MapEntry(k, v.toJson())),
      if (lifecycle != null) 'lifecycle': lifecycle!.toJson(),
    };
  }
}

/// Backward compatibility alias.
typedef ScreenDefinition = PageDefinition;

/// Widget node in the UI tree.
class WidgetNode {
  /// Widget type.
  final String type;

  /// Widget properties.
  final Map<String, dynamic> props;

  /// Child widget(s).
  final List<WidgetNode> children;

  /// Conditional rendering expression.
  final String? condition;

  /// Event handlers.
  final Map<String, ActionDef> actions;

  /// Data binding expression.
  final String? binding;

  const WidgetNode({
    required this.type,
    this.props = const {},
    this.children = const [],
    this.condition,
    this.actions = const {},
    this.binding,
  });

  factory WidgetNode.fromJson(Map<String, dynamic> json) {
    return WidgetNode(
      type: json['type'] as String? ?? 'Container',
      props: json['props'] as Map<String, dynamic>? ?? {},
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => WidgetNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      condition: json['condition'] as String?,
      actions: (json['actions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              ActionDef.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      binding: json['binding'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (props.isNotEmpty) 'props': props,
      if (children.isNotEmpty)
        'children': children.map((c) => c.toJson()).toList(),
      if (condition != null) 'condition': condition,
      if (actions.isNotEmpty)
        'actions': actions.map((k, v) => MapEntry(k, v.toJson())),
      if (binding != null) 'binding': binding,
    };
  }
}

/// Reusable widget definition.
class WidgetDefinition {
  /// Widget name.
  final String name;

  /// Widget description.
  final String? description;

  /// Widget parameters.
  final List<ParameterDef> parameters;

  /// Widget template.
  final WidgetNode template;

  const WidgetDefinition({
    required this.name,
    this.description,
    this.parameters = const [],
    required this.template,
  });

  factory WidgetDefinition.fromJson(Map<String, dynamic> json) {
    return WidgetDefinition(
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      parameters: (json['parameters'] as List<dynamic>?)
              ?.map((e) => ParameterDef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      template: WidgetNode.fromJson(
          json['template'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (parameters.isNotEmpty)
        'parameters': parameters.map((p) => p.toJson()).toList(),
      'template': template.toJson(),
    };
  }
}

/// Parameter definition.
class ParameterDef {
  /// Parameter name.
  final String name;

  /// Parameter type.
  final String type;

  /// Whether required.
  final bool required;

  /// Default value.
  final dynamic defaultValue;

  /// Description.
  final String? description;

  const ParameterDef({
    required this.name,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.description,
  });

  factory ParameterDef.fromJson(Map<String, dynamic> json) {
    return ParameterDef(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'string',
      required: json['required'] as bool? ?? false,
      defaultValue: json['default'],
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      if (required) 'required': required,
      if (defaultValue != null) 'default': defaultValue,
      if (description != null) 'description': description,
    };
  }
}

/// State definition.
class StateDefinition {
  /// Initial value.
  final dynamic initialValue;

  /// State type.
  final String type;

  /// Whether persisted.
  final bool persist;

  /// Computed expression.
  final String? computed;

  const StateDefinition({
    this.initialValue,
    this.type = 'dynamic',
    this.persist = false,
    this.computed,
  });

  factory StateDefinition.fromJson(Map<String, dynamic> json) {
    return StateDefinition(
      initialValue: json['initialValue'] ?? json['initial'],
      type: json['type'] as String? ?? 'dynamic',
      persist: json['persist'] as bool? ?? false,
      computed: json['computed'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (initialValue != null) 'initialValue': initialValue,
      'type': type,
      if (persist) 'persist': persist,
      if (computed != null) 'computed': computed,
    };
  }
}

/// Action definition.
class ActionDef {
  /// Action type.
  final ActionType type;

  /// Action target.
  final String? target;

  /// Action payload/arguments.
  final Map<String, dynamic> payload;

  /// Condition for execution.
  final String? condition;

  /// Next actions to execute.
  final List<ActionDef> then;

  const ActionDef({
    required this.type,
    this.target,
    this.payload = const {},
    this.condition,
    this.then = const [],
  });

  factory ActionDef.fromJson(Map<String, dynamic> json) {
    return ActionDef(
      type: ActionType.fromString(json['type'] as String? ?? 'custom'),
      target: json['target'] as String?,
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      condition: json['condition'] as String?,
      then: (json['then'] as List<dynamic>?)
              ?.map((e) => ActionDef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (target != null) 'target': target,
      if (payload.isNotEmpty) 'payload': payload,
      if (condition != null) 'condition': condition,
      if (then.isNotEmpty) 'then': then.map((a) => a.toJson()).toList(),
    };
  }
}

/// Action types.
enum ActionType {
  navigate,
  setState,
  callApi,
  callSkill,
  showDialog,
  showSnackbar,
  submit,
  validate,
  custom,
  unknown;

  static ActionType fromString(String value) {
    return ActionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ActionType.unknown,
    );
  }
}

/// Theme configuration — bundle-side wrapper around the runtime theme JSON.
///
/// Holds the raw theme JSON (MCP UI DSL 1.3 — 14 token domains: color /
/// typography / spacing / shape / elevation / motion / density / breakpoints
/// / border / opacity / focusRing / zIndex / component, plus optional
/// `light` / `dark` mode overrides) untouched, so the runtime can decode it
/// via its strongly-typed `ThemeDefinition.fromJson`.
class ThemeConfig {
  /// Theme mode — `light` / `dark` / `system`.
  final String mode;

  /// Per-domain theme JSON (the full 1.3 14-domain payload).
  final Map<String, dynamic> raw;

  const ThemeConfig({
    this.mode = 'system',
    this.raw = const {},
  });

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      mode: (json['mode'] as String?) ?? 'system',
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    final m = Map<String, dynamic>.from(raw);
    m['mode'] = mode;
    return m;
  }

  /// Convenience getter for the [color] sub-domain (M3 28-role).
  Map<String, dynamic>? get color =>
      raw['color'] as Map<String, dynamic>?;

  /// Convenience getter for the [typography] sub-domain (M3 15-role).
  Map<String, dynamic>? get typography =>
      raw['typography'] as Map<String, dynamic>?;

  /// Convenience getter for the [spacing] sub-domain.
  Map<String, dynamic>? get spacing =>
      raw['spacing'] as Map<String, dynamic>?;

  /// Convenience getter for the [shape] sub-domain (M3 7-family).
  Map<String, dynamic>? get shape =>
      raw['shape'] as Map<String, dynamic>?;

  /// Convenience getter for the [elevation] sub-domain (M3 6-level).
  Map<String, dynamic>? get elevation =>
      raw['elevation'] as Map<String, dynamic>?;

  /// Mode-specific override for `dark`.
  Map<String, dynamic>? get dark =>
      raw['dark'] as Map<String, dynamic>?;

  /// Mode-specific override for `light`.
  Map<String, dynamic>? get light =>
      raw['light'] as Map<String, dynamic>?;
}

/// Navigation configuration.
class NavigationConfig {
  /// Initial route.
  final String? initialRoute;

  /// Navigation type.
  final NavigationType type;

  /// Route definitions.
  final List<RouteDefinition> routes;

  /// Navigation guards.
  final List<NavigationGuard> guards;

  const NavigationConfig({
    this.initialRoute,
    this.type = NavigationType.stack,
    this.routes = const [],
    this.guards = const [],
  });

  factory NavigationConfig.fromJson(Map<String, dynamic> json) {
    return NavigationConfig(
      initialRoute: json['initialRoute'] as String?,
      type: NavigationType.fromString(json['type'] as String? ?? 'stack'),
      routes: (json['routes'] as List<dynamic>?)
              ?.map((e) => RouteDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      guards: (json['guards'] as List<dynamic>?)
              ?.map((e) => NavigationGuard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (initialRoute != null) 'initialRoute': initialRoute,
      'type': type.name,
      if (routes.isNotEmpty) 'routes': routes.map((r) => r.toJson()).toList(),
      if (guards.isNotEmpty) 'guards': guards.map((g) => g.toJson()).toList(),
    };
  }
}

/// Navigation types.
enum NavigationType {
  stack,
  tab,
  drawer,
  bottomNav,
  unknown;

  static NavigationType fromString(String value) {
    return NavigationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NavigationType.unknown,
    );
  }
}

/// Route definition.
class RouteDefinition {
  /// Route path.
  final String path;

  /// Target page ID.
  final String pageId;

  /// Route parameters.
  final List<ParameterDef> parameters;

  const RouteDefinition({
    required this.path,
    required this.pageId,
    this.parameters = const [],
  });

  factory RouteDefinition.fromJson(Map<String, dynamic> json) {
    return RouteDefinition(
      path: json['path'] as String? ?? '',
      pageId: json['pageId'] as String? ?? json['screenId'] as String? ?? json['screen'] as String? ?? '',
      parameters: (json['parameters'] as List<dynamic>?)
              ?.map((e) => ParameterDef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'pageId': pageId,
      if (parameters.isNotEmpty)
        'parameters': parameters.map((p) => p.toJson()).toList(),
    };
  }
}

/// Navigation guard.
class NavigationGuard {
  /// Guard name.
  final String name;

  /// Routes to protect.
  final List<String> routes;

  /// Guard condition expression.
  final String condition;

  /// Redirect route on failure.
  final String? redirectTo;

  const NavigationGuard({
    required this.name,
    this.routes = const [],
    required this.condition,
    this.redirectTo,
  });

  factory NavigationGuard.fromJson(Map<String, dynamic> json) {
    return NavigationGuard(
      name: json['name'] as String? ?? '',
      routes: (json['routes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      condition: json['condition'] as String? ?? 'true',
      redirectTo: json['redirectTo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (routes.isNotEmpty) 'routes': routes,
      'condition': condition,
      if (redirectTo != null) 'redirectTo': redirectTo,
    };
  }
}

/// Lifecycle hooks.
class LifecycleHooks {
  /// Called when page is created.
  final List<ActionDef> onCreate;

  /// Called when page is shown.
  final List<ActionDef> onShow;

  /// Called when page is hidden.
  final List<ActionDef> onHide;

  /// Called when page is destroyed.
  final List<ActionDef> onDestroy;

  const LifecycleHooks({
    this.onCreate = const [],
    this.onShow = const [],
    this.onHide = const [],
    this.onDestroy = const [],
  });

  factory LifecycleHooks.fromJson(Map<String, dynamic> json) {
    return LifecycleHooks(
      onCreate: _parseActionList(json['onCreate']),
      onShow: _parseActionList(json['onShow']),
      onHide: _parseActionList(json['onHide']),
      onDestroy: _parseActionList(json['onDestroy']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (onCreate.isNotEmpty)
        'onCreate': onCreate.map((a) => a.toJson()).toList(),
      if (onShow.isNotEmpty) 'onShow': onShow.map((a) => a.toJson()).toList(),
      if (onHide.isNotEmpty) 'onHide': onHide.map((a) => a.toJson()).toList(),
      if (onDestroy.isNotEmpty)
        'onDestroy': onDestroy.map((a) => a.toJson()).toList(),
    };
  }
}

List<ActionDef> _parseActionList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value
        .map((e) => ActionDef.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  return [];
}
