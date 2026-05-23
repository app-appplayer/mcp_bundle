/// Regression tests for `McpBundleLoader.fromJson` Section forwarding.
///
/// Background: prior to 0.3.3 fix the loader hand-rolled a `McpBundle(...)`
/// constructor call that only forwarded 4 fields (manifest / ui / skills /
/// assets / extensions). Every other Section the model defines (knowledge /
/// flow / profiles / philosophy / agents / facts / workflows / pipelines /
/// runbooks / tools / requires / factGraphSchema / factGraphSection /
/// bindings / tests / policies / integrity / compatibility) was silently
/// dropped at the loader boundary even though `_parseSections` had no
/// awareness of them at all. Hosts using `McpBundle.fromJson` directly saw
/// the right shape; hosts going through the loader (the canonical
/// `loadDirectory` / `loadFile` / `fromJsonString` path) did not.
///
/// These tests guard the round-trip: every typed top-level Section the
/// model accepts must survive the loader, both via the in-memory
/// `fromJson` entry point and via the on-disk `loadDirectory` entry
/// point. A backward-compat case asserts that bundles using only the
/// historical 4 sections still load unchanged.
import 'dart:convert';
import 'dart:io';

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

/// Build a manifest.json map populated with every typed top-level
/// Section the model declares. Each section is intentionally minimal —
/// just enough for the corresponding `fromJson` factory to succeed.
Map<String, dynamic> _allSectionsBundleJson() {
  return {
    'schemaVersion': '1.0.0',
    'manifest': {
      'id': 'all-sections-bundle',
      'name': 'All Sections Bundle',
      'version': '1.0.0',
    },
    // Existing 4 (must remain forwarded — backward compat anchor).
    'ui': {
      'schemaVersion': '1.0.0',
      'pages': <Map<String, dynamic>>[],
    },
    'skills': {
      'schemaVersion': '1.0.0',
      'modules': <Map<String, dynamic>>[],
    },
    'assets': {
      'schemaVersion': '1.0.0',
      'assets': <Map<String, dynamic>>[],
    },
    // Missing additions.
    'flow': {
      'schemaVersion': '1.0.0',
      'flows': <Map<String, dynamic>>[],
    },
    'knowledge': {
      'schemaVersion': '1.0.0',
      'sources': [
        {
          'id': 'kb-1',
          'name': 'Inline KB',
          'type': 'inline',
        },
      ],
    },
    'bindings': {
      'schemaVersion': '1.0.0',
      'bindings': <Map<String, dynamic>>[],
      'sources': <Map<String, dynamic>>[],
    },
    'tests': {
      'schemaVersion': '1.0.0',
      'suites': <Map<String, dynamic>>[],
    },
    'policies': {
      'policies': <Map<String, dynamic>>[],
    },
    'profiles': {
      'profiles': [
        {'id': 'p1', 'name': 'Profile 1'},
      ],
    },
    'philosophy': {
      'philosophies': [
        {'id': 'ph1', 'name': 'Phil 1', 'statement': 'Be kind.'},
      ],
    },
    'agents': {
      'agents': [
        {'id': 'a1', 'name': 'Agent 1', 'role': 'helper'},
      ],
    },
    'facts': {
      'schemaVersion': '1.0.0',
      'facts': [
        {
          'subject': 'workspace',
          'predicate': 'contains',
          'object': 'mcp_bundle',
        },
      ],
    },
    'workflows': {
      'schemaVersion': '1.0.0',
      'workflows': [
        {'id': 'wf1', 'name': 'Workflow 1'},
      ],
    },
    'pipelines': {
      'schemaVersion': '1.0.0',
      'pipelines': [
        {'id': 'pl1', 'name': 'Pipeline 1'},
      ],
    },
    'runbooks': {
      'schemaVersion': '1.0.0',
      'runbooks': [
        {'id': 'rb1', 'name': 'Runbook 1'},
      ],
    },
    'tools': {
      'schemaVersion': '1.0.0',
      'tools': [
        {'name': 'echo', 'kind': 'host'},
      ],
    },
    'requires': {
      'builtinAtoms': ['mcp', 'ui'],
      'builtinTools': <String>[],
    },
    'factGraphSchema': {
      'entityTypes': <Map<String, dynamic>>[],
      'relationTypes': <Map<String, dynamic>>[],
      'factTypes': <Map<String, dynamic>>[],
    },
    'factGraphSection': {
      'version': '1.0.0',
      'mode': 'embedded',
    },
    'compatibility': {
      'schemaVersion': '1.0.0',
    },
    'integrity': {
      'computedAt': '2026-05-15T00:00:00.000Z',
    },
    'extensions': {
      'host_specific': {'foo': 'bar'},
    },
  };
}

