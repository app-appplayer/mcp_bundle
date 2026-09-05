import 'package:mcp_bundle/ports.dart';
import 'package:test/test.dart';

/// The CeLM contract exists to take load off a planning model, locally.
/// These tests hold the shapes that make that true rather than merely
/// describable: a caller names a goal instead of authoring one, an
/// escalation carries a digest instead of a state, an observation carries
/// no confidence, a remote reasoner is recorded as one, and nothing that
/// crosses the boundary is coerced into something it is not.
void main() {
  Matcher refused(String code) =>
      throwsA(isA<AnalysisError>().having((e) => e.code, 'code', code));

  const budget = CelmBudgetUse(
    attemptsSpent: 1,
    attemptsAllowed: 6,
    escalationsSpent: 0,
    escalationsAllowed: 3,
    elapsed: Duration(milliseconds: 250),
  );

  final observed = ObservedConclusion(
    id: 'c1',
    runId: 'r1',
    statement: 'indicator 2 is red',
    at: DateTime.utc(2026, 9, 3),
    inputs: const [
      CelmFieldRef(field: 'panel.indicators[2].color', quality: 0.94),
    ],
  );

  final judged = JudgedConclusion(
    id: 'c2',
    runId: 'r1',
    statement: 'the unit is in fault',
    at: DateTime.utc(2026, 9, 3),
    confidence: 0.88,
    reasoner: 'celm-panel-small@0.1',
    premises: const ['c1'],
  );

  group('CelmGoalRef', () {
    test('a caller names a goal, it does not author one', () {
      const ref = CelmGoalRef(id: 'read_panel', params: {'panel': 'A'});
      expect(ref.id, equals('read_panel'));
      expect(ref.params['panel'], equals('A'));
      // There is no slot for a step graph. Authoring structure is the
      // pack's; a port that accepted one would hand the planner the work
      // this contract removes.
      expect(ref.toJson().keys, equals(['id', 'params']));
    });

    test('round-trips, and omits empty params', () {
      final bare = const CelmGoalRef(id: 'g').toJson();
      expect(bare.containsKey('params'), isFalse);
      final restored = CelmGoalRef.fromJson(
        const CelmGoalRef(id: 'g', params: {'x': 1}).toJson(),
      );
      expect(restored.params['x'], equals(1));
    });

    test('a goal reference without an id is refused', () {
      expect(() => CelmGoalRef.fromJson({}), refused('celm.missing_field'));
    });
  });

  group('observation', () {
    test('a request carries depth, not only scope', () {
      const r = CelmObserveRequest(scope: 'window[3]', depth: CelmDepth.atoms);
      expect(r.depth, equals(CelmDepth.atoms));
      expect(CelmObserveRequest.fromJson(r.toJson()).depth,
          equals(CelmDepth.atoms));
    });

    test('depth defaults to coarse when absent', () {
      expect(const CelmObserveRequest().depth, equals(CelmDepth.coarse));
      expect(CelmObserveRequest.fromJson({}).depth, equals(CelmDepth.coarse));
    });

    test('an unknown depth is refused, not coerced to coarse', () {
      // A misspelt depth that quietly became coarse would pass the
      // manifest's depth check and then resolve every absence as
      // unexamined.
      expect(() => CelmDepth.fromString('atom'), refused('celm.unknown_value'));
      expect(() => CelmObserveRequest.fromJson({'depth': 'microscopic'}),
          refused('celm.unknown_value'));
    });

    test('depth is ordered — deeper coverage satisfies a shallower need', () {
      expect(CelmDepth.atoms.satisfies(CelmDepth.structure), isTrue);
      expect(CelmDepth.structure.satisfies(CelmDepth.structure), isTrue);
      expect(CelmDepth.coarse.satisfies(CelmDepth.structure), isFalse);
    });

    test('coverage says what was examined', () {
      final o = CelmObservation(
        descriptor: const {'window': <String, dynamic>{}},
        coverage: const [
          CelmCoverage(scope: 'screen', depth: CelmDepth.coarse),
        ],
        at: DateTime.utc(2026, 9, 3),
      );
      final restored = CelmObservation.fromJson(o.toJson());
      expect(restored.coverage.single.scope, equals('screen'));
      expect(restored.coverage.single.depth, equals(CelmDepth.coarse));
    });

    test('an observation with no coverage round-trips as empty', () {
      final o = CelmObservation(
        descriptor: const {},
        coverage: const [],
        at: DateTime.utc(2026),
      );
      expect(o.toJson().containsKey('coverage'), isFalse);
      expect(CelmObservation.fromJson(o.toJson()).coverage, isEmpty);
    });

    test('a coverage entry without a depth is refused', () {
      expect(() => CelmCoverage.fromJson({'scope': 'screen'}),
          refused('celm.missing_field'));
    });
  });

  group('conclusions keep measurement and inference apart', () {
    test('an observation carries no confidence — it is a fact', () {
      final json = observed.toJson();
      expect(json['provenance'], equals('observed'));
      expect(json.containsKey('confidence'), isFalse);
    });

    test('a judgment names its reasoner and its premises', () {
      final json = judged.toJson();
      expect(json['provenance'], equals('judged'));
      expect(json['confidence'], equals(0.88));
      expect(json['reasoner'], equals('celm-panel-small@0.1'));
      expect(json['premises'], equals(['c1']));
    });

    test('a local reasoner is not marked remote', () {
      expect(judged.toJson().containsKey('reasonerRemote'), isFalse);
    });

    test('a remote reasoner is recorded as one', () {
      final remote = JudgedConclusion(
        id: 'c3',
        runId: 'r1',
        statement: 'x',
        at: DateTime.utc(2026),
        confidence: 0.9,
        reasoner: 'planner',
        reasonerRemote: true,
      );
      expect(remote.toJson()['reasonerRemote'], isTrue,
          reason: 'a domain judgment made off-box is a bootstrap, and the '
              'record says so rather than letting it pass for the '
              'arrangement this contract is for');
      expect(JudgedConclusion.fromJson(remote.toJson()).reasonerRemote, isTrue);
    });

    test('the two are separate types, so a consumer cannot conflate them', () {
      final all = <CelmConclusion>[observed, judged];
      expect(all.whereType<ObservedConclusion>(), hasLength(1));
      expect(all.whereType<JudgedConclusion>(), hasLength(1));
    });

    test('both round-trip', () {
      expect(ObservedConclusion.fromJson(observed.toJson()).inputs.single.field,
          equals('panel.indicators[2].color'));
      expect(
          JudgedConclusion.fromJson(judged.toJson()).confidence, equals(0.88));
    });

    test('decoding dispatches on provenance', () {
      expect(CelmConclusion.fromJson(observed.toJson()),
          isA<ObservedConclusion>());
      expect(CelmConclusion.fromJson(judged.toJson()), isA<JudgedConclusion>());
    });

    test('a judged record cannot come back as an observation', () {
      // The separation has to survive a store. A judged record fed to the
      // observation factory would become standalone evidence — exactly the
      // conflation the two types exist to make impossible.
      expect(() => ObservedConclusion.fromJson(judged.toJson()),
          refused('celm.provenance_mismatch'));
      expect(() => JudgedConclusion.fromJson(observed.toJson()),
          refused('celm.provenance_mismatch'));
    });

    test('a record without provenance is refused', () {
      final bare = Map<String, dynamic>.from(observed.toJson())
        ..remove('provenance');
      expect(
          () => CelmConclusion.fromJson(bare), refused('celm.missing_field'));
      expect(() => ObservedConclusion.fromJson(bare),
          refused('celm.missing_field'));
    });

    test('an unknown provenance is refused', () {
      final odd = Map<String, dynamic>.from(observed.toJson())
        ..['provenance'] = 'guessed';
      expect(() => CelmConclusion.fromJson(odd), refused('celm.unknown_value'));
    });

    test('a judgment without a reasoner or a confidence is refused', () {
      final noReasoner = Map<String, dynamic>.from(judged.toJson())
        ..remove('reasoner');
      expect(() => JudgedConclusion.fromJson(noReasoner),
          refused('celm.missing_field'));
      final noConfidence = Map<String, dynamic>.from(judged.toJson())
        ..remove('confidence');
      expect(() => JudgedConclusion.fromJson(noConfidence),
          refused('celm.missing_field'));
    });

    test('evidence round-trips with a mixed chain', () {
      final e = CelmEvidence(conclusion: judged, chain: [observed]);
      final restored = CelmEvidence.fromJson(e.toJson());
      expect(restored.conclusion, isA<JudgedConclusion>());
      expect(restored.chain.single, isA<ObservedConclusion>());
    });
  });

  group('escalation hands up a digest, not a state', () {
    const digest = CelmDigest(
      relevant: [CelmFieldRef(field: 'window.title', quality: 0.4)],
      coverage: [CelmCoverage(scope: 'screen', depth: CelmDepth.coarse)],
      knowledge: [
        CelmReferenceRef(
          id: 'nominal',
          field: 'panel.voltage',
          expected: {'value': 3.3, 'unit': 'V'},
        ),
      ],
    );

    test('a digest carries the fields the check reads', () {
      final json = digest.toJson();
      expect(json.keys, containsAll(['relevant', 'coverage', 'knowledge']));
      // No descriptor slot: what the planner must read is bounded by the
      // blocked check, not by the size of the screen.
      expect(json.containsKey('descriptor'), isFalse);
    });

    test('a digest round-trips', () {
      final restored = CelmDigest.fromJson(digest.toJson());
      expect(restored.relevant.single.field, equals('window.title'));
      expect(restored.knowledge.single.expected['unit'], equals('V'));
    });

    test('an empty digest emits nothing and decodes from nothing', () {
      expect(const CelmDigest().toJson(), isEmpty);
      expect(CelmDigest.fromJson({}).relevant, isEmpty);
    });

    test('reasons are distinguished because the response differs', () {
      expect(
        CelmEscalationReason.values.map((e) => e.name),
        containsAll([
          'lowConfidence',
          'unobservable',
          'budgetExhausted',
          'irreversibleGate',
          'preconditionFailed',
          'noProgress',
        ]),
      );
    });

    test('an unknown reason is refused, not read as low confidence', () {
      expect(() => CelmEscalationReason.fromString('nonsense'),
          refused('celm.unknown_value'));
      expect(() => CelmRefusalReason.fromString('nonsense'),
          refused('celm.unknown_value'));
    });
  });

  group('outcomes', () {
    final outcomes = <CelmOutcome>[
      CelmCompleted('r', budget: budget, conclusions: [observed, judged]),
      CelmEscalated(
        'r',
        reason: CelmEscalationReason.unobservable,
        digest: CelmDigest(),
        blockedAt: 's1',
        budget: budget,
        history: [
          CelmAttempt(
            step: 's1',
            action: 'hid.key',
            result: 'unobservable',
            why: 'window[3] not covered',
            at: DateTime.utc(2026),
          ),
        ],
      ),
      CelmCancelled('r', stoppedAt: 's2', conclusions: [observed]),
      const CelmRefused(
        'r',
        reason: CelmRefusalReason.goalUnknown,
        detail: 'no goal "x"',
      ),
    ];

    test('four outcomes, distinguishable', () {
      expect(outcomes.whereType<CelmCompleted>(), hasLength(1));
      expect(outcomes.whereType<CelmEscalated>(), hasLength(1));
      expect(outcomes.whereType<CelmCancelled>(), hasLength(1));
      expect(outcomes.whereType<CelmRefused>(), hasLength(1));
    });

    test('every outcome crosses a wire and comes back as itself', () {
      // The port surface is an MCP tool surface. A result that cannot be
      // serialized cannot be a tool result.
      for (final o in outcomes) {
        final restored = CelmOutcome.fromJson(o.toJson());
        expect(restored.runtimeType, equals(o.runtimeType));
        expect(restored.runId, equals('r'));
      }
    });

    test('a completed outcome keeps its conclusions apart across the wire', () {
      final restored = CelmOutcome.fromJson(outcomes[0].toJson());
      final c = (restored as CelmCompleted).conclusions;
      expect(c[0], isA<ObservedConclusion>());
      expect(c[1], isA<JudgedConclusion>());
      expect(
          restored.budget.elapsed, equals(const Duration(milliseconds: 250)));
    });

    test('an escalation names where to resume from and what was tried', () {
      final restored =
          CelmOutcome.fromJson(outcomes[1].toJson()) as CelmEscalated;
      expect(restored.blockedAt, equals('s1'));
      expect(restored.reason, equals(CelmEscalationReason.unobservable));
      expect(restored.history.single.why, equals('window[3] not covered'));
    });

    test('a cancelled run keeps what it established', () {
      final restored =
          CelmOutcome.fromJson(outcomes[2].toJson()) as CelmCancelled;
      expect(restored.conclusions, hasLength(1));
    });

    test('an unknown outcome kind is refused', () {
      expect(() => CelmOutcome.fromJson({'outcome': 'maybe', 'runId': 'r'}),
          refused('celm.unknown_value'));
    });
  });

  group('resumption', () {
    test('three shapes, including abandonment', () {
      final rs = <CelmResumption>[
        const ResumeAt('s'),
        const ResumeWith('s', {'path': '/tmp/x'}),
        const Abandon('operator declined'),
      ];
      expect(rs.whereType<ResumeAt>(), hasLength(1));
      expect(
          rs.whereType<ResumeWith>().single.params['path'], equals('/tmp/x'));
      expect(rs.whereType<Abandon>().single.why, equals('operator declined'));
    });

    test('each shape round-trips by kind', () {
      final rs = <CelmResumption>[
        const ResumeAt('s'),
        const ResumeWith('s', {'path': '/tmp/x'}),
        const Abandon('operator declined'),
      ];
      for (final r in rs) {
        expect(CelmResumption.fromJson(r.toJson()).runtimeType,
            equals(r.runtimeType));
      }
      expect(
          (CelmResumption.fromJson(rs[1].toJson()) as ResumeWith)
              .params['path'],
          equals('/tmp/x'));
    });

    test('an unknown kind is refused', () {
      expect(() => CelmResumption.fromJson({'kind': 'retry'}),
          refused('celm.unknown_value'));
    });
  });

  group('constraints only narrow', () {
    test('read-only is off by default and can only be turned on', () {
      expect(const CelmConstraints().readOnly, isFalse);
      expect(const CelmConstraints(readOnly: true).readOnly, isTrue);
    });

    test('round-trips, emitting only what narrows', () {
      expect(const CelmConstraints().toJson(), isEmpty);
      final c = CelmConstraints.fromJson(
        const CelmConstraints(readOnly: true, deadline: Duration(seconds: 5))
            .toJson(),
      );
      expect(c.readOnly, isTrue);
      expect(c.deadline, equals(const Duration(seconds: 5)));
    });
  });

  group('progress', () {
    test('carries the outcome once the run has ended', () {
      final p = CelmProgress(
        runId: 'r',
        currentStep: 'read',
        budget: budget,
        outcome: const CelmRefused('r', reason: CelmRefusalReason.goalUnknown),
      );
      final restored = CelmProgress.fromJson(p.toJson());
      expect(restored.outcome, isA<CelmRefused>());
    });

    test('has no outcome while running', () {
      final p = CelmProgress(runId: 'r', currentStep: 'read', budget: budget);
      expect(p.toJson().containsKey('outcome'), isFalse);
      expect(CelmProgress.fromJson(p.toJson()).outcome, isNull);
    });
  });

  group('StubCelmPort', () {
    test('execute hands back a run id before the outcome', () async {
      final port = StubCelmPort();
      final handle = await port.execute(const CelmGoalRef(id: 'g'));
      expect(handle.runId, isNotEmpty);
      expect(await handle.outcome, isA<CelmCompleted>());
    });

    test('progress on a finished run carries its outcome', () async {
      final port = StubCelmPort();
      final handle = await port.execute(const CelmGoalRef(id: 'g'));
      expect((await port.progress(handle.runId)).outcome, isA<CelmCompleted>());
    });

    test('progress on an unknown run is an error, not a null', () async {
      expect(
        () => StubCelmPort().progress('no-such-run'),
        refused('celm.run_not_found'),
      );
    });

    test('cancel returns a cancelled outcome', () async {
      expect(await StubCelmPort().cancel('r'), isA<CelmCancelled>());
    });

    test('resume continues, and abandon stops', () async {
      final port = StubCelmPort();
      expect(await port.resume('r', const ResumeAt('s')), isA<CelmCompleted>());
      expect(await port.resume('r', const Abandon('no')), isA<CelmCancelled>());
    });

    test('standalone returns observations only', () async {
      expect(await StubCelmPort().standalone('r'),
          isA<List<ObservedConclusion>>());
    });
  });
}
