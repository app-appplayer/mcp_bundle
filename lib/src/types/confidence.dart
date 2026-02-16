/// Confidence score utilities and conventions.
///
/// All confidence scores across packages should be 0.0 to 1.0.
library;

/// Semantic ranges for confidence interpretation.
enum ConfidenceLevel {
  veryLow(0.0, 0.3, 'Very Low'),
  low(0.3, 0.5, 'Low'),
  medium(0.5, 0.7, 'Medium'),
  high(0.7, 0.9, 'High'),
  veryHigh(0.9, 1.0, 'Very High');

  final double minValue;
  final double maxValue;
  final String label;

  const ConfidenceLevel(this.minValue, this.maxValue, this.label);

  /// Get the confidence level for a given score.
  static ConfidenceLevel fromScore(double score) {
    if (score < 0.0 || score > 1.0) {
      throw ArgumentError('Confidence score must be between 0.0 and 1.0');
    }
    for (final level in ConfidenceLevel.values) {
      if (score >= level.minValue && score < level.maxValue) {
        return level;
      }
    }
    return ConfidenceLevel.veryHigh; // score == 1.0
  }
}

/// Utility class for confidence calculations.
class Confidence {
  /// Ensure score is within valid range.
  static double clamp(double score) => score.clamp(0.0, 1.0);

  /// Calculate average confidence.
  static double average(List<double> scores) {
    if (scores.isEmpty) return 0.0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Calculate minimum confidence (used for derived metrics).
  static double minimum(List<double> scores) {
    if (scores.isEmpty) return 0.0;
    return scores.reduce((a, b) => a < b ? a : b);
  }

  /// Calculate weighted average confidence.
  static double weightedAverage(List<double> scores, List<double> weights) {
    if (scores.isEmpty || scores.length != weights.length) return 0.0;
    double sum = 0.0;
    double weightSum = 0.0;
    for (int i = 0; i < scores.length; i++) {
      sum += scores[i] * weights[i];
      weightSum += weights[i];
    }
    return weightSum > 0 ? sum / weightSum : 0.0;
  }

  /// Apply decay based on age (for time-sensitive confidence).
  static double withDecay({
    required double baseConfidence,
    required Duration age,
    required Duration halfLife,
  }) {
    if (halfLife.inMilliseconds <= 0) return baseConfidence;
    final decayFactor =
        0.5 * (age.inMilliseconds / halfLife.inMilliseconds).abs();
    return baseConfidence * (1.0 - decayFactor).clamp(0.0, 1.0);
  }
}
