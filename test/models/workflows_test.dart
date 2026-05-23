import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('WorkflowsSection', () {
    test('creates with defaults', () {
      const section = WorkflowsSection();
      expect(section.schemaVersion, '1.0.0');
      expect(section.workflows, isEmpty);
      expect(section.isEmpty, isTrue);
      expect(section.isNotEmpty, isFalse);
    });

    test('empty section toJson keeps schemaVersion and omits workflows', () {
      const section = WorkflowsSection();
      final json = section.toJson();
      expect(json['schemaVersion'], '1.0.0');
      expect(json.containsKey('workflows'), isFalse);
    });

    test('fromJson with empty map applies defaults', () {
      final section = WorkflowsSection.fromJson({});
      expect(section.schemaVersion, '1.0.0');
      expect(section.workflows, isEmpty);
    });

    test('round-trip preserves all fields', () {
      const original = WorkflowsSection(
        workflows: [
          WorkflowEntry(
            id: 'wf1',
            name: 'Deploy Service',
            version: '1.2.0',
            description: 'Standard service deploy.',
            steps: [
              {'id': 's1', 'action': 'build'},
              {'id': 's2', 'action': 'push'},
            ],
            metadata: {'owner': 'platform'},
          ),
        ],
      );

      final json = original.toJson();
      final round = WorkflowsSection.fromJson(json);

      expect(round.workflows, hasLength(1));
      final w = round.workflows.first;
      expect(w.id, 'wf1');
      expect(w.name, 'Deploy Service');
      expect(w.version, '1.2.0');
      expect(w.description, 'Standard service deploy.');
      expect(w.steps, hasLength(2));
      expect(w.steps[0]['action'], 'build');
      expect(w.steps[1]['id'], 's2');
      expect(w.metadata['owner'], 'platform');
    });

    test('default version is 1.0.0', () {
      const w = WorkflowEntry(id: 'x', name: 'X');
      expect(w.version, '1.0.0');
    });

    test('findById returns matching workflow', () {
      const section = WorkflowsSection(
        workflows: [
          WorkflowEntry(id: 'a', name: 'A'),
          WorkflowEntry(id: 'b', name: 'B'),
        ],
      );
      expect(section.findById('b')!.name, 'B');
      expect(section.findById('missing'), isNull);
    });

    test('copyWith creates modified copy', () {
      const original = WorkflowsSection(workflows: [
        WorkflowEntry(id: 'a', name: 'A'),
      ]);
      final copy = original.copyWith(workflows: const [
        WorkflowEntry(id: 'b', name: 'B'),
      ]);
      expect(original.workflows.first.id, 'a');
      expect(copy.workflows.first.id, 'b');
    });

    test('omits empty optional keys in toJson', () {
      const w = WorkflowEntry(id: 'x', name: 'X');
      final json = w.toJson();
      expect(json['id'], 'x');
      expect(json['name'], 'X');
      expect(json['version'], '1.0.0');
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('steps'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });
  });
}
