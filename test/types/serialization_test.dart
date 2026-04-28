/// Comprehensive serialization tests for all types in:
/// skill_result.dart, expression_style.dart, decision_guidance.dart,
/// appraisal_result.dart, profile_result.dart, period.dart, confidence.dart
import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:mcp_bundle/src/ports/llm_port.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Fixed reference values used throughout tests
  // ---------------------------------------------------------------------------
  final fixedNow = DateTime.utc(2025, 6, 15, 12, 0, 0);
  final fixedStart = DateTime.utc(2025, 6, 15, 11, 55, 0);
  final fixedEnd = DateTime.utc(2025, 6, 15, 12, 0, 0);

  // =========================================================================
  // skill_result.dart
  // =========================================================================
  group('SkillResult', () {
    Map<String, dynamic> _makeClaimJson({
      String id = 'claim-1',
      String text = 'Test claim',
    }) {
      return {
        'id': id,
        'workspaceId': 'ws-1',
        'text': text,
        'type': 'fact',
        'evidenceRefs': ['ev-1'],
        'confidence': 0.9,
        'status': 'pending',
      };
    }

    Map<String, dynamic> _makeMetadataJson() {
      return {
        'skillId': 'skill-abc',
        'skillVersion': '1.0.0',
        'procedureId': 'proc-1',
        'startedAt': fixedStart.toIso8601String(),
        'finishedAt': fixedEnd.toIso8601String(),
        'durationMs': 300000,
        'stepsExecuted': 3,
        'toolsCalled': ['tool-a', 'tool-b'],
      };
    }

    Map<String, dynamic> _makeFullJson() {
      return {
        'claims': [_makeClaimJson()],
        'actions': [
          {
            'type': 'notify',
            'description': 'Send notification',
            'toolRef': 'notifier',
            'args': {'channel': 'email'},
            'status': 'pending',
          }
        ],
        'evidenceRefs': ['ev-1', 'ev-2'],
        'rubricScores': [
          {
            'rubricId': 'rubric-1',
            'dimensionScores': {'accuracy': 0.9, 'completeness': 0.8},
            'totalScore': 85.0,
            'grade': 'A',
            'findings': [
              {
                'type': 'strength',
                'dimensionId': 'accuracy',
                'description': 'Highly accurate',
                'evidenceRefs': ['ev-1'],
                'impact': 0.9,
              }
            ],
          }
        ],
        'conflicts': [
          {
            'id': 'conflict-1',
            'type': 'contradiction',
            'description': 'Conflicting claims',
            'claimIds': ['claim-1', 'claim-2'],
            'severity': 'high',
            'resolution': 'Take latest',
          }
        ],
        'confidence': 0.95,
        'asOf': fixedNow.toIso8601String(),
        'policyVersion': 'v2.0',
        'ui': {'widget': 'card'},
        'artifacts': [
          {
            'id': 'art-1',
            'type': 'report',
            'content': 'Report content',
            'mimeType': 'text/plain',
            'fileName': 'report.txt',
            'metadata': {'generated': true},
          }
        ],
        'metadata': _makeMetadataJson(),
      };
    }

    test('fromJson/toJson roundtrip with all fields', () {
      final json = _makeFullJson();
      final result = SkillResult.fromJson(json);
      final roundtripped = SkillResult.fromJson(result.toJson());

      expect(roundtripped.claims.length, equals(1));
      expect(roundtripped.claims.first.id, equals('claim-1'));
      expect(roundtripped.actions!.length, equals(1));
      expect(roundtripped.actions!.first.type, equals('notify'));
      expect(roundtripped.evidenceRefs, equals(['ev-1', 'ev-2']));
      expect(roundtripped.rubricScores!.length, equals(1));
      expect(roundtripped.rubricScores!.first.rubricId, equals('rubric-1'));
      expect(roundtripped.conflicts!.length, equals(1));
      expect(roundtripped.confidence, equals(0.95));
      expect(roundtripped.asOf, equals(fixedNow));
      expect(roundtripped.policyVersion, equals('v2.0'));
      expect(roundtripped.ui, equals({'widget': 'card'}));
      expect(roundtripped.artifacts!.length, equals(1));
      expect(roundtripped.metadata.skillId, equals('skill-abc'));
    });

    test('fromJson handles null/missing optional fields', () {
      final json = {
        'claims': <Map<String, dynamic>>[],
        'evidenceRefs': <String>[],
        'confidence': 0.5,
        'asOf': fixedNow.toIso8601String(),
        'metadata': _makeMetadataJson(),
      };
      final result = SkillResult.fromJson(json);

      expect(result.actions, isNull);
      expect(result.rubricScores, isNull);
      expect(result.conflicts, isNull);
      expect(result.policyVersion, isNull);
      expect(result.ui, isNull);
      expect(result.artifacts, isNull);
    });

    test('isSuccess getter', () {
      final success = SkillResult.fromJson({
        ..._makeFullJson(),
        'confidence': 0.5,
      });
      final failure = SkillResult.fromJson({
        ..._makeFullJson(),
        'confidence': 0.0,
      });

      expect(success.isSuccess, isTrue);
      expect(success.success, isTrue);
      expect(failure.isSuccess, isFalse);
    });

    test('skillId getter delegates to metadata', () {
      final result = SkillResult.fromJson(_makeFullJson());
      expect(result.skillId, equals('skill-abc'));
    });

    test('primaryClaimText getter', () {
      final result = SkillResult.fromJson(_makeFullJson());
      expect(result.primaryClaimText, equals('Test claim'));

      final empty = SkillResult.fromJson({
        'claims': <Map<String, dynamic>>[],
        'evidenceRefs': <String>[],
        'confidence': 0.0,
        'asOf': fixedNow.toIso8601String(),
        'metadata': _makeMetadataJson(),
      });
      expect(empty.primaryClaimText, isNull);
    });

    group('factory constructors', () {
      test('SkillResult.success', () {
        final claim = Claim(
          id: 'c1',
          workspaceId: 'ws',
          text: 'claim text',
          type: ClaimType.fact,
          evidenceRefs: ['ev1'],
          confidence: 0.9,
        );
        final meta = ExecutionMetadata(
          skillId: 'sk',
          skillVersion: '1.0',
          procedureId: 'p1',
          startedAt: fixedStart,
          finishedAt: fixedEnd,
          duration: fixedEnd.difference(fixedStart),
          stepsExecuted: 1,
          toolsCalled: [],
        );
        final result = SkillResult.success(
          claims: [claim],
          evidenceRefs: ['ev1'],
          metadata: meta,
          confidence: 0.85,
          asOf: fixedNow,
          policyVersion: 'v1',
        );

        expect(result.isSuccess, isTrue);
        expect(result.confidence, equals(0.85));
        expect(result.asOf, equals(fixedNow));
        expect(result.policyVersion, equals('v1'));
      });

      test('SkillResult.error', () {
        final meta = ExecutionMetadata(
          skillId: 'sk',
          skillVersion: '1.0',
          procedureId: 'p1',
          startedAt: fixedStart,
          finishedAt: fixedEnd,
          duration: fixedEnd.difference(fixedStart),
          stepsExecuted: 0,
          toolsCalled: [],
        );
        final result = SkillResult.error(
          error: 'Something went wrong',
          metadata: meta,
          workspaceId: 'ws-test',
          asOf: fixedNow,
        );

        expect(result.confidence, equals(0.0));
        expect(result.isSuccess, isFalse);
        expect(result.claims.length, equals(1));
        expect(result.claims.first.text, equals('Something went wrong'));
        expect(result.claims.first.workspaceId, equals('ws-test'));
        expect(result.claims.first.type, equals(ClaimType.conclusion));
      });

      test('SkillResult.failure', () {
        final result = SkillResult.failure(
          skillId: 'fail-skill',
          error: 'Fatal error',
          asOf: fixedNow,
        );

        expect(result.confidence, equals(0.0));
        expect(result.isSuccess, isFalse);
        expect(result.claims, isEmpty);
        expect(result.metadata.skillId, equals('fail-skill'));
        expect(result.metadata.custom, equals({'error': 'Fatal error'}));
      });

      test('SkillResult.empty', () {
        final result = SkillResult.empty(asOf: fixedNow);

        expect(result.claims, isEmpty);
        expect(result.evidenceRefs, isEmpty);
        expect(result.confidence, equals(0.0));
        expect(result.isSuccess, isFalse);
        expect(result.metadata.skillId, isEmpty);
      });

      test('SkillResult.simpleSuccess', () {
        final result = SkillResult.simpleSuccess(
          {'key': 'value'},
          const Duration(seconds: 5),
        );

        expect(result.confidence, equals(1.0));
        expect(result.isSuccess, isTrue);
        expect(result.metadata.duration, equals(const Duration(seconds: 5)));
        expect(result.metadata.custom, equals({'output': {'key': 'value'}}));
      });

      test('SkillResult.simpleSuccess with null output', () {
        final result = SkillResult.simpleSuccess(
          null,
          const Duration(seconds: 2),
        );

        expect(result.metadata.custom, isNull);
      });

      test('SkillResult.simpleError', () {
        final result = SkillResult.simpleError(
          'Timeout',
          const Duration(seconds: 30),
        );

        expect(result.confidence, equals(0.0));
        expect(result.isSuccess, isFalse);
        expect(result.metadata.custom, equals({'error': 'Timeout'}));
        expect(result.metadata.duration, equals(const Duration(seconds: 30)));
      });
    });

    test('toJson omits null optional fields', () {
      final result = SkillResult(
        claims: [],
        evidenceRefs: [],
        confidence: 0.0,
        asOf: fixedNow,
        metadata: ExecutionMetadata(
          skillId: '',
          skillVersion: '',
          procedureId: '',
          startedAt: fixedStart,
          finishedAt: fixedEnd,
          duration: Duration.zero,
          stepsExecuted: 0,
          toolsCalled: [],
        ),
      );
      final json = result.toJson();

      expect(json.containsKey('actions'), isFalse);
      expect(json.containsKey('rubricScores'), isFalse);
      expect(json.containsKey('conflicts'), isFalse);
      expect(json.containsKey('policyVersion'), isFalse);
      expect(json.containsKey('ui'), isFalse);
      expect(json.containsKey('artifacts'), isFalse);
    });
  });

  // =========================================================================
  // SkillAction
  // =========================================================================
  group('SkillAction', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'type': 'execute',
        'description': 'Run tool',
        'toolRef': 'my-tool',
        'args': {'param': 'val'},
        'status': 'executed',
        'result': 'ok',
        'error': null,
      };
      final action = SkillAction.fromJson(json);
      final roundtripped = SkillAction.fromJson(action.toJson());

      expect(roundtripped.type, equals('execute'));
      expect(roundtripped.description, equals('Run tool'));
      expect(roundtripped.toolRef, equals('my-tool'));
      expect(roundtripped.args, equals({'param': 'val'}));
      expect(roundtripped.status, equals(ActionStatus.executed));
      expect(roundtripped.result, equals('ok'));
    });

    test('fromJson with missing fields uses defaults', () {
      final action = SkillAction.fromJson({});
      expect(action.type, equals(''));
      expect(action.description, equals(''));
      expect(action.status, equals(ActionStatus.pending));
      expect(action.toolRef, isNull);
      expect(action.args, isNull);
    });

    test('pending factory', () {
      final action = SkillAction.pending(
        type: 'send',
        description: 'Send email',
        toolRef: 'email-sender',
        args: {'to': 'user@example.com'},
      );

      expect(action.status, equals(ActionStatus.pending));
      expect(action.type, equals('send'));
      expect(action.toolRef, equals('email-sender'));
    });

    test('copyWithStatus', () {
      final pending = SkillAction.pending(
        type: 'task',
        description: 'Process data',
      );

      final executed = pending.copyWithStatus(
        ActionStatus.executed,
        result: {'processed': 42},
      );
      expect(executed.status, equals(ActionStatus.executed));
      expect(executed.result, equals({'processed': 42}));
      expect(executed.type, equals('task'));
      expect(executed.description, equals('Process data'));

      final failed = pending.copyWithStatus(
        ActionStatus.failed,
        error: 'Connection lost',
      );
      expect(failed.status, equals(ActionStatus.failed));
      expect(failed.error, equals('Connection lost'));
    });

    test('toJson omits null optional fields', () {
      final action = SkillAction(
        type: 'x',
        description: 'y',
        status: ActionStatus.pending,
      );
      final json = action.toJson();

      expect(json.containsKey('toolRef'), isFalse);
      expect(json.containsKey('args'), isFalse);
      expect(json.containsKey('result'), isFalse);
      expect(json.containsKey('error'), isFalse);
    });
  });

  // =========================================================================
  // ActionStatus
  // =========================================================================
  group('ActionStatus', () {
    test('fromString for all values', () {
      expect(ActionStatus.fromString('pending'), equals(ActionStatus.pending));
      expect(
          ActionStatus.fromString('executed'), equals(ActionStatus.executed));
      expect(ActionStatus.fromString('failed'), equals(ActionStatus.failed));
      expect(ActionStatus.fromString('skipped'), equals(ActionStatus.skipped));
    });

    test('fromString unknown value defaults to pending', () {
      expect(ActionStatus.fromString('unknown'), equals(ActionStatus.pending));
    });
  });

  // =========================================================================
  // RubricScore
  // =========================================================================
  group('RubricScore', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'rubricId': 'rubric-2',
        'dimensionScores': {'clarity': 0.8, 'depth': 0.7},
        'totalScore': 75.0,
        'grade': 'B',
        'findings': [
          {
            'type': 'weakness',
            'dimensionId': 'depth',
            'description': 'Needs more depth',
            'evidenceRefs': ['ref-1'],
            'impact': 0.6,
          }
        ],
      };
      final score = RubricScore.fromJson(json);
      final roundtripped = RubricScore.fromJson(score.toJson());

      expect(roundtripped.rubricId, equals('rubric-2'));
      expect(roundtripped.dimensionScores, equals({'clarity': 0.8, 'depth': 0.7}));
      expect(roundtripped.totalScore, equals(75.0));
      expect(roundtripped.grade, equals('B'));
      expect(roundtripped.findings!.length, equals(1));
      expect(roundtripped.findings!.first.type, equals('weakness'));
    });

    test('fromJson with missing fields uses defaults', () {
      final score = RubricScore.fromJson({});
      expect(score.rubricId, equals(''));
      expect(score.dimensionScores, isEmpty);
      expect(score.totalScore, equals(0.0));
      expect(score.grade, equals(''));
      expect(score.findings, isNull);
    });

    test('passed getter', () {
      final passing = RubricScore(
        rubricId: 'r1',
        dimensionScores: {},
        totalScore: 60.0,
        grade: 'C',
      );
      final failing = RubricScore(
        rubricId: 'r2',
        dimensionScores: {},
        totalScore: 59.9,
        grade: 'F',
      );

      expect(passing.passed, isTrue);
      expect(failing.passed, isFalse);
    });
  });

  // =========================================================================
  // Finding
  // =========================================================================
  group('Finding', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'type': 'suggestion',
        'dimensionId': 'accuracy',
        'description': 'Consider adding citations',
        'evidenceRefs': ['e1', 'e2'],
        'impact': 0.3,
      };
      final finding = Finding.fromJson(json);
      final roundtripped = Finding.fromJson(finding.toJson());

      expect(roundtripped.type, equals('suggestion'));
      expect(roundtripped.dimensionId, equals('accuracy'));
      expect(roundtripped.description, equals('Consider adding citations'));
      expect(roundtripped.evidenceRefs, equals(['e1', 'e2']));
      expect(roundtripped.impact, equals(0.3));
    });

    test('fromJson with missing fields uses defaults', () {
      final finding = Finding.fromJson({});
      expect(finding.type, equals(''));
      expect(finding.dimensionId, equals(''));
      expect(finding.description, equals(''));
      expect(finding.evidenceRefs, isEmpty);
      expect(finding.impact, isNull);
    });

    test('toJson omits empty evidenceRefs and null impact', () {
      final finding = Finding(
        type: 'strength',
        dimensionId: 'd1',
        description: 'Good',
      );
      final json = finding.toJson();

      expect(json.containsKey('evidenceRefs'), isFalse);
      expect(json.containsKey('impact'), isFalse);
    });
  });

  // =========================================================================
  // Conflict
  // =========================================================================
  group('Conflict', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'id': 'c-1',
        'type': 'contradiction',
        'description': 'Claims contradict',
        'claimIds': ['claim-a', 'claim-b'],
        'severity': 'high',
        'resolution': 'Prefer latest',
      };
      final conflict = Conflict.fromJson(json);
      final roundtripped = Conflict.fromJson(conflict.toJson());

      expect(roundtripped.id, equals('c-1'));
      expect(roundtripped.type, equals('contradiction'));
      expect(roundtripped.description, equals('Claims contradict'));
      expect(roundtripped.claimIds, equals(['claim-a', 'claim-b']));
      expect(roundtripped.severity, equals('high'));
      expect(roundtripped.resolution, equals('Prefer latest'));
    });

    test('fromJson with missing fields uses defaults', () {
      final conflict = Conflict.fromJson({});
      expect(conflict.id, equals(''));
      expect(conflict.severity, equals('medium'));
      expect(conflict.resolution, isNull);
    });

    test('toJson omits null resolution', () {
      final conflict = Conflict(
        id: 'c',
        type: 't',
        description: 'd',
        claimIds: [],
        severity: 'low',
      );
      expect(conflict.toJson().containsKey('resolution'), isFalse);
    });
  });

  // =========================================================================
  // Artifact
  // =========================================================================
  group('Artifact', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'id': 'art-1',
        'type': 'document',
        'content': 'Hello World',
        'mimeType': 'text/plain',
        'fileName': 'hello.txt',
        'metadata': {'size': 11},
      };
      final artifact = Artifact.fromJson(json);
      final roundtripped = Artifact.fromJson(artifact.toJson());

      expect(roundtripped.id, equals('art-1'));
      expect(roundtripped.type, equals('document'));
      expect(roundtripped.content, equals('Hello World'));
      expect(roundtripped.mimeType, equals('text/plain'));
      expect(roundtripped.fileName, equals('hello.txt'));
      expect(roundtripped.metadata, equals({'size': 11}));
    });

    test('fromJson with missing optional fields', () {
      final artifact = Artifact.fromJson({'content': 'data'});
      expect(artifact.id, equals(''));
      expect(artifact.type, equals(''));
      expect(artifact.mimeType, isNull);
      expect(artifact.fileName, isNull);
      expect(artifact.metadata, isNull);
    });

    test('toJson omits null optional fields', () {
      final artifact = Artifact(id: 'a', type: 't', content: 'c');
      final json = artifact.toJson();

      expect(json.containsKey('mimeType'), isFalse);
      expect(json.containsKey('fileName'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });
  });

  // =========================================================================
  // ExecutionMetadata
  // =========================================================================
  group('ExecutionMetadata', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'skillId': 'skill-x',
        'skillVersion': '2.0.0',
        'procedureId': 'proc-2',
        'startedAt': fixedStart.toIso8601String(),
        'finishedAt': fixedEnd.toIso8601String(),
        'durationMs': 300000,
        'stepsExecuted': 5,
        'llmUsage': {'inputTokens': 100, 'outputTokens': 200},
        'toolsCalled': ['tool-1'],
        'custom': {'key': 'value'},
      };
      final meta = ExecutionMetadata.fromJson(json);
      final roundtripped = ExecutionMetadata.fromJson(meta.toJson());

      expect(roundtripped.skillId, equals('skill-x'));
      expect(roundtripped.skillVersion, equals('2.0.0'));
      expect(roundtripped.procedureId, equals('proc-2'));
      expect(roundtripped.startedAt, equals(fixedStart));
      expect(roundtripped.finishedAt, equals(fixedEnd));
      expect(roundtripped.duration.inMilliseconds, equals(300000));
      expect(roundtripped.stepsExecuted, equals(5));
      expect(roundtripped.llmUsage!.inputTokens, equals(100));
      expect(roundtripped.llmUsage!.outputTokens, equals(200));
      expect(roundtripped.toolsCalled, equals(['tool-1']));
      expect(roundtripped.custom, equals({'key': 'value'}));
    });

    test('fromJson with missing fields uses defaults', () {
      final meta = ExecutionMetadata.fromJson({});
      expect(meta.skillId, equals(''));
      expect(meta.skillVersion, equals(''));
      expect(meta.procedureId, equals(''));
      expect(meta.duration.inMilliseconds, equals(0));
      expect(meta.stepsExecuted, equals(0));
      expect(meta.llmUsage, isNull);
      expect(meta.toolsCalled, isEmpty);
      expect(meta.custom, isNull);
    });

    test('create factory computes duration', () {
      final meta = ExecutionMetadata.create(
        skillId: 'sk-1',
        skillVersion: '1.0',
        procedureId: 'p-1',
        startedAt: fixedStart,
        finishedAt: fixedEnd,
        stepsExecuted: 3,
        toolsCalled: ['t1'],
        custom: {'x': 1},
      );

      expect(meta.duration, equals(fixedEnd.difference(fixedStart)));
      expect(meta.duration.inMinutes, equals(5));
      expect(meta.startedAt, equals(fixedStart));
      expect(meta.finishedAt, equals(fixedEnd));
    });

    test('create factory with LlmUsage', () {
      final usage = LlmUsage(inputTokens: 50, outputTokens: 75);
      final meta = ExecutionMetadata.create(
        skillId: 'sk',
        skillVersion: '1.0',
        procedureId: 'p',
        startedAt: fixedStart,
        finishedAt: fixedEnd,
        stepsExecuted: 1,
        llmUsage: usage,
      );

      expect(meta.llmUsage, isNotNull);
      expect(meta.llmUsage!.inputTokens, equals(50));
      expect(meta.llmUsage!.totalTokens, equals(125));
    });

    test('toJson omits null optional fields', () {
      final meta = ExecutionMetadata(
        skillId: 's',
        skillVersion: 'v',
        procedureId: 'p',
        startedAt: fixedStart,
        finishedAt: fixedEnd,
        duration: Duration.zero,
        stepsExecuted: 0,
        toolsCalled: [],
      );
      final json = meta.toJson();

      expect(json.containsKey('llmUsage'), isFalse);
      expect(json.containsKey('custom'), isFalse);
    });
  });

  // =========================================================================
  // StepResult
  // =========================================================================
  group('StepResult', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'stepId': 'step-1',
        'result': {'data': 'value'},
        'claims': [
          {
            'id': 'c-1',
            'workspaceId': 'ws',
            'text': 'Step claim',
            'type': 'fact',
            'evidenceRefs': <String>[],
            'confidence': 0.8,
          }
        ],
        'evidenceRefs': ['ev-1'],
        'toolCalled': 'my-tool',
        'metadata': {'step_key': 'step_value'},
      };
      final step = StepResult.fromJson(json);
      final roundtripped = StepResult.fromJson(step.toJson());

      expect(roundtripped.stepId, equals('step-1'));
      expect(roundtripped.result, equals({'data': 'value'}));
      expect(roundtripped.claims.length, equals(1));
      expect(roundtripped.evidenceRefs, equals(['ev-1']));
      expect(roundtripped.toolCalled, equals('my-tool'));
      expect(roundtripped.metadata, equals({'step_key': 'step_value'}));
    });

    test('fromJson with missing fields', () {
      final step = StepResult.fromJson({});
      expect(step.stepId, equals(''));
      expect(step.result, isNull);
      expect(step.claims, isEmpty);
      expect(step.evidenceRefs, isEmpty);
      expect(step.toolCalled, isNull);
      expect(step.metadata, isNull);
    });

    test('toJson omits empty/null optional fields', () {
      final step = StepResult(stepId: 's1', result: 42);
      final json = step.toJson();

      expect(json.containsKey('claims'), isFalse);
      expect(json.containsKey('evidenceRefs'), isFalse);
      expect(json.containsKey('toolCalled'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });
  });

  // =========================================================================
  // expression_style.dart
  // =========================================================================
  group('ExpressionStyle', () {
    Map<String, dynamic> _makeToneJson() {
      return {
        'formality': 'formal',
        'confidence': 'assertive',
        'empathy': 'high',
        'directness': 'direct',
      };
    }

    Map<String, dynamic> _makeFormatJson() {
      return {
        'structure': 'bullets',
        'length': 'concise',
        'includeEvidence': true,
        'includeCaveats': true,
        'includeAlternatives': true,
        'includeNextSteps': true,
        'maxParagraphs': 5,
        'maxBullets': 10,
      };
    }

    Map<String, dynamic> _makeFullStyleJson() {
      return {
        'tone': _makeToneJson(),
        'format': _makeFormatJson(),
        'hedging': {
          'level': 'moderate',
          'phrases': {
            'high_uncertainty': ['Perhaps...'],
            'moderate_uncertainty': ['It seems...'],
            'low_uncertainty': ['Clearly...'],
            'qualifying': ['however'],
            'probabilistic': ['likely'],
          },
          'position': 'start',
        },
        'audience': {
          'expertise': 'expert',
          'context': 'external',
          'role': 'analyst',
          'preferences': {
            'preferredFormat': 'table',
            'avoidJargon': true,
            'includeDefinitions': true,
            'visualPreference': 'diagrams',
          },
        },
        'language': {
          'locale': 'en-US',
          'vocabulary': {
            'avoidWords': ['basically', 'obviously'],
            'preferredTerms': {'utilize': 'use'},
            'jargonLevel': 'technical',
          },
          'grammar': {
            'voicePreference': 'passive',
            'sentenceComplexity': 'complex',
            'useContractions': true,
          },
        },
        'metadata': {'theme': 'dark'},
      };
    }

    test('fromJson/toJson roundtrip with all fields', () {
      final json = _makeFullStyleJson();
      final style = ExpressionStyle.fromJson(json);
      final roundtripped = ExpressionStyle.fromJson(style.toJson());

      // Tone
      expect(roundtripped.tone.formality, equals(Formality.formal));
      expect(roundtripped.tone.confidence, equals(ToneConfidence.assertive));
      expect(roundtripped.tone.empathy, equals(Empathy.high));
      expect(roundtripped.tone.directness, equals(Directness.direct));

      // Format
      expect(roundtripped.format.structure, equals(Structure.bullets));
      expect(roundtripped.format.length, equals(Length.concise));
      expect(roundtripped.format.includeEvidence, isTrue);
      expect(roundtripped.format.includeCaveats, isTrue);
      expect(roundtripped.format.includeAlternatives, isTrue);
      expect(roundtripped.format.includeNextSteps, isTrue);
      expect(roundtripped.format.maxParagraphs, equals(5));
      expect(roundtripped.format.maxBullets, equals(10));

      // Hedging
      expect(roundtripped.hedging!.level, equals(HedgingLevel.moderate));
      expect(roundtripped.hedging!.position, equals(HedgingPosition.start));
      expect(roundtripped.hedging!.phrases!.highUncertainty, equals(['Perhaps...']));
      expect(roundtripped.hedging!.phrases!.moderateUncertainty, equals(['It seems...']));
      expect(roundtripped.hedging!.phrases!.lowUncertainty, equals(['Clearly...']));
      expect(roundtripped.hedging!.phrases!.qualifying, equals(['however']));
      expect(roundtripped.hedging!.phrases!.probabilistic, equals(['likely']));

      // Audience
      expect(roundtripped.audience!.expertise, equals(Expertise.expert));
      expect(roundtripped.audience!.context, equals(AudienceContext.external));
      expect(roundtripped.audience!.role, equals('analyst'));
      expect(roundtripped.audience!.preferences!.preferredFormat, equals('table'));
      expect(roundtripped.audience!.preferences!.avoidJargon, isTrue);
      expect(roundtripped.audience!.preferences!.includeDefinitions, isTrue);
      expect(roundtripped.audience!.preferences!.visualPreference,
          equals(VisualPreference.diagrams));

      // Language
      expect(roundtripped.language!.locale, equals('en-US'));
      expect(roundtripped.language!.vocabulary!.avoidWords,
          equals(['basically', 'obviously']));
      expect(roundtripped.language!.vocabulary!.preferredTerms,
          equals({'utilize': 'use'}));
      expect(roundtripped.language!.vocabulary!.jargonLevel,
          equals(JargonLevel.technical));
      expect(roundtripped.language!.grammar!.voicePreference,
          equals(VoicePreference.passive));
      expect(roundtripped.language!.grammar!.sentenceComplexity,
          equals(SentenceComplexity.complex));
      expect(roundtripped.language!.grammar!.useContractions, isTrue);

      // Metadata
      expect(roundtripped.metadata, equals({'theme': 'dark'}));
    });

    test('fromJson with only required fields', () {
      final style = ExpressionStyle.fromJson({
        'tone': {
          'formality': 'neutral',
          'confidence': 'moderate',
          'empathy': 'moderate',
          'directness': 'balanced',
        },
        'format': {
          'structure': 'prose',
          'length': 'standard',
        },
      });

      expect(style.hedging, isNull);
      expect(style.audience, isNull);
      expect(style.language, isNull);
      expect(style.metadata, isNull);
    });

    test('merge with overrides', () {
      final base = ExpressionStyle.defaultStyle;
      final overrides = ExpressionStyle(
        tone: const ToneConfig(
          formality: Formality.formal,
          confidence: ToneConfidence.assertive,
          empathy: Empathy.low,
          directness: Directness.direct,
        ),
        format: const FormatConfig(
          structure: Structure.bullets,
          length: Length.concise,
        ),
        hedging: const HedgingConfig(level: HedgingLevel.strong),
        metadata: {'custom': true},
      );

      final merged = base.merge(overrides);

      expect(merged.tone.formality, equals(Formality.formal));
      expect(merged.format.structure, equals(Structure.bullets));
      expect(merged.hedging!.level, equals(HedgingLevel.strong));
      expect(merged.metadata, equals({'custom': true}));
    });

    test('merge with null returns self', () {
      final style = ExpressionStyle.defaultStyle;
      expect(identical(style.merge(null), style), isTrue);
    });

    test('merge combines metadata', () {
      final base = ExpressionStyle(
        tone: ToneConfig.neutral,
        format: FormatConfig.defaultFormat,
        metadata: {'a': 1, 'b': 2},
      );
      final overrides = ExpressionStyle(
        tone: ToneConfig.neutral,
        format: FormatConfig.defaultFormat,
        metadata: {'b': 3, 'c': 4},
      );

      final merged = base.merge(overrides);
      expect(merged.metadata, equals({'a': 1, 'b': 3, 'c': 4}));
    });
  });

  // =========================================================================
  // ToneConfig
  // =========================================================================
  group('ToneConfig', () {
    test('fromJson/toJson roundtrip for all enum values', () {
      for (final formality in Formality.values) {
        for (final confidence in ToneConfidence.values) {
          final json = {
            'formality': formality.name,
            'confidence': confidence.name,
            'empathy': 'moderate',
            'directness': 'balanced',
          };
          final config = ToneConfig.fromJson(json);
          expect(config.formality, equals(formality));
          expect(config.confidence, equals(confidence));
        }
      }
    });

    test('fromJson with unknown enum values uses defaults', () {
      final config = ToneConfig.fromJson({
        'formality': 'unknown',
        'confidence': 'unknown',
        'empathy': 'unknown',
        'directness': 'unknown',
      });

      expect(config.formality, equals(Formality.neutral));
      expect(config.confidence, equals(ToneConfidence.moderate));
      expect(config.empathy, equals(Empathy.moderate));
      expect(config.directness, equals(Directness.balanced));
    });

    test('merge replaces all fields', () {
      final base = ToneConfig.neutral;
      final other = const ToneConfig(
        formality: Formality.formal,
        confidence: ToneConfidence.assertive,
        empathy: Empathy.high,
        directness: Directness.direct,
      );

      final merged = base.merge(other);
      expect(merged.formality, equals(Formality.formal));
      expect(merged.confidence, equals(ToneConfidence.assertive));
      expect(merged.empathy, equals(Empathy.high));
      expect(merged.directness, equals(Directness.direct));
    });
  });

  // =========================================================================
  // FormatConfig
  // =========================================================================
  group('FormatConfig', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'structure': 'table',
        'length': 'detailed',
        'includeEvidence': true,
        'includeCaveats': true,
        'includeAlternatives': false,
        'includeNextSteps': true,
        'maxParagraphs': 3,
        'maxBullets': 8,
      };
      final config = FormatConfig.fromJson(json);
      final roundtripped = FormatConfig.fromJson(config.toJson());

      expect(roundtripped.structure, equals(Structure.table));
      expect(roundtripped.length, equals(Length.detailed));
      expect(roundtripped.includeEvidence, isTrue);
      expect(roundtripped.includeCaveats, isTrue);
      expect(roundtripped.includeAlternatives, isFalse);
      expect(roundtripped.includeNextSteps, isTrue);
      expect(roundtripped.maxParagraphs, equals(3));
      expect(roundtripped.maxBullets, equals(8));
    });

    test('fromJson with unknown enum values uses defaults', () {
      final config = FormatConfig.fromJson({
        'structure': 'unknown',
        'length': 'unknown',
      });

      expect(config.structure, equals(Structure.prose));
      expect(config.length, equals(Length.standard));
    });

    test('all Structure enum values roundtrip', () {
      for (final s in Structure.values) {
        final json = {'structure': s.name, 'length': 'standard'};
        final config = FormatConfig.fromJson(json);
        expect(config.structure, equals(s));
      }
    });

    test('all Length enum values roundtrip', () {
      for (final l in Length.values) {
        final json = {'structure': 'prose', 'length': l.name};
        final config = FormatConfig.fromJson(json);
        expect(config.length, equals(l));
      }
    });

    test('merge takes other values, preserves base maxParagraphs/maxBullets if null', () {
      final base = FormatConfig(
        structure: Structure.prose,
        length: Length.standard,
        maxParagraphs: 5,
        maxBullets: 10,
      );
      final other = FormatConfig(
        structure: Structure.bullets,
        length: Length.concise,
        includeEvidence: true,
      );

      final merged = base.merge(other);
      expect(merged.structure, equals(Structure.bullets));
      expect(merged.length, equals(Length.concise));
      expect(merged.includeEvidence, isTrue);
      expect(merged.maxParagraphs, equals(5));
      expect(merged.maxBullets, equals(10));
    });
  });

  // =========================================================================
  // HedgingConfig & HedgingPhrases
  // =========================================================================
  group('HedgingConfig', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'level': 'strong',
        'phrases': {
          'high_uncertainty': ['Maybe...'],
          'qualifying': ['but'],
        },
        'position': 'end',
      };
      final config = HedgingConfig.fromJson(json);
      final roundtripped = HedgingConfig.fromJson(config.toJson());

      expect(roundtripped.level, equals(HedgingLevel.strong));
      expect(roundtripped.position, equals(HedgingPosition.end));
      expect(roundtripped.phrases!.highUncertainty, equals(['Maybe...']));
      expect(roundtripped.phrases!.qualifying, equals(['but']));
    });

    test('all HedgingLevel enum values roundtrip', () {
      for (final l in HedgingLevel.values) {
        final config = HedgingConfig.fromJson({'level': l.name});
        expect(config.level, equals(l));
      }
    });

    test('all HedgingPosition enum values roundtrip', () {
      for (final p in HedgingPosition.values) {
        final config =
            HedgingConfig.fromJson({'level': 'none', 'position': p.name});
        expect(config.position, equals(p));
      }
    });
  });

  group('HedgingPhrases', () {
    test('fromJson/toJson roundtrip with all fields', () {
      final json = {
        'high_uncertainty': ['a'],
        'moderate_uncertainty': ['b'],
        'low_uncertainty': ['c'],
        'qualifying': ['d'],
        'probabilistic': ['e'],
      };
      final phrases = HedgingPhrases.fromJson(json);
      final roundtripped = HedgingPhrases.fromJson(phrases.toJson());

      expect(roundtripped.highUncertainty, equals(['a']));
      expect(roundtripped.moderateUncertainty, equals(['b']));
      expect(roundtripped.lowUncertainty, equals(['c']));
      expect(roundtripped.qualifying, equals(['d']));
      expect(roundtripped.probabilistic, equals(['e']));
    });

    test('fromJson with all null fields', () {
      final phrases = HedgingPhrases.fromJson({});
      expect(phrases.highUncertainty, isNull);
      expect(phrases.moderateUncertainty, isNull);
      expect(phrases.lowUncertainty, isNull);
      expect(phrases.qualifying, isNull);
      expect(phrases.probabilistic, isNull);
    });

    test('toJson omits null fields', () {
      final phrases = HedgingPhrases(highUncertainty: ['x']);
      final json = phrases.toJson();

      expect(json.containsKey('high_uncertainty'), isTrue);
      expect(json.containsKey('moderate_uncertainty'), isFalse);
      expect(json.containsKey('low_uncertainty'), isFalse);
      expect(json.containsKey('qualifying'), isFalse);
      expect(json.containsKey('probabilistic'), isFalse);
    });
  });

  // =========================================================================
  // AudienceConfig & AudiencePreferences
  // =========================================================================
  group('AudienceConfig', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'expertise': 'novice',
        'context': 'internal',
        'role': 'student',
        'preferences': {
          'preferredFormat': 'markdown',
          'avoidJargon': true,
          'includeDefinitions': true,
          'visualPreference': 'mixed',
        },
      };
      final config = AudienceConfig.fromJson(json);
      final roundtripped = AudienceConfig.fromJson(config.toJson());

      expect(roundtripped.expertise, equals(Expertise.novice));
      expect(roundtripped.context, equals(AudienceContext.internal));
      expect(roundtripped.role, equals('student'));
      expect(roundtripped.preferences!.preferredFormat, equals('markdown'));
      expect(roundtripped.preferences!.avoidJargon, isTrue);
      expect(roundtripped.preferences!.includeDefinitions, isTrue);
      expect(roundtripped.preferences!.visualPreference,
          equals(VisualPreference.mixed));
    });

    test('all Expertise enum values roundtrip', () {
      for (final e in Expertise.values) {
        final config = AudienceConfig.fromJson({'expertise': e.name});
        expect(config.expertise, equals(e));
      }
    });

    test('all AudienceContext enum values roundtrip', () {
      for (final c in AudienceContext.values) {
        final config = AudienceConfig.fromJson({'context': c.name});
        expect(config.context, equals(c));
      }
    });

    test('fromJson with unknown enum defaults', () {
      final config = AudienceConfig.fromJson({
        'expertise': 'unknown',
        'context': 'unknown',
      });
      expect(config.expertise, equals(Expertise.intermediate));
      expect(config.context, equals(AudienceContext.internal));
    });
  });

  group('AudiencePreferences', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'preferredFormat': 'json',
        'avoidJargon': true,
        'includeDefinitions': false,
        'visualPreference': 'text',
      };
      final prefs = AudiencePreferences.fromJson(json);
      final roundtripped = AudiencePreferences.fromJson(prefs.toJson());

      expect(roundtripped.preferredFormat, equals('json'));
      expect(roundtripped.avoidJargon, isTrue);
      expect(roundtripped.includeDefinitions, isFalse);
      expect(roundtripped.visualPreference, equals(VisualPreference.text));
    });

    test('all VisualPreference enum values roundtrip', () {
      for (final v in VisualPreference.values) {
        final prefs =
            AudiencePreferences.fromJson({'visualPreference': v.name});
        expect(prefs.visualPreference, equals(v));
      }
    });

    test('fromJson with missing fields uses defaults', () {
      final prefs = AudiencePreferences.fromJson({});
      expect(prefs.preferredFormat, isNull);
      expect(prefs.avoidJargon, isFalse);
      expect(prefs.includeDefinitions, isFalse);
      expect(prefs.visualPreference, equals(VisualPreference.text));
    });
  });

  // =========================================================================
  // LanguageConfig, VocabularyConfig, GrammarConfig
  // =========================================================================
  group('LanguageConfig', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'locale': 'ko-KR',
        'vocabulary': {
          'avoidWords': ['bad'],
          'preferredTerms': {'old': 'new'},
          'jargonLevel': 'minimal',
        },
        'grammar': {
          'voicePreference': 'mixed',
          'sentenceComplexity': 'simple',
          'useContractions': false,
        },
      };
      final config = LanguageConfig.fromJson(json);
      final roundtripped = LanguageConfig.fromJson(config.toJson());

      expect(roundtripped.locale, equals('ko-KR'));
      expect(roundtripped.vocabulary!.avoidWords, equals(['bad']));
      expect(roundtripped.vocabulary!.preferredTerms, equals({'old': 'new'}));
      expect(roundtripped.vocabulary!.jargonLevel, equals(JargonLevel.minimal));
      expect(roundtripped.grammar!.voicePreference,
          equals(VoicePreference.mixed));
      expect(roundtripped.grammar!.sentenceComplexity,
          equals(SentenceComplexity.simple));
      expect(roundtripped.grammar!.useContractions, isFalse);
    });

    test('fromJson with all null fields', () {
      final config = LanguageConfig.fromJson({});
      expect(config.locale, isNull);
      expect(config.vocabulary, isNull);
      expect(config.grammar, isNull);
    });

    test('toJson omits null fields', () {
      final config = LanguageConfig();
      final json = config.toJson();
      expect(json.containsKey('locale'), isFalse);
      expect(json.containsKey('vocabulary'), isFalse);
      expect(json.containsKey('grammar'), isFalse);
    });
  });

  group('VocabularyConfig', () {
    test('all JargonLevel enum values roundtrip', () {
      for (final j in JargonLevel.values) {
        final config = VocabularyConfig.fromJson({'jargonLevel': j.name});
        expect(config.jargonLevel, equals(j));
      }
    });

    test('fromJson with unknown jargonLevel defaults to standard', () {
      final config = VocabularyConfig.fromJson({'jargonLevel': 'unknown'});
      expect(config.jargonLevel, equals(JargonLevel.standard));
    });
  });

  group('GrammarConfig', () {
    test('all VoicePreference enum values roundtrip', () {
      for (final v in VoicePreference.values) {
        final config = GrammarConfig.fromJson({'voicePreference': v.name});
        expect(config.voicePreference, equals(v));
      }
    });

    test('all SentenceComplexity enum values roundtrip', () {
      for (final s in SentenceComplexity.values) {
        final config =
            GrammarConfig.fromJson({'sentenceComplexity': s.name});
        expect(config.sentenceComplexity, equals(s));
      }
    });
  });

  // =========================================================================
  // FormattedResponse
  // =========================================================================
  group('FormattedResponse', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'content': 'Formatted text here',
        'appliedStyle': {
          'tone': {
            'formality': 'neutral',
            'confidence': 'moderate',
            'empathy': 'moderate',
            'directness': 'balanced',
          },
          'format': {
            'structure': 'mixed',
            'length': 'standard',
            'includeEvidence': true,
            'includeCaveats': false,
            'includeAlternatives': false,
          },
        },
        'hedgingApplied': ['It seems...', 'however'],
        'metadata': {'processingTime': 42},
      };
      final response = FormattedResponse.fromJson(json);
      final roundtripped = FormattedResponse.fromJson(response.toJson());

      expect(roundtripped.content, equals('Formatted text here'));
      expect(roundtripped.appliedStyle.tone.formality,
          equals(Formality.neutral));
      expect(roundtripped.hedgingApplied, equals(['It seems...', 'however']));
      expect(roundtripped.metadata, equals({'processingTime': 42}));
    });

    test('fromJson with missing optional fields', () {
      final response = FormattedResponse.fromJson({});
      expect(response.content, equals(''));
      expect(response.hedgingApplied, isEmpty);
      expect(response.metadata, isNull);
      // appliedStyle defaults to defaultStyle when not a Map
      expect(response.appliedStyle.tone.formality, equals(Formality.neutral));
    });

    test('toJson omits empty hedgingApplied and null metadata', () {
      final response = FormattedResponse(
        content: 'text',
        appliedStyle: ExpressionStyle.defaultStyle,
      );
      final json = response.toJson();

      expect(json.containsKey('hedgingApplied'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });
  });

  // =========================================================================
  // decision_guidance.dart
  // =========================================================================
  group('DecisionGuidance', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'action': 'proceed_with_caution',
        'confidence': 0.75,
        'explanation': 'Proceed carefully',
        'modifiers': [
          {
            'type': 'require_evidence',
            'config': {'minSources': 2},
          },
          {
            'type': 'add_disclaimer',
            'config': {'text': 'Warning', 'position': 'start'},
          },
        ],
        'metadata': {'policyId': 'p-1'},
      };
      final guidance = DecisionGuidance.fromJson(json);
      final roundtripped = DecisionGuidance.fromJson(guidance.toJson());

      expect(roundtripped.action, equals(DecisionAction.proceedWithCaution));
      expect(roundtripped.confidence, equals(0.75));
      expect(roundtripped.explanation, equals('Proceed carefully'));
      expect(roundtripped.modifiers.length, equals(2));
      expect(roundtripped.modifiers[0].type,
          equals(ModifierType.requireEvidence));
      expect(roundtripped.modifiers[1].type,
          equals(ModifierType.addDisclaimer));
      expect(roundtripped.metadata, equals({'policyId': 'p-1'}));
    });

    test('fromJson with missing optional fields', () {
      final guidance =
          DecisionGuidance.fromJson({'action': 'proceed'});

      expect(guidance.confidence, isNull);
      expect(guidance.explanation, isNull);
      expect(guidance.modifiers, isEmpty);
      expect(guidance.metadata, isNull);
    });

    test('requiresApproval getter', () {
      final withApproval = DecisionGuidance(
        action: DecisionAction.hold,
        modifiers: [
          DecisionModifier.requireApproval(approverRole: 'manager'),
        ],
      );
      final withoutApproval = DecisionGuidance(
        action: DecisionAction.proceed,
        modifiers: [
          DecisionModifier.log(),
        ],
      );

      expect(withApproval.requiresApproval, isTrue);
      expect(withoutApproval.requiresApproval, isFalse);
    });

    test('requiresEvidence getter', () {
      final withEvidence = DecisionGuidance(
        action: DecisionAction.hold,
        modifiers: [
          DecisionModifier.requireEvidence(minSources: 3),
        ],
      );
      final withoutEvidence = DecisionGuidance(
        action: DecisionAction.proceed,
      );

      expect(withEvidence.requiresEvidence, isTrue);
      expect(withoutEvidence.requiresEvidence, isFalse);
    });

    test('getModifiers filters by type', () {
      final guidance = DecisionGuidance(
        action: DecisionAction.hold,
        modifiers: [
          DecisionModifier.requireEvidence(),
          DecisionModifier.log(),
          DecisionModifier.requireEvidence(minSources: 5),
        ],
      );

      final evidenceModifiers =
          guidance.getModifiers(ModifierType.requireEvidence);
      expect(evidenceModifiers.length, equals(2));

      final logModifiers = guidance.getModifiers(ModifierType.log);
      expect(logModifiers.length, equals(1));
    });

    test('toJson omits empty modifiers and null fields', () {
      final guidance = DecisionGuidance(
        action: DecisionAction.proceed,
      );
      final json = guidance.toJson();

      expect(json.containsKey('confidence'), isFalse);
      expect(json.containsKey('explanation'), isFalse);
      expect(json.containsKey('modifiers'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });
  });

  // =========================================================================
  // DecisionAction extension
  // =========================================================================
  group('DecisionAction', () {
    test('toJsonName for all values', () {
      expect(DecisionAction.proceed.toJsonName(), equals('proceed'));
      expect(DecisionAction.proceedWithCaution.toJsonName(),
          equals('proceed_with_caution'));
      expect(DecisionAction.hold.toJsonName(), equals('hold'));
      expect(DecisionAction.question.toJsonName(), equals('question'));
      expect(DecisionAction.escalate.toJsonName(), equals('escalate'));
      expect(DecisionAction.reject.toJsonName(), equals('reject'));
      expect(DecisionAction.defer.toJsonName(), equals('defer'));
      expect(DecisionAction.custom.toJsonName(), equals('custom'));
    });

    test('fromJsonName for all values', () {
      expect(DecisionActionExtension.fromJsonName('proceed'),
          equals(DecisionAction.proceed));
      expect(DecisionActionExtension.fromJsonName('proceed_with_caution'),
          equals(DecisionAction.proceedWithCaution));
      expect(DecisionActionExtension.fromJsonName('hold'),
          equals(DecisionAction.hold));
      expect(DecisionActionExtension.fromJsonName('question'),
          equals(DecisionAction.question));
      expect(DecisionActionExtension.fromJsonName('escalate'),
          equals(DecisionAction.escalate));
      expect(DecisionActionExtension.fromJsonName('reject'),
          equals(DecisionAction.reject));
      expect(DecisionActionExtension.fromJsonName('defer'),
          equals(DecisionAction.defer));
      expect(DecisionActionExtension.fromJsonName('custom'),
          equals(DecisionAction.custom));
    });

    test('fromJsonName unknown defaults to proceed', () {
      expect(DecisionActionExtension.fromJsonName('garbage'),
          equals(DecisionAction.proceed));
    });

    test('allowsProceeding', () {
      expect(DecisionAction.proceed.allowsProceeding, isTrue);
      expect(DecisionAction.proceedWithCaution.allowsProceeding, isTrue);
      expect(DecisionAction.hold.allowsProceeding, isFalse);
      expect(DecisionAction.question.allowsProceeding, isFalse);
      expect(DecisionAction.escalate.allowsProceeding, isFalse);
      expect(DecisionAction.reject.allowsProceeding, isFalse);
      expect(DecisionAction.defer.allowsProceeding, isFalse);
      expect(DecisionAction.custom.allowsProceeding, isFalse);
    });

    test('blocksProceeding', () {
      expect(DecisionAction.hold.blocksProceeding, isTrue);
      expect(DecisionAction.reject.blocksProceeding, isTrue);
      expect(DecisionAction.defer.blocksProceeding, isTrue);
      expect(DecisionAction.proceed.blocksProceeding, isFalse);
      expect(DecisionAction.proceedWithCaution.blocksProceeding, isFalse);
      expect(DecisionAction.question.blocksProceeding, isFalse);
      expect(DecisionAction.escalate.blocksProceeding, isFalse);
      expect(DecisionAction.custom.blocksProceeding, isFalse);
    });

    test('requiresHuman', () {
      expect(DecisionAction.escalate.requiresHuman, isTrue);
      expect(DecisionAction.question.requiresHuman, isTrue);
      expect(DecisionAction.proceed.requiresHuman, isFalse);
      expect(DecisionAction.hold.requiresHuman, isFalse);
      expect(DecisionAction.reject.requiresHuman, isFalse);
      expect(DecisionAction.defer.requiresHuman, isFalse);
      expect(DecisionAction.custom.requiresHuman, isFalse);
    });
  });

  // =========================================================================
  // DecisionModifier factories
  // =========================================================================
  group('DecisionModifier', () {
    test('requireEvidence factory', () {
      final mod = DecisionModifier.requireEvidence(
        minSources: 3,
        evidenceTypes: ['document', 'api'],
      );

      expect(mod.type, equals(ModifierType.requireEvidence));
      expect(mod.config!['minSources'], equals(3));
      expect(mod.config!['evidenceTypes'], equals(['document', 'api']));
    });

    test('requireEvidence factory with defaults', () {
      final mod = DecisionModifier.requireEvidence();
      expect(mod.config!['minSources'], equals(1));
      expect(mod.config!.containsKey('evidenceTypes'), isFalse);
    });

    test('requireApproval factory', () {
      final mod = DecisionModifier.requireApproval(
        approverRole: 'senior-analyst',
        expiresIn: '24h',
      );

      expect(mod.type, equals(ModifierType.requireApproval));
      expect(mod.config!['approverRole'], equals('senior-analyst'));
      expect(mod.config!['expiresIn'], equals('24h'));
    });

    test('requireApproval factory without expiresIn', () {
      final mod = DecisionModifier.requireApproval(approverRole: 'admin');
      expect(mod.config!.containsKey('expiresIn'), isFalse);
    });

    test('addDisclaimer factory', () {
      final mod = DecisionModifier.addDisclaimer(
        text: 'This is not financial advice',
        position: 'end',
      );

      expect(mod.type, equals(ModifierType.addDisclaimer));
      expect(mod.config!['text'], equals('This is not financial advice'));
      expect(mod.config!['position'], equals('end'));
    });

    test('addDisclaimer factory default position', () {
      final mod = DecisionModifier.addDisclaimer(text: 'Warning');
      expect(mod.config!['position'], equals('start'));
    });

    test('notify factory', () {
      final mod = DecisionModifier.notify(
        channels: ['email', 'slack'],
        recipients: ['user@example.com'],
        template: 'alert-template',
        urgency: 'high',
      );

      expect(mod.type, equals(ModifierType.notify));
      expect(mod.config!['channels'], equals(['email', 'slack']));
      expect(mod.config!['recipients'], equals(['user@example.com']));
      expect(mod.config!['template'], equals('alert-template'));
      expect(mod.config!['urgency'], equals('high'));
    });

    test('notify factory defaults', () {
      final mod = DecisionModifier.notify(
        channels: ['webhook'],
        recipients: ['system'],
      );
      expect(mod.config!['urgency'], equals('normal'));
      expect(mod.config!.containsKey('template'), isFalse);
    });

    test('log factory', () {
      final mod = DecisionModifier.log(level: 'warn');
      expect(mod.type, equals(ModifierType.log));
      expect(mod.config!['level'], equals('warn'));
    });

    test('log factory default level', () {
      final mod = DecisionModifier.log();
      expect(mod.config!['level'], equals('info'));
    });

    test('getConfig with correct type', () {
      final mod = DecisionModifier.requireEvidence(minSources: 5);
      expect(mod.getConfig<int>('minSources'), equals(5));
      expect(mod.getConfig<String>('minSources'), isNull); // wrong type
      expect(mod.getConfig<int>('nonexistent'), isNull);
    });

    test('getConfig with null config', () {
      final mod = DecisionModifier(type: ModifierType.custom);
      expect(mod.getConfig<String>('anything'), isNull);
    });

    test('fromJson/toJson roundtrip', () {
      final mod = DecisionModifier.requireApproval(
        approverRole: 'lead',
        expiresIn: '48h',
      );
      final json = mod.toJson();
      final roundtripped = DecisionModifier.fromJson(json);

      expect(roundtripped.type, equals(ModifierType.requireApproval));
      expect(roundtripped.config!['approverRole'], equals('lead'));
      expect(roundtripped.config!['expiresIn'], equals('48h'));
    });

    test('fromJson with unknown type defaults to custom', () {
      final mod = DecisionModifier.fromJson({'type': 'totally_unknown'});
      expect(mod.type, equals(ModifierType.custom));
    });
  });

  // =========================================================================
  // ModifierType extension
  // =========================================================================
  group('ModifierType', () {
    test('toJsonName for all values', () {
      expect(ModifierType.requireEvidence.toJsonName(),
          equals('require_evidence'));
      expect(ModifierType.requireApproval.toJsonName(),
          equals('require_approval'));
      expect(
          ModifierType.addDisclaimer.toJsonName(), equals('add_disclaimer'));
      expect(ModifierType.limitScope.toJsonName(), equals('limit_scope'));
      expect(ModifierType.reduceConfidence.toJsonName(),
          equals('reduce_confidence'));
      expect(ModifierType.increaseValidation.toJsonName(),
          equals('increase_validation'));
      expect(ModifierType.notify.toJsonName(), equals('notify'));
      expect(ModifierType.log.toJsonName(), equals('log'));
      expect(ModifierType.custom.toJsonName(), equals('custom'));
    });

    test('fromJson snake_case to camelCase conversion roundtrip', () {
      for (final type in ModifierType.values) {
        final jsonName = type.toJsonName();
        final mod = DecisionModifier.fromJson({'type': jsonName});
        expect(mod.type, equals(type),
            reason: 'Failed roundtrip for $jsonName');
      }
    });
  });

  // =========================================================================
  // appraisal_result.dart
  // =========================================================================
  group('MetricSourceType', () {
    test('toJson for all values', () {
      expect(MetricSourceType.factgraph.toJson(), equals('factgraph'));
      expect(MetricSourceType.computed.toJson(), equals('computed'));
      expect(MetricSourceType.static_.toJson(), equals('static'));
      expect(MetricSourceType.llmDerived.toJson(), equals('llm_derived'));
    });

    test('fromJson for all values', () {
      expect(
          MetricSourceType.fromJson('factgraph'), equals(MetricSourceType.factgraph));
      expect(
          MetricSourceType.fromJson('computed'), equals(MetricSourceType.computed));
      expect(
          MetricSourceType.fromJson('static'), equals(MetricSourceType.static_));
      expect(MetricSourceType.fromJson('llm_derived'),
          equals(MetricSourceType.llmDerived));
    });

    test('fromJson with static maps to static_', () {
      final type = MetricSourceType.fromJson('static');
      expect(type, equals(MetricSourceType.static_));
      expect(type.toJson(), equals('static'));
    });

    test('fromJson unknown value defaults to computed', () {
      expect(
          MetricSourceType.fromJson('unknown'), equals(MetricSourceType.computed));
    });

    test('roundtrip for all values', () {
      for (final type in MetricSourceType.values) {
        final jsonName = type.toJson();
        final parsed = MetricSourceType.fromJson(jsonName);
        expect(parsed, equals(type),
            reason: 'Failed roundtrip for ${type.name}');
      }
    });
  });

  group('MetricResult', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'id': 'metric-1',
        'rawValue': 85.5,
        'normalizedValue': 0.855,
        'sourceType': 'factgraph',
        'confidence': 0.9,
      };
      final result = MetricResult.fromJson(json);
      final roundtripped = MetricResult.fromJson(result.toJson());

      expect(roundtripped.id, equals('metric-1'));
      expect(roundtripped.rawValue, equals(85.5));
      expect(roundtripped.normalizedValue, equals(0.855));
      expect(roundtripped.sourceType, equals(MetricSourceType.factgraph));
      expect(roundtripped.confidence, equals(0.9));
    });

    test('fromJson with null rawValue', () {
      final json = {
        'id': 'metric-2',
        'normalizedValue': 0.5,
        'sourceType': 'computed',
        'confidence': 0.6,
      };
      final result = MetricResult.fromJson(json);
      expect(result.rawValue, isNull);

      final rt = MetricResult.fromJson(result.toJson());
      expect(rt.rawValue, isNull);
    });

    test('toJson omits null rawValue', () {
      final result = MetricResult(
        id: 'm1',
        normalizedValue: 0.5,
        sourceType: MetricSourceType.computed,
        confidence: 0.7,
      );
      expect(result.toJson().containsKey('rawValue'), isFalse);
    });

    test('confidence level getters', () {
      final low = MetricResult(
        id: 'l',
        normalizedValue: 0.5,
        sourceType: MetricSourceType.computed,
        confidence: 0.3,
      );
      final medium = MetricResult(
        id: 'm',
        normalizedValue: 0.5,
        sourceType: MetricSourceType.computed,
        confidence: 0.6,
      );
      final high = MetricResult(
        id: 'h',
        normalizedValue: 0.5,
        sourceType: MetricSourceType.computed,
        confidence: 0.9,
      );

      expect(low.isLowConfidence, isTrue);
      expect(low.isMediumConfidence, isFalse);
      expect(low.isHighConfidence, isFalse);

      expect(medium.isLowConfidence, isFalse);
      expect(medium.isMediumConfidence, isTrue);
      expect(medium.isHighConfidence, isFalse);

      expect(high.isLowConfidence, isFalse);
      expect(high.isMediumConfidence, isFalse);
      expect(high.isHighConfidence, isTrue);
    });
  });

  group('AppraisalMetadata', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'computedAt': fixedNow.toIso8601String(),
        'durationMs': 150,
        'sourceCounts': {'factgraph': 3, 'llm': 1},
        'missingMetrics': ['metric-x'],
        'lowConfidenceMetrics': ['metric-y'],
        'metricsRequiringEvidence': ['metric-z'],
        'warnings': ['Data may be stale'],
      };
      final meta = AppraisalMetadata.fromJson(json);
      final roundtripped = AppraisalMetadata.fromJson(meta.toJson());

      expect(roundtripped.computedAt, equals(fixedNow));
      expect(roundtripped.durationMs, equals(150));
      expect(roundtripped.duration, equals(const Duration(milliseconds: 150)));
      expect(roundtripped.sourceCounts, equals({'factgraph': 3, 'llm': 1}));
      expect(roundtripped.missingMetrics, equals(['metric-x']));
      expect(roundtripped.lowConfidenceMetrics, equals(['metric-y']));
      expect(roundtripped.metricsRequiringEvidence, equals(['metric-z']));
      expect(roundtripped.warnings, equals(['Data may be stale']));
    });

    test('fromJson with missing optional fields', () {
      final meta = AppraisalMetadata.fromJson({
        'computedAt': fixedNow.toIso8601String(),
      });

      expect(meta.durationMs, equals(0));
      expect(meta.sourceCounts, isEmpty);
      expect(meta.missingMetrics, isEmpty);
      expect(meta.lowConfidenceMetrics, isNull);
      expect(meta.metricsRequiringEvidence, isEmpty);
      expect(meta.warnings, isEmpty);
    });

    test('toJson omits empty lists and null lowConfidenceMetrics', () {
      final meta = AppraisalMetadata(computedAt: fixedNow);
      final json = meta.toJson();

      expect(json.containsKey('sourceCounts'), isFalse);
      expect(json.containsKey('missingMetrics'), isFalse);
      expect(json.containsKey('lowConfidenceMetrics'), isFalse);
      expect(json.containsKey('metricsRequiringEvidence'), isFalse);
      expect(json.containsKey('warnings'), isFalse);
    });
  });

  group('AppraisalResult', () {
    Map<String, dynamic> _makeAppraisalJson() {
      return {
        'profileId': 'prof-1',
        'contextId': 'ctx-1',
        'asOf': fixedNow.toIso8601String(),
        'metrics': {
          'accuracy': {
            'id': 'accuracy',
            'rawValue': 90.0,
            'normalizedValue': 0.9,
            'sourceType': 'factgraph',
            'confidence': 0.85,
          },
          'completeness': {
            'id': 'completeness',
            'normalizedValue': 0.7,
            'sourceType': 'llm_derived',
            'confidence': 0.4,
          },
        },
        'aggregatedScore': 0.8,
        'metadata': {
          'computedAt': fixedNow.toIso8601String(),
          'durationMs': 200,
        },
      };
    }

    test('fromJson/toJson roundtrip', () {
      final json = _makeAppraisalJson();
      final result = AppraisalResult.fromJson(json);
      final roundtripped = AppraisalResult.fromJson(result.toJson());

      expect(roundtripped.profileId, equals('prof-1'));
      expect(roundtripped.contextId, equals('ctx-1'));
      expect(roundtripped.asOf, equals(fixedNow));
      expect(roundtripped.metrics.length, equals(2));
      expect(roundtripped.metrics['accuracy']!.rawValue, equals(90.0));
      expect(roundtripped.metrics['completeness']!.sourceType,
          equals(MetricSourceType.llmDerived));
      expect(roundtripped.aggregatedScore, equals(0.8));
    });

    test('getMetric and getNormalizedValue', () {
      final result = AppraisalResult.fromJson(_makeAppraisalJson());

      expect(result.getMetric('accuracy'), isNotNull);
      expect(result.getMetric('nonexistent'), isNull);
      expect(result.getNormalizedValue('accuracy'), equals(0.9));
      expect(result.getNormalizedValue('nonexistent'), isNull);
    });

    test('isHighConfidence', () {
      final highConfidence = AppraisalResult(
        profileId: 'p',
        contextId: 'c',
        asOf: fixedNow,
        metrics: {
          'a': MetricResult(
            id: 'a',
            normalizedValue: 0.9,
            sourceType: MetricSourceType.factgraph,
            confidence: 0.8,
          ),
        },
        aggregatedScore: 0.9,
        metadata: AppraisalMetadata(computedAt: fixedNow),
      );
      expect(highConfidence.isHighConfidence, isTrue);

      final result = AppraisalResult.fromJson(_makeAppraisalJson());
      // 'completeness' has confidence 0.4, which is < 0.6
      expect(result.isHighConfidence, isFalse);
    });

    test('lowConfidenceMetrics', () {
      final result = AppraisalResult.fromJson(_makeAppraisalJson());
      final low = result.lowConfidenceMetrics;
      expect(low.length, equals(1));
      expect(low.first.id, equals('completeness'));
    });

    test('empty factory', () {
      final result = AppraisalResult.empty(
        profileId: 'test-profile',
        contextId: 'ctx',
        asOf: fixedNow,
      );

      expect(result.profileId, equals('test-profile'));
      expect(result.contextId, equals('ctx'));
      expect(result.metrics, isEmpty);
      expect(result.aggregatedScore, equals(1.0));
    });
  });

  // =========================================================================
  // profile_result.dart
  // =========================================================================
  group('ProfileExecutionMetadata', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'startedAt': fixedStart.toIso8601String(),
        'completedAt': fixedEnd.toIso8601String(),
        'profileVersion': '2.1.0',
      };
      final meta = ProfileExecutionMetadata.fromJson(json);
      final roundtripped = ProfileExecutionMetadata.fromJson(meta.toJson());

      expect(roundtripped.startedAt, equals(fixedStart));
      expect(roundtripped.completedAt, equals(fixedEnd));
      expect(roundtripped.profileVersion, equals('2.1.0'));
    });

    test('duration getter', () {
      final meta = ProfileExecutionMetadata(
        startedAt: fixedStart,
        completedAt: fixedEnd,
        profileVersion: '1.0.0',
      );
      expect(meta.duration, equals(fixedEnd.difference(fixedStart)));
      expect(meta.duration.inMinutes, equals(5));
    });

    test('fromJson with missing fields', () {
      final meta = ProfileExecutionMetadata.fromJson({});
      expect(meta.profileVersion, equals('0.0.0'));
      // startedAt and completedAt default to DateTime.now(), just check they exist
      expect(meta.startedAt, isA<DateTime>());
      expect(meta.completedAt, isA<DateTime>());
    });
  });

  group('EvaluationOutput', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'score': 0.85,
        'dimensions': {'accuracy': 0.9, 'relevance': 0.8},
        'issues': ['Missing source', 'Vague claim'],
        'suggestions': ['Add citation', 'Be more specific'],
      };
      final output = EvaluationOutput.fromJson(json);
      final roundtripped = EvaluationOutput.fromJson(output.toJson());

      expect(roundtripped.score, equals(0.85));
      expect(
          roundtripped.dimensions, equals({'accuracy': 0.9, 'relevance': 0.8}));
      expect(roundtripped.issues, equals(['Missing source', 'Vague claim']));
      expect(roundtripped.suggestions,
          equals(['Add citation', 'Be more specific']));
    });

    test('fromJson with missing fields', () {
      final output = EvaluationOutput.fromJson({});
      expect(output.score, equals(0.0));
      expect(output.dimensions, isEmpty);
      expect(output.issues, isEmpty);
      expect(output.suggestions, isEmpty);
    });

    test('toJson omits empty lists', () {
      final output = EvaluationOutput(
        score: 0.5,
        dimensions: {'a': 0.5},
      );
      final json = output.toJson();

      expect(json.containsKey('issues'), isFalse);
      expect(json.containsKey('suggestions'), isFalse);
    });
  });

  group('ProfileOutput', () {
    Map<String, dynamic> _makeProfileOutputJson() {
      return {
        'profileId': 'medical-advisor',
        'contextId': 'ctx-456',
        'appraisal': {
          'profileId': 'medical-advisor',
          'contextId': 'ctx-456',
          'asOf': fixedNow.toIso8601String(),
          'metrics': {
            'safety': {
              'id': 'safety',
              'normalizedValue': 0.95,
              'sourceType': 'static',
              'confidence': 0.99,
            }
          },
          'aggregatedScore': 0.95,
          'metadata': {
            'computedAt': fixedNow.toIso8601String(),
          },
        },
        'decision': {
          'action': 'proceed',
          'confidence': 1.0,
        },
        'expression': {
          'tone': {
            'formality': 'formal',
            'confidence': 'moderate',
            'empathy': 'high',
            'directness': 'diplomatic',
          },
          'format': {
            'structure': 'prose',
            'length': 'detailed',
            'includeEvidence': true,
            'includeCaveats': true,
            'includeAlternatives': false,
          },
        },
        'formatted': {
          'content': 'Based on analysis...',
          'appliedStyle': {
            'tone': {
              'formality': 'formal',
              'confidence': 'moderate',
              'empathy': 'high',
              'directness': 'diplomatic',
            },
            'format': {
              'structure': 'prose',
              'length': 'detailed',
              'includeEvidence': true,
              'includeCaveats': true,
              'includeAlternatives': false,
            },
          },
          'hedgingApplied': ['It appears that...'],
        },
        'metadata': {
          'startedAt': fixedStart.toIso8601String(),
          'completedAt': fixedEnd.toIso8601String(),
          'profileVersion': '3.0.0',
        },
      };
    }

    test('fromJson/toJson roundtrip', () {
      final json = _makeProfileOutputJson();
      final output = ProfileOutput.fromJson(json);
      final roundtripped = ProfileOutput.fromJson(output.toJson());

      expect(roundtripped.profileId, equals('medical-advisor'));
      expect(roundtripped.contextId, equals('ctx-456'));
      expect(roundtripped.appraisal.aggregatedScore, equals(0.95));
      expect(roundtripped.appraisal.metrics['safety']!.sourceType,
          equals(MetricSourceType.static_));
      expect(roundtripped.decision.action, equals(DecisionAction.proceed));
      expect(roundtripped.expression.tone.formality, equals(Formality.formal));
      expect(roundtripped.formatted, isNotNull);
      expect(roundtripped.formatted!.content, equals('Based on analysis...'));
      expect(roundtripped.metadata.profileVersion, equals('3.0.0'));
    });

    test('fromJson with missing optional formatted field', () {
      final json = _makeProfileOutputJson();
      json.remove('formatted');
      final output = ProfileOutput.fromJson(json);

      expect(output.formatted, isNull);
    });

    test('fromJson with non-map sub-fields uses defaults', () {
      final output = ProfileOutput.fromJson({
        'profileId': 'p1',
        'contextId': 'c1',
        'appraisal': 'not-a-map',
        'decision': 'not-a-map',
        'expression': 'not-a-map',
        'metadata': 'not-a-map',
      });

      // Should fall back to defaults
      expect(output.decision.action, equals(DecisionAction.proceed));
      expect(output.expression.tone.formality, equals(Formality.neutral));
    });

    test('empty factory', () {
      final output = ProfileOutput.empty(
        profileId: 'test',
        contextId: 'ctx',
      );

      expect(output.profileId, equals('test'));
      expect(output.contextId, equals('ctx'));
      expect(output.appraisal.metrics, isEmpty);
      expect(output.decision.action, equals(DecisionAction.proceed));
      expect(output.expression.tone, equals(ToneConfig.neutral));
      expect(output.formatted, isNull);
      expect(output.metadata.profileVersion, equals('0.0.0'));
    });

    test('toJson omits null formatted', () {
      final output = ProfileOutput.empty();
      final json = output.toJson();
      expect(json.containsKey('formatted'), isFalse);
    });
  });

  // =========================================================================
  // period.dart
  // =========================================================================
  group('Period', () {
    group('fromJson dispatch', () {
      test('dispatches to RelativePeriod', () {
        final period = Period.fromJson({
          'type': 'relative',
          'unit': 'days',
          'value': 30,
          'direction': 'past',
        });
        expect(period, isA<RelativePeriod>());
      });

      test('dispatches to AbsolutePeriod', () {
        final period = Period.fromJson({
          'type': 'absolute',
          'start': fixedStart.toIso8601String(),
          'end': fixedEnd.toIso8601String(),
        });
        expect(period, isA<AbsolutePeriod>());
      });

      test('throws ArgumentError for unknown type', () {
        expect(
          () => Period.fromJson({'type': 'unknown_type'}),
          throwsArgumentError,
        );
      });
    });
  });

  group('RelativePeriod', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'type': 'relative',
        'unit': 'hours',
        'value': 24,
        'direction': 'future',
      };
      final period = RelativePeriod.fromJson(json);
      final roundtripped = RelativePeriod.fromJson(period.toJson());

      expect(roundtripped.unit, equals(PeriodUnit.hours));
      expect(roundtripped.value, equals(24));
      expect(roundtripped.direction, equals(PeriodDirection.future));
    });

    test('fromJson default direction is past', () {
      final period = RelativePeriod.fromJson({
        'unit': 'days',
        'value': 7,
      });
      expect(period.direction, equals(PeriodDirection.past));
    });

    test('toJson includes type field', () {
      final period = RelativePeriod(unit: PeriodUnit.days, value: 10);
      expect(period.toJson()['type'], equals('relative'));
    });

    group('resolve', () {
      final ref = DateTime.utc(2025, 6, 15, 12, 0, 0);

      test('direction: past', () {
        final period = RelativePeriod(
          unit: PeriodUnit.days,
          value: 7,
          direction: PeriodDirection.past,
        );
        final range = period.resolve(ref);

        expect(range.end, equals(ref));
        expect(range.start, equals(DateTime.utc(2025, 6, 8, 12, 0, 0)));
      });

      test('direction: future', () {
        final period = RelativePeriod(
          unit: PeriodUnit.days,
          value: 7,
          direction: PeriodDirection.future,
        );
        final range = period.resolve(ref);

        expect(range.start, equals(ref));
        expect(range.end, equals(DateTime.utc(2025, 6, 22, 12, 0, 0)));
      });

      test('direction: around', () {
        final period = RelativePeriod(
          unit: PeriodUnit.days,
          value: 10,
          direction: PeriodDirection.around,
        );
        final range = period.resolve(ref);

        // halfValue = 10 ~/ 2 = 5
        expect(range.start, equals(DateTime.utc(2025, 6, 10, 12, 0, 0)));
        expect(range.end, equals(DateTime.utc(2025, 6, 20, 12, 0, 0)));
      });
    });

    group('_addDuration/_subtractDuration for all units', () {
      final ref = DateTime.utc(2025, 6, 15, 12, 30, 0);

      test('minutes', () {
        final period = RelativePeriod(
          unit: PeriodUnit.minutes,
          value: 45,
          direction: PeriodDirection.past,
        );
        final range = period.resolve(ref);
        expect(range.start, equals(DateTime.utc(2025, 6, 15, 11, 45, 0)));
        expect(range.end, equals(ref));

        final futurePeriod = RelativePeriod(
          unit: PeriodUnit.minutes,
          value: 45,
          direction: PeriodDirection.future,
        );
        final futureRange = futurePeriod.resolve(ref);
        expect(futureRange.end, equals(DateTime.utc(2025, 6, 15, 13, 15, 0)));
      });

      test('hours', () {
        final period = RelativePeriod(
          unit: PeriodUnit.hours,
          value: 3,
          direction: PeriodDirection.past,
        );
        final range = period.resolve(ref);
        expect(range.start, equals(DateTime.utc(2025, 6, 15, 9, 30, 0)));

        final futurePeriod = RelativePeriod(
          unit: PeriodUnit.hours,
          value: 3,
          direction: PeriodDirection.future,
        );
        expect(futurePeriod.resolve(ref).end,
            equals(DateTime.utc(2025, 6, 15, 15, 30, 0)));
      });

      test('days', () {
        final period = RelativePeriod(
          unit: PeriodUnit.days,
          value: 5,
          direction: PeriodDirection.past,
        );
        final range = period.resolve(ref);
        expect(range.start, equals(DateTime.utc(2025, 6, 10, 12, 30, 0)));

        final futurePeriod = RelativePeriod(
          unit: PeriodUnit.days,
          value: 5,
          direction: PeriodDirection.future,
        );
        expect(futurePeriod.resolve(ref).end,
            equals(DateTime.utc(2025, 6, 20, 12, 30, 0)));
      });

      test('weeks', () {
        final period = RelativePeriod(
          unit: PeriodUnit.weeks,
          value: 2,
          direction: PeriodDirection.past,
        );
        final range = period.resolve(ref);
        expect(range.start, equals(DateTime.utc(2025, 6, 1, 12, 30, 0)));

        final futurePeriod = RelativePeriod(
          unit: PeriodUnit.weeks,
          value: 2,
          direction: PeriodDirection.future,
        );
        expect(futurePeriod.resolve(ref).end,
            equals(DateTime.utc(2025, 6, 29, 12, 30, 0)));
      });

      test('months', () {
        final period = RelativePeriod(
          unit: PeriodUnit.months,
          value: 3,
          direction: PeriodDirection.past,
        );
        final range = period.resolve(ref);
        // DateTime() constructor produces local time, so compare structurally
        expect(range.start.year, equals(2025));
        expect(range.start.month, equals(3));
        expect(range.start.day, equals(15));

        final futurePeriod = RelativePeriod(
          unit: PeriodUnit.months,
          value: 3,
          direction: PeriodDirection.future,
        );
        final futureEnd = futurePeriod.resolve(ref).end;
        expect(futureEnd.year, equals(2025));
        expect(futureEnd.month, equals(9));
        expect(futureEnd.day, equals(15));
      });

      test('years', () {
        final period = RelativePeriod(
          unit: PeriodUnit.years,
          value: 2,
          direction: PeriodDirection.past,
        );
        final range = period.resolve(ref);
        expect(range.start.year, equals(2023));
        expect(range.start.month, equals(6));
        expect(range.start.day, equals(15));

        final futurePeriod = RelativePeriod(
          unit: PeriodUnit.years,
          value: 2,
          direction: PeriodDirection.future,
        );
        final futureEnd = futurePeriod.resolve(ref).end;
        expect(futureEnd.year, equals(2027));
        expect(futureEnd.month, equals(6));
        expect(futureEnd.day, equals(15));
      });
    });

    test('equality and hashCode', () {
      final a = RelativePeriod(unit: PeriodUnit.days, value: 7);
      final b = RelativePeriod(unit: PeriodUnit.days, value: 7);
      final c = RelativePeriod(
          unit: PeriodUnit.days, value: 7, direction: PeriodDirection.future);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('AbsolutePeriod', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'type': 'absolute',
        'start': fixedStart.toIso8601String(),
        'end': fixedEnd.toIso8601String(),
      };
      final period = AbsolutePeriod.fromJson(json);
      final roundtripped = AbsolutePeriod.fromJson(period.toJson());

      expect(roundtripped.start, equals(fixedStart));
      expect(roundtripped.end, equals(fixedEnd));
    });

    test('toJson includes type field', () {
      final period = AbsolutePeriod(start: fixedStart, end: fixedEnd);
      expect(period.toJson()['type'], equals('absolute'));
    });

    test('resolve returns fixed DateRange', () {
      final period = AbsolutePeriod(start: fixedStart, end: fixedEnd);
      final range = period.resolve();

      expect(range.start, equals(fixedStart));
      expect(range.end, equals(fixedEnd));

      // Reference time is ignored
      final rangeWithRef =
          period.resolve(DateTime.utc(2099, 1, 1));
      expect(rangeWithRef.start, equals(fixedStart));
      expect(rangeWithRef.end, equals(fixedEnd));
    });

    test('equality and hashCode', () {
      final a = AbsolutePeriod(start: fixedStart, end: fixedEnd);
      final b = AbsolutePeriod(start: fixedStart, end: fixedEnd);
      final c = AbsolutePeriod(
        start: fixedStart,
        end: fixedStart.add(const Duration(hours: 1)),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('PeriodDirection', () {
    test('fromString for all values', () {
      expect(PeriodDirection.fromString('past'), equals(PeriodDirection.past));
      expect(
          PeriodDirection.fromString('future'), equals(PeriodDirection.future));
      expect(
          PeriodDirection.fromString('around'), equals(PeriodDirection.around));
    });

    test('fromString case insensitive', () {
      expect(PeriodDirection.fromString('PAST'), equals(PeriodDirection.past));
      expect(
          PeriodDirection.fromString('Future'), equals(PeriodDirection.future));
    });

    test('fromString unknown defaults to past', () {
      expect(
          PeriodDirection.fromString('unknown'), equals(PeriodDirection.past));
    });
  });

  group('PeriodUnit', () {
    test('fromString for all values', () {
      expect(PeriodUnit.fromString('minutes'), equals(PeriodUnit.minutes));
      expect(PeriodUnit.fromString('hours'), equals(PeriodUnit.hours));
      expect(PeriodUnit.fromString('days'), equals(PeriodUnit.days));
      expect(PeriodUnit.fromString('weeks'), equals(PeriodUnit.weeks));
      expect(PeriodUnit.fromString('months'), equals(PeriodUnit.months));
      expect(PeriodUnit.fromString('years'), equals(PeriodUnit.years));
    });

    test('fromString throws ArgumentError for unknown value', () {
      expect(
        () => PeriodUnit.fromString('unknown'),
        throwsArgumentError,
      );
    });
  });

  group('DateRange', () {
    test('duration', () {
      final range = DateRange(start: fixedStart, end: fixedEnd);
      expect(range.duration, equals(fixedEnd.difference(fixedStart)));
    });

    test('contains inclusive boundaries', () {
      final range = DateRange(start: fixedStart, end: fixedEnd);
      expect(range.contains(fixedStart), isTrue);
      expect(range.contains(fixedEnd), isTrue);
      expect(
          range.contains(fixedStart.add(const Duration(minutes: 1))), isTrue);
      expect(range.contains(fixedStart.subtract(const Duration(seconds: 1))),
          isFalse);
      expect(
          range.contains(fixedEnd.add(const Duration(seconds: 1))), isFalse);
    });

    test('equality and hashCode', () {
      final a = DateRange(start: fixedStart, end: fixedEnd);
      final b = DateRange(start: fixedStart, end: fixedEnd);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  // =========================================================================
  // confidence.dart
  // =========================================================================
  group('Confidence', () {
    test('clamp constrains to 0.0-1.0', () {
      expect(Confidence.clamp(-0.5), equals(0.0));
      expect(Confidence.clamp(0.5), equals(0.5));
      expect(Confidence.clamp(1.5), equals(1.0));
    });

    test('average', () {
      expect(Confidence.average([0.8, 0.6, 0.4]), closeTo(0.6, 0.001));
      expect(Confidence.average([]), equals(0.0));
    });

    test('minimum', () {
      expect(Confidence.minimum([0.8, 0.3, 0.6]), equals(0.3));
      expect(Confidence.minimum([]), equals(0.0));
    });

    test('weightedAverage', () {
      expect(
        Confidence.weightedAverage([0.8, 0.4], [2.0, 1.0]),
        closeTo(0.6667, 0.001),
      );
      expect(Confidence.weightedAverage([], []), equals(0.0));
      expect(
          Confidence.weightedAverage([0.5], [0.5, 0.5]), equals(0.0)); // mismatch
    });

    test('withDecay exponential decay calculation', () {
      // No age: no decay
      final fresh = Confidence.withDecay(
        baseConfidence: 0.9,
        age: Duration.zero,
        halfLife: const Duration(days: 30),
      );
      expect(fresh, equals(0.9));

      // Age equals halfLife: decayFactor = 0.5 * 1.0 = 0.5
      // result = 0.9 * (1.0 - 0.5) = 0.9 * 0.5 = 0.45
      final halfDecay = Confidence.withDecay(
        baseConfidence: 0.9,
        age: const Duration(days: 30),
        halfLife: const Duration(days: 30),
      );
      expect(halfDecay, closeTo(0.45, 0.001));

      // Age is twice the halfLife: decayFactor = 0.5 * 2.0 = 1.0
      // result = 0.9 * (1.0 - 1.0).clamp(0,1) = 0.9 * 0.0 = 0.0
      final fullDecay = Confidence.withDecay(
        baseConfidence: 0.9,
        age: const Duration(days: 60),
        halfLife: const Duration(days: 30),
      );
      expect(fullDecay, equals(0.0));

      // Zero halfLife returns base confidence unchanged
      final zeroHalfLife = Confidence.withDecay(
        baseConfidence: 0.9,
        age: const Duration(days: 10),
        halfLife: Duration.zero,
      );
      expect(zeroHalfLife, equals(0.9));
    });

    test('withDecay partial decay', () {
      // Age is 15 days, halfLife 30 days:
      // decayFactor = 0.5 * (15/30) = 0.5 * 0.5 = 0.25
      // result = 0.8 * (1.0 - 0.25) = 0.8 * 0.75 = 0.6
      final result = Confidence.withDecay(
        baseConfidence: 0.8,
        age: const Duration(days: 15),
        halfLife: const Duration(days: 30),
      );
      expect(result, closeTo(0.6, 0.001));
    });
  });

  // =========================================================================
  // ConfidenceLevel
  // =========================================================================
  group('ConfidenceLevel', () {
    test('fromScore for boundary values', () {
      expect(ConfidenceLevel.fromScore(0.0), equals(ConfidenceLevel.veryLow));
      expect(ConfidenceLevel.fromScore(0.29), equals(ConfidenceLevel.veryLow));
      expect(ConfidenceLevel.fromScore(0.3), equals(ConfidenceLevel.low));
      expect(ConfidenceLevel.fromScore(0.5), equals(ConfidenceLevel.medium));
      expect(ConfidenceLevel.fromScore(0.7), equals(ConfidenceLevel.high));
      expect(ConfidenceLevel.fromScore(0.9), equals(ConfidenceLevel.veryHigh));
      expect(ConfidenceLevel.fromScore(1.0), equals(ConfidenceLevel.veryHigh));
    });

    test('fromScore throws for out of range', () {
      expect(() => ConfidenceLevel.fromScore(-0.1), throwsArgumentError);
      expect(() => ConfidenceLevel.fromScore(1.1), throwsArgumentError);
    });

    test('labels', () {
      expect(ConfidenceLevel.veryLow.label, equals('Very Low'));
      expect(ConfidenceLevel.low.label, equals('Low'));
      expect(ConfidenceLevel.medium.label, equals('Medium'));
      expect(ConfidenceLevel.high.label, equals('High'));
      expect(ConfidenceLevel.veryHigh.label, equals('Very High'));
    });
  });
}
