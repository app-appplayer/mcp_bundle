import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  group('McpBundle', () {
    test('creates bundle with manifest only', () {
      final bundle = McpBundle(
        manifest: const BundleManifest(
          id: 'test-bundle',
          name: 'Test Bundle',
          version: '1.0.0',
        ),
      );

      expect(bundle.manifest.id, equals('test-bundle'));
      expect(bundle.manifest.name, equals('Test Bundle'));
      expect(bundle.manifest.version, equals('1.0.0'));
      expect(bundle.hasContent, isFalse);
      expect(bundle.presentSections, isEmpty);
    });

    test('creates bundle with sections', () {
      final bundle = McpBundle(
        manifest: const BundleManifest(
          id: 'full-bundle',
          name: 'Full Bundle',
          version: '2.0.0',
        ),
        ui: const UiSection(screens: []),
        flow: const FlowSection(flows: []),
      );

      expect(bundle.hasContent, isTrue);
      expect(bundle.presentSections, containsAll(['ui', 'flow']));
    });

    test('serializes and deserializes correctly', () {
      final original = McpBundle(
        manifest: const BundleManifest(
          id: 'test-bundle',
          name: 'Test Bundle',
          version: '1.0.0',
          description: 'A test bundle',
        ),
        extensions: {'custom': 'value'},
      );

      final json = original.toJson();
      final restored = McpBundle.fromJson(json);

      expect(restored.manifest.id, equals(original.manifest.id));
      expect(restored.manifest.name, equals(original.manifest.name));
      expect(restored.manifest.version, equals(original.manifest.version));
      expect(restored.manifest.description, equals(original.manifest.description));
      expect(restored.extensions['custom'], equals('value'));
    });

    test('copyWith creates modified copy', () {
      final original = McpBundle(
        manifest: const BundleManifest(
          id: 'original',
          name: 'Original',
          version: '1.0.0',
        ),
      );

      final copy = original.copyWith(
        manifest: const BundleManifest(
          id: 'modified',
          name: 'Modified',
          version: '2.0.0',
        ),
      );

      expect(original.manifest.id, equals('original'));
      expect(copy.manifest.id, equals('modified'));
    });
  });

  group('BundleManifest', () {
    test('creates manifest with required fields', () {
      const manifest = BundleManifest(
        id: 'test-id',
        name: 'test',
        version: '1.0.0',
      );

      expect(manifest.id, equals('test-id'));
      expect(manifest.name, equals('test'));
      expect(manifest.version, equals('1.0.0'));
    });

    test('creates manifest with all fields', () {
      const manifest = BundleManifest(
        id: 'full-id',
        name: 'full-manifest',
        version: '1.2.3',
        description: 'Full description',
        provider: 'Test Provider',
        license: 'MIT',
        dependencies: [
          BundleDependency(id: 'dep1', version: '^1.0.0'),
        ],
      );

      expect(manifest.provider, equals('Test Provider'));
      expect(manifest.license, equals('MIT'));
      expect(manifest.dependencies.length, equals(1));
    });

    test('serializes and deserializes correctly', () {
      const original = BundleManifest(
        id: 'test-id',
        name: 'test',
        version: '1.0.0',
        description: 'Test description',
      );

      final json = original.toJson();
      final restored = BundleManifest.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.version, equals(original.version));
      expect(restored.description, equals(original.description));
    });

    test('BundleType fromString works correctly', () {
      expect(BundleType.fromString('application'), equals(BundleType.application));
      expect(BundleType.fromString('library'), equals(BundleType.library));
      expect(BundleType.fromString('skill'), equals(BundleType.skill));
      expect(BundleType.fromString('unknown_type'), equals(BundleType.unknown));
    });
  });

  group('BundleDependency', () {
    test('creates dependency with required fields', () {
      const dep = BundleDependency(id: 'my-dep', version: '^1.0.0');

      expect(dep.id, equals('my-dep'));
      expect(dep.version, equals('^1.0.0'));
      expect(dep.optional, isFalse);
    });

    test('creates optional dependency', () {
      const dep = BundleDependency(
        id: 'optional-dep',
        version: '*',
        optional: true,
        features: ['feature1'],
      );

      expect(dep.optional, isTrue);
      expect(dep.features, contains('feature1'));
    });

    test('serializes and deserializes correctly', () {
      const original = BundleDependency(
        id: 'dep',
        version: '^2.0.0',
        optional: true,
      );

      final json = original.toJson();
      final restored = BundleDependency.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.version, equals(original.version));
      expect(restored.optional, equals(original.optional));
    });
  });
}
