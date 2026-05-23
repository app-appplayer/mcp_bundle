/// Tests for BundleResources — the read/write surface for the bundle's
/// reserved sub-folders (`ui/`, `assets/`, `skills/`, `knowledge/`,
/// `facts/`, `workflows/`, `pipelines/`, `runbooks/`, `tools/`,
/// `profiles/`, `philosophy/`, `agents/`).
///
/// Contract under test: every consumer of a bundle (renderer, MCP
/// server, designer, installer) goes through this surface instead of
/// `dart:io` directly.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('bundle_resources_test_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<McpBundle> writeMinimalBundle({
    Map<String, String> uiFiles = const {},
    Map<String, String> assetFiles = const {},
    Map<String, String> philosophyFiles = const {},
    Map<String, String> factsFiles = const {},
    Map<String, String> workflowsFiles = const {},
    Map<String, String> pipelinesFiles = const {},
    Map<String, String> runbooksFiles = const {},
    Map<String, String> toolsFiles = const {},
  }) async {
    final mbd = await Directory('${tmp.path}/probe.mbd').create();
    await File('${mbd.path}/manifest.json').writeAsString('''
{
  "schemaVersion": "1.0.0",
  "manifest": {
    "id": "com.example.probe",
    "name": "Probe",
    "version": "1.0.0",
    "schemaVersion": "1.0.0",
    "type": "application"
  }
}
''');
    Future<void> writeFolder(String folder, Map<String, String> files) async {
      for (final entry in files.entries) {
        final f = File('${mbd.path}/$folder/${entry.key}');
        await f.parent.create(recursive: true);
        await f.writeAsString(entry.value);
      }
    }

    await writeFolder('ui', uiFiles);
    await writeFolder('assets', assetFiles);
    await writeFolder('philosophy', philosophyFiles);
    await writeFolder('facts', factsFiles);
    await writeFolder('workflows', workflowsFiles);
    await writeFolder('pipelines', pipelinesFiles);
    await writeFolder('runbooks', runbooksFiles);
    await writeFolder('tools', toolsFiles);
    return McpBundleLoader.loadDirectory(mbd.path);
  }

  group('BundleResources — read', () {
    test('reads UTF-8 text from ui/<rel>', () async {
      final bundle = await writeMinimalBundle(uiFiles: {
        'app.json': '{"type":"application","title":"Probe"}',
      });
      final content = await bundle.uiResources.read('app.json');
      expect(content, equals('{"type":"application","title":"Probe"}'));
    });

    test('reads bytes from assets/<rel>', () async {
      final bundle = await writeMinimalBundle(assetFiles: {
        'icon.txt': 'binary-stand-in',
      });
      final bytes = await bundle.assetResources.readBytes('icon.txt');
      expect(String.fromCharCodes(bytes), equals('binary-stand-in'));
    });

    test('readJson decodes JSON file', () async {
      final bundle = await writeMinimalBundle(uiFiles: {
        'pages/main.json': '{"id":"main","route":"/main"}',
      });
      final decoded =
          await bundle.uiResources.readJson('pages/main.json') as Map;
      expect(decoded['id'], equals('main'));
      expect(decoded['route'], equals('/main'));
    });

    test('readJson on malformed JSON throws BundleResourceParseException',
        () async {
      final bundle = await writeMinimalBundle(uiFiles: {
        'broken.json': '{not valid json',
      });
      expect(
        () => bundle.uiResources.readJson('broken.json'),
        throwsA(isA<BundleResourceParseException>()),
      );
    });

    test('missing file throws BundleResourceNotFoundException', () async {
      final bundle = await writeMinimalBundle();
      expect(
        () => bundle.uiResources.read('app.json'),
        throwsA(isA<BundleResourceNotFoundException>()),
      );
    });
  });

  group('BundleResources — list', () {
    test('enumerates files with extension filter', () async {
      final bundle = await writeMinimalBundle(uiFiles: {
        'app.json': '{}',
        'pages/main.json': '{}',
        'pages/about.json': '{}',
        'README.md': 'doc',
      });
      final jsons = await bundle.uiResources.list(extension: '.json');
      expect(jsons, equals(['app.json', 'pages/about.json', 'pages/main.json']));
    });

    test('enumerates all files when extension filter is null', () async {
      final bundle = await writeMinimalBundle(uiFiles: {
        'app.json': '{}',
        'README.md': 'doc',
      });
      final all = await bundle.uiResources.list();
      expect(all.length, equals(2));
      expect(all, contains('app.json'));
      expect(all, contains('README.md'));
    });

    test('returns empty list when folder is missing', () async {
      final bundle = await writeMinimalBundle();
      expect(await bundle.uiResources.list(), isEmpty);
      expect(await bundle.philosophyResources.list(), isEmpty);
    });
  });

  group('BundleResources — write / delete / exists', () {
    test('write creates the file and parent directories', () async {
      final bundle = await writeMinimalBundle();
      await bundle.uiResources.write('pages/new.json', '{"id":"new"}');
      expect(await bundle.uiResources.exists('pages/new.json'), isTrue);
      expect(await bundle.uiResources.read('pages/new.json'),
          equals('{"id":"new"}'));
    });

    test('writeBytes round-trips arbitrary bytes', () async {
      final bundle = await writeMinimalBundle();
      final bytes = Uint8List.fromList([0x00, 0x01, 0x7F, 0x80, 0xFF]);
      await bundle.assetResources.writeBytes('blob.bin', bytes);
      expect(await bundle.assetResources.readBytes('blob.bin'), equals(bytes));
    });

    test('writeJson encodes and round-trips through readJson', () async {
      final bundle = await writeMinimalBundle();
      await bundle.uiResources.writeJson(
        'pages/new.json',
        <String, Object?>{'id': 'new', 'count': 3, 'enabled': true},
      );
      final decoded = await bundle.uiResources.readJson('pages/new.json');
      expect(
        decoded,
        equals(<String, Object?>{'id': 'new', 'count': 3, 'enabled': true}),
      );
      // Default indent = 2 → human-readable multi-line JSON on disk.
      final raw = await bundle.uiResources.read('pages/new.json');
      expect(raw, contains('\n  '));
    });

    test('writeJson honours indent: 0 (single-line)', () async {
      final bundle = await writeMinimalBundle();
      await bundle.uiResources.writeJson(
        'pages/x.json',
        <String, Object?>{'a': 1},
        indent: 0,
      );
      final raw = await bundle.uiResources.read('pages/x.json');
      expect(raw.contains('\n'), isFalse);
    });

    test('delete removes the file; second call is a no-op', () async {
      final bundle = await writeMinimalBundle(uiFiles: {'app.json': '{}'});
      expect(await bundle.uiResources.exists('app.json'), isTrue);
      await bundle.uiResources.delete('app.json');
      expect(await bundle.uiResources.exists('app.json'), isFalse);
      // Idempotent on missing.
      await bundle.uiResources.delete('app.json');
    });
  });

  group('BundleResources — path safety', () {
    test('rejects absolute paths', () async {
      final bundle = await writeMinimalBundle();
      expect(
        () => bundle.uiResources.read('/etc/passwd'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects path traversal via ..', () async {
      final bundle = await writeMinimalBundle();
      expect(
        () => bundle.uiResources.read('../manifest.json'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => bundle.uiResources.read('pages/../../manifest.json'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty path', () async {
      final bundle = await writeMinimalBundle();
      expect(
        () => bundle.uiResources.read(''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('BundleResources — folder coverage', () {
    test('typed accessors hit the right folder name', () async {
      final bundle = await writeMinimalBundle();
      expect(bundle.uiResources.folder.name, equals('ui'));
      expect(bundle.assetResources.folder.name, equals('assets'));
      expect(bundle.skillResources.folder.name, equals('skills'));
      expect(bundle.knowledgeResources.folder.name, equals('knowledge'));
      expect(bundle.factsResources.folder.name, equals('facts'));
      expect(bundle.workflowsResources.folder.name, equals('workflows'));
      expect(bundle.pipelinesResources.folder.name, equals('pipelines'));
      expect(bundle.runbooksResources.folder.name, equals('runbooks'));
      expect(bundle.toolsResources.folder.name, equals('tools'));
      expect(bundle.profileResources.folder.name, equals('profiles'));
      expect(bundle.philosophyResources.folder.name, equals('philosophy'));
      expect(bundle.agentResources.folder.name, equals('agents'));
    });

    test('philosophy folder is reachable end-to-end', () async {
      final bundle = await writeMinimalBundle(philosophyFiles: {
        'ethos.json': '{"name":"calm"}',
      });
      expect(await bundle.philosophyResources.list(extension: '.json'),
          equals(['ethos.json']));
      expect(
        await bundle.philosophyResources.read('ethos.json'),
        equals('{"name":"calm"}'),
      );
    });

    test('generic resources(folder) matches typed accessor', () async {
      final bundle = await writeMinimalBundle(uiFiles: {'a.json': '{}'});
      final typed = await bundle.uiResources.list();
      final generic = await bundle.resources(BundleFolder.ui).list();
      expect(generic, equals(typed));
    });

    test('BundleFolder.values enumerates all twelve reserved folders', () {
      expect(BundleFolder.values, hasLength(12));
      expect(
        BundleFolder.values.map((f) => f.name).toList(),
        equals([
          'ui',
          'assets',
          'skills',
          'knowledge',
          'facts',
          'workflows',
          'pipelines',
          'runbooks',
          'tools',
          'profiles',
          'philosophy',
          'agents',
        ]),
      );
    });
  });

  group('BundleResources — new folder round-trip (facts/workflows/'
      'pipelines/runbooks/tools)', () {
    test('facts folder: read / write / exists / list / delete round-trip',
        () async {
      final bundle = await writeMinimalBundle(factsFiles: {
        'seed.json': '{"subject":"sun","predicate":"is","object":"star"}',
      });
      // read seeded
      expect(
        await bundle.factsResources.read('seed.json'),
        equals('{"subject":"sun","predicate":"is","object":"star"}'),
      );
      // list
      expect(
        await bundle.factsResources.list(extension: '.json'),
        equals(['seed.json']),
      );
      // write new
      await bundle.factsResources.write('extra.json', '{"k":1}');
      expect(await bundle.factsResources.exists('extra.json'), isTrue);
      // delete
      await bundle.factsResources.delete('extra.json');
      expect(await bundle.factsResources.exists('extra.json'), isFalse);
    });

    test('workflows folder: read / write / exists / list / delete round-trip',
        () async {
      final bundle = await writeMinimalBundle(workflowsFiles: {
        'onboarding.json': '{"id":"onboarding","steps":[]}',
      });
      expect(
        await bundle.workflowsResources.read('onboarding.json'),
        equals('{"id":"onboarding","steps":[]}'),
      );
      expect(
        await bundle.workflowsResources.list(extension: '.json'),
        equals(['onboarding.json']),
      );
      await bundle.workflowsResources.write('extra.json', '{"k":1}');
      expect(await bundle.workflowsResources.exists('extra.json'), isTrue);
      await bundle.workflowsResources.delete('extra.json');
      expect(await bundle.workflowsResources.exists('extra.json'), isFalse);
    });

    test('pipelines folder: read / write / exists / list / delete round-trip',
        () async {
      final bundle = await writeMinimalBundle(pipelinesFiles: {
        'deploy.json': '{"id":"deploy","stages":[]}',
      });
      expect(
        await bundle.pipelinesResources.read('deploy.json'),
        equals('{"id":"deploy","stages":[]}'),
      );
      expect(
        await bundle.pipelinesResources.list(extension: '.json'),
        equals(['deploy.json']),
      );
      await bundle.pipelinesResources.write('extra.json', '{"k":1}');
      expect(await bundle.pipelinesResources.exists('extra.json'), isTrue);
      await bundle.pipelinesResources.delete('extra.json');
      expect(await bundle.pipelinesResources.exists('extra.json'), isFalse);
    });

    test('runbooks folder: read / write / exists / list / delete round-trip',
        () async {
      final bundle = await writeMinimalBundle(runbooksFiles: {
        'incident.json': '{"id":"incident","procedure":[]}',
      });
      expect(
        await bundle.runbooksResources.read('incident.json'),
        equals('{"id":"incident","procedure":[]}'),
      );
      expect(
        await bundle.runbooksResources.list(extension: '.json'),
        equals(['incident.json']),
      );
      await bundle.runbooksResources.write('extra.json', '{"k":1}');
      expect(await bundle.runbooksResources.exists('extra.json'), isTrue);
      await bundle.runbooksResources.delete('extra.json');
      expect(await bundle.runbooksResources.exists('extra.json'), isFalse);
    });

    test('tools folder: read / write / exists / list / delete round-trip',
        () async {
      final bundle = await writeMinimalBundle(toolsFiles: {
        'echo.json': '{"name":"echo","kind":"host"}',
      });
      expect(
        await bundle.toolsResources.read('echo.json'),
        equals('{"name":"echo","kind":"host"}'),
      );
      expect(
        await bundle.toolsResources.list(extension: '.json'),
        equals(['echo.json']),
      );
      await bundle.toolsResources.write('extra.json', '{"k":1}');
      expect(await bundle.toolsResources.exists('extra.json'), isTrue);
      await bundle.toolsResources.delete('extra.json');
      expect(await bundle.toolsResources.exists('extra.json'), isFalse);
    });
  });

  group('BundleResources — bundle without directory', () {
    test('throws StateError when bundle was loaded from inline JSON', () {
      final bundle = McpBundleLoader.fromJsonString('''
{
  "schemaVersion": "1.0.0",
  "manifest": {
    "id": "com.example.inline",
    "name": "Inline",
    "version": "1.0.0",
    "schemaVersion": "1.0.0",
    "type": "application"
  }
}
''');
      expect(bundle.directory, isNull);
      expect(() => bundle.uiResources, throwsStateError);
    });
  });
}
