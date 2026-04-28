// Tests for FileStorageAdapter and BundleRepository.file factory.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('file_storage_adapter_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('FileStorageAdapter', () {
    group('constructor', () {
      test('creates adapter without basePath', () {
        const adapter = FileStorageAdapter();
        expect(adapter.basePath, isNull);
      });

      test('creates adapter with basePath', () {
        const adapter = FileStorageAdapter('/some/path');
        expect(adapter.basePath, equals('/some/path'));
      });
    });

    group('readBundle', () {
      test('reads a JSON file and returns Map', () async {
        final adapter = FileStorageAdapter();
        final file = File('${tempDir.path}/manifest.json');
        file.writeAsStringSync(jsonEncode({'manifest': {'id': 'test'}}));

        final result = await adapter.readBundle(Uri.file(file.path));
        expect(result, isA<Map<String, dynamic>>());
        expect(result['manifest'], isA<Map<String, dynamic>>());
        expect((result['manifest'] as Map<String, dynamic>)['id'], equals('test'));
      });

      test('reads from directory bundle (dir/manifest.json)', () async {
        final adapter = FileStorageAdapter();
        final bundleDir = Directory('${tempDir.path}/mybundle');
        bundleDir.createSync();
        File('${bundleDir.path}/manifest.json')
            .writeAsStringSync(jsonEncode({'name': 'dir_bundle'}));

        final result = await adapter.readBundle(Uri.file(bundleDir.path));
        expect(result['name'], equals('dir_bundle'));
      });

      test('reads from .mbd directory', () async {
        final adapter = FileStorageAdapter();
        final mcpDir = Directory('${tempDir.path}/test.mbd');
        mcpDir.createSync();
        File('${mcpDir.path}/manifest.json')
            .writeAsStringSync(jsonEncode({'name': 'mcp_bundle'}));

        // Pass URI without the .mbd suffix
        final result = await adapter.readBundle(
          Uri.file('${tempDir.path}/test'),
        );
        expect(result['name'], equals('mcp_bundle'));
      });

      test('throws BundleNotFoundException for non-existent path', () async {
        final adapter = FileStorageAdapter();
        expect(
          () => adapter.readBundle(
            Uri.file('${tempDir.path}/nonexistent.json'),
          ),
          throwsA(isA<BundleNotFoundException>()),
        );
      });

      test('throws BundleParseException for invalid JSON', () async {
        final adapter = FileStorageAdapter();
        final file = File('${tempDir.path}/bad.json');
        file.writeAsStringSync('not valid json {{{');

        expect(
          () => adapter.readBundle(Uri.file(file.path)),
          throwsA(isA<BundleParseException>()),
        );
      });

      test('throws BundleParseException for JSON that is not a Map', () async {
        final adapter = FileStorageAdapter();
        final file = File('${tempDir.path}/array.json');
        file.writeAsStringSync(jsonEncode([1, 2, 3]));

        expect(
          () => adapter.readBundle(Uri.file(file.path)),
          throwsA(isA<BundleParseException>()),
        );
      });
    });

    group('writeBundle', () {
      test('writes JSON file and creates parent dirs', () async {
        final adapter = FileStorageAdapter();
        final filePath = '${tempDir.path}/sub/dir/manifest.json';

        await adapter.writeBundle(
          Uri.file(filePath),
          {'manifest': {'id': 'written'}},
        );

        final file = File(filePath);
        expect(file.existsSync(), isTrue);
        final content = jsonDecode(file.readAsStringSync());
        expect((content as Map)['manifest']['id'], equals('written'));
      });
    });

    group('readAsset', () {
      test('reads binary file', () async {
        final adapter = FileStorageAdapter();
        final file = File('${tempDir.path}/asset.bin');
        final data = Uint8List.fromList([0x01, 0x02, 0x03, 0xFF]);
        file.writeAsBytesSync(data);

        final result = await adapter.readAsset(Uri.file(file.path));
        expect(result, equals(data));
      });

      test('throws AssetNotFoundException for missing file', () async {
        final adapter = FileStorageAdapter();
        expect(
          () => adapter.readAsset(
            Uri.file('${tempDir.path}/nonexistent.bin'),
          ),
          throwsA(isA<AssetNotFoundException>()),
        );
      });
    });

    group('writeAsset', () {
      test('writes binary file', () async {
        final adapter = FileStorageAdapter();
        final filePath = '${tempDir.path}/subdir/asset.bin';
        final data = Uint8List.fromList([0xAA, 0xBB, 0xCC]);

        await adapter.writeAsset(Uri.file(filePath), data);

        final file = File(filePath);
        expect(file.existsSync(), isTrue);
        expect(file.readAsBytesSync(), equals(data));
      });
    });

    group('exists', () {
      test('returns true for existing file', () async {
        final adapter = FileStorageAdapter();
        final file = File('${tempDir.path}/exists.json');
        file.writeAsStringSync('{}');

        final result = await adapter.exists(Uri.file(file.path));
        expect(result, isTrue);
      });

      test('returns true for existing directory', () async {
        final adapter = FileStorageAdapter();
        final dir = Directory('${tempDir.path}/existsdir');
        dir.createSync();

        final result = await adapter.exists(Uri.file(dir.path));
        expect(result, isTrue);
      });

      test('returns true for existing .mbd directory', () async {
        final adapter = FileStorageAdapter();
        final mcpDir = Directory('${tempDir.path}/mybundle.mbd');
        mcpDir.createSync();

        // Check for the path without .mbd suffix
        final result = await adapter.exists(
          Uri.file('${tempDir.path}/mybundle'),
        );
        expect(result, isTrue);
      });

      test('returns false for non-existent path', () async {
        final adapter = FileStorageAdapter();
        final result = await adapter.exists(
          Uri.file('${tempDir.path}/nope'),
        );
        expect(result, isFalse);
      });
    });

    group('delete', () {
      test('deletes a file', () async {
        final adapter = FileStorageAdapter();
        final file = File('${tempDir.path}/todelete.json');
        file.writeAsStringSync('{}');
        expect(file.existsSync(), isTrue);

        await adapter.delete(Uri.file(file.path));
        expect(file.existsSync(), isFalse);
      });

      test('deletes a directory recursively', () async {
        final adapter = FileStorageAdapter();
        final dir = Directory('${tempDir.path}/todeldir');
        dir.createSync();
        File('${dir.path}/inner.txt').writeAsStringSync('data');
        expect(dir.existsSync(), isTrue);

        await adapter.delete(Uri.file(dir.path));
        expect(dir.existsSync(), isFalse);
      });

      test('deletes .mbd directory', () async {
        final adapter = FileStorageAdapter();
        final mcpDir = Directory('${tempDir.path}/del.mbd');
        mcpDir.createSync();
        File('${mcpDir.path}/manifest.json').writeAsStringSync('{}');

        // Delete using path without .mbd suffix
        await adapter.delete(Uri.file('${tempDir.path}/del'));
        expect(mcpDir.existsSync(), isFalse);
      });

      test('silent for non-existent path', () async {
        final adapter = FileStorageAdapter();
        // Should not throw
        await adapter.delete(
          Uri.file('${tempDir.path}/nonexistent_delete'),
        );
      });
    });

    group('list', () {
      test('lists JSON and .mbd items in directory', () async {
        final adapter = FileStorageAdapter();

        // Create some files
        File('${tempDir.path}/a.json').writeAsStringSync('{}');
        File('${tempDir.path}/b.json').writeAsStringSync('{}');
        File('${tempDir.path}/c.txt').writeAsStringSync('not a bundle');
        Directory('${tempDir.path}/d.mbd').createSync();
        Directory('${tempDir.path}/e_dir').createSync();

        final result = await adapter.list(Uri.file(tempDir.path));
        final paths = result.map((u) => u.toFilePath()).toList();

        expect(paths.where((p) => p.endsWith('a.json')), hasLength(1));
        expect(paths.where((p) => p.endsWith('b.json')), hasLength(1));
        expect(paths.where((p) => p.endsWith('d.mbd')), hasLength(1));
        // Should not include .txt files or plain directories
        expect(paths.where((p) => p.endsWith('c.txt')), isEmpty);
        expect(paths.where((p) => p.endsWith('e_dir')), isEmpty);
      });

      test('empty directory returns empty list', () async {
        final adapter = FileStorageAdapter();
        final emptyDir = Directory('${tempDir.path}/empty');
        emptyDir.createSync();

        final result = await adapter.list(Uri.file(emptyDir.path));
        expect(result, isEmpty);
      });

      test('non-existent directory returns empty list', () async {
        final adapter = FileStorageAdapter();
        final result = await adapter.list(
          Uri.file('${tempDir.path}/nonexistent_dir'),
        );
        expect(result, isEmpty);
      });
    });

    group('watch', () {
      test('returns null for non-existent directory', () {
        final adapter = FileStorageAdapter();
        final result = adapter.watch(
          Uri.file('${tempDir.path}/nonexistent_watch'),
        );
        expect(result, isNull);
      });

      test('returns stream for existing directory', () {
        final adapter = FileStorageAdapter();
        final result = adapter.watch(Uri.file(tempDir.path));
        expect(result, isNotNull);
        expect(result, isA<Stream<BundleChangeEvent>>());
      });
    });

    group('_resolvePath', () {
      test('resolves file:// scheme URI', () async {
        final adapter = FileStorageAdapter();
        final file = File('${tempDir.path}/fileuri.json');
        file.writeAsStringSync(jsonEncode({'test': true}));

        final result = await adapter.readBundle(
          Uri.parse('file://${file.path}'),
        );
        expect(result['test'], isTrue);
      });

      test('throws BundleLoadException for unsupported scheme', () {
        final adapter = FileStorageAdapter();
        expect(
          () => adapter.readBundle(Uri.parse('ftp://example.com/manifest.json')),
          throwsA(isA<BundleLoadException>()),
        );
      });

      test('with basePath resolves relative paths', () async {
        final adapter = FileStorageAdapter(tempDir.path);
        final file = File('${tempDir.path}/relative.json');
        file.writeAsStringSync(jsonEncode({'relative': true}));

        final result = await adapter.readBundle(Uri.parse('relative.json'));
        expect(result['relative'], isTrue);
      });
    });
  });

  group('BundleRepository.file', () {
    test('creates repository with FileStorageAdapter', () {
      final repo = BundleRepository.file(tempDir.path);
      expect(repo, isA<BundleRepository>());
      expect(repo.storage, isA<FileStorageAdapter>());
    });

    test('creates repository without basePath', () {
      final repo = BundleRepository.file();
      expect(repo, isA<BundleRepository>());
      expect(repo.storage, isA<FileStorageAdapter>());
    });
  });
}