/// Backward-compat shape: only the 4 historically forwarded sections
/// (manifest / ui / skills / assets). Bundles produced before the fix
/// must continue to load identically.
Map<String, dynamic> _legacyFourSectionBundleJson() {
  return {
    'schemaVersion': '1.0.0',
    'manifest': {
      'id': 'legacy-bundle',
      'name': 'Legacy Bundle',
      'version': '1.0.0',
    },
    'ui': {
      'schemaVersion': '1.0.0',
      'pages': <Map<String, dynamic>>[],
    },
    'skills': {
      'schemaVersion': '1.0.0',
      'modules': <Map<String, dynamic>>[],
    },
    'assets': {
      'schemaVersion': '1.0.0',
      'assets': <Map<String, dynamic>>[],
    },
  };
}

/// Bundle JSON containing only the inline KnowledgeSection corpus. Used
/// to assert that the previously-dropped path now round-trips the
/// `'knowledge'` key through `bundle.toJson()`.
Map<String, dynamic> _knowledgeOnlyBundleJson() {
  return {
    'schemaVersion': '1.0.0',
    'manifest': {
      'id': 'knowledge-only',
      'name': 'Knowledge Only',
      'version': '1.0.0',
    },
    'knowledge': {
      'schemaVersion': '1.0.0',
      'sources': [
        {
          'id': 'kb-1',
          'name': 'Manifest Inline KB',
          'type': 'inline',
        },
      ],
    },
  };
}

