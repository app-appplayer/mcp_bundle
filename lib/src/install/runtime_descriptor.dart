/// Caller-declared runtime environment used by
/// `McpBundleInstaller` to evaluate a bundle's `CompatibilityConfig`.
library;

/// Runtime description injected by the host process.
///
/// `mcp_bundle` never discovers these values itself; the host declares
/// both the runtime version it implements and the capability set it
/// exposes, and the installer rejects any bundle whose
/// `CompatibilityConfig` is not satisfied by the provided descriptor.
class RuntimeDescriptor {
  const RuntimeDescriptor({
    required this.version,
    this.features = const <String>{},
  });

  /// Semver string describing the host runtime.
  final String version;

  /// Capability flags the host runtime exposes. Matched against
  /// `CompatibilityConfig.requiredFeatures`.
  final Set<String> features;

  @override
  String toString() => 'RuntimeDescriptor($version, $features)';
}
