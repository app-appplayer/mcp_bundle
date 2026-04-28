import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  // ---------------------------------------------------------------------------
  // SkillSection
  // ---------------------------------------------------------------------------
  group('SkillSection', () {
    test('fromJson with minimal JSON applies defaults', () {
      final section = SkillSection.fromJson(<String, dynamic>{});

      expect(section.schemaVersion, equals('1.0.0'));
      expect(section.modules, isEmpty);
      expect(section.config, isNull);
    });

    test('fromJson parses schemaVersion', () {
      final section = SkillSection.fromJson({
        'schemaVersion': '2.0.0',
      });

      expect(section.schemaVersion, equals('2.0.0'));
    });

    test('fromJson parses modules list', () {
      final section = SkillSection.fromJson({
        'modules': [
          {'id': 'm1', 'name': 'Module 1'},
          {'id': 'm2', 'name': 'Module 2'},
        ],
      });

      expect(section.modules, hasLength(2));
      expect(section.modules[0].id, equals('m1'));
      expect(section.modules[1].id, equals('m2'));
    });

    test('fromJson parses config', () {
      final section = SkillSection.fromJson({
        'config': {
          'defaultTimeoutMs': 5000,
        },
      });

      expect(section.config, isNotNull);
      expect(section.config!.defaultTimeoutMs, equals(5000));
    });

    test('toJson with defaults produces schemaVersion only', () {
      final section = SkillSection.fromJson(<String, dynamic>{});
      final json = section.toJson();

      expect(json['schemaVersion'], equals('1.0.0'));
      expect(json.containsKey('modules'), isFalse);
      expect(json.containsKey('config'), isFalse);
    });

    test('toJson includes modules when non-empty', () {
      final section = SkillSection.fromJson({
        'modules': [
          {'id': 's1', 'name': 'Skill One'},
        ],
      });
      final json = section.toJson();

      expect(json['modules'], isList);
      expect((json['modules'] as List), hasLength(1));
    });

    test('toJson includes config when present', () {
      final section = SkillSection.fromJson({
        'config': {'defaultTimeoutMs': 3000},
      });
      final json = section.toJson();

      expect(json.containsKey('config'), isTrue);
    });

    test('fromJson → toJson roundtrip preserves data', () {
      final input = {
        'schemaVersion': '1.2.0',
        'modules': [
          {'id': 'skill-a', 'name': 'Skill A', 'version': '2.0.0'},
        ],
        'config': {
          'defaultTimeoutMs': 10000,
          'llmDefaults': {'model': 'gpt-4'},
        },
      };

      final json = SkillSection.fromJson(input).toJson();

      expect(json['schemaVersion'], equals('1.2.0'));
      expect((json['modules'] as List).first['id'], equals('skill-a'));
      expect((json['config'] as Map)['defaultTimeoutMs'], equals(10000));
    });
  });

  // ---------------------------------------------------------------------------
  // SkillModule
  // ---------------------------------------------------------------------------
  group('SkillModule', () {
    test('fromJson with minimal JSON applies defaults', () {
      final module = SkillModule.fromJson({
        'id': 'test',
        'name': 'Test',
      });

      expect(module.id, equals('test'));
      expect(module.name, equals('Test'));
      expect(module.version, equals('1.0.0'));
      expect(module.description, isNull);
      expect(module.provider, isNull);
      expect(module.inputs, isEmpty);
      expect(module.output, isNull);
      expect(module.procedures, isEmpty);
      expect(module.triggers, isEmpty);
      expect(module.capabilities, isEmpty);
      expect(module.mcpTools, isEmpty);
      expect(module.knowledgeSources, isEmpty);
      expect(module.rubric, isNull);
    });

    test('fromJson parses all 13 fields', () {
      final module = SkillModule.fromJson({
        'id': 'qa-skill',
        'name': 'QA Skill',
        'version': '3.1.0',
        'description': 'A Q&A skill',
        'provider': 'acme-corp',
        'inputs': [
          {'name': 'query', 'type': 'string'},
        ],
        'output': {'type': 'text'},
        'procedures': [
          {'id': 'proc1', 'name': 'Main'},
        ],
        'triggers': [
          {'type': 'intent'},
        ],
        'capabilities': ['llm', 'retrieval'],
        'mcpTools': [
          {'serverId': 'srv1', 'toolName': 'search'},
        ],
        'knowledgeSources': [
          {'sourceId': 'kb1'},
        ],
        'rubric': {
          'minScore': 0.7,
          'criteria': [
            {'name': 'accuracy'},
          ],
        },
      });

      expect(module.id, equals('qa-skill'));
      expect(module.name, equals('QA Skill'));
      expect(module.version, equals('3.1.0'));
      expect(module.description, equals('A Q&A skill'));
      expect(module.provider, equals('acme-corp'));
      expect(module.inputs, hasLength(1));
      expect(module.output, isNotNull);
      expect(module.procedures, hasLength(1));
      expect(module.triggers, hasLength(1));
      expect(module.capabilities, equals(['llm', 'retrieval']));
      expect(module.mcpTools, hasLength(1));
      expect(module.knowledgeSources, hasLength(1));
      expect(module.rubric, isNotNull);
    });

    test('fromJson with missing id/name defaults to empty string', () {
      final module = SkillModule.fromJson(<String, dynamic>{});

      expect(module.id, equals(''));
      expect(module.name, equals(''));
    });

    test('toJson omits empty lists and null fields', () {
      final module = SkillModule.fromJson({
        'id': 'min',
        'name': 'Min',
      });
      final json = module.toJson();

      expect(json['id'], equals('min'));
      expect(json['name'], equals('Min'));
      expect(json['version'], equals('1.0.0'));
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('provider'), isFalse);
      expect(json.containsKey('inputs'), isFalse);
      expect(json.containsKey('output'), isFalse);
      expect(json.containsKey('procedures'), isFalse);
      expect(json.containsKey('triggers'), isFalse);
      expect(json.containsKey('capabilities'), isFalse);
      expect(json.containsKey('mcpTools'), isFalse);
      expect(json.containsKey('knowledgeSources'), isFalse);
      expect(json.containsKey('rubric'), isFalse);
    });

    test('fromJson → toJson roundtrip with rubric, mcpTools, knowledgeSources',
        () {
      final input = {
        'id': 'full-skill',
        'name': 'Full Skill',
        'version': '2.0.0',
        'description': 'Fully populated',
        'provider': 'provider-x',
        'inputs': [
          {'name': 'topic', 'type': 'string', 'required': true},
        ],
        'output': {'type': 'object', 'description': 'Result'},
        'procedures': [
          {
            'id': 'p1',
            'name': 'main',
            'steps': [
              {
                'id': 's1',
                'action': {'type': 'prompt', 'template': 'hello'},
              },
            ],
          },
        ],
        'triggers': [
          {'type': 'pattern', 'pattern': r'help\s+me'},
        ],
        'capabilities': ['llm'],
        'mcpTools': [
          {'serverId': 'srv', 'toolName': 'tool1'},
        ],
        'knowledgeSources': [
          {'sourceId': 'ks1', 'mode': 'keyword', 'topK': 5},
        ],
        'rubric': {
          'minScore': 0.8,
          'criteria': [
            {
              'name': 'relevance',
              'weight': 2.0,
              'levels': [
                {'score': 1, 'description': 'Poor'},
                {'score': 5, 'description': 'Excellent'},
              ],
            },
          ],
        },
      };

      final json = SkillModule.fromJson(input).toJson();

      expect(json['id'], equals('full-skill'));
      expect(json['version'], equals('2.0.0'));
      expect(json['provider'], equals('provider-x'));
      expect((json['mcpTools'] as List), hasLength(1));
      expect((json['knowledgeSources'] as List).first['topK'], equals(5));
      expect((json['rubric'] as Map)['minScore'], equals(0.8));
    });
  });

  // ---------------------------------------------------------------------------
  // SkillParameter
  // ---------------------------------------------------------------------------
  group('SkillParameter', () {
    test('fromJson with minimal JSON', () {
      final param = SkillParameter.fromJson({
        'name': 'query',
        'type': 'string',
      });

      expect(param.name, equals('query'));
      expect(param.type, equals('string'));
      expect(param.required, isFalse);
      expect(param.defaultValue, isNull);
      expect(param.description, isNull);
      expect(param.constraints, isNull);
    });

    test('fromJson parses required field', () {
      final param = SkillParameter.fromJson({
        'name': 'input',
        'type': 'string',
        'required': true,
      });

      expect(param.required, isTrue);
    });

    test('fromJson reads default value from "default" key', () {
      final param = SkillParameter.fromJson({
        'name': 'limit',
        'type': 'integer',
        'default': 10,
      });

      expect(param.defaultValue, equals(10));
    });

    test('fromJson parses constraints', () {
      final param = SkillParameter.fromJson({
        'name': 'count',
        'type': 'integer',
        'constraints': {'min': 1, 'max': 100},
      });

      expect(param.constraints, isNotNull);
      expect(param.constraints!['min'], equals(1));
      expect(param.constraints!['max'], equals(100));
    });

    test('toJson serializes defaultValue under "default" key', () {
      final param = SkillParameter.fromJson({
        'name': 'lang',
        'type': 'string',
        'default': 'en',
      });
      final json = param.toJson();

      expect(json['default'], equals('en'));
      expect(json.containsKey('defaultValue'), isFalse);
    });

    test('toJson omits required when false', () {
      final param = SkillParameter.fromJson({
        'name': 'opt',
        'type': 'string',
      });
      final json = param.toJson();

      expect(json.containsKey('required'), isFalse);
    });

    test('toJson includes required when true', () {
      final param = SkillParameter.fromJson({
        'name': 'mandatory',
        'type': 'string',
        'required': true,
      });
      final json = param.toJson();

      expect(json['required'], isTrue);
    });

    test('fromJson → toJson roundtrip with all fields', () {
      final input = {
        'name': 'temperature',
        'type': 'number',
        'required': true,
        'default': 0.7,
        'description': 'LLM temperature',
        'constraints': {'min': 0.0, 'max': 2.0},
      };

      final json = SkillParameter.fromJson(input).toJson();

      expect(json['name'], equals('temperature'));
      expect(json['type'], equals('number'));
      expect(json['required'], isTrue);
      expect(json['default'], equals(0.7));
      expect(json['description'], equals('LLM temperature'));
      expect(json['constraints'], equals({'min': 0.0, 'max': 2.0}));
    });
  });

  // ---------------------------------------------------------------------------
  // SkillOutput
  // ---------------------------------------------------------------------------
  group('SkillOutput', () {
    test('fromJson with missing type defaults to "any"', () {
      final output = SkillOutput.fromJson(<String, dynamic>{});

      expect(output.type, equals('any'));
      expect(output.schema, isNull);
      expect(output.description, isNull);
      expect(output.claims, isNull);
    });

    test('fromJson parses type', () {
      final output = SkillOutput.fromJson({'type': 'object'});

      expect(output.type, equals('object'));
    });

    test('fromJson parses schema', () {
      final output = SkillOutput.fromJson({
        'type': 'object',
        'schema': {
          'properties': {'result': 'string'},
        },
      });

      expect(output.schema, isNotNull);
      expect(output.schema!['properties'], isNotNull);
    });

    test('fromJson parses claims', () {
      final output = SkillOutput.fromJson({
        'type': 'text',
        'claims': [
          {'type': 'factual', 'confidence': 'high'},
        ],
      });

      expect(output.claims, isNotNull);
      expect(output.claims, hasLength(1));
      expect(output.claims!.first.type, equals('factual'));
    });

    test('toJson omits null fields', () {
      final output = SkillOutput.fromJson({'type': 'text'});
      final json = output.toJson();

      expect(json['type'], equals('text'));
      expect(json.containsKey('schema'), isFalse);
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('claims'), isFalse);
    });

    test('fromJson → toJson roundtrip with schema and claims', () {
      final input = {
        'type': 'structured',
        'description': 'Structured output',
        'schema': {'fields': ['a', 'b']},
        'claims': [
          {'type': 'inference', 'template': 'Result: {{value}}'},
        ],
      };

      final json = SkillOutput.fromJson(input).toJson();

      expect(json['type'], equals('structured'));
      expect(json['description'], equals('Structured output'));
      expect(json['schema'], equals({'fields': ['a', 'b']}));
      expect((json['claims'] as List), hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // ClaimDef
  // ---------------------------------------------------------------------------
  group('ClaimDef', () {
    test('fromJson with type only', () {
      final claim = ClaimDef.fromJson({'type': 'factual'});

      expect(claim.type, equals('factual'));
      expect(claim.template, isNull);
      expect(claim.confidence, isNull);
    });

    test('fromJson parses all fields', () {
      final claim = ClaimDef.fromJson({
        'type': 'inference',
        'template': 'Based on {{source}}',
        'confidence': 'medium',
      });

      expect(claim.type, equals('inference'));
      expect(claim.template, equals('Based on {{source}}'));
      expect(claim.confidence, equals('medium'));
    });

    test('fromJson with missing type defaults to empty string', () {
      final claim = ClaimDef.fromJson(<String, dynamic>{});

      expect(claim.type, equals(''));
    });

    test('toJson omits null template and confidence', () {
      final claim = ClaimDef.fromJson({'type': 'opinion'});
      final json = claim.toJson();

      expect(json, equals({'type': 'opinion'}));
    });

    test('fromJson → toJson roundtrip', () {
      final input = {
        'type': 'factual',
        'template': 'Fact: {{data}}',
        'confidence': 'high',
      };

      final json = ClaimDef.fromJson(input).toJson();

      expect(json, equals(input));
    });
  });

  // ---------------------------------------------------------------------------
  // SkillProcedure
  // ---------------------------------------------------------------------------
  group('SkillProcedure', () {
    test('fromJson with minimal JSON', () {
      final proc = SkillProcedure.fromJson({
        'id': 'proc-1',
        'name': 'Main Procedure',
      });

      expect(proc.id, equals('proc-1'));
      expect(proc.name, equals('Main Procedure'));
      expect(proc.description, isNull);
      expect(proc.steps, isEmpty);
      expect(proc.entryPoint, isNull);
    });

    test('fromJson parses steps', () {
      final proc = SkillProcedure.fromJson({
        'id': 'proc-2',
        'name': 'Multi-Step',
        'steps': [
          {
            'id': 'step-1',
            'action': {'type': 'prompt'},
          },
          {
            'id': 'step-2',
            'action': {'type': 'output'},
          },
        ],
      });

      expect(proc.steps, hasLength(2));
      expect(proc.steps[0].id, equals('step-1'));
      expect(proc.steps[1].id, equals('step-2'));
    });

    test('fromJson parses entryPoint', () {
      final proc = SkillProcedure.fromJson({
        'id': 'proc-3',
        'name': 'With Entry',
        'entryPoint': 'step-init',
      });

      expect(proc.entryPoint, equals('step-init'));
    });

    test('toJson omits empty steps and null fields', () {
      final proc = SkillProcedure.fromJson({
        'id': 'proc-min',
        'name': 'Minimal',
      });
      final json = proc.toJson();

      expect(json['id'], equals('proc-min'));
      expect(json['name'], equals('Minimal'));
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('steps'), isFalse);
      expect(json.containsKey('entryPoint'), isFalse);
    });

    test('fromJson → toJson roundtrip with steps and entryPoint', () {
      final input = {
        'id': 'proc-full',
        'name': 'Full Procedure',
        'description': 'A complete procedure',
        'steps': [
          {
            'id': 'init',
            'action': {'type': 'prompt', 'template': 'Start'},
          },
        ],
        'entryPoint': 'init',
      };

      final json = SkillProcedure.fromJson(input).toJson();

      expect(json['id'], equals('proc-full'));
      expect(json['description'], equals('A complete procedure'));
      expect(json['entryPoint'], equals('init'));
      expect((json['steps'] as List), hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // ProcedureStep
  // ---------------------------------------------------------------------------
  group('ProcedureStep', () {
    test('fromJson with minimal JSON', () {
      final step = ProcedureStep.fromJson({
        'id': 'step-1',
        'action': {'type': 'prompt'},
      });

      expect(step.id, equals('step-1'));
      expect(step.action.type, equals(StepActionType.prompt));
      expect(step.condition, isNull);
      expect(step.next, isEmpty);
      expect(step.onError, isNull);
    });

    test('fromJson parses condition', () {
      final step = ProcedureStep.fromJson({
        'id': 'step-cond',
        'action': {'type': 'branch'},
        'condition': 'input.score > 0.5',
      });

      expect(step.condition, equals('input.score > 0.5'));
    });

    test('fromJson parses next steps list', () {
      final step = ProcedureStep.fromJson({
        'id': 'step-fork',
        'action': {'type': 'branch'},
        'next': ['step-a', 'step-b'],
      });

      expect(step.next, equals(['step-a', 'step-b']));
    });

    test('fromJson parses onError', () {
      final step = ProcedureStep.fromJson({
        'id': 'step-err',
        'action': {'type': 'tool'},
        'onError': 'error-handler',
      });

      expect(step.onError, equals('error-handler'));
    });

    test('toJson omits null/empty optional fields', () {
      final step = ProcedureStep.fromJson({
        'id': 'step-min',
        'action': {'type': 'output'},
      });
      final json = step.toJson();

      expect(json['id'], equals('step-min'));
      expect(json.containsKey('action'), isTrue);
      expect(json.containsKey('condition'), isFalse);
      expect(json.containsKey('next'), isFalse);
      expect(json.containsKey('onError'), isFalse);
    });

    test('fromJson → toJson roundtrip with all fields', () {
      final input = {
        'id': 'step-full',
        'action': {'type': 'validate', 'schema': 'output-schema'},
        'condition': 'result != null',
        'next': ['step-next'],
        'onError': 'fallback-step',
      };

      final json = ProcedureStep.fromJson(input).toJson();

      expect(json['id'], equals('step-full'));
      expect(json['condition'], equals('result != null'));
      expect(json['next'], equals(['step-next']));
      expect(json['onError'], equals('fallback-step'));
    });
  });

  // ---------------------------------------------------------------------------
  // StepAction
  // ---------------------------------------------------------------------------
  group('StepAction', () {
    test('fromJson extracts type and puts remaining keys in config', () {
      final action = StepAction.fromJson({
        'type': 'prompt',
        'template': 'Hello {{name}}',
        'model': 'gpt-4',
      });

      expect(action.type, equals(StepActionType.prompt));
      expect(action.config['template'], equals('Hello {{name}}'));
      expect(action.config['model'], equals('gpt-4'));
      // Type should NOT be in config
      expect(action.config.containsKey('type'), isFalse);
    });

    test('fromJson with type only produces empty config', () {
      final action = StepAction.fromJson({'type': 'output'});

      expect(action.type, equals(StepActionType.output));
      expect(action.config, isEmpty);
    });

    test('toJson merges type and config at top level', () {
      final action = StepAction.fromJson({
        'type': 'tool',
        'toolName': 'search',
        'timeout': 5000,
      });
      final json = action.toJson();

      expect(json['type'], equals('tool'));
      expect(json['toolName'], equals('search'));
      expect(json['timeout'], equals(5000));
    });

    test('fromJson → toJson roundtrip with extra config keys', () {
      final input = {
        'type': 'retrieve',
        'source': 'kb-main',
        'topK': 3,
        'filter': 'category=tech',
      };

      final json = StepAction.fromJson(input).toJson();

      expect(json['type'], equals('retrieve'));
      expect(json['source'], equals('kb-main'));
      expect(json['topK'], equals(3));
      expect(json['filter'], equals('category=tech'));
    });
  });

  // ---------------------------------------------------------------------------
  // StepActionType.fromString
  // ---------------------------------------------------------------------------
  group('StepActionType.fromString', () {
    test('parses "prompt"', () {
      expect(StepActionType.fromString('prompt'), equals(StepActionType.prompt));
    });

    test('parses "tool"', () {
      expect(StepActionType.fromString('tool'), equals(StepActionType.tool));
    });

    test('parses "retrieve"', () {
      expect(
          StepActionType.fromString('retrieve'), equals(StepActionType.retrieve));
    });

    test('parses "validate"', () {
      expect(
          StepActionType.fromString('validate'), equals(StepActionType.validate));
    });

    test('parses "transform"', () {
      expect(StepActionType.fromString('transform'),
          equals(StepActionType.transform));
    });

    test('parses "branch"', () {
      expect(StepActionType.fromString('branch'), equals(StepActionType.branch));
    });

    test('parses "loop"', () {
      expect(StepActionType.fromString('loop'), equals(StepActionType.loop));
    });

    test('parses "output"', () {
      expect(StepActionType.fromString('output'), equals(StepActionType.output));
    });

    test('unknown string returns unknown', () {
      expect(StepActionType.fromString('nonexistent'),
          equals(StepActionType.unknown));
    });
  });

  // ---------------------------------------------------------------------------
  // SkillTrigger
  // ---------------------------------------------------------------------------
  group('SkillTrigger', () {
    test('fromJson with type only', () {
      final trigger = SkillTrigger.fromJson({'type': 'explicit'});

      expect(trigger.type, equals(SkillTriggerType.explicit));
      expect(trigger.pattern, isNull);
      expect(trigger.config, isEmpty);
    });

    test('fromJson parses pattern', () {
      final trigger = SkillTrigger.fromJson({
        'type': 'pattern',
        'pattern': r'help\s+.*',
      });

      expect(trigger.pattern, equals(r'help\s+.*'));
    });

    test('fromJson parses config', () {
      final trigger = SkillTrigger.fromJson({
        'type': 'event',
        'config': {'eventName': 'onStart', 'priority': 1},
      });

      expect(trigger.config['eventName'], equals('onStart'));
      expect(trigger.config['priority'], equals(1));
    });

    test('toJson omits null pattern and empty config', () {
      final trigger = SkillTrigger.fromJson({'type': 'explicit'});
      final json = trigger.toJson();

      expect(json['type'], equals('explicit'));
      expect(json.containsKey('pattern'), isFalse);
      expect(json.containsKey('config'), isFalse);
    });

    test('fromJson → toJson roundtrip with pattern and config', () {
      final input = {
        'type': 'intent',
        'pattern': 'greet',
        'config': {'threshold': 0.8},
      };

      final json = SkillTrigger.fromJson(input).toJson();

      expect(json['type'], equals('intent'));
      expect(json['pattern'], equals('greet'));
      expect((json['config'] as Map)['threshold'], equals(0.8));
    });
  });

  // ---------------------------------------------------------------------------
  // SkillTriggerType.fromString
  // ---------------------------------------------------------------------------
  group('SkillTriggerType.fromString', () {
    test('parses "explicit"', () {
      expect(SkillTriggerType.fromString('explicit'),
          equals(SkillTriggerType.explicit));
    });

    test('parses "intent"', () {
      expect(SkillTriggerType.fromString('intent'),
          equals(SkillTriggerType.intent));
    });

    test('parses "pattern"', () {
      expect(SkillTriggerType.fromString('pattern'),
          equals(SkillTriggerType.pattern));
    });

    test('parses "event"', () {
      expect(
          SkillTriggerType.fromString('event'), equals(SkillTriggerType.event));
    });

    test('unknown string returns unknown', () {
      expect(SkillTriggerType.fromString('invalid'),
          equals(SkillTriggerType.unknown));
    });
  });

  // ---------------------------------------------------------------------------
  // McpToolRef
  // ---------------------------------------------------------------------------
  group('McpToolRef', () {
    test('fromJson with required fields', () {
      final ref = McpToolRef.fromJson({
        'serverId': 'server-1',
        'toolName': 'search',
      });

      expect(ref.serverId, equals('server-1'));
      expect(ref.toolName, equals('search'));
      expect(ref.required, isTrue);
    });

    test('fromJson defaults required to true', () {
      final ref = McpToolRef.fromJson({
        'serverId': 's',
        'toolName': 't',
      });

      expect(ref.required, isTrue);
    });

    test('fromJson parses required=false', () {
      final ref = McpToolRef.fromJson({
        'serverId': 's',
        'toolName': 't',
        'required': false,
      });

      expect(ref.required, isFalse);
    });

    test('toJson omits required when true (default)', () {
      final ref = McpToolRef.fromJson({
        'serverId': 'srv',
        'toolName': 'tool',
      });
      final json = ref.toJson();

      expect(json['serverId'], equals('srv'));
      expect(json['toolName'], equals('tool'));
      expect(json.containsKey('required'), isFalse);
    });

    test('toJson includes required when false', () {
      final ref = McpToolRef.fromJson({
        'serverId': 'srv',
        'toolName': 'tool',
        'required': false,
      });
      final json = ref.toJson();

      expect(json['required'], isFalse);
    });

    test('fromJson → toJson roundtrip', () {
      final input = {
        'serverId': 'my-server',
        'toolName': 'my-tool',
        'required': false,
      };

      final json = McpToolRef.fromJson(input).toJson();

      expect(json, equals(input));
    });
  });

  // ---------------------------------------------------------------------------
  // KnowledgeSourceRef
  // ---------------------------------------------------------------------------
  group('KnowledgeSourceRef', () {
    test('fromJson with sourceId only', () {
      final ref = KnowledgeSourceRef.fromJson({'sourceId': 'kb-1'});

      expect(ref.sourceId, equals('kb-1'));
      expect(ref.mode, equals('similarity'));
      expect(ref.topK, isNull);
    });

    test('fromJson defaults mode to "similarity"', () {
      final ref = KnowledgeSourceRef.fromJson({'sourceId': 'kb-2'});

      expect(ref.mode, equals('similarity'));
    });

    test('fromJson parses custom mode', () {
      final ref = KnowledgeSourceRef.fromJson({
        'sourceId': 'kb-3',
        'mode': 'keyword',
      });

      expect(ref.mode, equals('keyword'));
    });

    test('fromJson parses topK', () {
      final ref = KnowledgeSourceRef.fromJson({
        'sourceId': 'kb-4',
        'topK': 10,
      });

      expect(ref.topK, equals(10));
    });

    test('toJson omits topK when null', () {
      final ref = KnowledgeSourceRef.fromJson({'sourceId': 'kb-5'});
      final json = ref.toJson();

      expect(json['sourceId'], equals('kb-5'));
      expect(json['mode'], equals('similarity'));
      expect(json.containsKey('topK'), isFalse);
    });

    test('fromJson → toJson roundtrip with topK', () {
      final input = {
        'sourceId': 'kb-full',
        'mode': 'hybrid',
        'topK': 15,
      };

      final json = KnowledgeSourceRef.fromJson(input).toJson();

      expect(json, equals(input));
    });
  });

  // ---------------------------------------------------------------------------
  // SkillRubric
  // ---------------------------------------------------------------------------
  group('SkillRubric', () {
    test('fromJson with empty JSON', () {
      final rubric = SkillRubric.fromJson(<String, dynamic>{});

      expect(rubric.criteria, isEmpty);
      expect(rubric.minScore, isNull);
    });

    test('fromJson parses criteria', () {
      final rubric = SkillRubric.fromJson({
        'criteria': [
          {'name': 'accuracy'},
          {'name': 'completeness'},
        ],
      });

      expect(rubric.criteria, hasLength(2));
      expect(rubric.criteria[0].name, equals('accuracy'));
      expect(rubric.criteria[1].name, equals('completeness'));
    });

    test('fromJson parses minScore', () {
      final rubric = SkillRubric.fromJson({'minScore': 0.75});

      expect(rubric.minScore, equals(0.75));
    });

    test('toJson omits empty criteria and null minScore', () {
      final rubric = SkillRubric.fromJson(<String, dynamic>{});
      final json = rubric.toJson();

      expect(json.containsKey('criteria'), isFalse);
      expect(json.containsKey('minScore'), isFalse);
    });

    test('fromJson → toJson roundtrip with criteria and minScore', () {
      final input = {
        'criteria': [
          {'name': 'quality', 'weight': 1.5},
        ],
        'minScore': 0.6,
      };

      final json = SkillRubric.fromJson(input).toJson();

      expect(json['minScore'], equals(0.6));
      expect((json['criteria'] as List), hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // RubricCriterion
  // ---------------------------------------------------------------------------
  group('RubricCriterion', () {
    test('fromJson with name only applies defaults', () {
      final criterion = RubricCriterion.fromJson({'name': 'accuracy'});

      expect(criterion.name, equals('accuracy'));
      expect(criterion.description, isNull);
      expect(criterion.weight, equals(1.0));
      expect(criterion.levels, isEmpty);
    });

    test('fromJson defaults weight to 1.0', () {
      final criterion = RubricCriterion.fromJson({'name': 'test'});

      expect(criterion.weight, equals(1.0));
    });

    test('fromJson parses custom weight', () {
      final criterion = RubricCriterion.fromJson({
        'name': 'importance',
        'weight': 3.0,
      });

      expect(criterion.weight, equals(3.0));
    });

    test('fromJson parses levels', () {
      final criterion = RubricCriterion.fromJson({
        'name': 'graded',
        'levels': [
          {'score': 1, 'description': 'Poor'},
          {'score': 3, 'description': 'Average'},
          {'score': 5, 'description': 'Excellent'},
        ],
      });

      expect(criterion.levels, hasLength(3));
      expect(criterion.levels[0].score, equals(1));
      expect(criterion.levels[2].description, equals('Excellent'));
    });

    test('toJson always includes weight', () {
      final criterion = RubricCriterion.fromJson({'name': 'test'});
      final json = criterion.toJson();

      expect(json['weight'], equals(1.0));
    });

    test('toJson omits empty levels', () {
      final criterion = RubricCriterion.fromJson({'name': 'no-levels'});
      final json = criterion.toJson();

      expect(json.containsKey('levels'), isFalse);
    });

    test('fromJson → toJson roundtrip with all fields', () {
      final input = {
        'name': 'coherence',
        'description': 'Response coherence',
        'weight': 2.5,
        'levels': [
          {'score': 0, 'description': 'Incoherent'},
          {'score': 5, 'description': 'Fully coherent'},
        ],
      };

      final json = RubricCriterion.fromJson(input).toJson();

      expect(json['name'], equals('coherence'));
      expect(json['description'], equals('Response coherence'));
      expect(json['weight'], equals(2.5));
      expect((json['levels'] as List), hasLength(2));
    });
  });

  // ---------------------------------------------------------------------------
  // ScoringLevel
  // ---------------------------------------------------------------------------
  group('ScoringLevel', () {
    test('fromJson parses score and description', () {
      final level = ScoringLevel.fromJson({
        'score': 4,
        'description': 'Very good',
      });

      expect(level.score, equals(4));
      expect(level.description, equals('Very good'));
    });

    test('fromJson defaults score to 0 and description to empty', () {
      final level = ScoringLevel.fromJson(<String, dynamic>{});

      expect(level.score, equals(0));
      expect(level.description, equals(''));
    });

    test('fromJson → toJson roundtrip', () {
      final input = {'score': 3, 'description': 'Good'};

      final json = ScoringLevel.fromJson(input).toJson();

      expect(json, equals(input));
    });
  });

  // ---------------------------------------------------------------------------
  // SkillConfig
  // ---------------------------------------------------------------------------
  group('SkillConfig', () {
    test('fromJson with empty JSON applies defaults', () {
      final config = SkillConfig.fromJson(<String, dynamic>{});

      expect(config.llmDefaults, isEmpty);
      expect(config.defaultTimeoutMs, isNull);
      expect(config.retryDefaults, isNull);
    });

    test('fromJson parses llmDefaults', () {
      final config = SkillConfig.fromJson({
        'llmDefaults': {'model': 'claude-3', 'temperature': 0.5},
      });

      expect(config.llmDefaults['model'], equals('claude-3'));
      expect(config.llmDefaults['temperature'], equals(0.5));
    });

    test('fromJson parses defaultTimeoutMs', () {
      final config = SkillConfig.fromJson({'defaultTimeoutMs': 30000});

      expect(config.defaultTimeoutMs, equals(30000));
    });

    test('fromJson parses retryDefaults', () {
      final config = SkillConfig.fromJson({
        'retryDefaults': {'maxRetries': 3, 'backoffMs': 1000},
      });

      expect(config.retryDefaults, isNotNull);
      expect(config.retryDefaults!['maxRetries'], equals(3));
    });

    test('toJson omits empty llmDefaults and null fields', () {
      final config = SkillConfig.fromJson(<String, dynamic>{});
      final json = config.toJson();

      expect(json.containsKey('llmDefaults'), isFalse);
      expect(json.containsKey('defaultTimeoutMs'), isFalse);
      expect(json.containsKey('retryDefaults'), isFalse);
    });

    test('fromJson → toJson roundtrip with all fields', () {
      final input = {
        'llmDefaults': {'model': 'gpt-4', 'maxTokens': 2048},
        'defaultTimeoutMs': 15000,
        'retryDefaults': {'maxRetries': 2, 'backoffMs': 500},
      };

      final json = SkillConfig.fromJson(input).toJson();

      expect(json['llmDefaults'], equals({'model': 'gpt-4', 'maxTokens': 2048}));
      expect(json['defaultTimeoutMs'], equals(15000));
      expect(json['retryDefaults'],
          equals({'maxRetries': 2, 'backoffMs': 500}));
    });
  });
}
