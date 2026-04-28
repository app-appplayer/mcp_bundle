/// Tests for Phase 1b ops layer ports (REDESIGN-PLAN.md §3.6).
///
/// Covers: WorkflowPort, PipelinePort, ScheduleTriggerPort, AuditPort,
/// RunbookPort.
library;

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('WorkflowPort', () {
    const port = StubWorkflowPort();

    test('runWorkflow returns a succeeded handle', () async {
      final handle = await port.runWorkflow('wf1', const {'x': 1});
      expect(handle.workflowId, 'wf1');
      expect(handle.status, 'succeeded');
      expect(handle.finishedAt, isNotNull);
    });

    test('getRun returns null', () async {
      expect(await port.getRun('missing'), isNull);
    });

    test('listWorkflows returns empty list', () async {
      expect(await port.listWorkflows(), isEmpty);
    });
  });

  group('PipelinePort', () {
    const port = StubPipelinePort();

    test('runPipeline returns a succeeded handle', () async {
      final handle = await port.runPipeline('pl1', const {});
      expect(handle.pipelineId, 'pl1');
      expect(handle.status, 'succeeded');
    });

    test('getPipelineRun returns null', () async {
      expect(await port.getPipelineRun('missing'), isNull);
    });
  });

  group('ScheduleTriggerPort', () {
    const port = StubScheduleTriggerPort();

    test('schedule returns a stub id', () async {
      final id = await port.schedule(
        '0 0 * * *',
        const ScheduleTarget(kind: 'workflow', id: 'wf1'),
      );
      expect(id, startsWith('stub-sched-'));
    });

    test('trigger does not throw', () async {
      await port.trigger(
        const ScheduleTarget(kind: 'runbook', id: 'rb1'),
        const {'cause': 'manual'},
      );
    });

    test('unschedule does not throw', () async {
      await port.unschedule('sched-1');
    });

    test('ScheduleTarget preserves fields', () {
      const t = ScheduleTarget(
        kind: 'workflow',
        id: 'wf1',
        parameters: {'env': 'prod'},
      );
      expect(t.parameters['env'], 'prod');
    });
  });

  group('AuditPort', () {
    const port = StubAuditPort();

    test('record does not throw', () async {
      await port.record(
        AuditEvent(
          id: 'a1',
          type: 'skill.executed',
          payload: const {'k': 'v'},
          occurredAt: DateTime.now(),
        ),
      );
    });

    test('query returns empty list', () async {
      expect(await port.query(const AuditFilter()), isEmpty);
    });

    test('AuditFilter preserves fields', () {
      const f = AuditFilter(
        types: ['skill.executed'],
        actorId: 'u1',
        workspaceId: 'w1',
        limit: 50,
      );
      expect(f.types, ['skill.executed']);
      expect(f.actorId, 'u1');
      expect(f.limit, 50);
    });
  });

  group('RunbookPort', () {
    const port = StubRunbookPort();

    test('runRunbook returns a succeeded execution', () async {
      final exec = await port.runRunbook('rb1', const {});
      expect(exec.runbookId, 'rb1');
      expect(exec.status, 'succeeded');
      expect(exec.finishedAt, isNotNull);
    });

    test('listRunbooks returns empty list', () async {
      expect(await port.listRunbooks(), isEmpty);
    });

    test('RunbookDescriptor preserves fields', () {
      const d = RunbookDescriptor(
        id: 'rb1',
        name: 'Disk Full Response',
        description: 'Clean up old artifacts',
        tags: ['infra', 'oncall'],
      );
      expect(d.tags, ['infra', 'oncall']);
    });
  });
}
