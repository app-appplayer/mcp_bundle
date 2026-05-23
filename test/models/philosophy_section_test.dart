import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('PhilosophySection (TC-085)', () {
    test('creates with defaults', () {
      const section = PhilosophySection();
      expect(section.philosophies, isEmpty);
      expect(section.isEmpty, isTrue);
      expect(section.isNotEmpty, isFalse);
    });

    test('empty section toJson keeps schemaVersion and omits philosophies key',
        () {
      const section = PhilosophySection();
      final json = section.toJson();
      expect(json['schemaVersion'], equals('1.0.0'));
      expect(json.containsKey('philosophies'), isFalse);
    });

    test('schemaVersion default is 1.0.0', () {
      const section = PhilosophySection();
      expect(section.schemaVersion, equals('1.0.0'));
    });

    test('fromJson defaults schemaVersion to 1.0.0 when absent', () {
      final section = PhilosophySection.fromJson(<String, dynamic>{});
      expect(section.schemaVersion, equals('1.0.0'));
    });

    test('fromJson preserves explicit schemaVersion', () {
      final section = PhilosophySection.fromJson({'schemaVersion': '1.2.0'});
      expect(section.schemaVersion, equals('1.2.0'));
    });

    test('round-trip preserves schemaVersion', () {
      const original = PhilosophySection(
        schemaVersion: '1.5.0',
        philosophies: [
          Philosophy(id: 'p1', name: 'P1', statement: 's'),
          Philosophy(id: 'p2', name: 'P2', statement: 's'),
        ],
      );
      final json = original.toJson();
      final round = PhilosophySection.fromJson(json);
      expect(round.schemaVersion, equals('1.5.0'));
      expect(round.philosophies, hasLength(2));
    });

    test('copyWith preserves schemaVersion when not overridden', () {
      const original = PhilosophySection(schemaVersion: '2.0.0');
      final copy = original.copyWith();
      expect(copy.schemaVersion, equals('2.0.0'));
    });

    test('fromJson with empty map', () {
      final section = PhilosophySection.fromJson({});
      expect(section.philosophies, isEmpty);
    });

    test('fromJson with null philosophies', () {
      final section = PhilosophySection.fromJson({'philosophies': null});
      expect(section.philosophies, isEmpty);
    });

    test('round-trip preserves all fields', () {
      const original = PhilosophySection(
        philosophies: [
          Philosophy(
            id: 'p1',
            name: 'Validated Patterns First',
            statement: 'Reuse proven patterns before designing new ones.',
            rationale: 'Saves verification cost and avoids regression.',
            examples: [
              PhilosophyExample(
                description: 'Adopt vibe builder shell for knowledge_builder',
                context: 'Tool rebuild parallel',
                source: 'tools/builder/app_builder_vibe',
              ),
            ],
            counterexamples: [
              PhilosophyExample(
                description: 'Hand-rolling a new shell from scratch',
              ),
            ],
            school: 'AI-era engineering',
            confidence: 0.85,
            metadata: {'tags': ['design', 'reuse']},
          ),
        ],
      );

      final json = original.toJson();
      final round = PhilosophySection.fromJson(json);

      expect(round.philosophies, hasLength(1));
      final p = round.philosophies.first;
      expect(p.id, 'p1');
      expect(p.name, 'Validated Patterns First');
      expect(p.statement, contains('Reuse proven patterns'));
      expect(p.rationale, contains('verification cost'));
      expect(p.examples, hasLength(1));
      expect(p.examples.first.description, contains('vibe builder shell'));
      expect(p.examples.first.context, 'Tool rebuild parallel');
      expect(p.examples.first.source, contains('app_builder_vibe'));
      expect(p.counterexamples, hasLength(1));
      expect(p.counterexamples.first.description, contains('Hand-rolling'));
      expect(p.counterexamples.first.context, isNull);
      expect(p.school, 'AI-era engineering');
      expect(p.confidence, 0.85);
      expect(p.metadata['tags'], ['design', 'reuse']);
    });

    test('missing optional fields deserialize to null', () {
      final p = Philosophy.fromJson({
        'id': 'p1',
        'name': 'Bare',
        'statement': 'Minimum viable principle.',
      });
      expect(p.rationale, isNull);
      expect(p.school, isNull);
      expect(p.confidence, isNull);
      expect(p.examples, isEmpty);
      expect(p.counterexamples, isEmpty);
    });

    test('empty examples lists serialize as omitted keys', () {
      const p = Philosophy(
        id: 'p1',
        name: 'Bare',
        statement: 'Minimum viable principle.',
      );
      final json = p.toJson();
      expect(json.containsKey('examples'), isFalse);
      expect(json.containsKey('counterexamples'), isFalse);
      expect(json.containsKey('rationale'), isFalse);
      expect(json.containsKey('school'), isFalse);
      expect(json.containsKey('confidence'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('findById returns matching philosophy', () {
      const section = PhilosophySection(
        philosophies: [
          Philosophy(id: 'a', name: 'A', statement: 'a'),
          Philosophy(id: 'b', name: 'B', statement: 'b'),
        ],
      );
      expect(section.findById('b')!.name, 'B');
      expect(section.findById('missing'), isNull);
    });

    test('PhilosophyExample round-trips minimal form', () {
      const ex = PhilosophyExample(description: 'Lone description');
      final round = PhilosophyExample.fromJson(ex.toJson());
      expect(round.description, 'Lone description');
      expect(round.context, isNull);
      expect(round.source, isNull);
    });

    test('McpBundle integration — philosophy section round-trips', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b1', name: 'B1', version: '1.0.0'),
        philosophy: PhilosophySection(
          philosophies: [
            Philosophy(id: 'p1', name: 'N', statement: 'S'),
          ],
        ),
      );
      final json = bundle.toJson();
      expect(json['philosophy'], isNotNull);
      final round = McpBundle.fromJson(json);
      expect(round.philosophy, isNotNull);
      expect(round.philosophy!.philosophies.first.id, 'p1');
      expect(round.presentSections, contains('philosophy'));
      expect(round.hasContent, isTrue);
    });
  });
}
