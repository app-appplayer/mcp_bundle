import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  // =========================================================================
  // PolicySection
  // =========================================================================
  group('PolicySection', () {
    group('fromJson / toJson', () {
      test('creates from JSON with policies list', () {
        final json = {
          'policies': <dynamic>[
            {
              'id': 'p1',
              'name': 'Policy One',
              'rules': <dynamic>[],
            },
            {
              'id': 'p2',
              'name': 'Policy Two',
              'rules': <dynamic>[],
            },
          ],
        };

        final section = PolicySection.fromJson(json);
        expect(section.policies.length, equals(2));
        expect(section.policies[0].id, equals('p1'));
        expect(section.policies[1].id, equals('p2'));
      });

      test('creates from empty JSON with empty policies', () {
        final section = PolicySection.fromJson({});
        expect(section.policies, isEmpty);
      });

      test('creates from JSON with null policies', () {
        final section = PolicySection.fromJson({'policies': null});
        expect(section.policies, isEmpty);
      });

      test('toJson omits policies key when list is empty', () {
        const section = PolicySection();
        final json = section.toJson();
        expect(json.containsKey('policies'), isFalse);
      });

      test('toJson includes policies when list is not empty', () {
        const section = PolicySection(
          policies: [
            Policy(id: 'p1', name: 'Test', rules: []),
          ],
        );
        final json = section.toJson();
        expect(json.containsKey('policies'), isTrue);
        expect((json['policies'] as List<dynamic>).length, equals(1));
      });

      test('roundtrip fromJson/toJson preserves data', () {
        const original = PolicySection(
          policies: [
            Policy(
              id: 'roundtrip-1',
              name: 'Roundtrip Policy',
              description: 'Test roundtrip',
              rules: [
                PolicyRule(
                  id: 'r1',
                  condition: AlwaysCondition(),
                  action: PolicyAction.allow,
                  message: 'Always allow',
                ),
              ],
              priority: 80,
              enabled: true,
              tags: ['test'],
            ),
          ],
        );

        final json = original.toJson();
        final restored = PolicySection.fromJson(json);
        expect(restored.policies.length, equals(1));
        expect(restored.policies[0].id, equals('roundtrip-1'));
        expect(restored.policies[0].description, equals('Test roundtrip'));
        expect(restored.policies[0].priority, equals(80));
      });
    });

    group('findById', () {
      test('finds existing policy by ID', () {
        const section = PolicySection(
          policies: [
            Policy(id: 'alpha', name: 'Alpha', rules: []),
            Policy(id: 'beta', name: 'Beta', rules: []),
          ],
        );

        final result = section.findById('beta');
        expect(result, isNotNull);
        expect(result!.name, equals('Beta'));
      });

      test('returns null for non-existent ID', () {
        const section = PolicySection(
          policies: [
            Policy(id: 'alpha', name: 'Alpha', rules: []),
          ],
        );

        expect(section.findById('gamma'), isNull);
      });

      test('returns null when policies list is empty', () {
        const section = PolicySection();
        expect(section.findById('anything'), isNull);
      });
    });

    group('sortedByPriority', () {
      test('returns policies sorted by priority descending', () {
        const section = PolicySection(
          policies: [
            Policy(id: 'low', name: 'Low', rules: [], priority: 10),
            Policy(id: 'high', name: 'High', rules: [], priority: 90),
            Policy(id: 'mid', name: 'Mid', rules: [], priority: 50),
          ],
        );

        final sorted = section.sortedByPriority;
        expect(sorted[0].id, equals('high'));
        expect(sorted[1].id, equals('mid'));
        expect(sorted[2].id, equals('low'));
      });

      test('does not mutate original list', () {
        const section = PolicySection(
          policies: [
            Policy(id: 'low', name: 'Low', rules: [], priority: 10),
            Policy(id: 'high', name: 'High', rules: [], priority: 90),
          ],
        );

        section.sortedByPriority;
        expect(section.policies[0].id, equals('low'));
      });

      test('returns empty list when no policies', () {
        const section = PolicySection();
        expect(section.sortedByPriority, isEmpty);
      });
    });

    group('copyWith', () {
      test('creates copy with new policies', () {
        const original = PolicySection(
          policies: [Policy(id: 'a', name: 'A', rules: [])],
        );
        final copy = original.copyWith(
          policies: [const Policy(id: 'b', name: 'B', rules: [])],
        );

        expect(copy.policies.length, equals(1));
        expect(copy.policies[0].id, equals('b'));
        expect(original.policies[0].id, equals('a'));
      });

      test('preserves original when no arguments given', () {
        const original = PolicySection(
          policies: [Policy(id: 'x', name: 'X', rules: [])],
        );
        final copy = original.copyWith();
        expect(copy.policies.length, equals(1));
        expect(copy.policies[0].id, equals('x'));
      });
    });

    test('default constructor has empty policies list', () {
      const section = PolicySection();
      expect(section.policies, isEmpty);
    });
  });

  // =========================================================================
  // Policy
  // =========================================================================
  group('Policy', () {
    group('fromJson / toJson', () {
      test('creates from JSON with all fields', () {
        final json = {
          'id': 'policy-1',
          'name': 'Full Policy',
          'description': 'A full policy',
          'rules': <dynamic>[
            {
              'id': 'r1',
              'condition': {'type': 'always'},
              'action': 'allow',
              'message': 'OK',
            }
          ],
          'priority': 75,
          'enabled': false,
          'tags': <dynamic>['security', 'audit'],
        };

        final policy = Policy.fromJson(json);
        expect(policy.id, equals('policy-1'));
        expect(policy.name, equals('Full Policy'));
        expect(policy.description, equals('A full policy'));
        expect(policy.rules.length, equals(1));
        expect(policy.priority, equals(75));
        expect(policy.enabled, isFalse);
        expect(policy.tags, equals(['security', 'audit']));
      });

      test('uses default values for missing optional fields', () {
        final policy = Policy.fromJson({
          'id': 'minimal',
          'name': 'Minimal',
        });

        expect(policy.priority, equals(50));
        expect(policy.enabled, isTrue);
        expect(policy.tags, isEmpty);
        expect(policy.rules, isEmpty);
        expect(policy.description, isNull);
      });

      test('defaults id and name to empty string when null', () {
        final policy = Policy.fromJson({});
        expect(policy.id, equals(''));
        expect(policy.name, equals(''));
      });

      test('toJson includes all required fields', () {
        const policy = Policy(
          id: 'test',
          name: 'Test Policy',
          rules: [],
          priority: 50,
        );

        final json = policy.toJson();
        expect(json['id'], equals('test'));
        expect(json['name'], equals('Test Policy'));
        expect(json['priority'], equals(50));
        expect(json['rules'], isA<List<dynamic>>());
      });

      test('toJson omits description when null', () {
        const policy = Policy(id: 'test', name: 'Test', rules: []);
        final json = policy.toJson();
        expect(json.containsKey('description'), isFalse);
      });

      test('toJson includes description when present', () {
        const policy = Policy(
          id: 'test',
          name: 'Test',
          rules: [],
          description: 'Desc',
        );
        final json = policy.toJson();
        expect(json['description'], equals('Desc'));
      });

      test('toJson omits enabled when true (default)', () {
        const policy = Policy(id: 'test', name: 'Test', rules: []);
        final json = policy.toJson();
        expect(json.containsKey('enabled'), isFalse);
      });

      test('toJson includes enabled when false', () {
        const policy = Policy(
          id: 'test',
          name: 'Test',
          rules: [],
          enabled: false,
        );
        final json = policy.toJson();
        expect(json['enabled'], isFalse);
      });

      test('toJson omits tags when empty', () {
        const policy = Policy(id: 'test', name: 'Test', rules: []);
        final json = policy.toJson();
        expect(json.containsKey('tags'), isFalse);
      });

      test('toJson includes tags when not empty', () {
        const policy = Policy(
          id: 'test',
          name: 'Test',
          rules: [],
          tags: ['a', 'b'],
        );
        final json = policy.toJson();
        expect(json['tags'], equals(['a', 'b']));
      });

      test('roundtrip fromJson/toJson preserves all fields', () {
        const original = Policy(
          id: 'rt',
          name: 'Roundtrip',
          description: 'Round-trip test',
          rules: [
            PolicyRule(
              id: 'rule-1',
              condition: AlwaysCondition(),
              action: PolicyAction.deny,
              message: 'Denied',
              metadata: {'severity': 'high'},
            ),
          ],
          priority: 99,
          enabled: false,
          tags: ['core'],
        );

        final json = original.toJson();
        final restored = Policy.fromJson(json);
        expect(restored.id, equals('rt'));
        expect(restored.name, equals('Roundtrip'));
        expect(restored.description, equals('Round-trip test'));
        expect(restored.rules.length, equals(1));
        expect(restored.rules[0].id, equals('rule-1'));
        expect(restored.priority, equals(99));
        expect(restored.enabled, isFalse);
        expect(restored.tags, equals(['core']));
      });
    });

    group('defaults', () {
      test('priority defaults to 50', () {
        const policy = Policy(id: 'p', name: 'P', rules: []);
        expect(policy.priority, equals(50));
      });

      test('enabled defaults to true', () {
        const policy = Policy(id: 'p', name: 'P', rules: []);
        expect(policy.enabled, isTrue);
      });
    });

    group('copyWith', () {
      test('creates copy with all fields overridden', () {
        const original = Policy(
          id: 'a',
          name: 'A',
          description: 'Original',
          rules: [],
          priority: 10,
          enabled: true,
          tags: ['old'],
        );
        final copy = original.copyWith(
          id: 'b',
          name: 'B',
          description: 'New',
          rules: [
            const PolicyRule(
              id: 'new-rule',
              condition: AlwaysCondition(),
              action: PolicyAction.warn,
            ),
          ],
          priority: 90,
          enabled: false,
          tags: ['new'],
        );

        expect(copy.id, equals('b'));
        expect(copy.name, equals('B'));
        expect(copy.description, equals('New'));
        expect(copy.rules.length, equals(1));
        expect(copy.priority, equals(90));
        expect(copy.enabled, isFalse);
        expect(copy.tags, equals(['new']));
      });

      test('preserves all fields when no arguments given', () {
        const original = Policy(
          id: 'keep',
          name: 'Keep',
          description: 'Kept',
          rules: [],
          priority: 42,
          enabled: false,
          tags: ['preserved'],
        );
        final copy = original.copyWith();

        expect(copy.id, equals('keep'));
        expect(copy.name, equals('Keep'));
        expect(copy.description, equals('Kept'));
        expect(copy.priority, equals(42));
        expect(copy.enabled, isFalse);
        expect(copy.tags, equals(['preserved']));
      });
    });
  });

  // =========================================================================
  // PolicyRule
  // =========================================================================
  group('PolicyRule', () {
    group('fromJson / toJson', () {
      test('creates from JSON with all fields', () {
        final json = {
          'id': 'rule-1',
          'condition': {'type': 'always'},
          'action': 'deny',
          'message': 'Not allowed',
          'metadata': {'severity': 'critical'},
        };

        final rule = PolicyRule.fromJson(json);
        expect(rule.id, equals('rule-1'));
        expect(rule.condition, isA<AlwaysCondition>());
        expect(rule.action, equals(PolicyAction.deny));
        expect(rule.message, equals('Not allowed'));
        expect(rule.metadata, equals({'severity': 'critical'}));
      });

      test('defaults id to empty string when missing', () {
        final rule = PolicyRule.fromJson({
          'condition': {'type': 'always'},
          'action': 'allow',
        });
        expect(rule.id, equals(''));
      });

      test('defaults action to deny when missing', () {
        final rule = PolicyRule.fromJson({
          'id': 'r1',
          'condition': {'type': 'always'},
        });
        expect(rule.action, equals(PolicyAction.deny));
      });

      test('toJson includes all required fields', () {
        const rule = PolicyRule(
          id: 'r1',
          condition: AlwaysCondition(),
          action: PolicyAction.allow,
        );

        final json = rule.toJson();
        expect(json['id'], equals('r1'));
        expect(json['condition'], equals({'type': 'always'}));
        expect(json['action'], equals('allow'));
      });

      test('toJson omits message when null', () {
        const rule = PolicyRule(
          id: 'r1',
          condition: AlwaysCondition(),
          action: PolicyAction.allow,
        );
        expect(rule.toJson().containsKey('message'), isFalse);
      });

      test('toJson omits metadata when null', () {
        const rule = PolicyRule(
          id: 'r1',
          condition: AlwaysCondition(),
          action: PolicyAction.allow,
        );
        expect(rule.toJson().containsKey('metadata'), isFalse);
      });

      test('toJson includes message when present', () {
        const rule = PolicyRule(
          id: 'r1',
          condition: AlwaysCondition(),
          action: PolicyAction.allow,
          message: 'msg',
        );
        expect(rule.toJson()['message'], equals('msg'));
      });

      test('toJson includes metadata when present', () {
        const rule = PolicyRule(
          id: 'r1',
          condition: AlwaysCondition(),
          action: PolicyAction.allow,
          metadata: {'key': 'val'},
        );
        expect(rule.toJson()['metadata'], equals({'key': 'val'}));
      });

      test('roundtrip fromJson/toJson preserves data', () {
        const original = PolicyRule(
          id: 'rule-rt',
          condition: ThresholdCondition(
            metric: 'score',
            operator: ThresholdOperator.gte,
            value: 0.8,
          ),
          action: PolicyAction.warn,
          message: 'Score low',
          metadata: {'category': 'quality'},
        );

        final json = original.toJson();
        final restored = PolicyRule.fromJson(json);
        expect(restored.id, equals('rule-rt'));
        expect(restored.action, equals(PolicyAction.warn));
        expect(restored.message, equals('Score low'));
        expect(restored.metadata, equals({'category': 'quality'}));
      });
    });

    group('copyWith', () {
      test('overrides specified fields', () {
        const original = PolicyRule(
          id: 'r1',
          condition: AlwaysCondition(),
          action: PolicyAction.allow,
          message: 'original',
        );
        final copy = original.copyWith(
          id: 'r2',
          action: PolicyAction.deny,
          message: 'updated',
        );

        expect(copy.id, equals('r2'));
        expect(copy.action, equals(PolicyAction.deny));
        expect(copy.message, equals('updated'));
        expect(copy.condition, isA<AlwaysCondition>());
      });

      test('preserves all fields when no arguments given', () {
        const original = PolicyRule(
          id: 'keep',
          condition: AlwaysCondition(),
          action: PolicyAction.log,
          message: 'kept',
          metadata: {'a': 1},
        );
        final copy = original.copyWith();

        expect(copy.id, equals('keep'));
        expect(copy.action, equals(PolicyAction.log));
        expect(copy.message, equals('kept'));
        expect(copy.metadata, equals({'a': 1}));
      });
    });
  });

  // =========================================================================
  // PolicyAction.fromString
  // =========================================================================
  group('PolicyAction', () {
    group('fromString', () {
      test('parses "allow"', () {
        expect(PolicyAction.fromString('allow'), equals(PolicyAction.allow));
      });

      test('parses "deny"', () {
        expect(PolicyAction.fromString('deny'), equals(PolicyAction.deny));
      });

      test('parses "warn"', () {
        expect(PolicyAction.fromString('warn'), equals(PolicyAction.warn));
      });

      test('parses "require_approval"', () {
        expect(
          PolicyAction.fromString('require_approval'),
          equals(PolicyAction.requireApproval),
        );
      });

      test('parses "requireapproval" (no underscore)', () {
        expect(
          PolicyAction.fromString('requireapproval'),
          equals(PolicyAction.requireApproval),
        );
      });

      test('parses "log"', () {
        expect(PolicyAction.fromString('log'), equals(PolicyAction.log));
      });

      test('returns unknown for unrecognized value', () {
        expect(
          PolicyAction.fromString('something_else'),
          equals(PolicyAction.unknown),
        );
      });

      test('is case-insensitive', () {
        expect(PolicyAction.fromString('ALLOW'), equals(PolicyAction.allow));
        expect(PolicyAction.fromString('Deny'), equals(PolicyAction.deny));
        expect(PolicyAction.fromString('WARN'), equals(PolicyAction.warn));
      });
    });
  });

  // =========================================================================
  // PolicyCondition.fromJson factory
  // =========================================================================
  group('PolicyCondition.fromJson factory', () {
    test('dispatches to ThresholdCondition for type "threshold"', () {
      final condition = PolicyCondition.fromJson({
        'type': 'threshold',
        'metric': 'score',
        'operator': '>=',
        'value': 0.5,
      });
      expect(condition, isA<ThresholdCondition>());
    });

    test('dispatches to CompositeCondition for type "composite"', () {
      final condition = PolicyCondition.fromJson({
        'type': 'composite',
        'operator': 'and',
        'conditions': <dynamic>[],
      });
      expect(condition, isA<CompositeCondition>());
    });

    test('dispatches to ExpressionCondition for type "expression"', () {
      final condition = PolicyCondition.fromJson({
        'type': 'expression',
        'expression': 'x > 1',
      });
      expect(condition, isA<ExpressionCondition>());
    });

    test('dispatches to AlwaysCondition for type "always"', () {
      final condition = PolicyCondition.fromJson({'type': 'always'});
      expect(condition, isA<AlwaysCondition>());
    });

    test('dispatches to MetricCondition for type "metric"', () {
      final condition = PolicyCondition.fromJson({
        'type': 'metric',
        'metric': 'accuracy',
        'exists': true,
      });
      expect(condition, isA<MetricCondition>());
    });

    test('defaults to ExpressionCondition when expression field present', () {
      final condition = PolicyCondition.fromJson({
        'expression': 'a + b',
      });
      expect(condition, isA<ExpressionCondition>());
      expect(
        (condition as ExpressionCondition).expression,
        equals('a + b'),
      );
    });

    test('defaults to ExpressionCondition with toString when no type and no expression', () {
      final json = {'some': 'data'};
      final condition = PolicyCondition.fromJson(json);
      expect(condition, isA<ExpressionCondition>());
      expect(
        (condition as ExpressionCondition).expression,
        equals(json.toString()),
      );
    });
  });

  // =========================================================================
  // ThresholdCondition
  // =========================================================================
  group('ThresholdCondition', () {
    group('evaluate', () {
      test('gt: returns true when context value > threshold', () {
        const cond = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.gt,
          value: 10,
        );
        expect(cond.evaluate({'score': 11}), isTrue);
      });

      test('gt: returns false when context value == threshold', () {
        const cond = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.gt,
          value: 10,
        );
        expect(cond.evaluate({'score': 10}), isFalse);
      });

      test('gt: returns false when context value < threshold', () {
        const cond = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.gt,
          value: 10,
        );
        expect(cond.evaluate({'score': 9}), isFalse);
      });

      test('gte: returns true when context value >= threshold', () {
        const cond = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.gte,
          value: 10,
        );
        expect(cond.evaluate({'score': 10}), isTrue);
        expect(cond.evaluate({'score': 11}), isTrue);
      });

      test('gte: returns false when context value < threshold', () {
        const cond = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.gte,
          value: 10,
        );
        expect(cond.evaluate({'score': 9}), isFalse);
      });

      test('lt: returns true when context value < threshold', () {
        const cond = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.lt,
          value: 10,
        );
        expect(cond.evaluate({'score': 9}), isTrue);
      });

      test('lt: returns false when context value >= threshold', () {
        const cond = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.lt,
          value: 10,
        );
        expect(cond.evaluate({'score': 10}), isFalse);
        expect(cond.evaluate({'score': 11}), isFalse);
      });

      test('lte: returns true when context value <= threshold', () {
        const cond = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.lte,
          value: 10,
        );
        expect(cond.evaluate({'score': 10}), isTrue);
        expect(cond.evaluate({'score': 9}), isTrue);
      });

      test('lte: returns false when context value > threshold', () {
        const cond = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.lte,
          value: 10,
        );
        expect(cond.evaluate({'score': 11}), isFalse);
      });

      test('eq: returns true when context value == threshold', () {
        const cond = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.eq,
          value: 42,
        );
        expect(cond.evaluate({'score': 42}), isTrue);
      });

      test('eq: returns false when context value != threshold', () {
        const cond = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.eq,
          value: 42,
        );
        expect(cond.evaluate({'score': 41}), isFalse);
      });

      test('ne: returns true when context value != threshold', () {
        const cond = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.ne,
          value: 42,
        );
        expect(cond.evaluate({'score': 41}), isTrue);
      });

      test('ne: returns false when context value == threshold', () {
        const cond = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.ne,
          value: 42,
        );
        expect(cond.evaluate({'score': 42}), isFalse);
      });

      test('between: returns true when value is within [min, max]', () {
        const cond = ThresholdCondition(
          metric: 'temp',
          operator: ThresholdOperator.between,
          value: [20, 30],
        );
        expect(cond.evaluate({'temp': 25}), isTrue);
      });

      test('between: returns true on boundary values', () {
        const cond = ThresholdCondition(
          metric: 'temp',
          operator: ThresholdOperator.between,
          value: [20, 30],
        );
        expect(cond.evaluate({'temp': 20}), isTrue);
        expect(cond.evaluate({'temp': 30}), isTrue);
      });

      test('between: returns false when value is outside [min, max]', () {
        const cond = ThresholdCondition(
          metric: 'temp',
          operator: ThresholdOperator.between,
          value: [20, 30],
        );
        expect(cond.evaluate({'temp': 19}), isFalse);
        expect(cond.evaluate({'temp': 31}), isFalse);
      });

      test('between: returns false when value is not a list', () {
        const cond = ThresholdCondition(
          metric: 'temp',
          operator: ThresholdOperator.between,
          value: 25,
        );
        expect(cond.evaluate({'temp': 25}), isFalse);
      });

      test('returns false when context value is not a num', () {
        const cond = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.gt,
          value: 10,
        );
        expect(cond.evaluate({'score': 'not a number'}), isFalse);
      });

      test('returns false when context key is missing (null)', () {
        const cond = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.gt,
          value: 10,
        );
        expect(cond.evaluate({}), isFalse);
      });

      test('works with double values', () {
        const cond = ThresholdCondition(
          metric: 'accuracy',
          operator: ThresholdOperator.gte,
          value: 0.95,
        );
        expect(cond.evaluate({'accuracy': 0.96}), isTrue);
        expect(cond.evaluate({'accuracy': 0.94}), isFalse);
      });
    });

    group('fromJson / toJson', () {
      test('roundtrip preserves all fields', () {
        const original = ThresholdCondition(
          metric: 'latency',
          operator: ThresholdOperator.lt,
          value: 100,
        );

        final json = original.toJson();
        expect(json['type'], equals('threshold'));
        expect(json['metric'], equals('latency'));
        expect(json['operator'], equals('<'));
        expect(json['value'], equals(100));

        final restored = ThresholdCondition.fromJson(json);
        expect(restored.metric, equals('latency'));
        expect(restored.operator, equals(ThresholdOperator.lt));
        expect(restored.value, equals(100));
      });

      test('fromJson defaults metric to empty string', () {
        final cond = ThresholdCondition.fromJson({});
        expect(cond.metric, equals(''));
      });

      test('fromJson defaults operator to gte', () {
        final cond = ThresholdCondition.fromJson({});
        expect(cond.operator, equals(ThresholdOperator.gte));
      });

      test('fromJson defaults value to 0.0', () {
        final cond = ThresholdCondition.fromJson({});
        expect(cond.value, equals(0.0));
      });
    });

    group('copyWith', () {
      test('overrides specified fields', () {
        const original = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.gt,
          value: 50,
        );
        final copy = original.copyWith(
          metric: 'rating',
          operator: ThresholdOperator.lt,
          value: 100,
        );
        expect(copy.metric, equals('rating'));
        expect(copy.operator, equals(ThresholdOperator.lt));
        expect(copy.value, equals(100));
      });

      test('preserves original when no arguments given', () {
        const original = ThresholdCondition(
          metric: 'score',
          operator: ThresholdOperator.eq,
          value: 42,
        );
        final copy = original.copyWith();
        expect(copy.metric, equals('score'));
        expect(copy.operator, equals(ThresholdOperator.eq));
        expect(copy.value, equals(42));
      });
    });
  });

  // =========================================================================
  // CompositeCondition
  // =========================================================================
  group('CompositeCondition', () {
    group('evaluate', () {
      test('AND: returns true when all conditions are true', () {
        const cond = CompositeCondition(
          operator: CompositeOperator.and,
          conditions: [
            AlwaysCondition(),
            AlwaysCondition(),
          ],
        );
        expect(cond.evaluate({}), isTrue);
      });

      test('AND: returns false when one condition is false', () {
        const cond = CompositeCondition(
          operator: CompositeOperator.and,
          conditions: [
            AlwaysCondition(),
            ThresholdCondition(
              metric: 'x',
              operator: ThresholdOperator.gt,
              value: 100,
            ),
          ],
        );
        expect(cond.evaluate({'x': 50}), isFalse);
      });

      test('AND: returns true for empty conditions (vacuous truth)', () {
        const cond = CompositeCondition(
          operator: CompositeOperator.and,
          conditions: [],
        );
        expect(cond.evaluate({}), isTrue);
      });

      test('OR: returns true when at least one condition is true', () {
        const cond = CompositeCondition(
          operator: CompositeOperator.or,
          conditions: [
            ThresholdCondition(
              metric: 'x',
              operator: ThresholdOperator.gt,
              value: 100,
            ),
            AlwaysCondition(),
          ],
        );
        expect(cond.evaluate({'x': 50}), isTrue);
      });

      test('OR: returns false when all conditions are false', () {
        const cond = CompositeCondition(
          operator: CompositeOperator.or,
          conditions: [
            ThresholdCondition(
              metric: 'x',
              operator: ThresholdOperator.gt,
              value: 100,
            ),
            ThresholdCondition(
              metric: 'y',
              operator: ThresholdOperator.gt,
              value: 100,
            ),
          ],
        );
        expect(cond.evaluate({'x': 50, 'y': 50}), isFalse);
      });

      test('OR: returns false for empty conditions', () {
        const cond = CompositeCondition(
          operator: CompositeOperator.or,
          conditions: [],
        );
        expect(cond.evaluate({}), isFalse);
      });

      test('NOT: negates a single true condition', () {
        const cond = CompositeCondition(
          operator: CompositeOperator.not,
          conditions: [AlwaysCondition()],
        );
        expect(cond.evaluate({}), isFalse);
      });

      test('NOT: negates a single false condition', () {
        const cond = CompositeCondition(
          operator: CompositeOperator.not,
          conditions: [
            ThresholdCondition(
              metric: 'x',
              operator: ThresholdOperator.gt,
              value: 100,
            ),
          ],
        );
        expect(cond.evaluate({'x': 50}), isTrue);
      });

      test('NOT: returns true for empty conditions', () {
        const cond = CompositeCondition(
          operator: CompositeOperator.not,
          conditions: [],
        );
        expect(cond.evaluate({}), isTrue);
      });
    });

    group('fromJson / toJson', () {
      test('roundtrip preserves composite structure', () {
        const original = CompositeCondition(
          operator: CompositeOperator.and,
          conditions: [
            AlwaysCondition(),
            ThresholdCondition(
              metric: 'score',
              operator: ThresholdOperator.gte,
              value: 0.5,
            ),
          ],
        );

        final json = original.toJson();
        expect(json['type'], equals('composite'));
        expect(json['operator'], equals('and'));
        expect((json['conditions'] as List<dynamic>).length, equals(2));

        final restored = CompositeCondition.fromJson(json);
        expect(restored.operator, equals(CompositeOperator.and));
        expect(restored.conditions.length, equals(2));
        expect(restored.conditions[0], isA<AlwaysCondition>());
        expect(restored.conditions[1], isA<ThresholdCondition>());
      });

      test('fromJson with empty conditions list', () {
        final cond = CompositeCondition.fromJson({
          'type': 'composite',
          'operator': 'or',
        });
        expect(cond.operator, equals(CompositeOperator.or));
        expect(cond.conditions, isEmpty);
      });

      test('fromJson defaults operator to and', () {
        final cond = CompositeCondition.fromJson({
          'type': 'composite',
        });
        expect(cond.operator, equals(CompositeOperator.and));
      });
    });

    group('copyWith', () {
      test('overrides specified fields', () {
        const original = CompositeCondition(
          operator: CompositeOperator.and,
          conditions: [AlwaysCondition()],
        );
        final copy = original.copyWith(
          operator: CompositeOperator.or,
        );
        expect(copy.operator, equals(CompositeOperator.or));
        expect(copy.conditions.length, equals(1));
      });

      test('preserves original when no arguments given', () {
        const original = CompositeCondition(
          operator: CompositeOperator.not,
          conditions: [AlwaysCondition()],
        );
        final copy = original.copyWith();
        expect(copy.operator, equals(CompositeOperator.not));
        expect(copy.conditions.length, equals(1));
      });
    });
  });

  // =========================================================================
  // CompositeOperator.fromString
  // =========================================================================
  group('CompositeOperator', () {
    group('fromString', () {
      test('parses "and"', () {
        expect(
          CompositeOperator.fromString('and'),
          equals(CompositeOperator.and),
        );
      });

      test('parses "or"', () {
        expect(
          CompositeOperator.fromString('or'),
          equals(CompositeOperator.or),
        );
      });

      test('parses "not"', () {
        expect(
          CompositeOperator.fromString('not'),
          equals(CompositeOperator.not),
        );
      });

      test('returns and for unknown value', () {
        expect(
          CompositeOperator.fromString('xor'),
          equals(CompositeOperator.and),
        );
      });

      test('is case-insensitive', () {
        expect(
          CompositeOperator.fromString('AND'),
          equals(CompositeOperator.and),
        );
        expect(
          CompositeOperator.fromString('Or'),
          equals(CompositeOperator.or),
        );
      });
    });
  });

  // =========================================================================
  // ThresholdOperator.fromString and symbol getter
  // =========================================================================
  group('ThresholdOperator', () {
    group('fromString with symbol strings', () {
      test('parses ">"', () {
        expect(
          ThresholdOperator.fromString('>'),
          equals(ThresholdOperator.gt),
        );
      });

      test('parses ">="', () {
        expect(
          ThresholdOperator.fromString('>='),
          equals(ThresholdOperator.gte),
        );
      });

      test('parses "<"', () {
        expect(
          ThresholdOperator.fromString('<'),
          equals(ThresholdOperator.lt),
        );
      });

      test('parses "<="', () {
        expect(
          ThresholdOperator.fromString('<='),
          equals(ThresholdOperator.lte),
        );
      });

      test('parses "=="', () {
        expect(
          ThresholdOperator.fromString('=='),
          equals(ThresholdOperator.eq),
        );
      });

      test('parses "!="', () {
        expect(
          ThresholdOperator.fromString('!='),
          equals(ThresholdOperator.ne),
        );
      });
    });

    group('fromString with named strings', () {
      test('parses "gt"', () {
        expect(
          ThresholdOperator.fromString('gt'),
          equals(ThresholdOperator.gt),
        );
      });

      test('parses "gte"', () {
        expect(
          ThresholdOperator.fromString('gte'),
          equals(ThresholdOperator.gte),
        );
      });

      test('parses "lt"', () {
        expect(
          ThresholdOperator.fromString('lt'),
          equals(ThresholdOperator.lt),
        );
      });

      test('parses "lte"', () {
        expect(
          ThresholdOperator.fromString('lte'),
          equals(ThresholdOperator.lte),
        );
      });

      test('parses "eq"', () {
        expect(
          ThresholdOperator.fromString('eq'),
          equals(ThresholdOperator.eq),
        );
      });

      test('parses "ne"', () {
        expect(
          ThresholdOperator.fromString('ne'),
          equals(ThresholdOperator.ne),
        );
      });

      test('parses "between"', () {
        expect(
          ThresholdOperator.fromString('between'),
          equals(ThresholdOperator.between),
        );
      });
    });

    group('fromString edge cases', () {
      test('returns gte for unknown value', () {
        expect(
          ThresholdOperator.fromString('unknown_op'),
          equals(ThresholdOperator.gte),
        );
      });

      test('is case-insensitive', () {
        expect(
          ThresholdOperator.fromString('GT'),
          equals(ThresholdOperator.gt),
        );
        expect(
          ThresholdOperator.fromString('BETWEEN'),
          equals(ThresholdOperator.between),
        );
      });
    });

    group('symbol getter', () {
      test('gt symbol is ">"', () {
        expect(ThresholdOperator.gt.symbol, equals('>'));
      });

      test('gte symbol is ">="', () {
        expect(ThresholdOperator.gte.symbol, equals('>='));
      });

      test('lt symbol is "<"', () {
        expect(ThresholdOperator.lt.symbol, equals('<'));
      });

      test('lte symbol is "<="', () {
        expect(ThresholdOperator.lte.symbol, equals('<='));
      });

      test('eq symbol is "=="', () {
        expect(ThresholdOperator.eq.symbol, equals('=='));
      });

      test('ne symbol is "!="', () {
        expect(ThresholdOperator.ne.symbol, equals('!='));
      });

      test('between symbol is "between"', () {
        expect(ThresholdOperator.between.symbol, equals('between'));
      });
    });
  });

  // =========================================================================
  // ExpressionCondition
  // =========================================================================
  group('ExpressionCondition', () {
    group('fromJson / toJson', () {
      test('creates from JSON with expression', () {
        final cond = ExpressionCondition.fromJson({
          'type': 'expression',
          'expression': 'x > 10',
        });
        expect(cond.expression, equals('x > 10'));
      });

      test('defaults expression to "true" when missing', () {
        final cond = ExpressionCondition.fromJson({});
        expect(cond.expression, equals('true'));
      });

      test('toJson includes type and expression', () {
        const cond = ExpressionCondition(expression: 'a + b');
        final json = cond.toJson();
        expect(json['type'], equals('expression'));
        expect(json['expression'], equals('a + b'));
      });

      test('roundtrip preserves expression', () {
        const original = ExpressionCondition(expression: 'foo.bar > 0');
        final restored = ExpressionCondition.fromJson(original.toJson());
        expect(restored.expression, equals('foo.bar > 0'));
      });
    });

    test('evaluate returns false (placeholder)', () {
      const cond = ExpressionCondition(expression: 'anything');
      expect(cond.evaluate({}), isFalse);
      expect(cond.evaluate({'key': 'value'}), isFalse);
    });

    group('copyWith', () {
      test('overrides expression', () {
        const original = ExpressionCondition(expression: 'old');
        final copy = original.copyWith(expression: 'new');
        expect(copy.expression, equals('new'));
      });

      test('preserves expression when no argument given', () {
        const original = ExpressionCondition(expression: 'keep');
        final copy = original.copyWith();
        expect(copy.expression, equals('keep'));
      });
    });
  });

  // =========================================================================
  // AlwaysCondition
  // =========================================================================
  group('AlwaysCondition', () {
    test('toJson returns type "always"', () {
      const cond = AlwaysCondition();
      expect(cond.toJson(), equals({'type': 'always'}));
    });

    test('evaluate always returns true', () {
      const cond = AlwaysCondition();
      expect(cond.evaluate({}), isTrue);
      expect(cond.evaluate({'any': 'context'}), isTrue);
    });

    test('roundtrip through PolicyCondition.fromJson', () {
      const original = AlwaysCondition();
      final json = original.toJson();
      final restored = PolicyCondition.fromJson(json);
      expect(restored, isA<AlwaysCondition>());
      expect(restored.evaluate({}), isTrue);
    });
  });

  // =========================================================================
  // MetricCondition
  // =========================================================================
  group('MetricCondition', () {
    group('evaluate', () {
      test('exists=true: returns true when value is present', () {
        const cond = MetricCondition(metric: 'score', exists: true);
        expect(cond.evaluate({'score': 42}), isTrue);
      });

      test('exists=true: returns false when value is absent', () {
        const cond = MetricCondition(metric: 'score', exists: true);
        expect(cond.evaluate({}), isFalse);
      });

      test('exists=false: returns false when value is absent', () {
        // When exists=false, evaluate checks isPresent != exists (false != false = false),
        // then falls through to: exists == null || (exists! && value != null) = false || (false && false) = false
        const cond = MetricCondition(metric: 'score', exists: false);
        expect(cond.evaluate({}), isFalse);
      });

      test('exists=false: returns false when value is present', () {
        const cond = MetricCondition(metric: 'score', exists: false);
        expect(cond.evaluate({'score': 42}), isFalse);
      });

      test('confidence threshold: returns true when value >= confidence', () {
        const cond = MetricCondition(
          metric: 'accuracy',
          exists: true,
          confidence: 0.8,
        );
        expect(cond.evaluate({'accuracy': 0.9}), isTrue);
      });

      test('confidence threshold: returns true when value == confidence', () {
        const cond = MetricCondition(
          metric: 'accuracy',
          exists: true,
          confidence: 0.8,
        );
        expect(cond.evaluate({'accuracy': 0.8}), isTrue);
      });

      test('confidence threshold: returns false when value < confidence', () {
        const cond = MetricCondition(
          metric: 'accuracy',
          exists: true,
          confidence: 0.8,
        );
        expect(cond.evaluate({'accuracy': 0.7}), isFalse);
      });

      test('exists=null and value!=null: returns true', () {
        const cond = MetricCondition(metric: 'score');
        expect(cond.evaluate({'score': 42}), isTrue);
      });

      test('exists=null and value==null: returns true (exists==null branch)', () {
        const cond = MetricCondition(metric: 'score');
        // exists is null, so the exists check is skipped.
        // confidence is null, so that check is skipped.
        // Falls to: return exists == null || (exists! && value != null)
        // exists == null is true, so returns true
        expect(cond.evaluate({}), isTrue);
      });

      test('exists=true with confidence and non-num value', () {
        // exists=true, value is string (present but not num)
        // exists check: isPresent(true) == exists(true) => passes
        // confidence check: value is not num => skip
        // falls to: exists == null => false, exists! && value != null => true
        const cond = MetricCondition(
          metric: 'tag',
          exists: true,
          confidence: 0.5,
        );
        expect(cond.evaluate({'tag': 'hello'}), isTrue);
      });
    });

    group('fromJson / toJson', () {
      test('roundtrip preserves all fields', () {
        const original = MetricCondition(
          metric: 'precision',
          exists: true,
          confidence: 0.9,
        );

        final json = original.toJson();
        expect(json['type'], equals('metric'));
        expect(json['metric'], equals('precision'));
        expect(json['exists'], isTrue);
        expect(json['confidence'], equals(0.9));

        final restored = MetricCondition.fromJson(json);
        expect(restored.metric, equals('precision'));
        expect(restored.exists, isTrue);
        expect(restored.confidence, equals(0.9));
      });

      test('toJson omits exists when null', () {
        const cond = MetricCondition(metric: 'score');
        final json = cond.toJson();
        expect(json.containsKey('exists'), isFalse);
      });

      test('toJson omits confidence when null', () {
        const cond = MetricCondition(metric: 'score', exists: true);
        final json = cond.toJson();
        expect(json.containsKey('confidence'), isFalse);
      });

      test('fromJson defaults metric to empty string', () {
        final cond = MetricCondition.fromJson({});
        expect(cond.metric, equals(''));
      });

      test('fromJson with integer confidence converts to double', () {
        final cond = MetricCondition.fromJson({
          'type': 'metric',
          'metric': 'score',
          'confidence': 1,
        });
        expect(cond.confidence, equals(1.0));
        expect(cond.confidence, isA<double>());
      });
    });

    group('copyWith', () {
      test('overrides specified fields', () {
        const original = MetricCondition(
          metric: 'score',
          exists: true,
          confidence: 0.5,
        );
        final copy = original.copyWith(
          metric: 'rating',
          exists: false,
          confidence: 0.9,
        );
        expect(copy.metric, equals('rating'));
        expect(copy.exists, isFalse);
        expect(copy.confidence, equals(0.9));
      });

      test('preserves original when no arguments given', () {
        const original = MetricCondition(
          metric: 'x',
          exists: true,
          confidence: 0.7,
        );
        final copy = original.copyWith();
        expect(copy.metric, equals('x'));
        expect(copy.exists, isTrue);
        expect(copy.confidence, equals(0.7));
      });
    });
  });

  // =========================================================================
  // PolicyEvaluationResult
  // =========================================================================
  group('PolicyEvaluationResult', () {
    group('pass() factory', () {
      test('creates a passing result', () {
        final result = PolicyEvaluationResult.pass();
        expect(result.passed, isTrue);
        expect(result.action, equals(PolicyAction.allow));
        expect(result.triggeredRules, isEmpty);
        expect(result.messages, isEmpty);
      });
    });

    group('fail() factory', () {
      test('creates a failing result with default action (deny)', () {
        final result = PolicyEvaluationResult.fail();
        expect(result.passed, isFalse);
        expect(result.action, equals(PolicyAction.deny));
        expect(result.triggeredRules, isEmpty);
        expect(result.messages, isEmpty);
      });

      test('creates a failing result with custom action', () {
        final result = PolicyEvaluationResult.fail(
          action: PolicyAction.warn,
        );
        expect(result.passed, isFalse);
        expect(result.action, equals(PolicyAction.warn));
      });

      test('creates a failing result with triggered rules', () {
        const triggered = [
          TriggeredRule(
            policyId: 'p1',
            ruleId: 'r1',
            action: PolicyAction.deny,
            message: 'Blocked',
          ),
        ];
        final result = PolicyEvaluationResult.fail(
          triggeredRules: triggered,
        );
        expect(result.triggeredRules.length, equals(1));
        expect(result.triggeredRules[0].policyId, equals('p1'));
      });

      test('creates a failing result with messages', () {
        final result = PolicyEvaluationResult.fail(
          messages: ['Error 1', 'Error 2'],
        );
        expect(result.messages, equals(['Error 1', 'Error 2']));
      });

      test('creates a failing result with all custom values', () {
        const triggered = [
          TriggeredRule(
            policyId: 'policy-x',
            ruleId: 'rule-y',
            action: PolicyAction.requireApproval,
            message: 'Needs approval',
          ),
        ];
        final result = PolicyEvaluationResult.fail(
          action: PolicyAction.requireApproval,
          triggeredRules: triggered,
          messages: ['Approval required'],
        );
        expect(result.passed, isFalse);
        expect(result.action, equals(PolicyAction.requireApproval));
        expect(result.triggeredRules.length, equals(1));
        expect(result.messages, equals(['Approval required']));
      });
    });

    test('constructor with all fields', () {
      const result = PolicyEvaluationResult(
        passed: true,
        action: PolicyAction.log,
        triggeredRules: [],
        messages: ['Logged'],
      );
      expect(result.passed, isTrue);
      expect(result.action, equals(PolicyAction.log));
      expect(result.messages, equals(['Logged']));
    });
  });

  // =========================================================================
  // TriggeredRule
  // =========================================================================
  group('TriggeredRule', () {
    test('construction with all fields', () {
      const rule = TriggeredRule(
        policyId: 'policy-1',
        ruleId: 'rule-1',
        action: PolicyAction.deny,
        message: 'Access denied',
      );
      expect(rule.policyId, equals('policy-1'));
      expect(rule.ruleId, equals('rule-1'));
      expect(rule.action, equals(PolicyAction.deny));
      expect(rule.message, equals('Access denied'));
    });

    test('construction without optional message', () {
      const rule = TriggeredRule(
        policyId: 'p',
        ruleId: 'r',
        action: PolicyAction.warn,
      );
      expect(rule.policyId, equals('p'));
      expect(rule.ruleId, equals('r'));
      expect(rule.action, equals(PolicyAction.warn));
      expect(rule.message, isNull);
    });

    test('field access returns correct values', () {
      const rule = TriggeredRule(
        policyId: 'sec-policy',
        ruleId: 'rate-limit',
        action: PolicyAction.requireApproval,
        message: 'Rate limit exceeded',
      );
      expect(rule.policyId, equals('sec-policy'));
      expect(rule.ruleId, equals('rate-limit'));
      expect(rule.action, equals(PolicyAction.requireApproval));
      expect(rule.message, equals('Rate limit exceeded'));
    });
  });
}
