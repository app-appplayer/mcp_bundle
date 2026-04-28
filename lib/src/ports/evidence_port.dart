/// Evidence Port - Evidence extraction and classification.
///
/// Capability-named port for evidence fragment extraction, confidence
/// scoring, and classification. Extracted from `knowledge_ports.dart` per
/// REDESIGN-PLAN.md Phase 1a (0.1.0-a2).
///
/// Provider: `mcp_fact_graph`.
library;

/// Port for evidence extraction operations.
///
/// Used by the fact graph to extract and evaluate evidence fragments.
abstract class EvidencePort {
  /// Extract fragments from content.
  Future<List<EvidenceFragment>> extractFragments(
    String content,
    String mimeType,
  );

  /// Compute confidence score for a fragment.
  Future<double> computeConfidence(String fragment);

  /// Classify fragment type.
  Future<String> classifyFragment(String fragment);
}

/// Evidence fragment.
class EvidenceFragment {
  /// Fragment text.
  final String text;

  /// Fragment type (claim, fact, opinion, etc.).
  final String type;

  /// Confidence score.
  final double confidence;

  /// Source offset in original content.
  final int? sourceOffset;

  /// Source length in original content.
  final int? sourceLength;

  const EvidenceFragment({
    required this.text,
    required this.type,
    required this.confidence,
    this.sourceOffset,
    this.sourceLength,
  });
}

/// Stub evidence port for testing.
class StubEvidencePort implements EvidencePort {
  const StubEvidencePort();

  @override
  Future<List<EvidenceFragment>> extractFragments(
    String content,
    String mimeType,
  ) async {
    return [];
  }

  @override
  Future<double> computeConfidence(String fragment) async {
    return 0.5;
  }

  @override
  Future<String> classifyFragment(String fragment) async {
    return 'unknown';
  }
}
