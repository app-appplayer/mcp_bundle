import 'package:test/test.dart';
// Import the schema file directly to avoid name collisions with
// models/manifest.dart which also defines BundleManifest/BundleDependency.
import 'package:mcp_bundle/src/schema/bundle_schema.dart';

void main() {
  // ── ResourceType ───────────────────────────────────────────────────────

  group('ResourceType', () {
    group('fromString', () {
      test('parses exact enum name', () {
        expect(ResourceType.fromString('skill'), equals(ResourceType.skill));
        expect(
            ResourceType.fromString('profile'), equals(ResourceType.profile));
        expect(ResourceType.fromString('factGraph'),
            equals(ResourceType.factGraph));
        expect(ResourceType.fromString('knowledgeOps'),
            equals(ResourceType.knowledgeOps));
        expect(ResourceType.fromString('data'), equals(ResourceType.data));
        expect(ResourceType.fromString('config'), equals(ResourceType.config));
        expect(
            ResourceType.fromString('template'), equals(ResourceType.template));
        expect(ResourceType.fromString('schema'), equals(ResourceType.schema));
        expect(
            ResourceType.fromString('unknown'), equals(ResourceType.unknown));
      });

      test('snake_case input does not match camelCase enum names', () {
        // _camelToSnake converts input to snake_case, then compares with e.name
        // which is camelCase. Since 'factGraph' != 'fact_graph', no match.
        expect(ResourceType.fromString('fact_graph'),
            equals(ResourceType.unknown));
        expect(ResourceType.fromString('knowledge_ops'),
            equals(ResourceType.unknown));
      });

      test('defaults to unknown for unrecognised values', () {
        expect(ResourceType.fromString('nonexistent'),
            equals(ResourceType.unknown));
        expect(ResourceType.fromString(''), equals(ResourceType.unknown));
        expect(ResourceType.fromString('invalid_type'),
            equals(ResourceType.unknown));
      });
    });
  });

  // ── BundleDependency ──────────────────────────────────────────────────

  group('BundleDependency', () {
    group('fromJson', () {
      test('parses all fields', () {
        final dep = BundleDependency.fromJson({
          'name': 'core-bundle',
          'version': '^1.0.0',
          'optional': true,
          'features': ['auth', 'logging'],
        });

        expect(dep.name, equals('core-bundle'));
        expect(dep.version, equals('^1.0.0'));
        expect(dep.optional, isTrue);
        expect(dep.features, equals(['auth', 'logging']));
      });

      test('applies defaults for missing fields', () {
        final dep = BundleDependency.fromJson(<String, dynamic>{});

        expect(dep.name, equals(''));
        expect(dep.version, equals('*'));
        expect(dep.optional, isFalse);
        expect(dep.features, isEmpty);
      });
    });

    group('toJson', () {
      test('serialises all populated fields', () {
        const dep = BundleDependency(
          name: 'dep-a',
          version: '>=2.0.0',
          optional: true,
          features: ['feature-x'],
        );
        final json = dep.toJson();

        expect(json['name'], equals('dep-a'));
        expect(json['version'], equals('>=2.0.0'));
        expect(json['optional'], isTrue);
        expect(json['features'], equals(['feature-x']));
      });

      test('omits optional when false', () {
        const dep = BundleDependency(name: 'd', version: '1.0.0');
        expect(dep.toJson().containsKey('optional'), isFalse);
      });

      test('omits features when empty', () {
        const dep = BundleDependency(name: 'd', version: '1.0.0');
        expect(dep.toJson().containsKey('features'), isFalse);
      });
    });

    group('JSON roundtrip', () {
      test('dependency survives roundtrip', () {
        const original = BundleDependency(
          name: 'dep-rt',
          version: '^3.0.0',
          optional: true,
          features: ['f1', 'f2'],
        );
        final restored = BundleDependency.fromJson(original.toJson());

        expect(restored.name, equals(original.name));
        expect(restored.version, equals(original.version));
        expect(restored.optional, equals(original.optional));
        expect(restored.features, equals(original.features));
      });

      test('minimal dependency survives roundtrip', () {
        const original = BundleDependency(name: 'min', version: '*');
        final restored = BundleDependency.fromJson(original.toJson());

        expect(restored.name, equals(original.name));
        expect(restored.version, equals(original.version));
        expect(restored.optional, isFalse);
        expect(restored.features, isEmpty);
      });
    });
  });

  // ── BundleManifest ────────────────────────────────────────────────────

  group('BundleManifest', () {
    group('fromJson', () {
      test('parses all fields', () {
        final manifest = BundleManifest.fromJson({
          'name': 'my-bundle',
          'version': '2.0.0',
          'description': 'A test bundle',
          'author': 'Author',
          'license': 'MIT',
          'homepage': 'https://example.com',
          'repository': 'https://github.com/example',
          'schemaVersion': '1.0.0',
          'entryPoint': 'main.json',
          'exports': ['skill-a', 'profile-b'],
          'capabilities': ['llm', 'storage'],
        });

        expect(manifest.name, equals('my-bundle'));
        expect(manifest.version, equals('2.0.0'));
        expect(manifest.description, equals('A test bundle'));
        expect(manifest.author, equals('Author'));
        expect(manifest.license, equals('MIT'));
        expect(manifest.homepage, equals('https://example.com'));
        expect(manifest.repository, equals('https://github.com/example'));
        expect(manifest.schemaVersion, equals('1.0.0'));
        expect(manifest.entryPoint, equals('main.json'));
        expect(manifest.exports, equals(['skill-a', 'profile-b']));
        expect(manifest.capabilities, equals(['llm', 'storage']));
      });

      test('applies defaults for missing fields', () {
        final manifest = BundleManifest.fromJson(<String, dynamic>{});

        expect(manifest.name, equals('unnamed'));
        expect(manifest.version, equals('0.0.0'));
        expect(manifest.description, isNull);
        expect(manifest.author, isNull);
        expect(manifest.license, isNull);
        expect(manifest.homepage, isNull);
        expect(manifest.repository, isNull);
        expect(manifest.schemaVersion, equals(bundleSchemaVersion));
        expect(manifest.entryPoint, isNull);
        expect(manifest.exports, isEmpty);
        expect(manifest.capabilities, isEmpty);
      });
    });

    group('toJson', () {
      test('serialises all populated fields', () {
        const manifest = BundleManifest(
          name: 'test',
          version: '1.0.0',
          description: 'desc',
          author: 'auth',
          license: 'MIT',
          homepage: 'https://home.com',
          repository: 'https://repo.com',
          entryPoint: 'entry.json',
          exports: ['exp-1'],
          capabilities: ['cap-1'],
        );
        final json = manifest.toJson();

        expect(json['name'], equals('test'));
        expect(json['version'], equals('1.0.0'));
        expect(json['description'], equals('desc'));
        expect(json['author'], equals('auth'));
        expect(json['license'], equals('MIT'));
        expect(json['homepage'], equals('https://home.com'));
        expect(json['repository'], equals('https://repo.com'));
        expect(json['schemaVersion'], equals(bundleSchemaVersion));
        expect(json['entryPoint'], equals('entry.json'));
        expect(json['exports'], equals(['exp-1']));
        expect(json['capabilities'], equals(['cap-1']));
      });

      test('omits null optional fields', () {
        const manifest = BundleManifest(name: 'min', version: '0.1.0');
        final json = manifest.toJson();

        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('author'), isFalse);
        expect(json.containsKey('license'), isFalse);
        expect(json.containsKey('homepage'), isFalse);
        expect(json.containsKey('repository'), isFalse);
        expect(json.containsKey('entryPoint'), isFalse);
      });

      test('omits empty lists', () {
        const manifest = BundleManifest(name: 'min', version: '0.1.0');
        final json = manifest.toJson();

        expect(json.containsKey('exports'), isFalse);
        expect(json.containsKey('capabilities'), isFalse);
      });
    });

    group('JSON roundtrip', () {
      test('fully populated manifest survives roundtrip', () {
        const original = BundleManifest(
          name: 'rt-bundle',
          version: '3.0.0',
          description: 'Roundtrip test',
          author: 'Tester',
          license: 'Apache-2.0',
          homepage: 'https://rt.example.com',
          repository: 'https://github.com/rt',
          entryPoint: 'index.json',
          exports: ['a', 'b'],
          capabilities: ['c', 'd'],
        );
        final restored = BundleManifest.fromJson(original.toJson());

        expect(restored.name, equals(original.name));
        expect(restored.version, equals(original.version));
        expect(restored.description, equals(original.description));
        expect(restored.author, equals(original.author));
        expect(restored.license, equals(original.license));
        expect(restored.homepage, equals(original.homepage));
        expect(restored.repository, equals(original.repository));
        expect(restored.schemaVersion, equals(original.schemaVersion));
        expect(restored.entryPoint, equals(original.entryPoint));
        expect(restored.exports, equals(original.exports));
        expect(restored.capabilities, equals(original.capabilities));
      });
    });
  });

  // ── BundleResource ────────────────────────────────────────────────────

  group('BundleResource', () {
    group('fromJson', () {
      test('parses all fields', () {
        final resource = BundleResource.fromJson({
          'path': 'skills/extract.json',
          'type': 'skill',
          'content': {'key': 'value'},
          'contentRef': 'https://cdn.example.com/extract.json',
          'encoding': 'utf-16',
          'metadata': {'version': '1.0'},
        });

        expect(resource.path, equals('skills/extract.json'));
        expect(resource.type, equals(ResourceType.skill));
        expect(resource.content, equals({'key': 'value'}));
        expect(resource.contentRef,
            equals('https://cdn.example.com/extract.json'));
        expect(resource.encoding, equals('utf-16'));
        expect(resource.metadata, equals({'version': '1.0'}));
      });

      test('applies defaults for missing fields', () {
        final resource = BundleResource.fromJson(<String, dynamic>{});

        expect(resource.path, equals(''));
        expect(resource.type, equals(ResourceType.unknown));
        expect(resource.content, isNull);
        expect(resource.contentRef, isNull);
        expect(resource.encoding, equals('utf-8'));
        expect(resource.metadata, isEmpty);
      });

      test('parses string content', () {
        final resource = BundleResource.fromJson({
          'path': 'data/file.txt',
          'type': 'data',
          'content': 'plain text content',
        });
        expect(resource.content, equals('plain text content'));
      });

      test('parses list content', () {
        final resource = BundleResource.fromJson({
          'path': 'data/list.json',
          'type': 'data',
          'content': [1, 2, 3],
        });
        expect(resource.content, equals([1, 2, 3]));
      });
    });

    group('toJson', () {
      test('serialises all populated fields', () {
        const resource = BundleResource(
          path: 'profiles/main.json',
          type: ResourceType.profile,
          content: 'inline-content',
          contentRef: '/ref/path',
          encoding: 'ascii',
          metadata: {'tag': 'v1'},
        );
        final json = resource.toJson();

        expect(json['path'], equals('profiles/main.json'));
        expect(json['type'], equals('profile'));
        expect(json['content'], equals('inline-content'));
        expect(json['contentRef'], equals('/ref/path'));
        expect(json['encoding'], equals('ascii'));
        expect(json['metadata'], equals({'tag': 'v1'}));
      });

      test('omits null content and contentRef', () {
        const resource = BundleResource(
          path: 'p',
          type: ResourceType.data,
        );
        final json = resource.toJson();

        expect(json.containsKey('content'), isFalse);
        expect(json.containsKey('contentRef'), isFalse);
      });

      test('omits empty metadata', () {
        const resource = BundleResource(
          path: 'p',
          type: ResourceType.data,
        );
        expect(resource.toJson().containsKey('metadata'), isFalse);
      });

      test('always includes encoding', () {
        const resource = BundleResource(
          path: 'p',
          type: ResourceType.data,
        );
        expect(resource.toJson()['encoding'], equals('utf-8'));
      });
    });

    group('hasInlineContent', () {
      test('returns true when content is set', () {
        const resource = BundleResource(
          path: 'p',
          type: ResourceType.data,
          content: 'some data',
        );
        expect(resource.hasInlineContent, isTrue);
      });

      test('returns false when content is null', () {
        const resource = BundleResource(
          path: 'p',
          type: ResourceType.data,
        );
        expect(resource.hasInlineContent, isFalse);
      });
    });

    group('hasExternalContent', () {
      test('returns true when contentRef is set', () {
        const resource = BundleResource(
          path: 'p',
          type: ResourceType.data,
          contentRef: 'https://example.com/file',
        );
        expect(resource.hasExternalContent, isTrue);
      });

      test('returns false when contentRef is null', () {
        const resource = BundleResource(
          path: 'p',
          type: ResourceType.data,
        );
        expect(resource.hasExternalContent, isFalse);
      });
    });

    group('JSON roundtrip', () {
      test('resource with inline content survives roundtrip', () {
        const original = BundleResource(
          path: 'data/file.json',
          type: ResourceType.data,
          content: 'raw content',
          encoding: 'utf-8',
          metadata: {'size': 42},
        );
        final restored = BundleResource.fromJson(original.toJson());

        expect(restored.path, equals(original.path));
        expect(restored.type, equals(original.type));
        expect(restored.content, equals(original.content));
        expect(restored.encoding, equals(original.encoding));
        expect(restored.metadata, equals(original.metadata));
      });

      test('resource with external ref survives roundtrip', () {
        const original = BundleResource(
          path: 'schemas/def.json',
          type: ResourceType.schema,
          contentRef: 'https://example.com/def.json',
        );
        final restored = BundleResource.fromJson(original.toJson());

        expect(restored.path, equals(original.path));
        expect(restored.type, equals(original.type));
        expect(restored.contentRef, equals(original.contentRef));
        expect(restored.content, isNull);
      });
    });
  });

  // ── Bundle ─────────────────────────────────────────────────────────────

  group('Bundle', () {
    Bundle fullBundle() => const Bundle(
          manifest: BundleManifest(
            name: 'test-bundle',
            version: '1.0.0',
            description: 'Test bundle',
          ),
          resources: [
            BundleResource(
              path: 'skills/a.json',
              type: ResourceType.skill,
              content: 'skill-content',
            ),
          ],
          dependencies: [
            BundleDependency(
              name: 'dep-1',
              version: '^1.0.0',
              optional: true,
              features: ['feat'],
            ),
          ],
          metadata: {'env': 'test'},
        );

    group('fromJson', () {
      test('parses all fields including nested objects', () {
        final json = {
          'manifest': {
            'name': 'parsed-bundle',
            'version': '2.0.0',
          },
          'resources': [
            {
              'path': 'profiles/p.json',
              'type': 'profile',
              'content': 'profile-data',
            },
          ],
          'dependencies': [
            {'name': 'core', 'version': '^1.0.0'},
          ],
          'metadata': {'key': 'val'},
        };

        final bundle = Bundle.fromJson(json);

        expect(bundle.manifest.name, equals('parsed-bundle'));
        expect(bundle.manifest.version, equals('2.0.0'));
        expect(bundle.resources, hasLength(1));
        expect(bundle.resources.first.path, equals('profiles/p.json'));
        expect(bundle.resources.first.type, equals(ResourceType.profile));
        expect(bundle.dependencies, hasLength(1));
        expect(bundle.dependencies.first.name, equals('core'));
        expect(bundle.metadata, equals({'key': 'val'}));
      });

      test('applies defaults for missing fields', () {
        final bundle = Bundle.fromJson(<String, dynamic>{});

        expect(bundle.manifest.name, equals('unnamed'));
        expect(bundle.manifest.version, equals('0.0.0'));
        expect(bundle.resources, isEmpty);
        expect(bundle.dependencies, isEmpty);
        expect(bundle.metadata, isEmpty);
      });

      test('parses bundle with empty manifest', () {
        final bundle = Bundle.fromJson({
          'manifest': <String, dynamic>{},
        });
        expect(bundle.manifest.name, equals('unnamed'));
      });

      test('parses bundle with multiple resources', () {
        final bundle = Bundle.fromJson({
          'manifest': {'name': 'multi', 'version': '1.0.0'},
          'resources': [
            {'path': 'a.json', 'type': 'skill'},
            {'path': 'b.json', 'type': 'profile'},
            {'path': 'c.json', 'type': 'data'},
          ],
        });
        expect(bundle.resources, hasLength(3));
        expect(bundle.resources[0].type, equals(ResourceType.skill));
        expect(bundle.resources[1].type, equals(ResourceType.profile));
        expect(bundle.resources[2].type, equals(ResourceType.data));
      });
    });

    group('toJson', () {
      test('serialises all fields', () {
        final json = fullBundle().toJson();

        expect(json['manifest'], isA<Map<String, dynamic>>());
        expect((json['manifest'] as Map<String, dynamic>)['name'],
            equals('test-bundle'));
        expect(json['resources'], isA<List<dynamic>>());
        expect(json['resources'] as List<dynamic>, hasLength(1));
        expect(json['dependencies'], isA<List<dynamic>>());
        expect(json['dependencies'] as List<dynamic>, hasLength(1));
        expect(json['metadata'], equals({'env': 'test'}));
      });

      test('serialises empty bundle correctly', () {
        const bundle = Bundle(
          manifest: BundleManifest(name: 'empty', version: '0.0.0'),
        );
        final json = bundle.toJson();

        expect(json['resources'], isA<List<dynamic>>());
        expect(json['resources'] as List<dynamic>, isEmpty);
        expect(json['dependencies'], isA<List<dynamic>>());
        expect(json['dependencies'] as List<dynamic>, isEmpty);
        expect(json['metadata'], isEmpty);
      });
    });

    group('copyWith', () {
      test('returns equivalent bundle when no overrides given', () {
        final original = fullBundle();
        final copied = original.copyWith();

        expect(copied.manifest.name, equals(original.manifest.name));
        expect(copied.resources.length, equals(original.resources.length));
        expect(
            copied.dependencies.length, equals(original.dependencies.length));
        expect(copied.metadata, equals(original.metadata));
      });

      test('overrides manifest only', () {
        final original = fullBundle();
        final copied = original.copyWith(
          manifest:
              const BundleManifest(name: 'overridden', version: '9.0.0'),
        );

        expect(copied.manifest.name, equals('overridden'));
        expect(copied.manifest.version, equals('9.0.0'));
        // Other fields remain unchanged
        expect(copied.resources.length, equals(original.resources.length));
        expect(copied.metadata, equals(original.metadata));
      });

      test('overrides resources only', () {
        final original = fullBundle();
        final copied = original.copyWith(resources: []);

        expect(copied.resources, isEmpty);
        expect(copied.manifest.name, equals(original.manifest.name));
      });

      test('overrides dependencies only', () {
        final original = fullBundle();
        final copied = original.copyWith(dependencies: []);

        expect(copied.dependencies, isEmpty);
        expect(copied.manifest.name, equals(original.manifest.name));
      });

      test('overrides metadata only', () {
        final original = fullBundle();
        final copied = original.copyWith(metadata: {'new': true});

        expect(copied.metadata, equals({'new': true}));
        expect(copied.manifest.name, equals(original.manifest.name));
      });
    });

    group('JSON roundtrip', () {
      test('fully populated bundle survives roundtrip', () {
        final original = fullBundle();
        final restored = Bundle.fromJson(original.toJson());

        expect(restored.manifest.name, equals(original.manifest.name));
        expect(restored.manifest.version, equals(original.manifest.version));
        expect(restored.manifest.description,
            equals(original.manifest.description));
        expect(restored.resources.length, equals(original.resources.length));
        expect(restored.resources.first.path,
            equals(original.resources.first.path));
        expect(restored.resources.first.type,
            equals(original.resources.first.type));
        expect(restored.dependencies.length,
            equals(original.dependencies.length));
        expect(restored.dependencies.first.name,
            equals(original.dependencies.first.name));
        expect(restored.metadata, equals(original.metadata));
      });

      test('minimal bundle survives roundtrip', () {
        const original = Bundle(
          manifest: BundleManifest(name: 'min', version: '0.0.1'),
        );
        final restored = Bundle.fromJson(original.toJson());

        expect(restored.manifest.name, equals('min'));
        expect(restored.manifest.version, equals('0.0.1'));
        expect(restored.resources, isEmpty);
        expect(restored.dependencies, isEmpty);
      });
    });
  });

  // ── bundleSchemaVersion constant ───────────────────────────────────────

  group('bundleSchemaVersion', () {
    test('is a valid semver string', () {
      expect(bundleSchemaVersion, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    });

    test('equals 1.0.0', () {
      expect(bundleSchemaVersion, equals('1.0.0'));
    });
  });
}
