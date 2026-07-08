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

/// Optional deletion capability for ethos stores.
///
/// Kept **separate** from [EthosStorePort] on purpose. Adding `deleteEthos` to
/// [EthosStorePort] itself would be a breaking change for every implementer
/// (Dart `implements` requires each interface member even when a default body
/// is provided), and — because [EthosStorePort] is re-exported by
/// `mcp_philosophy` / `mcp_knowledge` / `flowbrain` — that break would cascade a
/// republish through most of the package graph (`mcp_io`, `mcp_channel`, …) and
/// everything Studio consumes. A separate capability interface is additive:
/// [EthosStorePort]'s contract is untouched, so nothing existing breaks, and
/// only adapters that actually support deletion opt in.
///
/// Consumers detect support with `store is EthosStoreDelete`:
/// ```dart
/// final store = ...; // EthosStorePort
/// if (store is EthosStoreDelete) await store.deleteEthos(id);
/// ```
///
/// DEFERRED-BREAKING (recorded): when the next genuinely-breaking `mcp_bundle`
/// change is batched, `deleteEthos` may be folded into [EthosStorePort] as a
/// required member and this capability interface retired — paying the re-export
/// cascade once. Until then it stays a separate, additive capability.
abstract interface class EthosStoreDelete {
  /// Delete an ethos record by ID. Idempotent — deleting an absent id is a
  /// no-op (does not throw). If the deleted id was the active ethos, the active
  /// pointer is cleared (`getActiveEthosId` → null afterward).
  Future<void> deleteEthos(String id);
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

  /// Construct from a JSON map. `payload` is preserved as-is. `active`
  /// defaults to false when absent. `createdAt` parses ISO-8601 strings;
  /// missing values fall back to `DateTime.now()` so corrupt records do
  /// not crash callers (they surface as records with synthetic recency
  /// — adapters should validate before re-persisting).
  factory EthosRecord.fromJson(Map<String, dynamic> json) {
    return EthosRecord(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '',
      payload: Map<String, dynamic>.from(
        (json['payload'] as Map?) ?? const {},
      ),
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      active: json['active'] as bool? ?? false,
    );
  }

  /// Serialize to JSON. `createdAt` round-trips as an ISO-8601 string so
  /// adapters using `dart:convert` `jsonEncode` can persist directly.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'active': active,
      };
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
