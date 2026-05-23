import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('PipelinesSection', () {
    test('creates with defaults', () {
      const section = PipelinesSection();
      expect(section.schemaVersion, '1.0.0');
      expect(section.pipelines, isEmpty);
      expect(section.isEmpty, isTrue);
      expect(section.isNotEmpty, isFalse);
    });

    test('empty section toJson keeps schemaVersion and omits pipelines', () {
      const section = PipelinesSection();
      final json = section.toJson();
      expect(json['schemaVersion'], '1.0.0');
      expect(json.containsKey('pipelines'), isFalse);
    });

    test('fromJson with empty map applies defaults', () {
      final section = PipelinesSection.fromJson({});
      expect(section.schemaVersion, '1.0.0');
      expect(section.pipelines, isEmpty);
    });

    test('round-trip preserves all fields', () {
      const original = PipelinesSection(
        pipelines: [
          PipelineEntry(
            id: 'pl1',
            name: 'Data Ingest',
            version: '2.0.0',
            description: 'ETL pipeline.',
            stages: [
              {'id': 'extract', 'kind': 'source'},
              {'id': 'transform', 'kind': 'map'},
              {'id': 'load', 'kind': 'sink'},
            ],
            metadata: {'sla': 'gold'},
          ),
        ],
      );

      final json = original.toJson();
      final round = PipelinesSection.fromJson(json);

      expect(round.pipelines, hasLength(1));
      final p = round.pipelines.first;
      expect(p.id, 'pl1');
      expect(p.name, 'Data Ingest');
      expect(p.version, '2.0.0');
      expect(p.description, 'ETL pipeline.');
      expect(p.stages, hasLength(3));
      expect(p.stages[0]['id'], 'extract');
      expect(p.stages[2]['kind'], 'sink');
      expect(p.metadata['sla'], 'gold');
    });

    test('default version is 1.0.0', () {
      const p = PipelineEntry(id: 'x', name: 'X');
      expect(p.version, '1.0.0');
    });

    test('findById returns matching pipeline', () {
      const section = PipelinesSection(
        pipelines: [
          PipelineEntry(id: 'a', name: 'A'),
          PipelineEntry(id: 'b', name: 'B'),
        ],
      );
      expect(section.findById('a')!.name, 'A');
      expect(section.findById('missing'), isNull);
    });

    test('copyWith creates modified copy', () {
      const original = PipelinesSection(pipelines: [
        PipelineEntry(id: 'a', name: 'A'),
      ]);
      final copy = original.copyWith(pipelines: const [
        PipelineEntry(id: 'b', name: 'B'),
      ]);
      expect(original.pipelines.first.id, 'a');
      expect(copy.pipelines.first.id, 'b');
    });
  });
}
