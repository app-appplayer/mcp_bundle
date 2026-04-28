/// IO Audit Port - Audit trail for all IO device operations.
///
/// Provides an immutable audit log for device commands, policy decisions,
/// emergency stops, and access events. Supports querying and exporting
/// audit records to external systems.
library;

import 'io_device_port.dart';
import 'io_policy_port.dart';

// ============================================================================
// Audit Type
// ============================================================================

/// Type of auditable IO operation.
enum IoAuditType {
  execute,
  emergencyStop,
  readAccess,
  subscribeAccess,
  policyChange;

  /// Parse from string, defaulting to [execute].
  static IoAuditType fromString(String value) {
    return IoAuditType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IoAuditType.execute,
    );
  }
}

// ============================================================================
// Audit Record
// ============================================================================

/// Immutable record of an auditable IO operation.
class IoAuditRecord {
  /// Unique audit record identifier.
  final String id;

  /// Type of auditable operation.
  final IoAuditType type;

  /// Identity of the actor who initiated the operation.
  final String actorId;

  /// Role of the actor (e.g., "skill", "operator", "system").
  final String actorRole;

  /// Command that was executed, if applicable.
  final Command? command;

  /// Target device identifier.
  final String deviceId;

  /// Policy decision for this operation, if applicable.
  final PolicyDecision? policyDecision;

  /// Full policy evaluation trace, if applicable.
  final PolicyTrace? policyTrace;

  /// Result status of the command execution.
  final CommandStatus? resultStatus;

  /// Timestamp when the operation was requested.
  final DateTime requestedAt;

  /// Timestamp when execution began.
  final DateTime? executedAt;

  /// Timestamp when execution completed.
  final DateTime? completedAt;

  /// Device state snapshot before the operation.
  final Map<String, dynamic>? stateBefore;

  /// Device state snapshot after the operation.
  final Map<String, dynamic>? stateAfter;

  /// Additional metadata for the audit record.
  final Map<String, dynamic>? metadata;

  IoAuditRecord({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorRole,
    this.command,
    required this.deviceId,
    this.policyDecision,
    this.policyTrace,
    this.resultStatus,
    required this.requestedAt,
    this.executedAt,
    this.completedAt,
    this.stateBefore,
    this.stateAfter,
    this.metadata,
  });

