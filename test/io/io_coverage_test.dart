/// Comprehensive coverage tests for the io/ directory.
///
/// Covers uncovered code paths in:
/// - loader_options.dart
/// - bundle_loader.dart
/// - exceptions.dart
/// - mcp_bundle_loader.dart
/// - http_storage_adapter.dart
/// - type_coercion.dart
/// - bundle_repository.dart
import 'dart:convert';

import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:mcp_bundle/src/io/bundle_loader.dart';
import 'package:mcp_bundle/src/schema/bundle_schema.dart' as schema;
import 'package:mcp_bundle/src/io/http_storage_adapter.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal valid bundle JSON for BundleLoader (uses schema/bundle_schema.dart).
Map<String, dynamic> _schemaBundleJson({
  String name = 'test-bundle',
  String version = '1.0.0',
  List<Map<String, dynamic>>? resources,
  List<Map<String, dynamic>>? dependencies,
}) {
  return {
    'manifest': {
      'name': name,
      'version': version,
    },
    if (resources != null) 'resources': resources,
    if (dependencies != null) 'dependencies': dependencies,
  };
}

/// Minimal valid bundle JSON for McpBundleLoader (uses models/).
Map<String, dynamic> _mcpBundleJson({
  String id = 'test-bundle',
  String name = 'Test Bundle',
  String version = '1.0.0',
  String schemaVersion = '1.0.0',
}) {
  return {
    'schemaVersion': schemaVersion,
    'manifest': {
      'id': id,
      'name': name,
      'version': version,
    },
  };
}

