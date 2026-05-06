import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('AgentsSection (TC-086)', () {
    test('creates with defaults', () {
      const section = AgentsSection();
      expect(section.agents, isEmpty);
      expect(section.isEmpty, isTrue);
      expect(section.isNotEmpty, isFalse);
    });

    test('empty section toJson omits agents key', () {
      const section = AgentsSection();
      expect(section.toJson(), isEmpty);
    });

    test('fromJson with empty map / null agents', () {
      expect(AgentsSection.fromJson({}).agents, isEmpty);
      expect(AgentsSection.fromJson({'agents': null}).agents, isEmpty);
    });

    test('round-trip preserves 4-axis bindings + model + behavior', () {
      const original = AgentsSection(
        agents: [
          AgentDefinition(
            id: 'ui-designer',
            name: 'UI Designer',
            role: 'design',
            description: 'Designs UI from mcp_ui DSL specs.',
            profileIds: ['persona-craftsman'],
            skillIds: ['layout-compose', 'theme-apply'],
            factSourceIds: ['mcp-ui-spec', 'widget-catalogue'],
            philosophyIds: ['validated-patterns', 'no-premature-abstraction'],
            systemPrompt: 'Always honor the spec.',
            model: AgentModelConfig(
              provider: 'anthropic',
              model: 'claude-opus-4-7',
              temperature: 0.4,
              topP: 0.9,
              maxTokens: 4096,
              options: {'extra': true},
            ),
            tools: ['canvas.draw', 'spec.lookup'],
            behavior: AgentBehaviorConfig(
              turnLimit: 12,
              timeoutMs: 30000,
              maxRetries: 2,
              parallelTools: true,
              options: {'extra': 'value'},
            ),
            metadata: {'owner': 'design-team'},
          ),
        ],
      );

      final json = original.toJson();
      final round = AgentsSection.fromJson(json);

      expect(round.agents, hasLength(1));
      final a = round.agents.first;
      expect(a.id, 'ui-designer');
      expect(a.name, 'UI Designer');
      expect(a.role, 'design');
      expect(a.description, contains('mcp_ui DSL'));
      expect(a.profileIds, ['persona-craftsman']);
      expect(a.skillIds, ['layout-compose', 'theme-apply']);
      expect(a.factSourceIds, ['mcp-ui-spec', 'widget-catalogue']);
      expect(a.philosophyIds,
          ['validated-patterns', 'no-premature-abstraction']);
      expect(a.systemPrompt, 'Always honor the spec.');
      expect(a.model, isNotNull);
      expect(a.model!.provider, 'anthropic');
      expect(a.model!.model, 'claude-opus-4-7');
      expect(a.model!.temperature, 0.4);
      expect(a.model!.topP, 0.9);
      expect(a.model!.maxTokens, 4096);
      expect(a.model!.options['extra'], true);
      expect(a.tools, ['canvas.draw', 'spec.lookup']);
      expect(a.behavior, isNotNull);
      expect(a.behavior!.turnLimit, 12);
      expect(a.behavior!.timeoutMs, 30000);
      expect(a.behavior!.maxRetries, 2);
      expect(a.behavior!.parallelTools, isTrue);
      expect(a.behavior!.options['extra'], 'value');
      expect(a.metadata['owner'], 'design-team');
    });

    test('null tools survives — host default vs empty list distinction', () {
      const hostDefault = AgentDefinition(
        id: 'a1',
        name: 'A1',
        role: 'r',
        // tools: null (host applies default)
      );
      const noTools = AgentDefinition(
        id: 'a2',
        name: 'A2',
        role: 'r',
        tools: [],
      );

      final hostJson = hostDefault.toJson();
      final noToolsJson = noTools.toJson();

      expect(hostJson.containsKey('tools'), isFalse,
          reason: 'null tools must be omitted');
      expect(noToolsJson['tools'], isEmpty,
          reason: 'empty list must be present');

      final hostRound = AgentDefinition.fromJson(hostJson);
      final noToolsRound = AgentDefinition.fromJson(noToolsJson);
      expect(hostRound.tools, isNull);
      expect(noToolsRound.tools, isEmpty);
      expect(noToolsRound.tools, isNotNull);
    });

    test('empty 4-axis binding lists serialize as omitted keys', () {
      const a = AgentDefinition(id: 'a1', name: 'A', role: 'r');
      final json = a.toJson();
      expect(json.containsKey('profileIds'), isFalse);
      expect(json.containsKey('skillIds'), isFalse);
      expect(json.containsKey('factSourceIds'), isFalse);
      expect(json.containsKey('philosophyIds'), isFalse);
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('systemPrompt'), isFalse);
      expect(json.containsKey('model'), isFalse);
      expect(json.containsKey('behavior'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      expect(json.containsKey('tools'), isFalse);
    });

    test('AgentModelConfig + AgentBehaviorConfig round-trip without nulls', () {
      const m = AgentModelConfig();
      const b = AgentBehaviorConfig();
      expect(m.toJson(), isEmpty);
      expect(b.toJson(), isEmpty);
      expect(AgentModelConfig.fromJson(m.toJson()).provider, isNull);
      expect(AgentBehaviorConfig.fromJson(b.toJson()).turnLimit, isNull);
    });

    test('findById returns matching agent', () {
      const section = AgentsSection(
        agents: [
          AgentDefinition(id: 'a', name: 'A', role: 'r'),
          AgentDefinition(id: 'b', name: 'B', role: 'r'),
        ],
      );
      expect(section.findById('b')!.name, 'B');
      expect(section.findById('missing'), isNull);
    });

    test('McpBundle integration — agents section round-trips', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b1', name: 'B1', version: '1.0.0'),
        agents: AgentsSection(
          agents: [AgentDefinition(id: 'a1', name: 'A1', role: 'r')],
        ),
      );
      final json = bundle.toJson();
      expect(json['agents'], isNotNull);
      final round = McpBundle.fromJson(json);
      expect(round.agents, isNotNull);
      expect(round.agents!.agents.first.id, 'a1');
      expect(round.presentSections, contains('agents'));
      expect(round.hasContent, isTrue);
    });

    test('agents reserved folder + BundleFolder.values', () {
      expect(BundleFolder.agents.name, 'agents');
      expect(BundleFolder.values, contains(BundleFolder.agents));
      expect(BundleFolder.values, hasLength(7));
    });
  });
}