  /// Create from JSON.
  factory IoAuditRecord.fromJson(Map<String, dynamic> json) {
    return IoAuditRecord(
      id: json['id'] as String,
      type: IoAuditType.fromString(json['type'] as String),
      actorId: json['actorId'] as String,
      actorRole: json['actorRole'] as String,
      command: json['command'] != null
          ? Command.fromJson(json['command'] as Map<String, dynamic>)
          : null,
      deviceId: json['deviceId'] as String,
      policyDecision: json['policyDecision'] != null
          ? PolicyDecision.fromJson(
              json['policyDecision'] as Map<String, dynamic>)
          : null,
      policyTrace: json['policyTrace'] != null
          ? PolicyTrace.fromJson(json['policyTrace'] as Map<String, dynamic>)
          : null,
      resultStatus: json['resultStatus'] != null
          ? CommandStatus.fromString(json['resultStatus'] as String)
          : null,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      executedAt: json['executedAt'] != null
          ? DateTime.parse(json['executedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      stateBefore: json['stateBefore'] as Map<String, dynamic>?,
      stateAfter: json['stateAfter'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'actorId': actorId,
        'actorRole': actorRole,
        if (command != null) 'command': command!.toJson(),
        'deviceId': deviceId,
        if (policyDecision != null)
          'policyDecision': policyDecision!.toJson(),
        if (policyTrace != null) 'policyTrace': policyTrace!.toJson(),
        if (resultStatus != null) 'resultStatus': resultStatus!.name,
        'requestedAt': requestedAt.toIso8601String(),
        if (executedAt != null) 'executedAt': executedAt!.toIso8601String(),
        if (completedAt != null)
          'completedAt': completedAt!.toIso8601String(),
        if (stateBefore != null) 'stateBefore': stateBefore,
        if (stateAfter != null) 'stateAfter': stateAfter,
        if (metadata != null) 'metadata': metadata,
      };
}

// ============================================================================
// Audit Query
// ============================================================================

/// Filter criteria for querying audit records.
class IoAuditQuery {
  /// Filter by device identifier.
  final String? deviceId;

  /// Filter by actor identifier.
  final String? actorId;

  /// Filter by audit type.
  final IoAuditType? type;

  /// Start of time range (inclusive).
  final DateTime? from;

  /// End of time range (inclusive).
  final DateTime? to;

  /// Maximum number of records to return.
  final int? limit;

  /// Number of records to skip for pagination.
  final int? offset;

  const IoAuditQuery({
    this.deviceId,
    this.actorId,
    this.type,
    this.from,
    this.to,
    this.limit,
    this.offset,
  });

  /// Create from JSON.
  factory IoAuditQuery.fromJson(Map<String, dynamic> json) {
    return IoAuditQuery(
      deviceId: json['deviceId'] as String?,
      actorId: json['actorId'] as String?,
      type: json['type'] != null
          ? IoAuditType.fromString(json['type'] as String)
          : null,
      from:
          json['from'] != null ? DateTime.parse(json['from'] as String) : null,
      to: json['to'] != null ? DateTime.parse(json['to'] as String) : null,
      limit: json['limit'] as int?,
      offset: json['offset'] as int?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        if (deviceId != null) 'deviceId': deviceId,
        if (actorId != null) 'actorId': actorId,
        if (type != null) 'type': type!.name,
        if (from != null) 'from': from!.toIso8601String(),
        if (to != null) 'to': to!.toIso8601String(),
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      };
}

// ============================================================================
// Audit Export Configuration
// ============================================================================

/// Configuration for exporting audit records to an external system.
class IoAuditExportConfig {
  /// Query filter for selecting records to export.
  final IoAuditQuery query;

  /// Target system identifier (e.g., "mcp_fact_graph", "elasticsearch").
  final String targetSystem;

  /// Additional export options.
  final Map<String, dynamic>? options;

  const IoAuditExportConfig({
    required this.query,
    required this.targetSystem,
    this.options,
  });

  /// Create from JSON.
  factory IoAuditExportConfig.fromJson(Map<String, dynamic> json) {
    return IoAuditExportConfig(
      query: IoAuditQuery.fromJson(json['query'] as Map<String, dynamic>),
      targetSystem: json['targetSystem'] as String,
      options: json['options'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'query': query.toJson(),
        'targetSystem': targetSystem,
        if (options != null) 'options': options,
      };
}

// ============================================================================
// IO Audit Port
// ============================================================================

/// Port for recording and querying IO device audit trails.
abstract class IoAuditPort {
  /// Record an audit entry. Fire-and-forget (non-blocking).
  Future<void> record(IoAuditRecord record);

  /// Query audit records with filters.
  Future<List<IoAuditRecord>> query(IoAuditQuery query);

  /// Export audit records to an external system.
  Future<void> export(IoAuditExportConfig config);
}

// ============================================================================
// Stub Implementation
// ============================================================================

/// In-memory stub for testing audit operations.
class StubIoAuditPort implements IoAuditPort {
  final List<IoAuditRecord> _records = [];

  /// Access recorded entries for test assertions.
  List<IoAuditRecord> get records => List.unmodifiable(_records);

  @override
  Future<void> record(IoAuditRecord record) async {
    _records.add(record);
  }

  @override
  Future<List<IoAuditRecord>> query(IoAuditQuery query) async {
    // Apply basic filters
    return _records.where((r) {
      if (query.deviceId != null && r.deviceId != query.deviceId) return false;
      if (query.actorId != null && r.actorId != query.actorId) return false;
      if (query.type != null && r.type != query.type) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> export(IoAuditExportConfig config) async {
    // No-op in stub
  }

  /// Clear all recorded audit entries.
  void clear() {
    _records.clear();
  }
}
