/// Audit Port - Audit trail recording and query.
///
/// Capability-named port per REDESIGN-PLAN.md §3.6.
///
/// Provider: `mcp_knowledge_ops`.
library;

/// Port for audit event recording.
abstract class AuditPort {
  /// Record an audit event.
  Future<void> record(AuditEvent event);

  /// Query audit events.
  Future<List<AuditEvent>> query(AuditFilter filter);
}

/// Canonical audit event.
class AuditEvent {
  /// Event identifier.
  final String id;

  /// Event type (e.g., `skill.executed`, `claim.validated`).
  final String type;

  /// Actor identifier.
  final String? actorId;

  /// Workspace identifier.
  final String? workspaceId;

  /// Structured event payload.
  final Map<String, dynamic> payload;

  /// Event timestamp.
  final DateTime occurredAt;

  const AuditEvent({
    required this.id,
    required this.type,
    this.actorId,
    this.workspaceId,
    this.payload = const {},
    required this.occurredAt,
  });
}

/// Audit query filter.
class AuditFilter {
  /// Event type filter.
  final List<String>? types;

  /// Actor filter.
  final String? actorId;

  /// Workspace filter.
  final String? workspaceId;

  /// Earliest event time.
  final DateTime? since;

  /// Latest event time.
  final DateTime? until;

  /// Maximum results.
  final int? limit;

  const AuditFilter({
    this.types,
    this.actorId,
    this.workspaceId,
    this.since,
    this.until,
    this.limit,
  });
}

/// Stub implementation for testing.
class StubAuditPort implements AuditPort {
  const StubAuditPort();

  @override
  Future<void> record(AuditEvent event) async {}

  @override
  Future<List<AuditEvent>> query(AuditFilter filter) async => [];
}
