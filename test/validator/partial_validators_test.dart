/// Tests for [PartialValidators] — D3 of the authoring layer
/// boost. Each `validate*` returns `null` for valid entries, a
/// `List<String>` of issues otherwise.
library;

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('PartialValidators', () {
    test('validateKnowledgeSource accepts a minimal valid entry', () {
      expect(
        PartialValidators.validateKnowledgeSource({
          'id': 'src1',
          'name': 'My Source',
          'type': 'documents',
        }),
        isNull,
      );
    });

    test('validateKnowledgeSource flags missing id + name', () {
      final issues = PartialValidators.validateKnowledgeSource({
        'type': 'documents',
      });
      expect(issues, isNotNull);
      expect(issues!.any((e) => e.contains('"id"')), isTrue);
      expect(issues.any((e) => e.contains('"name"')), isTrue);
    });

    test('validateKnowledgeDocument requires id OR path', () {
      expect(
        PartialValidators.validateKnowledgeDocument({
          'id': 'doc1',
          'content': 'hello',
        }),
        isNull,
      );
      expect(
        PartialValidators.validateKnowledgeDocument({
          'path': 'docs/foo.md',
          'content': 'hello',
        }),
        isNull,
      );

      final issues = PartialValidators.validateKnowledgeDocument({
        'content': 'hello',
      });
      expect(issues, isNotNull);
      expect(issues!.any((e) => e.contains('id') && e.contains('path')), isTrue);
    });

    test('validateAgent requires id + name + role', () {
      expect(
        PartialValidators.validateAgent({
          'id': 'a1',
          'name': 'Agent One',
          'role': 'manager',
        }),
        isNull,
      );
      final issues = PartialValidators.validateAgent({
        'id': 'a1',
        'name': 'Agent One',
      });
      expect(issues, isNotNull);
      expect(issues!.any((e) => e.contains('"role"')), isTrue);
    });

    test('validateFact requires id', () {
      expect(
        PartialValidators.validateFact({
          'id': 'fact-1',
          'content': 'A is B',
        }),
        isNull,
      );
      final issues = PartialValidators.validateFact({'content': 'orphan'});
      expect(issues, isNotNull);
      expect(issues!.first, contains('"id"'));
    });

    test('validateSkill / Profile / Philosophy / Workflow / Pipeline / Runbook '
        'require id + name', () {
      final cases = <List<String>? Function(Map<String, dynamic>)>[
        PartialValidators.validateSkill,
        PartialValidators.validateProfile,
        PartialValidators.validatePhilosophy,
        PartialValidators.validateWorkflow,
        PartialValidators.validatePipeline,
        PartialValidators.validateRunbook,
      ];
      for (final v in cases) {
        expect(v({'id': 'x', 'name': 'Y'}), isNull);
        final issues = v({'id': 'x'});
        expect(issues, isNotNull, reason: 'missing-name not flagged');
        expect(issues!.any((e) => e.contains('"name"')), isTrue);
      }
    });

    test('flags empty-string id (silent fromJson fallback gap)', () {
      // KnowledgeSource.fromJson coerces missing id to '' — partial
      // validator must reject explicitly to close that gap.
      final issues = PartialValidators.validateKnowledgeSource({
        'id': '',
        'name': '',
      });
      expect(issues, isNotNull);
      expect(issues!.length, greaterThanOrEqualTo(2));
    });

    test('catches hard shape errors via smoke fromJson', () {
      // documents must be a List; passing a Map should be caught by
      // the smoke parse.
      final issues = PartialValidators.validateKnowledgeSource({
        'id': 'src',
        'name': 'name',
        'documents': {'not': 'a list'},
      });
      expect(issues, isNotNull);
      expect(issues!.any((e) => e.startsWith('shape:')), isTrue);
    });
  });
}