void main() {
  group('McpBundleLoader.fromJson — Section forward (regression)', () {
    test('every typed Section parses and forwards through fromJson', () {
      final bundle = McpBundleLoader.fromJson(_allSectionsBundleJson());

      // Existing 4 (anchor).
      expect(bundle.ui, isNotNull, reason: 'ui must remain forwarded');
      expect(bundle.skills, isNotNull, reason: 'skills must remain forwarded');
      expect(bundle.assets, isNotNull, reason: 'assets must remain forwarded');

      // Newly-forwarded missing sections.
      expect(bundle.flow, isNotNull, reason: 'flow forward missing');
      expect(bundle.knowledge, isNotNull, reason: 'knowledge forward missing');
      expect(bundle.bindings, isNotNull, reason: 'bindings forward missing');
      expect(bundle.tests, isNotNull, reason: 'tests forward missing');
      expect(bundle.policies, isNotNull, reason: 'policies forward missing');
      expect(bundle.profiles, isNotNull, reason: 'profiles forward missing');
      expect(bundle.philosophy, isNotNull,
          reason: 'philosophy forward missing');
      expect(bundle.agents, isNotNull, reason: 'agents forward missing');
      expect(bundle.facts, isNotNull, reason: 'facts forward missing');
      expect(bundle.workflows, isNotNull, reason: 'workflows forward missing');
      expect(bundle.pipelines, isNotNull, reason: 'pipelines forward missing');
      expect(bundle.runbooks, isNotNull, reason: 'runbooks forward missing');
      expect(bundle.tools, isNotNull, reason: 'tools forward missing');
      expect(bundle.requires, isNotNull, reason: 'requires forward missing');
      expect(bundle.factGraphSchema, isNotNull,
          reason: 'factGraphSchema forward missing');
      expect(bundle.factGraphSection, isNotNull,
          reason: 'factGraphSection forward missing');
      expect(bundle.compatibility, isNotNull,
          reason: 'compatibility forward missing');
      expect(bundle.integrity, isNotNull, reason: 'integrity forward missing');
    });

    test('inline knowledge corpus parses into KnowledgeSection', () {
      final bundle = McpBundleLoader.fromJson(_knowledgeOnlyBundleJson());

      expect(bundle.knowledge, isNotNull);
      expect(bundle.knowledge!.sources, hasLength(1));
      expect(bundle.knowledge!.sources.first.id, 'kb-1');
      expect(bundle.knowledge!.sources.first.name, 'Manifest Inline KB');
    });

    test('toJson() round-trip preserves the knowledge key', () {
      final bundle = McpBundleLoader.fromJson(_knowledgeOnlyBundleJson());
      final out = bundle.toJson();

      expect(out.containsKey('knowledge'), isTrue,
          reason:
              'bundle.toJson() must emit the knowledge key after loader fix');
      expect(out['knowledge'], isA<Map<String, dynamic>>());
    });

    test('extension content payload survives forwarding', () {
      final bundle = McpBundleLoader.fromJson(_allSectionsBundleJson());

      // Loader merges its own warning / error keys but author entries
      // must survive untouched.
      expect(bundle.extensions['host_specific'],
          equals({'foo': 'bar'}));
    });
  });

  group('McpBundleLoader — section forwarding through loadDirectory', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('mcp_bundle_fwd_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loadDirectory preserves every typed top-level section', () async {
      final manifestFile = File('${tempDir.path}/manifest.json');
      await manifestFile.writeAsString(jsonEncode(_allSectionsBundleJson()));

      final bundle = await McpBundleLoader.loadDirectory(tempDir.path);

      // Bundle now carries the on-disk root.
      expect(bundle.directory, isNotNull);

      // Same forwarding contract as fromJson (regression path through
      // loadFile + _resolveAssetPaths).
      expect(bundle.ui, isNotNull);
      expect(bundle.skills, isNotNull);
      expect(bundle.assets, isNotNull);
      expect(bundle.flow, isNotNull);
      expect(bundle.knowledge, isNotNull);
      expect(bundle.bindings, isNotNull);
      expect(bundle.tests, isNotNull);
      expect(bundle.policies, isNotNull);
      expect(bundle.profiles, isNotNull);
      expect(bundle.philosophy, isNotNull);
      expect(bundle.agents, isNotNull);
      expect(bundle.facts, isNotNull);
      expect(bundle.workflows, isNotNull);
      expect(bundle.pipelines, isNotNull);
      expect(bundle.runbooks, isNotNull);
      expect(bundle.tools, isNotNull);
      expect(bundle.requires, isNotNull);
      expect(bundle.factGraphSchema, isNotNull);
      expect(bundle.factGraphSection, isNotNull);
      expect(bundle.compatibility, isNotNull);
      expect(bundle.integrity, isNotNull);
    });

    test('fromJsonString preserves every typed top-level section', () {
      final jsonStr = jsonEncode(_allSectionsBundleJson());

      final bundle = McpBundleLoader.fromJsonString(jsonStr);

      expect(bundle.knowledge, isNotNull);
      expect(bundle.tools, isNotNull);
      expect(bundle.facts, isNotNull);
      expect(bundle.workflows, isNotNull);
      expect(bundle.pipelines, isNotNull);
      expect(bundle.runbooks, isNotNull);
      expect(bundle.philosophy, isNotNull);
      expect(bundle.agents, isNotNull);
      expect(bundle.profiles, isNotNull);
      expect(bundle.factGraphSchema, isNotNull);
      expect(bundle.factGraphSection, isNotNull);
      expect(bundle.bindings, isNotNull);
      expect(bundle.tests, isNotNull);
      expect(bundle.policies, isNotNull);
    });
  });

  group('McpBundleLoader — backward compatibility', () {
    test('legacy ui/skills/assets-only bundle still loads', () {
      final bundle = McpBundleLoader.fromJson(_legacyFourSectionBundleJson());

      expect(bundle.manifest.id, 'legacy-bundle');
      expect(bundle.ui, isNotNull);
      expect(bundle.skills, isNotNull);
      expect(bundle.assets, isNotNull);

      // All other sections remain null — additive forward must not
      // synthesize empty stand-ins.
      expect(bundle.flow, isNull);
      expect(bundle.knowledge, isNull);
      expect(bundle.bindings, isNull);
      expect(bundle.tests, isNull);
      expect(bundle.policies, isNull);
      expect(bundle.profiles, isNull);
      expect(bundle.philosophy, isNull);
      expect(bundle.agents, isNull);
      expect(bundle.facts, isNull);
      expect(bundle.workflows, isNull);
      expect(bundle.pipelines, isNull);
      expect(bundle.runbooks, isNull);
      expect(bundle.tools, isNull);
      expect(bundle.requires, isNull);
      expect(bundle.factGraphSchema, isNull);
      expect(bundle.factGraphSection, isNull);
      expect(bundle.compatibility, isNull);
      expect(bundle.integrity, isNull);
    });

    test('legacy bundle through loadDirectory unchanged', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('mcp_bundle_legacy_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final manifestFile = File('${tempDir.path}/manifest.json');
      await manifestFile
          .writeAsString(jsonEncode(_legacyFourSectionBundleJson()));

      final bundle = await McpBundleLoader.loadDirectory(tempDir.path);

      expect(bundle.manifest.id, 'legacy-bundle');
      expect(bundle.ui, isNotNull);
      expect(bundle.skills, isNotNull);
      expect(bundle.assets, isNotNull);
      expect(bundle.knowledge, isNull);
      expect(bundle.tools, isNull);
    });
  });
}
