/// Pipeline Port - Data/ETL pipeline execution.
///
/// Capability-named port per REDESIGN-PLAN.md §3.6.
///
/// Provider: `mcp_knowledge_ops`.
library;

/// Port for pipeline execution.
abstract class PipelinePort {
  /// Run a pipeline.
  Future<PipelineRunHandle> runPipeline(
    String id,
    Map<String, dynamic> input,
  );

  /// Get a pipeline run by ID.
  Future<PipelineRunHandle?> getPipelineRun(String runId);
}

/// Pipeline run handle.
class PipelineRunHandle {
  /// Run identifier.
  final String runId;

  /// Pipeline identifier.
  final String pipelineId;

  /// Run status.
  final String status;

  /// Start timestamp.
  final DateTime startedAt;

  /// Completion timestamp.
  final DateTime? finishedAt;

  /// Output payload.
  final Map<String, dynamic>? output;

  /// Error message if failed.
  final String? error;

  const PipelineRunHandle({
    required this.runId,
    required this.pipelineId,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    this.output,
    this.error,
  });
}

/// Stub implementation for testing.
class StubPipelinePort implements PipelinePort {
  const StubPipelinePort();

  @override
  Future<PipelineRunHandle> runPipeline(
    String id,
    Map<String, dynamic> input,
  ) async {
    final now = DateTime.now();
    return PipelineRunHandle(
      runId: 'stub-${now.microsecondsSinceEpoch}',
      pipelineId: id,
      status: 'succeeded',
      startedAt: now,
      finishedAt: now,
    );
  }

  @override
  Future<PipelineRunHandle?> getPipelineRun(String runId) async => null;
}
