import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('BindingSection', () {
    test('creates with defaults', () {
      const section = BindingSection();
      expect(section.schemaVersion, '1.0.0');
      expect(section.bindings, isEmpty);
      expect(section.sources, isEmpty);
      expect(section.computed, isEmpty);
    });

    test('fromJson with empty map', () {
      final section = BindingSection.fromJson({});
      expect(section.schemaVersion, '1.0.0');
      expect(section.bindings, isEmpty);
      expect(section.sources, isEmpty);
      expect(section.computed, isEmpty);
    });

    test('fromJson with all fields', () {
      final section = BindingSection.fromJson({
        'schemaVersion': '2.0.0',
        'bindings': [
          {'id': 'b1', 'source': 'state.name', 'target': 'ui.label'},
        ],
        'sources': [
          {'id': 's1', 'name': 'State', 'type': 'state'},
        ],
        'computed': {
          'fullName': {
            'expression': 'first + " " + last',
            'dependencies': ['first', 'last'],
          },
        },
      });
      expect(section.schemaVersion, '2.0.0');
      expect(section.bindings, hasLength(1));
      expect(section.sources, hasLength(1));
      expect(section.computed, hasLength(1));
    });

    test('toJson omits empty collections', () {
      const section = BindingSection();
      final json = section.toJson();
      expect(json['schemaVersion'], '1.0.0');
      expect(json.containsKey('bindings'), isFalse);
      expect(json.containsKey('sources'), isFalse);
      expect(json.containsKey('computed'), isFalse);
    });

    test('toJson includes non-empty collections', () {
      const section = BindingSection(
        bindings: [
          DataBinding(id: 'b1', source: 'a', target: 'b'),
        ],
        sources: [
          DataSource(id: 's1', name: 'S', type: DataSourceType.state),
        ],
      );
      final json = section.toJson();
      expect(json.containsKey('bindings'), isTrue);
      expect(json.containsKey('sources'), isTrue);
    });

    test('fromJson/toJson roundtrip', () {
      final original = BindingSection.fromJson({
        'schemaVersion': '1.0.0',
        'bindings': [
          {
            'id': 'b1',
            'source': 'state.x',
            'target': 'ui.y',
            'direction': 'oneWay',
          },
        ],
      });
      final json = original.toJson();
      final restored = BindingSection.fromJson(json);
      expect(restored.bindings, hasLength(1));
      expect(restored.bindings.first.id, 'b1');
    });
  });

  group('DataBinding', () {
    test('creates with required fields', () {
      const binding = DataBinding(id: 'b1', source: 'a', target: 'b');
      expect(binding.id, 'b1');
      expect(binding.source, 'a');
      expect(binding.target, 'b');
      expect(binding.direction, BindingDirection.oneWay);
      expect(binding.transform, isNull);
      expect(binding.condition, isNull);
      expect(binding.debounceMs, isNull);
    });

    test('fromJson with all fields', () {
      final binding = DataBinding.fromJson({
        'id': 'b1',
        'source': 'state.name',
        'target': 'ui.label',
        'direction': 'twoWay',
        'transform': 'value | uppercase',
        'condition': 'state.enabled',
        'debounceMs': 300,
      });
      expect(binding.id, 'b1');
      expect(binding.source, 'state.name');
      expect(binding.target, 'ui.label');
      expect(binding.direction, BindingDirection.twoWay);
      expect(binding.transform, 'value | uppercase');
      expect(binding.condition, 'state.enabled');
      expect(binding.debounceMs, 300);
    });

    test('fromJson defaults', () {
      final binding = DataBinding.fromJson({});
      expect(binding.id, '');
      expect(binding.source, '');
      expect(binding.target, '');
      expect(binding.direction, BindingDirection.oneWay);
    });

    test('toJson omits null fields', () {
      const binding = DataBinding(id: 'b1', source: 'a', target: 'b');
      final json = binding.toJson();
      expect(json['id'], 'b1');
      expect(json['source'], 'a');
      expect(json['target'], 'b');
      expect(json['direction'], 'oneWay');
      expect(json.containsKey('transform'), isFalse);
      expect(json.containsKey('condition'), isFalse);
      expect(json.containsKey('debounceMs'), isFalse);
    });

    test('toJson includes non-null fields', () {
      const binding = DataBinding(
        id: 'b1',
        source: 'a',
        target: 'b',
        transform: 'x | trim',
        condition: 'true',
        debounceMs: 500,
      );
      final json = binding.toJson();
      expect(json['transform'], 'x | trim');
      expect(json['condition'], 'true');
      expect(json['debounceMs'], 500);
    });
  });

  group('BindingDirection', () {
    test('fromString all values', () {
      expect(BindingDirection.fromString('oneWay'), BindingDirection.oneWay);
      expect(BindingDirection.fromString('twoWay'), BindingDirection.twoWay);
      expect(BindingDirection.fromString('reverse'), BindingDirection.reverse);
    });

    test('fromString unknown returns unknown', () {
      expect(BindingDirection.fromString('invalid'), BindingDirection.unknown);
    });
  });

  group('DataSource', () {
    test('creates with required fields', () {
      const source = DataSource(
        id: 's1',
        name: 'Source',
        type: DataSourceType.state,
      );
      expect(source.id, 's1');
      expect(source.name, 'Source');
      expect(source.type, DataSourceType.state);
      expect(source.config, isEmpty);
      expect(source.initialData, isNull);
      expect(source.refresh, isNull);
    });

    test('fromJson with all fields', () {
      final source = DataSource.fromJson({
        'id': 's1',
        'name': 'API Source',
        'type': 'api',
        'config': {'url': 'https://example.com/api'},
        'initialData': {'items': <String>[]},
        'refresh': {'mode': 'polling', 'intervalMs': 5000},
      });
      expect(source.id, 's1');
      expect(source.name, 'API Source');
      expect(source.type, DataSourceType.api);
      expect(source.config, {'url': 'https://example.com/api'});
      expect(source.initialData, isNotNull);
      expect(source.refresh, isNotNull);
      expect(source.refresh!.mode, RefreshMode.polling);
    });

    test('fromJson defaults', () {
      final source = DataSource.fromJson({});
      expect(source.id, '');
      expect(source.name, '');
      expect(source.type, DataSourceType.state);
    });

    test('toJson omits empty/null fields', () {
      const source = DataSource(
        id: 's1',
        name: 'S',
        type: DataSourceType.state,
      );
      final json = source.toJson();
      expect(json['id'], 's1');
      expect(json['name'], 'S');
      expect(json['type'], 'state');
      expect(json.containsKey('config'), isFalse);
      expect(json.containsKey('initialData'), isFalse);
      expect(json.containsKey('refresh'), isFalse);
    });
  });

  group('DataSourceType', () {
    test('fromString all values', () {
      expect(DataSourceType.fromString('state'), DataSourceType.state);
      expect(DataSourceType.fromString('api'), DataSourceType.api);
      expect(DataSourceType.fromString('websocket'), DataSourceType.websocket);
      expect(
        DataSourceType.fromString('localStorage'),
        DataSourceType.localStorage,
      );
      expect(
        DataSourceType.fromString('sessionStorage'),
        DataSourceType.sessionStorage,
      );
      expect(DataSourceType.fromString('graphql'), DataSourceType.graphql);
    });

    test('fromString unknown returns unknown', () {
      expect(DataSourceType.fromString('invalid'), DataSourceType.unknown);
    });
  });

  group('RefreshConfig', () {
    test('creates with required fields', () {
      const config = RefreshConfig(mode: RefreshMode.manual);
      expect(config.mode, RefreshMode.manual);
      expect(config.intervalMs, isNull);
      expect(config.events, isEmpty);
    });

    test('fromJson with all fields', () {
      final config = RefreshConfig.fromJson({
        'mode': 'polling',
        'intervalMs': 5000,
        'events': ['dataChange', 'refresh'],
      });
      expect(config.mode, RefreshMode.polling);
      expect(config.intervalMs, 5000);
      expect(config.events, ['dataChange', 'refresh']);
    });

    test('fromJson defaults', () {
      final config = RefreshConfig.fromJson({});
      expect(config.mode, RefreshMode.manual);
      expect(config.intervalMs, isNull);
      expect(config.events, isEmpty);
    });

    test('toJson omits null/empty fields', () {
      const config = RefreshConfig(mode: RefreshMode.manual);
      final json = config.toJson();
      expect(json['mode'], 'manual');
      expect(json.containsKey('intervalMs'), isFalse);
      expect(json.containsKey('events'), isFalse);
    });

    test('toJson includes non-null/empty fields', () {
      const config = RefreshConfig(
        mode: RefreshMode.event,
        intervalMs: 3000,
        events: ['click'],
      );
      final json = config.toJson();
      expect(json['mode'], 'event');
      expect(json['intervalMs'], 3000);
      expect(json['events'], ['click']);
    });
  });

  group('RefreshMode', () {
    test('fromString all values', () {
      expect(RefreshMode.fromString('manual'), RefreshMode.manual);
      expect(RefreshMode.fromString('polling'), RefreshMode.polling);
      expect(RefreshMode.fromString('event'), RefreshMode.event);
      expect(RefreshMode.fromString('realtime'), RefreshMode.realtime);
    });

    test('fromString unknown returns unknown', () {
      expect(RefreshMode.fromString('invalid'), RefreshMode.unknown);
    });
  });

  group('ComputedValue', () {
    test('creates with required fields', () {
      const computed = ComputedValue(expression: 'a + b');
      expect(computed.expression, 'a + b');
      expect(computed.dependencies, isEmpty);
      expect(computed.cache, isTrue);
    });

    test('fromJson with all fields', () {
      final computed = ComputedValue.fromJson({
        'expression': 'first + " " + last',
        'dependencies': ['first', 'last'],
        'cache': false,
      });
      expect(computed.expression, 'first + " " + last');
      expect(computed.dependencies, ['first', 'last']);
      expect(computed.cache, isFalse);
    });

    test('fromJson defaults', () {
      final computed = ComputedValue.fromJson({});
      expect(computed.expression, '');
      expect(computed.dependencies, isEmpty);
      expect(computed.cache, isTrue);
    });

    test('toJson omits defaults', () {
      const computed = ComputedValue(expression: 'x + y');
      final json = computed.toJson();
      expect(json['expression'], 'x + y');
      expect(json.containsKey('dependencies'), isFalse);
      expect(json.containsKey('cache'), isFalse);
    });

    test('toJson includes non-defaults', () {
      const computed = ComputedValue(
        expression: 'a + b',
        dependencies: ['a', 'b'],
        cache: false,
      );
      final json = computed.toJson();
      expect(json['dependencies'], ['a', 'b']);
      expect(json['cache'], isFalse);
    });

    test('fromJson/toJson roundtrip', () {
      final original = ComputedValue.fromJson({
        'expression': 'x * 2',
        'dependencies': ['x'],
        'cache': false,
      });
      final json = original.toJson();
      final restored = ComputedValue.fromJson(json);
      expect(restored.expression, 'x * 2');
      expect(restored.dependencies, ['x']);
      expect(restored.cache, isFalse);
    });
  });
}
