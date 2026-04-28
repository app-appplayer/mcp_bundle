import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart' hide ValidationRule;
// Import directly to access ValidationRule which is hidden in the barrel export
import 'package:mcp_bundle/src/models/fact_graph_section.dart'
    show ValidationRule;

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // 1. FactGraphSection
  // ─────────────────────────────────────────────────────────────────────
  group('FactGraphSection', () {
    test('fromJson with minimal JSON applies defaults', () {
      final section = FactGraphSection.fromJson(const <String, dynamic>{});

      expect(section.version, equals('1.0.0'));
      expect(section.mode, equals(FactGraphMode.embedded));
      expect(section.embedded, isNull);
      expect(section.external, isNull);
      expect(section.extraction, isNull);
    });

    test('toJson with defaults produces version and mode', () {
      const section = FactGraphSection();
      final json = section.toJson();

      expect(json['version'], equals('1.0.0'));
      expect(json['mode'], equals('embedded'));
      expect(json.containsKey('embedded'), isFalse);
      expect(json.containsKey('external'), isFalse);
      expect(json.containsKey('extraction'), isFalse);
    });

    test('roundtrip fromJson/toJson preserves all fields', () {
      final json = <String, dynamic>{
        'version': '2.0.0',
        'mode': 'hybrid',
        'embedded': {
          'entities': [
            {'id': 'e1', 'type': 'person'}
          ],
        },
        'external': {'uri': 'https://example.com/fg'},
        'extraction': {
          'rules': [
            {
              'id': 'r1',
              'sourceType': 'text',
              'targetType': 'entity',
              'pattern': '.*',
            }
          ],
        },
      };

      final section = FactGraphSection.fromJson(json);
      final restored = FactGraphSection.fromJson(section.toJson());

      expect(restored.version, equals('2.0.0'));
      expect(restored.mode, equals(FactGraphMode.hybrid));
      expect(restored.embedded, isNotNull);
      expect(restored.embedded!.entities.length, equals(1));
      expect(restored.external, isNotNull);
      expect(restored.external!.uri, equals('https://example.com/fg'));
      expect(restored.extraction, isNotNull);
      expect(restored.extraction!.rules.length, equals(1));
    });

    test('fromJson with embedded section', () {
      final section = FactGraphSection.fromJson(const {
        'mode': 'embedded',
        'embedded': {
          'entities': [
            {'id': 'e1', 'type': 'user'},
          ],
          'facts': [
            {'id': 'f1', 'type': 'name', 'entityId': 'e1', 'value': 'Alice'},
          ],
        },
      });

      expect(section.mode, equals(FactGraphMode.embedded));
      expect(section.embedded!.entities.first.id, equals('e1'));
      expect(section.embedded!.facts.first.value, equals('Alice'));
    });

    test('fromJson with external section', () {
      final section = FactGraphSection.fromJson(const {
        'mode': 'referenced',
        'external': {
          'uri': 'https://fg.example.com',
          'namespace': 'prod',
        },
      });

      expect(section.mode, equals(FactGraphMode.referenced));
      expect(section.external!.uri, equals('https://fg.example.com'));
      expect(section.external!.namespace, equals('prod'));
    });

    test('fromJson with extraction section', () {
      final section = FactGraphSection.fromJson(const {
        'extraction': {
          'rules': [
            {
              'id': 'ext-1',
              'sourceType': 'document',
              'targetType': 'entity',
              'pattern': r'\b[A-Z]\w+',
            }
          ],
        },
      });

      expect(section.extraction, isNotNull);
      expect(section.extraction!.rules.first.id, equals('ext-1'));
    });

    test('copyWith replaces selected fields', () {
      const original = FactGraphSection(
        version: '1.0.0',
        mode: FactGraphMode.embedded,
      );

      final copy = original.copyWith(
        version: '2.0.0',
        mode: FactGraphMode.hybrid,
      );

      expect(copy.version, equals('2.0.0'));
      expect(copy.mode, equals(FactGraphMode.hybrid));
      // Unchanged fields remain
      expect(copy.embedded, isNull);
    });

    test('copyWith preserves original when no arguments given', () {
      final embedded = EmbeddedFactGraphData(
        entities: [
          const EmbeddedEntity(id: 'e1', type: 'thing'),
        ],
      );
      final original = FactGraphSection(
        version: '3.0.0',
        mode: FactGraphMode.referenced,
        embedded: embedded,
      );

      final copy = original.copyWith();

      expect(copy.version, equals('3.0.0'));
      expect(copy.mode, equals(FactGraphMode.referenced));
      expect(copy.embedded, same(embedded));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 2. FactGraphMode.fromString
  // ─────────────────────────────────────────────────────────────────────
  group('FactGraphMode', () {
    test('fromString returns embedded for "embedded"', () {
      expect(FactGraphMode.fromString('embedded'),
          equals(FactGraphMode.embedded));
    });

    test('fromString returns referenced for "referenced"', () {
      expect(FactGraphMode.fromString('referenced'),
          equals(FactGraphMode.referenced));
    });

    test('fromString returns hybrid for "hybrid"', () {
      expect(
          FactGraphMode.fromString('hybrid'), equals(FactGraphMode.hybrid));
    });

    test('fromString returns embedded for null', () {
      expect(FactGraphMode.fromString(null), equals(FactGraphMode.embedded));
    });

    test('fromString returns embedded for unknown string', () {
      expect(FactGraphMode.fromString('unknown'),
          equals(FactGraphMode.embedded));
    });

    test('fromString is case-insensitive', () {
      expect(FactGraphMode.fromString('EMBEDDED'),
          equals(FactGraphMode.embedded));
      expect(FactGraphMode.fromString('Referenced'),
          equals(FactGraphMode.referenced));
      expect(
          FactGraphMode.fromString('HYBRID'), equals(FactGraphMode.hybrid));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 3. EmbeddedFactGraphData
  // ─────────────────────────────────────────────────────────────────────
  group('EmbeddedFactGraphData', () {
    test('fromJson with empty JSON returns all empty lists', () {
      final data =
          EmbeddedFactGraphData.fromJson(const <String, dynamic>{});

      expect(data.entities, isEmpty);
      expect(data.facts, isEmpty);
      expect(data.relations, isEmpty);
      expect(data.summaries, isEmpty);
      expect(data.policies, isEmpty);
    });

    test('toJson with all empty lists returns empty map', () {
      const data = EmbeddedFactGraphData();
      final json = data.toJson();

      expect(json, isEmpty);
    });

    test('isEmpty returns true when all lists are empty', () {
      const data = EmbeddedFactGraphData();
      expect(data.isEmpty, isTrue);
      expect(data.isNotEmpty, isFalse);
    });

    test('isNotEmpty returns true when entities is non-empty', () {
      final data = EmbeddedFactGraphData(
        entities: [const EmbeddedEntity(id: 'e1', type: 'x')],
      );
      expect(data.isEmpty, isFalse);
      expect(data.isNotEmpty, isTrue);
    });

    test('isNotEmpty returns true when facts is non-empty', () {
      final data = EmbeddedFactGraphData(
        facts: [
          const EmbeddedFact(
              id: 'f1', type: 'name', entityId: 'e1', value: 'v')
        ],
      );
      expect(data.isNotEmpty, isTrue);
    });

    test('isNotEmpty returns true when relations is non-empty', () {
      final data = EmbeddedFactGraphData(
        relations: [
          const EmbeddedRelation(
            id: 'r1',
            type: 'knows',
            fromEntityId: 'e1',
            toEntityId: 'e2',
          )
        ],
      );
      expect(data.isNotEmpty, isTrue);
    });

    test('isNotEmpty returns true when summaries is non-empty', () {
      final data = EmbeddedFactGraphData(
        summaries: [
          const EmbeddedSummary(
              id: 's1', type: 'overview', content: 'Summary text')
        ],
      );
      expect(data.isNotEmpty, isTrue);
    });

    test('isNotEmpty returns true when policies is non-empty', () {
      final data = EmbeddedFactGraphData(
        policies: [
          const EmbeddedPolicy(
              id: 'p1', name: 'policy', type: 'retention')
        ],
      );
      expect(data.isNotEmpty, isTrue);
    });

    test('roundtrip fromJson/toJson with all sections populated', () {
      final json = <String, dynamic>{
        'entities': [
          {'id': 'e1', 'type': 'person', 'name': 'Alice'}
        ],
        'facts': [
          {'id': 'f1', 'type': 'age', 'entityId': 'e1', 'value': 30}
        ],
        'relations': [
          {
            'id': 'r1',
            'type': 'works_at',
            'fromEntityId': 'e1',
            'toEntityId': 'e2',
          }
        ],
        'summaries': [
          {'id': 's1', 'type': 'bio', 'content': 'Alice is 30'}
        ],
        'policies': [
          {'id': 'p1', 'name': 'retention', 'type': 'data'}
        ],
      };

      final data = EmbeddedFactGraphData.fromJson(json);
      final restored = EmbeddedFactGraphData.fromJson(data.toJson());

      expect(restored.entities.length, equals(1));
      expect(restored.facts.length, equals(1));
      expect(restored.relations.length, equals(1));
      expect(restored.summaries.length, equals(1));
      expect(restored.policies.length, equals(1));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 4. EmbeddedEntity
  // ─────────────────────────────────────────────────────────────────────
  group('EmbeddedEntity', () {
    test('fromJson with minimal fields', () {
      final entity = EmbeddedEntity.fromJson(const {
        'id': 'e1',
        'type': 'person',
      });

      expect(entity.id, equals('e1'));
      expect(entity.type, equals('person'));
      expect(entity.name, isNull);
      expect(entity.properties, isEmpty);
      expect(entity.sourceId, isNull);
      expect(entity.createdAt, isNull);
      expect(entity.updatedAt, isNull);
      expect(entity.metadata, isEmpty);
    });

    test('fromJson with all fields', () {
      final entity = EmbeddedEntity.fromJson(const {
        'id': 'e1',
        'type': 'person',
        'name': 'Alice',
        'properties': {'role': 'engineer'},
        'sourceId': 'src-1',
        'createdAt': '2024-01-15T10:00:00.000Z',
        'updatedAt': '2024-06-20T14:30:00.000Z',
        'metadata': {'origin': 'import'},
      });

      expect(entity.name, equals('Alice'));
      expect(entity.properties['role'], equals('engineer'));
      expect(entity.sourceId, equals('src-1'));
      expect(entity.createdAt, equals(DateTime.utc(2024, 1, 15, 10, 0, 0)));
      expect(entity.updatedAt, equals(DateTime.utc(2024, 6, 20, 14, 30, 0)));
      expect(entity.metadata['origin'], equals('import'));
    });

    test('toJson omits null and empty fields', () {
      const entity = EmbeddedEntity(id: 'e1', type: 'person');
      final json = entity.toJson();

      expect(json['id'], equals('e1'));
      expect(json['type'], equals('person'));
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('properties'), isFalse);
      expect(json.containsKey('sourceId'), isFalse);
      expect(json.containsKey('createdAt'), isFalse);
      expect(json.containsKey('updatedAt'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('toJson includes all populated fields', () {
      final entity = EmbeddedEntity(
        id: 'e1',
        type: 'person',
        name: 'Bob',
        properties: const {'age': 25},
        sourceId: 'doc-1',
        createdAt: DateTime.utc(2024, 3, 1),
        updatedAt: DateTime.utc(2024, 3, 2),
        metadata: const {'quality': 'high'},
      );
      final json = entity.toJson();

      expect(json['name'], equals('Bob'));
      expect(json['properties'], equals({'age': 25}));
      expect(json['sourceId'], equals('doc-1'));
      expect(json['createdAt'], equals('2024-03-01T00:00:00.000Z'));
      expect(json['updatedAt'], equals('2024-03-02T00:00:00.000Z'));
      expect(json['metadata'], equals({'quality': 'high'}));
    });

    test('roundtrip fromJson/toJson preserves all fields', () {
      final original = EmbeddedEntity(
        id: 'e2',
        type: 'org',
        name: 'Acme',
        properties: const {'industry': 'tech'},
        sourceId: 'src-2',
        createdAt: DateTime.utc(2024, 5, 10, 8, 0),
        updatedAt: DateTime.utc(2024, 5, 11, 9, 0),
        metadata: const {'confidence': 0.95},
      );

      final restored = EmbeddedEntity.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.type, equals(original.type));
      expect(restored.name, equals(original.name));
      expect(restored.properties, equals(original.properties));
      expect(restored.sourceId, equals(original.sourceId));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.updatedAt, equals(original.updatedAt));
      expect(restored.metadata, equals(original.metadata));
    });

    test('copyWith replaces selected fields', () {
      const original = EmbeddedEntity(
        id: 'e1',
        type: 'person',
        name: 'Alice',
      );

      final copy = original.copyWith(name: 'Bob', type: 'user');

      expect(copy.id, equals('e1'));
      expect(copy.type, equals('user'));
      expect(copy.name, equals('Bob'));
    });

    test('copyWith with DateTime fields', () {
      const original = EmbeddedEntity(id: 'e1', type: 'x');
      final now = DateTime.utc(2025, 1, 1);
      final copy = original.copyWith(createdAt: now, updatedAt: now);

      expect(copy.createdAt, equals(now));
      expect(copy.updatedAt, equals(now));
    });

    test('fromJson defaults id and type to empty string when missing', () {
      final entity = EmbeddedEntity.fromJson(const <String, dynamic>{});

      expect(entity.id, equals(''));
      expect(entity.type, equals(''));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 5. EmbeddedFact
  // ─────────────────────────────────────────────────────────────────────
  group('EmbeddedFact', () {
    test('fromJson with minimal fields and default confidence', () {
      final fact = EmbeddedFact.fromJson(const {
        'id': 'f1',
        'type': 'name',
        'entityId': 'e1',
        'value': 'Alice',
      });

      expect(fact.id, equals('f1'));
      expect(fact.type, equals('name'));
      expect(fact.entityId, equals('e1'));
      expect(fact.value, equals('Alice'));
      expect(fact.confidence, equals(1.0));
      expect(fact.sourceId, isNull);
      expect(fact.evidenceRefs, isEmpty);
      expect(fact.validFrom, isNull);
      expect(fact.validUntil, isNull);
      expect(fact.createdAt, isNull);
      expect(fact.metadata, isEmpty);
    });

    test('fromJson with all fields', () {
      final fact = EmbeddedFact.fromJson(const {
        'id': 'f1',
        'type': 'age',
        'entityId': 'e1',
        'value': 30,
        'confidence': 0.85,
        'sourceId': 'doc-1',
        'evidenceRefs': ['ev-1', 'ev-2'],
        'validFrom': '2024-01-01T00:00:00.000Z',
        'validUntil': '2025-12-31T23:59:59.000Z',
        'createdAt': '2024-06-01T12:00:00.000Z',
        'metadata': {'source': 'manual'},
      });

      expect(fact.confidence, equals(0.85));
      expect(fact.sourceId, equals('doc-1'));
      expect(fact.evidenceRefs, equals(['ev-1', 'ev-2']));
      expect(fact.validFrom, equals(DateTime.utc(2024, 1, 1)));
      expect(fact.validUntil,
          equals(DateTime.utc(2025, 12, 31, 23, 59, 59)));
      expect(fact.createdAt, equals(DateTime.utc(2024, 6, 1, 12)));
      expect(fact.metadata['source'], equals('manual'));
    });

    test('toJson omits confidence when it equals 1.0', () {
      const fact = EmbeddedFact(
        id: 'f1',
        type: 'name',
        entityId: 'e1',
        value: 'test',
      );
      final json = fact.toJson();

      expect(json.containsKey('confidence'), isFalse);
    });

    test('toJson includes confidence when not 1.0', () {
      const fact = EmbeddedFact(
        id: 'f1',
        type: 'name',
        entityId: 'e1',
        value: 'test',
        confidence: 0.7,
      );
      final json = fact.toJson();

      expect(json['confidence'], equals(0.7));
    });

    test('toJson omits empty evidenceRefs', () {
      const fact = EmbeddedFact(
        id: 'f1',
        type: 'x',
        entityId: 'e1',
        value: 'v',
      );
      expect(fact.toJson().containsKey('evidenceRefs'), isFalse);
    });

    test('toJson includes non-empty evidenceRefs', () {
      const fact = EmbeddedFact(
        id: 'f1',
        type: 'x',
        entityId: 'e1',
        value: 'v',
        evidenceRefs: ['ref-1'],
      );
      expect(fact.toJson()['evidenceRefs'], equals(['ref-1']));
    });

    test('roundtrip fromJson/toJson preserves all fields', () {
      final original = EmbeddedFact(
        id: 'f2',
        type: 'score',
        entityId: 'e2',
        value: 99.5,
        confidence: 0.92,
        sourceId: 'src-3',
        evidenceRefs: const ['ev-a', 'ev-b'],
        validFrom: DateTime.utc(2024, 1, 1),
        validUntil: DateTime.utc(2025, 1, 1),
        createdAt: DateTime.utc(2024, 3, 15),
        metadata: const {'tag': 'verified'},
      );

      final restored = EmbeddedFact.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.type, equals(original.type));
      expect(restored.entityId, equals(original.entityId));
      expect(restored.value, equals(original.value));
      expect(restored.confidence, equals(original.confidence));
      expect(restored.sourceId, equals(original.sourceId));
      expect(restored.evidenceRefs, equals(original.evidenceRefs));
      expect(restored.validFrom, equals(original.validFrom));
      expect(restored.validUntil, equals(original.validUntil));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.metadata, equals(original.metadata));
    });

    test('copyWith replaces selected fields', () {
      const original = EmbeddedFact(
        id: 'f1',
        type: 'name',
        entityId: 'e1',
        value: 'Alice',
        confidence: 0.8,
      );

      final copy = original.copyWith(value: 'Bob', confidence: 0.95);

      expect(copy.id, equals('f1'));
      expect(copy.value, equals('Bob'));
      expect(copy.confidence, equals(0.95));
      expect(copy.entityId, equals('e1'));
    });

    test('fromJson with numeric value', () {
      final fact = EmbeddedFact.fromJson(const {
        'id': 'f1',
        'type': 'count',
        'entityId': 'e1',
        'value': 42,
      });
      expect(fact.value, equals(42));
    });

    test('fromJson with map value', () {
      final fact = EmbeddedFact.fromJson(const {
        'id': 'f1',
        'type': 'address',
        'entityId': 'e1',
        'value': {'city': 'Seoul', 'country': 'KR'},
      });
      expect(fact.value, isA<Map<String, dynamic>>());
      expect((fact.value as Map<String, dynamic>)['city'], equals('Seoul'));
    });

    test('fromJson with null value', () {
      final fact = EmbeddedFact.fromJson(const {
        'id': 'f1',
        'type': 'optional',
        'entityId': 'e1',
      });
      expect(fact.value, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 6. EmbeddedRelation
  // ─────────────────────────────────────────────────────────────────────
  group('EmbeddedRelation', () {
    test('fromJson with fromEntityId/toEntityId keys', () {
      final rel = EmbeddedRelation.fromJson(const {
        'id': 'r1',
        'type': 'knows',
        'fromEntityId': 'e1',
        'toEntityId': 'e2',
      });

      expect(rel.fromEntityId, equals('e1'));
      expect(rel.toEntityId, equals('e2'));
    });

    test('fromJson with "from"/"to" alternative keys', () {
      final rel = EmbeddedRelation.fromJson(const {
        'id': 'r1',
        'type': 'knows',
        'from': 'e1',
        'to': 'e2',
      });

      expect(rel.fromEntityId, equals('e1'));
      expect(rel.toEntityId, equals('e2'));
    });

    test('fromJson prefers fromEntityId over from', () {
      final rel = EmbeddedRelation.fromJson(const {
        'id': 'r1',
        'type': 'knows',
        'fromEntityId': 'preferred',
        'from': 'fallback',
        'toEntityId': 'preferred-to',
        'to': 'fallback-to',
      });

      expect(rel.fromEntityId, equals('preferred'));
      expect(rel.toEntityId, equals('preferred-to'));
    });

    test('fromJson with default confidence 1.0', () {
      final rel = EmbeddedRelation.fromJson(const {
        'id': 'r1',
        'type': 'knows',
        'fromEntityId': 'e1',
        'toEntityId': 'e2',
      });

      expect(rel.confidence, equals(1.0));
    });

    test('fromJson with all fields', () {
      final rel = EmbeddedRelation.fromJson(const {
        'id': 'r1',
        'type': 'employs',
        'fromEntityId': 'org1',
        'toEntityId': 'person1',
        'properties': {'since': '2020'},
        'confidence': 0.9,
        'sourceId': 'hr-system',
        'createdAt': '2024-02-01T08:00:00.000Z',
        'metadata': {'verified': true},
      });

      expect(rel.properties['since'], equals('2020'));
      expect(rel.confidence, equals(0.9));
      expect(rel.sourceId, equals('hr-system'));
      expect(rel.createdAt, equals(DateTime.utc(2024, 2, 1, 8)));
      expect(rel.metadata['verified'], isTrue);
    });

    test('toJson uses fromEntityId/toEntityId keys', () {
      const rel = EmbeddedRelation(
        id: 'r1',
        type: 'knows',
        fromEntityId: 'e1',
        toEntityId: 'e2',
      );
      final json = rel.toJson();

      expect(json['fromEntityId'], equals('e1'));
      expect(json['toEntityId'], equals('e2'));
      // Should not contain the alternative keys
      expect(json.containsKey('from'), isFalse);
      expect(json.containsKey('to'), isFalse);
    });

    test('toJson omits confidence when 1.0', () {
      const rel = EmbeddedRelation(
        id: 'r1',
        type: 'knows',
        fromEntityId: 'e1',
        toEntityId: 'e2',
      );
      expect(rel.toJson().containsKey('confidence'), isFalse);
    });

    test('toJson includes confidence when not 1.0', () {
      const rel = EmbeddedRelation(
        id: 'r1',
        type: 'knows',
        fromEntityId: 'e1',
        toEntityId: 'e2',
        confidence: 0.5,
      );
      expect(rel.toJson()['confidence'], equals(0.5));
    });

    test('roundtrip fromJson/toJson preserves all fields', () {
      final original = EmbeddedRelation(
        id: 'r2',
        type: 'parent_of',
        fromEntityId: 'p1',
        toEntityId: 'c1',
        properties: const {'legal': true},
        confidence: 0.99,
        sourceId: 'civil-reg',
        createdAt: DateTime.utc(2024, 4, 10),
        metadata: const {'source_type': 'official'},
      );

      final restored = EmbeddedRelation.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.type, equals(original.type));
      expect(restored.fromEntityId, equals(original.fromEntityId));
      expect(restored.toEntityId, equals(original.toEntityId));
      expect(restored.properties, equals(original.properties));
      expect(restored.confidence, equals(original.confidence));
      expect(restored.sourceId, equals(original.sourceId));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.metadata, equals(original.metadata));
    });

    test('copyWith replaces selected fields', () {
      const original = EmbeddedRelation(
        id: 'r1',
        type: 'knows',
        fromEntityId: 'e1',
        toEntityId: 'e2',
        confidence: 0.8,
      );

      final copy =
          original.copyWith(toEntityId: 'e3', confidence: 0.95);

      expect(copy.id, equals('r1'));
      expect(copy.fromEntityId, equals('e1'));
      expect(copy.toEntityId, equals('e3'));
      expect(copy.confidence, equals(0.95));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 7. EmbeddedSummary
  // ─────────────────────────────────────────────────────────────────────
  group('EmbeddedSummary', () {
    test('fromJson with minimal fields', () {
      final summary = EmbeddedSummary.fromJson(const {
        'id': 's1',
        'type': 'overview',
        'content': 'Brief summary.',
      });

      expect(summary.id, equals('s1'));
      expect(summary.type, equals('overview'));
      expect(summary.content, equals('Brief summary.'));
      expect(summary.entityId, isNull);
      expect(summary.sourceFactIds, isEmpty);
      expect(summary.generatedAt, isNull);
      expect(summary.confidence, equals(1.0));
      expect(summary.metadata, isEmpty);
    });

    test('fromJson with all fields', () {
      final summary = EmbeddedSummary.fromJson(const {
        'id': 's1',
        'type': 'profile',
        'entityId': 'e1',
        'content': 'Alice is an engineer.',
        'sourceFactIds': ['f1', 'f2', 'f3'],
        'generatedAt': '2024-07-01T00:00:00.000Z',
        'confidence': 0.88,
        'metadata': {'model': 'gpt-4'},
      });

      expect(summary.entityId, equals('e1'));
      expect(summary.sourceFactIds, equals(['f1', 'f2', 'f3']));
      expect(summary.generatedAt, equals(DateTime.utc(2024, 7, 1)));
      expect(summary.confidence, equals(0.88));
      expect(summary.metadata['model'], equals('gpt-4'));
    });

    test('toJson omits confidence when 1.0', () {
      const summary = EmbeddedSummary(
        id: 's1',
        type: 'overview',
        content: 'text',
      );
      expect(summary.toJson().containsKey('confidence'), isFalse);
    });

    test('toJson includes confidence when not 1.0', () {
      const summary = EmbeddedSummary(
        id: 's1',
        type: 'overview',
        content: 'text',
        confidence: 0.75,
      );
      expect(summary.toJson()['confidence'], equals(0.75));
    });

    test('toJson omits empty sourceFactIds', () {
      const summary = EmbeddedSummary(
        id: 's1',
        type: 'overview',
        content: 'text',
      );
      expect(summary.toJson().containsKey('sourceFactIds'), isFalse);
    });

    test('roundtrip fromJson/toJson preserves all fields', () {
      final original = EmbeddedSummary(
        id: 's2',
        type: 'digest',
        entityId: 'e5',
        content: 'Detailed digest of entity e5.',
        sourceFactIds: const ['f10', 'f11'],
        generatedAt: DateTime.utc(2024, 8, 15, 16, 30),
        confidence: 0.91,
        metadata: const {'version': 2},
      );

      final restored = EmbeddedSummary.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.type, equals(original.type));
      expect(restored.entityId, equals(original.entityId));
      expect(restored.content, equals(original.content));
      expect(restored.sourceFactIds, equals(original.sourceFactIds));
      expect(restored.generatedAt, equals(original.generatedAt));
      expect(restored.confidence, equals(original.confidence));
      expect(restored.metadata, equals(original.metadata));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 8. EmbeddedPolicy
  // ─────────────────────────────────────────────────────────────────────
  group('EmbeddedPolicy', () {
    test('fromJson with minimal fields', () {
      final policy = EmbeddedPolicy.fromJson(const {
        'id': 'p1',
        'name': 'retention',
        'type': 'data',
      });

      expect(policy.id, equals('p1'));
      expect(policy.name, equals('retention'));
      expect(policy.type, equals('data'));
      expect(policy.rules, isEmpty);
      expect(policy.priority, equals(0));
      expect(policy.enabled, isTrue);
      expect(policy.metadata, isEmpty);
    });

    test('fromJson with all fields', () {
      final policy = EmbeddedPolicy.fromJson(const {
        'id': 'p1',
        'name': 'access-control',
        'type': 'security',
        'rules': [
          {
            'id': 'rule-1',
            'condition': 'entity.type == "secret"',
            'action': 'deny',
          }
        ],
        'priority': 10,
        'enabled': false,
        'metadata': {'author': 'admin'},
      });

      expect(policy.rules.length, equals(1));
      expect(policy.rules.first.id, equals('rule-1'));
      expect(policy.priority, equals(10));
      expect(policy.enabled, isFalse);
      expect(policy.metadata['author'], equals('admin'));
    });

    test('toJson omits rules when empty', () {
      const policy = EmbeddedPolicy(
        id: 'p1',
        name: 'empty',
        type: 'test',
      );
      expect(policy.toJson().containsKey('rules'), isFalse);
    });

    test('toJson omits priority when 0', () {
      const policy = EmbeddedPolicy(
        id: 'p1',
        name: 'default-priority',
        type: 'test',
      );
      expect(policy.toJson().containsKey('priority'), isFalse);
    });

    test('toJson omits enabled when true (default)', () {
      const policy = EmbeddedPolicy(
        id: 'p1',
        name: 'enabled-policy',
        type: 'test',
      );
      expect(policy.toJson().containsKey('enabled'), isFalse);
    });

    test('toJson includes enabled when false', () {
      const policy = EmbeddedPolicy(
        id: 'p1',
        name: 'disabled-policy',
        type: 'test',
        enabled: false,
      );
      expect(policy.toJson()['enabled'], isFalse);
    });

    test('toJson includes priority when non-zero', () {
      const policy = EmbeddedPolicy(
        id: 'p1',
        name: 'high-priority',
        type: 'test',
        priority: 5,
      );
      expect(policy.toJson()['priority'], equals(5));
    });

    test('roundtrip fromJson/toJson preserves all fields', () {
      const original = EmbeddedPolicy(
        id: 'p2',
        name: 'complex-policy',
        type: 'composite',
        rules: [
          EmbeddedPolicyRule(
            id: 'rule-a',
            condition: 'fact.confidence < 0.5',
            action: 'flag',
            parameters: {'severity': 'warning'},
          ),
        ],
        priority: 3,
        enabled: false,
        metadata: {'scope': 'global'},
      );

      final restored = EmbeddedPolicy.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.type, equals(original.type));
      expect(restored.rules.length, equals(1));
      expect(restored.rules.first.id, equals('rule-a'));
      expect(restored.priority, equals(original.priority));
      expect(restored.enabled, equals(original.enabled));
      expect(restored.metadata, equals(original.metadata));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 9. EmbeddedPolicyRule
  // ─────────────────────────────────────────────────────────────────────
  group('EmbeddedPolicyRule', () {
    test('fromJson with required fields', () {
      final rule = EmbeddedPolicyRule.fromJson(const {
        'id': 'rule-1',
        'condition': 'entity.type == "person"',
        'action': 'allow',
      });

      expect(rule.id, equals('rule-1'));
      expect(rule.condition, equals('entity.type == "person"'));
      expect(rule.action, equals('allow'));
      expect(rule.parameters, isEmpty);
    });

    test('fromJson with parameters', () {
      final rule = EmbeddedPolicyRule.fromJson(const {
        'id': 'rule-2',
        'condition': 'fact.age > 18',
        'action': 'tag',
        'parameters': {'tag': 'adult', 'priority': 1},
      });

      expect(rule.parameters['tag'], equals('adult'));
      expect(rule.parameters['priority'], equals(1));
    });

    test('toJson omits empty parameters', () {
      const rule = EmbeddedPolicyRule(
        id: 'rule-1',
        condition: 'true',
        action: 'noop',
      );
      expect(rule.toJson().containsKey('parameters'), isFalse);
    });

    test('toJson includes non-empty parameters', () {
      const rule = EmbeddedPolicyRule(
        id: 'rule-1',
        condition: 'true',
        action: 'log',
        parameters: {'level': 'info'},
      );
      expect(rule.toJson()['parameters'], equals({'level': 'info'}));
    });

    test('roundtrip fromJson/toJson', () {
      const original = EmbeddedPolicyRule(
        id: 'rule-x',
        condition: 'relation.type == "owns"',
        action: 'propagate',
        parameters: {'depth': 3, 'cascade': true},
      );

      final restored = EmbeddedPolicyRule.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.condition, equals(original.condition));
      expect(restored.action, equals(original.action));
      expect(restored.parameters, equals(original.parameters));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 10. ExternalFactGraphRef
  // ─────────────────────────────────────────────────────────────────────
  group('ExternalFactGraphRef', () {
    test('fromJson with uri only', () {
      final ref = ExternalFactGraphRef.fromJson(const {
        'uri': 'https://fg.example.com',
      });

      expect(ref.uri, equals('https://fg.example.com'));
      expect(ref.namespace, isNull);
      expect(ref.authentication, isNull);
      expect(ref.syncPolicy, isNull);
    });

    test('fromJson with all fields', () {
      final ref = ExternalFactGraphRef.fromJson(const {
        'uri': 'https://fg.example.com/api',
        'namespace': 'production',
        'authentication': {'type': 'bearer', 'token': 'abc123'},
        'syncPolicy': {
          'mode': 'periodic',
          'intervalMs': 60000,
          'conflictResolution': 'merge',
        },
      });

      expect(ref.namespace, equals('production'));
      expect(ref.authentication!['type'], equals('bearer'));
      expect(ref.syncPolicy, isNotNull);
      expect(ref.syncPolicy!.mode, equals('periodic'));
    });

    test('toJson omits null fields', () {
      const ref = ExternalFactGraphRef(uri: 'https://fg.example.com');
      final json = ref.toJson();

      expect(json['uri'], equals('https://fg.example.com'));
      expect(json.containsKey('namespace'), isFalse);
      expect(json.containsKey('authentication'), isFalse);
      expect(json.containsKey('syncPolicy'), isFalse);
    });

    test('roundtrip fromJson/toJson preserves all fields', () {
      const original = ExternalFactGraphRef(
        uri: 'https://fg.service.io',
        namespace: 'staging',
        authentication: {'type': 'apiKey', 'key': 'xyz'},
        syncPolicy: SyncPolicy(
          mode: 'realtime',
          conflictResolution: 'merge',
        ),
      );

      final restored = ExternalFactGraphRef.fromJson(original.toJson());

      expect(restored.uri, equals(original.uri));
      expect(restored.namespace, equals(original.namespace));
      expect(restored.authentication, equals(original.authentication));
      expect(restored.syncPolicy!.mode, equals('realtime'));
      expect(
          restored.syncPolicy!.conflictResolution, equals('merge'));
    });

    test('fromJson defaults uri to empty string when missing', () {
      final ref = ExternalFactGraphRef.fromJson(const <String, dynamic>{});
      expect(ref.uri, equals(''));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 11. SyncPolicy
  // ─────────────────────────────────────────────────────────────────────
  group('SyncPolicy', () {
    test('fromJson with defaults', () {
      final policy = SyncPolicy.fromJson(const <String, dynamic>{});

      expect(policy.mode, equals('manual'));
      expect(policy.interval, isNull);
      expect(policy.conflictResolution, equals('lastWriteWins'));
    });

    test('fromJson with all fields and intervalMs conversion', () {
      final policy = SyncPolicy.fromJson(const {
        'mode': 'periodic',
        'intervalMs': 30000,
        'conflictResolution': 'merge',
      });

      expect(policy.mode, equals('periodic'));
      expect(policy.interval, equals(const Duration(milliseconds: 30000)));
      expect(policy.interval!.inSeconds, equals(30));
      expect(policy.conflictResolution, equals('merge'));
    });

    test('toJson converts interval Duration to intervalMs', () {
      const policy = SyncPolicy(
        mode: 'periodic',
        interval: Duration(seconds: 120),
        conflictResolution: 'lastWriteWins',
      );
      final json = policy.toJson();

      expect(json['intervalMs'], equals(120000));
      expect(json.containsKey('interval'), isFalse);
    });

    test('toJson omits intervalMs when interval is null', () {
      const policy = SyncPolicy(mode: 'manual');
      final json = policy.toJson();

      expect(json.containsKey('intervalMs'), isFalse);
      expect(json['mode'], equals('manual'));
    });

    test('toJson always includes mode and conflictResolution', () {
      const policy = SyncPolicy();
      final json = policy.toJson();

      expect(json['mode'], equals('manual'));
      expect(json['conflictResolution'], equals('lastWriteWins'));
    });

    test('roundtrip fromJson/toJson preserves all fields', () {
      const original = SyncPolicy(
        mode: 'periodic',
        interval: Duration(minutes: 5),
        conflictResolution: 'sourceWins',
      );

      final restored = SyncPolicy.fromJson(original.toJson());

      expect(restored.mode, equals(original.mode));
      expect(restored.interval, equals(original.interval));
      expect(restored.conflictResolution,
          equals(original.conflictResolution));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 12. ExtractionConfig
  // ─────────────────────────────────────────────────────────────────────
  group('ExtractionConfig', () {
    test('fromJson with empty JSON returns empty lists', () {
      final config =
          ExtractionConfig.fromJson(const <String, dynamic>{});

      expect(config.rules, isEmpty);
      expect(config.validators, isEmpty);
    });

    test('toJson with empty lists returns empty map', () {
      const config = ExtractionConfig();
      expect(config.toJson(), isEmpty);
    });

    test('fromJson with rules', () {
      final config = ExtractionConfig.fromJson(const {
        'rules': [
          {
            'id': 'r1',
            'sourceType': 'text',
            'targetType': 'entity',
            'pattern': r'\b[A-Z]\w+',
          }
        ],
      });

      expect(config.rules.length, equals(1));
      expect(config.rules.first.id, equals('r1'));
    });

    test('fromJson with validators', () {
      final config = ExtractionConfig.fromJson(const {
        'validators': [
          {
            'id': 'v1',
            'targetType': 'entity',
            'rules': [
              {'field': 'name', 'type': 'required'}
            ],
          }
        ],
      });

      expect(config.validators.length, equals(1));
      expect(config.validators.first.id, equals('v1'));
    });

    test('roundtrip fromJson/toJson with rules and validators', () {
      final json = <String, dynamic>{
        'rules': [
          {
            'id': 'r1',
            'sourceType': 'doc',
            'targetType': 'fact',
            'pattern': '.*',
          }
        ],
        'validators': [
          {
            'id': 'v1',
            'targetType': 'fact',
          }
        ],
      };

      final config = ExtractionConfig.fromJson(json);
      final restored = ExtractionConfig.fromJson(config.toJson());

      expect(restored.rules.length, equals(1));
      expect(restored.validators.length, equals(1));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 13. ExtractionRule
  // ─────────────────────────────────────────────────────────────────────
  group('ExtractionRule', () {
    test('fromJson with required fields and default enabled', () {
      final rule = ExtractionRule.fromJson(const {
        'id': 'r1',
        'sourceType': 'text',
        'targetType': 'entity',
        'pattern': r'(?i)\b(person|org)\b',
      });

      expect(rule.id, equals('r1'));
      expect(rule.sourceType, equals('text'));
      expect(rule.targetType, equals('entity'));
      expect(rule.pattern, equals(r'(?i)\b(person|org)\b'));
      expect(rule.mapping, isEmpty);
      expect(rule.enabled, isTrue);
    });

    test('fromJson with all fields', () {
      final rule = ExtractionRule.fromJson(const {
        'id': 'r2',
        'sourceType': 'csv',
        'targetType': 'fact',
        'pattern': 'column:age',
        'mapping': {'source': 'age', 'target': 'person.age'},
        'enabled': false,
      });

      expect(rule.mapping['source'], equals('age'));
      expect(rule.enabled, isFalse);
    });

    test('toJson omits enabled when true (default)', () {
      const rule = ExtractionRule(
        id: 'r1',
        sourceType: 'text',
        targetType: 'entity',
        pattern: '.*',
      );
      expect(rule.toJson().containsKey('enabled'), isFalse);
    });

    test('toJson includes enabled when false', () {
      const rule = ExtractionRule(
        id: 'r1',
        sourceType: 'text',
        targetType: 'entity',
        pattern: '.*',
        enabled: false,
      );
      expect(rule.toJson()['enabled'], isFalse);
    });

    test('toJson omits empty mapping', () {
      const rule = ExtractionRule(
        id: 'r1',
        sourceType: 'text',
        targetType: 'entity',
        pattern: '.*',
      );
      expect(rule.toJson().containsKey('mapping'), isFalse);
    });

    test('roundtrip fromJson/toJson preserves all fields', () {
      const original = ExtractionRule(
        id: 'r3',
        sourceType: 'json',
        targetType: 'relation',
        pattern: r'$.relationships[*]',
        mapping: {'from': 'source', 'to': 'target'},
        enabled: false,
      );

      final restored = ExtractionRule.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.sourceType, equals(original.sourceType));
      expect(restored.targetType, equals(original.targetType));
      expect(restored.pattern, equals(original.pattern));
      expect(restored.mapping, equals(original.mapping));
      expect(restored.enabled, equals(original.enabled));
    });

    test('fromJson defaults all strings to empty when missing', () {
      final rule = ExtractionRule.fromJson(const <String, dynamic>{});
      expect(rule.id, equals(''));
      expect(rule.sourceType, equals(''));
      expect(rule.targetType, equals(''));
      expect(rule.pattern, equals(''));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 14. ExtractionValidator
  // ─────────────────────────────────────────────────────────────────────
  group('ExtractionValidator', () {
    test('fromJson with minimal fields', () {
      final validator = ExtractionValidator.fromJson(const {
        'id': 'v1',
        'targetType': 'entity',
      });

      expect(validator.id, equals('v1'));
      expect(validator.targetType, equals('entity'));
      expect(validator.rules, isEmpty);
    });

    test('fromJson with rules', () {
      final validator = ExtractionValidator.fromJson(const {
        'id': 'v1',
        'targetType': 'fact',
        'rules': [
          {'field': 'value', 'type': 'required'},
          {'field': 'confidence', 'type': 'range', 'value': '0-1'},
        ],
      });

      expect(validator.rules.length, equals(2));
      expect(validator.rules[0].field, equals('value'));
      expect(validator.rules[1].type, equals('range'));
    });

    test('toJson omits empty rules', () {
      const validator = ExtractionValidator(
        id: 'v1',
        targetType: 'entity',
      );
      expect(validator.toJson().containsKey('rules'), isFalse);
    });

    test('roundtrip fromJson/toJson preserves all fields', () {
      const original = ExtractionValidator(
        id: 'v2',
        targetType: 'relation',
        rules: [
          ValidationRule(
            field: 'fromEntityId',
            type: 'required',
            message: 'Source entity is required',
          ),
          ValidationRule(
            field: 'confidence',
            type: 'range',
            value: {'min': 0.0, 'max': 1.0},
          ),
        ],
      );

      final restored =
          ExtractionValidator.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.targetType, equals(original.targetType));
      expect(restored.rules.length, equals(2));
      expect(restored.rules[0].field, equals('fromEntityId'));
      expect(restored.rules[0].message,
          equals('Source entity is required'));
      expect(restored.rules[1].value, isA<Map<String, dynamic>>());
    });

    test('fromJson defaults to empty strings when missing', () {
      final validator =
          ExtractionValidator.fromJson(const <String, dynamic>{});
      expect(validator.id, equals(''));
      expect(validator.targetType, equals(''));
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // 15. ValidationRule
  // ─────────────────────────────────────────────────────────────────────
  group('ValidationRule', () {
    test('fromJson with required fields only', () {
      final rule = ValidationRule.fromJson(const {
        'field': 'name',
        'type': 'required',
      });

      expect(rule.field, equals('name'));
      expect(rule.type, equals('required'));
      expect(rule.value, isNull);
      expect(rule.message, isNull);
    });

    test('fromJson with all fields', () {
      final rule = ValidationRule.fromJson(const {
        'field': 'email',
        'type': 'pattern',
        'value': r'^[\w.]+@[\w.]+$',
        'message': 'Invalid email format',
      });

      expect(rule.field, equals('email'));
      expect(rule.type, equals('pattern'));
      expect(rule.value, equals(r'^[\w.]+@[\w.]+$'));
      expect(rule.message, equals('Invalid email format'));
    });

    test('fromJson with numeric value', () {
      final rule = ValidationRule.fromJson(const {
        'field': 'age',
        'type': 'range',
        'value': 100,
      });
      expect(rule.value, equals(100));
    });

    test('fromJson with map value', () {
      final rule = ValidationRule.fromJson(const {
        'field': 'score',
        'type': 'range',
        'value': {'min': 0, 'max': 100},
      });
      expect(rule.value, isA<Map<String, dynamic>>());
      expect((rule.value as Map<String, dynamic>)['min'], equals(0));
    });

    test('toJson omits null value and message', () {
      const rule = ValidationRule(field: 'name', type: 'required');
      final json = rule.toJson();

      expect(json['field'], equals('name'));
      expect(json['type'], equals('required'));
      expect(json.containsKey('value'), isFalse);
      expect(json.containsKey('message'), isFalse);
    });

    test('toJson includes value and message when present', () {
      const rule = ValidationRule(
        field: 'count',
        type: 'range',
        value: 50,
        message: 'Count must be within range',
      );
      final json = rule.toJson();

      expect(json['value'], equals(50));
      expect(json['message'], equals('Count must be within range'));
    });

    test('roundtrip fromJson/toJson preserves all fields', () {
      const original = ValidationRule(
        field: 'confidence',
        type: 'range',
        value: {'min': 0.0, 'max': 1.0},
        message: 'Confidence must be between 0 and 1',
      );

      final restored = ValidationRule.fromJson(original.toJson());

      expect(restored.field, equals(original.field));
      expect(restored.type, equals(original.type));
      expect(restored.value, equals(original.value));
      expect(restored.message, equals(original.message));
    });

    test('fromJson defaults field and type to empty string', () {
      final rule = ValidationRule.fromJson(const <String, dynamic>{});
      expect(rule.field, equals(''));
      expect(rule.type, equals(''));
    });
  });
}
