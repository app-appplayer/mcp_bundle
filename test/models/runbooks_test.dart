import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('RunbooksSection', () {
    test('creates with defaults', () {
      const section = RunbooksSection();
      expect(section.schemaVersion, '1.0.0');
      expect(section.runbooks, isEmpty);
      expect(section.isEmpty, isTrue);
      expect(section.isNotEmpty, isFalse);
    });

    test('empty section toJson keeps schemaVersion and omits runbooks', () {
      const section = RunbooksSection();
      final json = section.toJson();
      expect(json['schemaVersion'], '1.0.0');
      expect(json.containsKey('runbooks'), isFalse);
    });

    test('fromJson with empty map applies defaults', () {
      final section = RunbooksSection.fromJson({});
      expect(section.schemaVersion, '1.0.0');
      expect(section.runbooks, isEmpty);
    });

    test('round-trip preserves all fields', () {
      const original = RunbooksSection(
        runbooks: [
          RunbookEntry(
            id: 'rb1',
            name: 'Disk Pressure Recovery',
            version: '1.1.0',
            description: 'Free space when alert fires.',
            procedure: [
              {'id': 'check', 'action': 'df -h'},
              {'id': 'cleanup', 'action': 'rotate-logs'},
            ],
            metadata: {'severity': 'P2'},
          ),
        ],
      );

      final json = original.toJson();
      final round = RunbooksSection.fromJson(json);

      expect(round.runbooks, hasLength(1));
      final r = round.runbooks.first;
      expect(r.id, 'rb1');
      expect(r.name, 'Disk Pressure Recovery');
      expect(r.version, '1.1.0');
      expect(r.description, 'Free space when alert fires.');
      expect(r.procedure, hasLength(2));
      expect(r.procedure[0]['id'], 'check');
      expect(r.procedure[1]['action'], 'rotate-logs');
      expect(r.metadata['severity'], 'P2');
    });

    test('default version is 1.0.0', () {
      const r = RunbookEntry(id: 'x', name: 'X');
      expect(r.version, '1.0.0');
    });

    test('findById returns matching runbook', () {
      const section = RunbooksSection(
        runbooks: [
          RunbookEntry(id: 'a', name: 'A'),
          RunbookEntry(id: 'b', name: 'B'),
        ],
      );
      expect(section.findById('b')!.name, 'B');
      expect(section.findById('missing'), isNull);
    });

    test('copyWith creates modified copy', () {
      const original = RunbooksSection(runbooks: [
        RunbookEntry(id: 'a', name: 'A'),
      ]);
      final copy = original.copyWith(runbooks: const [
        RunbookEntry(id: 'b', name: 'B'),
      ]);
      expect(original.runbooks.first.id, 'a');
      expect(copy.runbooks.first.id, 'b');
    });
  });
}
