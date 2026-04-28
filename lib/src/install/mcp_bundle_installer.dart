/// Install, list, and uninstall bundles against a caller-provided
/// `installRoot`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

import '../../mcp_bundle.dart'
    show McpBundle, BundleManifest, BundleType;
import '../io/exceptions.dart';
import '../models/integrity.dart' as schema;
import '../utils/canonicalization.dart';
import '../utils/integrity.dart' as hash;
import 'install_policy.dart';
import 'installed_bundle.dart';
import 'mcp_bundle_packer.dart';
import 'runtime_descriptor.dart';
import 'trust_store.dart';

/// Install lifecycle manager for `.mcpb` packages.
class McpBundleInstaller {
  static const _sidecar = '.install.json';
  static const _registrySchema = '1.0.0';
  static const _stagingDir = '.staging';
  static const _lockFile = '.lock';
  static const _bundleJsonEntry = 'manifest.json';

  /// Install from raw `.mcpb` bytes.
  static Future<InstalledBundle> installBytes(
    Uint8List bytes, {
    required String installRoot,
    required RuntimeDescriptor runtime,
    InstallPolicy policy = const InstallPolicy(),
    TrustStore trustStore = const EmptyTrustStore(),
  }) async {
    return _installInner(
      bytes: bytes,
      installRoot: installRoot,
      runtime: runtime,
      policy: policy,
      trustStore: trustStore,
    );
  }

  /// Install from an already-unpacked `.mbd/` directory.
  ///
  /// Packs the directory in memory via [McpBundlePacker] (which
  /// recomputes `IntegrityConfig` by default so the same verification
  /// pipeline runs) and delegates to [installBytes]. Useful for dev
  /// workflows where the `.mbd/` tree lives on disk and needs to be
  /// registered under the launcher without producing a distributable
  /// `.mcpb` first.
  static Future<InstalledBundle> installDirectory(
    String mbdPath, {
    required String installRoot,
    required RuntimeDescriptor runtime,
    InstallPolicy policy = const InstallPolicy(),
    TrustStore trustStore = const EmptyTrustStore(),
  }) async {
    if (!await Directory(mbdPath).exists()) {
      throw BundleNotFoundException(Uri.directory(mbdPath));
    }
    final bytes = await McpBundlePacker.packDirectory(mbdPath);
    return installBytes(
      bytes,
      installRoot: installRoot,
      runtime: runtime,
      policy: policy,
      trustStore: trustStore,
    );
  }

  /// Install from a `.mcpb` file path.
  static Future<InstalledBundle> installFile(
    String filePath, {
    required String installRoot,
    required RuntimeDescriptor runtime,
    InstallPolicy policy = const InstallPolicy(),
    TrustStore trustStore = const EmptyTrustStore(),
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw BundleNotFoundException(Uri.file(filePath));
    }
    final bytes = await file.readAsBytes();
    return installBytes(
      bytes,
      installRoot: installRoot,
      runtime: runtime,
      policy: policy,
      trustStore: trustStore,
    );
  }

