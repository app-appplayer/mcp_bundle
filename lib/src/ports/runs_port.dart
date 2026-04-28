/// Runs Port - Skill/pipeline run record storage.
///
/// Capability-named port per REDESIGN-PLAN.md §3.1.
///
/// Provider: `mcp_fact_graph`.
library;

/// Run lifecycle status.
enum RunStatus {
  running,
  completed,
  failed,
  blocked,
  cancelled,
}

/// Port for run record operations.
abstract class RunsPort {
  /// Write a run record.
  Future<void> writeRun(RunRecord record);

  /// Query runs.
  Future<List<RunRecord>> queryRuns(RunQuery query);

  /// Get a run record by ID.
  Future<RunRecord?> getRun(String id);
}

/// Canonical run record.
class RunRecord {
  /// Run identifier.
  final String id;

  /// Workspace identifier.
  final String workspaceId;

  /// Producer identifier (skill ID, pipeline ID, etc.).
  final String producerId;

  /// Producer kind (e.g., `skill`, `pipeline`, `workflow`).
  final String producerKind;

  /// Producer version.
  final String? producerVersion;

  /// Start time.
  final DateTime startedAt;

  /// Finish time.
  final DateTime? finishedAt;

  /// Run status.
  final RunStatus status;

  /// Input values.
  final Map<String, dynamic> inputs;

  /// Output values.
  final Map<String, dynamic>? outputs;

  /// Claim identifiers generated.
  final List<String> claimIds;

  /// Evidence references used.
  final List<String> evidenceRefs;

  const RunRecord({
    required this.id,
    required this.workspaceId,
    required this.producerId,
    required this.producerKind,
    this.producerVersion,
    required this.startedAt,
    this.finishedAt,
    required this.status,
    required this.inputs,
    this.outputs,
    this.claimIds = const [],
    this.evidenceRefs = const [],
  });
}

/// Query descriptor for [RunsPort.queryRuns].
class RunQuery {
  /// Workspace identifier.
  final String workspaceId;

  /// Producer kind filter.
  final String? producerKind;

  /// Producer identifier filter.
  final String? producerId;

  /// Status filter.
  final List<RunStatus>? statuses;

  /// Earliest start time.
  final DateTime? startedAfter;

  /// Latest start time.
  final DateTime? startedBefore;

  /// Maximum results.
  final int? limit;

  const RunQuery({
    required this.workspaceId,
    this.producerKind,
    this.producerId,
    this.statuses,
    this.startedAfter,
    this.startedBefore,
    this.limit,
  });
}

/// Stub implementation for testing.
class StubRunsPort implements RunsPort {
  const StubRunsPort();

  @override
  Future<void> writeRun(RunRecord record) async {}

  @override
  Future<List<RunRecord>> queryRuns(RunQuery query) async => [];

  @override
  Future<RunRecord?> getRun(String id) async => null;
}
