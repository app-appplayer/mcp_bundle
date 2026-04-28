/// Profile Result Types - Contract layer types for profile application output.
///
/// Defines the result types returned by ProfilePort operations:
/// - [ProfileOutput] - Complete profile application result (appraisal + decision + expression)
/// - [ProfileExecutionMetadata] - Execution timing and version info
/// - [EvaluationOutput] - Profile evaluation scores and feedback
///
/// These are the canonical definitions. Implementation packages (mcp_profile)
/// should re-export from here.
library;

import 'appraisal_result.dart';
import 'decision_guidance.dart';
import 'expression_style.dart';

// Re-export dependent types for consumer convenience.
export 'appraisal_result.dart';
export 'decision_guidance.dart';
export 'expression_style.dart';

// =============================================================================
// ProfileOutput
// =============================================================================

/// Complete profile application result per mcp_profile design/03-runtime.md §5.
///
/// Contains the full pipeline output:
/// - [appraisal] - Metric computation results
/// - [decision] - Policy evaluation guidance
/// - [expression] - Communication style determination
/// - [formatted] - Optional formatted response
///
/// Example:
/// ```dart
/// final output = ProfileOutput(
///   profileId: 'medical-advisor',
///   contextId: 'ctx-123',
///   appraisal: appraisalResult,
///   decision: decisionGuidance,
///   expression: expressionStyle,
///   metadata: ProfileExecutionMetadata(
///     startedAt: startTime,
///     completedAt: endTime,
///     profileVersion: '1.0.0',
///   ),
/// );
/// ```
class ProfileOutput {
  /// Profile ID that was applied.
  final String profileId;

  /// Context ID for this execution.
  final String contextId;

  /// Appraisal result with metrics.
  final AppraisalResult appraisal;

  /// Decision guidance from policy evaluation.
  final DecisionGuidance decision;

  /// Expression style determined by policies.
  final ExpressionStyle expression;

  /// Formatted response if content was provided.
  final FormattedResponse? formatted;

  /// Execution metadata.
  final ProfileExecutionMetadata metadata;

  const ProfileOutput({
    required this.profileId,
    required this.contextId,
    required this.appraisal,
    required this.decision,
    required this.expression,
    this.formatted,
    required this.metadata,
  });

  /// Create an empty ProfileOutput for testing/stub purposes.
  factory ProfileOutput.empty({
    String profileId = '',
    String contextId = '',
  }) {
    final now = DateTime.now();
    return ProfileOutput(
      profileId: profileId,
      contextId: contextId,
      appraisal: AppraisalResult.empty(
        profileId: profileId,
        contextId: contextId,
      ),
      decision: DecisionGuidance.defaultProceed,
      expression: ExpressionStyle.defaultStyle,
      metadata: ProfileExecutionMetadata(
        startedAt: now,
        completedAt: now,
        profileVersion: '0.0.0',
      ),
    );
  }

  /// Create from JSON map.
  factory ProfileOutput.fromJson(Map<String, dynamic> json) {
    return ProfileOutput(
      profileId: json['profileId'] as String? ?? '',
      contextId: json['contextId'] as String? ?? '',
      appraisal: json['appraisal'] is Map<String, dynamic>
          ? AppraisalResult.fromJson(json['appraisal'] as Map<String, dynamic>)
          : AppraisalResult.empty(profileId: json['profileId'] as String? ?? ''),
      decision: json['decision'] is Map<String, dynamic>
          ? DecisionGuidance.fromJson(json['decision'] as Map<String, dynamic>)
          : DecisionGuidance.defaultProceed,
      expression: json['expression'] is Map<String, dynamic>
          ? ExpressionStyle.fromJson(
              json['expression'] as Map<String, dynamic>)
          : ExpressionStyle.defaultStyle,
      formatted: json['formatted'] is Map<String, dynamic>
          ? FormattedResponse.fromJson(
              json['formatted'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] is Map<String, dynamic>
          ? ProfileExecutionMetadata.fromJson(
              json['metadata'] as Map<String, dynamic>)
          : ProfileExecutionMetadata(
              startedAt: DateTime.now(),
              completedAt: DateTime.now(),
              profileVersion: '0.0.0',
            ),
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'contextId': contextId,
        'appraisal': appraisal.toJson(),
        'decision': decision.toJson(),
        'expression': expression.toJson(),
        if (formatted != null) 'formatted': formatted!.toJson(),
        'metadata': metadata.toJson(),
      };

  @override
  String toString() =>
      'ProfileOutput(profileId: $profileId, contextId: $contextId, '
      'decision: ${decision.action.name})';
}

// =============================================================================
// ProfileExecutionMetadata
// =============================================================================

/// Metadata for profile application execution.
///
/// Tracks timing and version information for a profile application pipeline run.
class ProfileExecutionMetadata {
  /// When the application started.
  final DateTime startedAt;

  /// When the application completed.
  final DateTime completedAt;

  /// Profile version used.
  final String profileVersion;

  const ProfileExecutionMetadata({
    required this.startedAt,
    required this.completedAt,
    required this.profileVersion,
  });

  /// Get execution duration.
  Duration get duration => completedAt.difference(startedAt);

  /// Create from JSON map.
  factory ProfileExecutionMetadata.fromJson(Map<String, dynamic> json) {
    return ProfileExecutionMetadata(
      startedAt: json['startedAt'] is String
          ? DateTime.parse(json['startedAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] is String
          ? DateTime.parse(json['completedAt'] as String)
          : DateTime.now(),
      profileVersion: json['profileVersion'] as String? ?? '0.0.0',
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() => {
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'profileVersion': profileVersion,
      };

  @override
  String toString() =>
      'ProfileExecutionMetadata(duration: ${duration.inMilliseconds}ms, '
      'version: $profileVersion)';
}

// =============================================================================
// EvaluationOutput
// =============================================================================

/// Evaluation output from profile evaluation.
///
/// Contains scoring results when evaluating content against a profile's criteria.
///
/// Example:
/// ```dart
/// final evaluation = EvaluationOutput(
///   score: 0.85,
///   dimensions: {'accuracy': 0.9, 'completeness': 0.8},
///   issues: ['Missing citation for claim X'],
///   suggestions: ['Add source reference'],
/// );
/// ```
class EvaluationOutput {
  /// Overall score (0.0 - 1.0).
  final double score;

  /// Dimension scores.
  final Map<String, double> dimensions;

  /// Issues found.
  final List<String> issues;

  /// Suggestions.
  final List<String> suggestions;

  const EvaluationOutput({
    required this.score,
    required this.dimensions,
    this.issues = const [],
    this.suggestions = const [],
  });

  /// Create from JSON map.
  factory EvaluationOutput.fromJson(Map<String, dynamic> json) {
    return EvaluationOutput(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      dimensions: (json['dimensions'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      issues: (json['issues'] as List<dynamic>?)?.cast<String>() ?? [],
      suggestions:
          (json['suggestions'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() => {
        'score': score,
        'dimensions': dimensions,
        if (issues.isNotEmpty) 'issues': issues,
        if (suggestions.isNotEmpty) 'suggestions': suggestions,
      };

  @override
  String toString() =>
      'EvaluationOutput(score: $score, dimensions: ${dimensions.length})';
}
