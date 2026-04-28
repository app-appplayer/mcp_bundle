/// Coverage gap tests for bundle_loader.dart and mcp_bundle_loader.dart.
///
/// Targets uncovered lines:
/// - bundle_loader.dart: resolveRefs path, url/stream source failures,
///   BundleBuilder, BundleExtensions
/// - mcp_bundle_loader.dart: lenient mode section parse errors,
///   asset reference validation, recursive widget action validation,
///   reference registry methods
import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:mcp_bundle/src/io/bundle_loader.dart';
import 'package:mcp_bundle/src/schema/bundle_schema.dart' as schema;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal valid bundle JSON for BundleLoader (schema/bundle_schema.dart).
Map<String, dynamic> _schemaBundleJson({
  String name = 'test-bundle',
  String version = '1.0.0',
  List<Map<String, dynamic>>? resources,
  List<Map<String, dynamic>>? dependencies,
  Map<String, dynamic>? metadata,
}) {
  return {
    'manifest': {
      'name': name,
      'version': version,
    },
    if (resources != null) 'resources': resources,
    if (dependencies != null) 'dependencies': dependencies,
    if (metadata != null) 'metadata': metadata,
  };
}

/// Minimal valid McpBundleLoader JSON (models/).
Map<String, dynamic> _mcpBundleJson({
  String id = 'test-bundle',
  String name = 'Test Bundle',
  String version = '1.0.0',
  String schemaVersion = '1.0.0',
  Map<String, dynamic>? assets,
  Map<String, dynamic>? skills,
  Map<String, dynamic>? ui,
}) {
  return {
    'schemaVersion': schemaVersion,
    'manifest': {
      'id': id,
      'name': name,
      'version': version,
    },
    if (assets != null) 'assets': assets,
    if (skills != null) 'skills': skills,
    if (ui != null) 'ui': ui,
  };
}

