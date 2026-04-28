/// NotificationPort - Interface for notification operations.
///
/// Used by mcp_profile's DecisionPolicy when notify modifier is set.
/// Used by mcp_knowledge_ops for workflow notifications.
library;

/// Port for sending notifications.
abstract class NotificationPort {
  /// Send a single notification.
  Future<NotificationResult> notify(Notification notification);

  /// Send multiple notifications.
  Future<List<NotificationResult>> notifyBatch(List<Notification> notifications);

  /// Get the status of a sent notification.
  Future<NotificationStatus> getStatus(String notificationId);

  /// Get notification history for a recipient.
  Future<List<NotificationRecord>> getHistory({
    String? recipientId,
    NotificationType? type,
    DateTime? since,
    int limit = 100,
  });

  /// Cancel a pending notification.
  Future<bool> cancel(String notificationId);
}

/// Notification to send.
class Notification {
  /// Unique notification identifier.
  final String notificationId;

  /// Recipient identifier (user ID, email, etc.).
  final String recipientId;

  /// Type of notification.
  final NotificationType type;

  /// Notification title.
  final String title;

  /// Notification body/message.
  final String body;

  /// Structured data payload.
  final Map<String, dynamic> data;

  /// Priority level.
  final NotificationPriority priority;

  /// Channels to use for delivery.
  final List<NotificationChannel> channels;

  /// Optional action URL or deep link.
  final String? actionUrl;

  /// When the notification expires (won't be delivered after).
  final DateTime? expiresAt;

  /// Schedule for future delivery.
  final DateTime? scheduledAt;

