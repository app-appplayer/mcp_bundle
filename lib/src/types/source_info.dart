/// Source metadata for evidence/fact origination.
///
/// Shared DTO used across evidence ingestion (mcp_ingest), storage
/// (mcp_fact_graph), and ops pipelines (mcp_knowledge_ops). Previously
/// defined inline in the legacy `ops_ports.dart`; moved to
/// `types/source_info.dart` in Phase 9.
library;

/// Describes where a piece of evidence came from.
class SourceInfo {
  /// Source name/identifier (required for proper tracking).
  final String name;

  /// Source URI.
  final String? uri;

  /// Source type description.
  final String? type;

  /// When the original was created/captured.
  final DateTime? capturedAt;

  /// Reliability score (0.0 to 1.0).
  final double? reliability;

  /// Additional source attributes (can include author, etc.).
  final Map<String, dynamic> attributes;

  const SourceInfo({
    required this.name,
    this.uri,
    this.type,
    this.capturedAt,
    this.reliability,
    this.attributes = const {},
  });

  factory SourceInfo.fromJson(Map<String, dynamic> json) {
    return SourceInfo(
      name: json['name'] as String? ?? '',
      uri: json['uri'] as String?,
      type: json['type'] as String?,
      capturedAt: json['capturedAt'] != null
          ? DateTime.parse(json['capturedAt'] as String)
          : null,
      reliability: (json['reliability'] as num?)?.toDouble(),
      attributes: (json['attributes'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (uri != null) 'uri': uri,
      if (type != null) 'type': type,
      if (capturedAt != null) 'capturedAt': capturedAt!.toIso8601String(),
      if (reliability != null) 'reliability': reliability,
      if (attributes.isNotEmpty) 'attributes': attributes,
    };
  }
}