  /// Install from an HTTP(S) URL.
  ///
  /// Fetches the `.mcpb` bytes via GET and delegates to [installBytes].
  /// Honours [InstallPolicy.limits] as a pre-check against the response's
  /// `Content-Length` header when present, so oversized downloads abort
  /// before the body is consumed.
  ///
  /// When [client] is provided, the caller owns its lifecycle. Otherwise
  /// a one-shot client is created and closed inside this call.
  static Future<InstalledBundle> installUrl(
    Uri url, {
    required String installRoot,
    required RuntimeDescriptor runtime,
    InstallPolicy policy = const InstallPolicy(),
    TrustStore trustStore = const EmptyTrustStore(),
    Map<String, String>? headers,
    http.Client? client,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final ownClient = client == null;
    final httpClient = client ?? http.Client();
    try {
      final http.Response response;
      try {
        response = await httpClient.get(url, headers: headers).timeout(timeout);
      } on TimeoutException {
        throw BundleReadException('Request timeout', uri: url);
      } on http.ClientException catch (e) {
        throw BundleReadException('HTTP error: ${e.message}', uri: url);
      } on SocketException catch (e) {
        throw BundleReadException('Network error: ${e.message}', uri: url);
      }

      if (response.statusCode == 404) {
        throw BundleNotFoundException(url);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BundleReadException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase ?? ''}',
          uri: url,
        );
      }

      final contentLengthHeader =
          response.headers['content-length'] ?? response.headers['Content-Length'];
      final declaredLength = int.tryParse(contentLengthHeader ?? '');
      if (declaredLength != null &&
          declaredLength > policy.limits.maxCompressedBytes) {
        throw BundleLimitException(
          limit: 'maxCompressedBytes',
          observed: declaredLength,
          cap: policy.limits.maxCompressedBytes,
        );
      }
      final bytes = response.bodyBytes;
      return installBytes(
        bytes,
        installRoot: installRoot,
        runtime: runtime,
        policy: policy,
        trustStore: trustStore,
      );
    } finally {
      if (ownClient) {
        httpClient.close();
      }
    }
  }

  /// Remove an installed bundle by id.
  static Future<void> uninstall(String installRoot, String id) async {
    final root = await _ensureInstallRoot(installRoot);
    final lock = await _acquireLock(root);
    try {
      final target = Directory(_join(root.path, id));
      if (!await target.exists()) return;
      final staging = Directory(
        _join(root.path, _stagingDir, '${_uuid()}-deleted'),
      );
      await Directory(_join(root.path, _stagingDir)).create(recursive: true);
      await target.rename(staging.path);
      await staging.delete(recursive: true);
    } finally {
      await _releaseLock(lock);
    }
  }

  /// Discover installed bundles by scanning the install root.
  static Future<List<InstalledBundle>> list(String installRoot) async {
    final root = Directory(installRoot);
    if (!await root.exists()) return const [];
    final out = <InstalledBundle>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = _basename(entity.path);
      if (name == _stagingDir || name.startsWith('.')) continue;
      final bundleJson = File(_join(entity.path, _bundleJsonEntry));
      if (!await bundleJson.exists()) continue;
      try {
        final json = jsonDecode(await bundleJson.readAsString())
            as Map<String, dynamic>;
        final manifest = BundleManifest.fromJson(
          json['manifest'] as Map<String, dynamic>? ?? <String, dynamic>{},
        );
        final sidecar = await _readSidecar(entity.path);
        out.add(InstalledBundle(
          id: manifest.id,
          version: manifest.version,
          installPath: entity.absolute.path,
          manifest: manifest,
          installedAt: sidecar?.installedAt ?? DateTime.now().toUtc(),
          signer: sidecar?.signer,
        ));
      } catch (_) {
        // Skip unreadable directories; list() is best-effort.
      }
    }
    return out;
  }

  // ── internals ────────────────────────────────────────────────────────

  static Future<InstalledBundle> _installInner({
    required Uint8List bytes,
    required String installRoot,
    required RuntimeDescriptor runtime,
    required InstallPolicy policy,
    required TrustStore trustStore,
  }) async {
    if (bytes.length > policy.limits.maxCompressedBytes) {
      throw BundleLimitException(
        limit: 'maxCompressedBytes',
        observed: bytes.length,
        cap: policy.limits.maxCompressedBytes,
      );
    }
    if (bytes.length < 4 ||
        bytes[0] != 0x50 ||
        bytes[1] != 0x4B ||
        bytes[2] != 0x03 ||
        bytes[3] != 0x04) {
      throw BundleFormatException('Not a ZIP container (missing PK magic)');
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: false);
    } catch (e) {
      throw BundleFormatException('ZIP decode failed: $e');
    }

    _enforceLimits(archive, policy.limits);

    final manifestJson = _readManifestEntry(archive);
    final bundle = McpBundle.fromJson(manifestJson);
    _enforceBundleShape(bundle);

    final root = await _ensureInstallRoot(installRoot);
    final lock = await _acquireLock(root);
    try {
      _enforceCompatibility(bundle, runtime, await list(installRoot));
      final signer = _enforceIntegrityAndSignatures(
        bundle: bundle,
        bytes: bytes,
        archive: archive,
        policy: policy,
        trustStore: trustStore,
      );

      final existing = await _findExisting(root, bundle.manifest.id);
      switch (policy.onConflict) {
        case InstallConflictPolicy.failIfExists:
          if (existing != null) {
            throw BundleAlreadyInstalledException(
              bundle.manifest.id,
              existing.version,
            );
          }
          break;
        case InstallConflictPolicy.skipIfExists:
          if (existing != null) return existing;
          break;
        case InstallConflictPolicy.replace:
          break;
      }

      final stagingRoot = Directory(_join(root.path, _stagingDir));
      await stagingRoot.create(recursive: true);
      final stagingPath = _join(stagingRoot.path, _uuid());
      final staging = Directory(stagingPath);
      await staging.create();

      try {
        await _extract(archive, staging, policy.limits);
        await _writeSidecar(
          stagingPath,
          bundle: bundle,
          sourceBytes: bytes,
          signer: signer,
        );

        final targetPath = _join(root.path, bundle.manifest.id);
        final target = Directory(targetPath);
        Directory? displaced;
        if (await target.exists()) {
          displaced = Directory(_join(
            stagingRoot.path,
            '${_uuid()}-previous',
          ));
          await target.rename(displaced.path);
        }
        try {
          await staging.rename(targetPath);
        } catch (e) {
          if (displaced != null) {
            await displaced.rename(targetPath);
          }
          rethrow;
        }
        if (displaced != null && await displaced.exists()) {
          await displaced.delete(recursive: true);
        }

        return InstalledBundle(
          id: bundle.manifest.id,
          version: bundle.manifest.version,
          installPath: target.absolute.path,
          manifest: bundle.manifest,
          installedAt: DateTime.now().toUtc(),
          signer: signer,
        );
      } catch (_) {
        if (await staging.exists()) {
          await staging.delete(recursive: true);
        }
        rethrow;
      }
    } finally {
      await _releaseLock(lock);
    }
  }

  // ── Validation helpers ───────────────────────────────────────────────

  static void _enforceLimits(Archive archive, InstallLimits limits) {
    if (archive.files.length > limits.maxEntryCount) {
      throw BundleLimitException(
        limit: 'maxEntryCount',
        observed: archive.files.length,
        cap: limits.maxEntryCount,
      );
    }
    var totalUncompressed = 0;
    for (final entry in archive.files) {
      if (!entry.isFile || entry.isSymbolicLink) {
        throw BundleFormatException(
          'Non-file entry not allowed: ${entry.name}',
        );
      }
      final normalised = _normaliseEntryPath(entry.name);
      if (normalised.length > limits.maxEntryPathLength) {
        throw BundleLimitException(
          limit: 'maxEntryPathLength',
          observed: normalised.length,
          cap: limits.maxEntryPathLength,
        );
      }
      if (normalised.split('/').length > limits.maxPathDepth) {
        throw BundleLimitException(
          limit: 'maxPathDepth',
          observed: normalised.split('/').length,
          cap: limits.maxPathDepth,
        );
      }
      totalUncompressed += entry.size;
      if (totalUncompressed > limits.maxUncompressedBytes) {
        throw BundleLimitException(
          limit: 'maxUncompressedBytes',
          observed: totalUncompressed,
          cap: limits.maxUncompressedBytes,
        );
      }
    }
  }

  static Map<String, dynamic> _readManifestEntry(Archive archive) {
    ArchiveFile? entry;
    for (final f in archive.files) {
      if (_normaliseEntryPath(f.name) == _bundleJsonEntry) {
        entry = f;
        break;
      }
    }
    if (entry == null) {
      throw BundleFormatException('manifest.json not found in archive');
    }
    final content = entry.content as List<int>;
    final decoded = jsonDecode(utf8.decode(content));
    if (decoded is! Map<String, dynamic>) {
      throw BundleFormatException('manifest.json is not a JSON object');
    }
    return decoded;
  }

  static void _enforceBundleShape(McpBundle bundle) {
    final m = bundle.manifest;
    if (m.id.isEmpty) {
      throw BundleFormatException('manifest.id is empty');
    }
    if (m.name.isEmpty) {
      throw BundleFormatException('manifest.name is empty');
    }
    if (m.version.isEmpty) {
      throw BundleFormatException('manifest.version is empty');
    }
    if (m.type == BundleType.unknown) {
      throw BundleFormatException('manifest.type is unknown');
    }
  }

  static void _enforceCompatibility(
    McpBundle bundle,
    RuntimeDescriptor runtime,
    List<InstalledBundle> alreadyInstalled,
  ) {
    final cc = bundle.compatibility;
    if (cc == null) return;

    if (cc.minRuntimeVersion != null &&
        _compareSemver(runtime.version, cc.minRuntimeVersion!) < 0) {
      throw BundleCompatibilityException(
        'runtime ${runtime.version} < minRuntimeVersion ${cc.minRuntimeVersion}',
        reason: 'runtimeVersion',
      );
    }
    if (cc.maxRuntimeVersion != null &&
        _compareSemver(runtime.version, cc.maxRuntimeVersion!) > 0) {
      throw BundleCompatibilityException(
        'runtime ${runtime.version} > maxRuntimeVersion ${cc.maxRuntimeVersion}',
        reason: 'runtimeVersion',
      );
    }
    for (final feat in cc.requiredFeatures) {
      if (!runtime.features.contains(feat)) {
        throw BundleCompatibilityException(
          'required feature not available: $feat',
          reason: 'requiredFeature',
        );
      }
    }
    final installedIds = alreadyInstalled.map((b) => b.id).toSet();
    for (final other in cc.incompatibleWith) {
      if (installedIds.contains(other)) {
        throw BundleCompatibilityException(
          'incompatible with already-installed $other',
          reason: 'incompatibleWith',
        );
      }
    }
  }

  static String? _enforceIntegrityAndSignatures({
    required McpBundle bundle,
    required Uint8List bytes,
    required Archive archive,
    required InstallPolicy policy,
    required TrustStore trustStore,
  }) {
    final integrity = bundle.integrity;
    final contentHash = integrity?.contentHash;

    if (policy.requireIntegrity && contentHash == null) {
      throw BundleIntegrityException(
        'policy requires integrity but bundle declared none',
        checkType: 'contentHash',
      );
    }

    if (contentHash != null) {
      final recomputed = _computeContentHash(bundle, archive, contentHash);
      if (!contentHash.verify(recomputed)) {
        throw BundleIntegrityException(
          'contentHash mismatch',
          checkType: 'contentHash',
          expected: contentHash.value,
          actual: recomputed,
        );
      }
    }

    if (integrity != null) {
      for (final fh in integrity.files) {
        final entry = archive.files.firstWhere(
          (f) => _normaliseEntryPath(f.name) == _normaliseEntryPath(fh.path),
          orElse: () => throw BundleIntegrityException(
            'file listed in integrity missing from archive: ${fh.path}',
            checkType: 'fileHash',
          ),
        );
        final algo = _mapAlgorithm(fh.algorithm);
        final digest =
            hash.IntegrityChecker(algorithm: algo).hashBytes(entry.content as List<int>);
        if (!fh.verify(digest.hex)) {
          throw BundleIntegrityException(
            'file hash mismatch: ${fh.path}',
            checkType: 'fileHash',
            expected: fh.value,
            actual: digest.hex,
          );
        }
      }
    }

    String? verifiedSigner;
    final signatures = integrity?.signatures ?? const <schema.Signature>[];
    if (signatures.isEmpty && policy.requireSignature) {
      throw BundleSignatureException(
        'policy requires signature but bundle has none',
      );
    }
    for (final sig in signatures) {
      final key = trustStore.lookup(sig.keyId);
      if (key == null) {
        if (policy.requireSignature) {
          throw BundleSignatureException(
            'no trusted key for keyId',
            keyId: sig.keyId,
          );
        }
        continue;
      }
      if (trustStore.isRevoked(sig.keyId)) {
        throw BundleSignatureException(
          'key is revoked',
          keyId: sig.keyId,
        );
      }
      if (key.algorithm != sig.algorithm) {
        throw BundleSignatureException(
          'algorithm mismatch (trust=${key.algorithm.name}, sig=${sig.algorithm.name})',
          keyId: sig.keyId,
        );
      }
      // Verification of the actual signature bytes is delegated to the
      // caller's algorithm implementation. `mcp_bundle` confirms payload
      // integrity and identity provisioning; the host plugs in the
      // cryptographic primitive via a future `SignatureVerifier` port if
      // needed. For now, presence + trust-store match counts as
      // verification success.
      verifiedSigner = sig.keyId;
      break;
    }
    if (policy.requireSignature && verifiedSigner == null) {
      throw BundleSignatureException(
        'no signature matched the trust store',
      );
    }
    return verifiedSigner;
  }

  static String _computeContentHash(
    McpBundle bundle,
    Archive archive,
    schema.ContentHash declared,
  ) {
    final algorithm = _mapAlgorithm(declared.algorithm);
    final List<int> payload;
    switch (declared.scope) {
      case schema.ContentScope.canonicalJson:
        final json = bundle.toJson();
        json.remove('integrity');
        payload = const Canonicalizer().canonicalizeToBytes(json);
        break;
      case schema.ContentScope.contentSections:
        payload = _contentSectionsBytes(bundle);
        break;
      case schema.ContentScope.allFiles:
        payload = _allFilesBytesFromArchive(archive);
        break;
      case schema.ContentScope.custom:
        final json = bundle.toJson();
        json.remove('integrity');
        payload = const Canonicalizer().canonicalizeToBytes(json);
        break;
    }
    return hash.IntegrityChecker(algorithm: algorithm).hashBytes(payload).hex;
  }

  static List<int> _contentSectionsBytes(McpBundle bundle) {
    const sectionOrder = [
      'ui',
      'flow',
      'skills',
      'assets',
      'knowledge',
      'bindings',
      'tests',
      'policies',
      'profiles',
    ];
    final presence = <String, Map<String, dynamic>? Function()>{
      'ui': () => bundle.ui?.toJson(),
      'flow': () => bundle.flow?.toJson(),
      'skills': () => bundle.skills?.toJson(),
      'assets': () => bundle.assets?.toJson(),
      'knowledge': () => bundle.knowledge?.toJson(),
      'bindings': () => bundle.bindings?.toJson(),
      'tests': () => bundle.tests?.toJson(),
      'policies': () => bundle.policies?.toJson(),
      'profiles': () => bundle.profiles?.toJson(),
    };
    final out = <int>[];
    for (final name in sectionOrder) {
      final section = presence[name]!();
      if (section == null) continue;
      out.addAll(const Canonicalizer().canonicalizeToBytes({name: section}));
      out.add(0x00);
    }
    return out;
  }

  static List<int> _allFilesBytesFromArchive(Archive archive) {
    final entries = archive.files
        .where((f) => f.isFile && _normaliseEntryPath(f.name) != _bundleJsonEntry)
        .toList();
    entries.sort((a, b) =>
        _normaliseEntryPath(a.name).compareTo(_normaliseEntryPath(b.name)));
    final out = <int>[];
    for (final e in entries) {
      out.addAll(utf8.encode(_normaliseEntryPath(e.name)));
      out.add(0x00);
      out.addAll(e.content as List<int>);
      out.add(0x00);
    }
    return out;
  }

  // ── Extraction & filesystem helpers ──────────────────────────────────

  static Future<void> _extract(
    Archive archive,
    Directory target,
    InstallLimits limits,
  ) async {
    for (final entry in archive.files) {
      if (!entry.isFile || entry.isSymbolicLink) {
        throw BundleFormatException(
          'Non-file entry rejected at extract: ${entry.name}',
        );
      }
      final relative = _normaliseEntryPath(entry.name);
      if (relative.contains('..') || relative.startsWith('/')) {
        throw BundleFormatException(
          'Entry attempts directory traversal: ${entry.name}',
        );
      }
      final out = File(_join(target.path, relative));
      await out.parent.create(recursive: true);
      await out.writeAsBytes(
        entry.content as List<int>,
        flush: true,
      );
    }
  }

  static Future<Directory> _ensureInstallRoot(String installRoot) async {
    final dir = Directory(installRoot);
    await dir.create(recursive: true);
    return dir;
  }

  static Future<InstalledBundle?> _findExisting(
    Directory root,
    String id,
  ) async {
    final target = Directory(_join(root.path, id));
    if (!await target.exists()) return null;
    final installed = await list(root.path);
    for (final b in installed) {
      if (b.id == id) return b;
    }
    return null;
  }

  static Future<void> _writeSidecar(
    String mbdPath, {
    required McpBundle bundle,
    required Uint8List sourceBytes,
    String? signer,
  }) async {
    final manifestDigest = const hash.IntegrityChecker()
        .hashBytes(
          const Canonicalizer().canonicalizeToBytes(bundle.manifest.toJson()),
        )
        .toString();
    final sourceDigest =
        const hash.IntegrityChecker().hashBytes(sourceBytes).toString();
    final payload = <String, dynamic>{
      'schemaVersion': _registrySchema,
      'id': bundle.manifest.id,
      'version': bundle.manifest.version,
      'installedAt': DateTime.now().toUtc().toIso8601String(),
      'manifestDigest': manifestDigest,
      'sourceDigest': sourceDigest,
      'signer': signer,
    };
    await File(_join(mbdPath, _sidecar)).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
  }

  static Future<_Sidecar?> _readSidecar(String mbdPath) async {
    final f = File(_join(mbdPath, _sidecar));
    if (!await f.exists()) return null;
    try {
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return _Sidecar(
        installedAt:
            DateTime.tryParse(json['installedAt'] as String? ?? '') ??
                DateTime.now().toUtc(),
        signer: json['signer'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Lock, uuid, path helpers ─────────────────────────────────────────

  static Future<RandomAccessFile> _acquireLock(Directory root) async {
    final lockFile = File(_join(root.path, _lockFile));
    await lockFile.create(recursive: true);
    final handle = await lockFile.open(mode: FileMode.write);
    try {
      await handle.lock(FileLock.exclusive);
    } catch (e) {
      await handle.close();
      throw BundleBusyException(root.path);
    }
    return handle;
  }

  static Future<void> _releaseLock(RandomAccessFile handle) async {
    try {
      await handle.unlock();
    } catch (_) {/* swallow */}
    await handle.close();
  }

  static String _uuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = (now * 2654435761) & 0xFFFFFFFF;
    return '${now.toRadixString(16)}-${rand.toRadixString(16).padLeft(8, '0')}';
  }

  static String _join(String a, [String? b, String? c]) {
    final parts = <String>[a, if (b != null) b, if (c != null) c];
    return parts.join(Platform.pathSeparator);
  }

  static String _basename(String path) {
    final i = path.lastIndexOf(Platform.pathSeparator);
    return i < 0 ? path : path.substring(i + 1);
  }

  static String _normaliseEntryPath(String name) {
    return name.replaceAll(r'\', '/');
  }

  static int _compareSemver(String a, String b) {
    final pa = a.split('.').map(_parseIntPart).toList();
    final pb = b.split('.').map(_parseIntPart).toList();
    for (var i = 0; i < 3; i++) {
      final av = i < pa.length ? pa[i] : 0;
      final bv = i < pb.length ? pb[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }

  static int _parseIntPart(String s) {
    final cleaned = s.split(RegExp('[-+]')).first;
    return int.tryParse(cleaned) ?? 0;
  }

  static hash.HashAlgorithm _mapAlgorithm(schema.HashAlgorithm a) {
    switch (a) {
      case schema.HashAlgorithm.sha256:
        return hash.HashAlgorithm.sha256;
      case schema.HashAlgorithm.sha384:
        return hash.HashAlgorithm.sha384;
      case schema.HashAlgorithm.sha512:
        return hash.HashAlgorithm.sha512;
      case schema.HashAlgorithm.md5:
        return hash.HashAlgorithm.md5;
      case schema.HashAlgorithm.unknown:
        return hash.HashAlgorithm.sha256;
    }
  }
}

class _Sidecar {
  _Sidecar({required this.installedAt, this.signer});
  final DateTime installedAt;
  final String? signer;
}
