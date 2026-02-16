/// UI Section model for MCP Bundle.
///
/// Contains screen definitions, widgets, and UI configuration.
library;

/// UI section containing screens and widgets.
class UiSection {
  /// Schema version for UI section.
  final String schemaVersion;

  /// List of screens in the application.
  final List<ScreenDefinition> screens;

  /// Reusable widget definitions.
  final Map<String, WidgetDefinition> widgets;

  /// Theme configuration.
  final ThemeConfig? theme;

  /// Navigation configuration.
  final NavigationConfig? navigation;

  /// Global UI state definitions.
  final Map<String, StateDefinition> state;

  const UiSection({
    this.schemaVersion = '1.0.0',
    this.screens = const [],
    this.widgets = const {},
    this.theme,
    this.navigation,
    this.state = const {},
  });

  factory UiSection.fromJson(Map<String, dynamic> json) {
    return UiSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      screens: (json['screens'] as List<dynamic>?)
              ?.map((e) => ScreenDefinition.fromJson(e as Map<String, dynamic>))
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      if (screens.isNotEmpty) 'screens': screens.map((s) => s.toJson()).toList(),
      if (widgets.isNotEmpty)
        'widgets': widgets.map((k, v) => MapEntry(k, v.toJson())),
      if (theme != null) 'theme': theme!.toJson(),
      if (navigation != null) 'navigation': navigation!.toJson(),
      if (state.isNotEmpty)
        'state': state.map((k, v) => MapEntry(k, v.toJson())),
    };
  }
}

/// Screen definition.
class ScreenDefinition {
  /// Screen identifier.
  final String id;

  /// Screen name.
  final String name;

  /// Route path.
  final String? route;

  /// Root widget for the screen.
  final WidgetNode root;

  /// Screen parameters.
  final List<ParameterDef> parameters;

  /// Screen-level state.
  final Map<String, StateDefinition> state;

  /// Screen lifecycle hooks.
  final LifecycleHooks? lifecycle;

  const ScreenDefinition({
    required this.id,
    required this.name,
    this.route,
    required this.root,
    this.parameters = const [],
    this.state = const {},
    this.lifecycle,
  });

  factory ScreenDefinition.fromJson(Map<String, dynamic> json) {
    return ScreenDefinition(
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

/// Theme configuration.
class ThemeConfig {
  /// Color scheme.
  final Map<String, String> colors;

  /// Typography settings.
  final Map<String, dynamic> typography;

  /// Spacing values.
  final Map<String, double> spacing;

  /// Border radius values.
  final Map<String, double> borderRadius;

  /// Dark mode configuration.
  final Map<String, dynamic>? darkMode;

  const ThemeConfig({
    this.colors = const {},
    this.typography = const {},
    this.spacing = const {},
    this.borderRadius = const {},
    this.darkMode,
  });

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      colors: (json['colors'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      typography: json['typography'] as Map<String, dynamic>? ?? {},
      spacing: (json['spacing'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      borderRadius: (json['borderRadius'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      darkMode: json['darkMode'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (colors.isNotEmpty) 'colors': colors,
      if (typography.isNotEmpty) 'typography': typography,
      if (spacing.isNotEmpty) 'spacing': spacing,
      if (borderRadius.isNotEmpty) 'borderRadius': borderRadius,
      if (darkMode != null) 'darkMode': darkMode,
    };
  }
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

  /// Target screen ID.
  final String screenId;

  /// Route parameters.
  final List<ParameterDef> parameters;

  const RouteDefinition({
    required this.path,
    required this.screenId,
    this.parameters = const [],
  });

  factory RouteDefinition.fromJson(Map<String, dynamic> json) {
    return RouteDefinition(
      path: json['path'] as String? ?? '',
      screenId: json['screenId'] as String? ?? json['screen'] as String? ?? '',
      parameters: (json['parameters'] as List<dynamic>?)
              ?.map((e) => ParameterDef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'screenId': screenId,
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
  /// Called when screen is created.
  final List<ActionDef> onCreate;

  /// Called when screen is shown.
  final List<ActionDef> onShow;

  /// Called when screen is hidden.
  final List<ActionDef> onHide;

  /// Called when screen is destroyed.
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
