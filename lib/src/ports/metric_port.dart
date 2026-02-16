/// Metric Port - Unified interface for metric operations.
///
/// Provides abstract contracts for metric computation, recording,
/// and monitoring that can be used across all MCP knowledge packages.
library;

/// Metric value.
class MetricValue {
  /// Numeric value.
  final double value;

  /// Timestamp.
  final DateTime timestamp;

  /// Confidence score (0.0-1.0).
  final double? confidence;

  /// Additional metadata.
  final Map<String, dynamic>? metadata;

  const MetricValue({
    required this.value,
    required this.timestamp,
    this.confidence,
    this.metadata,
  });

  /// Create from JSON.
  factory MetricValue.fromJson(Map<String, dynamic> json) {
    return MetricValue(
      value: (json['value'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      confidence: (json['confidence'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'value': value,
        'timestamp': timestamp.toIso8601String(),
        if (confidence != null) 'confidence': confidence,
        if (metadata != null) 'metadata': metadata,
      };
}

/// Metric event for streaming.
class MetricEvent {
  /// Metric name.
  final String name;

  /// Metric value.
  final MetricValue value;

  /// Event type (update, threshold, anomaly).
  final String eventType;

  const MetricEvent({
    required this.name,
    required this.value,
    required this.eventType,
  });

  /// Create from JSON.
  factory MetricEvent.fromJson(Map<String, dynamic> json) {
    return MetricEvent(
      name: json['name'] as String,
      value: MetricValue.fromJson(json['value'] as Map<String, dynamic>),
      eventType: json['eventType'] as String,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value.toJson(),
        'eventType': eventType,
      };
}

/// Metric computation port.
abstract class MetricPort {
  /// Compute a metric value.
  Future<MetricValue> compute(
    String metricName,
    Map<String, dynamic> context,
  );

  /// Record a metric value.
  Future<void> record(
    String metricName,
    double value, {
    Map<String, String>? tags,
  });

  /// Watch metric changes.
  Stream<MetricEvent> watch(String metricName);

  /// Get historical values.
  Future<List<MetricValue>> history(
    String metricName, {
    DateTime? start,
    DateTime? end,
    int? limit,
  });
}

/// Stub metric port for testing.
class StubMetricPort implements MetricPort {
  @override
  Future<MetricValue> compute(
    String metricName,
    Map<String, dynamic> context,
  ) async {
    return MetricValue(
      value: 0.5,
      timestamp: DateTime.now(),
      confidence: 1.0,
    );
  }

  @override
  Future<void> record(
    String metricName,
    double value, {
    Map<String, String>? tags,
  }) async {}

  @override
  Stream<MetricEvent> watch(String metricName) => const Stream.empty();

  @override
  Future<List<MetricValue>> history(
    String metricName, {
    DateTime? start,
    DateTime? end,
    int? limit,
  }) async {
    return [];
  }
}
