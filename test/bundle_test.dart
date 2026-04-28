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
        ui: const UiSection(pages: []),
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

  group('McpBundle hasContent and presentSections', () {
    test('hasContent false when no sections', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
      );
      expect(bundle.hasContent, isFalse);
    });

    test('hasContent true with skills section', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
        skills: SkillSection(),
      );
      expect(bundle.hasContent, isTrue);
    });

    test('hasContent true with knowledge section', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
        knowledge: KnowledgeSection(),
      );
      expect(bundle.hasContent, isTrue);
    });

    test('hasContent true with bindings section', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
        bindings: BindingSection(),
      );
      expect(bundle.hasContent, isTrue);
    });

    test('hasContent true with tests section', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
        tests: TestSection(),
      );
      expect(bundle.hasContent, isTrue);
    });

    test('hasContent true with policies', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
        policies: PolicySection(),
      );
      expect(bundle.hasContent, isTrue);
    });

    test('hasContent true with profiles', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
        profiles: ProfilesSection(),
      );
      expect(bundle.hasContent, isTrue);
    });

    test('hasContent true with factGraphSchema', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
        factGraphSchema: FactGraphSchema(),
      );
      expect(bundle.hasContent, isTrue);
    });

    test('presentSections lists all present sections', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
        skills: SkillSection(),
        knowledge: KnowledgeSection(),
        policies: PolicySection(),
        profiles: ProfilesSection(),
        factGraphSchema: FactGraphSchema(),
      );
      expect(
        bundle.presentSections,
        containsAll([
          'skills',
          'knowledge',
          'policies',
          'profiles',
          'factGraphSchema',
        ]),
      );
    });

    test('presentSections includes compatibility and integrity', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
        compatibility: CompatibilityConfig(),
        integrity: IntegrityConfig(),
      );
      expect(bundle.presentSections, contains('compatibility'));
      expect(bundle.presentSections, contains('integrity'));
    });

    test('presentSections includes extensions when non-empty', () {
      final bundle = McpBundle(
        manifest: const BundleManifest(
          id: 'b',
          name: 'B',
          version: '1.0.0',
        ),
        extensions: {'custom': 'data'},
      );
      expect(bundle.presentSections, contains('extensions'));
    });
  });

  group('McpBundle hasPolicies/hasFactGraphSchema/hasIntegrity', () {
    test('hasPolicies false when policies is null', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
      );
      expect(bundle.hasPolicies, isFalse);
    });

    test('hasPolicies false when policies list is empty', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
        policies: PolicySection(),
      );
      expect(bundle.hasPolicies, isFalse);
    });

    test('hasPolicies true when policies list is non-empty', () {
      final bundle = McpBundle(
        manifest: const BundleManifest(
          id: 'b',
          name: 'B',
          version: '1.0.0',
        ),
        policies: const PolicySection(policies: [
          Policy(id: 'p1', name: 'Policy', rules: []),
        ]),
      );
      expect(bundle.hasPolicies, isTrue);
    });

    test('hasFactGraphSchema false when null', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
      );
      expect(bundle.hasFactGraphSchema, isFalse);
    });

    test('hasFactGraphSchema false when empty', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
        factGraphSchema: FactGraphSchema(),
      );
      expect(bundle.hasFactGraphSchema, isFalse);
    });

    test('hasFactGraphSchema true when non-empty', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
        factGraphSchema: FactGraphSchema(
          entityTypes: [EntityTypeDefinition(name: 'Person')],
        ),
      );
      expect(bundle.hasFactGraphSchema, isTrue);
    });

    test('hasIntegrity false when null', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
      );
      expect(bundle.hasIntegrity, isFalse);
    });

    test('hasIntegrity false when not valid', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
        integrity: IntegrityConfig(),
      );
      expect(bundle.hasIntegrity, isFalse);
    });

    test('hasIntegrity true when valid', () {
      final bundle = McpBundle(
        manifest: const BundleManifest(
          id: 'b',
          name: 'B',
          version: '1.0.0',
        ),
        integrity: IntegrityConfig.fromJson({
          'contentHash': {
            'algorithm': 'sha256',
            'value': 'abc123',
          },
        }),
      );
      expect(bundle.hasIntegrity, isTrue);
    });
  });

  group('McpBundle fromJson/toJson with all sections', () {
    test('fromJson with all section types', () {
      final bundle = McpBundle.fromJson({
        'schemaVersion': '1.0.0',
        'manifest': {'id': 'b', 'name': 'B', 'version': '1.0.0'},
        'ui': {'schemaVersion': '1.0.0'},
        'flow': {'schemaVersion': '1.0.0'},
        'skills': {'schemaVersion': '1.0.0'},
        'knowledge': {'schemaVersion': '1.0.0'},
        'bindings': {'schemaVersion': '1.0.0'},
        'tests': {'schemaVersion': '1.0.0'},
        'policies': <String, dynamic>{},
        'profiles': <String, dynamic>{},
        'factGraphSchema': <String, dynamic>{},
        'compatibility': <String, dynamic>{},
        'integrity': <String, dynamic>{},
        'extensions': {'custom': 'value'},
      });
      expect(bundle.ui, isNotNull);
      expect(bundle.flow, isNotNull);
      expect(bundle.skills, isNotNull);
      expect(bundle.knowledge, isNotNull);
      expect(bundle.bindings, isNotNull);
      expect(bundle.tests, isNotNull);
      expect(bundle.policies, isNotNull);
      expect(bundle.profiles, isNotNull);
      expect(bundle.factGraphSchema, isNotNull);
      expect(bundle.compatibility, isNotNull);
      expect(bundle.integrity, isNotNull);
      expect(bundle.extensions, {'custom': 'value'});
    });

    test('toJson omits null sections', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
      );
      final json = bundle.toJson();
      expect(json.containsKey('manifest'), isTrue);
      expect(json.containsKey('schemaVersion'), isTrue);
      expect(json.containsKey('ui'), isFalse);
      expect(json.containsKey('flow'), isFalse);
      expect(json.containsKey('skills'), isFalse);
      expect(json.containsKey('knowledge'), isFalse);
      expect(json.containsKey('bindings'), isFalse);
      expect(json.containsKey('tests'), isFalse);
      expect(json.containsKey('policies'), isFalse);
      expect(json.containsKey('profiles'), isFalse);
      expect(json.containsKey('factGraphSchema'), isFalse);
      expect(json.containsKey('compatibility'), isFalse);
      expect(json.containsKey('integrity'), isFalse);
      expect(json.containsKey('extensions'), isFalse);
    });

    test('copyWith preserves all sections', () {
      const original = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
        skills: SkillSection(),
        knowledge: KnowledgeSection(),
      );
      final copy = original.copyWith(
        policies: const PolicySection(),
      );
      expect(copy.skills, isNotNull);
      expect(copy.knowledge, isNotNull);
      expect(copy.policies, isNotNull);
    });

    test('schemaVersion defaults to 1.0.0', () {
      const bundle = McpBundle(
        manifest: BundleManifest(id: 'b', name: 'B', version: '1.0.0'),
      );
      expect(bundle.schemaVersion, '1.0.0');
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
