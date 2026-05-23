/// Tests for `McpBundle` typed reserved-folder accessors.
///
/// Each typed accessor (`uiResources`, `factsResources`, …) wraps the
/// generic `bundle.resources(BundleFolder.X)` so consumers can read /
/// write a folder without spelling its name. This test pins the
/// folder-name binding for the 5 accessors added alongside the
/// `facts` / `workflows` / `pipelines` / `runbooks` / `tools` reserved
/// folders so a future rename or shuffle is caught immediately.
library;

import 'dart:io';

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mcp_bundle_test_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<McpBundle> loadProbe() async {
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
    return McpBundleLoader.loadDirectory(mbd.path);
  }

  group('McpBundle typed accessors — new folders', () {
    test('factsResources returns BundleResources for facts folder', () async {
      final bundle = await loadProbe();
      final r = bundle.factsResources;
      expect(r, isA<BundleResources>());
      expect(r.folder, same(BundleFolder.facts));
      expect(r.folder.name, equals('facts'));
    });

    test('workflowsResources returns BundleResources for workflows folder',
        () async {
      final bundle = await loadProbe();
      final r = bundle.workflowsResources;
      expect(r, isA<BundleResources>());
      expect(r.folder, same(BundleFolder.workflows));
      expect(r.folder.name, equals('workflows'));
    });

    test('pipelinesResources returns BundleResources for pipelines folder',
        () async {
      final bundle = await loadProbe();
      final r = bundle.pipelinesResources;
      expect(r, isA<BundleResources>());
      expect(r.folder, same(BundleFolder.pipelines));
      expect(r.folder.name, equals('pipelines'));
    });

    test('runbooksResources returns BundleResources for runbooks folder',
        () async {
      final bundle = await loadProbe();
      final r = bundle.runbooksResources;
      expect(r, isA<BundleResources>());
      expect(r.folder, same(BundleFolder.runbooks));
      expect(r.folder.name, equals('runbooks'));
    });

    test('toolsResources returns BundleResources for tools folder', () async {
      final bundle = await loadProbe();
      final r = bundle.toolsResources;
      expect(r, isA<BundleResources>());
      expect(r.folder, same(BundleFolder.tools));
      expect(r.folder.name, equals('tools'));
    });

    test('new typed accessors match generic resources(folder)', () async {
      final bundle = await loadProbe();
      expect(bundle.factsResources.folder,
          same(bundle.resources(BundleFolder.facts).folder));
      expect(bundle.workflowsResources.folder,
          same(bundle.resources(BundleFolder.workflows).folder));
      expect(bundle.pipelinesResources.folder,
          same(bundle.resources(BundleFolder.pipelines).folder));
      expect(bundle.runbooksResources.folder,
          same(bundle.resources(BundleFolder.runbooks).folder));
      expect(bundle.toolsResources.folder,
          same(bundle.resources(BundleFolder.tools).folder));
    });

    test('new typed accessors throw StateError on inline-loaded bundle', () {
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
      expect(() => bundle.factsResources, throwsStateError);
      expect(() => bundle.workflowsResources, throwsStateError);
      expect(() => bundle.pipelinesResources, throwsStateError);
      expect(() => bundle.runbooksResources, throwsStateError);
      expect(() => bundle.toolsResources, throwsStateError);
    });
  });
}
