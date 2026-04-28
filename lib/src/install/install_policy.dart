/// Caller-selectable install behaviour flags and safety caps.
library;

/// Behaviour when the target `installRoot/<id>/` already exists.
enum InstallConflictPolicy {
  /// Throw `BundleAlreadyInstalledException`.
  failIfExists,

  /// Atomic swap: stage → rename existing aside → rename new into
  /// place → delete the displaced tree.
  replace,

  /// Leave the existing install alone and return its metadata.
  skipIfExists,
}

/// Upper bounds enforced before and during extraction to defend against
/// malformed or hostile `.mcpb` payloads.
class InstallLimits {
  const InstallLimits({
    this.maxCompressedBytes = 64 * 1024 * 1024,
    this.maxUncompressedBytes = 512 * 1024 * 1024,
    this.maxCompressionRatio = 100,
    this.maxEntryCount = 10000,
    this.maxEntryPathLength = 1024,
    this.maxPathDepth = 32,
  });

  /// Maximum total ZIP size on disk / in memory.
  final int maxCompressedBytes;

  /// Maximum total uncompressed size across all entries.
  final int maxUncompressedBytes;

  /// Maximum compression ratio per entry (`uncompressed / compressed`).
  final int maxCompressionRatio;

  /// Maximum number of entries.
  final int maxEntryCount;

  /// Maximum length of any entry's normalised path in characters.
  final int maxEntryPathLength;

  /// Maximum number of path components in any entry.
  final int maxPathDepth;
}

/// Policy flags for a single `install` call.
class InstallPolicy {
  const InstallPolicy({
    this.onConflict = InstallConflictPolicy.replace,
    this.requireIntegrity = true,
    this.requireSignature = false,
    this.limits = const InstallLimits(),
  });

  /// Conflict resolution for a pre-existing install.
  final InstallConflictPolicy onConflict;

  /// When `true`, an install without a parseable `IntegrityConfig` is
  /// rejected; when `false`, integrity is only enforced if declared.
  final bool requireIntegrity;

  /// When `true`, an install without at least one verified signature is
  /// rejected.
  final bool requireSignature;

  /// Safety caps applied to ZIP entries.
  final InstallLimits limits;
}
