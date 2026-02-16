/// Event Port - Unified interface for event operations.
///
/// Provides abstract contracts for event publishing and subscription
/// that can be used across all MCP knowledge packages.
library;

import 'dart:async';

/// Event data.
class PortEvent {
  /// Event type.
  final String type;

  /// Event payload.
  final Map<String, dynamic> payload;

  /// Timestamp.
  final DateTime timestamp;

  /// Source identifier.
  final String? source;

  const PortEvent({
    required this.type,
    required this.payload,
    required this.timestamp,
    this.source,
  });

  /// Create from JSON.
  factory PortEvent.fromJson(Map<String, dynamic> json) {
    return PortEvent(
      type: json['type'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: json['source'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'type': type,
        'payload': payload,
        'timestamp': timestamp.toIso8601String(),
        if (source != null) 'source': source,
      };
}

/// Event port for pub/sub.
abstract class EventPort {
  /// Publish an event.
  Future<void> publish(PortEvent event);

  /// Subscribe to events of a type.
  Stream<PortEvent> subscribe(String eventType);

  /// Subscribe to all events.
  Stream<PortEvent> subscribeAll();

  /// Unsubscribe from a type.
  Future<void> unsubscribe(String eventType);
}

/// In-memory event port for testing.
class InMemoryEventPort implements EventPort {
  final _controller = StreamController<PortEvent>.broadcast();

  @override
  Future<void> publish(PortEvent event) async {
    _controller.add(event);
  }

  @override
  Stream<PortEvent> subscribe(String eventType) {
    return _controller.stream.where((e) => e.type == eventType);
  }

  @override
  Stream<PortEvent> subscribeAll() => _controller.stream;

  @override
  Future<void> unsubscribe(String eventType) async {
    // No-op for broadcast stream
  }

  /// Dispose the controller.
  void dispose() {
    _controller.close();
  }
}
