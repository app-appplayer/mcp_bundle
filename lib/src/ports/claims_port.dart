/// Claims Port - CRUD and validation over claims.
///
/// Capability-named port per REDESIGN-PLAN.md §3.1. Supersedes the
/// claim-related fragments in `SkillFactGraphPort`.
///
/// Provider: `mcp_fact_graph`.
library;

import '../types/claim.dart';
import '../types/period.dart';

/// Port for claim operations.
abstract class ClaimsPort {
  /// Write claims with optional evidence links.
  Future<void> writeClaims(
    List<Claim> claims, {
    List<String>? evidenceRefs,
  });

  /// Query claims.
  Future<List<Claim>> queryClaims(ClaimQuery query);

  /// Validate a set of claims against the fact graph.
  Future<ClaimValidationReport> validateClaims(
    List<Claim> claims, {
    DateTime? asOf,
    String? policyVersion,
  });

  /// Get a claim by ID.
  Future<Claim?> getClaim(String id);

  /// Update the status of a claim.
  Future<void> updateClaimStatus(String id, ClaimStatus status);
}

/// Query descriptor for [ClaimsPort.queryClaims].
class ClaimQuery {
  /// Workspace identifier.
  final String workspaceId;

  /// Claim status filter.
  final List<ClaimStatus>? statuses;

  /// Claim type filter.
  final List<String>? types;

  /// Period filter.
  final Period? period;

  /// Entity filter.
  final String? entityId;

  /// Maximum results.
  final int? limit;

  const ClaimQuery({
    required this.workspaceId,
    this.statuses,
    this.types,
    this.period,
    this.entityId,
    this.limit,
  });
}

/// Aggregate validation report.
class ClaimValidationReport {
  /// Whether all claims passed validation.
  final bool passed;

  /// Per-claim status.
  final List<ClaimValidationEntry> entries;

  /// Aggregate issues discovered.
  final List<String> issues;

  const ClaimValidationReport({
    required this.passed,
    required this.entries,
    this.issues = const [],
  });
}

/// Single-claim validation entry.
class ClaimValidationEntry {
  /// Claim identifier.
  final String claimId;

  /// Validation status.
  final ClaimStatus status;

  /// Supporting evidence references.
  final List<String> supportingRefs;

  /// Conflict reason if applicable.
  final String? conflictReason;

  const ClaimValidationEntry({
    required this.claimId,
    required this.status,
    this.supportingRefs = const [],
    this.conflictReason,
  });
}

/// Stub implementation for testing.
class StubClaimsPort implements ClaimsPort {
  const StubClaimsPort();

  @override
  Future<void> writeClaims(
    List<Claim> claims, {
    List<String>? evidenceRefs,
  }) async {}

  @override
  Future<List<Claim>> queryClaims(ClaimQuery query) async => [];

  @override
  Future<ClaimValidationReport> validateClaims(
    List<Claim> claims, {
    DateTime? asOf,
    String? policyVersion,
  }) async {
    return const ClaimValidationReport(passed: true, entries: []);
  }

  @override
  Future<Claim?> getClaim(String id) async => null;

  @override
  Future<void> updateClaimStatus(String id, ClaimStatus status) async {}
}
