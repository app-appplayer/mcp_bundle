/// Install → list → load against a [BundleInstallStore] that is not the
/// filesystem.
///
/// The point of these tests is not that an in-memory store works — it is
/// that installing and reading back are expressible without `dart:io` at
/// all. A host with no filesystem (the browser) plugs its own store in
/// here; if any of this still needed a path, that host could not.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  const runtime = RuntimeDescriptor(version: '1.0.0');
  // These samples carry no `integrity` block — the subject here is where
  // the bytes land, not the verification pipeline (covered by
  // install_lifecycle_test).
  const lenient = InstallPolicy(requireIntegrity: false);

  /// Pack a minimal but valid `.mcpb` in memory.
  Uint8List packSample({
    String id = 'com.example.app',
    String version = '1.0.0',
    String appTitle = 'Sample',
    Map<String, String> extraFiles = const {},
  }) {
    final bundle = <String, dynamic>{
      'schemaVersion': '1.0.0',
      'manifest': {
        'id': id,
        'name': 'Sample',
        'version': version,
        'schemaVersion': '1.0.0',
        'type': 'application',
        'entryPoint': 'ui.main',
      },
    };
    final archive = Archive();
    void add(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    add('manifest.json', jsonEncode(bundle));
    add('ui/app.json', jsonEncode({'title': appTitle}));
    extraFiles.forEach(add);
    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  group('install into a store', () {
    test('installs, lists and reads back with no filesystem', () async {
      final store = MemoryBundleInstallStore();

      final installed = await McpBundleInstaller.installBytes(
        packSample(),
        store: store,
        runtime: runtime,
        policy: lenient,
      );

      expect(installed.id, 'com.example.app');
      expect(installed.version, '1.0.0');
      expect(installed.files, isNotNull);

      final listed = await McpBundleInstaller.listFrom(store);
      expect(listed.map((b) => b.id), ['com.example.app']);
      expect(listed.single.installedAt, isNotNull);

      // The whole reason for the port: the installed bundle is loadable
      // and its reserved folders are readable from the store alone.
      final files = await store.openInstalled('com.example.app');
      final bundle = await McpBundleLoader.loadStore(files!);
      expect(bundle.manifest.id, 'com.example.app');
      expect(bundle.directory, isNull);
      expect(jsonDecode(await bundle.uiResources.read('app.json')),
          {'title': 'Sample'});
    });

    test('sidecar survives the round trip', () async {
      final store = MemoryBundleInstallStore();
      await McpBundleInstaller.installBytes(
        packSample(),
        store: store,
        runtime: runtime,
        policy: lenient,
      );

      final files = (await store.openInstalled('com.example.app'))!;
      final sidecar = await files.read('.install.json');
      expect(sidecar, isNotNull);
      final json = jsonDecode(utf8.decode(sidecar!)) as Map<String, dynamic>;
      expect(json['id'], 'com.example.app');
      expect(json['sourceDigest'], isNotEmpty);
    });

    test('replace swaps the content, not just the manifest', () async {
      final store = MemoryBundleInstallStore();
      await McpBundleInstaller.installBytes(
        packSample(appTitle: 'First', extraFiles: {'ui/only-in-first.json': '1'}),
        store: store,
        runtime: runtime,
        policy: lenient,
      );
      await McpBundleInstaller.installBytes(
        packSample(version: '2.0.0', appTitle: 'Second'),
        store: store,
        runtime: runtime,
        policy: const InstallPolicy(
          requireIntegrity: false,
          onConflict: InstallConflictPolicy.replace,
        ),
      );

      final files = (await store.openInstalled('com.example.app'))!;
      final bundle = await McpBundleLoader.loadStore(files);
      expect(bundle.manifest.version, '2.0.0');
      expect(jsonDecode(await bundle.uiResources.read('app.json')),
          {'title': 'Second'});
      // A replace that merely overwrote the files it happened to have
      // would leave the old copy's extra file behind, and the bundle
      // would be a blend of two versions.
      expect(await files.exists('ui/only-in-first.json'), isFalse);
    });

    test('failIfExists and skipIfExists see the store registry', () async {
      final store = MemoryBundleInstallStore();
      await McpBundleInstaller.installBytes(
        packSample(),
        store: store,
        runtime: runtime,
        policy: lenient,
      );

      await expectLater(
        McpBundleInstaller.installBytes(
          packSample(version: '2.0.0'),
          store: store,
          runtime: runtime,
          policy: const InstallPolicy(
            requireIntegrity: false,
            onConflict: InstallConflictPolicy.failIfExists,
          ),
        ),
        throwsA(isA<BundleAlreadyInstalledException>()),
      );

      final skipped = await McpBundleInstaller.installBytes(
        packSample(version: '2.0.0'),
        store: store,
        runtime: runtime,
        policy: const InstallPolicy(
          requireIntegrity: false,
          onConflict: InstallConflictPolicy.skipIfExists,
        ),
      );
      expect(skipped.version, '1.0.0');
    });

    test('uninstallFrom empties the registry', () async {
      final store = MemoryBundleInstallStore();
      await McpBundleInstaller.installBytes(
        packSample(),
        store: store,
        runtime: runtime,
        policy: lenient,
      );
      await McpBundleInstaller.uninstallFrom(store, 'com.example.app');

      expect(await McpBundleInstaller.listFrom(store), isEmpty);
      expect(await store.openInstalled('com.example.app'), isNull);
    });

    test('a rejected archive installs nothing', () async {
      final store = MemoryBundleInstallStore();

      await expectLater(
        McpBundleInstaller.installBytes(
          Uint8List.fromList([1, 2, 3, 4]),
          store: store,
          runtime: runtime,
          policy: lenient,
        ),
        throwsA(isA<BundleFormatException>()),
      );
      expect(await McpBundleInstaller.listFrom(store), isEmpty);
    });

    test('a traversal entry is rejected and leaves nothing staged', () async {
      final store = MemoryBundleInstallStore();

      await expectLater(
        McpBundleInstaller.installBytes(
          packSample(extraFiles: {'../escape.json': 'no'}),
          store: store,
          runtime: runtime,
          policy: lenient,
        ),
        throwsA(isA<BundleFormatException>()),
      );
      expect(await McpBundleInstaller.listFrom(store), isEmpty);
    });

    test('neither installRoot nor store is a programming error', () async {
      expect(
        () => McpBundleInstaller.installBytes(
          packSample(),
          runtime: runtime,
          policy: lenient,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('store locking', () {
    test('serialises concurrent installs into the same store', () async {
      final store = MemoryBundleInstallStore();
      final order = <String>[];

      final a = McpBundleInstaller.installBytes(
        packSample(id: 'com.example.a'),
        store: store,
        runtime: runtime,
        policy: lenient,
      ).then((_) => order.add('a'));
      final b = McpBundleInstaller.installBytes(
        packSample(id: 'com.example.b'),
        store: store,
        runtime: runtime,
        policy: lenient,
      ).then((_) => order.add('b'));

      await Future.wait([a, b]);
      expect(order, ['a', 'b']);
      expect(
        (await McpBundleInstaller.listFrom(store)).map((e) => e.id),
        ['com.example.a', 'com.example.b'],
      );
    });
  });
}
