import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  // =====================================================================
  // UiSection
  // =====================================================================
  group('UiSection', () {
    test('fromJson with empty map returns defaults', () {
      final section = UiSection.fromJson({});

      expect(section.schemaVersion, equals('1.0.0'));
      expect(section.pages, isEmpty);
      expect(section.widgets, isEmpty);
      expect(section.theme, isNull);
      expect(section.navigation, isNull);
      expect(section.state, isEmpty);
    });

    test('toJson with defaults omits empty collections and nulls', () {
      const section = UiSection();
      final json = section.toJson();

      expect(json['schemaVersion'], equals('1.0.0'));
      expect(json.containsKey('screens'), isFalse);
      expect(json.containsKey('widgets'), isFalse);
      expect(json.containsKey('theme'), isFalse);
      expect(json.containsKey('navigation'), isFalse);
      expect(json.containsKey('state'), isFalse);
    });

    test('fromJson parses schemaVersion', () {
      final section = UiSection.fromJson({'schemaVersion': '2.0.0'});
      expect(section.schemaVersion, equals('2.0.0'));
    });

    test('fromJson/toJson roundtrip with screens preserves input keys', () {
      // 0.4.0: toJson re-emits the original raw map verbatim so unknown
      // keys, alias keys (`screens` vs `pages`), and ordering survive
      // the round-trip. The deprecated typed `pages` field is still
      // populated for legacy access.
      final json = {
        'schemaVersion': '1.0.0',
        'screens': [
          {
            'id': 'home',
            'name': 'Home Screen',
            'root': {'type': 'Column'},
          }
        ],
      };

      final section = UiSection.fromJson(json);
      // ignore: deprecated_member_use
      expect(section.pages, hasLength(1));
      // ignore: deprecated_member_use
      expect(section.pages.first.id, equals('home'));

      final output = section.toJson();
      // Round-trip: input `screens` is preserved verbatim.
      expect(output.containsKey('screens'), isTrue);
      final firstScreen =
          (output['screens'] as List<dynamic>).first as Map<String, dynamic>;
      expect(firstScreen['id'], equals('home'));
    });

    test('fromJson/toJson roundtrip with widgets', () {
      final json = {
        'widgets': {
          'MyButton': {
            'name': 'MyButton',
            'template': {'type': 'ElevatedButton'},
          }
        },
      };

      final section = UiSection.fromJson(json);
      // ignore: deprecated_member_use
      expect(section.widgets, contains('MyButton'));
      // ignore: deprecated_member_use
      expect(section.widgets['MyButton']!.name, equals('MyButton'));

      final output = section.toJson();
      expect(output['widgets'], isA<Map<String, dynamic>>());
      final widgetJson =
          (output['widgets'] as Map<String, dynamic>)['MyButton']
              as Map<String, dynamic>;
      expect(widgetJson['name'], equals('MyButton'));
    });

    test('fromJson preserves unknown keys for round-trip', () {
      // 0.4.0: forward-compat round-trip. New top-level keys land in
      // raw and re-appear in toJson unchanged.
      final json = {
        'schemaVersion': '1.0.0',
        'futureKey': {'experimental': true},
      };
      final section = UiSection.fromJson(json);
      final output = section.toJson();
      expect(output['futureKey'], equals({'experimental': true}));
    });

    test('fromJson/toJson roundtrip with theme', () {
      final json = {
        'theme': {
          'colors': {'primary': '#FF0000'},
        },
      };

      final section = UiSection.fromJson(json);
      expect(section.theme, isNotNull);
      expect(section.theme!.raw['colors'], isA<Map>());

      final output = section.toJson();
      expect(output['theme'], isA<Map<String, dynamic>>());
    });

    test('fromJson/toJson roundtrip with navigation', () {
      final json = {
        'navigation': {
          'type': 'tab',
          'initialRoute': '/home',
        },
      };

      final section = UiSection.fromJson(json);
      expect(section.navigation, isNotNull);
      expect(section.navigation!.type, equals(NavigationType.tab));

      final output = section.toJson();
      expect(output['navigation'], isA<Map<String, dynamic>>());
    });

    test('fromJson/toJson roundtrip with state', () {
      final json = {
        'state': {
          'counter': {'initialValue': 0, 'type': 'int'},
        },
      };

      final section = UiSection.fromJson(json);
      expect(section.state, contains('counter'));
      expect(section.state['counter']!.initialValue, equals(0));

      final output = section.toJson();
      expect(output['state'], isA<Map<String, dynamic>>());
      final counterJson =
          (output['state'] as Map<String, dynamic>)['counter']
              as Map<String, dynamic>;
      expect(counterJson['type'], equals('int'));
    });
  });

  // =====================================================================
  // PageDefinition
  // =====================================================================
  group('PageDefinition', () {
    test('fromJson with minimal data', () {
      final screen = ScreenDefinition.fromJson({
        'id': 'login',
        'name': 'Login',
        'root': {'type': 'Column'},
      });

      expect(screen.id, equals('login'));
      expect(screen.name, equals('Login'));
      expect(screen.route, isNull);
      expect(screen.root.type, equals('Column'));
      expect(screen.parameters, isEmpty);
      expect(screen.state, isEmpty);
      expect(screen.lifecycle, isNull);
    });

    test('fromJson defaults id and name to empty string if missing', () {
      final screen = ScreenDefinition.fromJson({'root': {'type': 'Text'}});

      expect(screen.id, equals(''));
      expect(screen.name, equals(''));
    });

    test('fromJson parses route', () {
      final screen = ScreenDefinition.fromJson({
        'id': 's1',
        'name': 'S1',
        'route': '/settings',
        'root': {'type': 'Container'},
      });

      expect(screen.route, equals('/settings'));
    });

    test('fromJson/toJson roundtrip with all fields', () {
      final json = {
        'id': 'profile',
        'name': 'Profile Screen',
        'route': '/profile',
        'root': {'type': 'Column'},
        'parameters': [
          {'name': 'userId', 'type': 'string', 'required': true}
        ],
        'state': {
          'loading': {'initialValue': true, 'type': 'bool'},
        },
        'lifecycle': {
          'onCreate': [
            {'type': 'callApi', 'target': 'fetchProfile'}
          ],
        },
      };

      final screen = ScreenDefinition.fromJson(json);
      expect(screen.parameters, hasLength(1));
      expect(screen.parameters.first.name, equals('userId'));
      expect(screen.state, contains('loading'));
      expect(screen.lifecycle, isNotNull);

      final output = screen.toJson();
      expect(output['id'], equals('profile'));
      expect(output['name'], equals('Profile Screen'));
      expect(output['route'], equals('/profile'));
      expect(output['parameters'], isList);
      expect(output['state'], isA<Map<String, dynamic>>());
      expect(output['lifecycle'], isA<Map<String, dynamic>>());
    });

    test('toJson omits optional empty fields', () {
      final screen = ScreenDefinition.fromJson({
        'id': 'x',
        'name': 'X',
        'root': {'type': 'Text'},
      });

      final output = screen.toJson();
      expect(output.containsKey('route'), isFalse);
      expect(output.containsKey('parameters'), isFalse);
      expect(output.containsKey('state'), isFalse);
      expect(output.containsKey('lifecycle'), isFalse);
    });
  });

  // =====================================================================
  // WidgetNode
  // =====================================================================
  group('WidgetNode', () {
    test('fromJson with empty map defaults type to Container', () {
      final node = WidgetNode.fromJson({});

      expect(node.type, equals('Container'));
      expect(node.props, isEmpty);
      expect(node.children, isEmpty);
      expect(node.condition, isNull);
      expect(node.actions, isEmpty);
      expect(node.binding, isNull);
    });

    test('fromJson parses type', () {
      final node = WidgetNode.fromJson({'type': 'Text'});
      expect(node.type, equals('Text'));
    });

    test('fromJson/toJson roundtrip with props', () {
      final json = {
        'type': 'Text',
        'props': {'text': 'Hello', 'fontSize': 16},
      };

      final node = WidgetNode.fromJson(json);
      expect(node.props['text'], equals('Hello'));
      expect(node.props['fontSize'], equals(16));

      final output = node.toJson();
      expect(output['props'], isA<Map<String, dynamic>>());
      expect((output['props'] as Map<String, dynamic>)['text'], equals('Hello'));
    });

    test('fromJson/toJson roundtrip with recursive children', () {
      final json = {
        'type': 'Column',
        'children': [
          {
            'type': 'Row',
            'children': [
              {'type': 'Text', 'props': {'text': 'Nested'}},
            ],
          },
          {'type': 'Icon'},
        ],
      };

      final node = WidgetNode.fromJson(json);
      expect(node.children, hasLength(2));
      expect(node.children[0].type, equals('Row'));
      expect(node.children[0].children, hasLength(1));
      expect(node.children[0].children[0].type, equals('Text'));
      expect(node.children[1].type, equals('Icon'));

      // Verify roundtrip preserves nesting
      final output = node.toJson();
      final restored = WidgetNode.fromJson(output);
      expect(restored.children[0].children[0].type, equals('Text'));
    });

    test('fromJson/toJson roundtrip with condition', () {
      final json = {
        'type': 'Text',
        'condition': 'state.isLoggedIn == true',
      };

      final node = WidgetNode.fromJson(json);
      expect(node.condition, equals('state.isLoggedIn == true'));

      final output = node.toJson();
      expect(output['condition'], equals('state.isLoggedIn == true'));
    });

    test('fromJson/toJson roundtrip with actions', () {
      final json = {
        'type': 'Button',
        'actions': {
          'onTap': {'type': 'navigate', 'target': '/home'},
          'onLongPress': {'type': 'showDialog', 'target': 'confirmDialog'},
        },
      };

      final node = WidgetNode.fromJson(json);
      expect(node.actions, hasLength(2));
      expect(node.actions['onTap']!.type, equals(ActionType.navigate));
      expect(node.actions['onLongPress']!.type, equals(ActionType.showDialog));

      final output = node.toJson();
      expect(output['actions'], isA<Map<String, dynamic>>());
      final onTapJson =
          (output['actions'] as Map<String, dynamic>)['onTap']
              as Map<String, dynamic>;
      expect(onTapJson['type'], equals('navigate'));
    });

    test('fromJson/toJson roundtrip with binding', () {
      final json = {
        'type': 'TextField',
        'binding': 'state.username',
      };

      final node = WidgetNode.fromJson(json);
      expect(node.binding, equals('state.username'));

      final output = node.toJson();
      expect(output['binding'], equals('state.username'));
    });

    test('toJson omits empty/null optional fields', () {
      final node = WidgetNode.fromJson({'type': 'Spacer'});
      final output = node.toJson();

      expect(output['type'], equals('Spacer'));
      expect(output.containsKey('props'), isFalse);
      expect(output.containsKey('children'), isFalse);
      expect(output.containsKey('condition'), isFalse);
      expect(output.containsKey('actions'), isFalse);
      expect(output.containsKey('binding'), isFalse);
    });
  });

  // =====================================================================
  // WidgetDefinition
  // =====================================================================
  group('WidgetDefinition', () {
    test('fromJson with minimal data', () {
      final def = WidgetDefinition.fromJson({
        'name': 'Card',
        'template': {'type': 'Container'},
      });

      expect(def.name, equals('Card'));
      expect(def.description, isNull);
      expect(def.parameters, isEmpty);
      expect(def.template.type, equals('Container'));
    });

    test('fromJson defaults name to empty string if missing', () {
      final def = WidgetDefinition.fromJson({
        'template': {'type': 'Text'},
      });
      expect(def.name, equals(''));
    });

    test('fromJson/toJson roundtrip with all fields', () {
      final json = {
        'name': 'CustomButton',
        'description': 'A reusable button widget',
        'parameters': [
          {'name': 'label', 'type': 'string', 'required': true},
          {'name': 'color', 'type': 'string', 'default': 'blue'},
        ],
        'template': {
          'type': 'ElevatedButton',
          'props': {'text': '\${label}'},
        },
      };

      final def = WidgetDefinition.fromJson(json);
      expect(def.name, equals('CustomButton'));
      expect(def.description, equals('A reusable button widget'));
      expect(def.parameters, hasLength(2));
      expect(def.template.type, equals('ElevatedButton'));

      final output = def.toJson();
      expect(output['name'], equals('CustomButton'));
      expect(output['description'], equals('A reusable button widget'));
      expect(output['parameters'], isList);
      expect(output['template'], isA<Map<String, dynamic>>());
    });

    test('toJson omits optional empty fields', () {
      final def = WidgetDefinition.fromJson({
        'name': 'Simple',
        'template': {'type': 'Container'},
      });

      final output = def.toJson();
      expect(output.containsKey('description'), isFalse);
      expect(output.containsKey('parameters'), isFalse);
    });
  });

  // =====================================================================
  // ParameterDef
  // =====================================================================
  group('ParameterDef', () {
    test('fromJson with minimal data', () {
      final param = ParameterDef.fromJson({
        'name': 'title',
        'type': 'string',
      });

      expect(param.name, equals('title'));
      expect(param.type, equals('string'));
      expect(param.required, isFalse);
      expect(param.defaultValue, isNull);
      expect(param.description, isNull);
    });

    test('fromJson defaults name and type if missing', () {
      final param = ParameterDef.fromJson({});

      expect(param.name, equals(''));
      expect(param.type, equals('string'));
    });

    test('fromJson reads defaultValue from "default" key', () {
      final param = ParameterDef.fromJson({
        'name': 'count',
        'type': 'int',
        'default': 42,
      });

      expect(param.defaultValue, equals(42));
    });

    test('fromJson parses required field', () {
      final param = ParameterDef.fromJson({
        'name': 'email',
        'type': 'string',
        'required': true,
      });

      expect(param.required, isTrue);
    });

    test('fromJson/toJson roundtrip with all fields', () {
      final json = {
        'name': 'age',
        'type': 'int',
        'required': true,
        'default': 18,
        'description': 'User age',
      };

      final param = ParameterDef.fromJson(json);
      final output = param.toJson();

      expect(output['name'], equals('age'));
      expect(output['type'], equals('int'));
      expect(output['required'], isTrue);
      expect(output['default'], equals(18));
      expect(output['description'], equals('User age'));
    });

    test('toJson omits optional fields when not set', () {
      final param = ParameterDef.fromJson({
        'name': 'x',
        'type': 'string',
      });

      final output = param.toJson();
      expect(output.containsKey('required'), isFalse);
      expect(output.containsKey('default'), isFalse);
      expect(output.containsKey('description'), isFalse);
    });
  });

  // =====================================================================
  // StateDefinition
  // =====================================================================
  group('StateDefinition', () {
    test('fromJson with empty map returns defaults', () {
      final state = StateDefinition.fromJson({});

      expect(state.initialValue, isNull);
      expect(state.type, equals('dynamic'));
      expect(state.persist, isFalse);
      expect(state.computed, isNull);
    });

    test('fromJson reads initialValue from "initialValue" key', () {
      final state = StateDefinition.fromJson({
        'initialValue': 'hello',
      });

      expect(state.initialValue, equals('hello'));
    });

    test('fromJson reads initialValue from "initial" key as fallback', () {
      final state = StateDefinition.fromJson({
        'initial': 100,
      });

      expect(state.initialValue, equals(100));
    });

    test('fromJson prefers "initialValue" over "initial"', () {
      final state = StateDefinition.fromJson({
        'initialValue': 'preferred',
        'initial': 'fallback',
      });

      expect(state.initialValue, equals('preferred'));
    });

    test('fromJson parses type and persist', () {
      final state = StateDefinition.fromJson({
        'type': 'int',
        'persist': true,
      });

      expect(state.type, equals('int'));
      expect(state.persist, isTrue);
    });

    test('fromJson parses computed expression', () {
      final state = StateDefinition.fromJson({
        'computed': 'state.price * state.quantity',
      });

      expect(state.computed, equals('state.price * state.quantity'));
    });

    test('fromJson/toJson roundtrip with all fields', () {
      final json = {
        'initialValue': ['a', 'b'],
        'type': 'list',
        'persist': true,
        'computed': 'items.filter(active)',
      };

      final state = StateDefinition.fromJson(json);
      final output = state.toJson();

      expect(output['initialValue'], equals(['a', 'b']));
      expect(output['type'], equals('list'));
      expect(output['persist'], isTrue);
      expect(output['computed'], equals('items.filter(active)'));
    });

    test('toJson omits optional fields when not set', () {
      final state = StateDefinition.fromJson({});
      final output = state.toJson();

      expect(output.containsKey('initialValue'), isFalse);
      expect(output['type'], equals('dynamic'));
      expect(output.containsKey('persist'), isFalse);
      expect(output.containsKey('computed'), isFalse);
    });
  });

  // =====================================================================
  // ActionDef
  // =====================================================================
  group('ActionDef', () {
    test('fromJson with minimal data', () {
      final action = ActionDef.fromJson({'type': 'navigate'});

      expect(action.type, equals(ActionType.navigate));
      expect(action.target, isNull);
      expect(action.payload, isEmpty);
      expect(action.condition, isNull);
      expect(action.then, isEmpty);
    });

    test('fromJson defaults to custom type if missing', () {
      final action = ActionDef.fromJson({});
      expect(action.type, equals(ActionType.custom));
    });

    test('fromJson/toJson roundtrip with target and payload', () {
      final json = {
        'type': 'callApi',
        'target': 'fetchUsers',
        'payload': {'page': 1, 'limit': 10},
      };

      final action = ActionDef.fromJson(json);
      expect(action.type, equals(ActionType.callApi));
      expect(action.target, equals('fetchUsers'));
      expect(action.payload['page'], equals(1));

      final output = action.toJson();
      expect(output['type'], equals('callApi'));
      expect(output['target'], equals('fetchUsers'));
      expect(output['payload'], isA<Map<String, dynamic>>());
    });

    test('fromJson/toJson roundtrip with condition', () {
      final json = {
        'type': 'setState',
        'condition': 'state.isValid == true',
      };

      final action = ActionDef.fromJson(json);
      expect(action.condition, equals('state.isValid == true'));

      final output = action.toJson();
      expect(output['condition'], equals('state.isValid == true'));
    });

    test('fromJson/toJson roundtrip with recursive then actions', () {
      final json = {
        'type': 'callApi',
        'target': 'submitForm',
        'then': [
          {
            'type': 'navigate',
            'target': '/success',
            'then': [
              {'type': 'showSnackbar', 'target': 'Done!'},
            ],
          },
          {'type': 'setState'},
        ],
      };

      final action = ActionDef.fromJson(json);
      expect(action.then, hasLength(2));
      expect(action.then[0].type, equals(ActionType.navigate));
      expect(action.then[0].then, hasLength(1));
      expect(action.then[0].then[0].type, equals(ActionType.showSnackbar));
      expect(action.then[1].type, equals(ActionType.setState));

      // Verify roundtrip preserves nesting
      final output = action.toJson();
      final restored = ActionDef.fromJson(output);
      expect(restored.then[0].then[0].type, equals(ActionType.showSnackbar));
    });

    test('toJson omits optional empty fields', () {
      final action = ActionDef.fromJson({'type': 'validate'});
      final output = action.toJson();

      expect(output['type'], equals('validate'));
      expect(output.containsKey('target'), isFalse);
      expect(output.containsKey('payload'), isFalse);
      expect(output.containsKey('condition'), isFalse);
      expect(output.containsKey('then'), isFalse);
    });
  });

  // =====================================================================
  // ActionType.fromString
  // =====================================================================
  group('ActionType.fromString', () {
    test('parses navigate', () {
      expect(ActionType.fromString('navigate'), equals(ActionType.navigate));
    });

    test('parses setState', () {
      expect(ActionType.fromString('setState'), equals(ActionType.setState));
    });

    test('parses callApi', () {
      expect(ActionType.fromString('callApi'), equals(ActionType.callApi));
    });

    test('parses callSkill', () {
      expect(ActionType.fromString('callSkill'), equals(ActionType.callSkill));
    });

    test('parses showDialog', () {
      expect(
          ActionType.fromString('showDialog'), equals(ActionType.showDialog));
    });

    test('parses showSnackbar', () {
      expect(ActionType.fromString('showSnackbar'),
          equals(ActionType.showSnackbar));
    });

    test('parses submit', () {
      expect(ActionType.fromString('submit'), equals(ActionType.submit));
    });

    test('parses validate', () {
      expect(ActionType.fromString('validate'), equals(ActionType.validate));
    });

    test('parses custom', () {
      expect(ActionType.fromString('custom'), equals(ActionType.custom));
    });

    test('unknown string returns unknown', () {
      expect(ActionType.fromString('nonExistentAction'),
          equals(ActionType.unknown));
    });
  });

  // =====================================================================
  // ThemeConfig (1.3 — bundle-side raw theme JSON wrapper)
  // =====================================================================
  group('ThemeConfig', () {
    test('fromJson with empty map produces default mode', () {
      final theme = ThemeConfig.fromJson({});

      expect(theme.mode, equals('system'));
      expect(theme.raw, isNotNull);
      expect(theme.color, isNull);
      expect(theme.typography, isNull);
      expect(theme.spacing, isNull);
      expect(theme.shape, isNull);
      expect(theme.elevation, isNull);
    });

    test('fromJson parses M3 28-role color block', () {
      final theme = ThemeConfig.fromJson({
        'color': {'primary': '#3366FF', 'onPrimary': '#FFFFFF'},
      });

      expect(theme.color, isNotNull);
      expect(theme.color!['primary'], equals('#3366FF'));
      expect(theme.color!['onPrimary'], equals('#FFFFFF'));
    });

    test('fromJson parses typography sub-section verbatim', () {
      final theme = ThemeConfig.fromJson({
        'typography': {
          'displayLarge': {'fontSize': 57},
          'bodyLarge': {'fontSize': 16},
        },
      });

      expect(theme.typography, isNotNull);
      expect((theme.typography!['bodyLarge'] as Map)['fontSize'], equals(16));
    });

    test('fromJson parses spacing sub-section', () {
      final theme = ThemeConfig.fromJson({
        'spacing': {'sm': 8, 'md': 16, '2xl': 48},
      });

      expect(theme.spacing!['sm'], equals(8));
      expect(theme.spacing!['md'], equals(16));
      expect(theme.spacing!['2xl'], equals(48));
    });

    test('fromJson parses shape sub-section', () {
      final theme = ThemeConfig.fromJson({
        'shape': {'small': 8, 'medium': 12, 'large': 16},
      });

      expect(theme.shape!['medium'], equals(12));
    });

    test('fromJson parses elevation sub-section', () {
      final theme = ThemeConfig.fromJson({
        'elevation': {
          'level3': {'shadow': 6},
        },
      });

      expect(theme.elevation, isNotNull);
      expect(
        (theme.elevation!['level3'] as Map)['shadow'],
        equals(6),
      );
    });

    test('fromJson parses light/dark mode-specific overrides', () {
      final theme = ThemeConfig.fromJson({
        'mode': 'system',
        'dark': {
          'mode': 'dark',
          'color': {'primary': '#FFFFFF'},
        },
      });

      expect(theme.dark, isNotNull);
      expect((theme.dark!['color'] as Map)['primary'], equals('#FFFFFF'));
    });

    test('fromJson/toJson roundtrip preserves arbitrary domains', () {
      final json = {
        'mode': 'dark',
        'color': {'primary': '#111111'},
        'typography': {
          'titleLarge': {'fontSize': 22}
        },
        'spacing': {'xs': 4},
        'shape': {'medium': 12},
        'elevation': {
          'level1': {'shadow': 1}
        },
      };

      final theme = ThemeConfig.fromJson(json);
      final output = theme.toJson();

      expect(output['mode'], equals('dark'));
      expect(output['color'], isA<Map>());
      expect(output['typography'], isA<Map>());
      expect(output['spacing'], isA<Map>());
      expect(output['shape'], isA<Map>());
      expect(output['elevation'], isA<Map>());
    });

    test('toJson always includes mode', () {
      final theme = ThemeConfig.fromJson({});
      final output = theme.toJson();
      expect(output['mode'], equals('system'));
    });
  });

  // =====================================================================
  // NavigationConfig
  // =====================================================================
  group('NavigationConfig', () {
    test('fromJson with empty map returns defaults', () {
      final nav = NavigationConfig.fromJson({});

      expect(nav.initialRoute, isNull);
      expect(nav.type, equals(NavigationType.stack));
      expect(nav.routes, isEmpty);
      expect(nav.guards, isEmpty);
    });

    test('fromJson parses initialRoute', () {
      final nav = NavigationConfig.fromJson({'initialRoute': '/dashboard'});
      expect(nav.initialRoute, equals('/dashboard'));
    });

    test('fromJson/toJson roundtrip with routes', () {
      final json = {
        'type': 'tab',
        'initialRoute': '/home',
        'routes': [
          {'path': '/home', 'screenId': 'homeScreen'},
          {'path': '/settings', 'screenId': 'settingsScreen'},
        ],
      };

      final nav = NavigationConfig.fromJson(json);
      expect(nav.type, equals(NavigationType.tab));
      expect(nav.routes, hasLength(2));
      expect(nav.routes[0].path, equals('/home'));

      final output = nav.toJson();
      expect(output['type'], equals('tab'));
      expect(output['initialRoute'], equals('/home'));
      expect(output['routes'], isList);
    });

    test('fromJson/toJson roundtrip with guards', () {
      final json = {
        'guards': [
          {
            'name': 'authGuard',
            'routes': ['/profile', '/settings'],
            'condition': 'state.isAuthenticated',
            'redirectTo': '/login',
          }
        ],
      };

      final nav = NavigationConfig.fromJson(json);
      expect(nav.guards, hasLength(1));
      expect(nav.guards.first.name, equals('authGuard'));

      final output = nav.toJson();
      expect(output['guards'], isList);
    });

    test('toJson omits optional empty fields', () {
      final nav = NavigationConfig.fromJson({});
      final output = nav.toJson();

      expect(output.containsKey('initialRoute'), isFalse);
      expect(output['type'], equals('stack'));
      expect(output.containsKey('routes'), isFalse);
      expect(output.containsKey('guards'), isFalse);
    });
  });

  // =====================================================================
  // NavigationType.fromString
  // =====================================================================
  group('NavigationType.fromString', () {
    test('parses stack', () {
      expect(
          NavigationType.fromString('stack'), equals(NavigationType.stack));
    });

    test('parses tab', () {
      expect(NavigationType.fromString('tab'), equals(NavigationType.tab));
    });

    test('parses drawer', () {
      expect(
          NavigationType.fromString('drawer'), equals(NavigationType.drawer));
    });

    test('parses bottomNav', () {
      expect(NavigationType.fromString('bottomNav'),
          equals(NavigationType.bottomNav));
    });

    test('unknown string returns unknown', () {
      expect(NavigationType.fromString('flyout'),
          equals(NavigationType.unknown));
    });
  });

  // =====================================================================
  // RouteDefinition
  // =====================================================================
  group('RouteDefinition', () {
    test('fromJson with minimal data', () {
      final route = RouteDefinition.fromJson({
        'path': '/home',
        'screenId': 'homeScreen',
      });

      expect(route.path, equals('/home'));
      expect(route.pageId, equals('homeScreen'));
      expect(route.parameters, isEmpty);
    });

    test('fromJson defaults path and pageId to empty string', () {
      final route = RouteDefinition.fromJson({});

      expect(route.path, equals(''));
      expect(route.pageId, equals(''));
    });

    test('fromJson reads pageId from "screen" as fallback', () {
      final route = RouteDefinition.fromJson({
        'path': '/detail',
        'screen': 'detailScreen',
      });

      expect(route.pageId, equals('detailScreen'));
    });

    test('fromJson prefers "pageId" over "screen" (also accepts legacy "screenId")', () {
      final route = RouteDefinition.fromJson({
        'path': '/x',
        'screenId': 'preferred',
        'screen': 'fallback',
      });

      expect(route.pageId, equals('preferred'));
    });

    test('fromJson/toJson roundtrip with parameters', () {
      final json = {
        'path': '/user/:id',
        'screenId': 'userScreen',
        'parameters': [
          {'name': 'id', 'type': 'string', 'required': true},
        ],
      };

      final route = RouteDefinition.fromJson(json);
      expect(route.parameters, hasLength(1));
      expect(route.parameters.first.name, equals('id'));

      final output = route.toJson();
      expect(output['path'], equals('/user/:id'));
      expect(output['pageId'], equals('userScreen'));
      expect(output['parameters'], isList);
    });

    test('toJson omits empty parameters', () {
      final route = RouteDefinition.fromJson({
        'path': '/home',
        'screenId': 'home',
      });

      final output = route.toJson();
      expect(output.containsKey('parameters'), isFalse);
    });
  });

  // =====================================================================
  // NavigationGuard
  // =====================================================================
  group('NavigationGuard', () {
    test('fromJson with minimal data', () {
      final guard = NavigationGuard.fromJson({
        'name': 'auth',
        'condition': 'state.loggedIn',
      });

      expect(guard.name, equals('auth'));
      expect(guard.routes, isEmpty);
      expect(guard.condition, equals('state.loggedIn'));
      expect(guard.redirectTo, isNull);
    });

    test('fromJson defaults name to empty string and condition to "true"', () {
      final guard = NavigationGuard.fromJson({});

      expect(guard.name, equals(''));
      expect(guard.condition, equals('true'));
    });

    test('fromJson/toJson roundtrip with all fields', () {
      final json = {
        'name': 'roleGuard',
        'routes': ['/admin', '/manage'],
        'condition': 'state.role == "admin"',
        'redirectTo': '/unauthorized',
      };

      final guard = NavigationGuard.fromJson(json);
      expect(guard.name, equals('roleGuard'));
      expect(guard.routes, equals(['/admin', '/manage']));
      expect(guard.condition, equals('state.role == "admin"'));
      expect(guard.redirectTo, equals('/unauthorized'));

      final output = guard.toJson();
      expect(output['name'], equals('roleGuard'));
      expect(output['routes'], equals(['/admin', '/manage']));
      expect(output['condition'], equals('state.role == "admin"'));
      expect(output['redirectTo'], equals('/unauthorized'));
    });

    test('toJson omits optional empty fields', () {
      final guard = NavigationGuard.fromJson({
        'name': 'g',
        'condition': 'true',
      });

      final output = guard.toJson();
      expect(output.containsKey('routes'), isFalse);
      expect(output.containsKey('redirectTo'), isFalse);
    });
  });

  // =====================================================================
  // LifecycleHooks
  // =====================================================================
  group('LifecycleHooks', () {
    test('fromJson with empty map returns empty lists', () {
      final hooks = LifecycleHooks.fromJson({});

      expect(hooks.onCreate, isEmpty);
      expect(hooks.onShow, isEmpty);
      expect(hooks.onHide, isEmpty);
      expect(hooks.onDestroy, isEmpty);
    });

    test('fromJson/toJson roundtrip with onCreate', () {
      final json = {
        'onCreate': [
          {'type': 'callApi', 'target': 'init'},
        ],
      };

      final hooks = LifecycleHooks.fromJson(json);
      expect(hooks.onCreate, hasLength(1));
      expect(hooks.onCreate.first.type, equals(ActionType.callApi));

      final output = hooks.toJson();
      expect(output['onCreate'], isList);
      final firstAction =
          (output['onCreate'] as List<dynamic>).first as Map<String, dynamic>;
      expect(firstAction['type'], equals('callApi'));
    });

    test('fromJson/toJson roundtrip with onShow', () {
      final json = {
        'onShow': [
          {'type': 'setState', 'target': 'visible'},
        ],
      };

      final hooks = LifecycleHooks.fromJson(json);
      expect(hooks.onShow, hasLength(1));

      final output = hooks.toJson();
      expect(output.containsKey('onShow'), isTrue);
    });

    test('fromJson/toJson roundtrip with onHide', () {
      final json = {
        'onHide': [
          {'type': 'callApi', 'target': 'saveState'},
        ],
      };

      final hooks = LifecycleHooks.fromJson(json);
      expect(hooks.onHide, hasLength(1));

      final output = hooks.toJson();
      expect(output.containsKey('onHide'), isTrue);
    });

    test('fromJson/toJson roundtrip with onDestroy', () {
      final json = {
        'onDestroy': [
          {'type': 'callApi', 'target': 'cleanup'},
        ],
      };

      final hooks = LifecycleHooks.fromJson(json);
      expect(hooks.onDestroy, hasLength(1));

      final output = hooks.toJson();
      expect(output.containsKey('onDestroy'), isTrue);
    });

    test('fromJson/toJson roundtrip with all hooks populated', () {
      final json = {
        'onCreate': [
          {'type': 'callApi', 'target': 'load'},
        ],
        'onShow': [
          {'type': 'setState'},
        ],
        'onHide': [
          {'type': 'callApi', 'target': 'pause'},
        ],
        'onDestroy': [
          {'type': 'callApi', 'target': 'dispose'},
        ],
      };

      final hooks = LifecycleHooks.fromJson(json);
      expect(hooks.onCreate, hasLength(1));
      expect(hooks.onShow, hasLength(1));
      expect(hooks.onHide, hasLength(1));
      expect(hooks.onDestroy, hasLength(1));

      final output = hooks.toJson();
      expect(output.keys, containsAll(['onCreate', 'onShow', 'onHide', 'onDestroy']));
    });

    test('toJson omits empty hook lists', () {
      final hooks = LifecycleHooks.fromJson({});
      final output = hooks.toJson();

      expect(output.containsKey('onCreate'), isFalse);
      expect(output.containsKey('onShow'), isFalse);
      expect(output.containsKey('onHide'), isFalse);
      expect(output.containsKey('onDestroy'), isFalse);
    });

    // Testing _parseActionList behavior via LifecycleHooks
    test('null hook value produces empty action list', () {
      final hooks = LifecycleHooks.fromJson({
        'onCreate': null,
      });

      expect(hooks.onCreate, isEmpty);
    });

    test('non-list hook value produces empty action list', () {
      final hooks = LifecycleHooks.fromJson({
        'onShow': 'not a list',
      });

      expect(hooks.onShow, isEmpty);
    });

    test('list hook value is parsed into actions', () {
      final hooks = LifecycleHooks.fromJson({
        'onHide': [
          {'type': 'navigate', 'target': '/away'},
          {'type': 'setState'},
        ],
      });

      expect(hooks.onHide, hasLength(2));
      expect(hooks.onHide[0].type, equals(ActionType.navigate));
      expect(hooks.onHide[1].type, equals(ActionType.setState));
    });
  });
}
