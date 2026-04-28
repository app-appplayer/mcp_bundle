/// Workflow Port - Workflow execution.
///
/// Capability-named port per REDESIGN-PLAN.md §3.6.
///
/// Provider: `mcp_knowledge_ops`.
library;

/// Port for workflow execution.
abstract class WorkflowPort {
  /// Run a workflow.
  Future<WorkflowRunHandle> runWorkflow(
    String id,
    Map<String, dynamic> input,
  );

  /// Get a workflow run by ID.
  Future<WorkflowRunHandle?> getRun(String runId);

  /// List registered workflows.
  Future<List<WorkflowDescriptor>> listWorkflows();
}

/// Workflow descriptor.
class WorkflowDescriptor {
  /// Workflow identifier.
  final String id;

  /// Workflow name.
  final String name;

  /// Workflow version.
  final String version;

  /// Description.
  final String? description;

  const WorkflowDescriptor({
    required this.id,
    required this.name,
    required this.version,
    this.description,
  });
}

/// Workflow run handle.
class WorkflowRunHandle {
  /// Run identifier.
  final String runId;

  /// Workflow identifier.
  final String workflowId;

  /// Run status ("running" | "succeeded" | "failed" | "cancelled").
  final String status;

  /// Start timestamp.
  final DateTime startedAt;

  /// Completion timestamp.
  final DateTime? finishedAt;

  /// Output payload.
  final Map<String, dynamic>? output;

  /// Error message if failed.
  final String? error;

  const WorkflowRunHandle({
    required this.runId,
    required this.workflowId,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    this.output,
    this.error,
  });
}

/// Stub implementation for testing.
class StubWorkflowPort implements WorkflowPort {
  const StubWorkflowPort();

  @override
  Future<WorkflowRunHandle> runWorkflow(
    String id,
    Map<String, dynamic> input,
  ) async {
    final now = DateTime.now();
    return WorkflowRunHandle(
      runId: 'stub-${now.microsecondsSinceEpoch}',
      workflowId: id,
      status: 'succeeded',
      startedAt: now,
      finishedAt: now,
    );
  }

  @override
  Future<WorkflowRunHandle?> getRun(String runId) async => null;

  @override
  Future<List<WorkflowDescriptor>> listWorkflows() async => [];
}
