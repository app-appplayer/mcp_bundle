/// Result type describing a bundle resident under `installRoot`.
library;

import '../models/manifest.dart';

/// Installed bundle metadata returned by `install` / `list` /
/// `loadInstalled`.
class InstalledBundle {
  const InstalledBundle({
    required this.id,
    required this.version,
    required this.installPath,
    required this.manifest,
    required this.installedAt,
    this.signer,
  });

  /// Manifest id of the installed bundle.
  final String id;

  /// Manifest version of the installed bundle.
  final String version;

  /// Absolute path to the `.mbd/` directory on disk.
  final String installPath;

  /// Parsed manifest of the installed bundle.
  final BundleManifest manifest;

  /// UTC instant when the sidecar was written.
  final DateTime installedAt;

  /// `keyId` of the signature that was verified at install time, or
  /// `null` when the bundle was unsigned and the install was permitted
  /// by policy.
  final String? signer;
}
