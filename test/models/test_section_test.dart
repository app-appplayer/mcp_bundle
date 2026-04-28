import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  // =========================================================================
  // TestSection
  // =========================================================================
  group('TestSection', () {
    test('creates with default values', () {
      const section = TestSection();

      expect(section.schemaVersion, equals('1.0.0'));
      expect(section.suites, isEmpty);
      expect(section.fixtures, isEmpty);
      expect(section.config, isNull);
    });

    test('creates with custom schemaVersion', () {
      const section = TestSection(schemaVersion: '2.0.0');

      expect(section.schemaVersion, equals('2.0.0'));
    });

    test('creates with suites', () {
      const section = TestSection(
        suites: [
          TestSuite(id: 'suite-1', name: 'Suite 1'),
          TestSuite(id: 'suite-2', name: 'Suite 2'),
        ],
      );

      expect(section.suites.length, equals(2));
      expect(section.suites[0].id, equals('suite-1'));
      expect(section.suites[1].id, equals('suite-2'));
    });

    test('creates with fixtures', () {
      const section = TestSection(
        fixtures: {
          'user': TestFixture(name: 'user-fixture'),
          'product': TestFixture(name: 'product-fixture'),
        },
      );

      expect(section.fixtures.length, equals(2));
      expect(section.fixtures['user']!.name, equals('user-fixture'));
      expect(section.fixtures['product']!.name, equals('product-fixture'));
    });

    test('creates with config', () {
      const section = TestSection(
        config: TestConfig(parallel: true, retryCount: 3),
      );

      expect(section.config, isNotNull);
      expect(section.config!.parallel, isTrue);
      expect(section.config!.retryCount, equals(3));
    });

    test('fromJson with empty map uses defaults', () {
      final section = TestSection.fromJson({});

      expect(section.schemaVersion, equals('1.0.0'));
      expect(section.suites, isEmpty);
      expect(section.fixtures, isEmpty);
      expect(section.config, isNull);
    });

    test('fromJson parses all fields', () {
      final section = TestSection.fromJson({
        'schemaVersion': '2.0.0',
        'suites': [
          {'id': 's1', 'name': 'Suite 1'},
        ],
        'fixtures': {
          'fx1': {'name': 'Fixture 1'},
        },
        'config': {
          'parallel': true,
        },
      });

      expect(section.schemaVersion, equals('2.0.0'));
      expect(section.suites.length, equals(1));
      expect(section.suites[0].id, equals('s1'));
      expect(section.fixtures.length, equals(1));
      expect(section.fixtures['fx1']!.name, equals('Fixture 1'));
      expect(section.config, isNotNull);
      expect(section.config!.parallel, isTrue);
    });

    test('toJson includes schemaVersion always', () {
      const section = TestSection();
      final json = section.toJson();

      expect(json['schemaVersion'], equals('1.0.0'));
    });

    test('toJson omits empty suites', () {
      const section = TestSection();
      final json = section.toJson();

      expect(json.containsKey('suites'), isFalse);
    });

    test('toJson omits empty fixtures', () {
      const section = TestSection();
      final json = section.toJson();

      expect(json.containsKey('fixtures'), isFalse);
    });

    test('toJson omits null config', () {
      const section = TestSection();
      final json = section.toJson();

      expect(json.containsKey('config'), isFalse);
    });

    test('toJson includes non-empty suites', () {
      const section = TestSection(
        suites: [TestSuite(id: 's1', name: 'Suite')],
      );
      final json = section.toJson();

      expect(json.containsKey('suites'), isTrue);
      expect((json['suites'] as List).length, equals(1));
    });

    test('toJson includes non-empty fixtures', () {
      const section = TestSection(
        fixtures: {'fx': TestFixture(name: 'FX')},
      );
      final json = section.toJson();

      expect(json.containsKey('fixtures'), isTrue);
    });

    test('toJson includes non-null config', () {
      const section = TestSection(config: TestConfig());
      final json = section.toJson();

      expect(json.containsKey('config'), isTrue);
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final original = TestSection.fromJson({
        'schemaVersion': '1.0.0',
        'suites': [
          {
            'id': 's1',
            'name': 'Auth Suite',
            'tests': [
              {'id': 't1', 'name': 'Login test', 'type': 'unit'},
            ],
          },
        ],
        'fixtures': {
          'user': {'name': 'user-fixture', 'data': {'username': 'admin'}},
        },
        'config': {'defaultTimeoutMs': 5000, 'parallel': true},
      });

      final json = original.toJson();
      final restored = TestSection.fromJson(json);

      expect(restored.schemaVersion, equals(original.schemaVersion));
      expect(restored.suites.length, equals(original.suites.length));
      expect(restored.suites[0].id, equals('s1'));
      expect(restored.fixtures.length, equals(original.fixtures.length));
      expect(restored.config!.parallel, isTrue);
    });
  });

  // =========================================================================
  // TestSuite
  // =========================================================================
  group('TestSuite', () {
    test('creates with required fields only', () {
      const suite = TestSuite(id: 'suite-1', name: 'My Suite');

      expect(suite.id, equals('suite-1'));
      expect(suite.name, equals('My Suite'));
      expect(suite.description, isNull);
      expect(suite.tests, isEmpty);
      expect(suite.setup, isNull);
      expect(suite.teardown, isNull);
      expect(suite.tags, isEmpty);
      expect(suite.timeoutMs, isNull);
    });

    test('creates with all fields', () {
      const suite = TestSuite(
        id: 'suite-full',
        name: 'Full Suite',
        description: 'A comprehensive test suite',
        tests: [TestCase(id: 'tc1', name: 'Test 1')],
        setup: [TestStep(action: TestStepAction.execute)],
        teardown: [TestStep(action: TestStepAction.restore)],
        tags: ['smoke', 'regression'],
        timeoutMs: 60000,
      );

      expect(suite.id, equals('suite-full'));
      expect(suite.name, equals('Full Suite'));
      expect(suite.description, equals('A comprehensive test suite'));
      expect(suite.tests.length, equals(1));
      expect(suite.setup!.length, equals(1));
      expect(suite.teardown!.length, equals(1));
      expect(suite.tags, equals(['smoke', 'regression']));
      expect(suite.timeoutMs, equals(60000));
    });

    test('fromJson with empty map uses defaults', () {
      final suite = TestSuite.fromJson({});

      expect(suite.id, equals(''));
      expect(suite.name, equals(''));
      expect(suite.description, isNull);
      expect(suite.tests, isEmpty);
      expect(suite.setup, isNull);
      expect(suite.teardown, isNull);
      expect(suite.tags, isEmpty);
      expect(suite.timeoutMs, isNull);
    });

    test('fromJson parses all fields', () {
      final suite = TestSuite.fromJson({
        'id': 'suite-parsed',
        'name': 'Parsed Suite',
        'description': 'Parsed description',
        'tests': [
          {'id': 'tc1', 'name': 'Test 1'},
        ],
        'setup': [
          {'action': 'execute', 'config': {'cmd': 'init'}},
        ],
        'teardown': [
          {'action': 'restore'},
        ],
        'tags': ['fast', 'unit'],
        'timeoutMs': 10000,
      });

      expect(suite.id, equals('suite-parsed'));
      expect(suite.name, equals('Parsed Suite'));
      expect(suite.description, equals('Parsed description'));
      expect(suite.tests.length, equals(1));
      expect(suite.setup!.length, equals(1));
      expect(suite.teardown!.length, equals(1));
      expect(suite.tags, equals(['fast', 'unit']));
      expect(suite.timeoutMs, equals(10000));
    });

    test('toJson includes id and name always', () {
      const suite = TestSuite(id: 'x', name: 'X');
      final json = suite.toJson();

      expect(json['id'], equals('x'));
      expect(json['name'], equals('X'));
    });

    test('toJson omits null description', () {
      const suite = TestSuite(id: 'x', name: 'X');
      final json = suite.toJson();

      expect(json.containsKey('description'), isFalse);
    });

    test('toJson omits empty tests', () {
      const suite = TestSuite(id: 'x', name: 'X');
      final json = suite.toJson();

      expect(json.containsKey('tests'), isFalse);
    });

    test('toJson omits null setup', () {
      const suite = TestSuite(id: 'x', name: 'X');
      final json = suite.toJson();

      expect(json.containsKey('setup'), isFalse);
    });

    test('toJson omits null teardown', () {
      const suite = TestSuite(id: 'x', name: 'X');
      final json = suite.toJson();

      expect(json.containsKey('teardown'), isFalse);
    });

    test('toJson omits empty tags', () {
      const suite = TestSuite(id: 'x', name: 'X');
      final json = suite.toJson();

      expect(json.containsKey('tags'), isFalse);
    });

    test('toJson omits null timeoutMs', () {
      const suite = TestSuite(id: 'x', name: 'X');
      final json = suite.toJson();

      expect(json.containsKey('timeoutMs'), isFalse);
    });

    test('toJson includes all present fields', () {
      const suite = TestSuite(
        id: 'full',
        name: 'Full',
        description: 'Desc',
        tests: [TestCase(id: 't1', name: 'T1')],
        setup: [TestStep(action: TestStepAction.execute)],
        teardown: [TestStep(action: TestStepAction.restore)],
        tags: ['tag1'],
        timeoutMs: 5000,
      );
      final json = suite.toJson();

      expect(json.containsKey('description'), isTrue);
      expect(json.containsKey('tests'), isTrue);
      expect(json.containsKey('setup'), isTrue);
      expect(json.containsKey('teardown'), isTrue);
      expect(json.containsKey('tags'), isTrue);
      expect(json.containsKey('timeoutMs'), isTrue);
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final original = TestSuite.fromJson({
        'id': 'rt-suite',
        'name': 'Roundtrip Suite',
        'description': 'Testing roundtrip',
        'tests': [
          {'id': 'tc1', 'name': 'TC1', 'type': 'integration'},
        ],
        'setup': [
          {'action': 'mock'},
        ],
        'teardown': [
          {'action': 'restore'},
        ],
        'tags': ['ci'],
        'timeoutMs': 30000,
      });

      final json = original.toJson();
      final restored = TestSuite.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.description, equals(original.description));
      expect(restored.tests.length, equals(1));
      expect(restored.tags, equals(original.tags));
      expect(restored.timeoutMs, equals(original.timeoutMs));
    });
  });

  // =========================================================================
  // TestCase
  // =========================================================================
  group('TestCase', () {
    test('creates with required fields only and defaults', () {
      const tc = TestCase(id: 'tc-1', name: 'Test Case 1');

      expect(tc.id, equals('tc-1'));
      expect(tc.name, equals('Test Case 1'));
      expect(tc.description, isNull);
      expect(tc.type, equals(TestType.unit));
      expect(tc.steps, isEmpty);
      expect(tc.expected, isNull);
      expect(tc.input, isNull);
      expect(tc.timeoutMs, isNull);
      expect(tc.skip, isFalse);
      expect(tc.skipReason, isNull);
    });

    test('creates with all fields', () {
      const tc = TestCase(
        id: 'tc-full',
        name: 'Full Test',
        description: 'A full test case',
        type: TestType.integration,
        steps: [TestStep(action: TestStepAction.execute)],
        expected: ExpectedResult(type: ResultType.success),
        input: {'key': 'value'},
        timeoutMs: 5000,
        skip: true,
        skipReason: 'Not ready yet',
      );

      expect(tc.id, equals('tc-full'));
      expect(tc.description, equals('A full test case'));
      expect(tc.type, equals(TestType.integration));
      expect(tc.steps.length, equals(1));
      expect(tc.expected, isNotNull);
      expect(tc.input, equals({'key': 'value'}));
      expect(tc.timeoutMs, equals(5000));
      expect(tc.skip, isTrue);
      expect(tc.skipReason, equals('Not ready yet'));
    });

    test('fromJson with empty map uses defaults', () {
      final tc = TestCase.fromJson({});

      expect(tc.id, equals(''));
      expect(tc.name, equals(''));
      expect(tc.type, equals(TestType.unit));
      expect(tc.steps, isEmpty);
      expect(tc.skip, isFalse);
    });

    test('fromJson parses all fields', () {
      final tc = TestCase.fromJson({
        'id': 'parsed-tc',
        'name': 'Parsed',
        'description': 'Parsed desc',
        'type': 'e2e',
        'steps': [
          {'action': 'navigate'},
        ],
        'expected': {'type': 'success', 'value': 42},
        'input': {'username': 'test'},
        'timeoutMs': 15000,
        'skip': true,
        'skipReason': 'Flaky',
      });

      expect(tc.id, equals('parsed-tc'));
      expect(tc.name, equals('Parsed'));
      expect(tc.description, equals('Parsed desc'));
      expect(tc.type, equals(TestType.e2e));
      expect(tc.steps.length, equals(1));
      expect(tc.expected!.type, equals(ResultType.success));
      expect(tc.expected!.value, equals(42));
      expect(tc.input, equals({'username': 'test'}));
      expect(tc.timeoutMs, equals(15000));
      expect(tc.skip, isTrue);
      expect(tc.skipReason, equals('Flaky'));
    });

    test('toJson includes id, name, and type always', () {
      const tc = TestCase(id: 'tc-1', name: 'TC');
      final json = tc.toJson();

      expect(json['id'], equals('tc-1'));
      expect(json['name'], equals('TC'));
      expect(json['type'], equals('unit'));
    });

    test('toJson omits optional null/empty/false fields', () {
      const tc = TestCase(id: 'tc-1', name: 'TC');
      final json = tc.toJson();

      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('steps'), isFalse);
      expect(json.containsKey('expected'), isFalse);
      expect(json.containsKey('input'), isFalse);
      expect(json.containsKey('timeoutMs'), isFalse);
      expect(json.containsKey('skip'), isFalse);
      expect(json.containsKey('skipReason'), isFalse);
    });

    test('toJson includes skip only when true', () {
      const skipped = TestCase(id: 'tc-1', name: 'TC', skip: true);
      final json = skipped.toJson();

      expect(json['skip'], isTrue);
    });

    test('toJson includes skipReason when present', () {
      const tc = TestCase(
        id: 'tc-1',
        name: 'TC',
        skip: true,
        skipReason: 'WIP',
      );
      final json = tc.toJson();

      expect(json['skipReason'], equals('WIP'));
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final original = TestCase.fromJson({
        'id': 'rt-tc',
        'name': 'Roundtrip TC',
        'description': 'Testing roundtrip',
        'type': 'performance',
        'steps': [
          {'action': 'execute', 'config': {'iterations': 1000}},
        ],
        'expected': {'type': 'success'},
        'input': {'size': 100},
        'timeoutMs': 60000,
        'skip': true,
        'skipReason': 'Slow',
      });

      final json = original.toJson();
      final restored = TestCase.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.type, equals(TestType.performance));
      expect(restored.skip, isTrue);
      expect(restored.skipReason, equals('Slow'));
      expect(restored.timeoutMs, equals(60000));
    });
  });

  // =========================================================================
  // TestType
  // =========================================================================
  group('TestType', () {
    test('fromString parses unit', () {
      expect(TestType.fromString('unit'), equals(TestType.unit));
    });

    test('fromString parses integration', () {
      expect(TestType.fromString('integration'), equals(TestType.integration));
    });

    test('fromString parses e2e', () {
      expect(TestType.fromString('e2e'), equals(TestType.e2e));
    });

    test('fromString parses snapshot', () {
      expect(TestType.fromString('snapshot'), equals(TestType.snapshot));
    });

    test('fromString parses performance', () {
      expect(TestType.fromString('performance'), equals(TestType.performance));
    });

    test('fromString returns unknown for unrecognized value', () {
      expect(TestType.fromString('randomType'), equals(TestType.unknown));
    });

    test('fromString returns unknown for empty string', () {
      expect(TestType.fromString(''), equals(TestType.unknown));
    });
  });

  // =========================================================================
  // TestStep
  // =========================================================================
  group('TestStep', () {
    test('creates with required action and defaults', () {
      const step = TestStep(action: TestStepAction.execute);

      expect(step.action, equals(TestStepAction.execute));
      expect(step.config, isEmpty);
      expect(step.assertion, isNull);
    });

    test('creates with all fields', () {
      const step = TestStep(
        action: TestStepAction.click,
        config: {'selector': '#submit-btn'},
        assertion: TestAssertion(
          type: AssertionType.visible,
          target: '#result',
        ),
      );

      expect(step.action, equals(TestStepAction.click));
      expect(step.config['selector'], equals('#submit-btn'));
      expect(step.assertion, isNotNull);
      expect(step.assertion!.type, equals(AssertionType.visible));
    });

    test('fromJson with empty map uses defaults', () {
      final step = TestStep.fromJson({});

      expect(step.action, equals(TestStepAction.execute));
      expect(step.config, isEmpty);
      expect(step.assertion, isNull);
    });

    test('fromJson parses action', () {
      final step = TestStep.fromJson({'action': 'navigate'});

      expect(step.action, equals(TestStepAction.navigate));
    });

    test('fromJson parses config', () {
      final step = TestStep.fromJson({
        'action': 'input',
        'config': {'field': 'email', 'value': 'test@example.com'},
      });

      expect(step.config['field'], equals('email'));
      expect(step.config['value'], equals('test@example.com'));
    });

    test('fromJson parses assertion', () {
      final step = TestStep.fromJson({
        'action': 'assert',
        'assertion': {
          'type': 'value',
          'target': 'result.count',
          'expected': 5,
        },
      });

      expect(step.action, equals(TestStepAction.assert_));
      expect(step.assertion, isNotNull);
      expect(step.assertion!.expected, equals(5));
    });

    test('toJson includes action always', () {
      const step = TestStep(action: TestStepAction.wait);
      final json = step.toJson();

      expect(json['action'], equals('wait'));
    });

    test('toJson omits empty config', () {
      const step = TestStep(action: TestStepAction.execute);
      final json = step.toJson();

      expect(json.containsKey('config'), isFalse);
    });

    test('toJson omits null assertion', () {
      const step = TestStep(action: TestStepAction.execute);
      final json = step.toJson();

      expect(json.containsKey('assertion'), isFalse);
    });

    test('toJson includes non-empty config', () {
      const step = TestStep(
        action: TestStepAction.execute,
        config: {'cmd': 'run'},
      );
      final json = step.toJson();

      expect(json.containsKey('config'), isTrue);
      expect(json['config'], equals({'cmd': 'run'}));
    });

    test('toJson includes non-null assertion', () {
      const step = TestStep(
        action: TestStepAction.assert_,
        assertion: TestAssertion(
          type: AssertionType.value,
          target: 'x',
        ),
      );
      final json = step.toJson();

      expect(json.containsKey('assertion'), isTrue);
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final original = TestStep.fromJson({
        'action': 'click',
        'config': {'selector': '.btn', 'delay': 100},
        'assertion': {
          'type': 'visible',
          'target': '.result',
          'expected': true,
        },
      });

      final json = original.toJson();
      final restored = TestStep.fromJson(json);

      expect(restored.action, equals(TestStepAction.click));
      expect(restored.config['selector'], equals('.btn'));
      expect(restored.assertion!.type, equals(AssertionType.visible));
    });
  });

  // =========================================================================
  // TestStepAction (CRITICAL - special assert_ handling)
  // =========================================================================
  group('TestStepAction', () {
    group('fromString', () {
      test('parses "assert" to assert_ (special conversion)', () {
        expect(
          TestStepAction.fromString('assert'),
          equals(TestStepAction.assert_),
        );
      });

      test('parses "execute"', () {
        expect(
          TestStepAction.fromString('execute'),
          equals(TestStepAction.execute),
        );
      });

      test('parses "navigate"', () {
        expect(
          TestStepAction.fromString('navigate'),
          equals(TestStepAction.navigate),
        );
      });

      test('parses "click"', () {
        expect(
          TestStepAction.fromString('click'),
          equals(TestStepAction.click),
        );
      });

      test('parses "input"', () {
        expect(
          TestStepAction.fromString('input'),
          equals(TestStepAction.input),
        );
      });

      test('parses "wait"', () {
        expect(
          TestStepAction.fromString('wait'),
          equals(TestStepAction.wait),
        );
      });

      test('parses "mock"', () {
        expect(
          TestStepAction.fromString('mock'),
          equals(TestStepAction.mock),
        );
      });

      test('parses "restore"', () {
        expect(
          TestStepAction.fromString('restore'),
          equals(TestStepAction.restore),
        );
      });

      test('returns unknown for unrecognized value', () {
        expect(
          TestStepAction.fromString('nonexistent'),
          equals(TestStepAction.unknown),
        );
      });

      test('returns unknown for empty string', () {
        expect(
          TestStepAction.fromString(''),
          equals(TestStepAction.unknown),
        );
      });

      test('"assert_" string does NOT map to assert_ (uses special path)', () {
        // The fromString matches on 'assert' (without underscore).
        // 'assert_' goes to firstWhere which checks e.name == value,
        // but the name getter for assert_ returns 'assert', not 'assert_',
        // so it doesn't match and returns unknown.
        final result = TestStepAction.fromString('assert_');
        expect(result, equals(TestStepAction.unknown));
      });
    });

    group('name getter', () {
      test('assert_ returns "assert" (not "assert_")', () {
        expect(TestStepAction.assert_.name, equals('assert'));
      });

      test('execute returns "execute"', () {
        expect(TestStepAction.execute.name, equals('execute'));
      });

      test('navigate returns "navigate"', () {
        expect(TestStepAction.navigate.name, equals('navigate'));
      });

      test('click returns "click"', () {
        expect(TestStepAction.click.name, equals('click'));
      });

      test('input returns "input"', () {
        expect(TestStepAction.input.name, equals('input'));
      });

      test('wait returns "wait"', () {
        expect(TestStepAction.wait.name, equals('wait'));
      });

      test('mock returns "mock"', () {
        expect(TestStepAction.mock.name, equals('mock'));
      });

      test('restore returns "restore"', () {
        expect(TestStepAction.restore.name, equals('restore'));
      });

      test('unknown returns "unknown"', () {
        expect(TestStepAction.unknown.name, equals('unknown'));
      });
    });

    group('roundtrip assert_ handling', () {
      test('fromString("assert").name returns "assert"', () {
        final action = TestStepAction.fromString('assert');
        expect(action.name, equals('assert'));
      });

      test('toJson serializes assert_ as "assert" and fromJson restores it', () {
        const step = TestStep(action: TestStepAction.assert_);
        final json = step.toJson();

        expect(json['action'], equals('assert'));

        final restored = TestStep.fromJson(json);
        expect(restored.action, equals(TestStepAction.assert_));
      });

      test('JSON roundtrip for all action types', () {
        for (final action in TestStepAction.values) {
          final step = TestStep(action: action);
          final json = step.toJson();
          final restored = TestStep.fromJson(json);
          expect(restored.action, equals(action),
              reason: 'Roundtrip failed for $action');
        }
      });
    });
  });

  // =========================================================================
  // TestAssertion
  // =========================================================================
  group('TestAssertion', () {
    test('creates with required fields and defaults', () {
      const assertion = TestAssertion(
        type: AssertionType.value,
        target: 'result',
      );

      expect(assertion.type, equals(AssertionType.value));
      expect(assertion.target, equals('result'));
      expect(assertion.expected, isNull);
      expect(assertion.operator, equals(ComparisonOperator.equals));
      expect(assertion.message, isNull);
    });

    test('creates with all fields', () {
      const assertion = TestAssertion(
        type: AssertionType.count,
        target: 'items',
        expected: 10,
        operator: ComparisonOperator.greaterThan,
        message: 'Should have more than 10 items',
      );

      expect(assertion.type, equals(AssertionType.count));
      expect(assertion.target, equals('items'));
      expect(assertion.expected, equals(10));
      expect(assertion.operator, equals(ComparisonOperator.greaterThan));
      expect(assertion.message, equals('Should have more than 10 items'));
    });

    test('fromJson with empty map uses defaults', () {
      final assertion = TestAssertion.fromJson({});

      expect(assertion.type, equals(AssertionType.value));
      expect(assertion.target, equals(''));
      expect(assertion.expected, isNull);
      expect(assertion.operator, equals(ComparisonOperator.equals));
      expect(assertion.message, isNull);
    });

    test('fromJson parses all fields', () {
      final assertion = TestAssertion.fromJson({
        'type': 'contains',
        'target': 'output.text',
        'expected': 'hello',
        'operator': 'contains',
        'message': 'Output should contain hello',
      });

      expect(assertion.type, equals(AssertionType.contains));
      expect(assertion.target, equals('output.text'));
      expect(assertion.expected, equals('hello'));
      expect(assertion.operator, equals(ComparisonOperator.contains));
      expect(assertion.message, equals('Output should contain hello'));
    });

    test('toJson includes type, target, and operator always', () {
      const assertion = TestAssertion(
        type: AssertionType.exists,
        target: '#element',
      );
      final json = assertion.toJson();

      expect(json['type'], equals('exists'));
      expect(json['target'], equals('#element'));
      expect(json['operator'], equals('equals'));
    });

    test('toJson omits null expected', () {
      const assertion = TestAssertion(
        type: AssertionType.exists,
        target: '#el',
      );
      final json = assertion.toJson();

      expect(json.containsKey('expected'), isFalse);
    });

    test('toJson omits null message', () {
      const assertion = TestAssertion(
        type: AssertionType.value,
        target: 'x',
      );
      final json = assertion.toJson();

      expect(json.containsKey('message'), isFalse);
    });

    test('toJson includes expected when present', () {
      const assertion = TestAssertion(
        type: AssertionType.value,
        target: 'count',
        expected: 42,
      );
      final json = assertion.toJson();

      expect(json['expected'], equals(42));
    });

    test('toJson includes message when present', () {
      const assertion = TestAssertion(
        type: AssertionType.value,
        target: 'x',
        message: 'Custom message',
      );
      final json = assertion.toJson();

      expect(json['message'], equals('Custom message'));
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final original = TestAssertion.fromJson({
        'type': 'text',
        'target': 'label.title',
        'expected': 'Welcome',
        'operator': 'equals',
        'message': 'Title should be Welcome',
      });

      final json = original.toJson();
      final restored = TestAssertion.fromJson(json);

      expect(restored.type, equals(original.type));
      expect(restored.target, equals(original.target));
      expect(restored.expected, equals(original.expected));
      expect(restored.operator, equals(original.operator));
      expect(restored.message, equals(original.message));
    });
  });

  // =========================================================================
  // AssertionType
  // =========================================================================
  group('AssertionType', () {
    test('fromString parses value', () {
      expect(AssertionType.fromString('value'), equals(AssertionType.value));
    });

    test('fromString parses exists', () {
      expect(AssertionType.fromString('exists'), equals(AssertionType.exists));
    });

    test('fromString parses visible', () {
      expect(
          AssertionType.fromString('visible'), equals(AssertionType.visible));
    });

    test('fromString parses enabled', () {
      expect(
          AssertionType.fromString('enabled'), equals(AssertionType.enabled));
    });

    test('fromString parses text', () {
      expect(AssertionType.fromString('text'), equals(AssertionType.text));
    });

    test('fromString parses contains', () {
      expect(
          AssertionType.fromString('contains'), equals(AssertionType.contains));
    });

    test('fromString parses count', () {
      expect(AssertionType.fromString('count'), equals(AssertionType.count));
    });

    test('fromString parses state', () {
      expect(AssertionType.fromString('state'), equals(AssertionType.state));
    });

    test('fromString returns unknown for unrecognized value', () {
      expect(AssertionType.fromString('invalid'), equals(AssertionType.unknown));
    });

    test('fromString returns unknown for empty string', () {
      expect(AssertionType.fromString(''), equals(AssertionType.unknown));
    });
  });

  // =========================================================================
  // ComparisonOperator
  // =========================================================================
  group('ComparisonOperator', () {
    test('fromString parses equals', () {
      expect(ComparisonOperator.fromString('equals'),
          equals(ComparisonOperator.equals));
    });

    test('fromString parses notEquals', () {
      expect(ComparisonOperator.fromString('notEquals'),
          equals(ComparisonOperator.notEquals));
    });

    test('fromString parses greaterThan', () {
      expect(ComparisonOperator.fromString('greaterThan'),
          equals(ComparisonOperator.greaterThan));
    });

    test('fromString parses lessThan', () {
      expect(ComparisonOperator.fromString('lessThan'),
          equals(ComparisonOperator.lessThan));
    });

    test('fromString parses greaterOrEqual', () {
      expect(ComparisonOperator.fromString('greaterOrEqual'),
          equals(ComparisonOperator.greaterOrEqual));
    });

    test('fromString parses lessOrEqual', () {
      expect(ComparisonOperator.fromString('lessOrEqual'),
          equals(ComparisonOperator.lessOrEqual));
    });

    test('fromString parses contains', () {
      expect(ComparisonOperator.fromString('contains'),
          equals(ComparisonOperator.contains));
    });

    test('fromString parses matches', () {
      expect(ComparisonOperator.fromString('matches'),
          equals(ComparisonOperator.matches));
    });

    test('fromString returns unknown for unrecognized value', () {
      expect(ComparisonOperator.fromString('nope'),
          equals(ComparisonOperator.unknown));
    });

    test('fromString returns unknown for empty string', () {
      expect(
          ComparisonOperator.fromString(''), equals(ComparisonOperator.unknown));
    });
  });

  // =========================================================================
  // ExpectedResult
  // =========================================================================
  group('ExpectedResult', () {
    test('creates with required type only', () {
      const result = ExpectedResult(type: ResultType.success);

      expect(result.type, equals(ResultType.success));
      expect(result.value, isNull);
      expect(result.error, isNull);
      expect(result.matchers, isNull);
    });

    test('creates with value', () {
      const result = ExpectedResult(
        type: ResultType.success,
        value: {'status': 200, 'body': 'OK'},
      );

      expect(result.value, equals({'status': 200, 'body': 'OK'}));
    });

    test('creates with error', () {
      const result = ExpectedResult(
        type: ResultType.error,
        error: 'Connection timeout',
      );

      expect(result.error, equals('Connection timeout'));
    });

    test('creates with matchers', () {
      const result = ExpectedResult(
        type: ResultType.success,
        matchers: {'status': 'greaterThan(199)', 'body': 'isNotEmpty'},
      );

      expect(result.matchers, isNotNull);
      expect(result.matchers!['status'], equals('greaterThan(199)'));
    });

    test('fromJson with empty map uses defaults', () {
      final result = ExpectedResult.fromJson({});

      expect(result.type, equals(ResultType.success));
      expect(result.value, isNull);
      expect(result.error, isNull);
      expect(result.matchers, isNull);
    });

    test('fromJson parses all fields', () {
      final result = ExpectedResult.fromJson({
        'type': 'failure',
        'value': 'expected failure value',
        'error': 'Something went wrong',
        'matchers': {'code': 'equals(404)'},
      });

      expect(result.type, equals(ResultType.failure));
      expect(result.value, equals('expected failure value'));
      expect(result.error, equals('Something went wrong'));
      expect(result.matchers!['code'], equals('equals(404)'));
    });

    test('toJson includes type always', () {
      const result = ExpectedResult(type: ResultType.timeout);
      final json = result.toJson();

      expect(json['type'], equals('timeout'));
    });

    test('toJson omits null value', () {
      const result = ExpectedResult(type: ResultType.success);
      final json = result.toJson();

      expect(json.containsKey('value'), isFalse);
    });

    test('toJson omits null error', () {
      const result = ExpectedResult(type: ResultType.success);
      final json = result.toJson();

      expect(json.containsKey('error'), isFalse);
    });

    test('toJson omits null matchers', () {
      const result = ExpectedResult(type: ResultType.success);
      final json = result.toJson();

      expect(json.containsKey('matchers'), isFalse);
    });

    test('toJson includes present value', () {
      const result = ExpectedResult(type: ResultType.success, value: 42);
      final json = result.toJson();

      expect(json['value'], equals(42));
    });

    test('toJson includes present error', () {
      const result = ExpectedResult(
        type: ResultType.error,
        error: 'fail',
      );
      final json = result.toJson();

      expect(json['error'], equals('fail'));
    });

    test('toJson includes present matchers', () {
      const result = ExpectedResult(
        type: ResultType.success,
        matchers: {'key': 'matcher'},
      );
      final json = result.toJson();

      expect(json['matchers'], equals({'key': 'matcher'}));
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final original = ExpectedResult.fromJson({
        'type': 'error',
        'value': {'details': 'timeout occurred'},
        'error': 'TimeoutException',
        'matchers': {'duration': 'greaterThan(5000)'},
      });

      final json = original.toJson();
      final restored = ExpectedResult.fromJson(json);

      expect(restored.type, equals(original.type));
      expect(restored.value, equals(original.value));
      expect(restored.error, equals(original.error));
      expect(restored.matchers, equals(original.matchers));
    });
  });

  // =========================================================================
  // ResultType
  // =========================================================================
  group('ResultType', () {
    test('fromString parses success', () {
      expect(ResultType.fromString('success'), equals(ResultType.success));
    });

    test('fromString parses failure', () {
      expect(ResultType.fromString('failure'), equals(ResultType.failure));
    });

    test('fromString parses error', () {
      expect(ResultType.fromString('error'), equals(ResultType.error));
    });

    test('fromString parses timeout', () {
      expect(ResultType.fromString('timeout'), equals(ResultType.timeout));
    });

    test('fromString parses skip', () {
      expect(ResultType.fromString('skip'), equals(ResultType.skip));
    });

    test('fromString returns unknown for unrecognized value', () {
      expect(ResultType.fromString('xyz'), equals(ResultType.unknown));
    });

    test('fromString returns unknown for empty string', () {
      expect(ResultType.fromString(''), equals(ResultType.unknown));
    });
  });

  // =========================================================================
  // TestFixture
  // =========================================================================
  group('TestFixture', () {
    test('creates with required name only', () {
      const fixture = TestFixture(name: 'user-fixture');

      expect(fixture.name, equals('user-fixture'));
      expect(fixture.data, isNull);
      expect(fixture.factory, isNull);
    });

    test('creates with data', () {
      const fixture = TestFixture(
        name: 'user-fixture',
        data: {'username': 'admin', 'role': 'superuser'},
      );

      expect(fixture.data, equals({'username': 'admin', 'role': 'superuser'}));
    });

    test('creates with factory', () {
      const fixture = TestFixture(
        name: 'user-fixture',
        factory: 'createTestUser()',
      );

      expect(fixture.factory, equals('createTestUser()'));
    });

    test('creates with both data and factory', () {
      const fixture = TestFixture(
        name: 'complex-fixture',
        data: {'seed': 42},
        factory: 'buildFromSeed(seed)',
      );

      expect(fixture.data, equals({'seed': 42}));
      expect(fixture.factory, equals('buildFromSeed(seed)'));
    });

    test('fromJson with empty map uses defaults', () {
      final fixture = TestFixture.fromJson({});

      expect(fixture.name, equals(''));
      expect(fixture.data, isNull);
      expect(fixture.factory, isNull);
    });

    test('fromJson parses all fields', () {
      final fixture = TestFixture.fromJson({
        'name': 'product-fixture',
        'data': [
          {'id': 1, 'name': 'Widget'},
          {'id': 2, 'name': 'Gadget'},
        ],
        'factory': 'createProducts()',
      });

      expect(fixture.name, equals('product-fixture'));
      expect(fixture.data, isList);
      expect((fixture.data as List).length, equals(2));
      expect(fixture.factory, equals('createProducts()'));
    });

    test('toJson includes name always', () {
      const fixture = TestFixture(name: 'fx');
      final json = fixture.toJson();

      expect(json['name'], equals('fx'));
    });

    test('toJson omits null data', () {
      const fixture = TestFixture(name: 'fx');
      final json = fixture.toJson();

      expect(json.containsKey('data'), isFalse);
    });

    test('toJson omits null factory', () {
      const fixture = TestFixture(name: 'fx');
      final json = fixture.toJson();

      expect(json.containsKey('factory'), isFalse);
    });

    test('toJson includes present data', () {
      const fixture = TestFixture(name: 'fx', data: 'simple string data');
      final json = fixture.toJson();

      expect(json['data'], equals('simple string data'));
    });

    test('toJson includes present factory', () {
      const fixture = TestFixture(name: 'fx', factory: 'build()');
      final json = fixture.toJson();

      expect(json['factory'], equals('build()'));
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final original = TestFixture.fromJson({
        'name': 'config-fixture',
        'data': {'host': 'localhost', 'port': 8080},
        'factory': 'createConfig()',
      });

      final json = original.toJson();
      final restored = TestFixture.fromJson(json);

      expect(restored.name, equals(original.name));
      expect(restored.data, equals(original.data));
      expect(restored.factory, equals(original.factory));
    });
  });

  // =========================================================================
  // TestConfig
  // =========================================================================
  group('TestConfig', () {
    test('creates with default values', () {
      const config = TestConfig();

      expect(config.defaultTimeoutMs, equals(30000));
      expect(config.parallel, isFalse);
      expect(config.maxParallel, isNull);
      expect(config.retryCount, equals(0));
      expect(config.coverage, isNull);
      expect(config.reporter, isNull);
    });

    test('creates with custom values', () {
      const config = TestConfig(
        defaultTimeoutMs: 60000,
        parallel: true,
        maxParallel: 4,
        retryCount: 3,
      );

      expect(config.defaultTimeoutMs, equals(60000));
      expect(config.parallel, isTrue);
      expect(config.maxParallel, equals(4));
      expect(config.retryCount, equals(3));
    });

    test('creates with coverage', () {
      const config = TestConfig(
        coverage: CoverageConfig(enabled: true, threshold: 80.0),
      );

      expect(config.coverage, isNotNull);
      expect(config.coverage!.enabled, isTrue);
      expect(config.coverage!.threshold, equals(80.0));
    });

    test('creates with reporter', () {
      const config = TestConfig(
        reporter: ReporterConfig(
          type: ReporterType.junit,
          outputPath: 'reports/test-results.xml',
        ),
      );

      expect(config.reporter, isNotNull);
      expect(config.reporter!.type, equals(ReporterType.junit));
    });

    test('fromJson with empty map uses defaults', () {
      final config = TestConfig.fromJson({});

      expect(config.defaultTimeoutMs, equals(30000));
      expect(config.parallel, isFalse);
      expect(config.maxParallel, isNull);
      expect(config.retryCount, equals(0));
      expect(config.coverage, isNull);
      expect(config.reporter, isNull);
    });

    test('fromJson parses all fields', () {
      final config = TestConfig.fromJson({
        'defaultTimeoutMs': 10000,
        'parallel': true,
        'maxParallel': 8,
        'retryCount': 2,
        'coverage': {'enabled': true, 'threshold': 90.0},
        'reporter': {'type': 'html', 'outputPath': 'coverage/index.html'},
      });

      expect(config.defaultTimeoutMs, equals(10000));
      expect(config.parallel, isTrue);
      expect(config.maxParallel, equals(8));
      expect(config.retryCount, equals(2));
      expect(config.coverage!.enabled, isTrue);
      expect(config.coverage!.threshold, equals(90.0));
      expect(config.reporter!.type, equals(ReporterType.html));
      expect(config.reporter!.outputPath, equals('coverage/index.html'));
    });

    test('toJson includes defaultTimeoutMs always', () {
      const config = TestConfig();
      final json = config.toJson();

      expect(json['defaultTimeoutMs'], equals(30000));
    });

    test('toJson omits parallel when false', () {
      const config = TestConfig();
      final json = config.toJson();

      expect(json.containsKey('parallel'), isFalse);
    });

    test('toJson includes parallel when true', () {
      const config = TestConfig(parallel: true);
      final json = config.toJson();

      expect(json['parallel'], isTrue);
    });

    test('toJson omits null maxParallel', () {
      const config = TestConfig();
      final json = config.toJson();

      expect(json.containsKey('maxParallel'), isFalse);
    });

    test('toJson includes non-null maxParallel', () {
      const config = TestConfig(maxParallel: 4);
      final json = config.toJson();

      expect(json['maxParallel'], equals(4));
    });

    test('toJson omits retryCount when zero', () {
      const config = TestConfig();
      final json = config.toJson();

      expect(json.containsKey('retryCount'), isFalse);
    });

    test('toJson includes retryCount when greater than zero', () {
      const config = TestConfig(retryCount: 2);
      final json = config.toJson();

      expect(json['retryCount'], equals(2));
    });

    test('toJson omits null coverage', () {
      const config = TestConfig();
      final json = config.toJson();

      expect(json.containsKey('coverage'), isFalse);
    });

    test('toJson omits null reporter', () {
      const config = TestConfig();
      final json = config.toJson();

      expect(json.containsKey('reporter'), isFalse);
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final original = TestConfig.fromJson({
        'defaultTimeoutMs': 15000,
        'parallel': true,
        'maxParallel': 6,
        'retryCount': 1,
        'coverage': {
          'enabled': true,
          'include': ['lib/**'],
          'threshold': 85.0,
        },
        'reporter': {
          'type': 'json',
          'outputPath': 'reports/results.json',
          'options': {'verbose': true},
        },
      });

      final json = original.toJson();
      final restored = TestConfig.fromJson(json);

      expect(restored.defaultTimeoutMs, equals(original.defaultTimeoutMs));
      expect(restored.parallel, equals(original.parallel));
      expect(restored.maxParallel, equals(original.maxParallel));
      expect(restored.retryCount, equals(original.retryCount));
      expect(restored.coverage!.enabled, isTrue);
      expect(restored.reporter!.type, equals(ReporterType.json));
    });
  });

  // =========================================================================
  // CoverageConfig
  // =========================================================================
  group('CoverageConfig', () {
    test('creates with default values', () {
      const config = CoverageConfig();

      expect(config.enabled, isFalse);
      expect(config.include, isEmpty);
      expect(config.exclude, isEmpty);
      expect(config.threshold, isNull);
    });

    test('creates with all fields', () {
      const config = CoverageConfig(
        enabled: true,
        include: ['lib/**', 'src/**'],
        exclude: ['**/*.g.dart', '**/*_test.dart'],
        threshold: 80.0,
      );

      expect(config.enabled, isTrue);
      expect(config.include, equals(['lib/**', 'src/**']));
      expect(config.exclude, equals(['**/*.g.dart', '**/*_test.dart']));
      expect(config.threshold, equals(80.0));
    });

    test('fromJson with empty map uses defaults', () {
      final config = CoverageConfig.fromJson({});

      expect(config.enabled, isFalse);
      expect(config.include, isEmpty);
      expect(config.exclude, isEmpty);
      expect(config.threshold, isNull);
    });

    test('fromJson parses all fields', () {
      final config = CoverageConfig.fromJson({
        'enabled': true,
        'include': ['lib/**'],
        'exclude': ['test/**'],
        'threshold': 95.5,
      });

      expect(config.enabled, isTrue);
      expect(config.include, equals(['lib/**']));
      expect(config.exclude, equals(['test/**']));
      expect(config.threshold, equals(95.5));
    });

    test('fromJson parses threshold from int', () {
      final config = CoverageConfig.fromJson({
        'threshold': 80,
      });

      expect(config.threshold, equals(80.0));
      expect(config.threshold, isA<double>());
    });

    test('toJson includes enabled always', () {
      const config = CoverageConfig();
      final json = config.toJson();

      expect(json['enabled'], isFalse);
    });

    test('toJson omits empty include', () {
      const config = CoverageConfig();
      final json = config.toJson();

      expect(json.containsKey('include'), isFalse);
    });

    test('toJson omits empty exclude', () {
      const config = CoverageConfig();
      final json = config.toJson();

      expect(json.containsKey('exclude'), isFalse);
    });

    test('toJson omits null threshold', () {
      const config = CoverageConfig();
      final json = config.toJson();

      expect(json.containsKey('threshold'), isFalse);
    });

    test('toJson includes non-empty include', () {
      const config = CoverageConfig(include: ['lib/**']);
      final json = config.toJson();

      expect(json['include'], equals(['lib/**']));
    });

    test('toJson includes non-empty exclude', () {
      const config = CoverageConfig(exclude: ['test/**']);
      final json = config.toJson();

      expect(json['exclude'], equals(['test/**']));
    });

    test('toJson includes non-null threshold', () {
      const config = CoverageConfig(threshold: 75.0);
      final json = config.toJson();

      expect(json['threshold'], equals(75.0));
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final original = CoverageConfig.fromJson({
        'enabled': true,
        'include': ['lib/**', 'bin/**'],
        'exclude': ['**/*.g.dart'],
        'threshold': 88.5,
      });

      final json = original.toJson();
      final restored = CoverageConfig.fromJson(json);

      expect(restored.enabled, equals(original.enabled));
      expect(restored.include, equals(original.include));
      expect(restored.exclude, equals(original.exclude));
      expect(restored.threshold, equals(original.threshold));
    });
  });

  // =========================================================================
  // ReporterConfig
  // =========================================================================
  group('ReporterConfig', () {
    test('creates with default values', () {
      const config = ReporterConfig();

      expect(config.type, equals(ReporterType.console));
      expect(config.outputPath, isNull);
      expect(config.options, isEmpty);
    });

    test('creates with all fields', () {
      const config = ReporterConfig(
        type: ReporterType.junit,
        outputPath: 'reports/junit.xml',
        options: {'suiteName': 'MyApp Tests'},
      );

      expect(config.type, equals(ReporterType.junit));
      expect(config.outputPath, equals('reports/junit.xml'));
      expect(config.options['suiteName'], equals('MyApp Tests'));
    });

    test('fromJson with empty map uses defaults', () {
      final config = ReporterConfig.fromJson({});

      expect(config.type, equals(ReporterType.console));
      expect(config.outputPath, isNull);
      expect(config.options, isEmpty);
    });

    test('fromJson parses all fields', () {
      final config = ReporterConfig.fromJson({
        'type': 'html',
        'outputPath': 'coverage/report.html',
        'options': {'theme': 'dark', 'showPassing': true},
      });

      expect(config.type, equals(ReporterType.html));
      expect(config.outputPath, equals('coverage/report.html'));
      expect(config.options['theme'], equals('dark'));
      expect(config.options['showPassing'], isTrue);
    });

    test('toJson includes type always', () {
      const config = ReporterConfig();
      final json = config.toJson();

      expect(json['type'], equals('console'));
    });

    test('toJson omits null outputPath', () {
      const config = ReporterConfig();
      final json = config.toJson();

      expect(json.containsKey('outputPath'), isFalse);
    });

    test('toJson omits empty options', () {
      const config = ReporterConfig();
      final json = config.toJson();

      expect(json.containsKey('options'), isFalse);
    });

    test('toJson includes non-null outputPath', () {
      const config = ReporterConfig(outputPath: 'out.xml');
      final json = config.toJson();

      expect(json['outputPath'], equals('out.xml'));
    });

    test('toJson includes non-empty options', () {
      const config = ReporterConfig(options: {'verbose': true});
      final json = config.toJson();

      expect(json['options'], equals({'verbose': true}));
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final original = ReporterConfig.fromJson({
        'type': 'custom',
        'outputPath': 'custom/output.dat',
        'options': {'format': 'binary', 'compress': true},
      });

      final json = original.toJson();
      final restored = ReporterConfig.fromJson(json);

      expect(restored.type, equals(original.type));
      expect(restored.outputPath, equals(original.outputPath));
      expect(restored.options, equals(original.options));
    });
  });

  // =========================================================================
  // ReporterType
  // =========================================================================
  group('ReporterType', () {
    test('fromString parses console', () {
      expect(
          ReporterType.fromString('console'), equals(ReporterType.console));
    });

    test('fromString parses json', () {
      expect(ReporterType.fromString('json'), equals(ReporterType.json));
    });

    test('fromString parses junit', () {
      expect(ReporterType.fromString('junit'), equals(ReporterType.junit));
    });

    test('fromString parses html', () {
      expect(ReporterType.fromString('html'), equals(ReporterType.html));
    });

    test('fromString parses custom', () {
      expect(ReporterType.fromString('custom'), equals(ReporterType.custom));
    });

    test('fromString returns unknown for unrecognized value', () {
      expect(ReporterType.fromString('pdf'), equals(ReporterType.unknown));
    });

    test('fromString returns unknown for empty string', () {
      expect(ReporterType.fromString(''), equals(ReporterType.unknown));
    });
  });
}
