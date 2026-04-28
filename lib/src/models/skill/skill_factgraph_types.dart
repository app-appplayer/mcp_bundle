/// # REMOVAL TARGET
///
/// This file is a **legacy transition shim** scheduled for removal per
/// REDESIGN-PLAN.md Phase 9. New code must not reference any symbol
/// declared here. The canonical replacements are:
///
/// | Legacy (this file)        | Canonical (new)                              |
/// |---------------------------|----------------------------------------------|
/// | `SkillContextBundle`      | `ContextBundle` (in `types/context_bundle.dart`) |
/// | `ContextBundleRequest`    | `ContextBundleRequest` (in `ports/context_bundle_port.dart`) |
/// | `ContextBudget`           | absorbed into `ContextBundleRequest.budget`  |
/// | `SkillFact`, `SkillFactQuery`, `SkillEntity` | `FactRecord`, `FactQuery`, `EntityRecord` (capability ports) |
/// | `SkillRunRecord`, `SkillRunStatus`           | `RunsPort` / `RunRecord` |
/// | `ClaimValidationResult`, `ClaimValidationStatus`, `ValidationIssue`, `ValidationIssueType`, `IssueSeverity` | `ClaimsPort` / `ClaimValidationReport` |
///
/// Consumers should migrate all imports away from this file. Once all
/// references are gone (Phase 9 verification) this file is deleted.
///
/// ---
///
/// (Original docstring retained for audit trail.)
///
/// Skill FactGraph Types - DTOs extracted from the legacy
/// `SkillFactGraphPort` per REDESIGN-PLAN.md Phase 2 substep (0.1.0-a3).
///
/// Previously these types lived inline in
/// `mcp_bundle/dart/lib/src/ports/skill_factgraph_port.dart`. They were
/// moved here so that Phase 9 deletion of the legacy port file does not
/// take the DTOs with it. The legacy port file re-exports this library
/// during the transition window.
///
/// Contained types (13 DTOs, matching the 0.1.0-a3 actual enumeration):
/// - Enums: `ValidationIssueType`, `IssueSeverity`, `SkillRunStatus`
/// - Context: `ContextBundleRequest`, `ContextBudget`, `SkillContextBundle`
/// - Validation: `ClaimValidationResult`, `ClaimValidationStatus`,
///   `ValidationIssue`
/// - Run record: `SkillRunRecord`
/// - Fact/entity: `SkillFact`, `SkillFactQuery`, `SkillEntity`
library;

import '../../types/claim.dart';
import '../../types/context_bundle.dart';
import '../../types/period.dart';

// =============================================================================
// Enums
// =============================================================================

/// Validation issue types.
enum ValidationIssueType {
  missingEvidence,
  contradiction,
  hallucination,
  outdated,
  policyViolation;

  static ValidationIssueType fromString(String value) {
    return ValidationIssueType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ValidationIssueType.missingEvidence,
    );
  }
}

/// Validation issue severity levels.
enum IssueSeverity {
  error,
  warning,
  info;

  static IssueSeverity fromString(String value) {
    return IssueSeverity.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => IssueSeverity.info,
    );
  }
}

/// Skill run status.
enum SkillRunStatus {
  running,
  completed,
  failed,
  blocked;

  static SkillRunStatus fromString(String value) {
    return SkillRunStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => SkillRunStatus.failed,
    );
  }
}

// =============================================================================
// Context Bundle Types
// =============================================================================

/// Context bundle request for skill execution.
class ContextBundleRequest {
  /// Query for context retrieval.
  final String query;

  /// Workspace identifier.
  final String workspaceId;

  /// Point in time for the query.
  final DateTime? asOf;

  /// Time period filter (uses canonical Period type).
  final Period? period;

  /// Policy version for filtering.
  final String? policyVersion;

  /// Context budget constraints.
  final ContextBudget? budget;

  const ContextBundleRequest({
    required this.query,
    required this.workspaceId,
    this.asOf,
    this.period,
    this.policyVersion,
    this.budget,
  });

