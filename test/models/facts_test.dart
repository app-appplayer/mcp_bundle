import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('FactsSection', () {
    test('creates with defaults', () {
      const section = FactsSection();
      expect(section.schemaVersion, '1.0.0');
      expect(section.facts, isEmpty);
      expect(section.isEmpty, isTrue);
      expect(section.isNotEmpty, isFalse);
    });

    test('empty section toJson keeps schemaVersion and omits facts', () {
      const section = FactsSection();
      final json = section.toJson();
      expect(json['schemaVersion'], '1.0.0');
      expect(json.containsKey('facts'), isFalse);
    });

    test('fromJson with empty map applies defaults', () {
      final section = FactsSection.fromJson({});
      expect(section.schemaVersion, '1.0.0');
      expect(section.facts, isEmpty);
    });

    test('round-trip preserves all fields', () {
      const original = FactsSection(
        facts: [
          Fact(
            id: 'f1',
            subject: 'mcp_bundle',
            predicate: 'has-version',
            object: '0.3.3',
            confidence: 0.95,
            source: 'manifest',
            metadata: {'tags': ['release']},
          ),
        ],
      );

      final json = original.toJson();
      final round = FactsSection.fromJson(json);

      expect(round.facts, hasLength(1));
      final f = round.facts.first;
      expect(f.id, 'f1');
      expect(f.subject, 'mcp_bundle');
      expect(f.predicate, 'has-version');
      expect(f.object, '0.3.3');
      expect(f.confidence, 0.95);
      expect(f.source, 'manifest');
      expect(f.metadata['tags'], ['release']);
    });

    test('findById returns matching fact', () {
      const section = FactsSection(
        facts: [
          Fact(id: 'a', subject: 'X', predicate: 'is', object: 'Y'),
          Fact(id: 'b', subject: 'P', predicate: 'is', object: 'Q'),
        ],
      );
      expect(section.findById('b')!.subject, 'P');
      expect(section.findById('missing'), isNull);
    });

    test('copyWith creates modified copy', () {
      const original = FactsSection(
        facts: [
          Fact(subject: 's', predicate: 'p', object: 'o'),
        ],
      );
      final copy = original.copyWith(facts: const [
        Fact(subject: 's2', predicate: 'p2', object: 'o2'),
      ]);
      expect(original.facts.first.subject, 's');
      expect(copy.facts.first.subject, 's2');
    });
  });

  group('Fact object shapes', () {
    test('round-trips with string object', () {
      const f = Fact(subject: 'x', predicate: 'p', object: 'hello');
      final round = Fact.fromJson(f.toJson());
      expect(round.object, 'hello');
    });

    test('round-trips with number object', () {
      const f = Fact(subject: 'x', predicate: 'count', object: 42);
      final round = Fact.fromJson(f.toJson());
      expect(round.object, 42);
    });

    test('round-trips with bool object', () {
      const f = Fact(subject: 'x', predicate: 'active', object: true);
      final round = Fact.fromJson(f.toJson());
      expect(round.object, isTrue);
    });

    test('round-trips with Map object', () {
      const f = Fact(
        subject: 'x',
        predicate: 'has',
        object: {'k': 'v', 'n': 1},
      );
      final round = Fact.fromJson(f.toJson());
      expect(round.object, isA<Map>());
      expect((round.object as Map)['k'], 'v');
      expect((round.object as Map)['n'], 1);
    });

    test('round-trips with List object', () {
      const f = Fact(
        subject: 'x',
        predicate: 'tags',
        object: ['a', 'b', 'c'],
      );
      final round = Fact.fromJson(f.toJson());
      expect(round.object, isA<List>());
      expect(round.object, ['a', 'b', 'c']);
    });
  });

  group('Fact confidence clamping', () {
    test('Fact.clamped pulls negative to 0.0', () {
      final f = Fact.clamped(
        subject: 's',
        predicate: 'p',
        object: 'o',
        confidence: -0.5,
      );
      expect(f.confidence, 0.0);
    });

    test('Fact.clamped pushes >1.0 down to 1.0', () {
      final f = Fact.clamped(
        subject: 's',
        predicate: 'p',
        object: 'o',
        confidence: 1.7,
      );
      expect(f.confidence, 1.0);
    });

    test('Fact.clamped preserves in-range value', () {
      final f = Fact.clamped(
        subject: 's',
        predicate: 'p',
        object: 'o',
        confidence: 0.42,
      );
      expect(f.confidence, 0.42);
    });

    test('Fact.clamped accepts null', () {
      final f = Fact.clamped(
        subject: 's',
        predicate: 'p',
        object: 'o',
      );
      expect(f.confidence, isNull);
    });

    test('fromJson clamps out-of-range values', () {
      final low = Fact.fromJson({
        'subject': 's',
        'predicate': 'p',
        'object': 'o',
        'confidence': -1.0,
      });
      expect(low.confidence, 0.0);

      final high = Fact.fromJson({
        'subject': 's',
        'predicate': 'p',
        'object': 'o',
        'confidence': 2.0,
      });
      expect(high.confidence, 1.0);
    });
  });

  group('Fact toJson keys', () {
    test('emits required keys + omits optional null fields', () {
      const f = Fact(subject: 's', predicate: 'p', object: 'o');
      final json = f.toJson();
      expect(json['subject'], 's');
      expect(json['predicate'], 'p');
      expect(json['object'], 'o');
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('confidence'), isFalse);
      expect(json.containsKey('source'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });
  });

  group('Fact copyWith', () {
    test('overrides selected fields', () {
      const original = Fact(
        id: 'f1',
        subject: 's',
        predicate: 'p',
        object: 'o',
        confidence: 0.5,
      );
      final copy = original.copyWith(confidence: 0.9, source: 'doc-1');
      expect(copy.id, 'f1');
      expect(copy.subject, 's');
      expect(copy.confidence, 0.9);
      expect(copy.source, 'doc-1');
    });
  });
}
