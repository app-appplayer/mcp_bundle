/// Ethos Store Port - Ethos persistence and activation.
///
/// Capability-named port per REDESIGN-PLAN.md §3.5. Breaks out the ethos
/// storage from the monolithic `PhilosophyPort` so that adapters can be
/// configured without depending on rule evaluation.
///
/// Provider: `mcp_philosophy` or host.
library;

/// Port for ethos storage.
abstract class EthosStorePort {
  /// Get an ethos record by ID.
  Future<EthosRecord?> getEthos(String id);

  /// Persist an ethos record.
  Future<void> putEthos(EthosRecord ethos);

  /// List stored ethos records.
  Future<List<EthosRecord>> listEthos({int? limit});

  /// Activate the specified ethos as the current default.
  Future<void> activateEthos(String id);

  /// Get the currently active ethos ID (null if none).
  Future<String?> getActiveEthosId();
}

/// Canonical ethos record.
class EthosRecord {
  /// Ethos identifier.
  final String id;

  /// Human-readable name.
  final String name;

  /// Version string.
  final String version;

  /// Opaque ethos payload (rules, principles, priorities).
  final Map<String, dynamic> payload;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Whether this ethos is currently active.
  final bool active;

  const EthosRecord({
    required this.id,
    required this.name,
    required this.version,
    required this.payload,
    required this.createdAt,
    this.active = false,
  });
}

/// Stub implementation for testing.
class StubEthosStorePort implements EthosStorePort {
  const StubEthosStorePort();

  @override
  Future<EthosRecord?> getEthos(String id) async => null;

  @override
  Future<void> putEthos(EthosRecord ethos) async {}

  @override
  Future<List<EthosRecord>> listEthos({int? limit}) async => [];

  @override
  Future<void> activateEthos(String id) async {}

  @override
  Future<String?> getActiveEthosId() async => null;
}
