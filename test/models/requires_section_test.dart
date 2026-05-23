import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('RequiresSection', () {
    test('creates with defaults — empty atoms and tools', () {
      const section = RequiresSection();
      expect(section.builtinAtoms, isEmpty);
      expect(section.builtinTools, isEmpty);
      expect(section.isEmpty, isTrue);
      expect(section.isNotEmpty, isFalse);
    });

    test('schemaVersion default is 1.0.0', () {
      const section = RequiresSection();
      expect(section.schemaVersion, equals('1.0.0'));
    });

    test('toJson always emits schemaVersion', () {
      const section = RequiresSection();
      final json = section.toJson();
      expect(json['schemaVersion'], equals('1.0.0'));
      expect(json.containsKey('builtinAtoms'), isFalse);
      expect(json.containsKey('builtinTools'), isFalse);
    });

    test('fromJson defaults schemaVersion to 1.0.0 when absent', () {
      final section = RequiresSection.fromJson(<String, dynamic>{});
      expect(section.schemaVersion, equals('1.0.0'));
    });

    test('fromJson preserves explicit schemaVersion', () {
      final section = RequiresSection.fromJson({'schemaVersion': '2.0.0'});
      expect(section.schemaVersion, equals('2.0.0'));
    });

    test('fromJson parses builtinAtoms list', () {
      final section = RequiresSection.fromJson({
        'builtinAtoms': ['mcp', 'fs', 'ui'],
      });
      expect(section.builtinAtoms, equals(['mcp', 'fs', 'ui']));
      expect(section.isNotEmpty, isTrue);
    });

    test('fromJson parses builtinTools list', () {
      final section = RequiresSection.fromJson({
        'builtinTools': ['studio.workspace.save', 'studio.fs.read'],
      });
      expect(section.builtinTools,
          equals(['studio.workspace.save', 'studio.fs.read']));
    });

    test('fromJson skips non-string entries gracefully', () {
      final section = RequiresSection.fromJson({
        'builtinAtoms': ['mcp', 42, null, 'fs'],
        'builtinTools': [true, 'studio.fs.read'],
      });
      expect(section.builtinAtoms, equals(['mcp', 'fs']));
      expect(section.builtinTools, equals(['studio.fs.read']));
    });

    test('toJson includes builtinAtoms when non-empty', () {
      const section = RequiresSection(builtinAtoms: ['mcp', 'ui']);
      final json = section.toJson();
      expect(json['builtinAtoms'], equals(['mcp', 'ui']));
    });

    test('toJson includes builtinTools when non-empty', () {
      const section = RequiresSection(
        builtinTools: ['studio.workspace.save'],
      );
      final json = section.toJson();
      expect(json['builtinTools'], equals(['studio.workspace.save']));
    });

    test('round-trip preserves schemaVersion + atoms + tools', () {
      const original = RequiresSection(
        schemaVersion: '1.5.0',
        builtinAtoms: ['mcp', 'fs', 'ui', 'workspace'],
        builtinTools: ['studio.workspace.save', 'studio.fs.read'],
      );
      final json = original.toJson();
      final restored = RequiresSection.fromJson(json);
      expect(restored.schemaVersion, equals('1.5.0'));
      expect(restored.builtinAtoms,
          equals(['mcp', 'fs', 'ui', 'workspace']));
      expect(restored.builtinTools,
          equals(['studio.workspace.save', 'studio.fs.read']));
    });

    test('copyWith preserves schemaVersion when not overridden', () {
      const original = RequiresSection(schemaVersion: '3.0.0');
      final copy = original.copyWith();
      expect(copy.schemaVersion, equals('3.0.0'));
    });

    test('copyWith overrides individual fields', () {
      const original = RequiresSection(
        schemaVersion: '1.0.0',
        builtinAtoms: ['mcp'],
      );
      final copy = original.copyWith(
        schemaVersion: '2.0.0',
        builtinTools: ['studio.fs.read'],
      );
      expect(copy.schemaVersion, equals('2.0.0'));
      expect(copy.builtinAtoms, equals(['mcp']));
      expect(copy.builtinTools, equals(['studio.fs.read']));
    });

    test('legacy bundles without schemaVersion still load', () {
      // Backward compat — bundles authored before schemaVersion was added
      // load with schemaVersion defaulting to '1.0.0'.
      final section = RequiresSection.fromJson({
        'builtinAtoms': ['mcp'],
      });
      expect(section.schemaVersion, equals('1.0.0'));
      expect(section.builtinAtoms, equals(['mcp']));
    });
  });
}
