/// Result type describing a bundle resident under `installRoot`.
library;

import '../io/bundle_file_store.dart';
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
    this.files,
  });

  /// Manifest id of the installed bundle.
  final String id;

  /// Manifest version of the installed bundle.
  final String version;

  /// Where the bundle lives, in its store's own terms — an absolute
  /// path to the `.mbd/` directory for a filesystem install.
  ///
  /// It names a location for diagnostics and for hosts that already know
  /// how to resolve it. Reading the bundle's files goes through [files],
  /// which does not assume this string is a path.
  final String installPath;

  /// Parsed manifest of the installed bundle.
  final BundleManifest manifest;

  /// UTC instant when the sidecar was written.
  final DateTime installedAt;

  /// `keyId` of the signature that was verified at install time, or
  /// `null` when the bundle was unsigned and the install was permitted
  /// by policy.
  final String? signer;

  /// File surface of the installed bundle, when the producing call had
  /// one to hand. `null` on results built by callers that only knew the
  /// path.
  final BundleFileStore? files;
}
