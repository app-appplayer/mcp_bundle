/// Runbook Port - Runbook execution.
///
/// Capability-named port per REDESIGN-PLAN.md §3.6.
///
/// Provider: `mcp_knowledge_ops`.
library;

/// Port for runbook execution.
abstract class RunbookPort {
  /// Execute a runbook.
  Future<RunbookExecution> runRunbook(
    String id,
    Map<String, dynamic> input,
  );

  /// List available runbooks.
  Future<List<RunbookDescriptor>> listRunbooks();
}

/// Runbook descriptor.
class RunbookDescriptor {
  /// Runbook identifier.
  final String id;

  /// Runbook name.
  final String name;

  /// Description.
  final String? description;

  /// Tags for discovery.
  final List<String> tags;

  const RunbookDescriptor({
    required this.id,
    required this.name,
    this.description,
    this.tags = const [],
  });
}

/// Result of a runbook execution.
class RunbookExecution {
  /// Execution identifier.
  final String executionId;

  /// Runbook identifier.
  final String runbookId;

  /// Status.
  final String status;

  /// Output payload.
  final Map<String, dynamic>? output;

  /// Start timestamp.
  final DateTime startedAt;

  /// Finish timestamp.
  final DateTime? finishedAt;

  /// Error message if failed.
  final String? error;

  const RunbookExecution({
    required this.executionId,
    required this.runbookId,
    required this.status,
    this.output,
    required this.startedAt,
    this.finishedAt,
    this.error,
  });
}

/// Stub implementation for testing.
class StubRunbookPort implements RunbookPort {
  const StubRunbookPort();

  @override
  Future<RunbookExecution> runRunbook(
    String id,
    Map<String, dynamic> input,
  ) async {
    final now = DateTime.now();
    return RunbookExecution(
      executionId: 'stub-${now.microsecondsSinceEpoch}',
      runbookId: id,
      status: 'succeeded',
      startedAt: now,
      finishedAt: now,
    );
  }

  @override
  Future<List<RunbookDescriptor>> listRunbooks() async => [];
}
