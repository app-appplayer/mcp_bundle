/// Lifecycle tests for `McpBundlePacker` + `McpBundleInstaller` +
/// `McpBundleLoader.loadInstalled`.
///
/// The suite covers:
///   - pack → install → load round trip
///   - deterministic pack output
///   - integrity scopes (canonicalJson, contentSections)
///   - tampered archive rejection
///   - compatibility rejection (runtime version, required feature)
///   - safety limits (entry count / uncompressed bytes)
///   - ZIP magic check
///   - conflict policy variants
///   - uninstall and list semantics
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('mcp_bundle_install_');
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  /// Write a minimal valid `.mbd/` layout into [dir] and return the path.
  Future<String> _writeSampleMbd(
    Directory dir, {
    String id = 'com.example.app',
    String version = '1.0.0',
    String? minRuntime,
    String? maxRuntime,
    List<String> features = const [],
    List<String> incompatibleWith = const [],
    ContentScope scope = ContentScope.canonicalJson,
    bool includeAssetFile = true,
  }) async {
    final manifest = <String, dynamic>{
      'id': id,
      'name': 'Sample',
      'version': version,
      'schemaVersion': '1.0.0',
      'type': 'application',
      'entryPoint': 'ui.main',
    };
    final bundle = <String, dynamic>{
      'schemaVersion': '1.0.0',
      'manifest': manifest,
      'ui': {
        'schemaVersion': '1.0.0',
        'pages': [
          {
            'id': 'main',
            'name': 'Home',
            'route': '/',
            'root': {'type': 'box', 'children': []},
          }
        ],
      },
      'integrity': {
        'contentHash': {
          'algorithm': 'sha256',
          'value': '',
          'scope': scope.name,
        },
      },
      if (minRuntime != null ||
              maxRuntime != null ||
              features.isNotEmpty ||
              incompatibleWith.isNotEmpty)
        'compatibility': {
          if (minRuntime != null) 'minRuntimeVersion': minRuntime,
          if (maxRuntime != null) 'maxRuntimeVersion': maxRuntime,
          if (features.isNotEmpty) 'requiredFeatures': features,
          if (incompatibleWith.isNotEmpty) 'incompatibleWith': incompatibleWith,
        },
      if (includeAssetFile)
        'assets': {
          'schemaVersion': '1.0.0',
          'assets': [
            {
              'id': 'icon',
              'path': 'icons/icon.svg',
              'type': 'icon',
              'mimeType': 'image/svg+xml',
              'contentRef': 'assets/icons/icon.svg',
            }
          ],
        },
    };
    await File('${dir.path}/manifest.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(bundle),
    );
    if (includeAssetFile) {
      final iconDir = Directory('${dir.path}/assets/icons');
      await iconDir.create(recursive: true);
      await File('${iconDir.path}/icon.svg').writeAsString(
        '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>',
      );
    }
    return dir.path;
  }

  group('pack + install + load round trip', () {
    test('installs, lists, and loads an installed bundle', () async {
      final mbd = await Directory('${tempRoot.path}/mbd').create();
      await _writeSampleMbd(mbd);

      final bytes =
          await McpBundlePacker.packDirectory(mbd.path, computeIntegrity: true);
      expect(bytes.length, greaterThan(0));
      expect(bytes.sublist(0, 4), equals([0x50, 0x4B, 0x03, 0x04]));

      final installRoot = '${tempRoot.path}/installs';
      final installed = await McpBundleInstaller.installBytes(
        bytes,
        installRoot: installRoot,
        runtime: const RuntimeDescriptor(version: '1.0.0'),
      );
      expect(installed.id, 'com.example.app');
      expect(installed.version, '1.0.0');
      expect(File('${installed.installPath}/manifest.json').existsSync(), isTrue);
      expect(
        File('${installed.installPath}/.install.json').existsSync(),
        isTrue,
      );
      expect(
        File('${installed.installPath}/assets/icons/icon.svg').existsSync(),
        isTrue,
      );

      final list = await McpBundleInstaller.list(installRoot);
      expect(list.length, 1);
      expect(list.single.id, 'com.example.app');

      final loaded =
          await McpBundleLoader.loadInstalled(installRoot, 'com.example.app');
      expect(loaded.manifest.id, 'com.example.app');
    });

    test('pack output is deterministic', () async {
      final mbd = await Directory('${tempRoot.path}/mbd').create();
      await _writeSampleMbd(mbd);

      final a = await McpBundlePacker.packDirectory(mbd.path);
      final b = await McpBundlePacker.packDirectory(mbd.path);
      expect(a, equals(b));
    });
  });

  group('integrity scopes', () {
    test('canonicalJson scope round-trips through install', () async {
      final mbd = await Directory('${tempRoot.path}/mbd').create();
      await _writeSampleMbd(mbd, scope: ContentScope.canonicalJson);
      final bytes = await McpBundlePacker.packDirectory(mbd.path);
      final installed = await McpBundleInstaller.installBytes(
        bytes,
        installRoot: '${tempRoot.path}/installs',
        runtime: const RuntimeDescriptor(version: '1.0.0'),
      );
      expect(installed.id, 'com.example.app');
    });

    test('contentSections scope round-trips through install', () async {
      final mbd = await Directory('${tempRoot.path}/mbd').create();
      await _writeSampleMbd(mbd, scope: ContentScope.contentSections);
      final bytes = await McpBundlePacker.packDirectory(mbd.path);
      final installed = await McpBundleInstaller.installBytes(
        bytes,
        installRoot: '${tempRoot.path}/installs',
        runtime: const RuntimeDescriptor(version: '1.0.0'),
      );
      expect(installed.id, 'com.example.app');
    });

    test('tampered manifest.json fails contentHash verification', () async {
      final mbd = await Directory('${tempRoot.path}/mbd').create();
      await _writeSampleMbd(mbd);
      final bytes = await McpBundlePacker.packDirectory(mbd.path);

      final archive = ZipDecoder().decodeBytes(bytes);
      final bundleEntry =
          archive.files.firstWhere((f) => f.name == 'manifest.json');
      final decoded =
          jsonDecode(utf8.decode(bundleEntry.content as List<int>))
              as Map<String, dynamic>;
      (decoded['manifest'] as Map<String, dynamic>)['name'] = 'Tampered';
      final tamperedBytes =
          utf8.encode(const JsonEncoder().convert(decoded));

      final tamperedArchive = Archive();
      tamperedArchive.addFile(
        ArchiveFile('manifest.json', tamperedBytes.length, tamperedBytes),
      );
      for (final f in archive.files) {
        if (f.name == 'manifest.json') continue;
        final content = f.content as List<int>;
        tamperedArchive.addFile(ArchiveFile(f.name, content.length, content));
      }
      final tamperedZip =
          Uint8List.fromList(ZipEncoder().encode(tamperedArchive)!);

      expect(
        () => McpBundleInstaller.installBytes(
          tamperedZip,
          installRoot: '${tempRoot.path}/installs',
          runtime: const RuntimeDescriptor(version: '1.0.0'),
        ),
        throwsA(isA<BundleIntegrityException>()),
      );
    });
  });

  group('compatibility rejection', () {
    test('rejects runtime version below minRuntimeVersion', () async {
      final mbd = await Directory('${tempRoot.path}/mbd').create();
      await _writeSampleMbd(mbd, minRuntime: '2.0.0');
      final bytes = await McpBundlePacker.packDirectory(mbd.path);
      expect(
        () => McpBundleInstaller.installBytes(
          bytes,
          installRoot: '${tempRoot.path}/installs',
          runtime: const RuntimeDescriptor(version: '1.0.0'),
        ),
        throwsA(isA<BundleCompatibilityException>()
            .having((e) => e.reason, 'reason', 'runtimeVersion')),
      );
    });

    test('rejects missing required feature', () async {
      final mbd = await Directory('${tempRoot.path}/mbd').create();
      await _writeSampleMbd(mbd, features: ['vision']);
      final bytes = await McpBundlePacker.packDirectory(mbd.path);
      expect(
        () => McpBundleInstaller.installBytes(
          bytes,
          installRoot: '${tempRoot.path}/installs',
          runtime: const RuntimeDescriptor(version: '1.0.0'),
        ),
        throwsA(isA<BundleCompatibilityException>()
            .having((e) => e.reason, 'reason', 'requiredFeature')),
      );
    });
  });

  group('safety limits', () {
    test('rejects bytes beyond maxCompressedBytes', () async {
      final mbd = await Directory('${tempRoot.path}/mbd').create();
      await _writeSampleMbd(mbd);
      final bytes = await McpBundlePacker.packDirectory(mbd.path);
      expect(
        () => McpBundleInstaller.installBytes(
          bytes,
          installRoot: '${tempRoot.path}/installs',
          runtime: const RuntimeDescriptor(version: '1.0.0'),
          policy: const InstallPolicy(
            limits: InstallLimits(maxCompressedBytes: 64),
          ),
        ),
        throwsA(isA<BundleLimitException>()
            .having((e) => e.limit, 'limit', 'maxCompressedBytes')),
      );
    });

    test('rejects non-ZIP bytes with BundleFormatException', () async {
      expect(
        () => McpBundleInstaller.installBytes(
          Uint8List.fromList(utf8.encode('{"not":"a zip"}')),
          installRoot: '${tempRoot.path}/installs',
          runtime: const RuntimeDescriptor(version: '1.0.0'),
        ),
        throwsA(isA<BundleFormatException>()),
      );
    });
  });

  group('conflict policy', () {
    test('failIfExists throws on second install', () async {
      final mbd = await Directory('${tempRoot.path}/mbd').create();
      await _writeSampleMbd(mbd);
      final bytes = await McpBundlePacker.packDirectory(mbd.path);

      final installRoot = '${tempRoot.path}/installs';
      await McpBundleInstaller.installBytes(
        bytes,
        installRoot: installRoot,
        runtime: const RuntimeDescriptor(version: '1.0.0'),
      );
      expect(
        () => McpBundleInstaller.installBytes(
          bytes,
          installRoot: installRoot,
          runtime: const RuntimeDescriptor(version: '1.0.0'),
          policy: const InstallPolicy(
            onConflict: InstallConflictPolicy.failIfExists,
          ),
        ),
        throwsA(isA<BundleAlreadyInstalledException>()),
      );
    });

    test('replace swaps atomically', () async {
      final mbdA = await Directory('${tempRoot.path}/mbdA').create();
      await _writeSampleMbd(mbdA, version: '1.0.0');
      final bytesA = await McpBundlePacker.packDirectory(mbdA.path);

      final mbdB = await Directory('${tempRoot.path}/mbdB').create();
      await _writeSampleMbd(mbdB, version: '1.1.0');
      final bytesB = await McpBundlePacker.packDirectory(mbdB.path);

      final installRoot = '${tempRoot.path}/installs';
      final first = await McpBundleInstaller.installBytes(
        bytesA,
        installRoot: installRoot,
        runtime: const RuntimeDescriptor(version: '1.0.0'),
      );
      expect(first.version, '1.0.0');

      final second = await McpBundleInstaller.installBytes(
        bytesB,
        installRoot: installRoot,
        runtime: const RuntimeDescriptor(version: '1.0.0'),
      );
      expect(second.version, '1.1.0');

      final list = await McpBundleInstaller.list(installRoot);
      expect(list.length, 1);
      expect(list.single.version, '1.1.0');
    });

    test('skipIfExists returns existing install without rewriting', () async {
      final mbd = await Directory('${tempRoot.path}/mbd').create();
      await _writeSampleMbd(mbd, version: '1.0.0');
      final bytes = await McpBundlePacker.packDirectory(mbd.path);

      final installRoot = '${tempRoot.path}/installs';
      await McpBundleInstaller.installBytes(
        bytes,
        installRoot: installRoot,
        runtime: const RuntimeDescriptor(version: '1.0.0'),
      );

      final mbd2 = await Directory('${tempRoot.path}/mbd2').create();
      await _writeSampleMbd(mbd2, version: '1.1.0');
      final bytes2 = await McpBundlePacker.packDirectory(mbd2.path);
      final result = await McpBundleInstaller.installBytes(
        bytes2,
        installRoot: installRoot,
        runtime: const RuntimeDescriptor(version: '1.0.0'),
        policy: const InstallPolicy(
          onConflict: InstallConflictPolicy.skipIfExists,
        ),
      );
      expect(result.version, '1.0.0',
          reason: 'skipIfExists should keep original install');
    });
  });

  group('installDirectory (unpacked .mbd source)', () {
    test('installs an unpacked .mbd/ directly', () async {
      final mbd = await Directory('${tempRoot.path}/mbd').create();
      await _writeSampleMbd(mbd);

      final installed = await McpBundleInstaller.installDirectory(
        mbd.path,
        installRoot: '${tempRoot.path}/installs',
        runtime: const RuntimeDescriptor(version: '1.0.0'),
      );
      expect(installed.id, 'com.example.app');
      expect(
        File('${installed.installPath}/assets/icons/icon.svg').existsSync(),
        isTrue,
      );
    });

    test('rejects a non-existent directory with BundleNotFoundException',
        () async {
      expect(
        () => McpBundleInstaller.installDirectory(
          '${tempRoot.path}/does-not-exist',
          installRoot: '${tempRoot.path}/installs',
          runtime: const RuntimeDescriptor(version: '1.0.0'),
        ),
        throwsA(isA<BundleNotFoundException>()),
      );
    });
  });

  group('installUrl (HTTP source)', () {
    test('downloads bytes and installs', () async {
      final mbd = await Directory('${tempRoot.path}/mbd').create();
      await _writeSampleMbd(mbd);
      final bytes = await McpBundlePacker.packDirectory(mbd.path);

      final client = http_testing.MockClient((req) async {
        expect(req.method, 'GET');
        expect(req.url.toString(), 'https://example.com/app.mcpb');
        return http.Response.bytes(bytes, 200, headers: {
          'content-length': '${bytes.length}',
          'content-type': 'application/octet-stream',
        });
      });

      final installed = await McpBundleInstaller.installUrl(
        Uri.parse('https://example.com/app.mcpb'),
        installRoot: '${tempRoot.path}/installs',
        runtime: const RuntimeDescriptor(version: '1.0.0'),
        client: client,
      );
      expect(installed.id, 'com.example.app');
    });

    test('rejects 404 with BundleNotFoundException', () async {
      final client = http_testing.MockClient((req) async {
        return http.Response('', 404);
      });
      expect(
        () => McpBundleInstaller.installUrl(
          Uri.parse('https://example.com/missing.mcpb'),
          installRoot: '${tempRoot.path}/installs',
          runtime: const RuntimeDescriptor(version: '1.0.0'),
          client: client,
        ),
        throwsA(isA<BundleNotFoundException>()),
      );
    });

    test('rejects non-2xx with BundleReadException', () async {
      final client = http_testing.MockClient((req) async {
        return http.Response('oops', 500, reasonPhrase: 'Server Error');
      });
      expect(
        () => McpBundleInstaller.installUrl(
          Uri.parse('https://example.com/err.mcpb'),
          installRoot: '${tempRoot.path}/installs',
          runtime: const RuntimeDescriptor(version: '1.0.0'),
          client: client,
        ),
        throwsA(isA<BundleReadException>()),
      );
    });

    test('honours Content-Length pre-check against maxCompressedBytes',
        () async {
      final client = http_testing.MockClient((req) async {
        return http.Response.bytes(Uint8List(0), 200, headers: {
          'content-length': '1073741824',
        });
      });
      expect(
        () => McpBundleInstaller.installUrl(
          Uri.parse('https://example.com/huge.mcpb'),
          installRoot: '${tempRoot.path}/installs',
          runtime: const RuntimeDescriptor(version: '1.0.0'),
          client: client,
          policy: const InstallPolicy(
            limits: InstallLimits(maxCompressedBytes: 1024),
          ),
        ),
        throwsA(isA<BundleLimitException>()
            .having((e) => e.limit, 'limit', 'maxCompressedBytes')),
      );
    });

    test('passes custom headers to the request', () async {
      final mbd = await Directory('${tempRoot.path}/mbd').create();
      await _writeSampleMbd(mbd);
      final bytes = await McpBundlePacker.packDirectory(mbd.path);

      Map<String, String>? seen;
      final client = http_testing.MockClient((req) async {
        seen = req.headers;
        return http.Response.bytes(bytes, 200);
      });
      await McpBundleInstaller.installUrl(
        Uri.parse('https://example.com/app.mcpb'),
        installRoot: '${tempRoot.path}/installs',
        runtime: const RuntimeDescriptor(version: '1.0.0'),
        headers: const {'Authorization': 'Bearer TOKEN'},
        client: client,
      );
      expect(seen?['authorization'], 'Bearer TOKEN');
    });
  });

  group('uninstall', () {
    test('removes installed directory and from list', () async {
      final mbd = await Directory('${tempRoot.path}/mbd').create();
      await _writeSampleMbd(mbd);
      final bytes = await McpBundlePacker.packDirectory(mbd.path);

      final installRoot = '${tempRoot.path}/installs';
      final installed = await McpBundleInstaller.installBytes(
        bytes,
        installRoot: installRoot,
        runtime: const RuntimeDescriptor(version: '1.0.0'),
      );
      expect(Directory(installed.installPath).existsSync(), isTrue);

      await McpBundleInstaller.uninstall(installRoot, installed.id);
      expect(Directory(installed.installPath).existsSync(), isFalse);
      final list = await McpBundleInstaller.list(installRoot);
      expect(list, isEmpty);
    });
  });
}
