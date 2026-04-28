/// Skill Registry Port - Bundle registration and discovery.
///
/// Capability-named port per REDESIGN-PLAN.md §3.3.
///
/// Provider: `mcp_skill`.
library;

/// Port for skill bundle registry.
abstract class SkillRegistryPort {
  /// Register a bundle by manifest payload.
  Future<void> registerBundle(BundleDescriptor descriptor);

  /// Get a bundle descriptor by ID.
  Future<BundleDescriptor?> getBundle(String id);

  /// List all registered bundles.
  Future<List<BundleDescriptor>> listBundles();

  /// Unregister a bundle.
  Future<void> unregister(String id);
}

/// Bundle descriptor used by [SkillRegistryPort].
class BundleDescriptor {
  /// Bundle identifier.
  final String id;

  /// Human-readable name.
  final String name;

  /// Version string.
  final String version;

  /// Skill identifiers exposed by the bundle.
  final List<String> skillIds;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const BundleDescriptor({
    required this.id,
    required this.name,
    required this.version,
    this.skillIds = const [],
    this.metadata = const {},
  });
}

/// Stub implementation for testing.
class StubSkillRegistryPort implements SkillRegistryPort {
  const StubSkillRegistryPort();

  @override
  Future<void> registerBundle(BundleDescriptor descriptor) async {}

  @override
  Future<BundleDescriptor?> getBundle(String id) async => null;

  @override
  Future<List<BundleDescriptor>> listBundles() async => [];

  @override
  Future<void> unregister(String id) async {}
}
