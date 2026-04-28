import 'package:test/test.dart';
// Import schema files directly to avoid name collisions with the barrel
// export which hides StepType, TriggerType, SkillTrigger, BundleManifest,
// and BundleDependency.
import 'package:mcp_bundle/src/schema/manifest_schema.dart';
import 'package:mcp_bundle/src/schema/bundle_schema.dart';

void main() {
  // ── StepType ───────────────────────────────────────────────────────────

  group('StepType', () {
    group('fromString', () {
      test('parses all known step types', () {
        expect(StepType.fromString('action'), equals(StepType.action));
        expect(StepType.fromString('condition'), equals(StepType.condition));
        expect(StepType.fromString('loop'), equals(StepType.loop));
        expect(StepType.fromString('parallel'), equals(StepType.parallel));
        expect(StepType.fromString('wait'), equals(StepType.wait));
        expect(StepType.fromString('transform'), equals(StepType.transform));
        expect(StepType.fromString('call'), equals(StepType.call));
        expect(StepType.fromString('output'), equals(StepType.output));
        expect(StepType.fromString('unknown'), equals(StepType.unknown));
      });

      test('defaults to unknown for unrecognised values', () {
        expect(StepType.fromString('nonexistent'), equals(StepType.unknown));
        expect(StepType.fromString(''), equals(StepType.unknown));
      });
    });
  });

  // ── TriggerType ────────────────────────────────────────────────────────

  group('TriggerType', () {
    group('fromString', () {
      test('parses all known trigger types', () {
        expect(TriggerType.fromString('manual'), equals(TriggerType.manual));
        expect(
            TriggerType.fromString('schedule'), equals(TriggerType.schedule));
        expect(TriggerType.fromString('event'), equals(TriggerType.event));
        expect(TriggerType.fromString('webhook'), equals(TriggerType.webhook));
        expect(TriggerType.fromString('fileChange'),
            equals(TriggerType.fileChange));
        expect(TriggerType.fromString('unknown'), equals(TriggerType.unknown));
      });

      test('defaults to unknown for unrecognised values', () {
        expect(
            TriggerType.fromString('nonexistent'), equals(TriggerType.unknown));
        expect(TriggerType.fromString(''), equals(TriggerType.unknown));
      });
    });
  });

  // ── ParameterSchema ────────────────────────────────────────────────────

  group('ParameterSchema', () {
    group('fromJson', () {
      test('parses all fields', () {
        final param = ParameterSchema.fromJson({
          'name': 'query',
          'type': 'string',
          'description': 'Search query',
          'required': false,
          'default': 'hello',
          'constraints': {'maxLength': 100},
        });

        expect(param.name, equals('query'));
        expect(param.type, equals('string'));
        expect(param.description, equals('Search query'));
        expect(param.required, isFalse);
        expect(param.defaultValue, equals('hello'));
        expect(param.constraints, equals({'maxLength': 100}));
      });

      test('applies defaults for missing fields', () {
        final param = ParameterSchema.fromJson(<String, dynamic>{});

        expect(param.name, equals(''));
        expect(param.type, equals('string'));
        expect(param.description, isNull);
        expect(param.required, isTrue);
        expect(param.defaultValue, isNull);
        expect(param.constraints, isEmpty);
      });
    });

    group('toJson', () {
      test('serialises all populated fields', () {
        const param = ParameterSchema(
          name: 'count',
          type: 'integer',
          description: 'Item count',
          required: false,
          defaultValue: 10,
          constraints: {'min': 1, 'max': 1000},
        );
        final json = param.toJson();

        expect(json['name'], equals('count'));
        expect(json['type'], equals('integer'));
        expect(json['description'], equals('Item count'));
        expect(json['required'], isFalse);
        expect(json['default'], equals(10));
        expect(json['constraints'], equals({'min': 1, 'max': 1000}));
      });

      test('omits null optional fields', () {
        const param = ParameterSchema(name: 'x', type: 'string');
        final json = param.toJson();

        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('default'), isFalse);
      });

      test('omits empty constraints', () {
        const param = ParameterSchema(name: 'x', type: 'string');
        expect(param.toJson().containsKey('constraints'), isFalse);
      });

      test('always includes required', () {
        const param = ParameterSchema(name: 'x', type: 'string');
        expect(param.toJson()['required'], isTrue);
      });
    });

    group('JSON roundtrip', () {
      test('fully populated parameter survives roundtrip', () {
        const original = ParameterSchema(
          name: 'rt-param',
          type: 'number',
          description: 'Roundtrip param',
          required: false,
          defaultValue: 3.14,
          constraints: {'precision': 2},
        );
        final restored = ParameterSchema.fromJson(original.toJson());

        expect(restored.name, equals(original.name));
        expect(restored.type, equals(original.type));
        expect(restored.description, equals(original.description));
        expect(restored.required, equals(original.required));
        expect(restored.defaultValue, equals(original.defaultValue));
        expect(restored.constraints, equals(original.constraints));
      });
    });
  });

  // ── OutputSchema ───────────────────────────────────────────────────────

  group('OutputSchema', () {
    group('fromJson', () {
      test('parses all fields', () {
        final output = OutputSchema.fromJson({
          'type': 'object',
          'schema': {
            'properties': {'name': 'string'}
          },
          'description': 'Output object',
        });

        expect(output.type, equals('object'));
        expect(output.schema, equals({
          'properties': {'name': 'string'}
        }));
        expect(output.description, equals('Output object'));
      });

      test('applies defaults for missing fields', () {
        final output = OutputSchema.fromJson(<String, dynamic>{});

        expect(output.type, equals('any'));
        expect(output.schema, isEmpty);
        expect(output.description, isNull);
      });
    });

    group('toJson', () {
      test('serialises all populated fields', () {
        const output = OutputSchema(
          type: 'array',
          schema: {'items': 'string'},
          description: 'List of strings',
        );
        final json = output.toJson();

        expect(json['type'], equals('array'));
        expect(json['schema'], equals({'items': 'string'}));
        expect(json['description'], equals('List of strings'));
      });

      test('omits empty schema', () {
        const output = OutputSchema(type: 'string');
        expect(output.toJson().containsKey('schema'), isFalse);
      });

      test('omits null description', () {
        const output = OutputSchema(type: 'string');
        expect(output.toJson().containsKey('description'), isFalse);
      });
    });

    group('JSON roundtrip', () {
      test('output schema survives roundtrip', () {
        const original = OutputSchema(
          type: 'object',
          schema: {'key': 'value'},
          description: 'Test output',
        );
        final restored = OutputSchema.fromJson(original.toJson());

        expect(restored.type, equals(original.type));
        expect(restored.schema, equals(original.schema));
        expect(restored.description, equals(original.description));
      });
    });
  });

  // ── SkillStep ──────────────────────────────────────────────────────────

  group('SkillStep', () {
    group('fromJson', () {
      test('parses all fields', () {
        final step = SkillStep.fromJson({
          'id': 'step-1',
          'type': 'action',
          'config': {'action': 'extract'},
          'condition': 'input.length > 0',
          'next': ['step-2', 'step-3'],
        });

        expect(step.id, equals('step-1'));
        expect(step.type, equals(StepType.action));
        expect(step.config, equals({'action': 'extract'}));
        expect(step.condition, equals('input.length > 0'));
        expect(step.next, equals(['step-2', 'step-3']));
      });

      test('applies defaults for missing fields', () {
        final step = SkillStep.fromJson(<String, dynamic>{});

        expect(step.id, equals(''));
        expect(step.type, equals(StepType.action));
        expect(step.config, isEmpty);
        expect(step.condition, isNull);
        expect(step.next, isEmpty);
      });

      test('parses different step types', () {
        for (final typeName in [
          'action',
          'condition',
          'loop',
          'parallel',
          'wait',
          'transform',
          'call',
          'output',
        ]) {
          final step = SkillStep.fromJson({
            'id': 'step-$typeName',
            'type': typeName,
          });
          expect(step.type, equals(StepType.fromString(typeName)));
        }
      });
    });

    group('toJson', () {
      test('serialises all populated fields', () {
        const step = SkillStep(
          id: 's1',
          type: StepType.condition,
          config: {'expr': 'x > 5'},
          condition: 'enabled == true',
          next: ['s2'],
        );
        final json = step.toJson();

        expect(json['id'], equals('s1'));
        expect(json['type'], equals('condition'));
        expect(json['config'], equals({'expr': 'x > 5'}));
        expect(json['condition'], equals('enabled == true'));
        expect(json['next'], equals(['s2']));
      });

      test('omits empty config', () {
        const step = SkillStep(id: 's', type: StepType.action);
        expect(step.toJson().containsKey('config'), isFalse);
      });

      test('omits null condition', () {
        const step = SkillStep(id: 's', type: StepType.action);
        expect(step.toJson().containsKey('condition'), isFalse);
      });

      test('omits empty next', () {
        const step = SkillStep(id: 's', type: StepType.action);
        expect(step.toJson().containsKey('next'), isFalse);
      });
    });

    group('JSON roundtrip', () {
      test('step survives roundtrip', () {
        const original = SkillStep(
          id: 'step-rt',
          type: StepType.transform,
          config: {'format': 'json'},
          condition: 'data != null',
          next: ['step-end'],
        );
        final restored = SkillStep.fromJson(original.toJson());

        expect(restored.id, equals(original.id));
        expect(restored.type, equals(original.type));
        expect(restored.config, equals(original.config));
        expect(restored.condition, equals(original.condition));
        expect(restored.next, equals(original.next));
      });
    });
  });

  // ── SkillTrigger ───────────────────────────────────────────────────────

  group('SkillTrigger', () {
    group('fromJson', () {
      test('parses all fields', () {
        final trigger = SkillTrigger.fromJson({
          'type': 'schedule',
          'config': {'cron': '0 * * * *'},
          'condition': 'isEnabled',
        });

        expect(trigger.type, equals(TriggerType.schedule));
        expect(trigger.config, equals({'cron': '0 * * * *'}));
        expect(trigger.condition, equals('isEnabled'));
      });

      test('applies defaults for missing fields', () {
        final trigger = SkillTrigger.fromJson(<String, dynamic>{});

        expect(trigger.type, equals(TriggerType.manual));
        expect(trigger.config, isEmpty);
        expect(trigger.condition, isNull);
      });
    });

    group('toJson', () {
      test('serialises all populated fields', () {
        const trigger = SkillTrigger(
          type: TriggerType.webhook,
          config: {'url': '/hook'},
          condition: 'auth.valid',
        );
        final json = trigger.toJson();

        expect(json['type'], equals('webhook'));
        expect(json['config'], equals({'url': '/hook'}));
        expect(json['condition'], equals('auth.valid'));
      });

      test('omits empty config', () {
        const trigger = SkillTrigger(type: TriggerType.manual);
        expect(trigger.toJson().containsKey('config'), isFalse);
      });

      test('omits null condition', () {
        const trigger = SkillTrigger(type: TriggerType.manual);
        expect(trigger.toJson().containsKey('condition'), isFalse);
      });
    });

    group('JSON roundtrip', () {
      test('trigger survives roundtrip', () {
        const original = SkillTrigger(
          type: TriggerType.event,
          config: {'eventType': 'user.login'},
          condition: 'user.active',
        );
        final restored = SkillTrigger.fromJson(original.toJson());

        expect(restored.type, equals(original.type));
        expect(restored.config, equals(original.config));
        expect(restored.condition, equals(original.condition));
      });
    });
  });

  // ── SkillManifest ──────────────────────────────────────────────────────

  group('SkillManifest', () {
    SkillManifest fullSkill() => const SkillManifest(
          id: 'skill-extract',
          name: 'Extract',
          description: 'Extracts claims from text',
          version: '2.0.0',
          inputs: [
            ParameterSchema(
              name: 'text',
              type: 'string',
              description: 'Input text',
            ),
          ],
          output: OutputSchema(
            type: 'array',
            schema: {'items': 'Claim'},
            description: 'Extracted claims',
          ),
          steps: [
            SkillStep(
              id: 's1',
              type: StepType.action,
              config: {'action': 'extract'},
              next: ['s2'],
            ),
            SkillStep(id: 's2', type: StepType.output),
          ],
          triggers: [
            SkillTrigger(type: TriggerType.manual),
          ],
        );

    group('fromJson', () {
      test('parses all fields', () {
        final json = {
          'id': 'sk-1',
          'name': 'Analyze',
          'description': 'Analyzes data',
          'version': '3.0.0',
          'inputs': [
            {'name': 'data', 'type': 'object'},
          ],
          'output': {'type': 'string', 'description': 'Result'},
          'steps': [
            {'id': 'step-a', 'type': 'action'},
          ],
          'triggers': [
            {'type': 'event', 'config': {'eventType': 'data.ready'}},
          ],
        };

        final skill = SkillManifest.fromJson(json);

        expect(skill.id, equals('sk-1'));
        expect(skill.name, equals('Analyze'));
        expect(skill.description, equals('Analyzes data'));
        expect(skill.version, equals('3.0.0'));
        expect(skill.inputs, hasLength(1));
        expect(skill.inputs.first.name, equals('data'));
        expect(skill.output, isNotNull);
        expect(skill.output!.type, equals('string'));
        expect(skill.steps, hasLength(1));
        expect(skill.steps.first.id, equals('step-a'));
        expect(skill.triggers, hasLength(1));
        expect(skill.triggers.first.type, equals(TriggerType.event));
      });

      test('applies defaults for missing fields', () {
        final skill = SkillManifest.fromJson(<String, dynamic>{});

        expect(skill.id, equals(''));
        expect(skill.name, equals(''));
        expect(skill.description, isNull);
        expect(skill.version, equals('1.0.0'));
        expect(skill.inputs, isEmpty);
        expect(skill.output, isNull);
        expect(skill.steps, isEmpty);
        expect(skill.triggers, isEmpty);
      });
    });

    group('toJson', () {
      test('serialises all populated fields', () {
        final json = fullSkill().toJson();

        expect(json['id'], equals('skill-extract'));
        expect(json['name'], equals('Extract'));
        expect(json['description'], equals('Extracts claims from text'));
        expect(json['version'], equals('2.0.0'));
        expect(json['inputs'], isA<List<dynamic>>());
        expect(json['inputs'] as List<dynamic>, hasLength(1));
        expect(json['output'], isA<Map<String, dynamic>>());
        expect(json['steps'], isA<List<dynamic>>());
        expect(json['steps'] as List<dynamic>, hasLength(2));
        expect(json['triggers'], isA<List<dynamic>>());
        expect(json['triggers'] as List<dynamic>, hasLength(1));
      });

      test('omits null and empty optional fields', () {
        const skill = SkillManifest(id: 'sk', name: 'Minimal');
        final json = skill.toJson();

        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('inputs'), isFalse);
        expect(json.containsKey('output'), isFalse);
        expect(json.containsKey('steps'), isFalse);
        expect(json.containsKey('triggers'), isFalse);
      });
    });

    group('JSON roundtrip', () {
      test('fully populated skill manifest survives roundtrip', () {
        final original = fullSkill();
        final restored = SkillManifest.fromJson(original.toJson());

        expect(restored.id, equals(original.id));
        expect(restored.name, equals(original.name));
        expect(restored.description, equals(original.description));
        expect(restored.version, equals(original.version));
        expect(restored.inputs.length, equals(original.inputs.length));
        expect(restored.inputs.first.name, equals(original.inputs.first.name));
        expect(restored.output, isNotNull);
        expect(restored.output!.type, equals(original.output!.type));
        expect(restored.steps.length, equals(original.steps.length));
        expect(restored.steps.first.id, equals(original.steps.first.id));
        expect(restored.triggers.length, equals(original.triggers.length));
        expect(
            restored.triggers.first.type, equals(original.triggers.first.type));
      });
    });
  });

  // ── ProfileSection ─────────────────────────────────────────────────────

  group('ProfileSection', () {
    group('fromJson', () {
      test('parses all fields', () {
        final section = ProfileSection.fromJson({
          'name': 'system',
          'content': 'You are a helpful assistant.',
          'priority': 10,
          'condition': 'context.mode == "chat"',
        });

        expect(section.name, equals('system'));
        expect(section.content, equals('You are a helpful assistant.'));
        expect(section.priority, equals(10));
        expect(section.condition, equals('context.mode == "chat"'));
      });

      test('applies defaults for missing fields', () {
        final section = ProfileSection.fromJson(<String, dynamic>{});

        expect(section.name, equals(''));
        expect(section.content, equals(''));
        expect(section.priority, equals(0));
        expect(section.condition, isNull);
      });
    });

    group('toJson', () {
      test('serialises all populated fields', () {
        const section = ProfileSection(
          name: 'intro',
          content: 'Welcome text',
          priority: 5,
          condition: 'user.isNew',
        );
        final json = section.toJson();

        expect(json['name'], equals('intro'));
        expect(json['content'], equals('Welcome text'));
        expect(json['priority'], equals(5));
        expect(json['condition'], equals('user.isNew'));
      });

      test('omits priority when zero', () {
        const section = ProfileSection(name: 'n', content: 'c');
        expect(section.toJson().containsKey('priority'), isFalse);
      });

      test('omits null condition', () {
        const section = ProfileSection(name: 'n', content: 'c');
        expect(section.toJson().containsKey('condition'), isFalse);
      });
    });

    group('JSON roundtrip', () {
      test('section survives roundtrip', () {
        const original = ProfileSection(
          name: 'rt-section',
          content: 'Roundtrip content',
          priority: 7,
          condition: 'active',
        );
        final restored = ProfileSection.fromJson(original.toJson());

        expect(restored.name, equals(original.name));
        expect(restored.content, equals(original.content));
        expect(restored.priority, equals(original.priority));
        expect(restored.condition, equals(original.condition));
      });

      test('section with defaults survives roundtrip', () {
        const original = ProfileSection(name: 'basic', content: 'text');
        final restored = ProfileSection.fromJson(original.toJson());

        expect(restored.name, equals(original.name));
        expect(restored.content, equals(original.content));
        expect(restored.priority, equals(0));
        expect(restored.condition, isNull);
      });
    });
  });

  // ── ProfileManifest ────────────────────────────────────────────────────

  group('ProfileManifest', () {
    ProfileManifest fullProfile() => const ProfileManifest(
          id: 'prof-1',
          name: 'Assistant Profile',
          description: 'A helpful assistant profile',
          version: '2.0.0',
          sections: [
            ProfileSection(
              name: 'system',
              content: 'System prompt',
              priority: 10,
            ),
            ProfileSection(
              name: 'guidelines',
              content: 'Follow these rules',
              priority: 5,
            ),
          ],
          capabilities: ['chat', 'analysis'],
        );

    group('fromJson', () {
      test('parses all fields', () {
        final json = {
          'id': 'p1',
          'name': 'Test Profile',
          'description': 'For testing',
          'version': '3.0.0',
          'sections': [
            {'name': 's1', 'content': 'content1'},
          ],
          'capabilities': ['search', 'generate'],
        };

        final profile = ProfileManifest.fromJson(json);

        expect(profile.id, equals('p1'));
        expect(profile.name, equals('Test Profile'));
        expect(profile.description, equals('For testing'));
        expect(profile.version, equals('3.0.0'));
        expect(profile.sections, hasLength(1));
        expect(profile.sections.first.name, equals('s1'));
        expect(profile.capabilities, equals(['search', 'generate']));
      });

      test('applies defaults for missing fields', () {
        final profile = ProfileManifest.fromJson(<String, dynamic>{});

        expect(profile.id, equals(''));
        expect(profile.name, equals(''));
        expect(profile.description, isNull);
        expect(profile.version, equals('1.0.0'));
        expect(profile.sections, isEmpty);
        expect(profile.capabilities, isEmpty);
      });
    });

    group('toJson', () {
      test('serialises all populated fields', () {
        final json = fullProfile().toJson();

        expect(json['id'], equals('prof-1'));
        expect(json['name'], equals('Assistant Profile'));
        expect(json['description'], equals('A helpful assistant profile'));
        expect(json['version'], equals('2.0.0'));
        expect(json['sections'], isA<List<dynamic>>());
        expect(json['sections'] as List<dynamic>, hasLength(2));
        expect(json['capabilities'], equals(['chat', 'analysis']));
      });

      test('omits null and empty optional fields', () {
        const profile = ProfileManifest(id: 'p', name: 'Min');
        final json = profile.toJson();

        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('sections'), isFalse);
        expect(json.containsKey('capabilities'), isFalse);
      });
    });

    group('JSON roundtrip', () {
      test('fully populated profile manifest survives roundtrip', () {
        final original = fullProfile();
        final restored = ProfileManifest.fromJson(original.toJson());

        expect(restored.id, equals(original.id));
        expect(restored.name, equals(original.name));
        expect(restored.description, equals(original.description));
        expect(restored.version, equals(original.version));
        expect(restored.sections.length, equals(original.sections.length));
        expect(restored.sections.first.name,
            equals(original.sections.first.name));
        expect(restored.sections.first.priority,
            equals(original.sections.first.priority));
        expect(restored.capabilities, equals(original.capabilities));
      });
    });
  });

  // ── skillToResource helper ─────────────────────────────────────────────

  group('skillToResource', () {
    test('creates BundleResource with skill type', () {
      const skill = SkillManifest(
        id: 'extract',
        name: 'Extract Skill',
        version: '1.0.0',
      );

      final resource = skillToResource(skill);

      expect(resource.type, equals(ResourceType.skill));
      expect(resource.path, equals('skills/extract.json'));
      expect(resource.content, isA<Map<String, dynamic>>());
      expect(
          (resource.content as Map<String, dynamic>)['id'], equals('extract'));
    });

    test('uses custom path when provided', () {
      const skill = SkillManifest(id: 'sk', name: 'S');

      final resource = skillToResource(skill, path: 'custom/path.json');

      expect(resource.path, equals('custom/path.json'));
    });

    test('resource content matches skill toJson', () {
      const skill = SkillManifest(
        id: 'sk',
        name: 'S',
        description: 'desc',
        version: '2.0.0',
      );

      final resource = skillToResource(skill);

      expect(resource.content, equals(skill.toJson()));
    });
  });

  // ── profileToResource helper ───────────────────────────────────────────

  group('profileToResource', () {
    test('creates BundleResource with profile type', () {
      const profile = ProfileManifest(
        id: 'assistant',
        name: 'Assistant',
        version: '1.0.0',
      );

      final resource = profileToResource(profile);

      expect(resource.type, equals(ResourceType.profile));
      expect(resource.path, equals('profiles/assistant.json'));
      expect(resource.content, isA<Map<String, dynamic>>());
      expect((resource.content as Map<String, dynamic>)['id'],
          equals('assistant'));
    });

    test('uses custom path when provided', () {
      const profile = ProfileManifest(id: 'p', name: 'P');

      final resource =
          profileToResource(profile, path: 'custom/profile.json');

      expect(resource.path, equals('custom/profile.json'));
    });

    test('resource content matches profile toJson', () {
      const profile = ProfileManifest(
        id: 'p',
        name: 'P',
        description: 'Profile desc',
        version: '3.0.0',
        capabilities: ['cap1'],
      );

      final resource = profileToResource(profile);

      expect(resource.content, equals(profile.toJson()));
    });
  });
}
