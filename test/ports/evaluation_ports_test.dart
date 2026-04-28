/// Tests for Phase 1a/1b evaluation layer ports (REDESIGN-PLAN.md §3.4).
///
/// Covers: AppraisalPort, DecisionPort, MetricsPort, ProfileSummariesPort.
/// Also verifies the MetricsPort (plural) vs MetricPort (singular) naming
/// distinction is preserved.
library;

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('AppraisalPort', () {
    const port = StubAppraisalPort();

    test('appraise returns an empty result for given profileId', () async {
      final result = await port.appraise(
        const ['dim1'],
        const {'profileId': 'p1'},
      );
      expect(result.profileId, 'p1');
      expect(result.metrics, isEmpty);
    });

    test('appraise without profileId falls back to stub', () async {
      final result = await port.appraise(const [], const {});
      expect(result.profileId, 'stub');
    });

    test('getHistory returns empty list (stub override)', () async {
      final hist = await port.getHistory(
        'p1',
        Period.absolute(
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 12, 31),
        ),
      );
      expect(hist, isEmpty);
    });
  });

  group('DecisionPort', () {
    const port = StubDecisionPort();

    test('decide returns a DecisionGuidance with proceed action', () async {
      final guidance = await port.decide('policy-1', const {});
      expect(guidance.action, DecisionAction.proceed);
      expect(guidance.confidence, 0.5);
      expect(guidance.explanation, 'stub decision');
    });
  });

  group('MetricsPort (plural — evaluation layer)', () {
    const port = StubMetricsPort();

    test('getMetric returns null', () async {
      expect(await port.getMetric('m1', 'e1'), isNull);
    });

    test('getMetrics returns empty map', () async {
      expect(await port.getMetrics(const ['a', 'b'], 'e1'), isEmpty);
    });

    test('computeMetric returns a stub result with static source', () async {
      final result = await port.computeMetric(
        const MetricSpec(id: 'm1', entityId: 'e1'),
      );
      expect(result.id, 'm1');
      expect(result.sourceType, MetricSourceType.static_);
      expect(result.confidence, 0.5);
    });
  });

  group('ProfileSummariesPort', () {
    const port = StubProfileSummariesPort();

    test('getProfileSummary returns null', () async {
      expect(await port.getProfileSummary('e1'), isNull);
    });

    test('ProfileSummaryResult preserves fields', () {
      final result = ProfileSummaryResult(
        entityId: 'e1',
        narrative: 'calm and steady',
        dimensionScores: const {'resilience': 0.8},
        generatedAt: DateTime(2026, 4, 11),
      );
      expect(result.dimensionScores['resilience'], 0.8);
    });
  });

  group('MetricsPort vs MetricPort naming distinction', () {
    test('both exported under distinct names', () {
      // Evaluation layer (plural).
      const MetricsPort evaluation = StubMetricsPort();
      // Instrumentation layer (singular).
      // StubMetricPort is the pre-existing instrumentation stub.
      final MetricPort instrumentation = StubMetricPort();
      expect(evaluation, isA<MetricsPort>());
      expect(instrumentation, isA<MetricPort>());
      // They are NOT the same type.
      expect(evaluation is MetricPort, isFalse);
      expect(instrumentation is MetricsPort, isFalse);
    });
  });
}
