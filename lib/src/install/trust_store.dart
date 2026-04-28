/// Caller-provided signature trust abstractions.
library;

import 'dart:typed_data';

import '../models/integrity.dart';

/// A public key the host accepts as a bundle signer.
class TrustedPublicKey {
  const TrustedPublicKey({
    required this.keyId,
    required this.algorithm,
    required this.publicKey,
  });

  /// Identifier matched against `Signature.keyId`.
  final String keyId;

  /// Algorithm this key is bound to.
  final SignatureAlgorithm algorithm;

  /// Raw public key bytes in the algorithm's canonical wire form.
  final Uint8List publicKey;
}

/// Host-controlled trust anchor.
///
/// `mcp_bundle` never persists or fetches keys; hosts inject a populated
/// [TrustStore] per install call and are free to back it with bundled
/// trust roots, OS keychains, TOFU pinning, or remote revocation lists.
abstract class TrustStore {
  /// Return the trusted key for [keyId] or `null` when no key is trusted.
  TrustedPublicKey? lookup(String keyId);

  /// Return `true` when [keyId] has been revoked even if still present.
  bool isRevoked(String keyId);
}

/// Trust store that rejects every signature.
class EmptyTrustStore implements TrustStore {
  const EmptyTrustStore();

  @override
  TrustedPublicKey? lookup(String keyId) => null;

  @override
  bool isRevoked(String keyId) => false;
}

/// Simple in-memory store useful for tests and small hosts.
class InMemoryTrustStore implements TrustStore {
  InMemoryTrustStore({Iterable<TrustedPublicKey> keys = const [], Set<String>? revoked})
      : _keys = {for (final k in keys) k.keyId: k},
        _revoked = revoked ?? <String>{};

  final Map<String, TrustedPublicKey> _keys;
  final Set<String> _revoked;

  @override
  TrustedPublicKey? lookup(String keyId) => _keys[keyId];

  @override
  bool isRevoked(String keyId) => _revoked.contains(keyId);
}