  /// Group ID for notification grouping.
  final String? groupId;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const Notification({
    required this.notificationId,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.priority = NotificationPriority.normal,
    this.channels = const [NotificationChannel.inApp],
    this.actionUrl,
    this.expiresAt,
    this.scheduledAt,
    this.groupId,
    this.metadata = const {},
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      notificationId: json['notificationId'] as String,
      recipientId: json['recipientId'] as String,
      type: NotificationType.fromString(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      priority: NotificationPriority.fromString(
          json['priority'] as String? ?? 'normal'),
      channels: (json['channels'] as List<dynamic>?)
              ?.map((e) => NotificationChannel.fromString(e as String))
              .toList() ??
          [NotificationChannel.inApp],
      actionUrl: json['actionUrl'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'] as String)
          : null,
      groupId: json['groupId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'notificationId': notificationId,
        'recipientId': recipientId,
        'type': type.name,
        'title': title,
        'body': body,
        if (data.isNotEmpty) 'data': data,
        'priority': priority.name,
        'channels': channels.map((c) => c.name).toList(),
        if (actionUrl != null) 'actionUrl': actionUrl,
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
        if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
        if (groupId != null) 'groupId': groupId,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Create a copy with updated fields.
  Notification copyWith({
    String? notificationId,
    String? recipientId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    NotificationPriority? priority,
    List<NotificationChannel>? channels,
    String? actionUrl,
    DateTime? expiresAt,
    DateTime? scheduledAt,
    String? groupId,
    Map<String, dynamic>? metadata,
  }) {
    return Notification(
      notificationId: notificationId ?? this.notificationId,
      recipientId: recipientId ?? this.recipientId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      channels: channels ?? this.channels,
      actionUrl: actionUrl ?? this.actionUrl,
      expiresAt: expiresAt ?? this.expiresAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      groupId: groupId ?? this.groupId,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Type of notification.
enum NotificationType {
  /// Informational message.
  info,

  /// Warning message.
  warning,

  /// Error/alert message.
  error,

  /// Success confirmation.
  success,

  /// Requires user action.
  action,

  /// Reminder.
  reminder,

  /// System notification.
  system;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.info,
    );
  }
}

/// Priority of notification.
enum NotificationPriority {
  /// Low priority - may be batched.
  low,

  /// Normal priority.
  normal,

  /// High priority - delivered promptly.
  high,

  /// Urgent - immediate delivery, may interrupt.
  urgent;

  static NotificationPriority fromString(String value) {
    return NotificationPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationPriority.normal,
    );
  }
}

/// Channel for notification delivery.
enum NotificationChannel {
  /// In-app notification.
  inApp,

  /// Email notification.
  email,

  /// SMS notification.
  sms,

  /// Push notification.
  push,

  /// Webhook callback.
  webhook,

  /// Slack message.
  slack,

  /// Microsoft Teams message.
  teams;

  static NotificationChannel fromString(String value) {
    return NotificationChannel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationChannel.inApp,
    );
  }
}

/// Result of sending a notification.
class NotificationResult {
  /// Notification ID.
  final String notificationId;

  /// Whether the notification was accepted for delivery.
  final bool accepted;

  /// Current status.
  final NotificationStatus status;

  /// Error message if failed.
  final String? error;

  /// Delivery results per channel.
  final Map<NotificationChannel, ChannelDeliveryResult> channelResults;

  const NotificationResult({
    required this.notificationId,
    required this.accepted,
    required this.status,
    this.error,
    this.channelResults = const {},
  });

  factory NotificationResult.fromJson(Map<String, dynamic> json) {
    return NotificationResult(
      notificationId: json['notificationId'] as String,
      accepted: json['accepted'] as bool,
      status: NotificationStatus.fromString(json['status'] as String),
      error: json['error'] as String?,
      channelResults: (json['channelResults'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              NotificationChannel.fromString(k),
              ChannelDeliveryResult.fromJson(v as Map<String, dynamic>),
            ),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() => {
        'notificationId': notificationId,
        'accepted': accepted,
        'status': status.name,
        if (error != null) 'error': error,
        if (channelResults.isNotEmpty)
          'channelResults': channelResults.map(
            (k, v) => MapEntry(k.name, v.toJson()),
          ),
      };

  /// Check if notification was successfully delivered.
  bool get isDelivered => status == NotificationStatus.delivered;

  /// Check if notification failed.
  bool get isFailed => status == NotificationStatus.failed;
}

/// Status of a notification.
enum NotificationStatus {
  /// Notification is queued for delivery.
  queued,

  /// Notification is being sent.
  sending,

  /// Notification was delivered.
  delivered,

  /// Delivery failed.
  failed,

  /// Notification was cancelled.
  cancelled,

  /// Notification expired before delivery.
  expired,

  /// Notification was read/acknowledged.
  read;

  static NotificationStatus fromString(String value) {
    return NotificationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationStatus.queued,
    );
  }
}

/// Delivery result for a specific channel.
class ChannelDeliveryResult {
  /// Channel used.
  final NotificationChannel channel;

  /// Whether delivery succeeded.
  final bool success;

  /// When delivery occurred.
  final DateTime? deliveredAt;

  /// Error if failed.
  final String? error;

  /// Channel-specific response data.
  final Map<String, dynamic> response;

  const ChannelDeliveryResult({
    required this.channel,
    required this.success,
    this.deliveredAt,
    this.error,
    this.response = const {},
  });

  factory ChannelDeliveryResult.fromJson(Map<String, dynamic> json) {
    return ChannelDeliveryResult(
      channel: NotificationChannel.fromString(json['channel'] as String),
      success: json['success'] as bool,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      error: json['error'] as String?,
      response: json['response'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'channel': channel.name,
        'success': success,
        if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
        if (error != null) 'error': error,
        if (response.isNotEmpty) 'response': response,
      };
}

/// Historical notification record.
class NotificationRecord {
  /// Original notification.
  final Notification notification;

  /// Delivery result.
  final NotificationResult result;

  /// When the notification was created.
  final DateTime createdAt;

  /// When it was last updated.
  final DateTime updatedAt;

  const NotificationRecord({
    required this.notification,
    required this.result,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationRecord.fromJson(Map<String, dynamic> json) {
    return NotificationRecord(
      notification:
          Notification.fromJson(json['notification'] as Map<String, dynamic>),
      result:
          NotificationResult.fromJson(json['result'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'notification': notification.toJson(),
        'result': result.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// Stub implementation for testing.
class StubNotificationPort implements NotificationPort {
  final List<Notification> sentNotifications = [];
  final bool _simulateSuccess;
  final Duration _simulateDelay;

  StubNotificationPort({
    bool simulateSuccess = true,
    Duration simulateDelay = Duration.zero,
  })  : _simulateSuccess = simulateSuccess,
        _simulateDelay = simulateDelay;

  @override
  Future<NotificationResult> notify(Notification notification) async {
    if (_simulateDelay > Duration.zero) {
      await Future<void>.delayed(_simulateDelay);
    }

    sentNotifications.add(notification);

    return NotificationResult(
      notificationId: notification.notificationId,
      accepted: _simulateSuccess,
      status: _simulateSuccess
          ? NotificationStatus.delivered
          : NotificationStatus.failed,
      error: _simulateSuccess ? null : 'Simulated failure',
    );
  }

  @override
  Future<List<NotificationResult>> notifyBatch(
      List<Notification> notifications) async {
    final results = <NotificationResult>[];
    for (final notification in notifications) {
      results.add(await notify(notification));
    }
    return results;
  }

  @override
  Future<NotificationStatus> getStatus(String notificationId) async {
    final exists = sentNotifications.any(
      (n) => n.notificationId == notificationId,
    );
    if (!exists) {
      throw StateError('Notification not found: $notificationId');
    }
    return _simulateSuccess
        ? NotificationStatus.delivered
        : NotificationStatus.failed;
  }

  @override
  Future<List<NotificationRecord>> getHistory({
    String? recipientId,
    NotificationType? type,
    DateTime? since,
    int limit = 100,
  }) async {
    var filtered = sentNotifications.where((n) {
      if (recipientId != null && n.recipientId != recipientId) return false;
      if (type != null && n.type != type) return false;
      return true;
    }).toList();

    if (limit < filtered.length) {
      filtered = filtered.sublist(0, limit);
    }

    return filtered
        .map((n) => NotificationRecord(
              notification: n,
              result: NotificationResult(
                notificationId: n.notificationId,
                accepted: true,
                status: NotificationStatus.delivered,
              ),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ))
        .toList();
  }

  @override
  Future<bool> cancel(String notificationId) async {
    final index = sentNotifications.indexWhere(
      (n) => n.notificationId == notificationId,
    );
    if (index >= 0) {
      sentNotifications.removeAt(index);
      return true;
    }
    return false;
  }

  /// Clear all sent notifications (for testing).
  void clear() {
    sentNotifications.clear();
  }
}
