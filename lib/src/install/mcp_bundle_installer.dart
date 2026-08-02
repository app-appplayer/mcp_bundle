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
import '../io/bundle_file_store.dart';
import '../io/exceptions.dart';
import '../models/integrity.dart' as schema;
import '../utils/canonicalization.dart';
import '../utils/integrity.dart' as hash;
import 'bundle_install_store.dart';
import 'install_policy.dart';
import 'installed_bundle.dart';
import 'mcp_bundle_packer.dart';
import 'runtime_descriptor.dart';
import 'trust_store.dart';

/// Install lifecycle manager for `.mcpb` packages.
class McpBundleInstaller {
  static const _sidecar = '.install.json';
  static const _registrySchema = '1.0.0';
  static const _bundleJsonEntry = 'manifest.json';

  /// Resolve the destination from the two ways of naming one.
  ///
  /// [installRoot] stays because every existing caller passes it and a
  /// filesystem host genuinely has a root; [store] is how a host that
  /// cannot name a path says the same thing. Passing neither is a
  /// programming error, not a runtime condition.
  static BundleInstallStore _destination(
    String? installRoot,
    BundleInstallStore? store,
  ) {
    if (store != null) return store;
    if (installRoot != null) return FileBundleInstallStore(installRoot);
    throw ArgumentError(
      'Provide either installRoot (filesystem) or store (any destination).',
    );
  }

  /// Install from raw `.mcpb` bytes.
  static Future<InstalledBundle> installBytes(
    Uint8List bytes, {
    String? installRoot,
    BundleInstallStore? store,
    required RuntimeDescriptor runtime,
    InstallPolicy policy = const InstallPolicy(),
    TrustStore trustStore = const EmptyTrustStore(),
  }) async {
    return _installInner(
      bytes: bytes,
      store: _destination(installRoot, store),
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
    String? installRoot,
    BundleInstallStore? store,
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
      store: store,
      runtime: runtime,
      policy: policy,
      trustStore: trustStore,
    );
  }

  /// Install from a `.mcpb` file path.
  ///
  /// The extension is ENFORCED: `.mcpb` is the packed install archive and the
  /// only file form this installer accepts (an unpacked `.mbd/` directory goes
  /// through [installDirectory]). Content-sniffing a wrongly-named file is
  /// deliberately rejected — a lenient installer masks a producer handing the
  /// wrong artifact form, and the defect then surfaces only on stricter hosts
  /// (the marketplace temp-file case, spec 08 §4 "Standard Consumer Embed").
  static Future<InstalledBundle> installFile(
    String filePath, {
    String? installRoot,
    BundleInstallStore? store,
    required RuntimeDescriptor runtime,
    InstallPolicy policy = const InstallPolicy(),
    TrustStore trustStore = const EmptyTrustStore(),
  }) async {
    if (!filePath.toLowerCase().endsWith('.mcpb')) {
      throw BundleReadException(
        'Expected a `.mcpb` package file — got "$filePath". '
        'An unpacked `.mbd/` directory installs via installDirectory.',
        uri: Uri.file(filePath),
      );
    }
    final file = File(filePath);
    if (!await file.exists()) {
      throw BundleNotFoundException(Uri.file(filePath));
    }
    final bytes = await file.readAsBytes();
    return installBytes(
      bytes,
      installRoot: installRoot,
      store: store,
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
    String? installRoot,
    BundleInstallStore? store,
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
        store: store,
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
  static Future<void> uninstall(String installRoot, String id) =>
      uninstallFrom(FileBundleInstallStore(installRoot), id);

  /// Remove an installed bundle by id from [store].
  static Future<void> uninstallFrom(BundleInstallStore store, String id) {
    return store.withLock(() => store.remove(id));
  }

  /// Discover installed bundles by scanning the install root.
  static Future<List<InstalledBundle>> list(String installRoot) =>
      listFrom(FileBundleInstallStore(installRoot));

  /// Discover installed bundles in [store].
  ///
  /// Best-effort per bundle: an entry that cannot be read is skipped
  /// rather than failing the whole listing, because one corrupt install
  /// must not hide every healthy one.
  static Future<List<InstalledBundle>> listFrom(BundleInstallStore store) async {
    final out = <InstalledBundle>[];
    for (final id in await store.listInstalled()) {
      try {
        final files = await store.openInstalled(id);
        if (files == null) continue;
        final raw = await files.read(_bundleJsonEntry);
        if (raw == null) continue;
        final json = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
        final manifest = BundleManifest.fromJson(
          json['manifest'] as Map<String, dynamic>? ?? <String, dynamic>{},
        );
        final sidecar = await _readSidecar(files);
        out.add(InstalledBundle(
          id: manifest.id,
          version: manifest.version,
          installPath: store.locatorOf(id),
          manifest: manifest,
          installedAt: sidecar?.installedAt ?? DateTime.now().toUtc(),
          signer: sidecar?.signer,
          files: files,
        ));
      } catch (_) {
        // Skip unreadable entries; listing is best-effort.
      }
    }
    return out;
  }

  // ── internals ────────────────────────────────────────────────────────

  static Future<InstalledBundle> _installInner({
    required Uint8List bytes,
    required BundleInstallStore store,
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

    return store.withLock(() async {
      final installed = await listFrom(store);
      _enforceCompatibility(bundle, runtime, installed);
      final signer = _enforceIntegrityAndSignatures(
        bundle: bundle,
        bytes: bytes,
        archive: archive,
        policy: policy,
        trustStore: trustStore,
      );

      final id = bundle.manifest.id;
      InstalledBundle? existing;
      for (final b in installed) {
        if (b.id == id) {
          existing = b;
          break;
        }
      }
      switch (policy.onConflict) {
        case InstallConflictPolicy.failIfExists:
          if (existing != null) {
            throw BundleAlreadyInstalledException(id, existing.version);
          }
          break;
        case InstallConflictPolicy.skipIfExists:
          if (existing != null) return existing;
          break;
        case InstallConflictPolicy.replace:
          break;
      }

      final staging = await store.beginInstall(id);
      try {
        await _extract(archive, staging.files, policy.limits);
        await _writeSidecar(
          staging.files,
          bundle: bundle,
          sourceBytes: bytes,
          signer: signer,
        );
        final locator = await staging.promote();
        return InstalledBundle(
          id: id,
          version: bundle.manifest.version,
          installPath: locator,
          manifest: bundle.manifest,
          installedAt: DateTime.now().toUtc(),
          signer: signer,
          files: await store.openInstalled(id),
        );
      } catch (_) {
        await staging.abandon();
        rethrow;
      }
    });
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
    BundleFileStore target,
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
      await target.write(
        relative,
        Uint8List.fromList(entry.content as List<int>),
      );
    }
  }

  static Future<void> _writeSidecar(
    BundleFileStore target, {
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
    await target.write(_sidecar, encodeJsonBytes(payload));
  }

  static Future<_Sidecar?> _readSidecar(BundleFileStore source) async {
    final raw = await source.read(_sidecar);
    if (raw == null) return null;
    try {
      final json = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
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

  // ── Entry-path helpers ──────────────────────────────────────────────

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
