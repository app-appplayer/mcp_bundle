import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  // ---------------------------------------------------------------------------
  // 1. FactGraphSchema
  // ---------------------------------------------------------------------------
  group('FactGraphSchema', () {
    group('fromJson / toJson', () {
      test('round-trip with all fields populated', () {
        final json = {
          'entityTypes': [
            {'name': 'Person', 'description': 'A person entity'},
          ],
          'relationTypes': [
            {
              'name': 'worksFor',
              'fromEntityType': 'Person',
              'toEntityType': 'Organization',
            },
          ],
          'factTypes': [
            {'name': 'birthDate', 'valueType': 'date'},
          ],
        };

        final schema = FactGraphSchema.fromJson(json);
        final output = schema.toJson();

        expect(schema.entityTypes, hasLength(1));
        expect(schema.entityTypes.first.name, 'Person');
        expect(schema.relationTypes, hasLength(1));
        expect(schema.relationTypes.first.name, 'worksFor');
        expect(schema.factTypes, hasLength(1));
        expect(schema.factTypes.first.name, 'birthDate');

        // Verify round-trip produces equivalent structure
        final restored = FactGraphSchema.fromJson(output);
        expect(restored.entityTypes.first.name, 'Person');
        expect(restored.relationTypes.first.name, 'worksFor');
        expect(restored.factTypes.first.name, 'birthDate');
      });

      test('fromJson with empty map yields empty lists', () {
        final schema = FactGraphSchema.fromJson({});
        expect(schema.entityTypes, isEmpty);
        expect(schema.relationTypes, isEmpty);
        expect(schema.factTypes, isEmpty);
      });

      test('toJson omits empty lists', () {
        const schema = FactGraphSchema();
        final json = schema.toJson();
        expect(json.containsKey('entityTypes'), isFalse);
        expect(json.containsKey('relationTypes'), isFalse);
        expect(json.containsKey('factTypes'), isFalse);
      });
    });

    group('findEntityType', () {
      test('returns matching entity type', () {
        const schema = FactGraphSchema(
          entityTypes: [
            EntityTypeDefinition(name: 'Person'),
            EntityTypeDefinition(name: 'Organization'),
          ],
        );
        final result = schema.findEntityType('Organization');
        expect(result, isNotNull);
        expect(result!.name, 'Organization');
      });

      test('returns null when not found', () {
        const schema = FactGraphSchema(
          entityTypes: [EntityTypeDefinition(name: 'Person')],
        );
        expect(schema.findEntityType('Unknown'), isNull);
      });
    });

    group('findRelationType', () {
      test('returns matching relation type', () {
        const schema = FactGraphSchema(
          relationTypes: [
            RelationTypeDefinition(
              name: 'worksFor',
              fromEntityType: 'Person',
              toEntityType: 'Organization',
            ),
          ],
        );
        final result = schema.findRelationType('worksFor');
        expect(result, isNotNull);
        expect(result!.name, 'worksFor');
      });

      test('returns null when not found', () {
        const schema = FactGraphSchema();
        expect(schema.findRelationType('missing'), isNull);
      });
    });

    group('findFactType', () {
      test('returns matching fact type', () {
        const schema = FactGraphSchema(
          factTypes: [FactTypeDefinition(name: 'birthDate', valueType: 'date')],
        );
        final result = schema.findFactType('birthDate');
        expect(result, isNotNull);
        expect(result!.name, 'birthDate');
      });

      test('returns null when not found', () {
        const schema = FactGraphSchema();
        expect(schema.findFactType('unknown'), isNull);
      });
    });

    group('isEmpty / isNotEmpty', () {
      test('empty schema is isEmpty', () {
        const schema = FactGraphSchema();
        expect(schema.isEmpty, isTrue);
        expect(schema.isNotEmpty, isFalse);
      });

      test('schema with entity types is not empty', () {
        const schema = FactGraphSchema(
          entityTypes: [EntityTypeDefinition(name: 'X')],
        );
        expect(schema.isEmpty, isFalse);
        expect(schema.isNotEmpty, isTrue);
      });

      test('schema with only relation types is not empty', () {
        const schema = FactGraphSchema(
          relationTypes: [
            RelationTypeDefinition(
              name: 'r',
              fromEntityType: 'A',
              toEntityType: 'B',
            ),
          ],
        );
        expect(schema.isNotEmpty, isTrue);
      });

      test('schema with only fact types is not empty', () {
        const schema = FactGraphSchema(
          factTypes: [FactTypeDefinition(name: 'f', valueType: 'string')],
        );
        expect(schema.isNotEmpty, isTrue);
      });
    });

    group('copyWith', () {
      test('copies with new entity types', () {
        const original = FactGraphSchema(
          entityTypes: [EntityTypeDefinition(name: 'A')],
        );
        final copied = original.copyWith(
          entityTypes: [const EntityTypeDefinition(name: 'B')],
        );
        expect(copied.entityTypes.first.name, 'B');
        // Original unchanged
        expect(original.entityTypes.first.name, 'A');
      });

      test('preserves fields not specified in copyWith', () {
        const original = FactGraphSchema(
          entityTypes: [EntityTypeDefinition(name: 'A')],
          factTypes: [FactTypeDefinition(name: 'f', valueType: 'string')],
        );
        final copied = original.copyWith(
          relationTypes: [
            const RelationTypeDefinition(
              name: 'r',
              fromEntityType: 'X',
              toEntityType: 'Y',
            ),
          ],
        );
        expect(copied.entityTypes.first.name, 'A');
        expect(copied.factTypes.first.name, 'f');
        expect(copied.relationTypes.first.name, 'r');
      });
    });

    test('default constructor creates empty schema', () {
      const schema = FactGraphSchema();
      expect(schema.entityTypes, isEmpty);
      expect(schema.relationTypes, isEmpty);
      expect(schema.factTypes, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. EntityTypeDefinition
  // ---------------------------------------------------------------------------
  group('EntityTypeDefinition', () {
    group('fromJson / toJson', () {
      test('round-trip with all fields', () {
        final json = {
          'name': 'Person',
          'description': 'Represents a person',
          'properties': [
            {'name': 'age', 'type': 'number'},
          ],
          'requiredProperties': ['age'],
          'extends': 'BaseEntity',
          'abstract': true,
        };

        final entity = EntityTypeDefinition.fromJson(json);
        expect(entity.name, 'Person');
        expect(entity.description, 'Represents a person');
        expect(entity.properties, hasLength(1));
        expect(entity.properties.first.name, 'age');
        expect(entity.requiredProperties, ['age']);
        expect(entity.extendsType, 'BaseEntity');
        expect(entity.isAbstract, isTrue);

        final output = entity.toJson();
        expect(output['name'], 'Person');
        expect(output['description'], 'Represents a person');
        expect(output['extends'], 'BaseEntity');
        expect(output['abstract'], true);
        expect(output['requiredProperties'], ['age']);

        // Round-trip
        final restored = EntityTypeDefinition.fromJson(output);
        expect(restored.name, 'Person');
        expect(restored.extendsType, 'BaseEntity');
        expect(restored.isAbstract, isTrue);
      });

      test('fromJson with minimal data uses defaults', () {
        final entity = EntityTypeDefinition.fromJson({});
        expect(entity.name, '');
        expect(entity.description, isNull);
        expect(entity.properties, isEmpty);
        expect(entity.requiredProperties, isEmpty);
        expect(entity.extendsType, isNull);
        expect(entity.isAbstract, isFalse);
      });

      test('toJson omits optional/empty fields', () {
        const entity = EntityTypeDefinition(name: 'Simple');
        final json = entity.toJson();
        expect(json['name'], 'Simple');
        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('properties'), isFalse);
        expect(json.containsKey('requiredProperties'), isFalse);
        expect(json.containsKey('extends'), isFalse);
        expect(json.containsKey('abstract'), isFalse);
      });
    });

    group('findProperty', () {
      test('returns matching property', () {
        const entity = EntityTypeDefinition(
          name: 'Person',
          properties: [
            PropertyDefinition(name: 'name', type: 'string'),
            PropertyDefinition(name: 'age', type: 'number'),
          ],
        );
        final prop = entity.findProperty('age');
        expect(prop, isNotNull);
        expect(prop!.name, 'age');
        expect(prop.type, 'number');
      });

      test('returns null when property not found', () {
        const entity = EntityTypeDefinition(
          name: 'Person',
          properties: [PropertyDefinition(name: 'name', type: 'string')],
        );
        expect(entity.findProperty('missing'), isNull);
      });
    });

    group('isPropertyRequired', () {
      test('returns true for required property', () {
        const entity = EntityTypeDefinition(
          name: 'Person',
          requiredProperties: ['name', 'email'],
        );
        expect(entity.isPropertyRequired('name'), isTrue);
        expect(entity.isPropertyRequired('email'), isTrue);
      });

      test('returns false for non-required property', () {
        const entity = EntityTypeDefinition(
          name: 'Person',
          requiredProperties: ['name'],
        );
        expect(entity.isPropertyRequired('age'), isFalse);
      });
    });

    group('copyWith', () {
      test('copies with overridden fields', () {
        const original = EntityTypeDefinition(
          name: 'Original',
          description: 'Desc',
          isAbstract: false,
        );
        final copied = original.copyWith(
          name: 'Copied',
          isAbstract: true,
          extendsType: 'Parent',
        );
        expect(copied.name, 'Copied');
        expect(copied.description, 'Desc');
        expect(copied.isAbstract, isTrue);
        expect(copied.extendsType, 'Parent');
      });

      test('preserves all fields when no overrides given', () {
        const original = EntityTypeDefinition(
          name: 'E',
          description: 'D',
          properties: [PropertyDefinition(name: 'p', type: 'string')],
          requiredProperties: ['p'],
          extendsType: 'Base',
          isAbstract: true,
        );
        final copied = original.copyWith();
        expect(copied.name, 'E');
        expect(copied.description, 'D');
        expect(copied.properties.first.name, 'p');
        expect(copied.requiredProperties, ['p']);
        expect(copied.extendsType, 'Base');
        expect(copied.isAbstract, isTrue);
      });
    });

    test('extendsType field works via constructor', () {
      const entity = EntityTypeDefinition(
        name: 'Employee',
        extendsType: 'Person',
      );
      expect(entity.extendsType, 'Person');
    });

    test('isAbstract defaults to false', () {
      const entity = EntityTypeDefinition(name: 'Concrete');
      expect(entity.isAbstract, isFalse);
    });

    test('requiredProperties accessible as list', () {
      const entity = EntityTypeDefinition(
        name: 'X',
        requiredProperties: ['a', 'b', 'c'],
      );
      expect(entity.requiredProperties, hasLength(3));
      expect(entity.requiredProperties, containsAll(['a', 'b', 'c']));
    });
  });

  // ---------------------------------------------------------------------------
  // 3. RelationTypeDefinition
  // ---------------------------------------------------------------------------
  group('RelationTypeDefinition', () {
    group('fromJson / toJson', () {
      test('round-trip with all fields', () {
        final json = {
          'name': 'worksFor',
          'description': 'Employment relation',
          'fromEntityType': 'Person',
          'toEntityType': 'Organization',
          'properties': [
            {'name': 'role', 'type': 'string'},
          ],
          'fromCardinality': 'many',
          'toCardinality': 'one',
          'bidirectional': true,
          'inverseName': 'employs',
        };

        final rel = RelationTypeDefinition.fromJson(json);
        expect(rel.name, 'worksFor');
        expect(rel.description, 'Employment relation');
        expect(rel.fromEntityType, 'Person');
        expect(rel.toEntityType, 'Organization');
        expect(rel.properties, hasLength(1));
        expect(rel.fromCardinality, Cardinality.many);
        expect(rel.toCardinality, Cardinality.one);
        expect(rel.bidirectional, isTrue);
        expect(rel.inverseName, 'employs');

        final output = rel.toJson();
        final restored = RelationTypeDefinition.fromJson(output);
        expect(restored.name, 'worksFor');
        expect(restored.fromEntityType, 'Person');
        expect(restored.toEntityType, 'Organization');
        expect(restored.bidirectional, isTrue);
        expect(restored.inverseName, 'employs');
      });

      test('fromJson supports "from" key as alternative to "fromEntityType"', () {
        final json = {
          'name': 'locatedIn',
          'from': 'Building',
          'to': 'City',
        };
        final rel = RelationTypeDefinition.fromJson(json);
        expect(rel.fromEntityType, 'Building');
        expect(rel.toEntityType, 'City');
      });

      test('fromJson prefers "fromEntityType" over "from"', () {
        final json = {
          'name': 'test',
          'fromEntityType': 'Preferred',
          'from': 'Fallback',
          'toEntityType': 'Target',
          'to': 'FallbackTarget',
        };
        final rel = RelationTypeDefinition.fromJson(json);
        expect(rel.fromEntityType, 'Preferred');
        expect(rel.toEntityType, 'Target');
      });

      test('fromJson with minimal data uses defaults', () {
        final rel = RelationTypeDefinition.fromJson({});
        expect(rel.name, '');
        expect(rel.fromEntityType, '');
        expect(rel.toEntityType, '');
        expect(rel.properties, isEmpty);
        expect(rel.fromCardinality, Cardinality.many);
        expect(rel.toCardinality, Cardinality.many);
        expect(rel.bidirectional, isFalse);
        expect(rel.inverseName, isNull);
      });

      test('toJson omits optional fields when at defaults', () {
        const rel = RelationTypeDefinition(
          name: 'r',
          fromEntityType: 'A',
          toEntityType: 'B',
        );
        final json = rel.toJson();
        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('properties'), isFalse);
        expect(json.containsKey('bidirectional'), isFalse);
        expect(json.containsKey('inverseName'), isFalse);
        // Cardinality is always present
        expect(json['fromCardinality'], 'many');
        expect(json['toCardinality'], 'many');
      });
    });

    group('bidirectional and inverseName', () {
      test('bidirectional defaults to false', () {
        const rel = RelationTypeDefinition(
          name: 'r',
          fromEntityType: 'A',
          toEntityType: 'B',
        );
        expect(rel.bidirectional, isFalse);
        expect(rel.inverseName, isNull);
      });

      test('bidirectional with inverse name', () {
        const rel = RelationTypeDefinition(
          name: 'parentOf',
          fromEntityType: 'Person',
          toEntityType: 'Person',
          bidirectional: true,
          inverseName: 'childOf',
        );
        expect(rel.bidirectional, isTrue);
        expect(rel.inverseName, 'childOf');
      });
    });

    group('copyWith', () {
      test('copies with overridden fields', () {
        const original = RelationTypeDefinition(
          name: 'r',
          fromEntityType: 'A',
          toEntityType: 'B',
          fromCardinality: Cardinality.one,
          toCardinality: Cardinality.many,
        );
        final copied = original.copyWith(
          name: 'r2',
          bidirectional: true,
          inverseName: 'r2Inv',
        );
        expect(copied.name, 'r2');
        expect(copied.fromEntityType, 'A');
        expect(copied.toEntityType, 'B');
        expect(copied.fromCardinality, Cardinality.one);
        expect(copied.bidirectional, isTrue);
        expect(copied.inverseName, 'r2Inv');
      });

      test('preserves all fields when no overrides given', () {
        const original = RelationTypeDefinition(
          name: 'rel',
          description: 'desc',
          fromEntityType: 'X',
          toEntityType: 'Y',
          fromCardinality: Cardinality.oneOrMore,
          toCardinality: Cardinality.zeroOrOne,
          bidirectional: true,
          inverseName: 'inv',
        );
        final copied = original.copyWith();
        expect(copied.name, 'rel');
        expect(copied.description, 'desc');
        expect(copied.fromEntityType, 'X');
        expect(copied.toEntityType, 'Y');
        expect(copied.fromCardinality, Cardinality.oneOrMore);
        expect(copied.toCardinality, Cardinality.zeroOrOne);
        expect(copied.bidirectional, isTrue);
        expect(copied.inverseName, 'inv');
      });
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Cardinality.fromString
  // ---------------------------------------------------------------------------
  group('Cardinality', () {
    group('fromString', () {
      test('"one" maps to Cardinality.one', () {
        expect(Cardinality.fromString('one'), Cardinality.one);
      });

      test('"1" maps to Cardinality.one', () {
        expect(Cardinality.fromString('1'), Cardinality.one);
      });

      test('"zeroorone" maps to Cardinality.zeroOrOne', () {
        expect(Cardinality.fromString('zeroorone'), Cardinality.zeroOrOne);
      });

      test('"0..1" maps to Cardinality.zeroOrOne', () {
        expect(Cardinality.fromString('0..1'), Cardinality.zeroOrOne);
      });

      test('"oneormore" maps to Cardinality.oneOrMore', () {
        expect(Cardinality.fromString('oneormore'), Cardinality.oneOrMore);
      });

      test('"1..*" maps to Cardinality.oneOrMore', () {
        expect(Cardinality.fromString('1..*'), Cardinality.oneOrMore);
      });

      test('"many" maps to Cardinality.many', () {
        expect(Cardinality.fromString('many'), Cardinality.many);
      });

      test('"*" maps to Cardinality.many', () {
        expect(Cardinality.fromString('*'), Cardinality.many);
      });

      test('"0..*" maps to Cardinality.many', () {
        expect(Cardinality.fromString('0..*'), Cardinality.many);
      });

      test('null defaults to Cardinality.many', () {
        expect(Cardinality.fromString(null), Cardinality.many);
      });

      test('unknown string defaults to Cardinality.many', () {
        expect(Cardinality.fromString('unknown'), Cardinality.many);
      });

      test('case insensitive matching', () {
        expect(Cardinality.fromString('ONE'), Cardinality.one);
        expect(Cardinality.fromString('ZeroOrOne'), Cardinality.zeroOrOne);
        expect(Cardinality.fromString('ONEORMORE'), Cardinality.oneOrMore);
        expect(Cardinality.fromString('MANY'), Cardinality.many);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // 5. FactTypeDefinition
  // ---------------------------------------------------------------------------
  group('FactTypeDefinition', () {
    group('fromJson / toJson', () {
      test('round-trip with all fields', () {
        final json = {
          'name': 'revenue',
          'description': 'Annual revenue',
          'valueType': 'number',
          'validSources': ['financial_report', 'api'],
          'temporal': true,
          'unit': 'USD',
          'pattern': r'^\d+$',
          'minValue': 0,
          'maxValue': 1000000,
          'allowedValues': ['100', '200', '300'],
        };

        final fact = FactTypeDefinition.fromJson(json);
        expect(fact.name, 'revenue');
        expect(fact.description, 'Annual revenue');
        expect(fact.valueType, 'number');
        expect(fact.validSources, ['financial_report', 'api']);
        expect(fact.temporal, isTrue);
        expect(fact.unit, 'USD');
        expect(fact.pattern, r'^\d+$');
        expect(fact.minValue, 0.0);
        expect(fact.maxValue, 1000000.0);
        expect(fact.allowedValues, ['100', '200', '300']);

        final output = fact.toJson();
        final restored = FactTypeDefinition.fromJson(output);
        expect(restored.name, 'revenue');
        expect(restored.valueType, 'number');
        expect(restored.temporal, isTrue);
        expect(restored.unit, 'USD');
      });

      test('fromJson with minimal data uses defaults', () {
        final fact = FactTypeDefinition.fromJson({});
        expect(fact.name, '');
        expect(fact.description, isNull);
        expect(fact.valueType, 'string');
        expect(fact.validSources, isEmpty);
        expect(fact.temporal, isFalse);
        expect(fact.unit, isNull);
        expect(fact.pattern, isNull);
        expect(fact.minValue, isNull);
        expect(fact.maxValue, isNull);
        expect(fact.allowedValues, isNull);
      });

      test('toJson omits optional fields at defaults', () {
        const fact = FactTypeDefinition(name: 'simple', valueType: 'string');
        final json = fact.toJson();
        expect(json['name'], 'simple');
        expect(json['valueType'], 'string');
        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('validSources'), isFalse);
        expect(json.containsKey('temporal'), isFalse);
        expect(json.containsKey('unit'), isFalse);
        expect(json.containsKey('pattern'), isFalse);
        expect(json.containsKey('minValue'), isFalse);
        expect(json.containsKey('maxValue'), isFalse);
        expect(json.containsKey('allowedValues'), isFalse);
      });
    });

    group('copyWith', () {
      test('copies with overridden fields', () {
        const original = FactTypeDefinition(
          name: 'f',
          valueType: 'string',
          temporal: false,
        );
        final copied = original.copyWith(
          name: 'f2',
          temporal: true,
          unit: 'kg',
        );
        expect(copied.name, 'f2');
        expect(copied.valueType, 'string');
        expect(copied.temporal, isTrue);
        expect(copied.unit, 'kg');
      });

      test('preserves all fields when no overrides given', () {
        const original = FactTypeDefinition(
          name: 'n',
          description: 'd',
          valueType: 'number',
          validSources: ['src'],
          temporal: true,
          unit: 'EUR',
          pattern: r'\d+',
          minValue: 1.0,
          maxValue: 99.0,
          allowedValues: ['a'],
        );
        final copied = original.copyWith();
        expect(copied.name, 'n');
        expect(copied.description, 'd');
        expect(copied.valueType, 'number');
        expect(copied.validSources, ['src']);
        expect(copied.temporal, isTrue);
        expect(copied.unit, 'EUR');
        expect(copied.pattern, r'\d+');
        expect(copied.minValue, 1.0);
        expect(copied.maxValue, 99.0);
        expect(copied.allowedValues, ['a']);
      });
    });

    // -------------------------------------------------------------------------
    // 6. FactTypeDefinition.validateValue()
    // -------------------------------------------------------------------------
    group('validateValue', () {
      test('null is always valid', () {
        const fact = FactTypeDefinition(name: 'f', valueType: 'string');
        expect(fact.validateValue(null), isTrue);
      });

      // -- string type --
      group('string type', () {
        test('valid string returns true', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'string');
          expect(fact.validateValue('hello'), isTrue);
        });

        test('non-string returns false', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'string');
          expect(fact.validateValue(42), isFalse);
        });

        test('pattern match returns true', () {
          const fact = FactTypeDefinition(
            name: 'f',
            valueType: 'string',
            pattern: r'^[A-Z]+$',
          );
          expect(fact.validateValue('ABC'), isTrue);
        });

        test('pattern mismatch returns false', () {
          const fact = FactTypeDefinition(
            name: 'f',
            valueType: 'string',
            pattern: r'^[A-Z]+$',
          );
          expect(fact.validateValue('abc'), isFalse);
        });

        test('allowedValues match returns true', () {
          const fact = FactTypeDefinition(
            name: 'f',
            valueType: 'string',
            allowedValues: ['red', 'green', 'blue'],
          );
          expect(fact.validateValue('green'), isTrue);
        });

        test('allowedValues mismatch returns false', () {
          const fact = FactTypeDefinition(
            name: 'f',
            valueType: 'string',
            allowedValues: ['red', 'green', 'blue'],
          );
          expect(fact.validateValue('yellow'), isFalse);
        });
      });

      // -- number / integer / double types --
      group('number type', () {
        test('valid number returns true', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'number');
          expect(fact.validateValue(42), isTrue);
          expect(fact.validateValue(3.14), isTrue);
        });

        test('non-number returns false', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'number');
          expect(fact.validateValue('42'), isFalse);
        });

        test('minValue boundary valid', () {
          const fact = FactTypeDefinition(
            name: 'f',
            valueType: 'number',
            minValue: 10.0,
          );
          expect(fact.validateValue(10), isTrue);
          expect(fact.validateValue(11), isTrue);
        });

        test('below minValue returns false', () {
          const fact = FactTypeDefinition(
            name: 'f',
            valueType: 'number',
            minValue: 10.0,
          );
          expect(fact.validateValue(9), isFalse);
        });

        test('maxValue boundary valid', () {
          const fact = FactTypeDefinition(
            name: 'f',
            valueType: 'number',
            maxValue: 100.0,
          );
          expect(fact.validateValue(100), isTrue);
          expect(fact.validateValue(99), isTrue);
        });

        test('above maxValue returns false', () {
          const fact = FactTypeDefinition(
            name: 'f',
            valueType: 'number',
            maxValue: 100.0,
          );
          expect(fact.validateValue(101), isFalse);
        });
      });

      group('integer type', () {
        test('valid integer returns true', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'integer');
          expect(fact.validateValue(5), isTrue);
        });

        test('double is also num so returns true for integer type', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'integer');
          expect(fact.validateValue(5.5), isTrue);
        });

        test('non-num returns false', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'integer');
          expect(fact.validateValue('5'), isFalse);
        });
      });

      group('double type', () {
        test('valid double returns true', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'double');
          expect(fact.validateValue(3.14), isTrue);
        });

        test('int is also num so returns true for double type', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'double');
          expect(fact.validateValue(3), isTrue);
        });

        test('non-num returns false', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'double');
          expect(fact.validateValue(true), isFalse);
        });
      });

      // -- boolean type --
      group('boolean type', () {
        test('true is valid', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'boolean');
          expect(fact.validateValue(true), isTrue);
        });

        test('false is valid', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'boolean');
          expect(fact.validateValue(false), isTrue);
        });

        test('non-bool returns false', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'boolean');
          expect(fact.validateValue(1), isFalse);
          expect(fact.validateValue('true'), isFalse);
        });
      });

      // -- date / datetime types --
      group('date type', () {
        test('DateTime is valid', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'date');
          expect(fact.validateValue(DateTime(2024, 1, 15)), isTrue);
        });

        test('valid ISO string is valid', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'date');
          expect(fact.validateValue('2024-01-15'), isTrue);
        });

        test('invalid string returns false', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'date');
          expect(fact.validateValue('not-a-date'), isFalse);
        });

        test('non-string non-DateTime returns false', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'date');
          expect(fact.validateValue(12345), isFalse);
        });
      });

      group('datetime type', () {
        test('DateTime is valid', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'datetime');
          expect(fact.validateValue(DateTime(2024, 6, 15, 10, 30)), isTrue);
        });

        test('valid ISO datetime string is valid', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'datetime');
          expect(fact.validateValue('2024-06-15T10:30:00Z'), isTrue);
        });

        test('invalid datetime string returns false', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'datetime');
          expect(fact.validateValue('yesterday'), isFalse);
        });

        test('non-string non-DateTime returns false', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'datetime');
          expect(fact.validateValue(true), isFalse);
        });
      });

      // -- json / object / map types --
      group('json type', () {
        test('Map is valid', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'json');
          expect(fact.validateValue({'key': 'value'}), isTrue);
        });

        test('non-Map returns false', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'json');
          expect(fact.validateValue([1, 2, 3]), isFalse);
          expect(fact.validateValue('json'), isFalse);
        });
      });

      group('object type', () {
        test('Map is valid', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'object');
          expect(fact.validateValue(<String, dynamic>{}), isTrue);
        });

        test('non-Map returns false', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'object');
          expect(fact.validateValue(42), isFalse);
        });
      });

      group('map type', () {
        test('Map is valid', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'map');
          expect(fact.validateValue({'a': 1}), isTrue);
        });

        test('non-Map returns false', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'map');
          expect(fact.validateValue('string'), isFalse);
        });
      });

      // -- array / list types --
      group('array type', () {
        test('List is valid', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'array');
          expect(fact.validateValue([1, 2, 3]), isTrue);
        });

        test('non-List returns false', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'array');
          expect(fact.validateValue({'a': 1}), isFalse);
        });
      });

      group('list type', () {
        test('List is valid', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'list');
          expect(fact.validateValue(<String>[]), isTrue);
        });

        test('non-List returns false', () {
          const fact = FactTypeDefinition(name: 'f', valueType: 'list');
          expect(fact.validateValue(42), isFalse);
        });
      });

      // -- unknown type --
      test('unknown type always returns true', () {
        const fact = FactTypeDefinition(name: 'f', valueType: 'custom_type');
        expect(fact.validateValue('anything'), isTrue);
        expect(fact.validateValue(42), isTrue);
        expect(fact.validateValue(true), isTrue);
        expect(fact.validateValue([1]), isTrue);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // 7. PropertyDefinition
  // ---------------------------------------------------------------------------
  group('PropertyDefinition', () {
    group('fromJson / toJson', () {
      test('round-trip with all fields', () {
        final json = {
          'name': 'email',
          'type': 'string',
          'required': true,
          'default': 'user@example.com',
          'description': 'Email address',
          'unique': true,
          'indexed': true,
          'pattern': r'^[\w]+@[\w]+\.[\w]+$',
          'minValue': 0.0,
          'maxValue': 100.0,
          'minLength': 5,
          'maxLength': 255,
          'elementType': 'string',
          'allowedValues': ['a@b.c', 'user@example.com'],
        };

        final prop = PropertyDefinition.fromJson(json);
        expect(prop.name, 'email');
        expect(prop.type, 'string');
        expect(prop.required, isTrue);
        expect(prop.defaultValue, 'user@example.com');
        expect(prop.description, 'Email address');
        expect(prop.unique, isTrue);
        expect(prop.indexed, isTrue);
        expect(prop.pattern, r'^[\w]+@[\w]+\.[\w]+$');
        expect(prop.minValue, 0.0);
        expect(prop.maxValue, 100.0);
        expect(prop.minLength, 5);
        expect(prop.maxLength, 255);
        expect(prop.elementType, 'string');
        expect(prop.allowedValues, ['a@b.c', 'user@example.com']);

        final output = prop.toJson();
        final restored = PropertyDefinition.fromJson(output);
        expect(restored.name, 'email');
        expect(restored.required, isTrue);
        expect(restored.defaultValue, 'user@example.com');
      });

      test('fromJson reads "default" key for defaultValue', () {
        final prop = PropertyDefinition.fromJson({
          'name': 'x',
          'type': 'string',
          'default': 'hello',
        });
        expect(prop.defaultValue, 'hello');
      });

      test('fromJson reads "defaultValue" key as fallback', () {
        final prop = PropertyDefinition.fromJson({
          'name': 'x',
          'type': 'string',
          'defaultValue': 'world',
        });
        expect(prop.defaultValue, 'world');
      });

      test('fromJson prefers "default" over "defaultValue"', () {
        final prop = PropertyDefinition.fromJson({
          'name': 'x',
          'type': 'string',
          'default': 'primary',
          'defaultValue': 'fallback',
        });
        expect(prop.defaultValue, 'primary');
      });

      test('fromJson with minimal data uses defaults', () {
        final prop = PropertyDefinition.fromJson({});
        expect(prop.name, '');
        expect(prop.type, 'string');
        expect(prop.required, isFalse);
        expect(prop.defaultValue, isNull);
        expect(prop.description, isNull);
        expect(prop.unique, isFalse);
        expect(prop.indexed, isFalse);
        expect(prop.pattern, isNull);
        expect(prop.minValue, isNull);
        expect(prop.maxValue, isNull);
        expect(prop.minLength, isNull);
        expect(prop.maxLength, isNull);
        expect(prop.elementType, isNull);
        expect(prop.allowedValues, isNull);
      });

      test('toJson outputs "default" key for defaultValue', () {
        const prop = PropertyDefinition(
          name: 'x',
          type: 'string',
          defaultValue: 'val',
        );
        final json = prop.toJson();
        expect(json['default'], 'val');
        expect(json.containsKey('defaultValue'), isFalse);
      });

      test('toJson omits optional fields at defaults', () {
        const prop = PropertyDefinition(name: 'x', type: 'string');
        final json = prop.toJson();
        expect(json.containsKey('required'), isFalse);
        expect(json.containsKey('default'), isFalse);
        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('unique'), isFalse);
        expect(json.containsKey('indexed'), isFalse);
        expect(json.containsKey('pattern'), isFalse);
        expect(json.containsKey('minValue'), isFalse);
        expect(json.containsKey('maxValue'), isFalse);
        expect(json.containsKey('minLength'), isFalse);
        expect(json.containsKey('maxLength'), isFalse);
        expect(json.containsKey('elementType'), isFalse);
        expect(json.containsKey('allowedValues'), isFalse);
      });
    });

    group('copyWith', () {
      test('copies with overridden fields', () {
        const original = PropertyDefinition(
          name: 'p',
          type: 'string',
          required: false,
        );
        final copied = original.copyWith(
          name: 'q',
          required: true,
          minLength: 3,
        );
        expect(copied.name, 'q');
        expect(copied.type, 'string');
        expect(copied.required, isTrue);
        expect(copied.minLength, 3);
      });

      test('preserves all fields when no overrides given', () {
        const original = PropertyDefinition(
          name: 'p',
          type: 'number',
          required: true,
          defaultValue: 42,
          description: 'd',
          unique: true,
          indexed: true,
          pattern: r'\d+',
          minValue: 0.0,
          maxValue: 100.0,
          minLength: 1,
          maxLength: 10,
          elementType: 'int',
          allowedValues: ['1', '2'],
        );
        final copied = original.copyWith();
        expect(copied.name, 'p');
        expect(copied.type, 'number');
        expect(copied.required, isTrue);
        expect(copied.defaultValue, 42);
        expect(copied.description, 'd');
        expect(copied.unique, isTrue);
        expect(copied.indexed, isTrue);
        expect(copied.pattern, r'\d+');
        expect(copied.minValue, 0.0);
        expect(copied.maxValue, 100.0);
        expect(copied.minLength, 1);
        expect(copied.maxLength, 10);
        expect(copied.elementType, 'int');
        expect(copied.allowedValues, ['1', '2']);
      });
    });

    // -------------------------------------------------------------------------
    // 8. PropertyDefinition.validateValue()
    // -------------------------------------------------------------------------
    group('validateValue', () {
      // -- null handling --
      group('null handling', () {
        test('null with required=false returns true', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'string',
            required: false,
          );
          expect(prop.validateValue(null), isTrue);
        });

        test('null with required=true returns false', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'string',
            required: true,
          );
          expect(prop.validateValue(null), isFalse);
        });

        test('null with required=true but defaultValue set returns true', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'string',
            required: true,
            defaultValue: 'fallback',
          );
          expect(prop.validateValue(null), isTrue);
        });
      });

      // -- string type --
      group('string type', () {
        test('valid string returns true', () {
          const prop = PropertyDefinition(name: 'p', type: 'string');
          expect(prop.validateValue('hello'), isTrue);
        });

        test('non-string returns false', () {
          const prop = PropertyDefinition(name: 'p', type: 'string');
          expect(prop.validateValue(42), isFalse);
        });

        test('minLength valid', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'string',
            minLength: 3,
          );
          expect(prop.validateValue('abc'), isTrue);
          expect(prop.validateValue('abcd'), isTrue);
        });

        test('minLength violation returns false', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'string',
            minLength: 3,
          );
          expect(prop.validateValue('ab'), isFalse);
        });

        test('maxLength valid', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'string',
            maxLength: 5,
          );
          expect(prop.validateValue('hello'), isTrue);
          expect(prop.validateValue('hi'), isTrue);
        });

        test('maxLength violation returns false', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'string',
            maxLength: 5,
          );
          expect(prop.validateValue('toolong'), isFalse);
        });

        test('pattern match returns true', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'string',
            pattern: r'^[a-z]+$',
          );
          expect(prop.validateValue('abc'), isTrue);
        });

        test('pattern mismatch returns false', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'string',
            pattern: r'^[a-z]+$',
          );
          expect(prop.validateValue('ABC'), isFalse);
        });

        test('allowedValues match returns true', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'string',
            allowedValues: ['yes', 'no'],
          );
          expect(prop.validateValue('yes'), isTrue);
        });

        test('allowedValues mismatch returns false', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'string',
            allowedValues: ['yes', 'no'],
          );
          expect(prop.validateValue('maybe'), isFalse);
        });
      });

      // -- number / integer / double types --
      group('number type', () {
        test('valid number returns true', () {
          const prop = PropertyDefinition(name: 'p', type: 'number');
          expect(prop.validateValue(42), isTrue);
          expect(prop.validateValue(3.14), isTrue);
        });

        test('non-number returns false', () {
          const prop = PropertyDefinition(name: 'p', type: 'number');
          expect(prop.validateValue('42'), isFalse);
        });

        test('minValue valid at boundary', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'number',
            minValue: 5.0,
          );
          expect(prop.validateValue(5), isTrue);
          expect(prop.validateValue(6), isTrue);
        });

        test('below minValue returns false', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'number',
            minValue: 5.0,
          );
          expect(prop.validateValue(4), isFalse);
        });

        test('maxValue valid at boundary', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'number',
            maxValue: 50.0,
          );
          expect(prop.validateValue(50), isTrue);
          expect(prop.validateValue(49), isTrue);
        });

        test('above maxValue returns false', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'number',
            maxValue: 50.0,
          );
          expect(prop.validateValue(51), isFalse);
        });
      });

      group('integer type', () {
        test('valid integer returns true', () {
          const prop = PropertyDefinition(name: 'p', type: 'integer');
          expect(prop.validateValue(10), isTrue);
        });

        test('non-num returns false', () {
          const prop = PropertyDefinition(name: 'p', type: 'integer');
          expect(prop.validateValue('10'), isFalse);
        });
      });

      group('double type', () {
        test('valid double returns true', () {
          const prop = PropertyDefinition(name: 'p', type: 'double');
          expect(prop.validateValue(2.718), isTrue);
        });

        test('non-num returns false', () {
          const prop = PropertyDefinition(name: 'p', type: 'double');
          expect(prop.validateValue(false), isFalse);
        });
      });

      // -- boolean type --
      group('boolean type', () {
        test('true is valid', () {
          const prop = PropertyDefinition(name: 'p', type: 'boolean');
          expect(prop.validateValue(true), isTrue);
        });

        test('false is valid', () {
          const prop = PropertyDefinition(name: 'p', type: 'boolean');
          expect(prop.validateValue(false), isTrue);
        });

        test('non-bool returns false', () {
          const prop = PropertyDefinition(name: 'p', type: 'boolean');
          expect(prop.validateValue(0), isFalse);
          expect(prop.validateValue('true'), isFalse);
        });
      });

      // -- date / datetime types --
      group('date type', () {
        test('DateTime is valid', () {
          const prop = PropertyDefinition(name: 'p', type: 'date');
          expect(prop.validateValue(DateTime(2024, 3, 1)), isTrue);
        });

        test('valid date string is valid', () {
          const prop = PropertyDefinition(name: 'p', type: 'date');
          expect(prop.validateValue('2024-03-01'), isTrue);
        });

        test('invalid date string returns false', () {
          const prop = PropertyDefinition(name: 'p', type: 'date');
          expect(prop.validateValue('not-a-date'), isFalse);
        });

        test('non-string non-DateTime returns false', () {
          const prop = PropertyDefinition(name: 'p', type: 'date');
          expect(prop.validateValue(20240301), isFalse);
        });
      });

      group('datetime type', () {
        test('DateTime is valid', () {
          const prop = PropertyDefinition(name: 'p', type: 'datetime');
          expect(prop.validateValue(DateTime(2024, 6, 15, 12, 0)), isTrue);
        });

        test('valid ISO datetime string is valid', () {
          const prop = PropertyDefinition(name: 'p', type: 'datetime');
          expect(prop.validateValue('2024-06-15T12:00:00Z'), isTrue);
        });

        test('invalid datetime string returns false', () {
          const prop = PropertyDefinition(name: 'p', type: 'datetime');
          expect(prop.validateValue('tomorrow'), isFalse);
        });
      });

      // -- list / array types --
      group('list type', () {
        test('valid list returns true', () {
          const prop = PropertyDefinition(name: 'p', type: 'list');
          expect(prop.validateValue([1, 2, 3]), isTrue);
        });

        test('non-list returns false', () {
          const prop = PropertyDefinition(name: 'p', type: 'list');
          expect(prop.validateValue('not a list'), isFalse);
        });

        test('minLength valid', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'list',
            minLength: 2,
          );
          expect(prop.validateValue([1, 2]), isTrue);
          expect(prop.validateValue([1, 2, 3]), isTrue);
        });

        test('minLength violation returns false', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'list',
            minLength: 2,
          );
          expect(prop.validateValue([1]), isFalse);
        });

        test('maxLength valid', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'list',
            maxLength: 3,
          );
          expect(prop.validateValue([1, 2, 3]), isTrue);
          expect(prop.validateValue([1]), isTrue);
        });

        test('maxLength violation returns false', () {
          const prop = PropertyDefinition(
            name: 'p',
            type: 'list',
            maxLength: 3,
          );
          expect(prop.validateValue([1, 2, 3, 4]), isFalse);
        });
      });

      group('array type', () {
        test('valid array returns true', () {
          const prop = PropertyDefinition(name: 'p', type: 'array');
          expect(prop.validateValue(<String>['a', 'b']), isTrue);
        });

        test('non-array returns false', () {
          const prop = PropertyDefinition(name: 'p', type: 'array');
          expect(prop.validateValue(42), isFalse);
        });
      });

      // -- map / object types --
      group('map type', () {
        test('valid map returns true', () {
          const prop = PropertyDefinition(name: 'p', type: 'map');
          expect(prop.validateValue({'key': 'value'}), isTrue);
        });

        test('non-map returns false', () {
          const prop = PropertyDefinition(name: 'p', type: 'map');
          expect(prop.validateValue([1, 2]), isFalse);
        });
      });

      group('object type', () {
        test('valid object (Map) returns true', () {
          const prop = PropertyDefinition(name: 'p', type: 'object');
          expect(prop.validateValue(<String, dynamic>{'a': 1}), isTrue);
        });

        test('non-Map returns false', () {
          const prop = PropertyDefinition(name: 'p', type: 'object');
          expect(prop.validateValue('string'), isFalse);
        });
      });

      // -- unknown type --
      test('unknown type always returns true', () {
        const prop = PropertyDefinition(name: 'p', type: 'exotic_type');
        expect(prop.validateValue('anything'), isTrue);
        expect(prop.validateValue(42), isTrue);
        expect(prop.validateValue(null), isTrue);
      });
    });
  });
}
