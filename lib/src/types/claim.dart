/// Unified Claim type for verifiable assertions.
///
/// This is the single canonical Claim type used across all packages:
/// - mcp_skill: extraction results
/// - mcp_fact_graph: verification and persistence
/// - SkillFactGraphPort: interface between packages
///
/// Designed based on mcp_fact_graph requirements (source of truth).
library;

/// Semantic type of the claim content.
enum ClaimType {
  // Factual types
  fact,
  date,
  amount,
  quantity,
  category,
  entity,
  relation,
  temporal,
  causal,
  comparative,
  quantitative,

  // Derived types
  conclusion,
  recommendation,
  speculation,
  observation,
  prediction,
  opinion,
  hypothetical;

  static ClaimType fromString(String value) {
    return ClaimType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ClaimType.fact,
    );
  }
}

/// Verification state of the claim.
enum ClaimStatus {
  pending,
  verifying,
  supported,
  unsupported,
  conflicting,
  partiallySupported,
  unverifiable,
  speculation;

  static ClaimStatus fromString(String value) {
    final normalized = value.toLowerCase().replaceAll('_', '');
    return ClaimStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => ClaimStatus.pending,
    );
  }
}

/// A verifiable assertion - the single canonical type for all packages.
///
/// Used by:
/// - mcp_skill: Creates claims with minimal required fields
/// - mcp_fact_graph: Uses all fields for verification workflow
/// - SkillFactGraphPort: Interface type for claim exchange
class Claim {
  /// Unique claim identifier (UUID).
  final String id;

  /// Workspace for multi-tenant isolation.
  final String workspaceId;

  /// Human-readable claim text (statement).
  final String text;

  /// Semantic type of the claim.
  final ClaimType type;

  /// Structured value (parsed from text).
  final dynamic value;

  /// RDF subject (optional).
  final String? subject;

  /// RDF predicate/relationship (optional).
  final String? predicate;

  /// RDF object (optional).
  final String? object;

  /// Source context (responseId, skillRunId, etc.).
  final String? sourceId;

  /// Evidence IDs supporting this claim.
  final List<String> evidenceRefs;

  /// Evidence IDs contradicting this claim.
  final List<String> contradictingRefs;

  /// Confidence score (0.0 to 1.0).
  final double confidence;

  /// Verification status.
  final ClaimStatus status;

  /// If status is 'conflicting', explains why.
  final String? conflictReason;

  /// Verification timestamp.
  final DateTime? verifiedAt;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Additional context-specific data.
  final Map<String, dynamic>? metadata;

  const Claim({
    required this.id,
    required this.workspaceId,
    required this.text,
    required this.type,
    this.value,
    this.subject,
    this.predicate,
    this.object,
    this.sourceId,
    required this.evidenceRefs,
    this.contradictingRefs = const [],
    required this.confidence,
    this.status = ClaimStatus.pending,
    this.conflictReason,
    this.verifiedAt,
    this.createdAt,
    this.metadata,
  });

  /// Parse from JSON.
  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      id: json['id'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? 'default',
      text: json['text'] as String? ?? json['statement'] as String? ?? '',
      type: ClaimType.fromString(json['type'] as String? ?? 'fact'),
      value: json['value'],
      subject: json['subject'] as String?,
      predicate: json['predicate'] as String?,
      object: json['object'] as String?,
      sourceId: json['sourceId'] as String? ?? json['responseId'] as String?,
      evidenceRefs: (json['evidenceRefs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['supportingEvidenceIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      contradictingRefs: (json['contradictingRefs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['contradictingEvidenceIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      status: ClaimStatus.fromString(json['status'] as String? ??
          json['verificationStatus'] as String? ??
          'pending'),
      conflictReason: json['conflictReason'] as String?,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'workspaceId': workspaceId,
        'text': text,
        'type': type.name,
        if (value != null) 'value': value,
        if (subject != null) 'subject': subject,
        if (predicate != null) 'predicate': predicate,
        if (object != null) 'object': object,
        if (sourceId != null) 'sourceId': sourceId,
        'evidenceRefs': evidenceRefs,
        if (contradictingRefs.isNotEmpty) 'contradictingRefs': contradictingRefs,
        'confidence': confidence,
        'status': status.name,
        if (conflictReason != null) 'conflictReason': conflictReason,
        if (verifiedAt != null) 'verifiedAt': verifiedAt!.toIso8601String(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

  /// Create a copy with updated fields.
  Claim copyWith({
    String? id,
    String? workspaceId,
    String? text,
    ClaimType? type,
    dynamic value,
    String? subject,
    String? predicate,
    String? object,
    String? sourceId,
    List<String>? evidenceRefs,
    List<String>? contradictingRefs,
    double? confidence,
    ClaimStatus? status,
    String? conflictReason,
    DateTime? verifiedAt,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return Claim(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      text: text ?? this.text,
      type: type ?? this.type,
      value: value ?? this.value,
      subject: subject ?? this.subject,
      predicate: predicate ?? this.predicate,
      object: object ?? this.object,
      sourceId: sourceId ?? this.sourceId,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      contradictingRefs: contradictingRefs ?? this.contradictingRefs,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      conflictReason: conflictReason ?? this.conflictReason,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if claim is verified.
  bool get isVerified =>
      status == ClaimStatus.supported ||
      status == ClaimStatus.unsupported ||
      status == ClaimStatus.conflicting ||
      status == ClaimStatus.partiallySupported;

  /// Check if claim is supported.
  bool get isSupported => status == ClaimStatus.supported;

  /// Check if claim has RDF structure.
  bool get hasRdfStructure =>
      subject != null || predicate != null || object != null;

  @override
  String toString() => 'Claim($id: $text, status: ${status.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Claim && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
