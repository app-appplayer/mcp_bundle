import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('FlowSection', () {
    test('creates with defaults', () {
      const section = FlowSection();
      expect(section.schemaVersion, '1.0.0');
      expect(section.flows, isEmpty);
      expect(section.sharedState, isEmpty);
      expect(section.errorHandlers, isEmpty);
    });

    test('fromJson with empty map', () {
      final section = FlowSection.fromJson({});
      expect(section.schemaVersion, '1.0.0');
      expect(section.flows, isEmpty);
    });

    test('fromJson with all fields', () {
      final section = FlowSection.fromJson({
        'schemaVersion': '2.0.0',
        'flows': [
          {'id': 'f1', 'name': 'Flow 1'},
        ],
        'sharedState': {'key': 'value'},
        'errorHandlers': [
          {'name': 'handler1'},
        ],
      });
      expect(section.schemaVersion, '2.0.0');
      expect(section.flows, hasLength(1));
      expect(section.sharedState, {'key': 'value'});
      expect(section.errorHandlers, hasLength(1));
    });

    test('toJson omits empty collections', () {
      const section = FlowSection();
      final json = section.toJson();
      expect(json['schemaVersion'], '1.0.0');
      expect(json.containsKey('flows'), isFalse);
      expect(json.containsKey('sharedState'), isFalse);
      expect(json.containsKey('errorHandlers'), isFalse);
    });

    test('toJson includes non-empty collections', () {
      final section = FlowSection(
        flows: const [FlowDefinition(id: 'f1', name: 'Flow')],
        sharedState: const {'x': 1},
        errorHandlers: const [ErrorHandler(name: 'eh1')],
      );
      final json = section.toJson();
      expect(json.containsKey('flows'), isTrue);
      expect(json.containsKey('sharedState'), isTrue);
      expect(json.containsKey('errorHandlers'), isTrue);
    });
  });

  group('FlowDefinition', () {
    test('creates with required fields', () {
      const flow = FlowDefinition(id: 'f1', name: 'Flow 1');
      expect(flow.id, 'f1');
      expect(flow.name, 'Flow 1');
      expect(flow.description, isNull);
      expect(flow.trigger, isNull);
      expect(flow.steps, isEmpty);
      expect(flow.inputs, isEmpty);
      expect(flow.output, isNull);
      expect(flow.timeoutMs, isNull);
      expect(flow.retry, isNull);
    });

    test('fromJson with all fields', () {
      final flow = FlowDefinition.fromJson({
        'id': 'f1',
        'name': 'Flow 1',
        'description': 'A flow',
        'trigger': {'type': 'manual'},
        'steps': [
          {'id': 's1', 'type': 'action'},
        ],
        'inputs': [
          {'name': 'x', 'type': 'string'},
        ],
        'output': {'type': 'object'},
        'timeoutMs': 5000,
        'retry': {'maxAttempts': 5},
      });
      expect(flow.id, 'f1');
      expect(flow.description, 'A flow');
      expect(flow.trigger, isNotNull);
      expect(flow.steps, hasLength(1));
      expect(flow.inputs, hasLength(1));
      expect(flow.output, isNotNull);
      expect(flow.timeoutMs, 5000);
      expect(flow.retry, isNotNull);
    });

    test('fromJson/toJson roundtrip', () {
      final original = {
        'id': 'f1',
        'name': 'Flow 1',
        'description': 'Test flow',
      };
      final flow = FlowDefinition.fromJson(original);
      final json = flow.toJson();
      expect(json['id'], 'f1');
      expect(json['name'], 'Flow 1');
      expect(json['description'], 'Test flow');
    });

    test('toJson omits null/empty fields', () {
      const flow = FlowDefinition(id: 'f1', name: 'Flow');
      final json = flow.toJson();
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('trigger'), isFalse);
      expect(json.containsKey('steps'), isFalse);
      expect(json.containsKey('timeoutMs'), isFalse);
      expect(json.containsKey('retry'), isFalse);
    });
  });

  group('FlowTrigger', () {
    test('creates with required fields', () {
      const trigger = FlowTrigger(type: TriggerType.manual);
      expect(trigger.type, TriggerType.manual);
      expect(trigger.config, isEmpty);
      expect(trigger.condition, isNull);
    });

    test('fromJson with all fields', () {
      final trigger = FlowTrigger.fromJson({
        'type': 'schedule',
        'config': {'cron': '0 * * * *'},
        'condition': 'state.enabled',
      });
      expect(trigger.type, TriggerType.schedule);
      expect(trigger.config, {'cron': '0 * * * *'});
      expect(trigger.condition, 'state.enabled');
    });

    test('fromJson defaults', () {
      final trigger = FlowTrigger.fromJson({});
      expect(trigger.type, TriggerType.manual);
      expect(trigger.config, isEmpty);
    });

    test('toJson omits empty/null fields', () {
      const trigger = FlowTrigger(type: TriggerType.manual);
      final json = trigger.toJson();
      expect(json['type'], 'manual');
      expect(json.containsKey('config'), isFalse);
      expect(json.containsKey('condition'), isFalse);
    });
  });

  group('TriggerType', () {
    test('fromString all values', () {
      expect(TriggerType.fromString('manual'), TriggerType.manual);
      expect(TriggerType.fromString('schedule'), TriggerType.schedule);
      expect(TriggerType.fromString('event'), TriggerType.event);
      expect(TriggerType.fromString('webhook'), TriggerType.webhook);
      expect(TriggerType.fromString('startup'), TriggerType.startup);
      expect(TriggerType.fromString('onChange'), TriggerType.onChange);
    });

    test('fromString unknown returns unknown', () {
      expect(TriggerType.fromString('invalid'), TriggerType.unknown);
    });
  });

  group('FlowStep', () {
    test('creates with required fields', () {
      const step = FlowStep(id: 's1', type: StepType.action);
      expect(step.id, 's1');
      expect(step.type, StepType.action);
      expect(step.name, isNull);
      expect(step.config, isEmpty);
      expect(step.condition, isNull);
      expect(step.next, isEmpty);
      expect(step.onError, isNull);
      expect(step.timeoutMs, isNull);
      expect(step.retry, isNull);
    });

    test('fromJson with all fields', () {
      final step = FlowStep.fromJson({
        'id': 's1',
        'type': 'skill',
        'name': 'Call skill',
        'config': {'skillId': 'sk1'},
        'condition': 'inputs.ready',
        'next': ['s2', 's3'],
        'onError': 'err1',
        'timeoutMs': 3000,
        'retry': {'maxAttempts': 2},
      });
      expect(step.id, 's1');
      expect(step.type, StepType.skill);
      expect(step.name, 'Call skill');
      expect(step.config, {'skillId': 'sk1'});
      expect(step.condition, 'inputs.ready');
      expect(step.next, ['s2', 's3']);
      expect(step.onError, 'err1');
      expect(step.timeoutMs, 3000);
      expect(step.retry, isNotNull);
    });

    test('fromJson defaults', () {
      final step = FlowStep.fromJson({});
      expect(step.type, StepType.action);
      expect(step.id, '');
    });

    test('toJson omits empty/null fields', () {
      const step = FlowStep(id: 's1', type: StepType.action);
      final json = step.toJson();
      expect(json['id'], 's1');
      expect(json['type'], 'action');
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('config'), isFalse);
      expect(json.containsKey('condition'), isFalse);
      expect(json.containsKey('next'), isFalse);
      expect(json.containsKey('onError'), isFalse);
      expect(json.containsKey('timeoutMs'), isFalse);
      expect(json.containsKey('retry'), isFalse);
    });
  });

  group('StepType', () {
    test('fromString all values', () {
      expect(StepType.fromString('action'), StepType.action);
      expect(StepType.fromString('skill'), StepType.skill);
      expect(StepType.fromString('flow'), StepType.flow);
      expect(StepType.fromString('condition'), StepType.condition);
      expect(StepType.fromString('switchCase'), StepType.switchCase);
      expect(StepType.fromString('parallel'), StepType.parallel);
      expect(StepType.fromString('loop'), StepType.loop);
      expect(StepType.fromString('wait'), StepType.wait);
      expect(StepType.fromString('setVar'), StepType.setVar);
      expect(StepType.fromString('transform'), StepType.transform);
      expect(StepType.fromString('api'), StepType.api);
      expect(StepType.fromString('llm'), StepType.llm);
      expect(StepType.fromString('output'), StepType.output);
    });

    test('fromString unknown returns unknown', () {
      expect(StepType.fromString('invalid'), StepType.unknown);
    });
  });

  group('FlowParameter', () {
    test('creates with required fields', () {
      const param = FlowParameter(name: 'x', type: 'string');
      expect(param.name, 'x');
      expect(param.type, 'string');
      expect(param.required, isFalse);
      expect(param.defaultValue, isNull);
      expect(param.description, isNull);
      expect(param.validation, isNull);
    });

    test('fromJson with all fields', () {
      final param = FlowParameter.fromJson({
        'name': 'count',
        'type': 'number',
        'required': true,
        'default': 10,
        'description': 'Item count',
        'validation': {'min': 0, 'max': 100},
      });
      expect(param.name, 'count');
      expect(param.type, 'number');
      expect(param.required, isTrue);
      expect(param.defaultValue, 10);
      expect(param.description, 'Item count');
      expect(param.validation, {'min': 0, 'max': 100});
    });

    test('fromJson defaults', () {
      final param = FlowParameter.fromJson({});
      expect(param.name, '');
      expect(param.type, 'string');
      expect(param.required, isFalse);
    });

    test('toJson omits false/null fields', () {
      const param = FlowParameter(name: 'x', type: 'string');
      final json = param.toJson();
      expect(json['name'], 'x');
      expect(json['type'], 'string');
      expect(json.containsKey('required'), isFalse);
      expect(json.containsKey('default'), isFalse);
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('validation'), isFalse);
    });

    test('toJson includes required when true', () {
      const param = FlowParameter(name: 'x', type: 'string', required: true);
      final json = param.toJson();
      expect(json['required'], isTrue);
    });
  });

  group('FlowOutput', () {
    test('creates with required fields', () {
      const output = FlowOutput(type: 'object');
      expect(output.type, 'object');
      expect(output.schema, isNull);
      expect(output.expression, isNull);
    });

    test('fromJson with all fields', () {
      final output = FlowOutput.fromJson({
        'type': 'object',
        'schema': <String, dynamic>{'properties': <String, dynamic>{}},
        'expression': 'steps.final.result',
      });
      expect(output.type, 'object');
      expect(output.schema, isNotNull);
      expect(output.expression, 'steps.final.result');
    });

    test('fromJson defaults', () {
      final output = FlowOutput.fromJson({});
      expect(output.type, 'any');
    });

    test('toJson omits null fields', () {
      const output = FlowOutput(type: 'string');
      final json = output.toJson();
      expect(json['type'], 'string');
      expect(json.containsKey('schema'), isFalse);
      expect(json.containsKey('expression'), isFalse);
    });
  });

  group('RetryConfig', () {
    test('creates with defaults', () {
      const config = RetryConfig();
      expect(config.maxAttempts, 3);
      expect(config.initialDelayMs, 1000);
      expect(config.maxDelayMs, 30000);
      expect(config.backoffMultiplier, 2.0);
      expect(config.retryOn, isEmpty);
    });

    test('fromJson with all fields', () {
      final config = RetryConfig.fromJson({
        'maxAttempts': 5,
        'initialDelayMs': 500,
        'maxDelayMs': 60000,
        'backoffMultiplier': 1.5,
        'retryOn': ['TIMEOUT', 'SERVER_ERROR'],
      });
      expect(config.maxAttempts, 5);
      expect(config.initialDelayMs, 500);
      expect(config.maxDelayMs, 60000);
      expect(config.backoffMultiplier, 1.5);
      expect(config.retryOn, ['TIMEOUT', 'SERVER_ERROR']);
    });

    test('fromJson defaults', () {
      final config = RetryConfig.fromJson({});
      expect(config.maxAttempts, 3);
      expect(config.initialDelayMs, 1000);
      expect(config.maxDelayMs, 30000);
      expect(config.backoffMultiplier, 2.0);
    });

    test('toJson omits empty retryOn', () {
      const config = RetryConfig();
      final json = config.toJson();
      expect(json['maxAttempts'], 3);
      expect(json.containsKey('retryOn'), isFalse);
    });

    test('toJson includes non-empty retryOn', () {
      const config = RetryConfig(retryOn: ['TIMEOUT']);
      final json = config.toJson();
      expect(json['retryOn'], ['TIMEOUT']);
    });
  });

  group('ErrorHandler', () {
    test('creates with required fields', () {
      const handler = ErrorHandler(name: 'handler1');
      expect(handler.name, 'handler1');
      expect(handler.patterns, isEmpty);
      expect(handler.action, isEmpty);
      expect(handler.continueFlow, isFalse);
    });

    test('fromJson with all fields', () {
      final handler = ErrorHandler.fromJson({
        'name': 'timeout_handler',
        'patterns': ['TIMEOUT', 'DEADLINE_EXCEEDED'],
        'action': {'type': 'retry'},
        'continueFlow': true,
      });
      expect(handler.name, 'timeout_handler');
      expect(handler.patterns, ['TIMEOUT', 'DEADLINE_EXCEEDED']);
      expect(handler.action, {'type': 'retry'});
      expect(handler.continueFlow, isTrue);
    });

    test('fromJson defaults', () {
      final handler = ErrorHandler.fromJson({});
      expect(handler.name, '');
      expect(handler.continueFlow, isFalse);
    });

    test('toJson omits empty/false fields', () {
      const handler = ErrorHandler(name: 'h1');
      final json = handler.toJson();
      expect(json['name'], 'h1');
      expect(json.containsKey('patterns'), isFalse);
      expect(json.containsKey('action'), isFalse);
      expect(json.containsKey('continueFlow'), isFalse);
    });

    test('toJson includes non-empty/true fields', () {
      const handler = ErrorHandler(
        name: 'h1',
        patterns: ['ERR'],
        action: {'type': 'log'},
        continueFlow: true,
      );
      final json = handler.toJson();
      expect(json['patterns'], ['ERR']);
      expect(json['action'], {'type': 'log'});
      expect(json['continueFlow'], isTrue);
    });
  });
}
