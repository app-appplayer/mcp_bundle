/// Transactional mutation API for `.mbd/` directory trees.
///
/// Wraps the load → mutate → write cycle in three layered guards:
///
/// 1. **In-process mutex** — per-`mbdPath` FIFO queue. Two concurrent
///    [McpBundleMutator.mutate] calls in the same isolate observe a
///    consistent snapshot. Required because the rest of the API is
///    plain stateless static calls.
/// 2. **OS file lock (opt-in)** — `RandomAccessFile.lock` on a hidden
///    `.mbd-lock` sentinel. Required when other processes (host shell
///    GUI, headless mcp-server, external LLM via MCP) might mutate
///    the same bundle. Off by default so the common single-process
///    path stays free of fs syscalls.
/// 3. **Optimistic checksum** — sha256 of `manifest.json` captured at
///    load time and verified just before write. Catches the residual
///    race where another writer slipped between mutex release and
///    file-lock acquire, or where the OS file lock is unavailable on
///    the host filesystem. Surfaces as [BundleMutationException] with
///    `reason: 'conflict'` so the caller can retry from a fresh load.
///
/// The mutation closure returns a [MutationOutcome]: a `null`
/// `updated` bundle skips the write entirely (read-only inspection
/// inside a guarded scope still benefits from the mutex), and any
/// thrown error aborts before the write — disk stays untouched.
library;

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../models/bundle.dart';
import 'mcp_bundle_loader.dart';
import 'mcp_bundle_writer.dart';
import 'exceptions.dart';

/// Result returned from a [McpBundleMutator.mutate] closure.
///
/// `updated == null` signals a no-op — the disk write is skipped. Use
/// to abort cleanly when the inspection step determines the requested
/// mutation is a no-op without raising an error.
class MutationOutcome<R> {
  const MutationOutcome({this.updated, required this.result});
  final McpBundle? updated;
  final R result;
}

/// Reason discriminator on [BundleMutationException].
enum BundleMutationReason {
  /// Another caller held the per-`mbdPath` mutex longer than the
  /// caller-supplied timeout.
  timeout,

  /// Could not acquire the OS file lock — usually because another
  /// process already holds it, or the filesystem does not support
  /// advisory locking.
  lockFailed,

  /// Disk-side `manifest.json` changed between load and write —
  /// another writer raced through despite the locks.
  conflict,
}

/// Failure raised from [McpBundleMutator.mutate] when one of the
/// three transaction guards trips. Reuses [BundleWriteException]'s
/// URI plumbing so callers handling either exception family see a
/// consistent shape.
class BundleMutationException extends BundleWriteException {
  BundleMutationException(
    super.message, {
    super.uri,
    required this.reason,
  });

  final BundleMutationReason reason;

  @override
  String toString() => 'BundleMutationException($reason): $message';
}

