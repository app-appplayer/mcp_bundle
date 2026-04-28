import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  // ==========================================================================
  // ApprovalPolicy enum
  // ==========================================================================
  group('ApprovalPolicy', () {
    test('has all expected values', () {
      expect(ApprovalPolicy.values, containsAll([
        ApprovalPolicy.anyOne,
        ApprovalPolicy.allRequired,
        ApprovalPolicy.majority,
        ApprovalPolicy.sequential,
      ]));
    });

    test('fromString resolves known values', () {
      expect(ApprovalPolicy.fromString('anyOne'), ApprovalPolicy.anyOne);
      expect(
        ApprovalPolicy.fromString('allRequired'),
        ApprovalPolicy.allRequired,
      );
      expect(ApprovalPolicy.fromString('majority'), ApprovalPolicy.majority);
      expect(
        ApprovalPolicy.fromString('sequential'),
        ApprovalPolicy.sequential,
      );
    });

    test('fromString defaults to anyOne for unknown value', () {
      expect(ApprovalPolicy.fromString('unknown'), ApprovalPolicy.anyOne);
      expect(ApprovalPolicy.fromString(''), ApprovalPolicy.anyOne);
    });
  });

  // ==========================================================================
  // ApprovalPriority enum
  // ==========================================================================
  group('ApprovalPriority', () {
    test('has all expected values', () {
      expect(ApprovalPriority.values, containsAll([
        ApprovalPriority.low,
        ApprovalPriority.normal,
        ApprovalPriority.high,
        ApprovalPriority.urgent,
      ]));
    });

    test('fromString resolves known values', () {
      expect(ApprovalPriority.fromString('low'), ApprovalPriority.low);
      expect(ApprovalPriority.fromString('normal'), ApprovalPriority.normal);
      expect(ApprovalPriority.fromString('high'), ApprovalPriority.high);
      expect(ApprovalPriority.fromString('urgent'), ApprovalPriority.urgent);
    });

    test('fromString defaults to normal for unknown value', () {
      expect(ApprovalPriority.fromString('critical'), ApprovalPriority.normal);
      expect(ApprovalPriority.fromString(''), ApprovalPriority.normal);
    });
  });

  // ==========================================================================
  // ApprovalStatus enum
  // ==========================================================================
  group('ApprovalStatus', () {
    test('has all expected values', () {
      expect(ApprovalStatus.values, containsAll([
        ApprovalStatus.pending,
        ApprovalStatus.approved,
        ApprovalStatus.rejected,
        ApprovalStatus.expired,
        ApprovalStatus.cancelled,
        ApprovalStatus.escalated,
      ]));
    });

    test('fromString resolves known values', () {
      expect(ApprovalStatus.fromString('pending'), ApprovalStatus.pending);
      expect(ApprovalStatus.fromString('approved'), ApprovalStatus.approved);
      expect(ApprovalStatus.fromString('rejected'), ApprovalStatus.rejected);
      expect(ApprovalStatus.fromString('expired'), ApprovalStatus.expired);
      expect(ApprovalStatus.fromString('cancelled'), ApprovalStatus.cancelled);
      expect(ApprovalStatus.fromString('escalated'), ApprovalStatus.escalated);
    });

    test('fromString defaults to pending for unknown value', () {
      expect(ApprovalStatus.fromString('unknown'), ApprovalStatus.pending);
      expect(ApprovalStatus.fromString(''), ApprovalStatus.pending);
    });
  });

  // ==========================================================================
  // ApprovalDecisionType enum
  // ==========================================================================
  group('ApprovalDecisionType', () {
    test('has all expected values', () {
      expect(ApprovalDecisionType.values, containsAll([
        ApprovalDecisionType.approve,
        ApprovalDecisionType.reject,
        ApprovalDecisionType.delegate,
        ApprovalDecisionType.abstain,
      ]));
    });

    test('fromString resolves known values', () {
      expect(
        ApprovalDecisionType.fromString('approve'),
        ApprovalDecisionType.approve,
      );
      expect(
        ApprovalDecisionType.fromString('reject'),
        ApprovalDecisionType.reject,
      );
      expect(
        ApprovalDecisionType.fromString('delegate'),
        ApprovalDecisionType.delegate,
      );
      expect(
        ApprovalDecisionType.fromString('abstain'),
        ApprovalDecisionType.abstain,
      );
    });

    test('fromString defaults to abstain for unknown value', () {
      expect(
        ApprovalDecisionType.fromString('skip'),
        ApprovalDecisionType.abstain,
      );
      expect(
        ApprovalDecisionType.fromString(''),
        ApprovalDecisionType.abstain,
      );
    });
  });

  // ==========================================================================
  // ApprovalEventType enum
  // ==========================================================================
  group('ApprovalEventType', () {
    test('has all expected values', () {
      expect(ApprovalEventType.values, containsAll([
        ApprovalEventType.created,
        ApprovalEventType.approved,
        ApprovalEventType.rejected,
        ApprovalEventType.expired,
        ApprovalEventType.cancelled,
        ApprovalEventType.escalated,
        ApprovalEventType.reminded,
        ApprovalEventType.delegated,
      ]));
    });

    test('fromString resolves known values', () {
      expect(
        ApprovalEventType.fromString('created'),
        ApprovalEventType.created,
      );
      expect(
        ApprovalEventType.fromString('approved'),
        ApprovalEventType.approved,
      );
      expect(
        ApprovalEventType.fromString('rejected'),
        ApprovalEventType.rejected,
      );
      expect(
        ApprovalEventType.fromString('expired'),
        ApprovalEventType.expired,
      );
      expect(
        ApprovalEventType.fromString('cancelled'),
        ApprovalEventType.cancelled,
      );
      expect(
        ApprovalEventType.fromString('escalated'),
        ApprovalEventType.escalated,
      );
      expect(
        ApprovalEventType.fromString('reminded'),
        ApprovalEventType.reminded,
      );
      expect(
        ApprovalEventType.fromString('delegated'),
        ApprovalEventType.delegated,
      );
    });

    test('fromString defaults to created for unknown value', () {
      expect(
        ApprovalEventType.fromString('unknown'),
        ApprovalEventType.created,
      );
    });
  });

  // ==========================================================================
  // ApprovalRequest
  // ==========================================================================
  group('ApprovalRequest', () {
    test('constructs with required fields and defaults', () {
      const request = ApprovalRequest(
        requestId: 'req-1',
        requestType: 'skill_execution',
        requesterId: 'user-1',
        description: 'Execute dangerous skill',
        approverIds: ['admin-1', 'admin-2'],
      );
      expect(request.requestId, equals('req-1'));
      expect(request.requestType, equals('skill_execution'));
      expect(request.requesterId, equals('user-1'));
      expect(request.description, equals('Execute dangerous skill'));
      expect(request.context, isEmpty);
      expect(request.approverIds, equals(['admin-1', 'admin-2']));
      expect(request.timeout, isNull);
      expect(request.policy, equals(ApprovalPolicy.anyOne));
      expect(request.priority, equals(ApprovalPriority.normal));
      expect(request.entityId, isNull);
      expect(request.metadata, isEmpty);
    });

    test('constructs with all fields', () {
      const request = ApprovalRequest(
        requestId: 'req-2',
        requestType: 'data_export',
        requesterId: 'user-2',
        description: 'Export sensitive data',
        context: {'dataType': 'PII', 'recordCount': 1000},
        approverIds: ['admin-1'],
        timeout: Duration(hours: 24),
        policy: ApprovalPolicy.allRequired,
        priority: ApprovalPriority.urgent,
        entityId: 'entity-42',
        metadata: {'source': 'automation'},
      );
      expect(request.context['dataType'], equals('PII'));
      expect(request.timeout, equals(const Duration(hours: 24)));
      expect(request.policy, equals(ApprovalPolicy.allRequired));
      expect(request.priority, equals(ApprovalPriority.urgent));
      expect(request.entityId, equals('entity-42'));
      expect(request.metadata['source'], equals('automation'));
    });

    test('fromJson creates correct instance with all fields', () {
      final request = ApprovalRequest.fromJson({
        'requestId': 'req-3',
        'requestType': 'profile_change',
        'requesterId': 'user-3',
        'description': 'Update profile permissions',
        'context': {'field': 'role', 'newValue': 'admin'},
        'approverIds': ['super-admin'],
        'timeoutSeconds': 3600,
        'policy': 'majority',
        'priority': 'high',
        'entityId': 'profile-99',
        'metadata': {'reason': 'promotion'},
      });
      expect(request.requestId, equals('req-3'));
      expect(request.requestType, equals('profile_change'));
      expect(request.requesterId, equals('user-3'));
      expect(request.description, equals('Update profile permissions'));
      expect(request.context['field'], equals('role'));
      expect(request.approverIds, equals(['super-admin']));
      expect(request.timeout, equals(const Duration(seconds: 3600)));
      expect(request.policy, equals(ApprovalPolicy.majority));
      expect(request.priority, equals(ApprovalPriority.high));
      expect(request.entityId, equals('profile-99'));
      expect(request.metadata['reason'], equals('promotion'));
    });

    test('fromJson uses defaults for missing optional fields', () {
      final request = ApprovalRequest.fromJson({
        'requestId': 'req-4',
        'requestType': 'test',
        'requesterId': 'user-4',
        'description': 'Minimal request',
        'approverIds': ['approver-1'],
      });
      expect(request.context, isEmpty);
      expect(request.timeout, isNull);
      expect(request.policy, equals(ApprovalPolicy.anyOne));
      expect(request.priority, equals(ApprovalPriority.normal));
      expect(request.entityId, isNull);
      expect(request.metadata, isEmpty);
    });

    test('toJson includes all present fields', () {
      const request = ApprovalRequest(
        requestId: 'req-5',
        requestType: 'skill_execution',
        requesterId: 'user-5',
        description: 'Run skill X',
        context: {'skillId': 'X'},
        approverIds: ['admin-1', 'admin-2'],
        timeout: Duration(minutes: 30),
        policy: ApprovalPolicy.sequential,
        priority: ApprovalPriority.low,
        entityId: 'entity-5',
        metadata: {'tag': 'auto'},
      );
      final json = request.toJson();
      expect(json['requestId'], equals('req-5'));
      expect(json['requestType'], equals('skill_execution'));
      expect(json['requesterId'], equals('user-5'));
      expect(json['description'], equals('Run skill X'));
      expect(json['context'], isA<Map<String, dynamic>>());
      expect(json['approverIds'], equals(['admin-1', 'admin-2']));
      expect(json['timeoutSeconds'], equals(1800));
      expect(json['policy'], equals('sequential'));
      expect(json['priority'], equals('low'));
      expect(json['entityId'], equals('entity-5'));
      expect(json['metadata'], isA<Map<String, dynamic>>());
    });

    test('toJson omits empty context, null timeout, null entityId, empty metadata', () {
      const request = ApprovalRequest(
        requestId: 'req-6',
        requestType: 'test',
        requesterId: 'user-6',
        description: 'Sparse request',
        approverIds: ['approver-1'],
      );
      final json = request.toJson();
      expect(json.containsKey('context'), isFalse);
      expect(json.containsKey('timeoutSeconds'), isFalse);
      expect(json.containsKey('entityId'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
      // policy and priority always included
      expect(json['policy'], equals('anyOne'));
      expect(json['priority'], equals('normal'));
    });

    test('fromJson/toJson roundtrip preserves data', () {
      const original = ApprovalRequest(
        requestId: 'req-rt',
        requestType: 'data_export',
        requesterId: 'user-rt',
        description: 'Roundtrip test',
        context: {'key': 'value'},
        approverIds: ['admin-A', 'admin-B'],
        timeout: Duration(hours: 2),
        policy: ApprovalPolicy.allRequired,
        priority: ApprovalPriority.high,
        entityId: 'ent-rt',
        metadata: {'env': 'staging'},
      );
      final restored = ApprovalRequest.fromJson(original.toJson());
      expect(restored.requestId, equals(original.requestId));
      expect(restored.requestType, equals(original.requestType));
      expect(restored.requesterId, equals(original.requesterId));
      expect(restored.description, equals(original.description));
      expect(restored.context['key'], equals('value'));
      expect(restored.approverIds, equals(original.approverIds));
      expect(restored.timeout, equals(original.timeout));
      expect(restored.policy, equals(original.policy));
      expect(restored.priority, equals(original.priority));
      expect(restored.entityId, equals(original.entityId));
      expect(restored.metadata['env'], equals('staging'));
    });
  });

  // ==========================================================================
  // ApprovalDecision
  // ==========================================================================
  group('ApprovalDecision', () {
    test('constructs with required fields', () {
      final decidedAt = DateTime.utc(2025, 6, 15, 14, 0);
      final decision = ApprovalDecision(
        approverId: 'admin-1',
        decision: ApprovalDecisionType.approve,
        decidedAt: decidedAt,
      );
      expect(decision.approverId, equals('admin-1'));
      expect(decision.decision, equals(ApprovalDecisionType.approve));
      expect(decision.reason, isNull);
      expect(decision.decidedAt, equals(decidedAt));
    });

    test('constructs with all fields including reason', () {
      final decidedAt = DateTime.utc(2025, 6, 15);
      final decision = ApprovalDecision(
        approverId: 'admin-2',
        decision: ApprovalDecisionType.reject,
        reason: 'Not compliant with policy',
        decidedAt: decidedAt,
      );
      expect(decision.reason, equals('Not compliant with policy'));
      expect(decision.decidedAt, equals(decidedAt));
    });

    test('fromJson creates correct instance', () {
      final decision = ApprovalDecision.fromJson({
        'approverId': 'admin-3',
        'decision': 'delegate',
        'reason': 'Delegated to team lead',
        'decidedAt': '2025-06-15T10:00:00.000Z',
      });
      expect(decision.approverId, equals('admin-3'));
      expect(decision.decision, equals(ApprovalDecisionType.delegate));
      expect(decision.reason, equals('Delegated to team lead'));
      expect(decision.decidedAt, equals(DateTime.utc(2025, 6, 15, 10, 0)));
    });

    test('fromJson without optional reason', () {
      final decision = ApprovalDecision.fromJson({
        'approverId': 'admin-4',
        'decision': 'approve',
        'decidedAt': '2025-01-01T00:00:00.000Z',
      });
      expect(decision.reason, isNull);
    });

    test('toJson includes all present fields', () {
      final decision = ApprovalDecision(
        approverId: 'admin-5',
        decision: ApprovalDecisionType.abstain,
        reason: 'Conflict of interest',
        decidedAt: DateTime.utc(2025, 3, 1),
      );
      final json = decision.toJson();
      expect(json['approverId'], equals('admin-5'));
      expect(json['decision'], equals('abstain'));
      expect(json['reason'], equals('Conflict of interest'));
      expect(json['decidedAt'], equals('2025-03-01T00:00:00.000Z'));
    });

    test('toJson omits null reason', () {
      final decision = ApprovalDecision(
        approverId: 'admin-6',
        decision: ApprovalDecisionType.approve,
        decidedAt: DateTime.utc(2025, 1, 1),
      );
      final json = decision.toJson();
      expect(json.containsKey('reason'), isFalse);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = ApprovalDecision(
        approverId: 'admin-rt',
        decision: ApprovalDecisionType.reject,
        reason: 'Roundtrip reason',
        decidedAt: DateTime.utc(2025, 7, 4, 12, 30),
      );
      final restored = ApprovalDecision.fromJson(original.toJson());
      expect(restored.approverId, equals(original.approverId));
      expect(restored.decision, equals(original.decision));
      expect(restored.reason, equals(original.reason));
      expect(restored.decidedAt, equals(original.decidedAt));
    });
  });

  // ==========================================================================
  // ApprovalResult
  // ==========================================================================
  group('ApprovalResult', () {
    test('constructs with required fields and defaults', () {
      const result = ApprovalResult(
        approvalId: 'apr-1',
        status: ApprovalStatus.pending,
      );
      expect(result.approvalId, equals('apr-1'));
      expect(result.status, equals(ApprovalStatus.pending));
      expect(result.approverId, isNull);
      expect(result.reason, isNull);
      expect(result.decidedAt, isNull);
      expect(result.decisions, isEmpty);
    });

    test('constructs with all fields', () {
      final decidedAt = DateTime.utc(2025, 6, 15);
      final result = ApprovalResult(
        approvalId: 'apr-2',
        status: ApprovalStatus.approved,
        approverId: 'admin-1',
        reason: 'Looks good',
        decidedAt: decidedAt,
        decisions: [
          ApprovalDecision(
            approverId: 'admin-1',
            decision: ApprovalDecisionType.approve,
            decidedAt: decidedAt,
          ),
        ],
      );
      expect(result.approverId, equals('admin-1'));
      expect(result.reason, equals('Looks good'));
      expect(result.decidedAt, equals(decidedAt));
      expect(result.decisions, hasLength(1));
    });

    test('isApproved returns true only for approved status', () {
      const approved = ApprovalResult(
        approvalId: 'apr-a',
        status: ApprovalStatus.approved,
      );
      expect(approved.isApproved, isTrue);
      expect(approved.isRejected, isFalse);
      expect(approved.isPending, isFalse);
    });

    test('isRejected returns true only for rejected status', () {
      const rejected = ApprovalResult(
        approvalId: 'apr-r',
        status: ApprovalStatus.rejected,
      );
      expect(rejected.isRejected, isTrue);
      expect(rejected.isApproved, isFalse);
      expect(rejected.isPending, isFalse);
    });

    test('isPending returns true only for pending status', () {
      const pending = ApprovalResult(
        approvalId: 'apr-p',
        status: ApprovalStatus.pending,
      );
      expect(pending.isPending, isTrue);
      expect(pending.isApproved, isFalse);
      expect(pending.isRejected, isFalse);
    });

    test('isApproved/isRejected/isPending are all false for other statuses', () {
      for (final status in [
        ApprovalStatus.expired,
        ApprovalStatus.cancelled,
        ApprovalStatus.escalated,
      ]) {
        final result = ApprovalResult(
          approvalId: 'apr-check',
          status: status,
        );
        expect(result.isApproved, isFalse,
            reason: '${status.name} should not be approved');
        expect(result.isRejected, isFalse,
            reason: '${status.name} should not be rejected');
        expect(result.isPending, isFalse,
            reason: '${status.name} should not be pending');
      }
    });

    test('fromJson creates correct instance with decisions', () {
      final result = ApprovalResult.fromJson({
        'approvalId': 'apr-json',
        'status': 'approved',
        'approverId': 'admin-json',
        'reason': 'Approved via JSON',
        'decidedAt': '2025-06-15T10:00:00.000Z',
        'decisions': [
          {
            'approverId': 'admin-json',
            'decision': 'approve',
            'reason': 'LGTM',
            'decidedAt': '2025-06-15T10:00:00.000Z',
          },
        ],
      });
      expect(result.approvalId, equals('apr-json'));
      expect(result.status, equals(ApprovalStatus.approved));
      expect(result.approverId, equals('admin-json'));
      expect(result.reason, equals('Approved via JSON'));
      expect(result.decidedAt, equals(DateTime.utc(2025, 6, 15, 10, 0)));
      expect(result.decisions, hasLength(1));
      expect(result.decisions.first.decision, equals(ApprovalDecisionType.approve));
      expect(result.decisions.first.reason, equals('LGTM'));
    });

    test('fromJson works without optional fields', () {
      final result = ApprovalResult.fromJson({
        'approvalId': 'apr-min',
        'status': 'pending',
      });
      expect(result.approverId, isNull);
      expect(result.reason, isNull);
      expect(result.decidedAt, isNull);
      expect(result.decisions, isEmpty);
    });

    test('toJson includes all present fields', () {
      final result = ApprovalResult(
        approvalId: 'apr-tj',
        status: ApprovalStatus.rejected,
        approverId: 'admin-tj',
        reason: 'Policy violation',
        decidedAt: DateTime.utc(2025, 3, 1),
        decisions: [
          ApprovalDecision(
            approverId: 'admin-tj',
            decision: ApprovalDecisionType.reject,
            reason: 'Policy violation',
            decidedAt: DateTime.utc(2025, 3, 1),
          ),
        ],
      );
      final json = result.toJson();
      expect(json['approvalId'], equals('apr-tj'));
      expect(json['status'], equals('rejected'));
      expect(json['approverId'], equals('admin-tj'));
      expect(json['reason'], equals('Policy violation'));
      expect(json['decidedAt'], isA<String>());
      expect(json['decisions'], isA<List<dynamic>>());
      expect((json['decisions'] as List<dynamic>), hasLength(1));
    });

    test('toJson omits null and empty optional fields', () {
      const result = ApprovalResult(
        approvalId: 'apr-sparse',
        status: ApprovalStatus.pending,
      );
      final json = result.toJson();
      expect(json.containsKey('approverId'), isFalse);
      expect(json.containsKey('reason'), isFalse);
      expect(json.containsKey('decidedAt'), isFalse);
      expect(json.containsKey('decisions'), isFalse);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = ApprovalResult(
        approvalId: 'apr-rt',
        status: ApprovalStatus.approved,
        approverId: 'admin-rt',
        reason: 'All checks passed',
        decidedAt: DateTime.utc(2025, 8, 1),
        decisions: [
          ApprovalDecision(
            approverId: 'admin-rt',
            decision: ApprovalDecisionType.approve,
            reason: 'LGTM',
            decidedAt: DateTime.utc(2025, 8, 1),
          ),
          ApprovalDecision(
            approverId: 'admin-rt-2',
            decision: ApprovalDecisionType.approve,
            decidedAt: DateTime.utc(2025, 8, 1),
          ),
        ],
      );
      final restored = ApprovalResult.fromJson(original.toJson());
      expect(restored.approvalId, equals(original.approvalId));
      expect(restored.status, equals(original.status));
      expect(restored.approverId, equals(original.approverId));
      expect(restored.reason, equals(original.reason));
      expect(restored.decidedAt, equals(original.decidedAt));
      expect(restored.decisions, hasLength(2));
      expect(restored.decisions[0].reason, equals('LGTM'));
      expect(restored.decisions[1].reason, isNull);
    });
  });

  // ==========================================================================
  // ApprovalEvent
  // ==========================================================================
  group('ApprovalEvent', () {
    test('constructs with required fields and defaults', () {
      final ts = DateTime.utc(2025, 6, 15, 10, 0);
      final event = ApprovalEvent(
        approvalId: 'ae-1',
        eventType: ApprovalEventType.created,
        currentStatus: ApprovalStatus.pending,
        timestamp: ts,
      );
      expect(event.approvalId, equals('ae-1'));
      expect(event.eventType, equals(ApprovalEventType.created));
      expect(event.previousStatus, isNull);
      expect(event.currentStatus, equals(ApprovalStatus.pending));
      expect(event.actorId, isNull);
      expect(event.timestamp, equals(ts));
      expect(event.data, isEmpty);
    });

    test('constructs with all fields', () {
      final ts = DateTime.utc(2025, 6, 15, 14, 30);
      final event = ApprovalEvent(
        approvalId: 'ae-2',
        eventType: ApprovalEventType.approved,
        previousStatus: ApprovalStatus.pending,
        currentStatus: ApprovalStatus.approved,
        actorId: 'admin-1',
        timestamp: ts,
        data: const {'comment': 'Approved with conditions'},
      );
      expect(event.previousStatus, equals(ApprovalStatus.pending));
      expect(event.currentStatus, equals(ApprovalStatus.approved));
      expect(event.actorId, equals('admin-1'));
      expect(event.timestamp, equals(ts));
      expect(event.data['comment'], equals('Approved with conditions'));
    });

    test('fromJson creates correct instance with all fields', () {
      final event = ApprovalEvent.fromJson({
        'approvalId': 'ae-json',
        'eventType': 'rejected',
        'previousStatus': 'pending',
        'currentStatus': 'rejected',
        'actorId': 'admin-json',
        'timestamp': '2025-06-15T12:00:00.000Z',
        'data': {'rejectionCode': 'POLICY_VIOLATION'},
      });
      expect(event.approvalId, equals('ae-json'));
      expect(event.eventType, equals(ApprovalEventType.rejected));
      expect(event.previousStatus, equals(ApprovalStatus.pending));
      expect(event.currentStatus, equals(ApprovalStatus.rejected));
      expect(event.actorId, equals('admin-json'));
      expect(event.timestamp, equals(DateTime.utc(2025, 6, 15, 12, 0)));
      expect(event.data['rejectionCode'], equals('POLICY_VIOLATION'));
    });

    test('fromJson works without optional fields', () {
      final event = ApprovalEvent.fromJson({
        'approvalId': 'ae-min',
        'eventType': 'created',
        'currentStatus': 'pending',
        'timestamp': '2025-01-01T00:00:00.000Z',
      });
      expect(event.previousStatus, isNull);
      expect(event.actorId, isNull);
      expect(event.data, isEmpty);
    });

    test('toJson includes all present fields', () {
      final event = ApprovalEvent(
        approvalId: 'ae-tj',
        eventType: ApprovalEventType.escalated,
        previousStatus: ApprovalStatus.pending,
        currentStatus: ApprovalStatus.escalated,
        actorId: 'system',
        timestamp: DateTime.utc(2025, 3, 1),
        data: const {'escalationLevel': 2},
      );
      final json = event.toJson();
      expect(json['approvalId'], equals('ae-tj'));
      expect(json['eventType'], equals('escalated'));
      expect(json['previousStatus'], equals('pending'));
      expect(json['currentStatus'], equals('escalated'));
      expect(json['actorId'], equals('system'));
      expect(json['timestamp'], isA<String>());
      expect(json['data'], isA<Map<String, dynamic>>());
    });

    test('toJson omits null and empty optional fields', () {
      final event = ApprovalEvent(
        approvalId: 'ae-sparse',
        eventType: ApprovalEventType.created,
        currentStatus: ApprovalStatus.pending,
        timestamp: DateTime.utc(2025, 1, 1),
      );
      final json = event.toJson();
      expect(json.containsKey('previousStatus'), isFalse);
      expect(json.containsKey('actorId'), isFalse);
      expect(json.containsKey('data'), isFalse);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = ApprovalEvent(
        approvalId: 'ae-rt',
        eventType: ApprovalEventType.reminded,
        previousStatus: ApprovalStatus.pending,
        currentStatus: ApprovalStatus.pending,
        actorId: 'system',
        timestamp: DateTime.utc(2025, 9, 1, 8, 0),
        data: const {'reminderCount': 3},
      );
      final restored = ApprovalEvent.fromJson(original.toJson());
      expect(restored.approvalId, equals(original.approvalId));
      expect(restored.eventType, equals(original.eventType));
      expect(restored.previousStatus, equals(original.previousStatus));
      expect(restored.currentStatus, equals(original.currentStatus));
      expect(restored.actorId, equals(original.actorId));
      expect(restored.timestamp, equals(original.timestamp));
      expect(restored.data['reminderCount'], equals(3));
    });
  });

  // ==========================================================================
  // ApprovalRecord
  // ==========================================================================
  group('ApprovalRecord', () {
    test('constructs with required fields', () {
      final createdAt = DateTime.utc(2025, 6, 1);
      const request = ApprovalRequest(
        requestId: 'rec-req',
        requestType: 'test',
        requesterId: 'user-1',
        description: 'Record test',
        approverIds: ['admin-1'],
      );
      const result = ApprovalResult(
        approvalId: 'rec-req',
        status: ApprovalStatus.approved,
      );
      final record = ApprovalRecord(
        approvalId: 'rec-req',
        request: request,
        result: result,
        createdAt: createdAt,
      );
      expect(record.approvalId, equals('rec-req'));
      expect(record.request.requestId, equals('rec-req'));
      expect(record.result.status, equals(ApprovalStatus.approved));
      expect(record.createdAt, equals(createdAt));
      expect(record.resolvedAt, isNull);
    });

    test('constructs with resolvedAt', () {
      final createdAt = DateTime.utc(2025, 6, 1);
      final resolvedAt = DateTime.utc(2025, 6, 2);
      final record = ApprovalRecord(
        approvalId: 'rec-2',
        request: const ApprovalRequest(
          requestId: 'rec-2',
          requestType: 'test',
          requesterId: 'user-1',
          description: 'Resolved test',
          approverIds: ['admin-1'],
        ),
        result: const ApprovalResult(
          approvalId: 'rec-2',
          status: ApprovalStatus.rejected,
        ),
        createdAt: createdAt,
        resolvedAt: resolvedAt,
      );
      expect(record.resolvedAt, equals(resolvedAt));
    });

    test('fromJson creates correct instance', () {
      final record = ApprovalRecord.fromJson({
        'approvalId': 'rec-json',
        'request': {
          'requestId': 'rec-json',
          'requestType': 'skill_execution',
          'requesterId': 'user-json',
          'description': 'JSON record test',
          'approverIds': ['admin-1'],
        },
        'result': {
          'approvalId': 'rec-json',
          'status': 'approved',
          'approverId': 'admin-1',
        },
        'createdAt': '2025-06-01T00:00:00.000Z',
        'resolvedAt': '2025-06-02T00:00:00.000Z',
      });
      expect(record.approvalId, equals('rec-json'));
      expect(record.request.requestType, equals('skill_execution'));
      expect(record.result.isApproved, isTrue);
      expect(record.createdAt, equals(DateTime.utc(2025, 6, 1)));
      expect(record.resolvedAt, equals(DateTime.utc(2025, 6, 2)));
    });

    test('fromJson works without optional resolvedAt', () {
      final record = ApprovalRecord.fromJson({
        'approvalId': 'rec-min',
        'request': {
          'requestId': 'rec-min',
          'requestType': 'test',
          'requesterId': 'user-min',
          'description': 'Minimal',
          'approverIds': ['admin-1'],
        },
        'result': {
          'approvalId': 'rec-min',
          'status': 'pending',
        },
        'createdAt': '2025-01-01T00:00:00.000Z',
      });
      expect(record.resolvedAt, isNull);
    });

    test('toJson includes all present fields', () {
      final record = ApprovalRecord(
        approvalId: 'rec-tj',
        request: const ApprovalRequest(
          requestId: 'rec-tj',
          requestType: 'data_export',
          requesterId: 'user-tj',
          description: 'Export data',
          approverIds: ['admin-1'],
        ),
        result: const ApprovalResult(
          approvalId: 'rec-tj',
          status: ApprovalStatus.approved,
        ),
        createdAt: DateTime.utc(2025, 3, 1),
        resolvedAt: DateTime.utc(2025, 3, 2),
      );
      final json = record.toJson();
      expect(json['approvalId'], equals('rec-tj'));
      expect(json['request'], isA<Map<String, dynamic>>());
      expect(json['result'], isA<Map<String, dynamic>>());
      expect(json['createdAt'], equals('2025-03-01T00:00:00.000Z'));
      expect(json['resolvedAt'], equals('2025-03-02T00:00:00.000Z'));
    });

    test('toJson omits null resolvedAt', () {
      final record = ApprovalRecord(
        approvalId: 'rec-sparse',
        request: const ApprovalRequest(
          requestId: 'rec-sparse',
          requestType: 'test',
          requesterId: 'user-1',
          description: 'No resolution',
          approverIds: ['admin-1'],
        ),
        result: const ApprovalResult(
          approvalId: 'rec-sparse',
          status: ApprovalStatus.pending,
        ),
        createdAt: DateTime.utc(2025, 1, 1),
      );
      final json = record.toJson();
      expect(json.containsKey('resolvedAt'), isFalse);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = ApprovalRecord(
        approvalId: 'rec-rt',
        request: const ApprovalRequest(
          requestId: 'rec-rt',
          requestType: 'profile_change',
          requesterId: 'user-rt',
          description: 'Roundtrip record',
          context: {'field': 'permissions'},
          approverIds: ['admin-A', 'admin-B'],
          timeout: Duration(hours: 1),
          policy: ApprovalPolicy.majority,
          priority: ApprovalPriority.high,
          entityId: 'ent-rt',
        ),
        result: ApprovalResult(
          approvalId: 'rec-rt',
          status: ApprovalStatus.approved,
          approverId: 'admin-A',
          reason: 'Approved',
          decidedAt: DateTime.utc(2025, 7, 1, 12, 0),
          decisions: [
            ApprovalDecision(
              approverId: 'admin-A',
              decision: ApprovalDecisionType.approve,
              decidedAt: DateTime.utc(2025, 7, 1, 12, 0),
            ),
          ],
        ),
        createdAt: DateTime.utc(2025, 7, 1),
        resolvedAt: DateTime.utc(2025, 7, 1, 12, 0),
      );
      final restored = ApprovalRecord.fromJson(original.toJson());
      expect(restored.approvalId, equals(original.approvalId));
      expect(restored.request.requestType, equals('profile_change'));
      expect(restored.request.policy, equals(ApprovalPolicy.majority));
      expect(restored.result.isApproved, isTrue);
      expect(restored.result.decisions, hasLength(1));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.resolvedAt, equals(original.resolvedAt));
    });
  });

  // ==========================================================================
  // StubApprovalPort
  // ==========================================================================
  group('StubApprovalPort', () {
    test('requestApproval with autoApprove returns approved', () async {
      final port = StubApprovalPort();
      const request = ApprovalRequest(
        requestId: 'stub-1',
        requestType: 'test',
        requesterId: 'user-1',
        description: 'Auto approve test',
        approverIds: ['admin-1'],
      );
      final result = await port.requestApproval(request);
      expect(result.approvalId, equals('stub-1'));
      expect(result.status, equals(ApprovalStatus.approved));
      expect(result.approverId, equals('stub_approver'));
      expect(result.decidedAt, isNotNull);
    });

    test('requestApproval without autoApprove returns pending', () async {
      final port = StubApprovalPort(autoApprove: false);
      const request = ApprovalRequest(
        requestId: 'stub-2',
        requestType: 'test',
        requesterId: 'user-2',
        description: 'No auto approve',
        approverIds: ['admin-1'],
      );
      final result = await port.requestApproval(request);
      expect(result.approvalId, equals('stub-2'));
      expect(result.status, equals(ApprovalStatus.pending));
      expect(result.approverId, isNull);
    });

    test('checkStatus returns status for known approval', () async {
      final port = StubApprovalPort();
      const request = ApprovalRequest(
        requestId: 'check-1',
        requestType: 'test',
        requesterId: 'user-1',
        description: 'Check status test',
        approverIds: ['admin-1'],
      );
      await port.requestApproval(request);
      final status = await port.checkStatus('check-1');
      expect(status, equals(ApprovalStatus.approved));
    });

    test('checkStatus returns pending for unknown approval', () async {
      final port = StubApprovalPort();
      final status = await port.checkStatus('nonexistent');
      expect(status, equals(ApprovalStatus.pending));
    });

    test('cancelApproval sets status to cancelled', () async {
      final port = StubApprovalPort();
      const request = ApprovalRequest(
        requestId: 'cancel-1',
        requestType: 'test',
        requesterId: 'user-1',
        description: 'Cancel test',
        approverIds: ['admin-1'],
      );
      await port.requestApproval(request);
      await port.cancelApproval('cancel-1');
      final status = await port.checkStatus('cancel-1');
      expect(status, equals(ApprovalStatus.cancelled));
    });

    test('watchApproval emits created event', () async {
      final port = StubApprovalPort();
      final events = await port.watchApproval('watch-1').toList();
      expect(events, hasLength(1));
      expect(events.first.approvalId, equals('watch-1'));
      expect(events.first.eventType, equals(ApprovalEventType.created));
      expect(events.first.currentStatus, equals(ApprovalStatus.pending));
    });

    test('getHistory returns empty list', () async {
      final port = StubApprovalPort();
      final history = await port.getHistory();
      expect(history, isEmpty);
    });

    test('getHistory accepts all filter parameters', () async {
      final port = StubApprovalPort();
      final history = await port.getHistory(
        entityId: 'ent-1',
        requesterId: 'user-1',
        since: DateTime.utc(2025, 1, 1),
        limit: 50,
      );
      expect(history, isEmpty);
    });

    test('autoApproveDelay configures delay', () async {
      final port = StubApprovalPort(
        autoApproveDelay: const Duration(milliseconds: 50),
      );
      const request = ApprovalRequest(
        requestId: 'delay-1',
        requestType: 'test',
        requesterId: 'user-1',
        description: 'Delay test',
        approverIds: ['admin-1'],
      );
      final stopwatch = Stopwatch()..start();
      await port.requestApproval(request);
      stopwatch.stop();
      // The delay should be at least 50ms
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
    });
  });
}