  factory ContextBundleRequest.fromJson(Map<String, dynamic> json) {
    return ContextBundleRequest(
      query: json['query'] as String,
      workspaceId: json['workspaceId'] as String,
      asOf: json['asOf'] != null
          ? DateTime.parse(json['asOf'] as String)
          : null,
      period: json['period'] != null
          ? Period.fromJson(json['period'] as Map<String, dynamic>)
          : null,
      policyVersion: json['policyVersion'] as String?,
      budget: json['budget'] != null
          ? ContextBudget.fromJson(json['budget'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'query': query,
        'workspaceId': workspaceId,
        if (asOf != null) 'asOf': asOf!.toIso8601String(),
        if (period != null) 'period': period!.toJson(),
        if (policyVersion != null) 'policyVersion': policyVersion,
        if (budget != null) 'budget': budget!.toJson(),
      };
}

/// Context budget constraints.
class ContextBudget {
  /// Maximum number of nodes.
  final int? maxNodes;

  /// Maximum number of tokens.
  final int? maxTokens;

  /// Maximum number of sentences.
  final int? maxSentences;

  const ContextBudget({this.maxNodes, this.maxTokens, this.maxSentences});

  factory ContextBudget.fromJson(Map<String, dynamic> json) {
    return ContextBudget(
      maxNodes: json['maxNodes'] as int?,
      maxTokens: json['maxTokens'] as int?,
      maxSentences: json['maxSentences'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (maxNodes != null) 'maxNodes': maxNodes,
        if (maxTokens != null) 'maxTokens': maxTokens,
        if (maxSentences != null) 'maxSentences': maxSentences,
      };
}

/// Built context bundle for skill execution.
class SkillContextBundle {
  /// Facts included in the bundle (canonical ContextEntity type).
  final List<ContextEntity> facts;

  /// Summaries included in the bundle (canonical ContextView type).
  final List<ContextView> summaries;

  /// Evidence references.
  final List<String> evidenceRefs;

  /// Open questions (canonical ContextClaim type).
  final List<ContextClaim> openQuestions;

  /// Estimated token count.
  final int tokenEstimate;

  /// Point in time for the bundle.
  final DateTime asOf;

  /// Policy version used.
  final String? policyVersion;

  const SkillContextBundle({
    required this.facts,
    required this.summaries,
    required this.evidenceRefs,
    required this.openQuestions,
    required this.tokenEstimate,
    required this.asOf,
    this.policyVersion,
  });

  factory SkillContextBundle.fromJson(Map<String, dynamic> json) {
    return SkillContextBundle(
      facts: (json['facts'] as List<dynamic>)
          .map((e) => ContextEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      summaries: (json['summaries'] as List<dynamic>)
          .map((e) => ContextView.fromJson(e as Map<String, dynamic>))
          .toList(),
      evidenceRefs: (json['evidenceRefs'] as List<dynamic>).cast<String>(),
      openQuestions: (json['openQuestions'] as List<dynamic>)
          .map((e) => ContextClaim.fromJson(e as Map<String, dynamic>))
          .toList(),
      tokenEstimate: json['tokenEstimate'] as int,
      asOf: DateTime.parse(json['asOf'] as String),
      policyVersion: json['policyVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'facts': facts.map((e) => e.toJson()).toList(),
        'summaries': summaries.map((e) => e.toJson()).toList(),
        'evidenceRefs': evidenceRefs,
        'openQuestions': openQuestions.map((e) => e.toJson()).toList(),
        'tokenEstimate': tokenEstimate,
        'asOf': asOf.toIso8601String(),
        if (policyVersion != null) 'policyVersion': policyVersion,
      };
}

// =============================================================================
// Claim Validation Types
// =============================================================================

/// Claim validation result.
class ClaimValidationResult {
  /// Whether all claims passed validation.
  final bool passed;

  /// Status for each claim.
  final List<ClaimValidationStatus> claimStatuses;

  /// Validation issues found.
  final List<ValidationIssue> issues;

  const ClaimValidationResult({
    required this.passed,
    required this.claimStatuses,
    required this.issues,
  });

  factory ClaimValidationResult.fromJson(Map<String, dynamic> json) {
    return ClaimValidationResult(
      passed: json['passed'] as bool,
      claimStatuses: (json['claimStatuses'] as List<dynamic>)
          .map((e) => ClaimValidationStatus.fromJson(e as Map<String, dynamic>))
          .toList(),
      issues: (json['issues'] as List<dynamic>)
          .map((e) => ValidationIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'passed': passed,
        'claimStatuses': claimStatuses.map((s) => s.toJson()).toList(),
        'issues': issues.map((i) => i.toJson()).toList(),
      };
}

/// Claim validation status.
class ClaimValidationStatus {
  /// Claim identifier.
  final String claimId;

  /// Status (canonical ClaimStatus from types/claim.dart).
  final ClaimStatus status;

  /// Supporting evidence references.
  final List<String> supportingRefs;

  /// Conflict reason if applicable.
  final String? conflictReason;

  const ClaimValidationStatus({
    required this.claimId,
    required this.status,
    required this.supportingRefs,
    this.conflictReason,
  });

  factory ClaimValidationStatus.fromJson(Map<String, dynamic> json) {
    return ClaimValidationStatus(
      claimId: json['claimId'] as String,
      status: ClaimStatus.fromString(json['status'] as String),
      supportingRefs: (json['supportingRefs'] as List<dynamic>).cast<String>(),
      conflictReason: json['conflictReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'claimId': claimId,
        'status': status.name,
        'supportingRefs': supportingRefs,
        if (conflictReason != null) 'conflictReason': conflictReason,
      };
}

/// Validation issue.
class ValidationIssue {
  /// Unique issue identifier.
  final String issueId;

  /// Typed issue classification.
  final ValidationIssueType issueType;

  /// Typed severity level.
  final IssueSeverity severity;

  /// Issue description.
  final String description;

  /// Related claim IDs.
  final List<String> relatedClaimIds;

  /// Resolution guidance.
  final String? suggestedAction;

  const ValidationIssue({
    required this.issueId,
    required this.issueType,
    required this.severity,
    required this.description,
    required this.relatedClaimIds,
    this.suggestedAction,
  });

  factory ValidationIssue.fromJson(Map<String, dynamic> json) {
    return ValidationIssue(
      issueId: json['issueId'] as String,
      issueType: ValidationIssueType.fromString(json['issueType'] as String),
      severity: IssueSeverity.fromString(json['severity'] as String),
      description: json['description'] as String,
      relatedClaimIds:
          (json['relatedClaimIds'] as List<dynamic>).cast<String>(),
      suggestedAction: json['suggestedAction'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'issueId': issueId,
        'issueType': issueType.name,
        'severity': severity.name,
        'description': description,
        'relatedClaimIds': relatedClaimIds,
        if (suggestedAction != null) 'suggestedAction': suggestedAction,
      };
}

// =============================================================================
// Skill Run Record
// =============================================================================

/// Skill run record for audit and traceability.
class SkillRunRecord {
  /// Skill identifier.
  final String skillId;

  /// Skill version.
  final String skillVersion;

  /// Procedure identifier.
  final String procedureId;

  /// Start time.
  final DateTime startedAt;

  /// Finish time.
  final DateTime? finishedAt;

  /// Run status (typed enum).
  final SkillRunStatus status;

  /// Input values.
  final Map<String, dynamic> inputs;

  /// Output values.
  final Map<String, dynamic>? outputs;

  /// Claim IDs generated.
  final List<String> claimIds;

  /// Evidence references used.
  final List<String> evidenceRefs;

  const SkillRunRecord({
    required this.skillId,
    required this.skillVersion,
    required this.procedureId,
    required this.startedAt,
    this.finishedAt,
    required this.status,
    required this.inputs,
    this.outputs,
    required this.claimIds,
    required this.evidenceRefs,
  });

  factory SkillRunRecord.fromJson(Map<String, dynamic> json) {
    return SkillRunRecord(
      skillId: json['skillId'] as String,
      skillVersion: json['skillVersion'] as String,
      procedureId: json['procedureId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
      status: SkillRunStatus.fromString(json['status'] as String),
      inputs: json['inputs'] as Map<String, dynamic>,
      outputs: json['outputs'] as Map<String, dynamic>?,
      claimIds: (json['claimIds'] as List<dynamic>).cast<String>(),
      evidenceRefs: (json['evidenceRefs'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'skillId': skillId,
        'skillVersion': skillVersion,
        'procedureId': procedureId,
        'startedAt': startedAt.toIso8601String(),
        if (finishedAt != null) 'finishedAt': finishedAt!.toIso8601String(),
        'status': status.name,
        'inputs': inputs,
        if (outputs != null) 'outputs': outputs,
        'claimIds': claimIds,
        'evidenceRefs': evidenceRefs,
      };
}

// =============================================================================
// Fact and Entity Types
// =============================================================================

/// Fact from the graph (for skill queries).
class SkillFact {
  /// Fact identifier.
  final String id;

  /// Fact type.
  final String type;

  /// Fact content.
  final Map<String, dynamic> content;

  /// Creation time.
  final DateTime createdAt;

  /// Confidence score.
  final double? confidence;

  /// Evidence references.
  final List<String> evidenceRefs;

  const SkillFact({
    required this.id,
    required this.type,
    required this.content,
    required this.createdAt,
    this.confidence,
    required this.evidenceRefs,
  });

  factory SkillFact.fromJson(Map<String, dynamic> json) {
    return SkillFact(
      id: json['id'] as String,
      type: json['type'] as String,
      content: json['content'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      confidence: (json['confidence'] as num?)?.toDouble(),
      evidenceRefs: (json['evidenceRefs'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        if (confidence != null) 'confidence': confidence,
        'evidenceRefs': evidenceRefs,
      };
}

/// Fact query for skills.
class SkillFactQuery {
  /// Workspace identifier.
  final String workspaceId;

  /// Fact types to query.
  final List<String>? types;

  /// Time period (uses canonical Period type).
  final Period? period;

  /// Point in time.
  final DateTime? asOf;

  /// Entity ID filter.
  final String? entityId;

  /// Maximum results.
  final int? limit;

  /// Additional filters.
  final Map<String, dynamic>? filters;

  const SkillFactQuery({
    required this.workspaceId,
    this.types,
    this.period,
    this.asOf,
    this.entityId,
    this.limit,
    this.filters,
  });

  factory SkillFactQuery.fromJson(Map<String, dynamic> json) {
    return SkillFactQuery(
      workspaceId: json['workspaceId'] as String,
      types: (json['types'] as List<dynamic>?)?.cast<String>(),
      period: json['period'] != null
          ? Period.fromJson(json['period'] as Map<String, dynamic>)
          : null,
      asOf: json['asOf'] != null
          ? DateTime.parse(json['asOf'] as String)
          : null,
      entityId: json['entityId'] as String?,
      limit: json['limit'] as int?,
      filters: json['filters'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'workspaceId': workspaceId,
        if (types != null) 'types': types,
        if (period != null) 'period': period!.toJson(),
        if (asOf != null) 'asOf': asOf!.toIso8601String(),
        if (entityId != null) 'entityId': entityId,
        if (limit != null) 'limit': limit,
        if (filters != null) 'filters': filters,
      };
}

/// Entity from the graph (for skill queries).
class SkillEntity {
  /// Entity identifier.
  final String id;

  /// Entity type.
  final String type;

  /// Entity name.
  final String name;

  /// Entity properties.
  final Map<String, dynamic> properties;

  /// Creation time.
  final DateTime createdAt;

  /// Last update time.
  final DateTime? updatedAt;

  const SkillEntity({
    required this.id,
    required this.type,
    required this.name,
    required this.properties,
    required this.createdAt,
    this.updatedAt,
  });

  factory SkillEntity.fromJson(Map<String, dynamic> json) {
    return SkillEntity(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      properties: json['properties'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'properties': properties,
        'createdAt': createdAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}
