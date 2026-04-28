import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  group('McpLoaderOptions', () {
    test('default constructor has expected defaults', () {
      const options = McpLoaderOptions();
      expect(options.requireSchemaVersion, isTrue);
      expect(options.validateReferences, isTrue);
      expect(options.allowPartialLoad, isFalse);
      expect(options.maxNestingDepth, equals(50));
    });

    test('strict constructor has all validations enabled', () {
      const options = McpLoaderOptions.strict();
      expect(options.requireSchemaVersion, isTrue);
      expect(options.validateReferences, isTrue);
      expect(options.allowPartialLoad, isFalse);
    });

    test('lenient constructor allows partial loads', () {
      const options = McpLoaderOptions.lenient();
      expect(options.requireSchemaVersion, isFalse);
      expect(options.validateReferences, isFalse);
      expect(options.allowPartialLoad, isTrue);
    });
  });

  group('McpBundleLoader', () {
    group('fromJson', () {
      test('loads valid bundle with all required fields', () {
        final json = {
          'schemaVersion': '1.0.0',
          'manifest': {
            'id': 'test.bundle',
            'name': 'Test Bundle',
            'version': '1.0.0',
          },
        };

        final bundle = McpBundleLoader.fromJson(json);
        expect(bundle.manifest.id, equals('test.bundle'));
        expect(bundle.manifest.name, equals('Test Bundle'));
        expect(bundle.manifest.version, equals('1.0.0'));
      });

      test('loads bundle with UI section', () {
        final json = {
          'schemaVersion': '1.0.0',
          'manifest': {
            'id': 'test.bundle',
            'name': 'Test Bundle',
            'version': '1.0.0',
          },
          'ui': {
            'screens': [
              {
                'id': 'home',
                'title': 'Home',
                'root': {
                  'type': 'container',
                  'children': <Map<String, dynamic>>[],
                },
              },
            ],
          },
        };

        final bundle = McpBundleLoader.fromJson(json);
        expect(bundle.ui, isNotNull);
        expect(bundle.ui!.pages, hasLength(1));
        expect(bundle.ui!.pages.first.id, equals('home'));
      });

      test('loads bundle with skills section', () {
        final json = {
          'schemaVersion': '1.0.0',
          'manifest': {
            'id': 'test.bundle',
            'name': 'Test Bundle',
            'version': '1.0.0',
          },
          'skills': {
            'modules': [
              {
                'id': 'greeting',
                'name': 'Greeting Skill',
                'procedures': [
                  {'id': 'greet', 'steps': <Map<String, dynamic>>[]},
                ],
              },
            ],
          },
        };

        final bundle = McpBundleLoader.fromJson(json);
        expect(bundle.skills, isNotNull);
        expect(bundle.skills!.modules, hasLength(1));
        expect(bundle.skills!.modules.first.id, equals('greeting'));
      });

      test('loads bundle with assets section', () {
        final json = {
          'schemaVersion': '1.0.0',
          'manifest': {
            'id': 'test.bundle',
            'name': 'Test Bundle',
            'version': '1.0.0',
          },
          'assets': {
            'assets': [
              {
                'path': 'images/logo.png',
                'type': 'image',
                'content': 'base64content',
              },
            ],
          },
        };

        final bundle = McpBundleLoader.fromJson(json);
        expect(bundle.assets, isNotNull);
        expect(bundle.assets!.assets, hasLength(1));
        expect(bundle.assets!.assets.first.path, equals('images/logo.png'));
      });

      test('throws when schemaVersion is missing in strict mode', () {
        final json = {
          'manifest': {
            'id': 'test.bundle',
            'name': 'Test Bundle',
            'version': '1.0.0',
          },
        };

        expect(
          () => McpBundleLoader.fromJson(json, options: const McpLoaderOptions.strict()),
          throwsA(isA<BundleValidationException>()),
        );
      });

      test('accepts missing schemaVersion in lenient mode', () {
        final json = {
          'manifest': {
            'id': 'test.bundle',
            'name': 'Test Bundle',
            'version': '1.0.0',
          },
        };

        final bundle = McpBundleLoader.fromJson(json, options: const McpLoaderOptions.lenient());
        expect(bundle.manifest.id, equals('test.bundle'));
      });

      test('throws when manifest is missing', () {
        final json = {
          'schemaVersion': '1.0.0',
        };

        expect(
          () => McpBundleLoader.fromJson(json),
          throwsA(isA<BundleValidationException>()),
        );
      });

      test('accepts partial manifest in lenient mode', () {
        final json = {
          'manifest': {'id': '', 'name': '', 'version': ''},
        };

        final bundle = McpBundleLoader.fromJson(json, options: const McpLoaderOptions.lenient());
        expect(bundle, isNotNull);
      });

      test('throws for invalid schema version format', () {
        final json = {
          'schemaVersion': 'invalid',
          'manifest': {
            'id': 'test.bundle',
            'name': 'Test Bundle',
            'version': '1.0.0',
          },
        };

        expect(
          () => McpBundleLoader.fromJson(json),
          throwsA(isA<BundleValidationException>()),
        );
      });

      test('warns for unsupported but compatible schema version', () {
        final json = {
          'schemaVersion': '1.1.0',
          'manifest': {
            'id': 'test.bundle',
            'name': 'Test Bundle',
            'version': '1.0.0',
          },
        };

        final bundle = McpBundleLoader.fromJson(json, options: const McpLoaderOptions.lenient());
        final warnings = bundle.extensions['_loadWarnings'] as List<dynamic>?;
        expect(warnings, isNotEmpty);
      });

      test('throws for incompatible major version', () {
        final json = {
          'schemaVersion': '2.0.0',
          'manifest': {
            'id': 'test.bundle',
            'name': 'Test Bundle',
            'version': '1.0.0',
          },
        };

        expect(
          () => McpBundleLoader.fromJson(json),
          throwsA(isA<BundleValidationException>()),
        );
      });

      test('validates UI action references to skills', () {
        final json = {
          'schemaVersion': '1.0.0',
          'manifest': {
            'id': 'test.bundle',
            'name': 'Test Bundle',
            'version': '1.0.0',
          },
          'skills': {
            'modules': [
              {
                'id': 'greeting',
                'name': 'Greeting',
                'procedures': <Map<String, dynamic>>[],
              },
            ],
          },
          'ui': {
            'screens': [
              {
                'id': 'home',
                'root': {
                  'type': 'button',
                  'actions': {
                    'onPressed': {
                      'type': 'callSkill',
                      'target': 'nonexistent',
                    },
                  },
                },
              },
            ],
          },
        };

        expect(
          () => McpBundleLoader.fromJson(json),
          throwsA(isA<BundleValidationException>()),
        );
      });

      test('includes warnings in extensions for partial load', () {
        final json = {
          'manifest': {
            'id': 'test.bundle',
            'name': 'Test Bundle',
            'version': '1.0.0',
          },
        };

        final bundle = McpBundleLoader.fromJson(json, options: const McpLoaderOptions.lenient());
        expect(bundle.extensions['_loadWarnings'], isNotNull);
      });
    });

    group('fromJsonString', () {
      test('parses valid JSON string', () {
        final jsonString = jsonEncode({
          'schemaVersion': '1.0.0',
          'manifest': {
            'id': 'test.bundle',
            'name': 'Test Bundle',
            'version': '1.0.0',
          },
        });

        final bundle = McpBundleLoader.fromJsonString(jsonString);
        expect(bundle.manifest.id, equals('test.bundle'));
      });

      test('throws BundleParseException for invalid JSON', () {
        expect(
          () => McpBundleLoader.fromJsonString('invalid json'),
          throwsA(isA<BundleParseException>()),
        );
      });

      test('includes line number in parse exception', () {
        const invalidJson = '{\n  "manifest": {\n    invalid\n  }\n}';
        try {
          McpBundleLoader.fromJsonString(invalidJson);
          fail('Should have thrown');
        } catch (e) {
          expect(e, isA<BundleParseException>());
        }
      });
    });

    group('loadFile', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('mcp_bundle_test_');
      });

      tearDown(() {
        tempDir.deleteSync(recursive: true);
      });

      test('loads bundle from file', () async {
        final file = File('${tempDir.path}/manifest.json');
        file.writeAsStringSync(jsonEncode({
          'schemaVersion': '1.0.0',
          'manifest': {
            'id': 'test.bundle',
            'name': 'Test Bundle',
            'version': '1.0.0',
          },
        }));

        final bundle = await McpBundleLoader.loadFile(file.path);
        expect(bundle.manifest.id, equals('test.bundle'));
      });

      test('throws when file not found', () async {
        expect(
          () => McpBundleLoader.loadFile('${tempDir.path}/nonexistent.json'),
          throwsA(isA<BundleLoadException>()),
        );
      });
    });

    group('loadDirectory', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('mcp_bundle_dir_test_');
      });

      tearDown(() {
        tempDir.deleteSync(recursive: true);
      });

      test('loads bundle from directory with manifest.json', () async {
        final bundleDir = Directory('${tempDir.path}/mybundle.mbd');
        bundleDir.createSync();

        final file = File('${bundleDir.path}/manifest.json');
        file.writeAsStringSync(jsonEncode({
          'schemaVersion': '1.0.0',
          'manifest': {
            'id': 'test.bundle',
            'name': 'Test Bundle',
            'version': '1.0.0',
          },
        }));

        final bundle = await McpBundleLoader.loadDirectory(bundleDir.path);
        expect(bundle.manifest.id, equals('test.bundle'));
      });

      test('throws when manifest.json not found in directory', () async {
        final bundleDir = Directory('${tempDir.path}/empty.mbd');
        bundleDir.createSync();

        expect(
          () => McpBundleLoader.loadDirectory(bundleDir.path),
          throwsA(isA<BundleLoadException>()),
        );
      });

      test('resolves relative asset paths', () async {
        final bundleDir = Directory('${tempDir.path}/assets.mbd');
        bundleDir.createSync();

        final file = File('${bundleDir.path}/manifest.json');
        file.writeAsStringSync(jsonEncode({
          'schemaVersion': '1.0.0',
          'manifest': {
            'id': 'test.bundle',
            'name': 'Test Bundle',
            'version': '1.0.0',
          },
          'assets': {
            'assets': [
              {
                'path': 'images/logo.png',
                'type': 'image',
                'contentRef': 'assets/logo.png',
              },
            ],
          },
        }));

        final bundle = await McpBundleLoader.loadDirectory(bundleDir.path);
        expect(bundle.assets, isNotNull);
        final asset = bundle.assets!.assets.first;
        expect(asset.contentRef, contains(bundleDir.path));
      });
    });
  });

  group('LazyMcpBundle', () {
    late Directory tempDir;
    late File bundleFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('lazy_bundle_test_');
      bundleFile = File('${tempDir.path}/manifest.json');
      bundleFile.writeAsStringSync(jsonEncode({
        'schemaVersion': '1.0.0',
        'manifest': {
          'id': 'lazy.bundle',
          'name': 'Lazy Bundle',
          'version': '1.0.0',
        },
        'ui': {
          'screens': [
            {
              'id': 'home',
              'root': {'type': 'container'},
            },
          ],
        },
        'skills': {
          'modules': [
            {
              'id': 'skill1',
              'name': 'Skill 1',
              'procedures': <dynamic>[],
            },
          ],
        },
        'assets': {
          'assets': [
            {
              'path': 'test.txt',
              'type': 'text',
              'content': 'test',
            },
          ],
        },
      }));
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('loads manifest immediately', () async {
      final lazyBundle = await LazyMcpBundle.load(bundleFile.path);
      expect(lazyBundle.manifest.id, equals('lazy.bundle'));
    });

    test('loads UI section on demand', () async {
      final lazyBundle = await LazyMcpBundle.load(bundleFile.path);
      final ui = await lazyBundle.ui;
      expect(ui, isNotNull);
      expect(ui!.pages, hasLength(1));
    });

    test('loads skills section on demand', () async {
      final lazyBundle = await LazyMcpBundle.load(bundleFile.path);
      final skills = await lazyBundle.skills;
      expect(skills, isNotNull);
      expect(skills!.modules, hasLength(1));
    });

    test('loads assets section on demand', () async {
      final lazyBundle = await LazyMcpBundle.load(bundleFile.path);
      final assets = await lazyBundle.assets;
      expect(assets, isNotNull);
      expect(assets!.assets, hasLength(1));
    });

    test('caches loaded sections', () async {
      final lazyBundle = await LazyMcpBundle.load(bundleFile.path);

      final ui1 = await lazyBundle.ui;
      final ui2 = await lazyBundle.ui;
      expect(identical(ui1, ui2), isTrue);
    });

    test('provides full bundle', () async {
      final lazyBundle = await LazyMcpBundle.load(bundleFile.path);
      final full = await lazyBundle.fullBundle;
      expect(full.manifest.id, equals('lazy.bundle'));
      expect(full.ui, isNotNull);
      expect(full.skills, isNotNull);
      expect(full.assets, isNotNull);
    });

    test('throws when file not found', () async {
      expect(
        () => LazyMcpBundle.load('${tempDir.path}/nonexistent.json'),
        throwsA(isA<BundleLoadException>()),
      );
    });
  });
}
