import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  group('Asset', () {
    test('creates asset with required fields', () {
      const asset = Asset(
        path: 'images/logo.png',
        type: AssetType.image,
      );

      expect(asset.path, equals('images/logo.png'));
      expect(asset.type, equals(AssetType.image));
      expect(asset.encoding, equals('utf-8'));
    });

    test('creates asset with all fields', () {
      const asset = Asset(
        id: 'logo',
        path: 'images/logo.png',
        type: AssetType.image,
        name: 'Logo',
        description: 'Application logo',
        mimeType: 'image/png',
        encoding: 'base64',
        content: 'base64data',
        hash: 'sha256:abc',
        size: 1024,
        metadata: {'author': 'designer'},
      );

      expect(asset.id, equals('logo'));
      expect(asset.name, equals('Logo'));
      expect(asset.mimeType, equals('image/png'));
      expect(asset.hasInlineContent, isTrue);
      expect(asset.hasExternalContent, isFalse);
    });

    test('hasInlineContent and hasExternalContent', () {
      const inlineAsset = Asset(
        path: 'data.json',
        type: AssetType.json,
        content: '{"key": "value"}',
      );

      const externalAsset = Asset(
        path: 'large.bin',
        type: AssetType.binary,
        contentRef: 'https://example.com/large.bin',
      );

      expect(inlineAsset.hasInlineContent, isTrue);
      expect(inlineAsset.hasExternalContent, isFalse);
      expect(externalAsset.hasInlineContent, isFalse);
      expect(externalAsset.hasExternalContent, isTrue);
    });

    test('serializes and deserializes correctly', () {
      const original = Asset(
        id: 'test-asset',
        path: 'test/file.txt',
        type: AssetType.text,
        name: 'Test File',
        content: 'Hello World',
      );

      final json = original.toJson();
      final restored = Asset.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.path, equals(original.path));
      expect(restored.type, equals(original.type));
      expect(restored.name, equals(original.name));
      expect(restored.content, equals(original.content));
    });
  });

  group('AssetType', () {
    test('fromString parses correctly', () {
      expect(AssetType.fromString('image'), equals(AssetType.image));
      expect(AssetType.fromString('icon'), equals(AssetType.icon));
      expect(AssetType.fromString('font'), equals(AssetType.font));
      expect(AssetType.fromString('audio'), equals(AssetType.audio));
      expect(AssetType.fromString('video'), equals(AssetType.video));
      expect(AssetType.fromString('json'), equals(AssetType.json));
      expect(AssetType.fromString('text'), equals(AssetType.text));
      expect(AssetType.fromString('binary'), equals(AssetType.binary));
    });

    test('fromString returns unknown for invalid', () {
      expect(AssetType.fromString('invalid'), equals(AssetType.unknown));
    });

    test('commonMimeTypes returns correct values', () {
      expect(AssetType.image.commonMimeTypes, contains('image/png'));
      expect(AssetType.json.commonMimeTypes, contains('application/json'));
      expect(AssetType.font.commonMimeTypes, contains('font/woff2'));
    });
  });

  group('AssetSection', () {
    test('creates section with defaults', () {
      const section = AssetSection();

      expect(section.schemaVersion, equals('1.0.0'));
      expect(section.assets, isEmpty);
      expect(section.directories, isEmpty);
    });

    test('creates section with assets', () {
      const section = AssetSection(
        assets: [
          Asset(path: 'logo.png', type: AssetType.image),
          Asset(path: 'config.json', type: AssetType.json),
        ],
      );

      expect(section.assets.length, equals(2));
    });

    test('getAsset finds asset by path', () {
      const section = AssetSection(
        assets: [
          Asset(path: 'images/logo.png', type: AssetType.image),
          Asset(path: 'data/config.json', type: AssetType.json),
        ],
      );

      expect(section.getAsset('images/logo.png'), isNotNull);
      expect(section.getAsset('images/logo.png')!.type, equals(AssetType.image));
      expect(section.getAsset('not/found.txt'), isNull);
    });

    test('getAssetsByType filters correctly', () {
      const section = AssetSection(
        assets: [
          Asset(path: 'a.png', type: AssetType.image),
          Asset(path: 'b.png', type: AssetType.image),
          Asset(path: 'c.json', type: AssetType.json),
        ],
      );

      final images = section.getAssetsByType(AssetType.image);
      expect(images.length, equals(2));

      final jsonAssets = section.getAssetsByType(AssetType.json);
      expect(jsonAssets.length, equals(1));
    });

    test('serializes and deserializes correctly', () {
      const original = AssetSection(
        schemaVersion: '2.0.0',
        assets: [
          Asset(path: 'test.txt', type: AssetType.text),
        ],
      );

      final json = original.toJson();
      final restored = AssetSection.fromJson(json);

      expect(restored.schemaVersion, equals(original.schemaVersion));
      expect(restored.assets.length, equals(1));
    });
  });

  group('AssetDirectory', () {
    test('creates directory with required fields', () {
      const dir = AssetDirectory(path: 'assets/images');

      expect(dir.path, equals('assets/images'));
      expect(dir.pattern, equals('*'));
      expect(dir.type, equals(AssetType.file));
      expect(dir.recursive, isFalse);
    });

    test('creates directory with all fields', () {
      const dir = AssetDirectory(
        path: 'assets/icons',
        pattern: '*.svg',
        type: AssetType.icon,
        recursive: true,
      );

      expect(dir.pattern, equals('*.svg'));
      expect(dir.type, equals(AssetType.icon));
      expect(dir.recursive, isTrue);
    });

    test('serializes and deserializes correctly', () {
      const original = AssetDirectory(
        path: 'fonts',
        pattern: '*.ttf',
        type: AssetType.font,
      );

      final json = original.toJson();
      final restored = AssetDirectory.fromJson(json);

      expect(restored.path, equals(original.path));
      expect(restored.pattern, equals(original.pattern));
      expect(restored.type, equals(original.type));
    });
  });

  group('AssetBundle', () {
    test('creates bundle with required fields', () {
      const bundle = AssetBundle(
        id: 'icons',
        name: 'Icon Bundle',
      );

      expect(bundle.id, equals('icons'));
      expect(bundle.name, equals('Icon Bundle'));
      expect(bundle.assets, isEmpty);
      expect(bundle.loadStrategy, equals(LoadStrategy.lazy));
    });

    test('creates bundle with all fields', () {
      const bundle = AssetBundle(
        id: 'main',
        name: 'Main Assets',
        assets: ['logo.png', 'splash.png'],
        loadStrategy: LoadStrategy.eager,
      );

      expect(bundle.assets.length, equals(2));
      expect(bundle.loadStrategy, equals(LoadStrategy.eager));
    });

    test('serializes and deserializes correctly', () {
      const original = AssetBundle(
        id: 'test',
        name: 'Test Bundle',
        assets: ['a.png', 'b.png'],
        loadStrategy: LoadStrategy.preload,
      );

      final json = original.toJson();
      final restored = AssetBundle.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.assets, equals(original.assets));
      expect(restored.loadStrategy, equals(original.loadStrategy));
    });
  });

  group('LoadStrategy', () {
    test('fromString parses correctly', () {
      expect(LoadStrategy.fromString('eager'), equals(LoadStrategy.eager));
      expect(LoadStrategy.fromString('lazy'), equals(LoadStrategy.lazy));
      expect(LoadStrategy.fromString('preload'), equals(LoadStrategy.preload));
    });

    test('fromString returns unknown for invalid', () {
      expect(LoadStrategy.fromString('invalid'), equals(LoadStrategy.unknown));
    });
  });
}
