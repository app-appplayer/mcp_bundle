/// ApprovalPort - Interface for approval workflow operations.
///
/// Used by mcp_profile's DecisionPolicy when require_approval modifier is set.
/// Used by mcp_knowledge_ops for workflow approval stages.
library;

/// Port for requesting and managing approvals.
abstract class ApprovalPort {
  /// Request approval for an action.
  Future<ApprovalResult> requestApproval(ApprovalRequest request);

  /// Check the status of an existing approval request.
  Future<ApprovalStatus> checkStatus(String approvalId);

  /// Cancel a pending approval request.
  Future<void> cancelApproval(String approvalId);

  /// Watch for approval status changes.
  Stream<ApprovalEvent> watchApproval(String approvalId);

  /// Get approval history for an entity.
  Future<List<ApprovalRecord>> getHistory({
    String? entityId,
    String? requesterId,
    DateTime? since,
    int limit = 100,
  });
}

/// Approval request details.
class ApprovalRequest {
  /// Unique request identifier.
  final String requestId;

  /// Type of request (e.g., 'skill_execution', 'profile_change', 'data_export').
  final String requestType;

  /// ID of the requester (user or system).
  final String requesterId;

  /// Human-readable description of what needs approval.
  final String description;

  /// Context data for the approval decision.
  final Map<String, dynamic> context;

  /// List of user/role IDs who can approve.
  final List<String> approverIds;

  /// Optional timeout for the request.
  final Duration? timeout;

  /// Approval policy to use.
  final ApprovalPolicy policy;

  /// Priority of the request.
  final ApprovalPriority priority;