/// Transactional mutation entry point. See library doc for the three
/// guard layers.
class McpBundleMutator {
  /// Load → mutate → write under transaction. Returns the closure's
  /// `result` field.
  ///
  /// - [mbdPath] absolute path to the `.mbd/` directory.
  /// - [fn] mutation closure. Receives the freshly-loaded bundle,
  ///   returns a [MutationOutcome] (`updated` = bundle to write or
  ///   null to skip; `result` = caller-defined value).
  /// - [timeout] mutex acquire timeout. Throws
  ///   [BundleMutationException] (`reason: timeout`) when exceeded.
  /// - [useFileLock] enable OS-level advisory lock against other
  ///   processes. Off by default — single-process callers pay no fs
  ///   syscall for the lock file.
  /// - [indent] forwarded to [McpBundleWriter.writeManifest] on
  ///   successful commit.
  /// - [options] forwarded to [McpBundleLoader.loadDirectory] —
  ///   pass `McpLoaderOptions(strict: false)` to mutate bundles
  ///   that violate strict-mode invariants (e.g. legacy bundles
  ///   missing `schemaVersion`).
  ///
  /// Mutation closure errors propagate as-is and skip the write.
  /// [BundleMutationException] is thrown for guard failures
  /// (timeout / lockFailed / conflict).
  static Future<R> mutate<R>(
    String mbdPath, {
    required Future<MutationOutcome<R>> Function(McpBundle current) fn,
    Duration timeout = const Duration(seconds: 5),
    bool useFileLock = false,
    int indent = 2,
    McpLoaderOptions? options,
  }) async {
    final dir = Directory(mbdPath);
    final absPath = dir.absolute.path;

    // The mutex must be joined before the first `await`. `protect` takes
    // its queue position synchronously, so anything awaited ahead of it
    // — a directory probe included — lets two callers arrive in the
    // opposite order to the one they were issued in, and the FIFO
    // guarantee silently stops holding. The existence check therefore
    // runs inside the protected body.
    final mutex = _MutexRegistry.get(absPath);
    return mutex.protect<R>(timeout, () async {
      if (!await dir.exists()) {
        throw BundleMutationException(
          'Bundle directory does not exist: $mbdPath',
          uri: Uri.directory(absPath),
          reason: BundleMutationReason.lockFailed,
        );
      }
      RandomAccessFile? lockHandle;
      if (useFileLock) {
        lockHandle = await _acquireFileLock(absPath);
      }
      try {
        final manifestFile = File(
            '$absPath${Platform.pathSeparator}${McpBundleWriter.manifestEntry}');
        if (!await manifestFile.exists()) {
          throw BundleMutationException(
            'manifest.json missing under $absPath',
            uri: Uri.file(manifestFile.path),
            reason: BundleMutationReason.conflict,
          );
        }

        final beforeBytes = await manifestFile.readAsBytes();
        final beforeHash = sha256.convert(beforeBytes).toString();

        final loaded =
            await McpBundleLoader.loadDirectory(absPath, options: options);
        final outcome = await fn(loaded);

        final updated = outcome.updated;
        if (updated == null) return outcome.result;

        // Optimistic check — disk-side manifest must match the
        // snapshot we loaded from. Catches the residual race
        // between mutex release and our re-acquire.
        final currentBytes = await manifestFile.readAsBytes();
        final currentHash = sha256.convert(currentBytes).toString();
        if (currentHash != beforeHash) {
          throw BundleMutationException(
            'manifest.json was modified by another writer during '
            'this mutation (optimistic checksum mismatch)',
            uri: Uri.file(manifestFile.path),
            reason: BundleMutationReason.conflict,
          );
        }

        await McpBundleWriter.writeManifest(updated, absPath, indent: indent);
        return outcome.result;
      } finally {
        if (lockHandle != null) {
          try {
            await lockHandle.unlock();
          } catch (_) {/* best-effort */}
          try {
            await lockHandle.close();
          } catch (_) {/* best-effort */}
        }
      }
    });
  }

  /// Acquire the OS file lock on the `.mbd-lock` sentinel under
  /// [absPath]. Throws [BundleMutationException] (`lockFailed`) when
  /// the lock cannot be taken.
  static Future<RandomAccessFile> _acquireFileLock(String absPath) async {
    final lockPath = '$absPath${Platform.pathSeparator}.mbd-lock';
    final lockFile = File(lockPath);
    RandomAccessFile? handle;
    try {
      handle = await lockFile.open(mode: FileMode.write);
      await handle.lock(FileLock.exclusive);
      return handle;
    } catch (e) {
      try {
        await handle?.close();
      } catch (_) {/* best-effort */}
      throw BundleMutationException(
        'Failed to acquire OS file lock on $lockPath: $e',
        uri: Uri.file(lockPath),
        reason: BundleMutationReason.lockFailed,
      );
    }
  }
}

/// Process-wide registry of per-`mbdPath` mutexes. The map is
/// intentionally never pruned — entries are tiny (one `Future`
/// reference) and unbounded `mbdPath` churn is not a realistic
/// load on an authoring host.
class _MutexRegistry {
  static final Map<String, _Mutex> _mutexes = {};

  static _Mutex get(String key) =>
      _mutexes.putIfAbsent(key, () => _Mutex());
}

/// FIFO mutex built from chained `Future`s. Each `protect` call
/// awaits the previous holder's release, then runs its body, then
/// completes its own future so the next waiter can proceed. Cheap,
/// race-free, no third-party dependency.
class _Mutex {
  Future<void> _last = Future.value();

  Future<T> protect<T>(Duration timeout, Future<T> Function() body) async {
    final myCompleter = Completer<void>();
    final prev = _last;
    _last = myCompleter.future;
    try {
      try {
        await prev.timeout(timeout);
      } on TimeoutException {
        throw BundleMutationException(
          'Timed out waiting for in-process mutex '
          '(${timeout.inMilliseconds}ms)',
          reason: BundleMutationReason.timeout,
        );
      }
      return await body();
    } finally {
      myCompleter.complete();
    }
  }
}
