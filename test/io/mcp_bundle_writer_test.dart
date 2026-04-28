/// Tests for [McpBundleWriter] — the dual to
/// `McpBundleLoader.loadDirectory`. Owns the `manifest.json` write path
/// and routes reserved-folder content through [BundleResources].
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mcp_bundle_writer_test_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  McpBundle minimalBundle() => const McpBundle(
        manifest: BundleManifest(
          id: 'com.example.probe',
          name: 'Probe',
          version: '1.0.0',
        ),
      );

  group('McpBundleWriter.writeDirectory', () {
    test('writes manifest.json and creates the .mbd directory', () async {
      final mbdPath = '${tmp.path}/probe.mbd';
      final returned = await McpBundleWriter.writeDirectory(
        minimalBundle(),
        mbdPath,
      );

      expect(Directory(returned).existsSync(), isTrue);
      final manifestFile = File('$mbdPath/manifest.json');
      expect(manifestFile.existsSync(), isTrue);
      final decoded = jsonDecode(manifestFile.readAsStringSync())
          as Map<String, dynamic>;
      expect(
        (decoded['manifest'] as Map<String, dynamic>)['id'],
        equals('com.example.probe'),
      );
    });

    test('legacy bundle.json is not produced', () async {
      final mbdPath = '${tmp.path}/probe.mbd';
      await McpBundleWriter.writeDirectory(minimalBundle(), mbdPath);
      expect(File('$mbdPath/bundle.json').existsSync(), isFalse);
    });

    test('default indent = 2 (multi-line manifest)', () async {
      final mbdPath = '${tmp.path}/probe.mbd';
      await McpBundleWriter.writeDirectory(minimalBundle(), mbdPath);
      final raw = File('$mbdPath/manifest.json').readAsStringSync();
      expect(raw, contains('\n  '));
    });

    test('indent: 0 emits single-line manifest', () async {
      final mbdPath = '${tmp.path}/probe.mbd';
      await McpBundleWriter.writeDirectory(
        minimalBundle(),
        mbdPath,
        indent: 0,
      );
      final raw = File('$mbdPath/manifest.json').readAsStringSync();
      expect(raw.contains('\n'), isFalse);
    });

    test('reserved files routed through BundleResources', () async {
      final mbdPath = '${tmp.path}/probe.mbd';
      await McpBundleWriter.writeDirectory(
        minimalBundle(),
        mbdPath,
        reservedFiles: {
          BundleFolder.ui: <String, Object>{
            'pages/home.json': <String, Object?>{'id': 'home'},
            'app.json': '{"type":"application"}',
          },
          BundleFolder.assets: <String, Object>{
            'icon.bin': Uint8List.fromList([0xCA, 0xFE]),
          },
        },
      );

      // The Writer stamped the directory; load through the loader to
      // confirm BundleResources can re-read every file.
      final loaded = await McpBundleLoader.loadDirectory(mbdPath);
      expect(loaded.manifest.id, equals('com.example.probe'));

      final pageJson = await loaded.uiResources.readJson('pages/home.json');
      expect(pageJson, equals({'id': 'home'}));
      expect(
        await loaded.uiResources.read('app.json'),
        equals('{"type":"application"}'),
      );
      expect(
        await loaded.assetResources.readBytes('icon.bin'),
        equals(Uint8List.fromList([0xCA, 0xFE])),
      );
    });

    test('refuses to overwrite a non-empty directory by default',
        () async {
      final mbdPath = '${tmp.path}/probe.mbd';
      await Directory(mbdPath).create(recursive: true);
      await File('$mbdPath/leftover.txt').writeAsString('keep me');

      expect(
        () => McpBundleWriter.writeDirectory(minimalBundle(), mbdPath),
        throwsA(isA<BundleWriteException>()),
      );
      // The pre-existing file must survive the failed call.
      expect(File('$mbdPath/leftover.txt').existsSync(), isTrue);
    });

    test('overwrite: true clears the directory before writing', () async {
      final mbdPath = '${tmp.path}/probe.mbd';
      await Directory(mbdPath).create(recursive: true);
      await File('$mbdPath/leftover.txt').writeAsString('discard');

      await McpBundleWriter.writeDirectory(
        minimalBundle(),
        mbdPath,
        overwrite: true,
      );
      expect(File('$mbdPath/leftover.txt').existsSync(), isFalse);
      expect(File('$mbdPath/manifest.json').existsSync(), isTrue);
    });

    test('round-trips through loadDirectory', () async {
      final mbdPath = '${tmp.path}/probe.mbd';
      await McpBundleWriter.writeDirectory(minimalBundle(), mbdPath);
      final loaded = await McpBundleLoader.loadDirectory(mbdPath);
      expect(loaded.manifest.id, equals('com.example.probe'));
      expect(loaded.manifest.name, equals('Probe'));
      expect(loaded.manifest.version, equals('1.0.0'));
    });
  });
}
