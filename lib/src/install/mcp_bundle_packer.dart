/// Pack a `.mbd/` tree into a `.mcpb` ZIP container.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../mcp_bundle.dart' show McpBundle;
import '../io/exceptions.dart';
import '../models/integrity.dart' as schema;
import '../utils/canonicalization.dart';
import '../utils/integrity.dart' as hash;
import 'bundle_signer.dart';

/// Produces deterministic `.mcpb` bytes from a `.mbd/` directory.
class McpBundlePacker {
  static const _fixedZipEpoch = 315532800; // 1980-01-01T00:00:00Z
  static const _bundleJsonEntry = 'manifest.json';

  /// Pack [mbdPath] into `.mcpb` bytes.
  ///
  /// When [computeIntegrity] is `true` (default), populates
  /// `McpBundle.integrity` per the scope already declared in
  /// `contentHash`, falling back to `ContentScope.canonicalJson` and
  /// `HashAlgorithm.sha256` when the bundle provides no declaration.
  ///
  /// When [signer] is supplied, appends a detached signature to
  /// `integrity.signatures[]` per the signer's `payloadRefType`.
  static Future<Uint8List> packDirectory(
    String mbdPath, {
    bool computeIntegrity = true,
    BundleSigner? signer,
  }) async {
    final bundleJsonFile = File('$mbdPath${Platform.pathSeparator}$_bundleJsonEntry');
    if (!await bundleJsonFile.exists()) {
      throw BundleNotFoundException(Uri.file(bundleJsonFile.path));
    }
    final decoded =
        jsonDecode(await bundleJsonFile.readAsString()) as Map<String, dynamic>;
    final bundle = McpBundle.fromJson(decoded);
    final integrityUpdated = computeIntegrity || signer != null
        ? _withComputedIntegrity(bundle, mbdPath, signer: signer)
        : bundle;

    final archive = Archive();
    final bundleJsonBytes = _canonicalJsonBytes(integrityUpdated.toJson());
    archive.addFile(_archiveFile(_bundleJsonEntry, bundleJsonBytes));

    final fileEntries = <({String path, Uint8List bytes})>[];
    final dir = Directory(mbdPath);
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final rel = _relativeForward(mbdPath, entity.path);
        if (rel == _bundleJsonEntry) continue;
        final bytes = await entity.readAsBytes();
        fileEntries.add((path: rel, bytes: bytes));
      }
    }
    fileEntries.sort((a, b) => a.path.compareTo(b.path));
    for (final e in fileEntries) {
      archive.addFile(_archiveFile(e.path, e.bytes));
    }

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw StateError('ZipEncoder returned null');
    }
    return Uint8List.fromList(encoded);
  }

  static ArchiveFile _archiveFile(String name, List<int> bytes) {
    // Raw uncompressed bytes; archive package compresses on encode.
    final f = ArchiveFile(name, bytes.length, bytes);
    f.compress = true;
    f.lastModTime = _fixedZipEpoch;
    f.mode = 420; // 0644
    f.ownerId = 0;
    f.groupId = 0;
    return f;
  }

  static String _relativeForward(String root, String child) {
    final rootAbs = Directory(root).absolute.path;
    final childAbs = File(child).absolute.path;
    var rel = childAbs.substring(rootAbs.length);
    if (rel.startsWith(Platform.pathSeparator)) {
      rel = rel.substring(Platform.pathSeparator.length);
    }
    return rel.replaceAll(r'\', '/');
  }

  /// Compute `contentHash` / `files[]` / `signatures[]` per the scope
  /// already declared in the bundle.
  static McpBundle _withComputedIntegrity(
    McpBundle bundle,
    String mbdPath, {
    BundleSigner? signer,
  }) {
    final declared = bundle.integrity?.contentHash;
    final scope = declared?.scope ?? schema.ContentScope.canonicalJson;
    final algorithm = _mapAlgorithm(
      declared?.algorithm ?? schema.HashAlgorithm.sha256,
    );

    final contentBytes = _payloadForScope(bundle, mbdPath, scope);
    final contentHashBytes = _digestBytes(algorithm, contentBytes);
    final contentHash = schema.ContentHash(
      algorithm: declared?.algorithm ?? schema.HashAlgorithm.sha256,
      value: _hex(contentHashBytes),
      scope: scope,
      excludedPaths: declared?.excludedPaths ?? const [],
    );

    final signatures = <schema.Signature>[];
    final existing = bundle.integrity?.signatures ?? const <schema.Signature>[];
    signatures.addAll(existing);
    if (signer != null) {
      final payload = _signaturePayload(
        type: signer.payloadRefType,
        contentHashValue: contentHash.value,
        bundle: bundle,
      );
      final signatureBytes = signer.sign(Uint8List.fromList(payload));
      signatures.add(schema.Signature(
        keyId: signer.keyId,
        algorithm: signer.algorithm,
        value: base64.encode(signatureBytes),
        signedPayload: schema.SignedPayloadRef(
          type: signer.payloadRefType,
          hash: _hex(_digestBytes(algorithm, payload)),
          hashAlgorithm: declared?.algorithm ?? schema.HashAlgorithm.sha256,
        ),
      ));
    }

    // `computedAt` is intentionally omitted so that pack output is
    // byte-reproducible for identical inputs. Hosts that want a
    // provenance stamp can add one on top of the sidecar.
    final updated = schema.IntegrityConfig(
      contentHash: contentHash,
      files: bundle.integrity?.files ?? const [],
      signatures: signatures,
    );
    return bundle.copyWith(integrity: updated);
  }

  /// Build the canonical byte payload for the declared [scope].
  static List<int> _payloadForScope(
    McpBundle bundle,
    String mbdPath,
    schema.ContentScope scope,
  ) {
    switch (scope) {
      case schema.ContentScope.canonicalJson:
        return _canonicalBundleBytesWithoutIntegrity(bundle);
      case schema.ContentScope.contentSections:
        return _contentSectionsBytes(bundle);
      case schema.ContentScope.allFiles:
        return _allFilesBytes(mbdPath);
      case schema.ContentScope.custom:
        return _canonicalBundleBytesWithoutIntegrity(bundle);
    }
  }

  static List<int> _canonicalBundleBytesWithoutIntegrity(McpBundle bundle) {
    final json = bundle.toJson();
    json.remove('integrity');
    return _canonicalJsonBytes(json);
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
    final parts = <List<int>>[];
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
    for (final name in sectionOrder) {
      final section = presence[name]!();
      if (section == null) continue;
      parts.add(_canonicalJsonBytes({name: section}));
      parts.add(const [0x00]);
    }
    return parts.expand((e) => e).toList(growable: false);
  }

  static List<int> _allFilesBytes(String mbdPath) {
    final dir = Directory(mbdPath);
    if (!dir.existsSync()) return const [];
    final files = dir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .toList();
    final entries = <({String path, Uint8List bytes})>[];
    for (final f in files) {
      final rel = _relativeForward(mbdPath, f.path);
      if (rel == _bundleJsonEntry) continue;
      entries.add((path: rel, bytes: f.readAsBytesSync()));
    }
    entries.sort((a, b) => a.path.compareTo(b.path));
    final out = <int>[];
    for (final e in entries) {
      out.addAll(utf8.encode(e.path));
      out.add(0x00);
      out.addAll(e.bytes);
      out.add(0x00);
    }
    return out;
  }

  static List<int> _signaturePayload({
    required schema.PayloadRefType type,
    required String contentHashValue,
    required McpBundle bundle,
  }) {
    switch (type) {
      case schema.PayloadRefType.contentHash:
        return utf8.encode(contentHashValue);
      case schema.PayloadRefType.manifest:
        return _canonicalJsonBytes(bundle.manifest.toJson());
      case schema.PayloadRefType.allSections:
        return _contentSectionsBytes(bundle);
      case schema.PayloadRefType.external:
      case schema.PayloadRefType.unknown:
        return utf8.encode(contentHashValue);
    }
  }

  static List<int> _canonicalJsonBytes(dynamic value) {
    return const Canonicalizer().canonicalizeToBytes(value);
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

  static List<int> _digestBytes(hash.HashAlgorithm algorithm, List<int> bytes) {
    return hash.IntegrityChecker(algorithm: algorithm).hashBytes(bytes).bytes;
  }

  static String _hex(List<int> bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}

