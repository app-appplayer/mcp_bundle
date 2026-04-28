/// Skill Runtime Port - Skill execution.
///
/// Capability-named port per REDESIGN-PLAN.md §3.3. Supersedes the
/// `ops_ports.SkillPort` legacy contract.
///
/// Provider: `mcp_skill`.
library;

import '../types/skill_result.dart';

/// Port for skill execution.
abstract class SkillRuntimePort {
  /// Execute a skill.
  Future<SkillRunHandle> executeSkill(
    String skillId,
    Map<String, dynamic> inputs, {
    Map<String, dynamic>? context,
  });

  /// Cancel a running skill.
  Future<void> cancel(String runId);
}

/// Handle for an executing or completed skill run.
class SkillRunHandle {
  /// Run identifier.
  final String runId;

  /// Skill identifier.
  final String skillId;

  /// Whether the run is still in progress.
  final bool running;

  /// Final result (null when still running).
  final SkillResult? result;

  /// Start timestamp.
  final DateTime startedAt;

  /// Completion timestamp.
  final DateTime? finishedAt;

  const SkillRunHandle({
    required this.runId,
    required this.skillId,
    required this.running,
    this.result,
    required this.startedAt,
    this.finishedAt,
  });
}

/// Stub implementation for testing.
class StubSkillRuntimePort implements SkillRuntimePort {
  const StubSkillRuntimePort();

  @override
  Future<SkillRunHandle> executeSkill(
    String skillId,
    Map<String, dynamic> inputs, {
    Map<String, dynamic>? context,
  }) async {
    return SkillRunHandle(
      runId: 'stub-${DateTime.now().microsecondsSinceEpoch}',
      skillId: skillId,
      running: false,
      startedAt: DateTime.now(),
      finishedAt: DateTime.now(),
    );
  }

  @override
  Future<void> cancel(String runId) async {}
}
