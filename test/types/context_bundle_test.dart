import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  // ── ContextEntity ──────────────────────────────────────────────────────

  group('ContextEntity', () {
    group('fromJson', () {
      test('parses all fields', () {
        final entity = ContextEntity.fromJson({
          'id': 'ent-1',
          'type': 'person',
          'name': 'Alice',
          'attributes': {'age': 30, 'role': 'engineer'},
        });

        expect(entity.id, equals('ent-1'));
        expect(entity.type, equals('person'));
        expect(entity.name, equals('Alice'));
        expect(entity.attributes, equals({'age': 30, 'role': 'engineer'}));
      });

      test('applies defaults for missing fields', () {
        final entity = ContextEntity.fromJson({});

        expect(entity.id, equals(''));
        expect(entity.type, equals(''));
        expect(entity.name, equals(''));
        expect(entity.attributes, isEmpty);
      });
    });

    group('toJson', () {
      test('serialises all populated fields', () {
        const entity = ContextEntity(
          id: 'ent-1',
          type: 'org',
          name: 'Acme',
          attributes: {'size': 'large'},
        );
        final json = entity.toJson();

        expect(json['id'], equals('ent-1'));
        expect(json['type'], equals('org'));
        expect(json['name'], equals('Acme'));
        expect(json['attributes'], equals({'size': 'large'}));
      });

      test('omits attributes when empty', () {
        const entity = ContextEntity(
          id: 'ent-1',
          type: 'org',
          name: 'Acme',
        );
        expect(entity.toJson().containsKey('attributes'), isFalse);
      });
    });

    group('JSON roundtrip', () {
      test('entity survives roundtrip', () {
        const original = ContextEntity(
          id: 'ent-rt',
          type: 'device',
          name: 'Sensor-A',
          attributes: {'unit': 'celsius'},
        );
        final restored = ContextEntity.fromJson(original.toJson());

        expect(restored.id, equals(original.id));
        expect(restored.type, equals(original.type));
        expect(restored.name, equals(original.name));
        expect(restored.attributes, equals(original.attributes));
      });
    });

    group('equality and hashCode', () {
      test('entities with same id are equal', () {
        const a = ContextEntity(id: 'e1', type: 'a', name: 'A');
        const b = ContextEntity(id: 'e1', type: 'b', name: 'B');
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('entities with different ids are not equal', () {
        const a = ContextEntity(id: 'e1', type: 'a', name: 'A');
        const b = ContextEntity(id: 'e2', type: 'a', name: 'A');
        expect(a, isNot(equals(b)));
      });
    });
  });

  // ── ContextEvent ───────────────────────────────────────────────────────

  group('ContextEvent', () {
    final ts = DateTime(2024, 6, 15, 10, 30, 0);

    group('fromJson', () {
      test('parses all fields', () {
        final event = ContextEvent.fromJson({
          'id': 'evt-1',
          'type': 'click',
          'timestamp': '2024-06-15T10:30:00.000',
          'data': {'button': 'submit'},
        });

        expect(event.id, equals('evt-1'));
        expect(event.type, equals('click'));
        expect(event.timestamp, equals(ts));
        expect(event.data, equals({'button': 'submit'}));
      });

      test('applies defaults for missing fields', () {
        final event = ContextEvent.fromJson({});

        expect(event.id, equals(''));
        expect(event.type, equals(''));
        expect(event.data, isEmpty);
        // timestamp defaults to DateTime.now() -- just verify it is reasonable
        expect(event.timestamp.year, greaterThanOrEqualTo(2024));
      });
    });

    group('toJson', () {
      test('serialises all populated fields', () {
        final event = ContextEvent(
          id: 'evt-1',
          type: 'navigate',
          timestamp: ts,
          data: {'page': '/home'},
        );
        final json = event.toJson();

        expect(json['id'], equals('evt-1'));
        expect(json['type'], equals('navigate'));
        expect(json['timestamp'], equals(ts.toIso8601String()));
        expect(json['data'], equals({'page': '/home'}));
      });

      test('omits data when empty', () {
        final event = ContextEvent(
          id: 'evt-1',
          type: 'ping',
          timestamp: ts,
        );
        expect(event.toJson().containsKey('data'), isFalse);
      });
    });

    group('JSON roundtrip', () {
      test('event survives roundtrip', () {
        final original = ContextEvent(
          id: 'evt-rt',
          type: 'action',
          timestamp: ts,
          data: {'key': 'value'},
        );
        final restored = ContextEvent.fromJson(original.toJson());

        expect(restored.id, equals(original.id));
        expect(restored.type, equals(original.type));
        expect(restored.timestamp, equals(original.timestamp));
        expect(restored.data, equals(original.data));
      });
    });

    group('equality and hashCode', () {
      test('events with same id are equal', () {
        final a = ContextEvent(id: 'ev1', type: 'a', timestamp: ts);
        final b = ContextEvent(
          id: 'ev1',
          type: 'b',
          timestamp: ts.add(const Duration(hours: 1)),
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('events with different ids are not equal', () {
        final a = ContextEvent(id: 'ev1', type: 'a', timestamp: ts);
        final b = ContextEvent(id: 'ev2', type: 'a', timestamp: ts);
        expect(a, isNot(equals(b)));
      });
    });
  });

  // ── ContextView ────────────────────────────────────────────────────────

  group('ContextView', () {
    final asOf = DateTime(2024, 7, 1, 0, 0, 0);

    group('fromJson', () {
      test('parses all fields', () {
        final view = ContextView.fromJson({
          'id': 'v1',
          'type': 'summary',
          'content': 'Full summary text',
          'asOf': '2024-07-01T00:00:00.000',
        });

        expect(view.id, equals('v1'));
        expect(view.type, equals('summary'));
        expect(view.content, equals('Full summary text'));
        expect(view.asOf, equals(asOf));
      });

      test('applies defaults for missing fields', () {
        final view = ContextView.fromJson({});

        expect(view.id, equals(''));
        expect(view.type, equals(''));
        expect(view.content, equals(''));
        expect(view.asOf.year, greaterThanOrEqualTo(2024));
      });
    });

    group('toJson', () {
      test('serialises all fields', () {
        final view = ContextView(
          id: 'v1',
          type: 'report',
          content: 'Report content',
          asOf: asOf,
        );
        final json = view.toJson();

        expect(json['id'], equals('v1'));
        expect(json['type'], equals('report'));
        expect(json['content'], equals('Report content'));
        expect(json['asOf'], equals(asOf.toIso8601String()));
      });
    });

    group('JSON roundtrip', () {
      test('view survives roundtrip', () {
        final original = ContextView(
          id: 'v-rt',
          type: 'digest',
          content: 'Digest content here',
          asOf: asOf,
        );
        final restored = ContextView.fromJson(original.toJson());

        expect(restored.id, equals(original.id));
        expect(restored.type, equals(original.type));
        expect(restored.content, equals(original.content));
        expect(restored.asOf, equals(original.asOf));
      });
    });

    group('equality and hashCode', () {
      test('views with same id are equal', () {
        final a = ContextView(
          id: 'v1',
          type: 'a',
          content: 'aaa',
          asOf: asOf,
        );
        final b = ContextView(
          id: 'v1',
          type: 'b',
          content: 'bbb',
          asOf: asOf,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('views with different ids are not equal', () {
        final a = ContextView(
          id: 'v1',
          type: 'a',
          content: 'c',
          asOf: asOf,
        );
        final b = ContextView(
          id: 'v2',
          type: 'a',
          content: 'c',
          asOf: asOf,
        );
        expect(a, isNot(equals(b)));
      });
    });
  });

  // ── ContextClaim ───────────────────────────────────────────────────────

  group('ContextClaim', () {
    group('fromJson', () {
      test('parses all fields', () {
        final claim = ContextClaim.fromJson({
          'id': 'cc-1',
          'text': 'A claim statement',
          'confidence': 0.75,
          'evidenceRefs': ['ref-a', 'ref-b'],
        });

        expect(claim.id, equals('cc-1'));
        expect(claim.text, equals('A claim statement'));
        expect(claim.confidence, equals(0.75));
        expect(claim.evidenceRefs, equals(['ref-a', 'ref-b']));
      });

      test('applies defaults for missing fields', () {
        final claim = ContextClaim.fromJson({});

        expect(claim.id, equals(''));
        expect(claim.text, equals(''));
        expect(claim.confidence, equals(0.0));
        expect(claim.evidenceRefs, isEmpty);
      });

      test('parses confidence from integer', () {
        final claim = ContextClaim.fromJson({
          'id': 'cc-2',
          'text': 'test',
          'confidence': 1,
        });
        expect(claim.confidence, equals(1.0));
      });
    });

    group('toJson', () {
      test('serialises all populated fields', () {
        const claim = ContextClaim(
          id: 'cc-1',
          text: 'A claim',
          confidence: 0.9,
          evidenceRefs: ['r1'],
        );
        final json = claim.toJson();

        expect(json['id'], equals('cc-1'));
        expect(json['text'], equals('A claim'));
        expect(json['confidence'], equals(0.9));
        expect(json['evidenceRefs'], equals(['r1']));
      });

      test('omits evidenceRefs when empty', () {
        const claim = ContextClaim(
          id: 'cc-1',
          text: 'No refs',
          confidence: 0.5,
        );
        expect(claim.toJson().containsKey('evidenceRefs'), isFalse);
      });
    });

    group('JSON roundtrip', () {
      test('claim survives roundtrip', () {
        const original = ContextClaim(
          id: 'cc-rt',
          text: 'Roundtrip claim',
          confidence: 0.88,
          evidenceRefs: ['r1', 'r2'],
        );
        final restored = ContextClaim.fromJson(original.toJson());

        expect(restored.id, equals(original.id));
        expect(restored.text, equals(original.text));
        expect(restored.confidence, equals(original.confidence));
        expect(restored.evidenceRefs, equals(original.evidenceRefs));
      });
    });

    group('equality and hashCode', () {
      test('claims with same id are equal', () {
        const a = ContextClaim(id: 'c1', text: 'a', confidence: 0.1);
        const b = ContextClaim(id: 'c1', text: 'b', confidence: 0.9);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('claims with different ids are not equal', () {
        const a = ContextClaim(id: 'c1', text: 'a', confidence: 0.5);
        const b = ContextClaim(id: 'c2', text: 'a', confidence: 0.5);
        expect(a, isNot(equals(b)));
      });
    });
  });

  // ── ContextBundle ──────────────────────────────────────────────────────

  group('ContextBundle', () {
    final createdAt = DateTime(2024, 8, 1, 12, 0, 0);

    ContextBundle fullBundle() => ContextBundle(
          id: 'bundle-1',
          entities: const [
            ContextEntity(id: 'ent-1', type: 'person', name: 'Alice'),
          ],
          events: [
            ContextEvent(
              id: 'evt-1',
              type: 'action',
              timestamp: createdAt,
            ),
          ],
          views: [
            ContextView(
              id: 'v-1',
              type: 'summary',
              content: 'summary text',
              asOf: createdAt,
            ),
          ],
          claims: const [
            ContextClaim(id: 'cc-1', text: 'claim', confidence: 0.8),
          ],
          createdAt: createdAt,
          estimatedTokens: 500,
        );

    group('empty factory', () {
      test('creates an empty bundle with id "empty"', () {
        final bundle = ContextBundle.empty();

        expect(bundle.id, equals('empty'));
        expect(bundle.entities, isEmpty);
        expect(bundle.events, isEmpty);
        expect(bundle.views, isEmpty);
        expect(bundle.claims, isEmpty);
        expect(bundle.estimatedTokens, isNull);
      });
    });

    group('isEmpty', () {
      test('returns true for empty bundle', () {
        expect(ContextBundle.empty().isEmpty, isTrue);
      });

      test('returns false when entities are present', () {
        final bundle = ContextBundle(
          id: 'b',
          entities: const [
            ContextEntity(id: 'e', type: 't', name: 'n'),
          ],
          createdAt: createdAt,
        );
        expect(bundle.isEmpty, isFalse);
      });

      test('returns false when events are present', () {
        final bundle = ContextBundle(
          id: 'b',
          events: [
            ContextEvent(id: 'ev', type: 't', timestamp: createdAt),
          ],
          createdAt: createdAt,
        );
        expect(bundle.isEmpty, isFalse);
      });

      test('returns false when views are present', () {
        final bundle = ContextBundle(
          id: 'b',
          views: [
            ContextView(id: 'v', type: 't', content: 'c', asOf: createdAt),
          ],
          createdAt: createdAt,
        );
        expect(bundle.isEmpty, isFalse);
      });

      test('returns false when claims are present', () {
        final bundle = ContextBundle(
          id: 'b',
          claims: const [
            ContextClaim(id: 'c', text: 't', confidence: 0.5),
          ],
          createdAt: createdAt,
        );
        expect(bundle.isEmpty, isFalse);
      });
    });

    group('fromJson', () {
      test('parses all fields including nested collections', () {
        final json = {
          'id': 'b1',
          'entities': [
            {'id': 'ent-1', 'type': 'person', 'name': 'Bob'},
          ],
          'events': [
            {
              'id': 'evt-1',
              'type': 'login',
              'timestamp': '2024-08-01T12:00:00.000',
            },
          ],
          'views': [
            {
              'id': 'v-1',
              'type': 'digest',
              'content': 'content',
              'asOf': '2024-08-01T12:00:00.000',
            },
          ],
          'claims': [
            {'id': 'cc-1', 'text': 'claim', 'confidence': 0.9},
          ],
          'createdAt': '2024-08-01T12:00:00.000',
          'estimatedTokens': 250,
        };

        final bundle = ContextBundle.fromJson(json);

        expect(bundle.id, equals('b1'));
        expect(bundle.entities, hasLength(1));
        expect(bundle.entities.first.name, equals('Bob'));
        expect(bundle.events, hasLength(1));
        expect(bundle.events.first.type, equals('login'));
        expect(bundle.views, hasLength(1));
        expect(bundle.views.first.content, equals('content'));
        expect(bundle.claims, hasLength(1));
        expect(bundle.claims.first.text, equals('claim'));
        expect(bundle.createdAt, equals(createdAt));
        expect(bundle.estimatedTokens, equals(250));
      });

      test('applies defaults for missing fields', () {
        final bundle = ContextBundle.fromJson({});

        expect(bundle.id, equals(''));
        expect(bundle.entities, isEmpty);
        expect(bundle.events, isEmpty);
        expect(bundle.views, isEmpty);
        expect(bundle.claims, isEmpty);
        expect(bundle.estimatedTokens, isNull);
      });
    });

    group('toJson', () {
      test('serialises all populated fields', () {
        final json = fullBundle().toJson();

        expect(json['id'], equals('bundle-1'));
        expect(json['entities'], isA<List<dynamic>>());
        expect(json['entities'] as List<dynamic>, hasLength(1));
        expect(json['events'], isA<List<dynamic>>());
        expect(json['views'], isA<List<dynamic>>());
        expect(json['claims'], isA<List<dynamic>>());
        expect(json['createdAt'], equals(createdAt.toIso8601String()));
        expect(json['estimatedTokens'], equals(500));
      });

      test('omits empty collections', () {
        final bundle = ContextBundle(id: 'b', createdAt: createdAt);
        final json = bundle.toJson();

        expect(json.containsKey('entities'), isFalse);
        expect(json.containsKey('events'), isFalse);
        expect(json.containsKey('views'), isFalse);
        expect(json.containsKey('claims'), isFalse);
      });

      test('omits null estimatedTokens', () {
        final bundle = ContextBundle(id: 'b', createdAt: createdAt);
        expect(bundle.toJson().containsKey('estimatedTokens'), isFalse);
      });
    });

    group('JSON roundtrip', () {
      test('fully populated bundle survives roundtrip', () {
        final original = fullBundle();
        final restored = ContextBundle.fromJson(original.toJson());

        expect(restored.id, equals(original.id));
        expect(restored.entities.length, equals(original.entities.length));
        expect(restored.entities.first.id, equals(original.entities.first.id));
        expect(restored.events.length, equals(original.events.length));
        expect(restored.views.length, equals(original.views.length));
        expect(restored.claims.length, equals(original.claims.length));
        expect(restored.createdAt, equals(original.createdAt));
        expect(restored.estimatedTokens, equals(original.estimatedTokens));
      });
    });

    group('equality and hashCode', () {
      test('bundles with same id are equal', () {
        final a = ContextBundle(id: 'b1', createdAt: createdAt);
        final b = ContextBundle(
          id: 'b1',
          createdAt: createdAt.add(const Duration(days: 1)),
          estimatedTokens: 999,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('bundles with different ids are not equal', () {
        final a = ContextBundle(id: 'b1', createdAt: createdAt);
        final b = ContextBundle(id: 'b2', createdAt: createdAt);
        expect(a, isNot(equals(b)));
      });
    });

    group('toString', () {
      test('includes id and collection counts', () {
        final bundle = fullBundle();
        final str = bundle.toString();

        expect(str, contains('bundle-1'));
        expect(str, contains('entities: 1'));
        expect(str, contains('events: 1'));
      });
    });
  });
}
