import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('BehaviorSection', () {
    final json = {
      'schemaVersion': '1.0.0',
      'definitions': [
        {
          'id': 'approve-and-pay',
          'name': 'Approve and pay',
          'description': 'Wait for sign-off, then pay.',
          'steps': [
            {
              'id': 'gate',
              'when': 'approved == true',
              'then': {'false': 'wait'},
            },
            {
              'id': 'pay',
              'do': {
                'tool': 'finance.pay',
                'args': {'amount': 100},
              },
              'dependsOn': ['gate'],
              'onFailure': 'notify',
            },
          ],
          'metadata': {'owner': 'ops'},
        },
      ],
    };

    test('parses definitions and steps', () {
      final section = BehaviorSection.fromJson(json);
      expect(section.definitions, hasLength(1));
      final def = section.definitions.first;
      expect(def.id, 'approve-and-pay');
      expect(def.steps, hasLength(2));

      final gate = def.steps[0];
      expect(gate.when, 'approved == true');
      expect(gate.then['false'], 'wait');
      expect(gate.action, isNull); // guard-only step

      final pay = def.steps[1];
      expect(pay.action!['tool'], 'finance.pay');
      expect(pay.dependsOn, ['gate']);
      expect(pay.onFailure, 'notify');
    });

    test('round-trips through json', () {
      final section = BehaviorSection.fromJson(json);
      final back = BehaviorSection.fromJson(section.toJson());
      expect(back.definitions.first.steps[1].action!['tool'], 'finance.pay');
      expect(back.definitions.first.steps[0].then['false'], 'wait');
    });

    test('findById', () {
      final section = BehaviorSection.fromJson(json);
      expect(section.findById('approve-and-pay'), isNotNull);
      expect(section.findById('nope'), isNull);
    });
  });

  group('McpBundle carries behavior section', () {
    test('round-trips behavior alongside other sections', () {
      final bundle = McpBundle.fromJson({
        'schemaVersion': '1.0.0',
        'manifest': {'id': 'b', 'name': 'B', 'version': '1.0.0'},
        'behavior': {
          'definitions': [
            {
              'id': 'd1',
              'name': 'D1',
              'steps': [
                {'id': 's1', 'do': {'skill': 'review'}},
              ],
            },
          ],
        },
      });
      expect(bundle.behavior, isNotNull);
      expect(bundle.presentSections, contains('behavior'));

      final back = McpBundle.fromJson(bundle.toJson());
      expect(back.behavior!.definitions.first.steps.first.action!['skill'],
          'review');
    });

    test('absent behavior stays null and is not emitted', () {
      final bundle = McpBundle.fromJson({
        'schemaVersion': '1.0.0',
        'manifest': {'id': 'b', 'name': 'B', 'version': '1.0.0'},
      });
      expect(bundle.behavior, isNull);
      expect(bundle.toJson().containsKey('behavior'), isFalse);
    });
  });
}
