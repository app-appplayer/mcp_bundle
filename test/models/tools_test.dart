import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('ToolsSection', () {
    test('creates with defaults', () {
      const section = ToolsSection();
      expect(section.schemaVersion, '1.0.0');
      expect(section.tools, isEmpty);
      expect(section.isEmpty, isTrue);
      expect(section.isNotEmpty, isFalse);
    });

    test('empty section toJson keeps schemaVersion and omits tools', () {
      const section = ToolsSection();
      final json = section.toJson();
      expect(json['schemaVersion'], '1.0.0');
      expect(json.containsKey('tools'), isFalse);
    });

    test('fromJson with empty map applies defaults', () {
      final section = ToolsSection.fromJson({});
      expect(section.schemaVersion, '1.0.0');
      expect(section.tools, isEmpty);
    });

    test('round-trip preserves all fields', () {
      const original = ToolsSection(
        tools: [
          ToolEntry(
            id: 't1',
            name: 'studio.run',
            description: 'Run a studio command',
            kind: ToolKind.host,
            inputSchema: {
              'type': 'object',
              'properties': {
                'cmd': {'type': 'string'},
              },
            },
            outputSchema: {
              'type': 'object',
              'properties': {
                'ok': {'type': 'boolean'},
              },
              'required': ['ok'],
            },
            agentScope: ['designer', 'builder'],
            metadata: {'group': 'studio'},
          ),
        ],
      );

      final json = original.toJson();
      final round = ToolsSection.fromJson(json);

      expect(round.tools, hasLength(1));
      final t = round.tools.first;
      expect(t.id, 't1');
      expect(t.name, 'studio.run');
      expect(t.description, 'Run a studio command');
      expect(t.kind, ToolKind.host);
      expect(t.inputSchema!['type'], 'object');
      expect(t.outputSchema!['type'], 'object');
      expect(t.outputSchema!['required'], ['ok']);
      expect(t.agentScope, ['designer', 'builder']);
      expect(t.metadata['group'], 'studio');
    });

    test('findByName returns matching tool', () {
      const section = ToolsSection(
        tools: [
          ToolEntry(name: 'a.do'),
          ToolEntry(name: 'b.do'),
        ],
      );
      expect(section.findByName('b.do')!.name, 'b.do');
      expect(section.findByName('missing'), isNull);
    });

    test('findById returns matching tool when id present', () {
      const section = ToolsSection(
        tools: [
          ToolEntry(id: 'first', name: 'a.do'),
          ToolEntry(id: 'second', name: 'b.do'),
        ],
      );
      expect(section.findById('second')!.name, 'b.do');
      expect(section.findById('missing'), isNull);
    });

    test('copyWith creates modified copy', () {
      const original = ToolsSection(
        tools: [ToolEntry(name: 'a.do')],
      );
      final copy = original.copyWith(tools: const [
        ToolEntry(name: 'b.do'),
      ]);
      expect(original.tools.first.name, 'a.do');
      expect(copy.tools.first.name, 'b.do');
    });
  });

  group('ToolKind', () {
    test('fromString maps known kinds', () {
      expect(ToolKind.fromString('host'), ToolKind.host);
      expect(ToolKind.fromString('mcp'), ToolKind.mcp);
      expect(ToolKind.fromString('cloud'), ToolKind.cloud);
      expect(ToolKind.fromString('js'), ToolKind.js);
    });

    test('fromString is case-insensitive', () {
      expect(ToolKind.fromString('MCP'), ToolKind.mcp);
      expect(ToolKind.fromString('Cloud'), ToolKind.cloud);
    });

    test('fromString falls back to unknown', () {
      expect(ToolKind.fromString('zzz'), ToolKind.unknown);
      expect(ToolKind.fromString(null), ToolKind.unknown);
      expect(ToolKind.fromString(''), ToolKind.unknown);
    });

    test('wireValue round-trips through fromString', () {
      for (final k in ToolKind.values) {
        expect(ToolKind.fromString(k.wireValue), k);
      }
    });
  });

  group('ToolEntry kind-target shapes', () {
    test('host kind — empty target', () {
      const t = ToolEntry(name: 'studio.run');
      final round = ToolEntry.fromJson(t.toJson());
      expect(round.kind, ToolKind.host);
      expect(round.target, isEmpty);
    });

    test('mcp kind — http transport', () {
      const t = ToolEntry(
        name: 'remote.search',
        kind: ToolKind.mcp,
        target: {
          'transport': 'http',
          'url': 'https://example.com/mcp',
        },
      );
      final round = ToolEntry.fromJson(t.toJson());
      expect(round.kind, ToolKind.mcp);
      expect(round.target['transport'], 'http');
      expect(round.target['url'], 'https://example.com/mcp');
    });

    test('mcp kind — stdio transport with command + args', () {
      const t = ToolEntry(
        name: 'local.tool',
        kind: ToolKind.mcp,
        target: {
          'transport': 'stdio',
          'command': 'dart',
          'args': ['run', 'tool.dart'],
        },
      );
      final round = ToolEntry.fromJson(t.toJson());
      expect(round.target['transport'], 'stdio');
      expect(round.target['command'], 'dart');
      expect(round.target['args'], ['run', 'tool.dart']);
    });

    test('cloud kind — url target', () {
      const t = ToolEntry(
        name: 'cloud.fn',
        kind: ToolKind.cloud,
        target: {'url': 'https://api.example.com/v1/run'},
      );
      final round = ToolEntry.fromJson(t.toJson());
      expect(round.kind, ToolKind.cloud);
      expect(round.target['url'], 'https://api.example.com/v1/run');
    });

    test('js kind — entry + fn target', () {
      const t = ToolEntry(
        name: 'foo',
        kind: ToolKind.js,
        target: {'entry': 'tools/foo.js', 'fn': 'foo'},
      );
      final round = ToolEntry.fromJson(t.toJson());
      expect(round.kind, ToolKind.js);
      expect(round.target['entry'], 'tools/foo.js');
      expect(round.target['fn'], 'foo');
    });
  });

  group('ToolEntry toJson keys', () {
    test('emits required keys + omits optional null fields', () {
      const t = ToolEntry(name: 'do');
      final json = t.toJson();
      expect(json['name'], 'do');
      expect(json['kind'], 'host');
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('target'), isFalse);
      expect(json.containsKey('inputSchema'), isFalse);
      expect(json.containsKey('outputSchema'), isFalse);
      expect(json.containsKey('agentScope'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('emits target only when non-empty', () {
      const t = ToolEntry(
        name: 'do',
        target: {'transport': 'http'},
      );
      final json = t.toJson();
      expect(json['target'], {'transport': 'http'});
    });
  });

  group('ToolEntry copyWith', () {
    test('overrides selected fields', () {
      const original = ToolEntry(
        name: 'old',
        kind: ToolKind.host,
      );
      final copy = original.copyWith(
        name: 'new',
        kind: ToolKind.cloud,
        target: const {'url': 'https://x'},
      );
      expect(copy.name, 'new');
      expect(copy.kind, ToolKind.cloud);
      expect(copy.target['url'], 'https://x');
      expect(original.name, 'old');
      expect(original.kind, ToolKind.host);
    });
  });

  group('ToolEntry outputSchema', () {
    test('default null — toJson omits key', () {
      const t = ToolEntry(name: 'do');
      expect(t.outputSchema, isNull);
      final json = t.toJson();
      expect(json.containsKey('outputSchema'), isFalse);
    });

    test('Map round-trip preserves shape', () {
      const t = ToolEntry(
        name: 'studio.export',
        outputSchema: {
          'type': 'object',
          'properties': {
            'ok': {'type': 'boolean'},
            'path': {'type': 'string'},
          },
          'required': ['ok'],
        },
      );
      final json = t.toJson();
      expect(json['outputSchema'], isA<Map<String, dynamic>>());
      final round = ToolEntry.fromJson(json);
      expect(round.outputSchema, isNotNull);
      expect(round.outputSchema!['type'], 'object');
      expect(round.outputSchema!['required'], ['ok']);
      expect(
        (round.outputSchema!['properties'] as Map)['ok'],
        {'type': 'boolean'},
      );
    });

    test('fromJson casts nested Map correctly', () {
      final json = <String, dynamic>{
        'name': 'studio.export',
        'kind': 'host',
        'outputSchema': {
          'type': 'object',
          'properties': {
            'ok': {'type': 'boolean'},
          },
        },
      };
      final t = ToolEntry.fromJson(json);
      expect(t.outputSchema, isA<Map<String, dynamic>>());
      expect(t.outputSchema!['type'], 'object');
    });

    test('copyWith carries outputSchema through', () {
      const original = ToolEntry(name: 'do');
      final added = original.copyWith(
        outputSchema: const {
          'type': 'object',
          'properties': {
            'value': {'type': 'number'},
          },
        },
      );
      expect(original.outputSchema, isNull);
      expect(added.outputSchema, isNotNull);
      expect(added.outputSchema!['type'], 'object');
      // Unspecified copyWith arg preserves existing outputSchema
      final renamed = added.copyWith(name: 'do2');
      expect(renamed.outputSchema, isNotNull);
      expect(renamed.outputSchema!['type'], 'object');
    });

    test('inputSchema and outputSchema are independent', () {
      const t = ToolEntry(
        name: 'do',
        inputSchema: {'type': 'object'},
      );
      expect(t.inputSchema, isNotNull);
      expect(t.outputSchema, isNull);
      final json = t.toJson();
      expect(json.containsKey('inputSchema'), isTrue);
      expect(json.containsKey('outputSchema'), isFalse);
    });
  });

  group('ToolsSection backward compatibility', () {
    test('McpBundle.fromJson without `tools` key leaves field null', () {
      final json = {
        'schemaVersion': '1.0.0',
        'manifest': {'id': 'legacy', 'name': 'Legacy', 'version': '0.3.2'},
      };
      final bundle = McpBundle.fromJson(json);
      expect(bundle.tools, isNull);

      final reEmit = bundle.toJson();
      expect(reEmit.containsKey('tools'), isFalse);
    });
  });
}
