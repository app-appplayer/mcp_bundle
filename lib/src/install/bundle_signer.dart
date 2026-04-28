/// Host-provided signing interface.
library;

import 'dart:typed_data';

import '../models/integrity.dart';

/// Implementations sign arbitrary payload bytes with a single key.
///
/// `mcp_bundle` produces the payload per `SignedPayloadRef.type` and
/// asks the signer for the detached signature value. The host is
/// responsible for key storage and algorithm-specific cryptographic
/// operations.
abstract class BundleSigner {
  /// Identifier recorded in `Signature.keyId`.
  String get keyId;

  /// Algorithm recorded in `Signature.algorithm`.
  SignatureAlgorithm get algorithm;

  /// `SignedPayloadRef.type` that identifies which bytes are signed.
  /// Defaults to hashing the bundle's `contentHash` value.
  PayloadRefType get payloadRefType => PayloadRefType.contentHash;

  /// Compute the detached signature for [payload].
  Uint8List sign(Uint8List payload);
}
