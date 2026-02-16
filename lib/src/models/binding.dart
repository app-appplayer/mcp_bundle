/// Binding Section model for MCP Bundle.
///
/// Contains data binding definitions for connecting data sources to UI/logic.
library;

/// Binding section containing data bindings.
class BindingSection {
  /// Schema version for binding section.
  final String schemaVersion;

  /// Data bindings.
  final List<DataBinding> bindings;

  /// Data sources.
  final List<DataSource> sources;

  /// Computed values.
  final Map<String, ComputedValue> computed;

  const BindingSection({
    this.schemaVersion = '1.0.0',
    this.bindings = const [],
    this.sources = const [],
    this.computed = const {},
  });

  factory BindingSection.fromJson(Map<String, dynamic> json) {
    return BindingSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      bindings: (json['bindings'] as List<dynamic>?)
              ?.map((e) => DataBinding.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sources: (json['sources'] as List<dynamic>?)
              ?.map((e) => DataSource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      computed: (json['computed'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              ComputedValue.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      if (bindings.isNotEmpty)
        'bindings': bindings.map((b) => b.toJson()).toList(),
      if (sources.isNotEmpty)
        'sources': sources.map((s) => s.toJson()).toList(),
      if (computed.isNotEmpty)
        'computed': computed.map((k, v) => MapEntry(k, v.toJson())),
    };
  }
}

/// Data binding definition.
class DataBinding {
  /// Binding identifier.
  final String id;

  /// Source path.
  final String source;

  /// Target path.
  final String target;

  /// Binding direction.
  final BindingDirection direction;

  /// Transform expression.
  final String? transform;

  /// Condition for binding.
  final String? condition;

  /// Debounce time in milliseconds.
  final int? debounceMs;

  const DataBinding({
    required this.id,
    required this.source,
    required this.target,
    this.direction = BindingDirection.oneWay,
    this.transform,
    this.condition,
    this.debounceMs,
  });

  factory DataBinding.fromJson(Map<String, dynamic> json) {
    return DataBinding(
      id: json['id'] as String? ?? '',
      source: json['source'] as String? ?? '',
      target: json['target'] as String? ?? '',
      direction: BindingDirection.fromString(
          json['direction'] as String? ?? 'oneWay'),
      transform: json['transform'] as String?,
      condition: json['condition'] as String?,
      debounceMs: json['debounceMs'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'target': target,
      'direction': direction.name,
      if (transform != null) 'transform': transform,
      if (condition != null) 'condition': condition,
      if (debounceMs != null) 'debounceMs': debounceMs,
    };
  }
}

/// Binding directions.
enum BindingDirection {
  /// Source to target only.
  oneWay,

  /// Bidirectional.
  twoWay,

  /// Target to source only.
  reverse,

  /// Unknown direction.
  unknown;

  static BindingDirection fromString(String value) {
    return BindingDirection.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BindingDirection.unknown,
    );
  }
}

/// Data source definition.
class DataSource {
  /// Source identifier.
  final String id;

  /// Source name.
  final String name;

  /// Source type.
  final DataSourceType type;

  /// Source configuration.
  final Map<String, dynamic> config;

  /// Initial data.
  final dynamic initialData;

  /// Refresh configuration.
  final RefreshConfig? refresh;

  const DataSource({
    required this.id,
    required this.name,
    required this.type,
    this.config = const {},
    this.initialData,
    this.refresh,
  });

  factory DataSource.fromJson(Map<String, dynamic> json) {
    return DataSource(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: DataSourceType.fromString(json['type'] as String? ?? 'state'),
      config: json['config'] as Map<String, dynamic>? ?? {},
      initialData: json['initialData'],
      refresh: json['refresh'] != null
          ? RefreshConfig.fromJson(json['refresh'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      if (config.isNotEmpty) 'config': config,
      if (initialData != null) 'initialData': initialData,
      if (refresh != null) 'refresh': refresh!.toJson(),
    };
  }
}

/// Data source types.
enum DataSourceType {
  /// Local state.
  state,

  /// API endpoint.
  api,

  /// WebSocket.
  websocket,

  /// Local storage.
  localStorage,

  /// Session storage.
  sessionStorage,

  /// GraphQL.
  graphql,

  /// Unknown type.
  unknown;

  static DataSourceType fromString(String value) {
    return DataSourceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DataSourceType.unknown,
    );
  }
}

/// Refresh configuration.
class RefreshConfig {
  /// Refresh mode.
  final RefreshMode mode;

  /// Interval in milliseconds.
  final int? intervalMs;

  /// Events that trigger refresh.
  final List<String> events;

  const RefreshConfig({
    required this.mode,
    this.intervalMs,
    this.events = const [],
  });

  factory RefreshConfig.fromJson(Map<String, dynamic> json) {
    return RefreshConfig(
      mode: RefreshMode.fromString(json['mode'] as String? ?? 'manual'),
      intervalMs: json['intervalMs'] as int?,
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      if (intervalMs != null) 'intervalMs': intervalMs,
      if (events.isNotEmpty) 'events': events,
    };
  }
}

/// Refresh modes.
enum RefreshMode {
  /// Manual refresh only.
  manual,

  /// Automatic polling.
  polling,

  /// Event-driven refresh.
  event,

  /// Real-time subscription.
  realtime,

  /// Unknown mode.
  unknown;

  static RefreshMode fromString(String value) {
    return RefreshMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RefreshMode.unknown,
    );
  }
}

/// Computed value definition.
class ComputedValue {
  /// Dependencies for recomputation.
  final List<String> dependencies;

  /// Computation expression.
  final String expression;

  /// Whether to cache result.
  final bool cache;

  const ComputedValue({
    this.dependencies = const [],
    required this.expression,
    this.cache = true,
  });

  factory ComputedValue.fromJson(Map<String, dynamic> json) {
    return ComputedValue(
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      expression: json['expression'] as String? ?? '',
      cache: json['cache'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (dependencies.isNotEmpty) 'dependencies': dependencies,
      'expression': expression,
      if (!cache) 'cache': cache,
    };
  }
}
