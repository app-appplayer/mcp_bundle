/// Tests for [McpBundleMutator.mutate] and the partial-write
/// `McpBundleWriter.writeManifest` path.
///
/// D1 — writeManifest leaves reserved files alone.
/// D2 — mutate provides FIFO mutex, optional file lock, and an
///       optimistic checksum check that rejects a racing writer.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mcp_bundle_mutator_test_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  McpBundle minimal({String version = '1.0.0'}) => McpBundle(
        manifest: BundleManifest(
          id: 'com.example.probe',
          name: 'Probe',
          version: version,
        ),
      );

  Future<String> seedBundle() async {
    final mbdPath = '${tmp.path}/probe.mbd';
    await McpBundleWriter.writeDirectory(
      minimal(),
      mbdPath,
      reservedFiles: const {
        BundleFolder.knowledge: {
          'docs/note.md': '# preserved',
        },
      },
    );
    return mbdPath;
  }

  group('D1 — McpBundleWriter.writeManifest', () {
    test('writes manifest.json without touching reserved folder', () async {
      final mbdPath = await seedBundle();
      final preserved = File('$mbdPath/knowledge/docs/note.md');
      final beforeMtime = (await preserved.stat()).modified;
      // Ensure the filesystem clock advances enough for mtime
      // comparison on macOS HFS+ (1-second resolution).
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      await McpBundleWriter.writeManifest(minimal(version: '1.1.0'), mbdPath);

      final root = jsonDecode(
              await File('$mbdPath/manifest.json').readAsString())
          as Map<String, dynamic>;
      final manifestJson = root['manifest'] as Map<String, dynamic>;
      expect(manifestJson['version'], '1.1.0');
      // Reserved file untouched (content + mtime).
      expect(await preserved.readAsString(), '# preserved');
      expect((await preserved.stat()).modified, beforeMtime);
    });

    test('throws when bundle directory missing', () async {
      expect(
        () => McpBundleWriter.writeManifest(minimal(), '${tmp.path}/missing.mbd'),
        throwsA(isA<BundleWriteException>()),
      );
    });
  });

  group('D2 — McpBundleMutator.mutate', () {
    test('commits the mutation closure and persists manifest', () async {
      final mbdPath = await seedBundle();

      final result = await McpBundleMutator.mutate<int>(
        mbdPath,
        fn: (current) async {
          expect(current.manifest.id, 'com.example.probe');
          return MutationOutcome(
            updated: McpBundle(
              manifest: current.manifest.copyWith(name: 'Renamed'),
            ),
            result: 42,
          );
        },
      );

      expect(result, 42);
      final root = jsonDecode(
          await File('$mbdPath/manifest.json').readAsString()) as Map<String, dynamic>;
      expect((root['manifest'] as Map<String, dynamic>)['name'], 'Renamed');
    });

    test('skips write when MutationOutcome.updated is null', () async {
      final mbdPath = await seedBundle();
      final before = await File('$mbdPath/manifest.json').readAsString();

      final result = await McpBundleMutator.mutate<String>(
        mbdPath,
        fn: (_) async => const MutationOutcome(updated: null, result: 'noop'),
      );

      expect(result, 'noop');
      expect(await File('$mbdPath/manifest.json').readAsString(), before);
    });

    test('rethrows mutation closure exception without writing', () async {
      final mbdPath = await seedBundle();
      final before = await File('$mbdPath/manifest.json').readAsString();

      await expectLater(
        McpBundleMutator.mutate<void>(
          mbdPath,
          fn: (_) async => throw StateError('boom'),
        ),
        throwsA(isA<StateError>()),
      );
      expect(await File('$mbdPath/manifest.json').readAsString(), before);
    });

    test('serialises concurrent same-path mutations FIFO', () async {
      final mbdPath = await seedBundle();
      final order = <String>[];

      final f1 = McpBundleMutator.mutate<void>(
        mbdPath,
        fn: (current) async {
          order.add('A:start');
          // Hold the mutex briefly so the second call must queue.
          await Future<void>.delayed(const Duration(milliseconds: 60));
          order.add('A:end');
          return MutationOutcome(
            updated: McpBundle(
              manifest: current.manifest.copyWith(name: 'A'),
            ),
            result: null,
          );
        },
      );
      final f2 = McpBundleMutator.mutate<void>(
        mbdPath,
        fn: (current) async {
          order.add('B:start');
          order.add('B:end');
          return MutationOutcome(
            updated: McpBundle(
              manifest: current.manifest.copyWith(name: 'B'),
            ),
            result: null,
          );
        },
      );

      await Future.wait([f1, f2]);
      expect(order, ['A:start', 'A:end', 'B:start', 'B:end']);

      // B observed A's commit (FIFO + optimistic checksum compatibility).
      final root = jsonDecode(
          await File('$mbdPath/manifest.json').readAsString()) as Map<String, dynamic>;
      expect((root['manifest'] as Map<String, dynamic>)['name'], 'B');
    });

    test('throws timeout when mutex held past timeout', () async {
      final mbdPath = await seedBundle();
      final holdReleased = Completer<void>();

      // First call holds the mutex.
      final holding = McpBundleMutator.mutate<void>(
        mbdPath,
        fn: (current) async {
          await holdReleased.future;
          return MutationOutcome(
            updated: current,
            result: null,
          );
        },
      );

      // Second call should time out.
      await expectLater(
        McpBundleMutator.mutate<void>(
          mbdPath,
          timeout: const Duration(milliseconds: 50),
          fn: (_) async =>
              const MutationOutcome(updated: null, result: null),
        ),
        throwsA(
          isA<BundleMutationException>().having(
              (e) => e.reason, 'reason', BundleMutationReason.timeout),
        ),
      );

      holdReleased.complete();
      await holding;
    });

    test('detects external write between load and commit (conflict)',
        () async {
      final mbdPath = await seedBundle();
      final manifestFile = File('$mbdPath/manifest.json');

      await expectLater(
        McpBundleMutator.mutate<void>(
          mbdPath,
          fn: (current) async {
            // Simulate a racing external writer between load and the
            // committed write. The optimistic checksum should catch it.
            final raw = jsonDecode(await manifestFile.readAsString())
                as Map<String, dynamic>;
            (raw['manifest'] as Map<String, dynamic>)['name'] = 'External';
            await manifestFile.writeAsString(jsonEncode(raw), flush: true);

            return MutationOutcome(
              updated: McpBundle(
                manifest: current.manifest.copyWith(name: 'Mine'),
              ),
              result: null,
            );
          },
        ),
        throwsA(
          isA<BundleMutationException>().having(
              (e) => e.reason, 'reason', BundleMutationReason.conflict),
        ),
      );

      // External value survives — our commit was rejected.
      final root = jsonDecode(await manifestFile.readAsString())
          as Map<String, dynamic>;
      expect((root['manifest'] as Map<String, dynamic>)['name'], 'External');
    });

    test('OS file lock acquires and releases on success path (useFileLock=true)',
        () async {
      final mbdPath = await seedBundle();

      await McpBundleMutator.mutate<void>(
        mbdPath,
        useFileLock: true,
        fn: (current) async => MutationOutcome(
          updated: current,
          result: null,
        ),
      );

      // Lock sentinel was created and the lock released — subsequent
      // mutate must succeed.
      expect(File('$mbdPath/.mbd-lock').existsSync(), isTrue);
      await McpBundleMutator.mutate<void>(
        mbdPath,
        useFileLock: true,
        fn: (current) async => MutationOutcome(
          updated: current,
          result: null,
        ),
      );
    });
  });
}