void main() {
  // ==========================================================================
  // 1. loader_options.dart
  // ==========================================================================

  group('LoaderOptions', () {
    test('default constructor has expected defaults', () {
      const opts = LoaderOptions();
      expect(opts.validate, isTrue);
      expect(opts.resolveRefs, isTrue);
      expect(opts.loadDependencies, isTrue);
      expect(opts.maxDepth, equals(10));
      expect(opts.basePath, isNull);
      expect(opts.contentResolver, isNull);
      expect(opts.dependencyResolver, isNull);
      expect(opts.cache, isTrue);
      expect(opts.allowMissingOptional, isTrue);
    });

    test('strict() factory enables validation and disallows missing optional', () {
      final opts = LoaderOptions.strict();
      expect(opts.validate, isTrue);
      expect(opts.resolveRefs, isTrue);
      expect(opts.loadDependencies, isTrue);
      expect(opts.allowMissingOptional, isFalse);
      // Defaults retained
      expect(opts.maxDepth, equals(10));
      expect(opts.cache, isTrue);
    });

    test('lenient() factory disables validation and dependency loading', () {
      final opts = LoaderOptions.lenient();
      expect(opts.validate, isFalse);
      expect(opts.resolveRefs, isFalse);
      expect(opts.loadDependencies, isFalse);
      // Defaults for unset fields
      expect(opts.allowMissingOptional, isTrue);
      expect(opts.cache, isTrue);
    });

    test('copyWith overrides all fields', () {
      const original = LoaderOptions();
      final copied = original.copyWith(
        validate: false,
        resolveRefs: false,
        loadDependencies: false,
        maxDepth: 5,
        basePath: '/tmp',
        cache: false,
        allowMissingOptional: false,
      );
      expect(copied.validate, isFalse);
      expect(copied.resolveRefs, isFalse);
      expect(copied.loadDependencies, isFalse);
      expect(copied.maxDepth, equals(5));
      expect(copied.basePath, equals('/tmp'));
      expect(copied.cache, isFalse);
      expect(copied.allowMissingOptional, isFalse);
    });

    test('copyWith retains original values when no overrides', () {
      final original = LoaderOptions.strict();
      final copied = original.copyWith();
      expect(copied.validate, equals(original.validate));
      expect(copied.resolveRefs, equals(original.resolveRefs));
      expect(copied.loadDependencies, equals(original.loadDependencies));
      expect(copied.maxDepth, equals(original.maxDepth));
      expect(copied.cache, equals(original.cache));
      expect(copied.allowMissingOptional, equals(original.allowMissingOptional));
    });

    test('copyWith with contentResolver and dependencyResolver', () {
      final resolver = FileContentResolver(rootPath: '/root');
      final copied = const LoaderOptions().copyWith(
        contentResolver: resolver,
      );
      expect(copied.contentResolver, same(resolver));
    });
  });

  group('FileContentResolver', () {
    test('resolve() throws UnimplementedError', () async {
      const resolver = FileContentResolver();
      expect(
        () => resolver.resolve('some-ref'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('resolve() with basePath throws UnimplementedError', () async {
      const resolver = FileContentResolver(rootPath: '/root');
      expect(
        () => resolver.resolve('ref', basePath: '/base'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('canResolve() returns true for file:// references', () async {
      const resolver = FileContentResolver();
      expect(await resolver.canResolve('file://path/to/file'), isTrue);
    });

    test('canResolve() returns true for references without scheme', () async {
      const resolver = FileContentResolver();
      expect(await resolver.canResolve('relative/path'), isTrue);
      expect(await resolver.canResolve('file.txt'), isTrue);
    });

    test('canResolve() returns false for http:// references', () async {
      const resolver = FileContentResolver();
      expect(await resolver.canResolve('http://example.com'), isFalse);
    });

    test('canResolve() returns false for https:// references', () async {
      const resolver = FileContentResolver();
      expect(await resolver.canResolve('https://example.com'), isFalse);
    });

    test('canResolve() returns false for custom scheme references', () async {
      const resolver = FileContentResolver();
      expect(await resolver.canResolve('ftp://example.com'), isFalse);
    });
  });

  group('LoadResult', () {
    test('ok() creates successful result with value', () {
      final result = LoadResult<String>.ok('hello');
      expect(result.success, isTrue);
      expect(result.value, equals('hello'));
      expect(result.error, isNull);
      expect(result.warnings, isEmpty);
    });

    test('ok() with warnings', () {
      final result = LoadResult<int>.ok(42, warnings: ['warn1', 'warn2']);
      expect(result.success, isTrue);
      expect(result.value, equals(42));
      expect(result.warnings, hasLength(2));
    });

    test('fail() creates failed result with error', () {
      final result = LoadResult<String>.fail('something broke');
      expect(result.success, isFalse);
      expect(result.value, isNull);
      expect(result.error, equals('something broke'));
      expect(result.warnings, isEmpty);
    });

    test('fail() with warnings', () {
      final result =
          LoadResult<String>.fail('error', warnings: ['warning']);
      expect(result.success, isFalse);
      expect(result.error, equals('error'));
      expect(result.warnings, equals(['warning']));
    });

    test('map() transforms value on success', () {
      final original = LoadResult<int>.ok(10);
      final mapped = original.map((v) => v * 2);
      expect(mapped.success, isTrue);
      expect(mapped.value, equals(20));
      expect(mapped.warnings, isEmpty);
    });

    test('map() preserves warnings on success', () {
      final original = LoadResult<int>.ok(5, warnings: ['w']);
      final mapped = original.map((v) => 'value: $v');
      expect(mapped.success, isTrue);
      expect(mapped.value, equals('value: 5'));
      expect(mapped.warnings, equals(['w']));
    });

    test('map() propagates failure without calling mapper', () {
      final original = LoadResult<int>.fail('failed', warnings: ['w']);
      var mapperCalled = false;
      final mapped = original.map((v) {
        mapperCalled = true;
        return v.toString();
      });
      expect(mapperCalled, isFalse);
      expect(mapped.success, isFalse);
      expect(mapped.error, equals('failed'));
      expect(mapped.warnings, equals(['w']));
    });

    test('map() handles success with null value', () {
      const original = LoadResult<String>(success: true, value: null);
      var mapperCalled = false;
      final mapped = original.map((v) {
        mapperCalled = true;
        return v.length;
      });
      expect(mapperCalled, isFalse);
      expect(mapped.success, isTrue);
      expect(mapped.value, isNull);
    });

    test('default constructor with metadata', () {
      const result = LoadResult<String>(
        success: true,
        value: 'test',
        metadata: {'key': 'val'},
      );
      expect(result.metadata['key'], equals('val'));
    });

    test('map() preserves metadata', () {
      const original = LoadResult<int>(
        success: true,
        value: 1,
        metadata: {'k': 'v'},
      );
      final mapped = original.map((v) => v + 1);
      expect(mapped.metadata['k'], equals('v'));
    });
  });

  group('BundleSource', () {
    test('file() creates source with SourceType.file', () {
      final source = BundleSource.file('/path/to/manifest.json');
      expect(source.type, equals(SourceType.file));
      expect(source.source, equals('/path/to/manifest.json'));
      expect(source.metadata, isEmpty);
    });

    test('url() creates source with SourceType.url', () {
      final source = BundleSource.url('https://example.com/manifest.json');
      expect(source.type, equals(SourceType.url));
      expect(source.source, equals('https://example.com/manifest.json'));
    });

    test('json() creates source with SourceType.json', () {
      final data = {'manifest': {'name': 'test'}};
      final source = BundleSource.json(data);
      expect(source.type, equals(SourceType.json));
      expect(source.source, same(data));
    });

    test('string() creates source with SourceType.string', () {
      final source = BundleSource.string('{"test": true}');
      expect(source.type, equals(SourceType.string));
      expect(source.source, equals('{"test": true}'));
    });

    test('default constructor with metadata', () {
      const source = BundleSource(
        type: SourceType.file,
        source: '/path',
        metadata: {'origin': 'test'},
      );
      expect(source.metadata['origin'], equals('test'));
    });
  });

  // ==========================================================================
  // 2. bundle_loader.dart
  // ==========================================================================

  group('BundleLoader', () {
    group('load with BundleSource.json', () {
      test('successfully loads a valid bundle', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(validate: false, resolveRefs: false),
        );
        final result = await loader.load(BundleSource.json(_schemaBundleJson()));
        expect(result.success, isTrue);
        expect(result.value, isNotNull);
        expect(result.value!.manifest.name, equals('test-bundle'));
      });

      test('caches loaded bundle when cache is enabled', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(
            validate: false,
            resolveRefs: false,
            cache: true,
          ),
        );
        await loader.load(BundleSource.json(_schemaBundleJson()));
        expect(loader.isCached('test-bundle'), isTrue);
        expect(loader.getCached('test-bundle'), isNotNull);
      });

      test('does not cache when cache is disabled', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(
            validate: false,
            resolveRefs: false,
            cache: false,
          ),
        );
        await loader.load(BundleSource.json(_schemaBundleJson()));
        expect(loader.isCached('test-bundle'), isFalse);
      });
    });

    group('load with BundleSource.string', () {
      test('successfully parses JSON string', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(validate: false, resolveRefs: false),
        );
        final json = jsonEncode(_schemaBundleJson());
        final result = await loader.load(BundleSource.string(json));
        expect(result.success, isTrue);
        expect(result.value!.manifest.name, equals('test-bundle'));
      });

      test('fails on invalid JSON string', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(validate: false, resolveRefs: false),
        );
        final result = await loader.load(BundleSource.string('not json'));
        expect(result.success, isFalse);
        expect(result.error, contains('Failed to load bundle'));
      });
    });

    group('load with BundleSource.file', () {
      test('returns failure with UnimplementedError', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(validate: false, resolveRefs: false),
        );
        final result = await loader.load(BundleSource.file('/some/path'));
        expect(result.success, isFalse);
        expect(result.error, contains('Failed to load bundle'));
      });
    });

    group('load with validation enabled', () {
      test('valid bundle passes validation', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(validate: true, resolveRefs: false),
        );
        final json = _schemaBundleJson(
          name: 'valid-bundle',
          version: '1.0.0',
          resources: [
            {
              'path': 'skill.yaml',
              'type': 'skill',
              'content': 'test content',
            },
          ],
        );
        final result = await loader.load(BundleSource.json(json));
        expect(result.success, isTrue);
      });

      test('invalid bundle fails validation - empty name', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(validate: true, resolveRefs: false),
        );
        final json = _schemaBundleJson(name: '', version: '1.0.0');
        final result = await loader.load(BundleSource.json(json));
        expect(result.success, isFalse);
        expect(result.error, contains('Validation failed'));
        expect(result.warnings, isNotEmpty);
      });

      test('invalid bundle fails validation - empty version', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(validate: true, resolveRefs: false),
        );
        final json = _schemaBundleJson(name: 'test', version: '');
        final result = await loader.load(BundleSource.json(json));
        expect(result.success, isFalse);
        expect(result.error, contains('Validation failed'));
      });

      test('invalid bundle fails validation - bad version format', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(validate: true, resolveRefs: false),
        );
        final json = _schemaBundleJson(name: 'test', version: 'not-semver');
        final result = await loader.load(BundleSource.json(json));
        expect(result.success, isFalse);
        expect(result.error, contains('Invalid version format'));
      });

      test('validation catches resource with no content', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(validate: true, resolveRefs: false),
        );
        final json = _schemaBundleJson(
          resources: [
            {'path': 'empty.txt', 'type': 'data'},
          ],
        );
        final result = await loader.load(BundleSource.json(json));
        expect(result.success, isFalse);
        expect(result.error, contains('has no content'));
      });

      test('validation catches empty resource path', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(validate: true, resolveRefs: false),
        );
        final json = _schemaBundleJson(
          resources: [
            {'path': '', 'type': 'data', 'content': 'something'},
          ],
        );
        final result = await loader.load(BundleSource.json(json));
        expect(result.success, isFalse);
        expect(result.error, contains('Resource path is required'));
      });

      test('validation catches empty dependency name', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(validate: true, resolveRefs: false),
        );
        final json = _schemaBundleJson(
          dependencies: [
            {'name': '', 'version': '1.0.0'},
          ],
        );
        final result = await loader.load(BundleSource.json(json));
        expect(result.success, isFalse);
        expect(result.error, contains('Dependency name is required'));
      });

      test('version with pre-release suffix is valid', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(validate: true, resolveRefs: false),
        );
        final json = _schemaBundleJson(version: '1.0.0-beta.1');
        final result = await loader.load(BundleSource.json(json));
        expect(result.success, isTrue);
      });

      test('version with build metadata is valid', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(validate: true, resolveRefs: false),
        );
        final json = _schemaBundleJson(version: '1.0.0+build.42');
        final result = await loader.load(BundleSource.json(json));
        expect(result.success, isTrue);
      });
    });

    group('loadFromJson convenience', () {
      test('delegates to load with BundleSource.json', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(validate: false, resolveRefs: false),
        );
        final result = await loader.loadFromJson(_schemaBundleJson());
        expect(result.success, isTrue);
        expect(result.value!.manifest.name, equals('test-bundle'));
      });
    });

    group('loadFromString convenience', () {
      test('delegates to load with BundleSource.string', () async {
        final loader = BundleLoader(
          options: const LoaderOptions(validate: false, resolveRefs: false),
        );
        final json = jsonEncode(_schemaBundleJson());
        final result = await loader.loadFromString(json);
        expect(result.success, isTrue);
      });
    });

    group('cache operations', () {
      late BundleLoader loader;

      setUp(() {
        loader = BundleLoader(
          options: const LoaderOptions(
            validate: false,
            resolveRefs: false,
            cache: true,
          ),
        );
      });

      test('getCached returns null for uncached bundle', () {
        expect(loader.getCached('nonexistent'), isNull);
      });

      test('isCached returns false for uncached bundle', () {
        expect(loader.isCached('nonexistent'), isFalse);
      });

      test('clearCache removes all cached bundles', () async {
        await loader.load(BundleSource.json(
          _schemaBundleJson(name: 'bundle-a'),
        ));
        await loader.load(BundleSource.json(
          _schemaBundleJson(name: 'bundle-b'),
        ));
        expect(loader.isCached('bundle-a'), isTrue);
        expect(loader.isCached('bundle-b'), isTrue);

        loader.clearCache();
        expect(loader.isCached('bundle-a'), isFalse);
        expect(loader.isCached('bundle-b'), isFalse);
      });

      test('removeFromCache removes specific bundle', () async {
        await loader.load(BundleSource.json(
          _schemaBundleJson(name: 'to-remove'),
        ));
        await loader.load(BundleSource.json(
          _schemaBundleJson(name: 'to-keep'),
        ));
        expect(loader.isCached('to-remove'), isTrue);

        loader.removeFromCache('to-remove');
        expect(loader.isCached('to-remove'), isFalse);
        expect(loader.isCached('to-keep'), isTrue);
      });

      test('removeFromCache is no-op for uncached name', () {
        // Should not throw
        loader.removeFromCache('nonexistent');
      });
    });
  });

  group('BundleBuilder', () {
    test('builds bundle with defaults', () {
      final bundle = BundleBuilder().build();
      expect(bundle.manifest.name, equals('unnamed'));
      expect(bundle.manifest.version, equals('0.0.1'));
      expect(bundle.manifest.description, isNull);
      expect(bundle.manifest.author, isNull);
      expect(bundle.manifest.license, isNull);
      expect(bundle.resources, isEmpty);
      expect(bundle.dependencies, isEmpty);
      expect(bundle.metadata, isEmpty);
    });

    test('builds bundle with all fields set', () {
      final bundle = BundleBuilder()
          .name('my-bundle')
          .version('2.0.0')
          .description('A test bundle')
          .author('Test Author')
          .license('MIT')
          .addResource(const schema.BundleResource(
            path: 'skill.yaml',
            type: schema.ResourceType.skill,
            content: 'content',
          ))
          .addDependency(const schema.BundleDependency(
            name: 'dep-a',
            version: '^1.0.0',
          ))
          .addMetadata('key1', 'value1')
          .addMetadata('key2', 42)
          .build();

      expect(bundle.manifest.name, equals('my-bundle'));
      expect(bundle.manifest.version, equals('2.0.0'));
      expect(bundle.manifest.description, equals('A test bundle'));
      expect(bundle.manifest.author, equals('Test Author'));
      expect(bundle.manifest.license, equals('MIT'));
      expect(bundle.resources, hasLength(1));
      expect(bundle.resources.first.path, equals('skill.yaml'));
      expect(bundle.dependencies, hasLength(1));
      expect(bundle.dependencies.first.name, equals('dep-a'));
      expect(bundle.metadata['key1'], equals('value1'));
      expect(bundle.metadata['key2'], equals(42));
    });

    test('fluent API returns the same builder', () {
      final builder = BundleBuilder();
      expect(builder.name('test'), same(builder));
      expect(builder.version('1.0.0'), same(builder));
      expect(builder.description('desc'), same(builder));
      expect(builder.author('author'), same(builder));
      expect(builder.license('MIT'), same(builder));
      expect(
        builder.addResource(const schema.BundleResource(
          path: 'p',
          type: schema.ResourceType.data,
        )),
        same(builder),
      );
      expect(
        builder.addDependency(const schema.BundleDependency(
          name: 'dep',
          version: '*',
        )),
        same(builder),
      );
      expect(builder.addMetadata('k', 'v'), same(builder));
    });

    test('build produces unmodifiable resources and dependencies', () {
      final bundle = BundleBuilder()
          .addResource(const schema.BundleResource(
            path: 'a',
            type: schema.ResourceType.data,
            content: 'x',
          ))
          .addDependency(const schema.BundleDependency(
            name: 'dep',
            version: '*',
          ))
          .build();

      // Unmodifiable lists throw UnsupportedError on mutation
      expect(
        () => bundle.resources.add(const schema.BundleResource(
          path: 'extra',
          type: schema.ResourceType.data,
        )),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => bundle.dependencies.add(const schema.BundleDependency(
          name: 'extra-dep',
          version: '*',
        )),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('BundleExtensions', () {
    test('getResource returns matching resource', () {
      final bundle = schema.Bundle(
        manifest: const schema.BundleManifest(name: 'test', version: '1.0.0'),
        resources: const [
          schema.BundleResource(
            path: 'skills/greet.yaml',
            type: schema.ResourceType.skill,
            content: 'test',
          ),
          schema.BundleResource(
            path: 'data/config.json',
            type: schema.ResourceType.config,
            content: '{}',
          ),
        ],
      );
      final found = bundle.getResource('skills/greet.yaml');
      expect(found, isNotNull);
      expect(found!.type, equals(schema.ResourceType.skill));
    });

    test('getResource returns null for non-existing path', () {
      const bundle = schema.Bundle(
        manifest: schema.BundleManifest(name: 'test', version: '1.0.0'),
      );
      expect(bundle.getResource('nonexistent'), isNull);
    });

    test('getResourcesByType returns filtered list', () {
      final bundle = schema.Bundle(
        manifest: const schema.BundleManifest(name: 'test', version: '1.0.0'),
        resources: const [
          schema.BundleResource(
            path: 'a.yaml',
            type: schema.ResourceType.skill,
            content: 's1',
          ),
          schema.BundleResource(
            path: 'b.yaml',
            type: schema.ResourceType.skill,
            content: 's2',
          ),
          schema.BundleResource(
            path: 'c.json',
            type: schema.ResourceType.config,
            content: '{}',
          ),
        ],
      );
      final skills = bundle.getResourcesByType(schema.ResourceType.skill);
      expect(skills, hasLength(2));
    });

    test('getResourcesByType returns empty for no matches', () {
      const bundle = schema.Bundle(
        manifest: schema.BundleManifest(name: 'test', version: '1.0.0'),
      );
      expect(bundle.getResourcesByType(schema.ResourceType.profile), isEmpty);
    });

    test('hasCapability checks capabilities list', () {
      const bundle = schema.Bundle(
        manifest: schema.BundleManifest(
          name: 'test',
          version: '1.0.0',
          capabilities: ['llm', 'rag'],
        ),
      );
      expect(bundle.hasCapability('llm'), isTrue);
      expect(bundle.hasCapability('rag'), isTrue);
      expect(bundle.hasCapability('nonexistent'), isFalse);
    });

    test('skills getter returns skill-type resources', () {
      final bundle = schema.Bundle(
        manifest: const schema.BundleManifest(name: 'test', version: '1.0.0'),
        resources: const [
          schema.BundleResource(
            path: 'skill1.yaml',
            type: schema.ResourceType.skill,
            content: 'skill',
          ),
          schema.BundleResource(
            path: 'profile.yaml',
            type: schema.ResourceType.profile,
            content: 'prof',
          ),
        ],
      );
      expect(bundle.skills, hasLength(1));
      expect(bundle.skills.first.path, equals('skill1.yaml'));
    });

    test('profiles getter returns profile-type resources', () {
      final bundle = schema.Bundle(
        manifest: const schema.BundleManifest(name: 'test', version: '1.0.0'),
        resources: const [
          schema.BundleResource(
            path: 'profile.yaml',
            type: schema.ResourceType.profile,
            content: 'prof',
          ),
        ],
      );
      expect(bundle.profiles, hasLength(1));
    });

    test('factGraphs getter returns factGraph-type resources', () {
      final bundle = schema.Bundle(
        manifest: const schema.BundleManifest(name: 'test', version: '1.0.0'),
        resources: const [
          schema.BundleResource(
            path: 'fg.json',
            type: schema.ResourceType.factGraph,
            content: '{}',
          ),
        ],
      );
      expect(bundle.factGraphs, hasLength(1));
    });
  });

  // ==========================================================================
  // 3. exceptions.dart
  // ==========================================================================

  group('Exceptions - toString coverage', () {
    test('BundleLoadException.toString', () {
      final e = BundleLoadException('test error');
      expect(e.toString(), equals('BundleLoadException: test error'));
    });

    test('BundleParseException.toString without line', () {
      final e = BundleParseException('parse error');
      expect(e.toString(), equals('BundleParseException: parse error'));
    });

    test('BundleParseException.toString with line', () {
      final e = BundleParseException('parse error', line: 42);
      expect(e.toString(),
          equals('BundleParseException: parse error at line 42'));
    });

    test('BundleMissingFieldException.toString', () {
      final e = BundleMissingFieldException('manifest.name');
      expect(e.toString(),
          equals('BundleMissingFieldException: Missing field "manifest.name"'));
    });

    test('BundleInvalidValueException.toString', () {
      final e = BundleInvalidValueException('field', 42, 'string');
      expect(
        e.toString(),
        equals(
          'BundleInvalidValueException: Invalid value at "field": expected string',
        ),
      );
    });

    test('BundleSchemaVersionException.toString', () {
      final e = BundleSchemaVersionException('3.0.0', ['1.0.0', '2.0.0']);
      expect(e.toString(), contains('"3.0.0"'));
      expect(e.toString(), contains('1.0.0, 2.0.0'));
    });

    test('BundleReferenceException.toString', () {
      final e = BundleReferenceException('my-ref', 'asset');
      expect(e.toString(),
          equals('BundleReferenceException: Unresolved asset reference "my-ref"'));
    });

    test('BundleValidationException.toString', () {
      final e = BundleValidationException(
        'Validation failed',
        errors: [BundleMissingFieldException('a'), BundleMissingFieldException('b')],
        warnings: ['w1'],
      );
      expect(e.toString(), contains('2 errors'));
      expect(e.toString(), contains('1 warnings'));
    });

    test('BundleValidationException.toString with no errors or warnings', () {
      final e = BundleValidationException('Empty validation');
      expect(e.toString(), contains('0 errors'));
      expect(e.toString(), contains('0 warnings'));
    });

    test('BundleNotFoundException.toString', () {
      final e = BundleNotFoundException(Uri.parse('file:///missing.json'));
      expect(e.toString(), contains('file:///missing.json'));
      expect(e.toString(), startsWith('BundleNotFoundException:'));
    });

    test('AssetNotFoundException.toString', () {
      final e = AssetNotFoundException(Uri.parse('asset://image.png'));
      expect(e.toString(), contains('asset://image.png'));
      expect(e.toString(), startsWith('AssetNotFoundException:'));
    });

    test('BundleWriteException.toString without URI', () {
      final e = BundleWriteException('write failed');
      expect(e.toString(), equals('BundleWriteException: write failed'));
    });

    test('BundleWriteException.toString with URI', () {
      final e = BundleWriteException(
        'write failed',
        uri: Uri.parse('file:///manifest.json'),
      );
      expect(e.toString(), contains('write failed'));
      expect(e.toString(), contains('file:///manifest.json'));
    });

    test('BundleReadException.toString without URI', () {
      final e = BundleReadException('read failed');
      expect(e.toString(), equals('BundleReadException: read failed'));
    });

    test('BundleReadException.toString with URI', () {
      final e = BundleReadException(
        'read failed',
        uri: Uri.parse('http://example.com/bundle'),
      );
      expect(e.toString(), contains('read failed'));
      expect(e.toString(), contains('http://example.com/bundle'));
    });

    test('BundleIntegrityException.toString without expected/actual', () {
      final e = BundleIntegrityException(
        'hash mismatch',
        checkType: 'sha256',
      );
      expect(e.toString(), contains('sha256 check failed'));
      expect(e.toString(), contains('hash mismatch'));
      // No (expected: ..., actual: ...) part
      expect(e.toString(), isNot(contains('expected:')));
    });

    test('BundleIntegrityException.toString with expected/actual', () {
      final e = BundleIntegrityException(
        'hash mismatch',
        checkType: 'sha256',
        expected: 'abc123',
        actual: 'def456',
      );
      expect(e.toString(), contains('sha256 check failed'));
      expect(e.toString(), contains('expected: abc123'));
      expect(e.toString(), contains('actual: def456'));
      expect(e.toString(), contains('hash mismatch'));
    });

    test('BundleIntegrityException with only expected set', () {
      final e = BundleIntegrityException(
        'check error',
        checkType: 'crc',
        expected: 'abc',
      );
      // Only both present triggers detail output
      expect(e.toString(), isNot(contains('expected:')));
    });

    test('BundleIntegrityException with only actual set', () {
      final e = BundleIntegrityException(
        'check error',
        checkType: 'crc',
        actual: 'xyz',
      );
      expect(e.toString(), isNot(contains('actual:')));
    });
  });

  // ==========================================================================
  // 4. mcp_bundle_loader.dart
  // ==========================================================================

  group('McpBundleLoader', () {
    group('fromJson', () {
      test('minimal valid bundle', () {
        final bundle = McpBundleLoader.fromJson(_mcpBundleJson());
        expect(bundle.manifest.id, equals('test-bundle'));
        expect(bundle.manifest.name, equals('Test Bundle'));
      });

      test('missing schemaVersion in strict mode throws', () {
        final json = {
          'manifest': {
            'id': 'test',
            'name': 'Test',
            'version': '1.0.0',
          },
        };
        expect(
          () => McpBundleLoader.fromJson(
            json,
            options: const McpLoaderOptions.strict(),
          ),
          throwsA(isA<BundleValidationException>()),
        );
      });

      test('invalid schemaVersion format causes error', () {
        final json = _mcpBundleJson(schemaVersion: 'bad-version');
        expect(
          () => McpBundleLoader.fromJson(json),
          throwsA(isA<BundleValidationException>()),
        );
      });

      test('null manifest in strict mode throws BundleValidationException', () {
        final json = <String, dynamic>{
          'schemaVersion': '1.0.0',
        };
        expect(
          () => McpBundleLoader.fromJson(json),
          throwsA(isA<BundleValidationException>()),
        );
      });

      test('non-object manifest in strict mode throws', () {
        final json = <String, dynamic>{
          'schemaVersion': '1.0.0',
          'manifest': 'not an object',
        };
        expect(
          () => McpBundleLoader.fromJson(json),
          throwsA(isA<BundleValidationException>()),
        );
      });

      test('null manifest in lenient mode returns default manifest', () {
        final json = <String, dynamic>{
          'schemaVersion': '1.0.0',
        };
        final bundle = McpBundleLoader.fromJson(
          json,
          options: const McpLoaderOptions.lenient(),
        );
        expect(bundle.manifest.name, equals('Unknown Bundle'));
        expect(bundle.manifest.id, equals('unknown'));
      });

      test('non-object manifest in lenient mode returns default', () {
        final json = <String, dynamic>{
          'schemaVersion': '1.0.0',
          'manifest': 42,
        };
        final bundle = McpBundleLoader.fromJson(
          json,
          options: const McpLoaderOptions.lenient(),
        );
        expect(bundle.manifest.name, equals('Unknown Bundle'));
      });

      test('lenient mode allows partial loads with errors in extensions', () {
        final json = <String, dynamic>{
          'manifest': {
            'id': '',
            'name': '',
            'version': '',
          },
        };
        final bundle = McpBundleLoader.fromJson(
          json,
          options: const McpLoaderOptions.lenient(),
        );
        expect(bundle, isNotNull);
        // Warnings should be recorded
        expect(bundle.extensions['_loadWarnings'], isNotNull);
      });

      test('unsupported major schema version causes error in strict mode', () {
        final json = _mcpBundleJson(schemaVersion: '2.0.0');
        expect(
          () => McpBundleLoader.fromJson(json),
          throwsA(isA<BundleValidationException>()),
        );
      });

      test('compatible minor version adds warning in lenient mode', () {
        final json = _mcpBundleJson(schemaVersion: '1.1.0');
        final bundle = McpBundleLoader.fromJson(
          json,
          options: const McpLoaderOptions.lenient(),
        );
        final warnings = bundle.extensions['_loadWarnings'] as List<dynamic>?;
        expect(warnings, isNotNull);
        expect(
          warnings!.any((w) => (w as String).contains('not explicitly supported')),
          isTrue,
        );
      });

      test('uses default options (strict) when none provided', () {
        final json = _mcpBundleJson();
        // Should not throw - valid bundle with strict defaults
        final bundle = McpBundleLoader.fromJson(json);
        expect(bundle, isNotNull);
      });
    });

    group('fromJsonString', () {
      test('valid JSON string parses successfully', () {
        final jsonStr = jsonEncode(_mcpBundleJson());
        final bundle = McpBundleLoader.fromJsonString(jsonStr);
        expect(bundle.manifest.id, equals('test-bundle'));
      });

      test('invalid JSON throws BundleParseException', () {
        expect(
          () => McpBundleLoader.fromJsonString('{invalid json'),
          throwsA(isA<BundleParseException>()),
        );
      });

      test('BundleParseException message contains Invalid JSON', () {
        try {
          McpBundleLoader.fromJsonString('not json');
          fail('Should have thrown');
        } catch (e) {
          expect(e, isA<BundleParseException>());
          expect((e as BundleParseException).message, contains('Invalid JSON'));
        }
      });
    });
  });

  group('McpLoaderOptions', () {
    test('strict() has all strict settings', () {
      const opts = McpLoaderOptions.strict();
      expect(opts.requireSchemaVersion, isTrue);
      expect(opts.validateReferences, isTrue);
      expect(opts.allowPartialLoad, isFalse);
      expect(opts.maxNestingDepth, equals(50));
    });

    test('lenient() has all lenient settings', () {
      const opts = McpLoaderOptions.lenient();
      expect(opts.requireSchemaVersion, isFalse);
      expect(opts.validateReferences, isFalse);
      expect(opts.allowPartialLoad, isTrue);
      expect(opts.maxNestingDepth, equals(50));
    });

    test('lenient uses lenient coercion rules', () {
      const opts = McpLoaderOptions.lenient();
      expect(opts.coercion.stringToBool, isTrue);
      expect(opts.coercion.stringToNumber, isTrue);
      expect(opts.coercion.numberToBool, isTrue);
      expect(opts.coercion.singleToList, isTrue);
    });

    test('strict uses default (no coercion) rules', () {
      const opts = McpLoaderOptions.strict();
      expect(opts.coercion.stringToBool, isFalse);
      expect(opts.coercion.stringToNumber, isFalse);
    });

    test('custom options', () {
      const opts = McpLoaderOptions(
        requireSchemaVersion: false,
        validateReferences: false,
        allowPartialLoad: true,
        maxNestingDepth: 100,
      );
      expect(opts.requireSchemaVersion, isFalse);
      expect(opts.maxNestingDepth, equals(100));
    });
  });

  // ==========================================================================
  // 5. http_storage_adapter.dart
  // ==========================================================================

  group('HttpAuthConfig constructors', () {
    test('bearer() sets type and token', () {
      const auth = HttpAuthConfig.bearer('my-token');
      expect(auth.type, equals(HttpAuthType.bearer));
      expect(auth.token, equals('my-token'));
      expect(auth.username, isNull);
      expect(auth.password, isNull);
      expect(auth.headerName, isNull);
    });

    test('basic() sets type, username, and password', () {
      const auth = HttpAuthConfig.basic(
        username: 'user',
        password: 'pass123',
      );
      expect(auth.type, equals(HttpAuthType.basic));
      expect(auth.username, equals('user'));
      expect(auth.password, equals('pass123'));
      expect(auth.token, isNull);
      expect(auth.headerName, isNull);
    });

    test('apiKey() sets type, token, and default header name', () {
      const auth = HttpAuthConfig.apiKey('key-abc');
      expect(auth.type, equals(HttpAuthType.apiKey));
      expect(auth.token, equals('key-abc'));
      expect(auth.headerName, equals('X-API-Key'));
      expect(auth.username, isNull);
      expect(auth.password, isNull);
    });

    test('apiKey() with custom header name', () {
      const auth = HttpAuthConfig.apiKey(
        'key-xyz',
        headerName: 'X-Custom-Auth',
      );
      expect(auth.headerName, equals('X-Custom-Auth'));
    });
  });

  group('HttpStorageAdapter', () {
    test('registry factory sets baseUrl and api key header', () {
      final adapter = HttpStorageAdapter.registry(
        'https://registry.example.com',
        apiKey: 'secret',
      );
      expect(adapter.baseUrl, equals('https://registry.example.com'));
      expect(adapter.headers['X-API-Key'], equals('secret'));
    });

    test('registry factory without api key', () {
      final adapter = HttpStorageAdapter.registry(
        'https://registry.example.com',
      );
      expect(adapter.baseUrl, equals('https://registry.example.com'));
      expect(adapter.headers.containsKey('X-API-Key'), isFalse);
    });

    test('registry factory with custom headers', () {
      final adapter = HttpStorageAdapter.registry(
        'https://registry.example.com',
        headers: {'Accept': 'application/json'},
      );
      expect(adapter.headers['Accept'], equals('application/json'));
    });

    test('watch() returns null for HTTP adapter', () {
      final adapter = HttpStorageAdapter(
        baseUrl: 'https://example.com',
      );
      expect(adapter.watch(Uri.parse('manifest.json')), isNull);
    });

    test('close() does not throw', () {
      final adapter = HttpStorageAdapter(
        baseUrl: 'https://example.com',
      );
      // Should complete without error
      adapter.close();
    });
  });

  // ==========================================================================
  // 6. type_coercion.dart
  // ==========================================================================

  group('TypeCoercionRules - additional coverage', () {
    test('strict() all fields are false', () {
      const rules = TypeCoercionRules.strict();
      expect(rules.stringToNumber, isFalse);
      expect(rules.stringToBool, isFalse);
      expect(rules.numberToBool, isFalse);
      expect(rules.singleToList, isFalse);
    });

    test('lenient() all fields are true', () {
      const rules = TypeCoercionRules.lenient();
      expect(rules.stringToNumber, isTrue);
      expect(rules.stringToBool, isTrue);
      expect(rules.numberToBool, isTrue);
      expect(rules.singleToList, isTrue);
    });
  });

  group('TypeCoercer - additional edge cases', () {
    test('coerce returns value as-is when type matches', () {
      final coercer = TypeCoercer(const TypeCoercionRules.strict());
      expect(coercer.coerce<String>('hello'), equals('hello'));
      expect(coercer.coerce<int>(42), equals(42));
      expect(coercer.coerce<double>(3.14), equals(3.14));
      expect(coercer.coerce<bool>(true), isTrue);
    });

    test('coerce returns null for incompatible type without coercion', () {
      final coercer = TypeCoercer(const TypeCoercionRules.strict());
      expect(coercer.coerce<int>('hello'), isNull);
      expect(coercer.coerce<bool>('true'), isNull);
    });

    test('coerce string "true"/"false" case-insensitive', () {
      final coercer = TypeCoercer(const TypeCoercionRules.lenient());
      expect(coercer.coerce<bool>('TRUE'), isTrue);
      expect(coercer.coerce<bool>('False'), isFalse);
      expect(coercer.coerce<bool>('TrUe'), isTrue);
    });

    test('coerce string to bool returns null for non-bool strings', () {
      final coercer = TypeCoercer(const TypeCoercionRules.lenient());
      expect(coercer.coerce<bool>('yes'), isNull);
      expect(coercer.coerce<bool>('1'), isNull);
    });

    test('coerce number to bool only for 0 and 1', () {
      final coercer = TypeCoercer(const TypeCoercionRules.lenient());
      expect(coercer.coerce<bool>(1), isTrue);
      expect(coercer.coerce<bool>(0), isFalse);
      expect(coercer.coerce<bool>(2), isNull);
      expect(coercer.coerce<bool>(-1), isNull);
    });

    test('coerce string to int', () {
      final coercer = TypeCoercer(const TypeCoercionRules.lenient());
      expect(coercer.coerce<int>('100'), equals(100));
      expect(coercer.coerce<int>('3.5'), equals(3)); // truncates
    });

    test('coerce string to double', () {
      final coercer = TypeCoercer(const TypeCoercionRules.lenient());
      expect(coercer.coerce<double>('3.14'), equals(3.14));
      expect(coercer.coerce<double>('42'), equals(42.0));
    });

    test('coerce string to num', () {
      final coercer = TypeCoercer(const TypeCoercionRules.lenient());
      expect(coercer.coerce<num>('99'), equals(99));
      expect(coercer.coerce<num>('1.5'), equals(1.5));
    });

    test('coerce unparseable string to num returns null', () {
      final coercer = TypeCoercer(const TypeCoercionRules.lenient());
      expect(coercer.coerce<int>('abc'), isNull);
      expect(coercer.coerce<double>('xyz'), isNull);
      expect(coercer.coerce<num>('not-a-number'), isNull);
    });

    test('coerce single value to List when enabled', () {
      final coercer = TypeCoercer(const TypeCoercionRules.lenient());
      final result = coercer.coerce<List<dynamic>>('single-item');
      expect(result, isA<List<dynamic>>());
      expect(result, equals(['single-item']));
    });

    test('coerce list to List returns as-is', () {
      final coercer = TypeCoercer(const TypeCoercionRules.lenient());
      final list = [1, 2, 3];
      final result = coercer.coerce<List<dynamic>>(list);
      expect(result, same(list));
    });

    test('parseRequired with coercible value', () {
      final coercer = TypeCoercer(const TypeCoercionRules.lenient());
      final errors = <BundleLoadException>[];
      final result = coercer.parseRequired<int>(
        {'count': '42'},
        'count',
        errors,
      );
      expect(result, equals(42));
      expect(errors, isEmpty);
    });

    test('parseRequired with null value and default', () {
      final coercer = TypeCoercer(const TypeCoercionRules());
      final errors = <BundleLoadException>[];
      final result = coercer.parseRequired<String>(
        {'field': null},
        'field',
        errors,
        defaultValue: 'fallback',
      );
      expect(result, equals('fallback'));
      expect(errors, hasLength(1));
    });

    test('parseRequired with uncoercible value adds error', () {
      final coercer = TypeCoercer(const TypeCoercionRules.strict());
      final errors = <BundleLoadException>[];
      // int cannot be coerced to String in strict mode
      expect(
        () => coercer.parseRequired<String>(
          {'field': 42},
          'field',
          errors,
        ),
        throwsA(isA<BundleMissingFieldException>()),
      );
    });

    test('parseOptional returns default when value not coercible', () {
      final coercer = TypeCoercer(const TypeCoercionRules.strict());
      final result = coercer.parseOptional<int>(
        {'field': 'not-a-number'},
        'field',
        defaultValue: 0,
      );
      expect(result, equals(0));
    });

    test('parseList with single value and singleToList enabled', () {
      final coercer = TypeCoercer(const TypeCoercionRules.lenient());
      final result = coercer.parseList<String>(
        {'items': 'solo'},
        'items',
      );
      expect(result, equals(['solo']));
    });

    test('parseList with null returns empty list', () {
      final coercer = TypeCoercer(const TypeCoercionRules());
      final result = coercer.parseList<String>(
        {},
        'items',
      );
      expect(result, isEmpty);
    });

    test('parseList with null returns default list when provided', () {
      final coercer = TypeCoercer(const TypeCoercionRules());
      final result = coercer.parseList<String>(
        {},
        'items',
        defaultValue: ['default'],
      );
      expect(result, equals(['default']));
    });

    test('parseList returns default when value is not list and coercion disabled', () {
      final coercer = TypeCoercer(const TypeCoercionRules.strict());
      final result = coercer.parseList<String>(
        {'items': 42},
        'items',
        defaultValue: ['fallback'],
      );
      expect(result, equals(['fallback']));
    });

    test('parseList with itemParser on coerced single value', () {
      final coercer = TypeCoercer(const TypeCoercionRules.lenient());
      final result = coercer.parseList<int>(
        {'nums': '5'},
        'nums',
        itemParser: (item) => int.parse(item.toString()),
      );
      expect(result, equals([5]));
    });
  });

  group('ErrorRecoveryHandler - additional coverage', () {
    test('handleMissingField repair without default returns null', () {
      final handler = ErrorRecoveryHandler(
        coercionRules: const TypeCoercionRules.lenient(),
        allowPartialLoad: true,
      );
      final errors = <BundleLoadException>[];
      final warnings = <String>[];

      final result = handler.handleMissingField<String>(
        'field',
        errors,
        warnings,
        strategy: RecoveryStrategy.repair,
      );
      expect(result, isNull);
      expect(warnings, hasLength(1));
    });

    test('handleInvalidValue repair coercion succeeds', () {
      final handler = ErrorRecoveryHandler(
        coercionRules: const TypeCoercionRules.lenient(),
        allowPartialLoad: true,
      );
      final errors = <BundleLoadException>[];
      final warnings = <String>[];

      final result = handler.handleInvalidValue<bool>(
        'field',
        'true',
        'bool',
        errors,
        warnings,
        strategy: RecoveryStrategy.repair,
      );
      expect(result, isTrue);
      expect(warnings, hasLength(1));
      expect(warnings.first, contains('coerced'));
    });

    test('handleInvalidValue useDefault without default adds warning', () {
      final handler = ErrorRecoveryHandler(
        coercionRules: const TypeCoercionRules(),
        allowPartialLoad: true,
      );
      final errors = <BundleLoadException>[];
      final warnings = <String>[];

      final result = handler.handleInvalidValue<int>(
        'age',
        'not-int',
        'int',
        errors,
        warnings,
        defaultValue: 0,
        strategy: RecoveryStrategy.useDefault,
      );
      expect(result, equals(0));
      expect(warnings, hasLength(1));
    });
  });

  group('RecoveryStrategy enum', () {
    test('has all four values', () {
      expect(RecoveryStrategy.values, hasLength(4));
      expect(RecoveryStrategy.values, contains(RecoveryStrategy.skip));
      expect(RecoveryStrategy.values, contains(RecoveryStrategy.useDefault));
      expect(RecoveryStrategy.values, contains(RecoveryStrategy.repair));
      expect(RecoveryStrategy.values, contains(RecoveryStrategy.fail));
    });
  });

  // ==========================================================================
  // 7. bundle_repository.dart
  // ==========================================================================

  group('BundleRepository - loadAll coverage', () {
    late MemoryStorageAdapter storage;
    late BundleRepository repo;

    setUp(() {
      storage = MemoryStorageAdapter();
      repo = BundleRepository(storage);
    });

    tearDown(() {
      storage.dispose();
    });

    test('loadAll silently skips invalid bundles', () async {
      // Seed one valid and one invalid bundle
      storage.seed('bundle://dir/valid.json', _mcpBundleJson(id: 'valid'));
      // Invalid: manifest is missing required fields in strict mode
      storage.seed('bundle://dir/invalid.json', {
        'garbage': true,
      });

      final results = await repo.loadAll(Uri.parse('bundle://dir/'));
      // Only the valid one should be returned
      expect(results, hasLength(1));
      expect(results.values.first.manifest.id, equals('valid'));
    });

    test('loadAll returns empty map when all bundles are invalid', () async {
      storage.seed('bundle://bad/a.json', {'not': 'a bundle'});
      storage.seed('bundle://bad/b.json', {'also': 'invalid'});

      final results = await repo.loadAll(Uri.parse('bundle://bad/'));
      expect(results, isEmpty);
    });

    test('loadAll with lenient options parses more bundles', () async {
      // This bundle is valid in lenient mode but not in strict
      storage.seed('bundle://lenient/partial.json', {
        'manifest': {
          'id': 'partial',
          'name': 'Partial',
          'version': '1.0.0',
        },
      });

      final results = await repo.loadAll(
        Uri.parse('bundle://lenient/'),
        options: const McpLoaderOptions.lenient(),
      );
      expect(results, hasLength(1));
    });

    test('loadAll passes options to individual loads', () async {
      storage.seed('bundle://opts/test.json', _mcpBundleJson(id: 'opts'));

      final results = await repo.loadAll(
        Uri.parse('bundle://opts/'),
        options: const McpLoaderOptions.strict(),
      );
      expect(results, hasLength(1));
    });

    test('loadAll returns empty map for empty directory', () async {
      final results = await repo.loadAll(Uri.parse('bundle://empty/'));
      expect(results, isEmpty);
    });
  });

  group('BundleRepository - watch and file factory', () {
    test('memory factory creates working repository', () async {
      final repo = BundleRepository.memory();
      // Should be able to perform basic operations
      final uri = Uri.parse('test://manifest.json');
      await repo.save(
        const McpBundle(
          manifest: BundleManifest(
            id: 'mem-test',
            name: 'Memory Test',
            version: '1.0.0',
          ),
        ),
        uri,
      );
      expect(await repo.exists(uri), isTrue);
    });

    test('watch delegates to storage', () {
      final storage = MemoryStorageAdapter();
      final repo = BundleRepository(storage);
      final stream = repo.watch(Uri.parse('test://any'));
      expect(stream, isNotNull);
      storage.dispose();
    });
  });

  // ==========================================================================
  // SourceType enum coverage
  // ==========================================================================

  group('SourceType enum', () {
    test('has all expected values', () {
      expect(SourceType.values, contains(SourceType.file));
      expect(SourceType.values, contains(SourceType.url));
      expect(SourceType.values, contains(SourceType.json));
      expect(SourceType.values, contains(SourceType.string));
      expect(SourceType.values, contains(SourceType.stream));
    });
  });

  // ==========================================================================
  // BundleChangeEvent and BundleChangeType coverage
  // ==========================================================================

  group('BundleChangeEvent', () {
    test('toString contains all fields', () {
      final event = BundleChangeEvent(
        uri: Uri.parse('file:///test.json'),
        type: BundleChangeType.created,
        timestamp: DateTime.utc(2025, 6, 15, 10, 30),
      );
      final str = event.toString();
      expect(str, contains('created'));
      expect(str, contains('file:///test.json'));
    });
  });

  group('BundleChangeType enum', () {
    test('has all expected values', () {
      expect(BundleChangeType.values, hasLength(3));
      expect(BundleChangeType.values, contains(BundleChangeType.created));
      expect(BundleChangeType.values, contains(BundleChangeType.modified));
      expect(BundleChangeType.values, contains(BundleChangeType.deleted));
    });
  });
}
