/// Regression for the 5 round-trip gaps reported in
/// `cherry/inbox/mcp-bundle-authoring-roundtrip-gaps-2026-05-19.md`.
///
/// G1 — chat / settings / wiring section model coverage
/// G2 — unknown top-level key absorption (forward-compat)
/// G3 — RequiresSection empty-array preservation
/// G5 — McpBundleMutator.mutate accepts McpLoaderOptions
///
/// G4 was reverted — spec §3.2 mandates section schemaVersion always
/// emit; the noise digest is a spec-driven choice, not a defect.
library;

import 'dart:convert';
import 'dart:io';

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('G1 — chat / settings / wiring round-trip', () {
    test('top-level chat round-trips with slashCommands and agent', () {
      final raw = <String, dynamic>{
        'manifest': {'id': 'c1', 'name': 'C', 'version': '1.0.0'},
        'chat': {
          'slashCommands': [
            {
              'command': '/help',
              'description': 'show help',
              'directDispatch': {'tool': 'showHelp', 'args': {'k': 1}},
            },
            {'command': '/find', 'template': '/find '},
          ],
          'agent': 'main_agent',
        },
      };
      final bundle = McpBundle.fromJson(raw);
      expect(bundle.chat, isNotNull);
      expect(bundle.chat!.slashCommands.length, 2);
      expect(bundle.chat!.slashCommands.first.tool, 'showHelp');
      expect(bundle.chat!.slashCommands.first.args, {'k': 1});
      expect(bundle.chat!.agent, 'main_agent');

      final reparsed = McpBundle.fromJson(bundle.toJson());
      expect(reparsed.chat!.slashCommands.length, 2);
      expect(reparsed.chat!.agent, 'main_agent');
    });

    test('wiring titlebar / statusbar round-trip (chrome user-zone payloads)', () {
      final raw = <String, dynamic>{
        'manifest': {'id': 'cz', 'name': 'CZ', 'version': '1.0.0'},
        'wiring': {
          'titlebar': 'scenarios: {{count}} · ready',
          'statusbar': 'warnings: {{warnings}}',
        },
      };
      final bundle = McpBundle.fromJson(raw);
      expect(bundle.wiring!.titlebar, 'scenarios: {{count}} · ready');
      expect(bundle.wiring!.statusbar, 'warnings: {{warnings}}');

      final reparsed = McpBundle.fromJson(bundle.toJson());
      expect(reparsed.wiring!.titlebar, 'scenarios: {{count}} · ready');
      expect(reparsed.wiring!.statusbar, 'warnings: {{warnings}}');
    });

    test('wiring titlebar / statusbar omit when null', () {
      final raw = <String, dynamic>{
        'manifest': {'id': 'cz2', 'name': 'CZ2', 'version': '1.0.0'},
        'wiring': {'lifecycle': []},
      };
      final bundle = McpBundle.fromJson(raw);
      expect(bundle.wiring!.titlebar, isNull);
      expect(bundle.wiring!.statusbar, isNull);
      final out = bundle.wiring!.toJson();
      expect(out.containsKey('titlebar'), isFalse);
      expect(out.containsKey('statusbar'), isFalse);
    });

    test('top-level wiring round-trips with domainActions / lifecycle / settings', () {
      final raw = <String, dynamic>{
        'manifest': {'id': 'w1', 'name': 'W', 'version': '1.0.0'},
        'wiring': {
          'domainActions': [
            {'kind': 'button', 'tool': 'export', 'icon': 'upload'},
            {
              'kind': 'selectGroup',
              'stateKey': 'currentRoute',
              'items': [
                {'icon': 'preview', 'tool': 'goto', 'args': {'p': 1}, 'value': '/p1'},
                {'icon': 'build', 'tool': 'goto', 'args': {'p': 2}, 'value': '/p2'},
              ],
            },
          ],
          'lifecycle': [
            {'slot': 'project.save', 'tool': 'doSave'},
          ],
          'settings': [
            {'label': 'Reset', 'tool': 'reset', 'icon': 'refresh'},
          ],
          'lifecycleStateBindings': {'project.save': 'dirty'},
        },
      };
      final bundle = McpBundle.fromJson(raw);
      expect(bundle.wiring, isNotNull);
      expect(bundle.wiring!.domainActions.length, 2);
      expect(bundle.wiring!.domainActions.first.kind, DomainActionKind.button);
      expect(bundle.wiring!.domainActions.last.kind, DomainActionKind.selectGroup);
      expect(bundle.wiring!.domainActions.last.items.length, 2);
      expect(bundle.wiring!.lifecycle.first.slot, 'project.save');
      expect(bundle.wiring!.settings.first.label, 'Reset');
      expect(bundle.wiring!.lifecycleStateBindings['project.save'], 'dirty');

      final reparsed = McpBundle.fromJson(bundle.toJson());
      expect(reparsed.wiring!.domainActions.length, 2);
      expect(reparsed.wiring!.lifecycle.first.tool, 'doSave');
      expect(reparsed.wiring!.lifecycleStateBindings['project.save'], 'dirty');
    });

    test('top-level settings round-trips with sections × fields', () {
      final raw = <String, dynamic>{
        'manifest': {'id': 's1', 'name': 'S', 'version': '1.0.0'},
        'settings': {
          'sections': [
            {
              'key': 'general',
              'label': 'General',
              'fields': [
                {
                  'key': 'sizeDefault',
                  'label': 'Default size',
                  'type': 'menu',
                  'options': ['s', 'm', 'l'],
                  'value': 'm',
                  'placeholder': 'pick one',
                },
              ],
            },
          ],
        },
      };
      final bundle = McpBundle.fromJson(raw);
      expect(bundle.settingsSection, isNotNull);
      final f = bundle.settingsSection!.sections.first.fields.first;
      expect(f.key, 'sizeDefault');
      expect(f.type, 'menu');
      expect(f.options, ['s', 'm', 'l']);
      expect(f.value, 'm');
      // Free-form extra preserved.
      expect(f.extra['placeholder'], 'pick one');

      final reparsed = McpBundle.fromJson(bundle.toJson());
      expect(reparsed.settingsSection!.sections.first.fields.first.extra['placeholder'],
          'pick one');
    });

    test('legacy manifest-nested chat/wiring/settings accepted on load', () {
      // Pre-spec-update bundles embedded these inline under manifest.
      // Loader still resolves them.
      final raw = <String, dynamic>{
        'manifest': {
          'id': 'lg', 'name': 'L', 'version': '1.0.0',
          'chat': {'slashCommands': [{'command': '/x', 'tool': 't'}]},
          'wiring': {'lifecycle': [{'slot': 'project.new', 'tool': 'n'}]},
          'settings': {'sections': [{'key': 'g', 'label': 'G', 'fields': []}]},
        },
      };
      final bundle = McpBundle.fromJson(raw);
      expect(bundle.chat!.slashCommands.first.command, '/x');
      expect(bundle.wiring!.lifecycle.first.slot, 'project.new');
      expect(bundle.settingsSection!.sections.first.key, 'g');
    });

    test('top-level wins when both positions present', () {
      final raw = <String, dynamic>{
        'manifest': {
          'id': 'tw', 'name': 'TW', 'version': '1.0.0',
          'chat': {'slashCommands': [{'command': '/nested'}]},
        },
        'chat': {'slashCommands': [{'command': '/top'}]},
      };
      final bundle = McpBundle.fromJson(raw);
      expect(bundle.chat!.slashCommands.first.command, '/top');
    });
  });

  group('G2 — unknown top-level key absorption', () {
    test('unknown keys survive round-trip via extensions._unmodeledTopLevel', () {
      final raw = <String, dynamic>{
        'manifest': {'id': 'u1', 'name': 'U', 'version': '1.0.0'},
        'futureSection': {'foo': 1, 'bar': [1, 2, 3]},
        'anotherCustom': 'hello',
      };
      final bundle = McpBundle.fromJson(raw);
      final emitted = bundle.toJson();
      expect(emitted['futureSection'], {'foo': 1, 'bar': [1, 2, 3]});
      expect(emitted['anotherCustom'], 'hello');
      // Reserved sub-key is internal and not re-emitted under extensions.
      final ext = emitted['extensions'] as Map<String, dynamic>?;
      expect(ext == null || !ext.containsKey('_unmodeledTopLevel'), isTrue);
    });

    test('known + unknown keys coexist', () {
      final raw = <String, dynamic>{
        'manifest': {'id': 'k', 'name': 'K', 'version': '1.0.0'},
        'requires': {'builtinAtoms': []},
        'mysteryV2': {'opaque': true},
      };
      final bundle = McpBundle.fromJson(raw);
      final out = bundle.toJson();
      expect(out['requires'], isNotNull);
      expect(out['mysteryV2'], {'opaque': true});
    });
  });

  group('G3 — RequiresSection empty-array preservation', () {
    test('explicit empty builtinAtoms survives round-trip', () {
      final raw = <String, dynamic>{
        'manifest': {'id': 'r1', 'name': 'R', 'version': '1.0.0'},
        'requires': {'builtinAtoms': []},
      };
      final bundle = McpBundle.fromJson(raw);
      final out = bundle.toJson();
      expect(out['requires'], isNotNull);
      final req = out['requires'] as Map<String, dynamic>;
      expect(req.containsKey('builtinAtoms'), isTrue);
      expect(req['builtinAtoms'], <String>[]);
    });

    test('absent builtinAtoms stays absent after round-trip', () {
      final raw = <String, dynamic>{
        'manifest': {'id': 'r2', 'name': 'R2', 'version': '1.0.0'},
        'requires': {'schemaVersion': '1.0.0'},
      };
      final bundle = McpBundle.fromJson(raw);
      final out = bundle.toJson();
      final req = out['requires'] as Map<String, dynamic>;
      expect(req.containsKey('builtinAtoms'), isFalse);
    });
  });

  group('G5 — McpBundleMutator.mutate accepts McpLoaderOptions', () {
    test('lenient options let legacy bundle (missing schemaVersion) mutate', () async {
      final tmp = await Directory.systemTemp.createTemp('mcp_bundle_g5_');
      try {
        final mbdPath = '${tmp.path}/legacy.mbd';
        await Directory(mbdPath).create();
        // Legacy bundle: top-level schemaVersion absent.
        final raw = {
          'manifest': {'id': 'lg', 'name': 'Legacy', 'version': '1.0.0'},
        };
        await File('$mbdPath/manifest.json').writeAsString(jsonEncode(raw));

        await McpBundleMutator.mutate<void>(
          mbdPath,
          options: const McpLoaderOptions.lenient(),
          fn: (current) async => MutationOutcome(
            updated: current.copyWith(
              manifest: current.manifest.copyWith(name: 'Migrated'),
            ),
            result: null,
          ),
        );

        final out = jsonDecode(await File('$mbdPath/manifest.json').readAsString())
            as Map<String, dynamic>;
        expect((out['manifest'] as Map)['name'], 'Migrated');
      } finally {
        await tmp.delete(recursive: true);
      }
    });
  });
}