void main() {
  // ==========================================================================
  // Part 1: BundleLoader coverage gaps
  // ==========================================================================

  group('BundleLoader - resolveRefs path', () {
    test('resolves references when resolveRefs is true and no resources', () async {
      // Covers line 34-36: resolveRefs ternary, true branch
      final loader = BundleLoader(
        options: const LoaderOptions(
          validate: false,
          resolveRefs: true,
          cache: false,
        ),
      );
      final result = await loader.load(BundleSource.json(
        _schemaBundleJson(),
      ));
      expect(result.success, isTrue);
      expect(result.value, isNotNull);
      expect(result.value!.manifest.name, equals('test-bundle'));
    });

    test('resolves references with resources that have no external content', () async {
      // Covers _resolveReferences with resources that have inline content only
      // (line 168-170: else branch - resource is kept as-is)
      final loader = BundleLoader(
        options: const LoaderOptions(
          validate: false,
          resolveRefs: true,
          cache: false,
        ),
      );
      final result = await loader.load(BundleSource.json(
        _schemaBundleJson(
          resources: [
            {
              'path': 'skills/main.json',
              'type': 'skill',
              'content': 'inline content here',
            },
          ],
        ),
      ));
      expect(result.success, isTrue);
      expect(result.value!.resources, hasLength(1));
      expect(result.value!.resources.first.content, equals('inline content here'));
    });

    test('resolves references with external contentRef and default resolver', () async {
      // Covers _resolveReferences with external content reference
      // (lines 151-167: the try/catch that falls back to original resource)
      // The default FileContentResolver throws UnimplementedError,
      // so the catch block at line 164-167 is exercised
      final loader = BundleLoader(
        options: const LoaderOptions(
          validate: false,
          resolveRefs: true,
          cache: false,
        ),
      );
      final result = await loader.load(BundleSource.json(
        _schemaBundleJson(
          resources: [
            {
              'path': 'skills/main.json',
              'type': 'skill',
              'contentRef': 'external-ref.json',
            },
          ],
        ),
      ));
      // Resolution fails, but resource is kept as-is
      expect(result.success, isTrue);
      expect(result.value!.resources, hasLength(1));
      expect(result.value!.resources.first.contentRef, equals('external-ref.json'));
    });

    test('resolves references with basePath option', () async {
      // Covers line 146: basePath from options (not from source)
      final loader = BundleLoader(
        options: const LoaderOptions(
          validate: false,
          resolveRefs: true,
          cache: false,
          basePath: '/custom/base/path',
        ),
      );
      final result = await loader.load(BundleSource.json(
        _schemaBundleJson(
          resources: [
            {
              'path': 'data/ref.json',
              'type': 'data',
              'contentRef': 'some-ref.json',
            },
          ],
        ),
      ));
      expect(result.success, isTrue);
    });

    test('resolves references with custom content resolver', () async {
      // Covers line 145: custom contentResolver branch
      final loader = BundleLoader(
        options: LoaderOptions(
          validate: false,
          resolveRefs: true,
          cache: false,
          contentResolver: _TestContentResolver(),
        ),
      );
      final result = await loader.load(BundleSource.json(
        _schemaBundleJson(
          resources: [
            {
              'path': 'data/ref.json',
              'type': 'data',
              'contentRef': 'resolvable-ref',
            },
          ],
        ),
      ));
      expect(result.success, isTrue);
      expect(result.value!.resources.first.content, equals('resolved-content'));
    });

    test('caches resolved bundle when cache is enabled', () async {
      // Covers line 39-41: cache branch with resolvedBundle
      final loader = BundleLoader(
        options: const LoaderOptions(
          validate: false,
          resolveRefs: true,
          cache: true,
        ),
      );
      final result = await loader.load(BundleSource.json(
        _schemaBundleJson(name: 'cached-bundle'),
      ));
      expect(result.success, isTrue);
      expect(loader.isCached('cached-bundle'), isTrue);
      expect(loader.getCached('cached-bundle'), isNotNull);
    });

    test('resolves references with both inline and external content', () async {
      // Resource that has both inline content AND contentRef
      // Covers line 151 condition: hasExternalContent && !hasInlineContent
      // When both are present, the resource is kept as-is (else branch)
      final loader = BundleLoader(
        options: const LoaderOptions(
          validate: false,
          resolveRefs: true,
          cache: false,
        ),
      );
      final result = await loader.load(BundleSource.json(
        _schemaBundleJson(
          resources: [
            {
              'path': 'data/both.json',
              'type': 'data',
              'content': 'inline',
              'contentRef': 'also-external.json',
            },
          ],
        ),
      ));
      expect(result.success, isTrue);
      // Resource kept as-is because it has inline content
      expect(result.value!.resources.first.content, equals('inline'));
    });
  });

  group('BundleLoader - _getBasePath', () {
    test('extracts base path from json source (returns null)', () async {
      // Covers _getBasePath default case returning null (line 189-190)
      final loader = BundleLoader(
        options: const LoaderOptions(
          validate: false,
          resolveRefs: true,
          cache: false,
        ),
      );
      final result = await loader.load(BundleSource.json(
        _schemaBundleJson(
          resources: [
            {
              'path': 'skills/ext.json',
              'type': 'skill',
              'contentRef': 'ext-ref.json',
            },
          ],
        ),
      ));
      // basePath is null (json source), resolver uses null basePath
      expect(result.success, isTrue);
    });

    test('extracts base path from string source (returns null)', () async {
      // Covers _getBasePath default case via string source type
      final loader = BundleLoader(
        options: const LoaderOptions(
          validate: false,
          resolveRefs: true,
          cache: false,
        ),
      );
      final result = await loader.load(BundleSource.string(
        '{"manifest":{"name":"test","version":"1.0.0"},"resources":[{"path":"x.json","type":"data","contentRef":"ext.json"}]}',
      ));
      expect(result.success, isTrue);
    });
  });

  group('BundleLoader - url source failure', () {
    test('returns failure for url source (unimplemented)', () async {
      // Covers lines 84-86: SourceType.url throws UnimplementedError
      final loader = BundleLoader(
        options: const LoaderOptions(validate: false, resolveRefs: false),
      );
      final result = await loader.load(BundleSource.url('https://example.com/manifest.json'));
      expect(result.success, isFalse);
      expect(result.error, contains('Failed to load bundle'));
    });
  });

  group('BundleLoader - stream source failure', () {
    test('returns failure for stream source (unimplemented)', () async {
      // Covers lines 88-90: SourceType.stream throws UnimplementedError
      // BundleSource has no stream factory, so we use the general constructor
      final source = BundleSource(
        type: SourceType.stream,
        source: const Stream<List<int>>.empty(),
      );
      final loader = BundleLoader(
        options: const LoaderOptions(validate: false, resolveRefs: false),
      );
      final result = await loader.load(source);
      expect(result.success, isFalse);
      expect(result.error, contains('Failed to load bundle'));
    });
  });

  group('BundleBuilder - comprehensive field coverage', () {
    test('builds bundle with description, author, and license', () {
      // Covers BundleBuilder description(), author(), license() setters
      // (lines 219-233)
      final builder = BundleBuilder()
        ..name('my-bundle')
        ..version('2.0.0')
        ..description('A test bundle description')
        ..author('Test Author')
        ..license('MIT');

      final bundle = builder.build();
      expect(bundle.manifest.name, equals('my-bundle'));
      expect(bundle.manifest.version, equals('2.0.0'));
      expect(bundle.manifest.description, equals('A test bundle description'));
      expect(bundle.manifest.author, equals('Test Author'));
      expect(bundle.manifest.license, equals('MIT'));
    });

    test('builds bundle with resources and dependencies', () {
      // Covers addResource() and addDependency() (lines 237-246)
      final bundle = (BundleBuilder()
            ..name('full-bundle')
            ..version('1.0.0')
            ..addResource(const schema.BundleResource(
              path: 'skills/main.json',
              type: schema.ResourceType.skill,
            ))
            ..addResource(const schema.BundleResource(
              path: 'profiles/default.json',
              type: schema.ResourceType.profile,
            ))
            ..addDependency(const schema.BundleDependency(
              name: 'base-bundle',
              version: '>=1.0.0',
            )))
          .build();

      expect(bundle.resources, hasLength(2));
      expect(bundle.dependencies, hasLength(1));
      expect(bundle.dependencies.first.name, equals('base-bundle'));
    });

    test('builds bundle with metadata', () {
      // Covers addMetadata() (lines 249-252)
      final bundle = (BundleBuilder()
            ..name('meta-bundle')
            ..version('1.0.0')
            ..addMetadata('author', 'test')
            ..addMetadata('tags', ['a', 'b']))
          .build();

      expect(bundle.metadata['author'], equals('test'));
      expect(bundle.metadata['tags'], equals(['a', 'b']));
    });

    test('builder chain returns self for fluent API', () {
      // Ensures all setters return BundleBuilder for chaining
      final builder = BundleBuilder();
      expect(builder.name('x'), same(builder));
      expect(builder.version('1.0.0'), same(builder));
      expect(builder.description('desc'), same(builder));
      expect(builder.author('auth'), same(builder));
      expect(builder.license('lic'), same(builder));
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
  });

  group('BundleExtensions - resource access by type', () {
    test('skills returns only skill resources', () {
      // Covers line 289: skills getter
      final bundle = schema.Bundle(
        manifest: const schema.BundleManifest(name: 'ext-test', version: '1.0.0'),
        resources: const [
          schema.BundleResource(path: 'a.json', type: schema.ResourceType.skill),
          schema.BundleResource(path: 'b.json', type: schema.ResourceType.profile),
          schema.BundleResource(path: 'c.json', type: schema.ResourceType.skill),
        ],
      );

      expect(bundle.skills, hasLength(2));
      expect(bundle.skills.every((r) => r.type == schema.ResourceType.skill), isTrue);
    });

    test('profiles returns only profile resources', () {
      // Covers line 292: profiles getter
      final bundle = schema.Bundle(
        manifest: const schema.BundleManifest(name: 'ext-test', version: '1.0.0'),
        resources: const [
          schema.BundleResource(path: 'a.json', type: schema.ResourceType.profile),
          schema.BundleResource(path: 'b.json', type: schema.ResourceType.skill),
        ],
      );

      expect(bundle.profiles, hasLength(1));
      expect(bundle.profiles.first.path, equals('a.json'));
    });

    test('factGraphs returns only factGraph resources', () {
      // Covers lines 295-296: factGraphs getter
      final bundle = schema.Bundle(
        manifest: const schema.BundleManifest(name: 'ext-test', version: '1.0.0'),
        resources: const [
          schema.BundleResource(path: 'fg.json', type: schema.ResourceType.factGraph),
          schema.BundleResource(path: 's.json', type: schema.ResourceType.skill),
        ],
      );

      expect(bundle.factGraphs, hasLength(1));
      expect(bundle.factGraphs.first.path, equals('fg.json'));
    });

    test('factGraphs returns empty when none present', () {
      final bundle = schema.Bundle(
        manifest: const schema.BundleManifest(name: 'empty', version: '1.0.0'),
        resources: const [
          schema.BundleResource(path: 'x.json', type: schema.ResourceType.data),
        ],
      );
      expect(bundle.factGraphs, isEmpty);
    });

    test('getResource returns null for non-existing path', () {
      // Covers line 274-276: getResource null return
      final bundle = schema.Bundle(
        manifest: const schema.BundleManifest(name: 'test', version: '1.0.0'),
        resources: const [
          schema.BundleResource(path: 'a.json', type: schema.ResourceType.skill),
        ],
      );
      expect(bundle.getResource('nonexistent'), isNull);
      expect(bundle.getResource('a.json'), isNotNull);
    });

    test('hasCapability returns correct values', () {
      // Covers lines 284-286: hasCapability
      final bundle = schema.Bundle(
        manifest: const schema.BundleManifest(
          name: 'caps',
          version: '1.0.0',
          capabilities: ['llm', 'rag'],
        ),
      );
      expect(bundle.hasCapability('llm'), isTrue);
      expect(bundle.hasCapability('rag'), isTrue);
      expect(bundle.hasCapability('missing'), isFalse);
    });

    test('getResourcesByType returns filtered list', () {
      // Covers lines 279-281: getResourcesByType
      final bundle = schema.Bundle(
        manifest: const schema.BundleManifest(name: 'typed', version: '1.0.0'),
        resources: const [
          schema.BundleResource(path: 'a', type: schema.ResourceType.skill),
          schema.BundleResource(path: 'b', type: schema.ResourceType.data),
          schema.BundleResource(path: 'c', type: schema.ResourceType.skill),
        ],
      );
      expect(bundle.getResourcesByType(schema.ResourceType.skill), hasLength(2));
      expect(bundle.getResourcesByType(schema.ResourceType.config), isEmpty);
    });
  });

  // ==========================================================================
  // Part 2: McpBundleLoader coverage gaps
  // ==========================================================================

  group('McpBundleLoader - lenient mode section parse errors', () {
    test('handles invalid assets section gracefully in lenient mode', () {
      // Covers lines 328-331: catch block in assets parsing
      // Passing 'not-a-map' forces a type cast error
      final bundle = McpBundleLoader.fromJson(
        _mcpBundleJson(
          assets: {'invalid_key': 'this will cause cast error'} ,
        ),
        options: const McpLoaderOptions.lenient(),
      );
      // Even with a weird assets section, lenient mode should not throw
      expect(bundle, isNotNull);
    });

    test('handles non-map assets section in lenient mode', () {
      // Directly inject a non-map to trigger the cast exception at line 322
      final json = <String, dynamic>{
        'schemaVersion': '1.0.0',
        'manifest': {'id': 'test', 'name': 'Test', 'version': '1.0.0'},
        'assets': 'not-a-map',
      };
      final bundle = McpBundleLoader.fromJson(
        json,
        options: const McpLoaderOptions.lenient(),
      );
      // Assets section should be null due to parse failure
      expect(bundle.assets, isNull);
      // Warnings should contain the parse error message
      final warnings = bundle.extensions['_loadWarnings'] as List<dynamic>?;
      expect(warnings, isNotNull);
      expect(
        warnings!.any((w) => w.toString().contains('Assets section skipped')),
        isTrue,
      );
    });

    test('handles non-map skills section in lenient mode', () {
      // Covers lines 346-349: catch block in skills parsing
      final json = <String, dynamic>{
        'schemaVersion': '1.0.0',
        'manifest': {'id': 'test', 'name': 'Test', 'version': '1.0.0'},
        'skills': 'not-a-map',
      };
      final bundle = McpBundleLoader.fromJson(
        json,
        options: const McpLoaderOptions.lenient(),
      );
      expect(bundle.skills, isNull);
      final warnings = bundle.extensions['_loadWarnings'] as List<dynamic>?;
      expect(warnings, isNotNull);
      expect(
        warnings!.any((w) => w.toString().contains('Skills section skipped')),
        isTrue,
      );
    });

    test('handles non-map ui section in lenient mode', () {
      // Covers lines 360-363: catch block in UI parsing
      final json = <String, dynamic>{
        'schemaVersion': '1.0.0',
        'manifest': {'id': 'test', 'name': 'Test', 'version': '1.0.0'},
        'ui': 'not-a-map',
      };
      final bundle = McpBundleLoader.fromJson(
        json,
        options: const McpLoaderOptions.lenient(),
      );
      expect(bundle.ui, isNull);
      final warnings = bundle.extensions['_loadWarnings'] as List<dynamic>?;
      expect(warnings, isNotNull);
      expect(
        warnings!.any((w) => w.toString().contains('UI section skipped')),
        isTrue,
      );
    });

    test('handles all three invalid sections simultaneously in lenient mode', () {
      final json = <String, dynamic>{
        'schemaVersion': '1.0.0',
        'manifest': {'id': 'test', 'name': 'Test', 'version': '1.0.0'},
        'assets': 42,
        'skills': true,
        'ui': <dynamic>[],
      };
      final bundle = McpBundleLoader.fromJson(
        json,
        options: const McpLoaderOptions.lenient(),
      );
      expect(bundle.assets, isNull);
      expect(bundle.skills, isNull);
      expect(bundle.ui, isNull);
    });
  });

  group('McpBundleLoader - reference registry and cross-references', () {
    test('registers and resolves assets, skills, and screens', () {
      // Covers _ReferenceRegistry methods: registerAsset, registerSkill,
      // registerProcedure, registerPage (lines 78-92)
      final bundle = McpBundleLoader.fromJson(_mcpBundleJson(
        assets: {
          'schemaVersion': '1.0.0',
          'assets': [
            {
              'id': 'asset-1',
              'path': 'data/file.txt',
              'type': 'text',
              'content': 'hello',
            },
            {
              'id': 'asset-2',
              'path': 'data/file2.txt',
              'type': 'text',
              'content': 'world',
            },
          ],
        },
        skills: {
          'schemaVersion': '1.0.0',
          'modules': [
            {
              'id': 'skill-1',
              'name': 'Skill One',
              'description': 'First skill',
              'procedures': [
                {'id': 'proc-1', 'name': 'Procedure', 'steps': <dynamic>[]},
              ],
            },
          ],
        },
        ui: {
          'screens': [
            {
              'id': 'home',
              'name': 'Home Screen',
              'root': {'type': 'Text'},
            },
          ],
        },
      ));

      expect(bundle.assets, isNotNull);
      expect(bundle.assets!.assets, hasLength(2));
      expect(bundle.skills, isNotNull);
      expect(bundle.skills!.modules, hasLength(1));
      expect(bundle.skills!.modules.first.procedures, hasLength(1));
      expect(bundle.ui, isNotNull);
      expect(bundle.ui!.pages, hasLength(1));
    });

    test('registers assets without id (id is null)', () {
      // Asset without an id should not be registered but should still parse
      final bundle = McpBundleLoader.fromJson(_mcpBundleJson(
        assets: {
          'schemaVersion': '1.0.0',
          'assets': [
            {
              'path': 'data/no-id.txt',
              'type': 'text',
              'content': 'no id here',
            },
          ],
        },
      ));
      expect(bundle.assets, isNotNull);
      expect(bundle.assets!.assets, hasLength(1));
      expect(bundle.assets!.assets.first.id, isNull);
    });
  });

  group('McpBundleLoader - asset reference validation', () {
    test('warns when skill references unknown asset', () {
      // Covers lines 402-405: knowledge source asset ref check
      final bundle = McpBundleLoader.fromJson(
        _mcpBundleJson(
          assets: {
            'schemaVersion': '1.0.0',
            'assets': [
              {
                'id': 'known-asset',
                'path': 'data/file.txt',
                'type': 'text',
                'content': 'hello',
              },
            ],
          },
          skills: {
            'schemaVersion': '1.0.0',
            'modules': [
              {
                'id': 'skill-1',
                'name': 'Skill 1',
                'description': 'A skill',
                'procedures': <dynamic>[],
                'knowledgeSources': [
                  {
                    'sourceId': 'asset:unknown-asset',
                    'mode': 'similarity',
                  },
                ],
              },
            ],
          },
        ),
        // Use strict validateReferences to trigger _validateReferences
        options: const McpLoaderOptions(
          requireSchemaVersion: true,
          validateReferences: true,
          allowPartialLoad: true,
        ),
      );

      // The warning about unknown asset should be in _loadWarnings
      final warnings = bundle.extensions['_loadWarnings'] as List<dynamic>?;
      expect(warnings, isNotNull);
      expect(
        warnings!.any((w) => w.toString().contains('unknown-asset')),
        isTrue,
      );
    });

    test('does not warn when skill references known asset', () {
      // Ensure no false warnings when reference is valid
      final bundle = McpBundleLoader.fromJson(
        _mcpBundleJson(
          assets: {
            'schemaVersion': '1.0.0',
            'assets': [
              {
                'id': 'known-asset',
                'path': 'data/file.txt',
                'type': 'text',
                'content': 'hello',
              },
            ],
          },
          skills: {
            'schemaVersion': '1.0.0',
            'modules': [
              {
                'id': 'skill-1',
                'name': 'Skill 1',
                'description': 'A skill',
                'procedures': <dynamic>[],
                'knowledgeSources': [
                  {
                    'sourceId': 'asset:known-asset',
                    'mode': 'similarity',
                  },
                ],
              },
            ],
          },
        ),
        options: const McpLoaderOptions(
          requireSchemaVersion: true,
          validateReferences: true,
          allowPartialLoad: true,
        ),
      );

      final warnings = bundle.extensions['_loadWarnings'] as List<dynamic>?;
      // No warning about unknown asset
      if (warnings != null) {
        expect(
          warnings.every((w) => !w.toString().contains('unknown asset')),
          isTrue,
        );
      }
    });

    test('skips non-asset knowledge source references', () {
      // Knowledge sources that do not start with "asset:" are ignored
      final bundle = McpBundleLoader.fromJson(
        _mcpBundleJson(
          assets: {
            'schemaVersion': '1.0.0',
            'assets': [
              {
                'id': 'a1',
                'path': 'p.txt',
                'type': 'text',
                'content': 'c',
              },
            ],
          },
          skills: {
            'schemaVersion': '1.0.0',
            'modules': [
              {
                'id': 'skill-1',
                'name': 'Skill 1',
                'description': 'desc',
                'procedures': <dynamic>[],
                'knowledgeSources': [
                  {
                    'sourceId': 'external:some-source',
                    'mode': 'similarity',
                  },
                ],
              },
            ],
          },
        ),
        options: const McpLoaderOptions(
          requireSchemaVersion: true,
          validateReferences: true,
          allowPartialLoad: true,
        ),
      );

      // No warnings about unknown assets because sourceId does not start with "asset:"
      final warnings = bundle.extensions['_loadWarnings'] as List<dynamic>?;
      if (warnings != null) {
        expect(
          warnings.every((w) => !w.toString().contains('unknown asset')),
          isTrue,
        );
      }
    });
  });

  group('McpBundleLoader - recursive widget action validation', () {
    test('validates callSkill actions in nested widget children', () {
      // Covers line 430-431: recursive _validateWidgetActions for children
      final json = _mcpBundleJson(
        skills: {
          'schemaVersion': '1.0.0',
          'modules': [
            {
              'id': 'skill-1',
              'name': 'Skill',
              'description': 'test',
              'procedures': <dynamic>[],
            },
          ],
        },
        ui: {
          'screens': [
            {
              'id': 'screen-1',
              'name': 'Home',
              'root': {
                'type': 'Column',
                'children': [
                  {
                    'type': 'Container',
                    'children': [
                      {
                        'type': 'Button',
                        'actions': {
                          'onTap': {
                            'type': 'callSkill',
                            'target': 'nonexistent-skill',
                          },
                        },
                      },
                    ],
                  },
                ],
              },
            },
          ],
        },
      );

      // In strict mode, this should throw because of the unresolved reference
      expect(
        () => McpBundleLoader.fromJson(json),
        throwsA(isA<BundleValidationException>()),
      );
    });

    test('passes validation when nested child references valid skill', () {
      final json = _mcpBundleJson(
        skills: {
          'schemaVersion': '1.0.0',
          'modules': [
            {
              'id': 'skill-1',
              'name': 'Skill',
              'description': 'test',
              'procedures': <dynamic>[],
            },
          ],
        },
        ui: {
          'screens': [
            {
              'id': 'screen-1',
              'name': 'Home',
              'root': {
                'type': 'Column',
                'children': [
                  {
                    'type': 'Button',
                    'actions': {
                      'onTap': {
                        'type': 'callSkill',
                        'target': 'skill-1',
                      },
                    },
                  },
                ],
              },
            },
          ],
        },
      );

      // No exception since skill-1 exists
      final bundle = McpBundleLoader.fromJson(json);
      expect(bundle.ui!.pages.first.root.children, hasLength(1));
    });

    test('validates multiple levels of nesting with actions', () {
      // Three levels of nesting: root > child1 > child2 > widget with action
      final json = _mcpBundleJson(
        skills: {
          'schemaVersion': '1.0.0',
          'modules': [
            {
              'id': 'valid-skill',
              'name': 'Valid',
              'description': 'desc',
              'procedures': <dynamic>[],
            },
          ],
        },
        ui: {
          'screens': [
            {
              'id': 'deep-screen',
              'name': 'Deep',
              'root': {
                'type': 'Column',
                'children': [
                  {
                    'type': 'Row',
                    'children': [
                      {
                        'type': 'Stack',
                        'children': [
                          {
                            'type': 'Button',
                            'actions': {
                              'onTap': {
                                'type': 'callSkill',
                                'target': 'deeply-missing-skill',
                              },
                            },
                          },
                        ],
                      },
                    ],
                  },
                ],
              },
            },
          ],
        },
      );

      // Should throw in strict mode
      expect(
        () => McpBundleLoader.fromJson(json),
        throwsA(isA<BundleValidationException>()),
      );
    });

    test('widgets without actions do not cause validation errors', () {
      final json = _mcpBundleJson(
        skills: {
          'schemaVersion': '1.0.0',
          'modules': [
            {
              'id': 'skill-1',
              'name': 'Skill',
              'description': 'test',
              'procedures': <dynamic>[],
            },
          ],
        },
        ui: {
          'screens': [
            {
              'id': 'screen-1',
              'name': 'Home',
              'root': {
                'type': 'Column',
                'children': [
                  {'type': 'Text'},
                  {
                    'type': 'Container',
                    'children': [
                      {'type': 'Text'},
                    ],
                  },
                ],
              },
            },
          ],
        },
      );

      // Should not throw; no actions to validate
      final bundle = McpBundleLoader.fromJson(json);
      expect(bundle.ui, isNotNull);
    });
  });

  group('McpBundleLoader - validateReferences disabled', () {
    test('skips reference validation when validateReferences is false', () {
      // Covers line 127-129: validateReferences branch skipped
      final json = _mcpBundleJson(
        skills: {
          'schemaVersion': '1.0.0',
          'modules': [
            {
              'id': 'skill-1',
              'name': 'Skill',
              'description': 'test',
              'procedures': <dynamic>[],
            },
          ],
        },
        ui: {
          'screens': [
            {
              'id': 'screen-1',
              'name': 'Home',
              'root': {
                'type': 'Button',
                'actions': {
                  'onTap': {
                    'type': 'callSkill',
                    'target': 'nonexistent',
                  },
                },
              },
            },
          ],
        },
      );

      // Should not throw because validation is disabled
      final bundle = McpBundleLoader.fromJson(
        json,
        options: const McpLoaderOptions.lenient(),
      );
      expect(bundle, isNotNull);
    });
  });

  group('McpBundleLoader - _validateReferences edge cases', () {
    test('validates when ui is present but skills is null', () {
      // Covers line 381: sections.skills != null check (false branch)
      final json = _mcpBundleJson(
        ui: {
          'screens': [
            {
              'id': 'screen-1',
              'name': 'Home',
              'root': {
                'type': 'Button',
                'actions': {
                  'onTap': {
                    'type': 'callSkill',
                    'target': 'some-skill',
                  },
                },
              },
            },
          ],
        },
      );

      // No skills section means UI-to-skill validation is skipped
      final bundle = McpBundleLoader.fromJson(json);
      expect(bundle.ui, isNotNull);
      expect(bundle.skills, isNull);
    });

    test('validates when skills is present but assets is null', () {
      // Covers line 391: sections.assets != null check (false branch)
      final json = _mcpBundleJson(
        skills: {
          'schemaVersion': '1.0.0',
          'modules': [
            {
              'id': 'skill-1',
              'name': 'Skill',
              'description': 'desc',
              'procedures': <dynamic>[],
              'knowledgeSources': [
                {
                  'sourceId': 'asset:whatever',
                  'mode': 'similarity',
                },
              ],
            },
          ],
        },
      );

      // No assets section means asset ref validation is skipped
      final bundle = McpBundleLoader.fromJson(json);
      expect(bundle.skills, isNotNull);
      expect(bundle.assets, isNull);
    });
  });

  group('McpBundleLoader - errors in strict mode', () {
    test('non-map assets section throws in strict mode', () {
      final json = <String, dynamic>{
        'schemaVersion': '1.0.0',
        'manifest': {'id': 'test', 'name': 'Test', 'version': '1.0.0'},
        'assets': 'invalid',
      };
      expect(
        () => McpBundleLoader.fromJson(json),
        throwsA(isA<BundleValidationException>()),
      );
    });

    test('non-map skills section throws in strict mode', () {
      final json = <String, dynamic>{
        'schemaVersion': '1.0.0',
        'manifest': {'id': 'test', 'name': 'Test', 'version': '1.0.0'},
        'skills': 123,
      };
      expect(
        () => McpBundleLoader.fromJson(json),
        throwsA(isA<BundleValidationException>()),
      );
    });

    test('non-map ui section throws in strict mode', () {
      final json = <String, dynamic>{
        'schemaVersion': '1.0.0',
        'manifest': {'id': 'test', 'name': 'Test', 'version': '1.0.0'},
        'ui': false,
      };
      expect(
        () => McpBundleLoader.fromJson(json),
        throwsA(isA<BundleValidationException>()),
      );
    });
  });

  group('McpBundleLoader - error collection in extensions', () {
    test('errors are recorded in extensions when allowPartialLoad is true', () {
      final json = <String, dynamic>{
        'schemaVersion': '1.0.0',
        'manifest': {'id': 'test', 'name': 'Test', 'version': '1.0.0'},
        'assets': 'bad',
        'skills': 'bad',
        'ui': 'bad',
      };
      final bundle = McpBundleLoader.fromJson(
        json,
        options: const McpLoaderOptions.lenient(),
      );

      final errors = bundle.extensions['_loadErrors'] as List<dynamic>?;
      expect(errors, isNotNull);
      expect(errors!.length, greaterThanOrEqualTo(3));

      final warnings = bundle.extensions['_loadWarnings'] as List<dynamic>?;
      expect(warnings, isNotNull);
    });
  });
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// A content resolver that always succeeds for testing.
class _TestContentResolver implements ContentResolver {
  @override
  Future<dynamic> resolve(String ref, {String? basePath}) async {
    return 'resolved-content';
  }

  @override
  Future<bool> canResolve(String ref) async => true;
}
