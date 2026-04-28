import 'package:mcp_bundle/mcp_bundle.dart' hide HashAlgorithm, ContentHash;
import 'package:mcp_bundle/src/models/integrity.dart';
import 'package:test/test.dart';

void main() {
  // ===========================================================================
  // 1. manifest.dart edge cases
  // ===========================================================================
  group('BundleManifest', () {
    group('fromJson edge cases', () {
      test('handles null dependencies gracefully', () {
        final manifest = BundleManifest.fromJson({
          'id': 'test',
          'name': 'Test',
          'version': '1.0.0',
          'dependencies': null,
        });
        expect(manifest.dependencies, isEmpty);
      });

      test('handles empty dependencies list', () {
        final manifest = BundleManifest.fromJson({
          'id': 'test',
          'name': 'Test',
          'version': '1.0.0',
          'dependencies': <dynamic>[],
        });
        expect(manifest.dependencies, isEmpty);
      });

      test('parses dependencies list with entries', () {
        final manifest = BundleManifest.fromJson({
          'id': 'test',
          'name': 'Test',
          'version': '1.0.0',
          'dependencies': [
            {'id': 'dep-1', 'version': '^1.0.0'},
            {'name': 'dep-2', 'version': '>=2.0.0', 'optional': true},
          ],
        });
        expect(manifest.dependencies, hasLength(2));
        expect(manifest.dependencies[0].id, 'dep-1');
        expect(manifest.dependencies[0].version, '^1.0.0');
        expect(manifest.dependencies[0].optional, isFalse);
        expect(manifest.dependencies[1].id, 'dep-2');
        expect(manifest.dependencies[1].optional, isTrue);
      });

      test('uses defaults when fields are missing', () {
        final manifest = BundleManifest.fromJson({});
        expect(manifest.id, '');
        expect(manifest.name, '');
        expect(manifest.version, '0.0.0');
        expect(manifest.provider, isNull);
        expect(manifest.description, isNull);
        expect(manifest.schemaVersion, currentSchemaVersion);
        expect(manifest.type, BundleType.application);
        expect(manifest.entryPoint, isNull);
        expect(manifest.license, isNull);
        expect(manifest.homepage, isNull);
        expect(manifest.repository, isNull);
        expect(manifest.capabilities, isEmpty);
        expect(manifest.tags, isEmpty);
        expect(manifest.dependencies, isEmpty);
        expect(manifest.platform, isNull);
        expect(manifest.metadata, isEmpty);
      });

      test('parses capabilities and tags from non-string list items', () {
        final manifest = BundleManifest.fromJson({
          'id': 'test',
          'name': 'Test',
          'version': '1.0.0',
          'capabilities': [1, 2, 'three'],
          'tags': [true, 'tag1'],
        });
        expect(manifest.capabilities, equals(['1', '2', 'three']));
        expect(manifest.tags, equals(['true', 'tag1']));
      });

      test('parses platform requirements from JSON', () {
        final manifest = BundleManifest.fromJson({
          'id': 'test',
          'name': 'Test',
          'version': '1.0.0',
          'platform': {
            'dartSdk': '>=3.0.0',
            'flutterSdk': '>=3.10.0',
            'os': ['linux', 'macos'],
            'envVars': ['API_KEY'],
          },
        });
        expect(manifest.platform, isNotNull);
        expect(manifest.platform!.dartSdk, '>=3.0.0');
        expect(manifest.platform!.flutterSdk, '>=3.10.0');
        expect(manifest.platform!.os, ['linux', 'macos']);
        expect(manifest.platform!.envVars, ['API_KEY']);
      });

      test('parses metadata map', () {
        final manifest = BundleManifest.fromJson({
          'id': 'test',
          'name': 'Test',
          'version': '1.0.0',
          'metadata': {'custom': 'value', 'count': 42},
        });
        expect(manifest.metadata['custom'], 'value');
        expect(manifest.metadata['count'], 42);
      });
    });

    group('copyWith', () {
      test('with all parameters explicitly passed', () {
        const original = BundleManifest(
          id: 'orig-id',
          name: 'Original',
          version: '1.0.0',
        );

        final platformReqs = PlatformRequirements(
          dartSdk: '>=3.0.0',
          os: ['linux'],
        );
        final deps = [
          const BundleDependency(id: 'dep-1', version: '^1.0.0'),
        ];

        final copied = original.copyWith(
          id: 'new-id',
          name: 'New Name',
          version: '2.0.0',
          provider: 'new-provider',
          description: 'new desc',
          schemaVersion: '2.0.0',
          type: BundleType.library,
          entryPoint: 'lib/main.dart',
          license: 'MIT',
          homepage: 'https://example.com',
          repository: 'https://github.com/test',
          capabilities: ['streaming'],
          tags: ['tag1', 'tag2'],
          dependencies: deps,
          platform: platformReqs,
          metadata: {'key': 'val'},
        );

        expect(copied.id, 'new-id');
        expect(copied.name, 'New Name');
        expect(copied.version, '2.0.0');
        expect(copied.provider, 'new-provider');
        expect(copied.description, 'new desc');
        expect(copied.schemaVersion, '2.0.0');
        expect(copied.type, BundleType.library);
        expect(copied.entryPoint, 'lib/main.dart');
        expect(copied.license, 'MIT');
        expect(copied.homepage, 'https://example.com');
        expect(copied.repository, 'https://github.com/test');
        expect(copied.capabilities, ['streaming']);
        expect(copied.tags, ['tag1', 'tag2']);
        expect(copied.dependencies, hasLength(1));
        expect(copied.platform, isNotNull);
        expect(copied.platform!.dartSdk, '>=3.0.0');
        expect(copied.metadata, {'key': 'val'});
      });

      test('preserves original values when no parameters passed', () {
        const original = BundleManifest(
          id: 'orig-id',
          name: 'Original',
          version: '1.0.0',
          provider: 'provider',
          description: 'desc',
          type: BundleType.skill,
          tags: ['t1'],
        );

        final copied = original.copyWith();
        expect(copied.id, original.id);
        expect(copied.name, original.name);
        expect(copied.version, original.version);
        expect(copied.provider, original.provider);
        expect(copied.description, original.description);
        expect(copied.type, original.type);
        expect(copied.tags, original.tags);
      });
    });

    group('toJson', () {
      test('omits null and empty optional fields', () {
        const manifest = BundleManifest(
          id: 'test',
          name: 'Test',
          version: '1.0.0',
        );
        final json = manifest.toJson();

        expect(json['id'], 'test');
        expect(json['name'], 'Test');
        expect(json['version'], '1.0.0');
        expect(json.containsKey('provider'), isFalse);
        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('entryPoint'), isFalse);
        expect(json.containsKey('license'), isFalse);
        expect(json.containsKey('homepage'), isFalse);
        expect(json.containsKey('repository'), isFalse);
        expect(json.containsKey('capabilities'), isFalse);
        expect(json.containsKey('tags'), isFalse);
        expect(json.containsKey('dependencies'), isFalse);
        expect(json.containsKey('platform'), isFalse);
        expect(json.containsKey('metadata'), isFalse);
      });

      test('includes all non-null and non-empty fields', () {
        final manifest = BundleManifest(
          id: 'test',
          name: 'Test',
          version: '1.0.0',
          provider: 'p',
          description: 'd',
          entryPoint: 'main.dart',
          license: 'MIT',
          homepage: 'https://h.com',
          repository: 'https://r.com',
          capabilities: ['cap1'],
          tags: ['t1'],
          dependencies: [
            const BundleDependency(id: 'dep', version: '1.0.0'),
          ],
          platform: const PlatformRequirements(dartSdk: '>=3.0.0'),
          metadata: {'k': 'v'},
        );
        final json = manifest.toJson();

        expect(json.containsKey('provider'), isTrue);
        expect(json.containsKey('description'), isTrue);
        expect(json.containsKey('entryPoint'), isTrue);
        expect(json.containsKey('license'), isTrue);
        expect(json.containsKey('homepage'), isTrue);
        expect(json.containsKey('repository'), isTrue);
        expect(json.containsKey('capabilities'), isTrue);
        expect(json.containsKey('tags'), isTrue);
        expect(json.containsKey('dependencies'), isTrue);
        expect(json.containsKey('platform'), isTrue);
        expect(json.containsKey('metadata'), isTrue);
      });
    });
  });

  group('BundleType', () {
    test('fromString with known types', () {
      expect(BundleType.fromString('application'), BundleType.application);
      expect(BundleType.fromString('library'), BundleType.library);
      expect(BundleType.fromString('skill'), BundleType.skill);
      expect(BundleType.fromString('profile'), BundleType.profile);
      expect(BundleType.fromString('extension'), BundleType.extension);
    });

    test('fromString with unknown type returns unknown', () {
      expect(BundleType.fromString('nonexistent'), BundleType.unknown);
      expect(BundleType.fromString(''), BundleType.unknown);
      expect(BundleType.fromString('APPLICATION'), BundleType.unknown);
    });
  });

  group('PlatformRequirements', () {
    test('constructor defaults', () {
      const platform = PlatformRequirements();
      expect(platform.dartSdk, isNull);
      expect(platform.flutterSdk, isNull);
      expect(platform.os, isEmpty);
      expect(platform.envVars, isEmpty);
    });

    test('fromJson / toJson roundtrip', () {
      final json = {
        'dartSdk': '>=3.0.0',
        'flutterSdk': '>=3.10.0',
        'os': ['linux', 'macos', 'windows'],
        'envVars': ['API_KEY', 'SECRET'],
      };
      final platform = PlatformRequirements.fromJson(json);
      final output = platform.toJson();

      expect(output['dartSdk'], '>=3.0.0');
      expect(output['flutterSdk'], '>=3.10.0');
      expect(output['os'], ['linux', 'macos', 'windows']);
      expect(output['envVars'], ['API_KEY', 'SECRET']);
    });

    test('fromJson with empty map', () {
      final platform = PlatformRequirements.fromJson({});
      expect(platform.dartSdk, isNull);
      expect(platform.flutterSdk, isNull);
      expect(platform.os, isEmpty);
      expect(platform.envVars, isEmpty);
    });

    test('toJson omits null and empty fields', () {
      const platform = PlatformRequirements();
      final json = platform.toJson();
      expect(json.containsKey('dartSdk'), isFalse);
      expect(json.containsKey('flutterSdk'), isFalse);
      expect(json.containsKey('os'), isFalse);
      expect(json.containsKey('envVars'), isFalse);
    });

    test('toJson includes only non-null fields', () {
      const platform = PlatformRequirements(
        dartSdk: '>=3.0.0',
        os: ['linux'],
      );
      final json = platform.toJson();
      expect(json.containsKey('dartSdk'), isTrue);
      expect(json.containsKey('flutterSdk'), isFalse);
      expect(json.containsKey('os'), isTrue);
      expect(json.containsKey('envVars'), isFalse);
    });
  });

  group('BundleDependency', () {
    test('fromJson uses name as fallback for id', () {
      final dep = BundleDependency.fromJson({
        'name': 'fallback-name',
        'version': '1.0.0',
      });
      expect(dep.id, 'fallback-name');
    });

    test('fromJson defaults when both id and name are missing', () {
      final dep = BundleDependency.fromJson({});
      expect(dep.id, '');
      expect(dep.version, '*');
      expect(dep.optional, isFalse);
      expect(dep.features, isEmpty);
    });

    test('fromJson with features', () {
      final dep = BundleDependency.fromJson({
        'id': 'dep-1',
        'version': '^1.0.0',
        'optional': true,
        'features': ['streaming', 'caching'],
      });
      expect(dep.features, ['streaming', 'caching']);
      expect(dep.optional, isTrue);
    });

    test('toJson omits optional when false and features when empty', () {
      const dep = BundleDependency(id: 'dep', version: '1.0.0');
      final json = dep.toJson();
      expect(json.containsKey('optional'), isFalse);
      expect(json.containsKey('features'), isFalse);
    });

    test('toJson includes optional and features when set', () {
      const dep = BundleDependency(
        id: 'dep',
        version: '1.0.0',
        optional: true,
        features: ['f1'],
      );
      final json = dep.toJson();
      expect(json['optional'], isTrue);
      expect(json['features'], ['f1']);
    });
  });

  // ===========================================================================
  // 2. asset.dart edge cases
  // ===========================================================================
  group('AssetType', () {
    group('commonMimeTypes', () {
      test('image returns expected MIME types', () {
        expect(AssetType.image.commonMimeTypes, contains('image/png'));
        expect(AssetType.image.commonMimeTypes, contains('image/jpeg'));
        expect(AssetType.image.commonMimeTypes, contains('image/gif'));
        expect(AssetType.image.commonMimeTypes, contains('image/svg+xml'));
        expect(AssetType.image.commonMimeTypes, contains('image/webp'));
      });

      test('icon returns expected MIME types', () {
        expect(AssetType.icon.commonMimeTypes, contains('image/png'));
        expect(AssetType.icon.commonMimeTypes, contains('image/svg+xml'));
        expect(AssetType.icon.commonMimeTypes, contains('image/x-icon'));
      });

      test('font returns expected MIME types', () {
        expect(AssetType.font.commonMimeTypes, contains('font/ttf'));
        expect(AssetType.font.commonMimeTypes, contains('font/otf'));
        expect(AssetType.font.commonMimeTypes, contains('font/woff'));
        expect(AssetType.font.commonMimeTypes, contains('font/woff2'));
      });

      test('audio returns expected MIME types', () {
        expect(AssetType.audio.commonMimeTypes, contains('audio/mpeg'));
        expect(AssetType.audio.commonMimeTypes, contains('audio/wav'));
        expect(AssetType.audio.commonMimeTypes, contains('audio/ogg'));
      });

      test('video returns expected MIME types', () {
        expect(AssetType.video.commonMimeTypes, contains('video/mp4'));
        expect(AssetType.video.commonMimeTypes, contains('video/webm'));
        expect(AssetType.video.commonMimeTypes, contains('video/ogg'));
      });

      test('json returns application/json', () {
        expect(AssetType.json.commonMimeTypes, equals(['application/json']));
      });

      test('text returns text MIME types', () {
        expect(AssetType.text.commonMimeTypes, contains('text/plain'));
        expect(AssetType.text.commonMimeTypes, contains('text/markdown'));
      });

      test('template returns text MIME types', () {
        expect(AssetType.template.commonMimeTypes, contains('text/html'));
        expect(AssetType.template.commonMimeTypes, contains('text/plain'));
      });

      test('style returns text/css', () {
        expect(AssetType.style.commonMimeTypes, equals(['text/css']));
      });

      test('binary falls through to default octet-stream', () {
        expect(AssetType.binary.commonMimeTypes,
            equals(['application/octet-stream']));
      });

      test('file falls through to default octet-stream', () {
        expect(AssetType.file.commonMimeTypes,
            equals(['application/octet-stream']));
      });

      test('unknown falls through to default octet-stream', () {
        expect(AssetType.unknown.commonMimeTypes,
            equals(['application/octet-stream']));
      });
    });

    test('fromString with unknown value returns unknown', () {
      expect(AssetType.fromString('nonexistent'), AssetType.unknown);
      expect(AssetType.fromString(''), AssetType.unknown);
    });

    test('fromString with known values', () {
      expect(AssetType.fromString('image'), AssetType.image);
      expect(AssetType.fromString('icon'), AssetType.icon);
      expect(AssetType.fromString('font'), AssetType.font);
      expect(AssetType.fromString('audio'), AssetType.audio);
      expect(AssetType.fromString('video'), AssetType.video);
      expect(AssetType.fromString('json'), AssetType.json);
      expect(AssetType.fromString('text'), AssetType.text);
      expect(AssetType.fromString('binary'), AssetType.binary);
      expect(AssetType.fromString('template'), AssetType.template);
      expect(AssetType.fromString('style'), AssetType.style);
      expect(AssetType.fromString('file'), AssetType.file);
    });
  });

  group('AssetDirectory', () {
    test('fromJson with all fields', () {
      final dir = AssetDirectory.fromJson({
        'path': 'assets/images',
        'pattern': '*.png',
        'type': 'image',
        'recursive': true,
      });
      expect(dir.path, 'assets/images');
      expect(dir.pattern, '*.png');
      expect(dir.type, AssetType.image);
      expect(dir.recursive, isTrue);
    });

    test('fromJson with defaults', () {
      final dir = AssetDirectory.fromJson({});
      expect(dir.path, '');
      expect(dir.pattern, '*');
      expect(dir.type, AssetType.file);
      expect(dir.recursive, isFalse);
    });

    test('toJson includes recursive only when true', () {
      const dirNonRecursive = AssetDirectory(
        path: 'assets',
        recursive: false,
      );
      final json1 = dirNonRecursive.toJson();
      expect(json1.containsKey('recursive'), isFalse);

      const dirRecursive = AssetDirectory(
        path: 'assets',
        recursive: true,
      );
      final json2 = dirRecursive.toJson();
      expect(json2['recursive'], isTrue);
    });

    test('toJson roundtrip with recursive flag', () {
      const dir = AssetDirectory(
        path: 'fonts',
        pattern: '*.ttf',
        type: AssetType.font,
        recursive: true,
      );
      final json = dir.toJson();
      final restored = AssetDirectory.fromJson(json);

      expect(restored.path, 'fonts');
      expect(restored.pattern, '*.ttf');
      expect(restored.type, AssetType.font);
      expect(restored.recursive, isTrue);
    });
  });

  group('AssetBundle', () {
    test('fromJson with all fields', () {
      final bundle = AssetBundle.fromJson({
        'id': 'bundle-1',
        'name': 'Icons Bundle',
        'assets': ['icon1.png', 'icon2.png'],
        'loadStrategy': 'eager',
      });
      expect(bundle.id, 'bundle-1');
      expect(bundle.name, 'Icons Bundle');
      expect(bundle.assets, ['icon1.png', 'icon2.png']);
      expect(bundle.loadStrategy, LoadStrategy.eager);
    });

    test('fromJson with defaults', () {
      final bundle = AssetBundle.fromJson({});
      expect(bundle.id, '');
      expect(bundle.name, '');
      expect(bundle.assets, isEmpty);
      expect(bundle.loadStrategy, LoadStrategy.lazy);
    });

    test('toJson omits empty assets', () {
      const bundle = AssetBundle(id: 'b1', name: 'B1');
      final json = bundle.toJson();
      expect(json.containsKey('assets'), isFalse);
      expect(json['loadStrategy'], 'lazy');
    });

    test('toJson includes non-empty assets', () {
      const bundle = AssetBundle(
        id: 'b1',
        name: 'B1',
        assets: ['a.png'],
        loadStrategy: LoadStrategy.preload,
      );
      final json = bundle.toJson();
      expect(json['assets'], ['a.png']);
      expect(json['loadStrategy'], 'preload');
    });

    test('roundtrip fromJson/toJson', () {
      final original = {
        'id': 'bundle-2',
        'name': 'Fonts',
        'assets': ['font1.ttf', 'font2.otf'],
        'loadStrategy': 'preload',
      };
      final bundle = AssetBundle.fromJson(original);
      final output = bundle.toJson();
      expect(output['id'], original['id']);
      expect(output['name'], original['name']);
      expect(output['assets'], original['assets']);
      expect(output['loadStrategy'], original['loadStrategy']);
    });
  });

  group('LoadStrategy', () {
    test('fromString with known values', () {
      expect(LoadStrategy.fromString('eager'), LoadStrategy.eager);
      expect(LoadStrategy.fromString('lazy'), LoadStrategy.lazy);
      expect(LoadStrategy.fromString('preload'), LoadStrategy.preload);
    });

    test('fromString with unknown value returns unknown', () {
      expect(LoadStrategy.fromString('nonexistent'), LoadStrategy.unknown);
      expect(LoadStrategy.fromString(''), LoadStrategy.unknown);
    });
  });

  group('Asset', () {
    test('hasInlineContent and hasExternalContent', () {
      const assetInline = Asset(
        path: 'data.json',
        type: AssetType.json,
        content: '{"key": "val"}',
      );
      expect(assetInline.hasInlineContent, isTrue);
      expect(assetInline.hasExternalContent, isFalse);

      const assetExternal = Asset(
        path: 'image.png',
        type: AssetType.image,
        contentRef: 'https://example.com/img.png',
      );
      expect(assetExternal.hasInlineContent, isFalse);
      expect(assetExternal.hasExternalContent, isTrue);

      const assetNeither = Asset(path: 'empty', type: AssetType.file);
      expect(assetNeither.hasInlineContent, isFalse);
      expect(assetNeither.hasExternalContent, isFalse);
    });

    test('fromJson with all fields', () {
      final asset = Asset.fromJson({
        'id': 'a1',
        'path': 'data.json',
        'type': 'json',
        'name': 'Data',
        'description': 'A JSON file',
        'mimeType': 'application/json',
        'encoding': 'ascii',
        'content': '{}',
        'contentRef': 'https://example.com',
        'hash': 'abc123',
        'size': 1024,
        'metadata': {'key': 'value'},
      });
      expect(asset.id, 'a1');
      expect(asset.path, 'data.json');
      expect(asset.type, AssetType.json);
      expect(asset.name, 'Data');
      expect(asset.description, 'A JSON file');
      expect(asset.mimeType, 'application/json');
      expect(asset.encoding, 'ascii');
      expect(asset.content, '{}');
      expect(asset.contentRef, 'https://example.com');
      expect(asset.hash, 'abc123');
      expect(asset.size, 1024);
      expect(asset.metadata, {'key': 'value'});
    });

    test('toJson omits null optional fields', () {
      const asset = Asset(path: 'file.txt', type: AssetType.text);
      final json = asset.toJson();
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('mimeType'), isFalse);
      expect(json.containsKey('content'), isFalse);
      expect(json.containsKey('contentRef'), isFalse);
      expect(json.containsKey('hash'), isFalse);
      expect(json.containsKey('size'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      expect(json['path'], 'file.txt');
      expect(json['encoding'], 'utf-8');
    });
  });

  group('AssetSection', () {
    test('getAsset returns matching asset or null', () {
      const section = AssetSection(
        assets: [
          Asset(path: 'a.txt', type: AssetType.text),
          Asset(path: 'b.json', type: AssetType.json),
        ],
      );
      expect(section.getAsset('a.txt'), isNotNull);
      expect(section.getAsset('a.txt')!.path, 'a.txt');
      expect(section.getAsset('nonexistent'), isNull);
    });

    test('getAssetsByType filters by type', () {
      const section = AssetSection(
        assets: [
          Asset(path: 'a.txt', type: AssetType.text),
          Asset(path: 'b.json', type: AssetType.json),
          Asset(path: 'c.txt', type: AssetType.text),
        ],
      );
      final textAssets = section.getAssetsByType(AssetType.text);
      expect(textAssets, hasLength(2));
      expect(textAssets.every((a) => a.type == AssetType.text), isTrue);
    });

    test('fromJson/toJson roundtrip with directories and bundles', () {
      final json = {
        'schemaVersion': '1.0.0',
        'assets': [
          {'path': 'logo.png', 'type': 'image'},
        ],
        'directories': [
          {'path': 'fonts', 'pattern': '*.ttf', 'type': 'font', 'recursive': true},
        ],
        'bundles': [
          {
            'id': 'icons',
            'name': 'Icons',
            'assets': ['icon1.svg'],
            'loadStrategy': 'eager',
          },
        ],
      };
      final section = AssetSection.fromJson(json);
      expect(section.assets, hasLength(1));
      expect(section.directories, hasLength(1));
      expect(section.directories[0].recursive, isTrue);
      expect(section.bundles, hasLength(1));
      expect(section.bundles[0].loadStrategy, LoadStrategy.eager);

      final output = section.toJson();
      expect(output.containsKey('assets'), isTrue);
      expect(output.containsKey('directories'), isTrue);
      expect(output.containsKey('bundles'), isTrue);
    });
  });

  // ===========================================================================
  // 3. fact_graph_section.dart edge cases
  // ===========================================================================
  group('FactGraphMode', () {
    test('fromString with null input returns embedded', () {
      expect(FactGraphMode.fromString(null), FactGraphMode.embedded);
    });

    test('fromString with case insensitive input', () {
      expect(FactGraphMode.fromString('EMBEDDED'), FactGraphMode.embedded);
      expect(FactGraphMode.fromString('Embedded'), FactGraphMode.embedded);
      expect(FactGraphMode.fromString('REFERENCED'), FactGraphMode.referenced);
      expect(FactGraphMode.fromString('Referenced'), FactGraphMode.referenced);
      expect(FactGraphMode.fromString('HYBRID'), FactGraphMode.hybrid);
      expect(FactGraphMode.fromString('Hybrid'), FactGraphMode.hybrid);
    });

    test('fromString with unknown value defaults to embedded', () {
      expect(FactGraphMode.fromString('invalid'), FactGraphMode.embedded);
      expect(FactGraphMode.fromString(''), FactGraphMode.embedded);
    });

    test('fromString exact lowercase values', () {
      expect(FactGraphMode.fromString('embedded'), FactGraphMode.embedded);
      expect(FactGraphMode.fromString('referenced'), FactGraphMode.referenced);
      expect(FactGraphMode.fromString('hybrid'), FactGraphMode.hybrid);
    });
  });

  // ===========================================================================
  // 4. integrity.dart edge cases
  // ===========================================================================
  group('CompatibilityConfig', () {
    group('checkCompatibility', () {
      test('returns true when no requirements', () {
        const config = CompatibilityConfig();
        expect(config.checkCompatibility({}), isTrue);
        expect(config.checkCompatibility({'dart': '3.0.0'}), isTrue);
      });

      test('returns false when required package is missing', () {
        const config = CompatibilityConfig(
          requirements: {'dart': '>=3.0.0'},
        );
        expect(config.checkCompatibility({}), isFalse);
        expect(config.checkCompatibility({'flutter': '3.10.0'}), isFalse);
      });

      test('handles >= version constraint', () {
        const config = CompatibilityConfig(
          requirements: {'dart': '>=3.0.0'},
        );
        expect(config.checkCompatibility({'dart': '3.0.0'}), isTrue);
        expect(config.checkCompatibility({'dart': '4.0.0'}), isTrue);
        expect(config.checkCompatibility({'dart': '2.9.9'}), isFalse);
      });

      test('handles > version constraint', () {
        const config = CompatibilityConfig(
          requirements: {'dart': '>3.0.0'},
        );
        expect(config.checkCompatibility({'dart': '3.0.1'}), isTrue);
        expect(config.checkCompatibility({'dart': '3.0.0'}), isFalse);
        expect(config.checkCompatibility({'dart': '2.9.9'}), isFalse);
      });

      test('handles <= version constraint', () {
        const config = CompatibilityConfig(
          requirements: {'dart': '<=3.0.0'},
        );
        expect(config.checkCompatibility({'dart': '3.0.0'}), isTrue);
        expect(config.checkCompatibility({'dart': '2.9.9'}), isTrue);
        expect(config.checkCompatibility({'dart': '3.0.1'}), isFalse);
      });

      test('handles < version constraint', () {
        const config = CompatibilityConfig(
          requirements: {'dart': '<3.0.0'},
        );
        expect(config.checkCompatibility({'dart': '2.9.9'}), isTrue);
        expect(config.checkCompatibility({'dart': '3.0.0'}), isFalse);
      });

      test('handles ^ (caret) version constraint', () {
        const config = CompatibilityConfig(
          requirements: {'dart': '^3.0.0'},
        );
        // Caret range checks that actual starts with the major version
        expect(config.checkCompatibility({'dart': '3.0.0'}), isTrue);
        expect(config.checkCompatibility({'dart': '3.5.0'}), isTrue);
        expect(config.checkCompatibility({'dart': '2.0.0'}), isFalse);
        expect(config.checkCompatibility({'dart': '4.0.0'}), isFalse);
      });

      test('handles exact version constraint', () {
        const config = CompatibilityConfig(
          requirements: {'dart': '3.0.0'},
        );
        expect(config.checkCompatibility({'dart': '3.0.0'}), isTrue);
        expect(config.checkCompatibility({'dart': '3.0.1'}), isFalse);
      });

      test('handles wildcard version constraint', () {
        const config = CompatibilityConfig(
          requirements: {'dart': '*'},
        );
        expect(config.checkCompatibility({'dart': '3.0.0'}), isTrue);
        expect(config.checkCompatibility({'dart': '1.0.0'}), isTrue);
      });

      test('checks all requirements - all must pass', () {
        const config = CompatibilityConfig(
          requirements: {'dart': '>=3.0.0', 'flutter': '>=3.10.0'},
        );
        expect(config.checkCompatibility(
            {'dart': '3.0.0', 'flutter': '3.10.0'}), isTrue);
        // Missing one requirement fails
        expect(config.checkCompatibility(
            {'dart': '3.0.0'}), isFalse);
        // Both present and satisfying passes
        expect(config.checkCompatibility(
            {'dart': '4.0.0', 'flutter': '4.0.0'}), isTrue);
      });

      test('checks all requirements - one failing fails overall', () {
        const config = CompatibilityConfig(
          requirements: {'dart': '>=3.0.0', 'flutter': '3.10.0'},
        );
        // flutter exact match required
        expect(config.checkCompatibility(
            {'dart': '3.0.0', 'flutter': '3.10.0'}), isTrue);
        expect(config.checkCompatibility(
            {'dart': '3.0.0', 'flutter': '3.11.0'}), isFalse);
      });
    });
  });

  group('ContentHash', () {
    test('verify compares case-insensitively', () {
      const hash = ContentHash(
        algorithm: HashAlgorithm.sha256,
        value: 'AbCdEf123456',
      );
      expect(hash.verify('abcdef123456'), isTrue);
      expect(hash.verify('ABCDEF123456'), isTrue);
      expect(hash.verify('AbCdEf123456'), isTrue);
      expect(hash.verify('different'), isFalse);
    });
  });

  group('FileHash', () {
    test('verify compares case-insensitively', () {
      const fileHash = FileHash(
        path: 'file.txt',
        algorithm: HashAlgorithm.sha256,
        value: 'AAbb11',
      );
      expect(fileHash.verify('aabb11'), isTrue);
      expect(fileHash.verify('AABB11'), isTrue);
      expect(fileHash.verify('wrong'), isFalse);
    });
  });

  group('IntegrityConfig', () {
    test('isValid when contentHash is present', () {
      const config = IntegrityConfig(
        contentHash: ContentHash(
          algorithm: HashAlgorithm.sha256,
          value: 'abc',
        ),
      );
      expect(config.isValid, isTrue);
    });

    test('isValid when files are present', () {
      const config = IntegrityConfig(
        files: [
          FileHash(
            path: 'f.txt',
            algorithm: HashAlgorithm.sha256,
            value: 'abc',
          ),
        ],
      );
      expect(config.isValid, isTrue);
    });

    test('isValid is false when all empty', () {
      const config = IntegrityConfig();
      expect(config.isValid, isFalse);
    });
  });

  // ===========================================================================
  // 5. profile_section.dart edge cases
  // ===========================================================================
  group('ProfilesSection', () {
    test('roundtrip with empty profiles list', () {
      const section = ProfilesSection(profiles: []);
      final json = section.toJson();
      final restored = ProfilesSection.fromJson(json);

      expect(restored.profiles, isEmpty);
      expect(restored.isEmpty, isTrue);
      expect(restored.isNotEmpty, isFalse);
    });

    test('toJson always includes profiles key even when empty', () {
      const section = ProfilesSection();
      final json = section.toJson();
      expect(json.containsKey('profiles'), isTrue);
      expect(json['profiles'], isList);
      expect((json['profiles'] as List).isEmpty, isTrue);
    });

    test('getProfile returns null for non-existent id', () {
      const section = ProfilesSection(profiles: [
        ProfileDefinition(id: 'p1', name: 'Profile 1'),
      ]);
      expect(section.getProfile('p1'), isNotNull);
      expect(section.getProfile('p1')!.id, 'p1');
      expect(section.getProfile('nonexistent'), isNull);
    });

    test('isEmpty and isNotEmpty reflect profiles list', () {
      const empty = ProfilesSection();
      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);

      const nonEmpty = ProfilesSection(profiles: [
        ProfileDefinition(id: 'p1', name: 'P1'),
      ]);
      expect(nonEmpty.isEmpty, isFalse);
      expect(nonEmpty.isNotEmpty, isTrue);
    });

    test('copyWith replaces profiles', () {
      const original = ProfilesSection(profiles: [
        ProfileDefinition(id: 'p1', name: 'P1'),
      ]);
      final copied = original.copyWith(profiles: [
        const ProfileDefinition(id: 'p2', name: 'P2'),
      ]);
      expect(copied.profiles, hasLength(1));
      expect(copied.profiles[0].id, 'p2');
    });
  });

  // ===========================================================================
  // 6. binding.dart edge cases
  // ===========================================================================
  group('DataBinding', () {
    test('fromJson with all fields including optional ones', () {
      final binding = DataBinding.fromJson({
        'id': 'b1',
        'source': 'state.name',
        'target': 'ui.label',
        'direction': 'twoWay',
        'transform': 'toUpperCase()',
        'condition': 'isActive',
        'debounceMs': 300,
      });
      expect(binding.id, 'b1');
      expect(binding.source, 'state.name');
      expect(binding.target, 'ui.label');
      expect(binding.direction, BindingDirection.twoWay);
      expect(binding.transform, 'toUpperCase()');
      expect(binding.condition, 'isActive');
      expect(binding.debounceMs, 300);
    });

    test('toJson omits null optional fields', () {
      const binding = DataBinding(
        id: 'b1',
        source: 'a',
        target: 'b',
      );
      final json = binding.toJson();
      expect(json.containsKey('transform'), isFalse);
      expect(json.containsKey('condition'), isFalse);
      expect(json.containsKey('debounceMs'), isFalse);
    });

    test('toJson includes optional fields when set', () {
      const binding = DataBinding(
        id: 'b1',
        source: 'a',
        target: 'b',
        transform: 'x',
        condition: 'y',
        debounceMs: 100,
      );
      final json = binding.toJson();
      expect(json['transform'], 'x');
      expect(json['condition'], 'y');
      expect(json['debounceMs'], 100);
    });
  });

  group('BindingDirection', () {
    test('fromString with known values', () {
      expect(BindingDirection.fromString('oneWay'), BindingDirection.oneWay);
      expect(BindingDirection.fromString('twoWay'), BindingDirection.twoWay);
      expect(BindingDirection.fromString('reverse'), BindingDirection.reverse);
    });

    test('fromString with unknown value returns unknown', () {
      expect(
          BindingDirection.fromString('invalid'), BindingDirection.unknown);
    });
  });

  group('BindingSection', () {
    test('fromJson/toJson roundtrip with computed values', () {
      final json = {
        'schemaVersion': '1.0.0',
        'computed': {
          'fullName': {
            'expression': 'first + " " + last',
            'dependencies': ['first', 'last'],
            'cache': false,
          },
        },
      };
      final section = BindingSection.fromJson(json);
      expect(section.computed, hasLength(1));
      expect(section.computed['fullName']!.expression, 'first + " " + last');
      expect(section.computed['fullName']!.cache, isFalse);

      final output = section.toJson();
      expect(output.containsKey('computed'), isTrue);
    });
  });

  // ===========================================================================
  // 7. bundle.dart edge cases
  // ===========================================================================
  group('McpBundle', () {
    test('copyWith preserving nested sections', () {
      const assetSection = AssetSection(
        assets: [Asset(path: 'logo.png', type: AssetType.image)],
      );
      const profilesSection = ProfilesSection(
        profiles: [ProfileDefinition(id: 'p1', name: 'P1')],
      );
      const policiesSection = PolicySection(
        policies: [
          Policy(
            id: 'pol1',
            name: 'Test Policy',
            rules: [
              PolicyRule(
                id: 'r1',
                condition: AlwaysCondition(),
                action: PolicyAction.allow,
              ),
            ],
          ),
        ],
      );

      final bundle = McpBundle(
        manifest: const BundleManifest(
          id: 'test-bundle',
          name: 'Test',
          version: '1.0.0',
        ),
        assets: assetSection,
        profiles: profilesSection,
        policies: policiesSection,
        extensions: {'custom': 'data'},
      );

      // copyWith changing only manifest, preserving all sections
      final copied = bundle.copyWith(
        manifest: const BundleManifest(
          id: 'new-bundle',
          name: 'New',
          version: '2.0.0',
        ),
      );

      expect(copied.manifest.id, 'new-bundle');
      expect(copied.manifest.version, '2.0.0');
      // Nested sections preserved
      expect(copied.assets, isNotNull);
      expect(copied.assets!.assets, hasLength(1));
      expect(copied.assets!.assets[0].path, 'logo.png');
      expect(copied.profiles, isNotNull);
      expect(copied.profiles!.profiles, hasLength(1));
      expect(copied.profiles!.profiles[0].id, 'p1');
      expect(copied.policies, isNotNull);
      expect(copied.policies!.policies, hasLength(1));
      expect(copied.extensions, {'custom': 'data'});
    });

    test('hasContent returns true when any section present', () {
      final bundleWithAssets = McpBundle(
        manifest: const BundleManifest(
          id: 'b',
          name: 'B',
          version: '1.0.0',
        ),
        assets: const AssetSection(),
      );
      expect(bundleWithAssets.hasContent, isTrue);

      final emptyBundle = McpBundle(
        manifest: const BundleManifest(
          id: 'b',
          name: 'B',
          version: '1.0.0',
        ),
      );
      expect(emptyBundle.hasContent, isFalse);
    });

    test('presentSections lists all non-null sections', () {
      final bundle = McpBundle(
        manifest: const BundleManifest(
          id: 'b',
          name: 'B',
          version: '1.0.0',
        ),
        assets: const AssetSection(),
        profiles: const ProfilesSection(),
        extensions: {'x': 1},
      );
      final sections = bundle.presentSections;
      expect(sections, contains('assets'));
      expect(sections, contains('profiles'));
      expect(sections, contains('extensions'));
      expect(sections, isNot(contains('ui')));
      expect(sections, isNot(contains('flow')));
    });

    test('hasPolicies is true only when policies section has entries', () {
      final bundleNoPolicies = McpBundle(
        manifest: const BundleManifest(
          id: 'b',
          name: 'B',
          version: '1.0.0',
        ),
        policies: const PolicySection(),
      );
      expect(bundleNoPolicies.hasPolicies, isFalse);

      final bundleWithPolicies = McpBundle(
        manifest: const BundleManifest(
          id: 'b',
          name: 'B',
          version: '1.0.0',
        ),
        policies: const PolicySection(policies: [
          Policy(id: 'p1', name: 'P', rules: []),
        ]),
      );
      expect(bundleWithPolicies.hasPolicies, isTrue);
    });

    test('hasIntegrity is true only when integrity config is valid', () {
      final bundleNoIntegrity = McpBundle(
        manifest: const BundleManifest(
          id: 'b',
          name: 'B',
          version: '1.0.0',
        ),
        integrity: const IntegrityConfig(),
      );
      expect(bundleNoIntegrity.hasIntegrity, isFalse);

      final bundleWithIntegrity = McpBundle(
        manifest: const BundleManifest(
          id: 'b',
          name: 'B',
          version: '1.0.0',
        ),
        integrity: const IntegrityConfig(
          contentHash: ContentHash(
            algorithm: HashAlgorithm.sha256,
            value: 'abc',
          ),
        ),
      );
      expect(bundleWithIntegrity.hasIntegrity, isTrue);
    });
  });

  // ===========================================================================
  // 8. policy.dart edge cases
  // ===========================================================================
  group('Policy', () {
    test('default values from constructor', () {
      const policy = Policy(id: 'p1', name: 'Test', rules: []);
      expect(policy.priority, 50);
      expect(policy.enabled, isTrue);
      expect(policy.tags, isEmpty);
      expect(policy.description, isNull);
    });

    test('fromJson uses default priority 50 and enabled true', () {
      final policy = Policy.fromJson({
        'id': 'p1',
        'name': 'Test',
      });
      expect(policy.priority, 50);
      expect(policy.enabled, isTrue);
      expect(policy.rules, isEmpty);
      expect(policy.tags, isEmpty);
    });

    test('toJson includes priority and omits enabled when true', () {
      const policy = Policy(id: 'p1', name: 'Test', rules: []);
      final json = policy.toJson();
      expect(json['priority'], 50);
      expect(json.containsKey('enabled'), isFalse);
    });

    test('toJson includes enabled when false', () {
      const policy = Policy(
        id: 'p1',
        name: 'Test',
        rules: [],
        enabled: false,
      );
      final json = policy.toJson();
      expect(json['enabled'], isFalse);
    });

    test('toJson includes tags when non-empty', () {
      const policy = Policy(
        id: 'p1',
        name: 'Test',
        rules: [],
        tags: ['security', 'validation'],
      );
      final json = policy.toJson();
      expect(json['tags'], ['security', 'validation']);
    });
  });

  group('PolicySection', () {
    test('sortedByPriority returns highest priority first', () {
      const section = PolicySection(policies: [
        Policy(id: 'low', name: 'Low', rules: [], priority: 10),
        Policy(id: 'high', name: 'High', rules: [], priority: 90),
        Policy(id: 'mid', name: 'Mid', rules: [], priority: 50),
      ]);
      final sorted = section.sortedByPriority;
      expect(sorted[0].id, 'high');
      expect(sorted[1].id, 'mid');
      expect(sorted[2].id, 'low');
    });

    test('findById returns matching policy or null', () {
      const section = PolicySection(policies: [
        Policy(id: 'p1', name: 'P1', rules: []),
        Policy(id: 'p2', name: 'P2', rules: []),
      ]);
      expect(section.findById('p1'), isNotNull);
      expect(section.findById('p1')!.name, 'P1');
      expect(section.findById('nonexistent'), isNull);
    });

    test('toJson omits policies when empty', () {
      const section = PolicySection();
      final json = section.toJson();
      expect(json.containsKey('policies'), isFalse);
    });
  });

  group('PolicyAction', () {
    test('fromString with known values', () {
      expect(PolicyAction.fromString('allow'), PolicyAction.allow);
      expect(PolicyAction.fromString('deny'), PolicyAction.deny);
      expect(PolicyAction.fromString('warn'), PolicyAction.warn);
      expect(PolicyAction.fromString('require_approval'),
          PolicyAction.requireApproval);
      expect(PolicyAction.fromString('requireapproval'),
          PolicyAction.requireApproval);
      expect(PolicyAction.fromString('log'), PolicyAction.log);
    });

    test('fromString with unknown value returns unknown', () {
      expect(PolicyAction.fromString('invalid'), PolicyAction.unknown);
    });

    test('fromString is case insensitive', () {
      expect(PolicyAction.fromString('ALLOW'), PolicyAction.allow);
      expect(PolicyAction.fromString('Deny'), PolicyAction.deny);
      expect(PolicyAction.fromString('WARN'), PolicyAction.warn);
    });
  });

  group('PolicyEvaluationResult', () {
    test('pass factory creates passing result', () {
      final result = PolicyEvaluationResult.pass();
      expect(result.passed, isTrue);
      expect(result.action, PolicyAction.allow);
      expect(result.triggeredRules, isEmpty);
      expect(result.messages, isEmpty);
    });

    test('fail factory creates failing result', () {
      final result = PolicyEvaluationResult.fail(
        action: PolicyAction.deny,
        messages: ['Access denied'],
        triggeredRules: [
          const TriggeredRule(
            policyId: 'p1',
            ruleId: 'r1',
            action: PolicyAction.deny,
            message: 'Blocked',
          ),
        ],
      );
      expect(result.passed, isFalse);
      expect(result.action, PolicyAction.deny);
      expect(result.messages, ['Access denied']);
      expect(result.triggeredRules, hasLength(1));
    });
  });

  // ===========================================================================
  // Additional helpers/utilities coverage
  // ===========================================================================
  group('_parseStringList (via manifest fromJson)', () {
    test('handles non-list non-null value gracefully by returning empty', () {
      // The _parseStringList function returns [] for non-list values.
      // We exercise this via capabilities field with a non-list value.
      final manifest = BundleManifest.fromJson({
        'id': 'test',
        'name': 'Test',
        'version': '1.0.0',
        'capabilities': 'not-a-list',
      });
      expect(manifest.capabilities, isEmpty);
    });

    test('handles integer list items by converting toString', () {
      final manifest = BundleManifest.fromJson({
        'id': 'test',
        'name': 'Test',
        'version': '1.0.0',
        'tags': [1, 2.5, true],
      });
      expect(manifest.tags, equals(['1', '2.5', 'true']));
    });
  });

  group('HashAlgorithm', () {
    test('fromString with various aliases', () {
      expect(HashAlgorithm.fromString('sha256'), HashAlgorithm.sha256);
      expect(HashAlgorithm.fromString('sha-256'), HashAlgorithm.sha256);
      expect(HashAlgorithm.fromString('SHA256'), HashAlgorithm.sha256);
      expect(HashAlgorithm.fromString('sha384'), HashAlgorithm.sha384);
      expect(HashAlgorithm.fromString('sha-384'), HashAlgorithm.sha384);
      expect(HashAlgorithm.fromString('sha512'), HashAlgorithm.sha512);
      expect(HashAlgorithm.fromString('sha-512'), HashAlgorithm.sha512);
      expect(HashAlgorithm.fromString('md5'), HashAlgorithm.md5);
    });

    test('fromString with null returns unknown', () {
      expect(HashAlgorithm.fromString(null), HashAlgorithm.unknown);
    });

    test('fromString with unknown value returns unknown', () {
      expect(HashAlgorithm.fromString('ripemd'), HashAlgorithm.unknown);
    });
  });

  group('ContentScope', () {
    test('fromString with various formats', () {
      expect(ContentScope.fromString('canonical_json'),
          ContentScope.canonicalJson);
      expect(ContentScope.fromString('canonicaljson'),
          ContentScope.canonicalJson);
      expect(ContentScope.fromString('content_sections'),
          ContentScope.contentSections);
      expect(ContentScope.fromString('contentsections'),
          ContentScope.contentSections);
      expect(ContentScope.fromString('all_files'), ContentScope.allFiles);
      expect(ContentScope.fromString('allfiles'), ContentScope.allFiles);
      expect(ContentScope.fromString('custom'), ContentScope.custom);
    });

    test('fromString with null returns canonicalJson', () {
      expect(ContentScope.fromString(null), ContentScope.canonicalJson);
    });

    test('fromString with unknown returns canonicalJson', () {
      expect(ContentScope.fromString('other'), ContentScope.canonicalJson);
    });
  });
}
