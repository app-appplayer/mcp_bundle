/// Reproduces the launcher flow:
/// `.mbd/` → `pack` → `.mcpb` bytes → `installBytes` → disk
/// → `loadInstalled` → `bundle.toJson` → `McpBundle.fromJson`.
///
/// The fixture lives under `test/fixtures/launcher_flow_probe.mbd/`
/// so this package's tests stay self-contained — `mcp_bundle` is a
/// lower-layer package than any consumer that ships a sample, so the
/// fixture must NOT live in `os/appplayer/...` or any upstream tree.
library;

import 'dart:io';

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  test('packed fixture .mcpb installs and reloads without cast errors',
      () async {
    final mbdPath =
        '${Directory.current.path}/test/fixtures/launcher_flow_probe.mbd';
    expect(Directory(mbdPath).existsSync(), isTrue,
        reason: 'fixture missing: $mbdPath');

    final tmp = await Directory.systemTemp.createTemp('launcher_flow_');
    try {
      // Pack the fixture .mbd/ → .mcpb bytes (canonical distribution form).
      final bytes = await McpBundlePacker.packDirectory(mbdPath);
      expect(bytes.isNotEmpty, isTrue);

      // Install — same path the launcher takes for an installed app.
      final installRoot = '${tmp.path}/installs';
      final installed = await McpBundleInstaller.installBytes(
        bytes,
        installRoot: installRoot,
        runtime: const RuntimeDescriptor(version: '1.0.0'),
      );
      expect(installed.id, 'com.example.launcher_flow');

      // Reload via loadInstalled — what the launcher hands to core.
      final loaded =
          await McpBundleLoader.loadInstalled(installRoot, installed.id);
      expect(loaded.manifest.id, installed.id);

      // Serialised form is what the launcher hands to core via
      // BundleInlineRef.
      final json = loaded.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['manifest'], isA<Map<String, dynamic>>());
      expect(json['ui'], isA<Map<String, dynamic>>());

      // Round-trip through McpBundle.fromJson like the core does.
      final reparsed = McpBundle.fromJson(json);
      expect(reparsed.manifest.id, installed.id);
    } finally {
      await tmp.delete(recursive: true);
    }
  });
}
