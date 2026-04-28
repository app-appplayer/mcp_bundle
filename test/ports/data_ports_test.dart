/// Tests for Phase 1b data layer ports (REDESIGN-PLAN.md §3.1).
///
/// Covers: FactsPort, ClaimsPort, EntitiesPort, CandidatesPort,
/// PatternsPort, SummariesPort, RunsPort.
library;

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('FactsPort', () {
    const port = StubFactsPort();

    test('queryFacts returns empty list', () async {
      final result = await port.queryFacts(
        const FactQuery(workspaceId: 'w1'),
      );
      expect(result, isEmpty);
    });

    test('writeFacts accepts batch without throwing', () async {
      await port.writeFacts([
        FactRecord(
          id: 'f1',
          workspaceId: 'w1',
          type: 'observation',
          content: const {'x': 1},
          createdAt: DateTime.now(),
        ),
      ]);
    });

    test('getFact returns null for unknown id', () async {
      expect(await port.getFact('missing'), isNull);
    });

    test('deleteFacts accepts id list', () async {
      await port.deleteFacts(['f1', 'f2']);
    });

    test('FactRecord preserves fields', () {
      final rec = FactRecord(
        id: 'f1',
        workspaceId: 'w',
        type: 't',
        entityId: 'e',
        content: const {'k': 'v'},
        confidence: 0.8,
        evidenceRefs: const ['ev1'],
        createdAt: DateTime(2026, 1, 1),
      );
      expect(rec.id, 'f1');
      expect(rec.confidence, 0.8);
      expect(rec.evidenceRefs, ['ev1']);
    });
  });

  group('ClaimsPort', () {
    const port = StubClaimsPort();

    test('writeClaims accepts empty list', () async {
      await port.writeClaims(const []);
    });

    test('queryClaims returns empty list', () async {
      final result = await port.queryClaims(
        const ClaimQuery(workspaceId: 'w1'),
      );
      expect(result, isEmpty);
    });

    test('validateClaims returns passed report', () async {
      final report = await port.validateClaims(const []);
      expect(report.passed, isTrue);
      expect(report.entries, isEmpty);
    });

    test('getClaim returns null', () async {
      expect(await port.getClaim('missing'), isNull);
    });

    test('updateClaimStatus does not throw', () async {
      await port.updateClaimStatus('c1', ClaimStatus.supported);
    });

    test('ClaimValidationEntry preserves fields', () {
      const entry = ClaimValidationEntry(
        claimId: 'c1',
        status: ClaimStatus.supported,
        supportingRefs: ['e1'],
      );
      expect(entry.claimId, 'c1');
      expect(entry.supportingRefs, ['e1']);
    });
  });

  group('EntitiesPort', () {
    const port = StubEntitiesPort();

    test('getEntity returns null', () async {
      expect(await port.getEntity('missing'), isNull);
    });

    test('linkEntity does not throw', () async {
      await port.linkEntity('a', 'b', 'related');
    });

    test('queryEntities returns empty list', () async {
      final result = await port.queryEntities(
        const EntityQuery(workspaceId: 'w1'),
      );
      expect(result, isEmpty);
    });

    test('mergeEntities returns a record with surviving id', () async {
      final merged = await port.mergeEntities('survivor', 'absorbed');
      expect(merged.id, 'survivor');
    });
  });

  group('CandidatesPort', () {
    const port = StubCandidatesPort();

    test('createCandidates returns ids from records', () async {
      final ids = await port.createCandidates([
        CandidateRecord(
          id: 'c1',
          workspaceId: 'w1',
          type: 'fact-candidate',
          content: const {'k': 'v'},
          createdAt: DateTime.now(),
        ),
      ]);
      expect(ids, ['c1']);
    });

    test('getPendingCandidates returns empty list', () async {
      expect(await port.getPendingCandidates('w1'), isEmpty);
    });

    test('confirm and reject do not throw', () async {
      await port.confirmCandidate('c1');
      await port.rejectCandidate('c2', 'low confidence');
    });

    test('CandidateStatus values complete', () {
      expect(CandidateStatus.values, [
        CandidateStatus.pending,
        CandidateStatus.confirmed,
        CandidateStatus.rejected,
      ]);
    });
  });

  group('PatternsPort', () {
    const port = StubPatternsPort();

    test('storePattern echoes id', () async {
      final id = await port.storePattern(
        PatternRecord(
          id: 'p1',
          workspaceId: 'w1',
          type: 'freq',
          description: 'weekly purchase',
          detectedAt: DateTime.now(),
        ),
      );
      expect(id, 'p1');
    });

    test('queryPatterns returns empty list', () async {
      expect(
        await port.queryPatterns(const PatternQuery(workspaceId: 'w1')),
        isEmpty,
      );
    });

    test('getPattern returns null', () async {
      expect(await port.getPattern('missing'), isNull);
    });
  });

  group('SummariesPort', () {
    const port = StubSummariesPort();

    test('getSummary returns null', () async {
      expect(await port.getSummary('e1', 'daily'), isNull);
    });

    test('refreshSummary returns a record with refreshedAt', () async {
      final rec = await port.refreshSummary('e1', 'daily');
      expect(rec.entityId, 'e1');
      expect(rec.type, 'daily');
      expect(rec.refreshedAt, isNotNull);
    });

    test('markSummariesStale does not throw', () async {
      await port.markSummariesStale(['e1', 'e2']);
    });

    test('getStaleSummaries returns empty list', () async {
      expect(await port.getStaleSummaries(), isEmpty);
    });
  });

  group('RunsPort', () {
    const port = StubRunsPort();

    test('writeRun does not throw', () async {
      await port.writeRun(
        RunRecord(
          id: 'r1',
          workspaceId: 'w1',
          producerId: 'skill-1',
          producerKind: 'skill',
          startedAt: DateTime.now(),
          status: RunStatus.completed,
          inputs: const {'x': 1},
        ),
      );
    });

    test('queryRuns returns empty list', () async {
      expect(
        await port.queryRuns(const RunQuery(workspaceId: 'w1')),
        isEmpty,
      );
    });

    test('getRun returns null', () async {
      expect(await port.getRun('missing'), isNull);
    });

    test('RunStatus values cover lifecycle', () {
      expect(RunStatus.values, hasLength(5));
    });
  });
}
