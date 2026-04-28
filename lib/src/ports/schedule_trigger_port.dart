/// Schedule Trigger Port - Scheduling and event-driven triggers.
///
/// Capability-named port per REDESIGN-PLAN.md §3.6.
///
/// Provider: `mcp_knowledge_ops`.
library;

/// Port for scheduled and event-based triggers.
abstract class ScheduleTriggerPort {
  /// Schedule a target by cron expression. Returns a schedule ID.
  Future<String> schedule(String cron, ScheduleTarget target);

  /// Fire a trigger on the given target.
  Future<void> trigger(ScheduleTarget target, Map<String, dynamic> event);

  /// Unschedule by schedule ID.
  Future<void> unschedule(String scheduleId);
}

/// Target for a scheduled/triggered action.
class ScheduleTarget {
  /// Target kind (e.g., `workflow`, `pipeline`, `runbook`).
  final String kind;

  /// Target identifier.
  final String id;

  /// Target parameters.
  final Map<String, dynamic> parameters;

  const ScheduleTarget({
    required this.kind,
    required this.id,
    this.parameters = const {},
  });
}

/// Stub implementation for testing.
class StubScheduleTriggerPort implements ScheduleTriggerPort {
  const StubScheduleTriggerPort();

  @override
  Future<String> schedule(String cron, ScheduleTarget target) async {
    return 'stub-sched-${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  Future<void> trigger(
    ScheduleTarget target,
    Map<String, dynamic> event,
  ) async {}

  @override
  Future<void> unschedule(String scheduleId) async {}
}