  /// Entity ID this approval is related to.
  final String? entityId;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const ApprovalRequest({
    required this.requestId,
    required this.requestType,
    required this.requesterId,
    required this.description,
    this.context = const {},
    required this.approverIds,
    this.timeout,
    this.policy = ApprovalPolicy.anyOne,
    this.priority = ApprovalPriority.normal,
    this.entityId,
    this.metadata = const {},
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      requestId: json['requestId'] as String,
      requestType: json['requestType'] as String,
      requesterId: json['requesterId'] as String,
      description: json['description'] as String,
      context: json['context'] as Map<String, dynamic>? ?? {},
      approverIds: (json['approverIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      timeout: json['timeoutSeconds'] != null
          ? Duration(seconds: json['timeoutSeconds'] as int)
          : null,
      policy: ApprovalPolicy.fromString(
          json['policy'] as String? ?? 'anyOne'),
      priority: ApprovalPriority.fromString(
          json['priority'] as String? ?? 'normal'),
      entityId: json['entityId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'requestType': requestType,
        'requesterId': requesterId,
        'description': description,
        if (context.isNotEmpty) 'context': context,
        'approverIds': approverIds,
        if (timeout != null) 'timeoutSeconds': timeout!.inSeconds,
        'policy': policy.name,
        'priority': priority.name,
        if (entityId != null) 'entityId': entityId,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

/// Approval policy determines how approvals are collected.
enum ApprovalPolicy {
  /// Any single approver can approve.
  anyOne,

  /// All approvers must approve.
  allRequired,

  /// Majority of approvers must approve.
  majority,

  /// Approvers must approve in sequence.
  sequential;

  static ApprovalPolicy fromString(String value) {
    return ApprovalPolicy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ApprovalPolicy.anyOne,
    );
  }
}

/// Priority of approval request.
enum ApprovalPriority {
  low,
  normal,
  high,
  urgent;

  static ApprovalPriority fromString(String value) {
    return ApprovalPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ApprovalPriority.normal,
    );
  }
}

/// Result of an approval request.
class ApprovalResult {
  /// Approval ID for tracking.
  final String approvalId;

  /// Current status.
  final ApprovalStatus status;

  /// ID of the approver who made the decision (if decided).
  final String? approverId;

  /// Reason provided by the approver.
  final String? reason;

  /// When the decision was made.
  final DateTime? decidedAt;

  /// List of all approval decisions (for multi-approver policies).
  final List<ApprovalDecision> decisions;

  const ApprovalResult({
    required this.approvalId,
    required this.status,
    this.approverId,
    this.reason,
    this.decidedAt,
    this.decisions = const [],
  });

  factory ApprovalResult.fromJson(Map<String, dynamic> json) {
    return ApprovalResult(
      approvalId: json['approvalId'] as String,
      status: ApprovalStatus.fromString(json['status'] as String),
      approverId: json['approverId'] as String?,
      reason: json['reason'] as String?,
      decidedAt: json['decidedAt'] != null
          ? DateTime.parse(json['decidedAt'] as String)
          : null,
      decisions: (json['decisions'] as List<dynamic>?)
              ?.map((e) => ApprovalDecision.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'approvalId': approvalId,
        'status': status.name,
        if (approverId != null) 'approverId': approverId,
        if (reason != null) 'reason': reason,
        if (decidedAt != null) 'decidedAt': decidedAt!.toIso8601String(),
        if (decisions.isNotEmpty)
          'decisions': decisions.map((d) => d.toJson()).toList(),
      };

  /// Check if approved.
  bool get isApproved => status == ApprovalStatus.approved;

  /// Check if rejected.
  bool get isRejected => status == ApprovalStatus.rejected;

  /// Check if still pending.
  bool get isPending => status == ApprovalStatus.pending;
}

/// Status of an approval request.
enum ApprovalStatus {
  /// Waiting for approval.
  pending,

  /// Approved.
  approved,

  /// Rejected.
  rejected,

  /// Expired (timeout).
  expired,

  /// Cancelled by requester.
  cancelled,

  /// Escalated to higher authority.
  escalated;

  static ApprovalStatus fromString(String value) {
    return ApprovalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ApprovalStatus.pending,
    );
  }
}

/// Individual approval decision.
class ApprovalDecision {
  /// ID of the approver.
  final String approverId;

  /// Decision made.
  final ApprovalDecisionType decision;

  /// Reason for the decision.
  final String? reason;

  /// When the decision was made.
  final DateTime decidedAt;

  const ApprovalDecision({
    required this.approverId,
    required this.decision,
    this.reason,
    required this.decidedAt,
  });

  factory ApprovalDecision.fromJson(Map<String, dynamic> json) {
    return ApprovalDecision(
      approverId: json['approverId'] as String,
      decision: ApprovalDecisionType.fromString(json['decision'] as String),
      reason: json['reason'] as String?,
      decidedAt: DateTime.parse(json['decidedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'approverId': approverId,
        'decision': decision.name,
        if (reason != null) 'reason': reason,
        'decidedAt': decidedAt.toIso8601String(),
      };
}

/// Type of decision made by an approver.
enum ApprovalDecisionType {
  approve,
  reject,
  delegate,
  abstain;

  static ApprovalDecisionType fromString(String value) {
    return ApprovalDecisionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ApprovalDecisionType.abstain,
    );
  }
}

/// Event emitted when approval status changes.
class ApprovalEvent {
  /// Approval ID.
  final String approvalId;

  /// Type of event.
  final ApprovalEventType eventType;

  /// Previous status.
  final ApprovalStatus? previousStatus;

  /// Current status.
  final ApprovalStatus currentStatus;

  /// Who triggered the event.
  final String? actorId;

  /// When the event occurred.
  final DateTime timestamp;

  /// Additional event data.
  final Map<String, dynamic> data;

  const ApprovalEvent({
    required this.approvalId,
    required this.eventType,
    this.previousStatus,
    required this.currentStatus,
    this.actorId,
    required this.timestamp,
    this.data = const {},
  });

  factory ApprovalEvent.fromJson(Map<String, dynamic> json) {
    return ApprovalEvent(
      approvalId: json['approvalId'] as String,
      eventType: ApprovalEventType.fromString(json['eventType'] as String),
      previousStatus: json['previousStatus'] != null
          ? ApprovalStatus.fromString(json['previousStatus'] as String)
          : null,
      currentStatus: ApprovalStatus.fromString(json['currentStatus'] as String),
      actorId: json['actorId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'approvalId': approvalId,
        'eventType': eventType.name,
        if (previousStatus != null) 'previousStatus': previousStatus!.name,
        'currentStatus': currentStatus.name,
        if (actorId != null) 'actorId': actorId,
        'timestamp': timestamp.toIso8601String(),
        if (data.isNotEmpty) 'data': data,
      };
}

/// Type of approval event.
enum ApprovalEventType {
  created,
  approved,
  rejected,
  expired,
  cancelled,
  escalated,
  reminded,
  delegated;

  static ApprovalEventType fromString(String value) {
    return ApprovalEventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ApprovalEventType.created,
    );
  }
}

/// Historical approval record.
class ApprovalRecord {
  /// Approval ID.
  final String approvalId;

  /// Original request.
  final ApprovalRequest request;

  /// Final result.
  final ApprovalResult result;

  /// When the request was created.
  final DateTime createdAt;

  /// When it was resolved (if resolved).
  final DateTime? resolvedAt;

  const ApprovalRecord({
    required this.approvalId,
    required this.request,
    required this.result,
    required this.createdAt,
    this.resolvedAt,
  });

  factory ApprovalRecord.fromJson(Map<String, dynamic> json) {
    return ApprovalRecord(
      approvalId: json['approvalId'] as String,
      request: ApprovalRequest.fromJson(json['request'] as Map<String, dynamic>),
      result: ApprovalResult.fromJson(json['result'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'approvalId': approvalId,
        'request': request.toJson(),
        'result': result.toJson(),
        'createdAt': createdAt.toIso8601String(),
        if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
      };
}

/// Stub implementation for testing.
class StubApprovalPort implements ApprovalPort {
  final Map<String, ApprovalResult> _approvals = {};
  final Duration _autoApproveDelay;
  final bool _autoApprove;

  StubApprovalPort({
    Duration autoApproveDelay = const Duration(milliseconds: 100),
    bool autoApprove = true,
  })  : _autoApproveDelay = autoApproveDelay,
        _autoApprove = autoApprove;

  @override
  Future<ApprovalResult> requestApproval(ApprovalRequest request) async {
    final result = ApprovalResult(
      approvalId: request.requestId,
      status: ApprovalStatus.pending,
    );
    _approvals[request.requestId] = result;

    if (_autoApprove) {
      await Future<void>.delayed(_autoApproveDelay);
      _approvals[request.requestId] = ApprovalResult(
        approvalId: request.requestId,
        status: ApprovalStatus.approved,
        approverId: 'stub_approver',
        decidedAt: DateTime.now(),
      );
    }

    return _approvals[request.requestId]!;
  }

  @override
  Future<ApprovalStatus> checkStatus(String approvalId) async {
    return _approvals[approvalId]?.status ?? ApprovalStatus.pending;
  }

  @override
  Future<void> cancelApproval(String approvalId) async {
    _approvals[approvalId] = ApprovalResult(
      approvalId: approvalId,
      status: ApprovalStatus.cancelled,
    );
  }

  @override
  Stream<ApprovalEvent> watchApproval(String approvalId) async* {
    yield ApprovalEvent(
      approvalId: approvalId,
      eventType: ApprovalEventType.created,
      currentStatus: ApprovalStatus.pending,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<List<ApprovalRecord>> getHistory({
    String? entityId,
    String? requesterId,
    DateTime? since,
    int limit = 100,
  }) async {
    return [];
  }
}
