/// IoStreamPort - Streaming subscription interface for I/O device topics.
///
/// Provides subscription-based access to continuous data streams from I/O
/// devices. Consumers subscribe to topics and receive a stream of
/// PayloadEnvelope messages. Handles subscription lifecycle, status
/// monitoring, and cleanup.
library;

import 'dart:async';

import 'io_device_port.dart';

// ============================================================================
// Data Types
// ============================================================================

/// Handle identifying an active subscription.
class SubscriptionHandle {
  /// Unique subscription identifier.
  final String subscriptionId;

  /// Topic URI this subscription is bound to.
  final String topic;

  /// Subscription mode (continuous, onChange, poll, event).
  final TopicMode mode;

  /// Creation timestamp in epoch milliseconds.
  final int createdAt;

  /// Expiration timestamp in epoch milliseconds, if TTL is set.
  final int? expiresAt;

  const SubscriptionHandle({
    required this.subscriptionId,
    required this.topic,
    required this.mode,
    required this.createdAt,
    this.expiresAt,
  });

  /// Create from JSON.
  factory SubscriptionHandle.fromJson(Map<String, dynamic> json) {
    return SubscriptionHandle(
      subscriptionId: json['subscriptionId'] as String,
      topic: json['topic'] as String,
      mode: TopicMode.values.byName(json['mode'] as String),
      createdAt: json['createdAt'] as int,
      expiresAt: json['expiresAt'] as int?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'subscriptionId': subscriptionId,
        'topic': topic,
        'mode': mode.name,
        'createdAt': createdAt,
        if (expiresAt != null) 'expiresAt': expiresAt,
      };
}

/// Status information for an active subscription.
class SubscriptionStatus {
  /// Subscription identifier.
  final String subscriptionId;

  /// Whether the subscription is currently active.
  final bool active;

  /// Total number of messages successfully delivered.
  final int messagesDelivered;

  /// Total number of messages dropped (e.g., due to backpressure).
  final int messagesDropped;

  /// Current buffer usage in number of items.
  final int bufferUsed;

  /// Maximum buffer capacity in number of items.
  final int bufferCapacity;

  /// Timestamp of the last delivered message, if any.
  final DateTime? lastMessageAt;

  const SubscriptionStatus({
    required this.subscriptionId,
    required this.active,
    this.messagesDelivered = 0,
    this.messagesDropped = 0,
    this.bufferUsed = 0,
    this.bufferCapacity = 0,
    this.lastMessageAt,
  });

  /// Create from JSON.
  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      subscriptionId: json['subscriptionId'] as String,
      active: json['active'] as bool,
      messagesDelivered: json['messagesDelivered'] as int? ?? 0,
      messagesDropped: json['messagesDropped'] as int? ?? 0,
      bufferUsed: json['bufferUsed'] as int? ?? 0,
      bufferCapacity: json['bufferCapacity'] as int? ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'subscriptionId': subscriptionId,
        'active': active,
        'messagesDelivered': messagesDelivered,
        'messagesDropped': messagesDropped,
        'bufferUsed': bufferUsed,
        'bufferCapacity': bufferCapacity,
        if (lastMessageAt != null)
          'lastMessageAt': lastMessageAt!.toIso8601String(),
      };
}

/// Active subscription with its associated data stream.
///
/// Named IoStreamSubscription to avoid collision with dart:async
/// StreamSubscription.
class IoStreamSubscription {
  /// Handle identifying this subscription.
  final SubscriptionHandle handle;

  /// Stream of payload envelopes from the subscribed topic.
  final Stream<PayloadEnvelope> stream;

  // Not const - Stream cannot be a compile-time constant.
  // No fromJson/toJson - Stream is not serializable.
  IoStreamSubscription({
    required this.handle,
    required this.stream,
  });
}

// ============================================================================
// Port Interface
// ============================================================================

/// Abstract port for streaming subscriptions to I/O device topics.
///
/// Provides subscription lifecycle management: subscribe, unsubscribe,
/// list active subscriptions, and query subscription status.
abstract class IoStreamPort {
  /// Create a subscription and return handle + stream.
  Future<IoStreamSubscription> subscribe(
    TopicSpec spec, {
    required String consumerId,
  });

  /// Unsubscribe from a topic.
  Future<void> unsubscribe(String subscriptionId);

  /// List active subscriptions, optionally filtered by consumer or device.
  Future<List<SubscriptionHandle>> listSubscriptions({
    String? consumerId,
    String? deviceId,
  });

  /// Get subscription status, or null if the subscription does not exist.
  Future<SubscriptionStatus?> getStatus(String subscriptionId);
}

// ============================================================================
// Stub Implementation
// ============================================================================

/// Stub implementation of [IoStreamPort] for testing.
class StubIoStreamPort implements IoStreamPort {
  final Map<String, SubscriptionHandle> _subscriptions = {};

  @override
  Future<IoStreamSubscription> subscribe(
    TopicSpec spec, {
    required String consumerId,
  }) async {
    final id = 'sub_${_subscriptions.length}';
    final handle = SubscriptionHandle(
      subscriptionId: id,
      topic: spec.uri,
      mode: spec.mode,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    _subscriptions[id] = handle;
    return IoStreamSubscription(
      handle: handle,
      stream: const Stream.empty(),
    );
  }

  @override
  Future<void> unsubscribe(String subscriptionId) async {
    _subscriptions.remove(subscriptionId);
  }

  @override
  Future<List<SubscriptionHandle>> listSubscriptions({
    String? consumerId,
    String? deviceId,
  }) async {
    return _subscriptions.values.toList();
  }

  @override
  Future<SubscriptionStatus?> getStatus(String subscriptionId) async {
    final handle = _subscriptions[subscriptionId];
    if (handle == null) return null;
    return SubscriptionStatus(
      subscriptionId: subscriptionId,
      active: true,
    );
  }

  /// Clear all subscriptions (for test reset).
  void clear() {
    _subscriptions.clear();
  }
}
