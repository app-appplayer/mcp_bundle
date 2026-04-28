import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

/// Helper to build a minimal valid bundle JSON map.
Map<String, dynamic> _minimalBundleJson({
  String id = 'test-bundle',
  String name = 'Test Bundle',
  String version = '1.0.0',
}) {
  return {
    'schemaVersion': '1.0.0',
    'manifest': {
      'id': id,
      'name': name,
      'version': version,
    },
  };
}

void main() {
  late MemoryStorageAdapter storage;
  late BundleRepository repo;

  setUp(() {
    storage = MemoryStorageAdapter();
    repo = BundleRepository(storage);
  });

  tearDown(() {
    storage.dispose();
  });

  // ==================== Factory Constructors ====================

  group('BundleRepository - constructors', () {
    test('creates repository with given storage', () {
      expect(repo.storage, same(storage));
    });

    test('memory factory creates repository backed by MemoryStorageAdapter', () {
      final memRepo = BundleRepository.memory();
      expect(memRepo.storage, isA<MemoryStorageAdapter>());
    });
  });

  // ==================== Load ====================

  group('BundleRepository - load', () {
    test('loads and parses a valid bundle', () async {
      final uri = Uri.parse('bundle://test.json');
      storage.seed(uri.toString(), _minimalBundleJson());

      final bundle = await repo.load(uri);
      expect(bundle, isA<McpBundle>());
      expect(bundle.manifest.id, equals('test-bundle'));
      expect(bundle.manifest.name, equals('Test Bundle'));
    });

    test('loads bundle with lenient options', () async {
      final uri = Uri.parse('bundle://lenient.json');
      // Bundle without schemaVersion - would fail in strict mode
      storage.seed(uri.toString(), {
        'manifest': {
          'id': 'lenient',
          'name': 'Lenient Bundle',
          'version': '1.0.0',
        },
      });

      final bundle = await repo.load(
        uri,
        options: const McpLoaderOptions.lenient(),
      );
      expect(bundle.manifest.id, equals('lenient'));
    });

    test('throws when bundle does not exist', () async {
      final uri = Uri.parse('bundle://nonexistent.json');
      expect(
        () => repo.load(uri),
        throwsA(isA<BundleNotFoundException>()),
      );
    });

    test('throws for invalid bundle JSON (strict mode)', () async {
      final uri = Uri.parse('bundle://invalid.json');
      // Missing manifest entirely
      storage.seed(uri.toString(), {'random': 'data'});

      expect(
        () => repo.load(uri),
        throwsA(isA<BundleLoadException>()),
      );
    });
  });

  // ==================== Save ====================

  group('BundleRepository - save', () {
    test('saves bundle and reads it back', () async {
      final uri = Uri.parse('bundle://save.json');
      const bundle = McpBundle(
        manifest: BundleManifest(
          id: 'save-test',
          name: 'Save Test',
          version: '2.0.0',
        ),
      );

      await repo.save(bundle, uri);

      final loaded = await repo.load(
        uri,
        options: const McpLoaderOptions.lenient(),
      );
      expect(loaded.manifest.id, equals('save-test'));
    });

    test('save overwrites existing bundle', () async {
      final uri = Uri.parse('bundle://overwrite.json');

      const bundle1 = McpBundle(
        manifest: BundleManifest(
          id: 'v1',
          name: 'Version 1',
          version: '1.0.0',
        ),
      );
      const bundle2 = McpBundle(
        manifest: BundleManifest(
          id: 'v2',
          name: 'Version 2',
          version: '2.0.0',
        ),
      );

      await repo.save(bundle1, uri);
      await repo.save(bundle2, uri);

      final loaded = await repo.load(
        uri,
        options: const McpLoaderOptions.lenient(),
      );
      expect(loaded.manifest.id, equals('v2'));
    });
  });

  // ==================== Exists ====================

  group('BundleRepository - exists', () {
    test('returns true for existing bundle', () async {
      final uri = Uri.parse('bundle://exists.json');
      storage.seed(uri.toString(), _minimalBundleJson());
      expect(await repo.exists(uri), isTrue);
    });

    test('returns false for non-existing bundle', () async {
      expect(
        await repo.exists(Uri.parse('bundle://nope.json')),
        isFalse,
      );
    });
  });

  // ==================== Delete ====================

  group('BundleRepository - delete', () {
    test('deletes an existing bundle', () async {
      final uri = Uri.parse('bundle://del.json');
      storage.seed(uri.toString(), _minimalBundleJson());

      await repo.delete(uri);
      expect(await repo.exists(uri), isFalse);
    });

    test('delete on non-existing URI does not throw', () async {
      // Should complete without error
      await repo.delete(Uri.parse('bundle://nothing.json'));
    });
  });

  // ==================== List ====================

  group('BundleRepository - list', () {
    test('lists bundles under a directory prefix', () async {
      storage.seed('bundle://dir/a.json', _minimalBundleJson(id: 'a'));
      storage.seed('bundle://dir/b.json', _minimalBundleJson(id: 'b'));
      storage.seed('bundle://other/c.json', _minimalBundleJson(id: 'c'));

      final results = await repo.list(Uri.parse('bundle://dir/'));
      expect(results, hasLength(2));
    });

    test('returns empty list when no bundles match', () async {
      final results = await repo.list(Uri.parse('bundle://empty/'));
      expect(results, isEmpty);
    });
  });

  // ==================== LoadAll ====================

  group('BundleRepository - loadAll', () {
    test('loads all bundles in a directory', () async {
      storage.seed(
        'bundle://all/a.json',
        _minimalBundleJson(id: 'a', name: 'A'),
      );
      storage.seed(
        'bundle://all/b.json',
        _minimalBundleJson(id: 'b', name: 'B'),
      );

      final results = await repo.loadAll(Uri.parse('bundle://all/'));
      expect(results, hasLength(2));
    });

    test('skips bundles that fail to parse', () async {
      storage.seed(
        'bundle://mixed/good.json',
        _minimalBundleJson(id: 'good'),
      );
      // Invalid bundle: missing manifest (strict mode will fail)
      storage.seed(
        'bundle://mixed/bad.json',
        {'not': 'a bundle'},
      );

      final results = await repo.loadAll(Uri.parse('bundle://mixed/'));
      // Only the valid bundle should be loaded
      expect(results, hasLength(1));
      expect(
        results.values.first.manifest.id,
        equals('good'),
      );
    });

    test('returns empty map when directory is empty', () async {
      final results = await repo.loadAll(Uri.parse('bundle://empty/'));
      expect(results, isEmpty);
    });
  });

  // ==================== Watch ====================

  group('BundleRepository - watch', () {
    test('returns stream from underlying storage', () {
      final stream = repo.watch(Uri.parse('bundle://any'));
      expect(stream, isNotNull);
    });
  });

  // ==================== Asset Operations ====================

  group('BundleRepository - asset operations', () {
    test('reads an asset through the repository', () async {
      final uri = Uri.parse('asset://image.png');
      final data = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
      storage.seedAsset(uri.toString(), data);

      final result = await repo.readAsset(uri);
      expect(result, equals(data));
    });

    test('writes an asset through the repository', () async {
      final uri = Uri.parse('asset://new.dat');
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);

      await repo.writeAsset(uri, data);

      final result = await repo.readAsset(uri);
      expect(result, equals(data));
    });
  });
}
