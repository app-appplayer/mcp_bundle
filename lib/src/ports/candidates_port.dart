/// Candidates Port - Candidate management (pending facts awaiting review).
///
/// Capability-named port per REDESIGN-PLAN.md §3.1.
///
/// Provider: `mcp_fact_graph`.
library;

/// Candidate lifecycle states.
enum CandidateStatus {
  /// Pending review.
  pending,

  /// Confirmed into the fact graph.
  confirmed,

  /// Rejected (with reason).
  rejected,
}

/// Port for candidate fact operations.
abstract class CandidatesPort {
  /// Create a batch of candidates.
  Future<List<String>> createCandidates(List<CandidateRecord> candidates);

  /// Get candidates in pending state for a workspace.
  Future<List<CandidateRecord>> getPendingCandidates(
    String workspaceId, {
    int? limit,
  });

  /// Confirm a candidate (promote to fact).
  Future<void> confirmCandidate(String candidateId, {String? reviewerId});

  /// Reject a candidate with a reason.
  Future<void> rejectCandidate(
    String candidateId,
    String reason, {
    String? reviewerId,
  });
}

/// Canonical candidate record.
class CandidateRecord {
  /// Candidate identifier (assigned on create).
  final String id;

  /// Workspace identifier.
  final String workspaceId;

  /// Candidate type.
  final String type;

  /// Candidate content.
  final Map<String, dynamic> content;

  /// Lifecycle status.
  final CandidateStatus status;

  /// Evidence references.
  final List<String> evidenceRefs;

  /// Confidence score.
  final double? confidence;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Reviewer identifier when processed.
  final String? reviewerId;

  /// Rejection reason (when rejected).
  final String? rejectionReason;

  const CandidateRecord({
    required this.id,
    required this.workspaceId,
    required this.type,
    required this.content,
    this.status = CandidateStatus.pending,
    this.evidenceRefs = const [],
    this.confidence,
    required this.createdAt,
    this.reviewerId,
    this.rejectionReason,
  });
}

/// Stub implementation for testing.
class StubCandidatesPort implements CandidatesPort {
  const StubCandidatesPort();

  @override
  Future<List<String>> createCandidates(
    List<CandidateRecord> candidates,
  ) async {
    return candidates.map((c) => c.id).toList();
  }

  @override
  Future<List<CandidateRecord>> getPendingCandidates(
    String workspaceId, {
    int? limit,
  }) async =>
      [];

  @override
  Future<void> confirmCandidate(
    String candidateId, {
    String? reviewerId,
  }) async {}

  @override
  Future<void> rejectCandidate(
    String candidateId,
    String reason, {
    String? reviewerId,
  }) async {}
}
