import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  // ==========================================================================
  // NotificationType enum
  // ==========================================================================
  group('NotificationType', () {
    test('has all expected values', () {
      expect(NotificationType.values, containsAll([
        NotificationType.info,
        NotificationType.warning,
        NotificationType.error,
        NotificationType.success,
        NotificationType.action,
        NotificationType.reminder,
        NotificationType.system,
      ]));
    });

    test('fromString resolves known values', () {
      expect(NotificationType.fromString('info'), NotificationType.info);
      expect(NotificationType.fromString('warning'), NotificationType.warning);
      expect(NotificationType.fromString('error'), NotificationType.error);
      expect(NotificationType.fromString('success'), NotificationType.success);
      expect(NotificationType.fromString('action'), NotificationType.action);
      expect(NotificationType.fromString('reminder'), NotificationType.reminder);
      expect(NotificationType.fromString('system'), NotificationType.system);
    });

    test('fromString defaults to info for unknown value', () {
      expect(NotificationType.fromString('unknown'), NotificationType.info);
      expect(NotificationType.fromString(''), NotificationType.info);
    });
  });

  // ==========================================================================
  // NotificationPriority enum
  // ==========================================================================
  group('NotificationPriority', () {
    test('has all expected values', () {
      expect(NotificationPriority.values, containsAll([
        NotificationPriority.low,
        NotificationPriority.normal,
        NotificationPriority.high,
        NotificationPriority.urgent,
      ]));
    });

    test('fromString resolves known values', () {
      expect(
        NotificationPriority.fromString('low'),
        NotificationPriority.low,
      );
      expect(
        NotificationPriority.fromString('normal'),
        NotificationPriority.normal,
      );
      expect(
        NotificationPriority.fromString('high'),
        NotificationPriority.high,
      );
      expect(
        NotificationPriority.fromString('urgent'),
        NotificationPriority.urgent,
      );
    });

    test('fromString defaults to normal for unknown value', () {
      expect(
        NotificationPriority.fromString('critical'),
        NotificationPriority.normal,
      );
      expect(
        NotificationPriority.fromString(''),
        NotificationPriority.normal,
      );
    });
  });

  // ==========================================================================
  // NotificationChannel enum
  // ==========================================================================
  group('NotificationChannel', () {
    test('has all expected values', () {
      expect(NotificationChannel.values, containsAll([
        NotificationChannel.inApp,
        NotificationChannel.email,
        NotificationChannel.sms,
        NotificationChannel.push,
        NotificationChannel.webhook,
        NotificationChannel.slack,
        NotificationChannel.teams,
      ]));
    });

    test('fromString resolves known values', () {
      expect(
        NotificationChannel.fromString('inApp'),
        NotificationChannel.inApp,
      );
      expect(
        NotificationChannel.fromString('email'),
        NotificationChannel.email,
      );
      expect(
        NotificationChannel.fromString('sms'),
        NotificationChannel.sms,
      );
      expect(
        NotificationChannel.fromString('push'),
        NotificationChannel.push,
      );
      expect(
        NotificationChannel.fromString('webhook'),
        NotificationChannel.webhook,
      );
      expect(
        NotificationChannel.fromString('slack'),
        NotificationChannel.slack,
      );
      expect(
        NotificationChannel.fromString('teams'),
        NotificationChannel.teams,
      );
    });

    test('fromString defaults to inApp for unknown value', () {
      expect(
        NotificationChannel.fromString('carrier_pigeon'),
        NotificationChannel.inApp,
      );
    });
  });

  // ==========================================================================
  // NotificationStatus enum
  // ==========================================================================
  group('NotificationStatus', () {
    test('has all expected values', () {
      expect(NotificationStatus.values, containsAll([
        NotificationStatus.queued,
        NotificationStatus.sending,
        NotificationStatus.delivered,
        NotificationStatus.failed,
        NotificationStatus.cancelled,
        NotificationStatus.expired,
        NotificationStatus.read,
      ]));
    });

    test('fromString resolves known values', () {
      expect(
        NotificationStatus.fromString('queued'),
        NotificationStatus.queued,
      );
      expect(
        NotificationStatus.fromString('sending'),
        NotificationStatus.sending,
      );
      expect(
        NotificationStatus.fromString('delivered'),
        NotificationStatus.delivered,
      );
      expect(
        NotificationStatus.fromString('failed'),
        NotificationStatus.failed,
      );
      expect(
        NotificationStatus.fromString('cancelled'),
        NotificationStatus.cancelled,
      );
      expect(
        NotificationStatus.fromString('expired'),
        NotificationStatus.expired,
      );
      expect(
        NotificationStatus.fromString('read'),
        NotificationStatus.read,
      );
    });

    test('fromString defaults to queued for unknown value', () {
      expect(
        NotificationStatus.fromString('processing'),
        NotificationStatus.queued,
      );
    });
  });

  // ==========================================================================
  // Notification
  // ==========================================================================
  group('Notification', () {
    test('constructs with required fields and defaults', () {
      const notification = Notification(
        notificationId: 'n-1',
        recipientId: 'user-1',
        type: NotificationType.info,
        title: 'Test Title',
        body: 'Test body message',
      );
      expect(notification.notificationId, equals('n-1'));
      expect(notification.recipientId, equals('user-1'));
      expect(notification.type, equals(NotificationType.info));
      expect(notification.title, equals('Test Title'));
      expect(notification.body, equals('Test body message'));
      expect(notification.data, isEmpty);
      expect(notification.priority, equals(NotificationPriority.normal));
      expect(notification.channels, equals([NotificationChannel.inApp]));
      expect(notification.actionUrl, isNull);
      expect(notification.expiresAt, isNull);
      expect(notification.scheduledAt, isNull);
      expect(notification.groupId, isNull);
      expect(notification.metadata, isEmpty);
    });

    test('constructs with all fields', () {
      final expiresAt = DateTime.utc(2025, 12, 31);
      final scheduledAt = DateTime.utc(2025, 6, 15, 9, 0);
      final notification = Notification(
        notificationId: 'n-2',
        recipientId: 'user-2',
        type: NotificationType.warning,
        title: 'Alert',
        body: 'Something happened',
        data: const {'key': 'value'},
        priority: NotificationPriority.high,
        channels: const [NotificationChannel.email, NotificationChannel.push],
        actionUrl: 'https://example.com/action',
        expiresAt: expiresAt,
        scheduledAt: scheduledAt,
        groupId: 'group-A',
        metadata: const {'source': 'test'},
      );
      expect(notification.data['key'], equals('value'));
      expect(notification.priority, equals(NotificationPriority.high));
      expect(notification.channels, hasLength(2));
      expect(notification.actionUrl, equals('https://example.com/action'));
      expect(notification.expiresAt, equals(expiresAt));
      expect(notification.scheduledAt, equals(scheduledAt));
      expect(notification.groupId, equals('group-A'));
      expect(notification.metadata['source'], equals('test'));
    });

    test('fromJson creates correct instance with all fields', () {
      final notification = Notification.fromJson({
        'notificationId': 'n-3',
        'recipientId': 'user-3',
        'type': 'error',
        'title': 'Error Alert',
        'body': 'Something failed',
        'data': {'code': 500},
        'priority': 'urgent',
        'channels': ['email', 'sms'],
        'actionUrl': 'https://example.com/fix',
        'expiresAt': '2025-12-31T23:59:59.000Z',
        'scheduledAt': '2025-06-01T00:00:00.000Z',
        'groupId': 'errors',
        'metadata': {'env': 'production'},
      });
      expect(notification.notificationId, equals('n-3'));
      expect(notification.type, equals(NotificationType.error));
      expect(notification.priority, equals(NotificationPriority.urgent));
      expect(notification.channels, equals([
        NotificationChannel.email,
        NotificationChannel.sms,
      ]));
      expect(notification.actionUrl, equals('https://example.com/fix'));
      expect(notification.expiresAt, equals(DateTime.utc(2025, 12, 31, 23, 59, 59)));
      expect(notification.scheduledAt, equals(DateTime.utc(2025, 6, 1)));
      expect(notification.groupId, equals('errors'));
      expect(notification.data['code'], equals(500));
      expect(notification.metadata['env'], equals('production'));
    });

    test('fromJson uses defaults for missing optional fields', () {
      final notification = Notification.fromJson({
        'notificationId': 'n-4',
        'recipientId': 'user-4',
        'type': 'info',
        'title': 'Minimal',
        'body': 'Minimal notification',
      });
      expect(notification.data, isEmpty);
      expect(notification.priority, equals(NotificationPriority.normal));
      expect(notification.channels, equals([NotificationChannel.inApp]));
      expect(notification.actionUrl, isNull);
      expect(notification.expiresAt, isNull);
      expect(notification.scheduledAt, isNull);
      expect(notification.groupId, isNull);
      expect(notification.metadata, isEmpty);
    });

    test('toJson includes all present fields', () {
      final notification = Notification(
        notificationId: 'n-5',
        recipientId: 'user-5',
        type: NotificationType.success,
        title: 'Done',
        body: 'Task completed',
        data: const {'taskId': 42},
        priority: NotificationPriority.low,
        channels: const [NotificationChannel.webhook],
        actionUrl: 'https://example.com/done',
        expiresAt: DateTime.utc(2025, 12, 1),
        scheduledAt: DateTime.utc(2025, 6, 1),
        groupId: 'tasks',
        metadata: const {'tag': 'auto'},
      );
      final json = notification.toJson();
      expect(json['notificationId'], equals('n-5'));
      expect(json['recipientId'], equals('user-5'));
      expect(json['type'], equals('success'));
      expect(json['title'], equals('Done'));
      expect(json['body'], equals('Task completed'));
      expect(json['data'], isA<Map<String, dynamic>>());
      expect(json['priority'], equals('low'));
      expect(json['channels'], equals(['webhook']));
      expect(json['actionUrl'], equals('https://example.com/done'));
      expect(json['expiresAt'], isA<String>());
      expect(json['scheduledAt'], isA<String>());
      expect(json['groupId'], equals('tasks'));
      expect(json['metadata'], isA<Map<String, dynamic>>());
    });

    test('toJson omits empty data and metadata', () {
      const notification = Notification(
        notificationId: 'n-6',
        recipientId: 'user-6',
        type: NotificationType.info,
        title: 'Sparse',
        body: 'Sparse notification',
      );
      final json = notification.toJson();
      expect(json.containsKey('data'), isFalse);
      expect(json.containsKey('actionUrl'), isFalse);
      expect(json.containsKey('expiresAt'), isFalse);
      expect(json.containsKey('scheduledAt'), isFalse);
      expect(json.containsKey('groupId'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = Notification(
        notificationId: 'n-rt',
        recipientId: 'user-rt',
        type: NotificationType.action,
        title: 'Roundtrip Title',
        body: 'Roundtrip body',
        data: const {'nested': 'data'},
        priority: NotificationPriority.high,
        channels: const [
          NotificationChannel.email,
          NotificationChannel.push,
          NotificationChannel.slack,
        ],
        actionUrl: 'https://example.com/roundtrip',
        expiresAt: DateTime.utc(2025, 12, 31),
        scheduledAt: DateTime.utc(2025, 7, 1),
        groupId: 'group-rt',
        metadata: const {'rtKey': 'rtVal'},
      );
      final restored = Notification.fromJson(original.toJson());
      expect(restored.notificationId, equals(original.notificationId));
      expect(restored.recipientId, equals(original.recipientId));
      expect(restored.type, equals(original.type));
      expect(restored.title, equals(original.title));
      expect(restored.body, equals(original.body));
      expect(restored.data['nested'], equals('data'));
      expect(restored.priority, equals(original.priority));
      expect(restored.channels, equals(original.channels));
      expect(restored.actionUrl, equals(original.actionUrl));
      expect(restored.expiresAt, equals(original.expiresAt));
      expect(restored.scheduledAt, equals(original.scheduledAt));
      expect(restored.groupId, equals(original.groupId));
      expect(restored.metadata['rtKey'], equals('rtVal'));
    });

    group('copyWith', () {
      const base = Notification(
        notificationId: 'n-base',
        recipientId: 'user-base',
        type: NotificationType.info,
        title: 'Base Title',
        body: 'Base body',
      );

      test('returns identical copy when no fields specified', () {
        final copy = base.copyWith();
        expect(copy.notificationId, equals(base.notificationId));
        expect(copy.recipientId, equals(base.recipientId));
        expect(copy.type, equals(base.type));
        expect(copy.title, equals(base.title));
        expect(copy.body, equals(base.body));
        expect(copy.priority, equals(base.priority));
        expect(copy.channels, equals(base.channels));
      });

      test('updates notificationId', () {
        final copy = base.copyWith(notificationId: 'n-new');
        expect(copy.notificationId, equals('n-new'));
        expect(copy.title, equals('Base Title'));
      });

      test('updates recipientId', () {
        final copy = base.copyWith(recipientId: 'user-new');
        expect(copy.recipientId, equals('user-new'));
      });

      test('updates type', () {
        final copy = base.copyWith(type: NotificationType.error);
        expect(copy.type, equals(NotificationType.error));
      });

      test('updates title and body', () {
        final copy = base.copyWith(
          title: 'New Title',
          body: 'New body',
        );
        expect(copy.title, equals('New Title'));
        expect(copy.body, equals('New body'));
      });

      test('updates priority', () {
        final copy = base.copyWith(priority: NotificationPriority.urgent);
        expect(copy.priority, equals(NotificationPriority.urgent));
      });

      test('updates channels', () {
        final copy = base.copyWith(
          channels: [NotificationChannel.email, NotificationChannel.sms],
        );
        expect(copy.channels, hasLength(2));
        expect(copy.channels, contains(NotificationChannel.email));
        expect(copy.channels, contains(NotificationChannel.sms));
      });

      test('updates optional fields', () {
        final copy = base.copyWith(
          actionUrl: 'https://example.com/new',
          expiresAt: DateTime.utc(2026, 1, 1),
          scheduledAt: DateTime.utc(2025, 12, 1),
          groupId: 'new-group',
          data: {'newKey': 'newValue'},
          metadata: {'meta': true},
        );
        expect(copy.actionUrl, equals('https://example.com/new'));
        expect(copy.expiresAt, equals(DateTime.utc(2026, 1, 1)));
        expect(copy.scheduledAt, equals(DateTime.utc(2025, 12, 1)));
        expect(copy.groupId, equals('new-group'));
        expect(copy.data['newKey'], equals('newValue'));
        expect(copy.metadata['meta'], isTrue);
      });

      test('updates multiple fields at once', () {
        final copy = base.copyWith(
          title: 'Updated',
          priority: NotificationPriority.high,
          channels: [NotificationChannel.push],
        );
        expect(copy.title, equals('Updated'));
        expect(copy.priority, equals(NotificationPriority.high));
        expect(copy.channels, equals([NotificationChannel.push]));
        // Unchanged fields remain the same
        expect(copy.notificationId, equals(base.notificationId));
        expect(copy.body, equals(base.body));
      });
    });
  });

  // ==========================================================================
  // ChannelDeliveryResult
  // ==========================================================================
  group('ChannelDeliveryResult', () {
    test('constructs with required fields and defaults', () {
      const result = ChannelDeliveryResult(
        channel: NotificationChannel.email,
        success: true,
      );
      expect(result.channel, equals(NotificationChannel.email));
      expect(result.success, isTrue);
      expect(result.deliveredAt, isNull);
      expect(result.error, isNull);
      expect(result.response, isEmpty);
    });

    test('constructs with all fields', () {
      final deliveredAt = DateTime.utc(2025, 6, 15, 10, 0);
      final result = ChannelDeliveryResult(
        channel: NotificationChannel.sms,
        success: false,
        deliveredAt: deliveredAt,
        error: 'Phone number invalid',
        response: const {'provider': 'twilio', 'code': 400},
      );
      expect(result.channel, equals(NotificationChannel.sms));
      expect(result.success, isFalse);
      expect(result.deliveredAt, equals(deliveredAt));
      expect(result.error, equals('Phone number invalid'));
      expect(result.response['provider'], equals('twilio'));
    });

    test('fromJson creates correct instance with all fields', () {
      final result = ChannelDeliveryResult.fromJson({
        'channel': 'push',
        'success': true,
        'deliveredAt': '2025-06-15T12:00:00.000Z',
        'response': {'token': 'abc123'},
      });
      expect(result.channel, equals(NotificationChannel.push));
      expect(result.success, isTrue);
      expect(
        result.deliveredAt,
        equals(DateTime.utc(2025, 6, 15, 12, 0)),
      );
      expect(result.response['token'], equals('abc123'));
    });

    test('fromJson creates instance without optional fields', () {
      final result = ChannelDeliveryResult.fromJson({
        'channel': 'webhook',
        'success': false,
        'error': 'Timeout',
      });
      expect(result.channel, equals(NotificationChannel.webhook));
      expect(result.success, isFalse);
      expect(result.deliveredAt, isNull);
      expect(result.error, equals('Timeout'));
      expect(result.response, isEmpty);
    });

    test('toJson includes all present fields', () {
      final result = ChannelDeliveryResult(
        channel: NotificationChannel.slack,
        success: true,
        deliveredAt: DateTime.utc(2025, 1, 1),
        error: null,
        response: const {'ts': '12345'},
      );
      final json = result.toJson();
      expect(json['channel'], equals('slack'));
      expect(json['success'], isTrue);
      expect(json['deliveredAt'], isA<String>());
      expect(json.containsKey('error'), isFalse);
      expect(json['response'], isA<Map<String, dynamic>>());
    });

    test('toJson omits null and empty optional fields', () {
      const result = ChannelDeliveryResult(
        channel: NotificationChannel.inApp,
        success: true,
      );
      final json = result.toJson();
      expect(json.containsKey('deliveredAt'), isFalse);
      expect(json.containsKey('error'), isFalse);
      expect(json.containsKey('response'), isFalse);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = ChannelDeliveryResult(
        channel: NotificationChannel.teams,
        success: false,
        deliveredAt: DateTime.utc(2025, 3, 15),
        error: 'Webhook unreachable',
        response: const {'statusCode': 503},
      );
      final restored = ChannelDeliveryResult.fromJson(original.toJson());
      expect(restored.channel, equals(original.channel));
      expect(restored.success, equals(original.success));
      expect(restored.deliveredAt, equals(original.deliveredAt));
      expect(restored.error, equals(original.error));
      expect(restored.response['statusCode'], equals(503));
    });
  });

  // ==========================================================================
  // NotificationResult
  // ==========================================================================
  group('NotificationResult', () {
    test('constructs with required fields and defaults', () {
      const result = NotificationResult(
        notificationId: 'n-1',
        accepted: true,
        status: NotificationStatus.delivered,
      );
      expect(result.notificationId, equals('n-1'));
      expect(result.accepted, isTrue);
      expect(result.status, equals(NotificationStatus.delivered));
      expect(result.error, isNull);
      expect(result.channelResults, isEmpty);
    });

    test('constructs with all fields', () {
      const result = NotificationResult(
        notificationId: 'n-2',
        accepted: false,
        status: NotificationStatus.failed,
        error: 'Delivery failed',
        channelResults: {
          NotificationChannel.email: ChannelDeliveryResult(
            channel: NotificationChannel.email,
            success: false,
            error: 'SMTP error',
          ),
        },
      );
      expect(result.error, equals('Delivery failed'));
      expect(result.channelResults, hasLength(1));
      expect(
        result.channelResults[NotificationChannel.email]!.error,
        equals('SMTP error'),
      );
    });

    test('isDelivered returns true only for delivered status', () {
      const delivered = NotificationResult(
        notificationId: 'n-d',
        accepted: true,
        status: NotificationStatus.delivered,
      );
      expect(delivered.isDelivered, isTrue);
      expect(delivered.isFailed, isFalse);

      const queued = NotificationResult(
        notificationId: 'n-q',
        accepted: true,
        status: NotificationStatus.queued,
      );
      expect(queued.isDelivered, isFalse);
    });

    test('isFailed returns true only for failed status', () {
      const failed = NotificationResult(
        notificationId: 'n-f',
        accepted: false,
        status: NotificationStatus.failed,
        error: 'Something broke',
      );
      expect(failed.isFailed, isTrue);
      expect(failed.isDelivered, isFalse);

      const sending = NotificationResult(
        notificationId: 'n-s',
        accepted: true,
        status: NotificationStatus.sending,
      );
      expect(sending.isFailed, isFalse);
    });

    test('isDelivered and isFailed are both false for other statuses', () {
      for (final status in [
        NotificationStatus.queued,
        NotificationStatus.sending,
        NotificationStatus.cancelled,
        NotificationStatus.expired,
        NotificationStatus.read,
      ]) {
        final result = NotificationResult(
          notificationId: 'n-check',
          accepted: true,
          status: status,
        );
        expect(result.isDelivered, isFalse,
            reason: '${status.name} should not be delivered');
        expect(result.isFailed, isFalse,
            reason: '${status.name} should not be failed');
      }
    });

    test('fromJson creates correct instance with channelResults', () {
      final result = NotificationResult.fromJson({
        'notificationId': 'n-json',
        'accepted': true,
        'status': 'delivered',
        'channelResults': {
          'email': {
            'channel': 'email',
            'success': true,
            'deliveredAt': '2025-06-15T12:00:00.000Z',
          },
          'push': {
            'channel': 'push',
            'success': false,
            'error': 'Token expired',
          },
        },
      });
      expect(result.notificationId, equals('n-json'));
      expect(result.accepted, isTrue);
      expect(result.status, equals(NotificationStatus.delivered));
      expect(result.channelResults, hasLength(2));
      expect(
        result.channelResults[NotificationChannel.email]!.success,
        isTrue,
      );
      expect(
        result.channelResults[NotificationChannel.push]!.error,
        equals('Token expired'),
      );
    });

    test('fromJson works without channelResults', () {
      final result = NotificationResult.fromJson({
        'notificationId': 'n-simple',
        'accepted': true,
        'status': 'queued',
      });
      expect(result.channelResults, isEmpty);
      expect(result.error, isNull);
    });

    test('toJson includes all present fields', () {
      const result = NotificationResult(
        notificationId: 'n-tj',
        accepted: false,
        status: NotificationStatus.failed,
        error: 'All channels failed',
        channelResults: {
          NotificationChannel.sms: ChannelDeliveryResult(
            channel: NotificationChannel.sms,
            success: false,
            error: 'Bad number',
          ),
        },
      );
      final json = result.toJson();
      expect(json['notificationId'], equals('n-tj'));
      expect(json['accepted'], isFalse);
      expect(json['status'], equals('failed'));
      expect(json['error'], equals('All channels failed'));
      expect(json['channelResults'], isA<Map<String, dynamic>>());
      expect(
        (json['channelResults'] as Map<String, dynamic>).containsKey('sms'),
        isTrue,
      );
    });

    test('toJson omits null error and empty channelResults', () {
      const result = NotificationResult(
        notificationId: 'n-sparse',
        accepted: true,
        status: NotificationStatus.delivered,
      );
      final json = result.toJson();
      expect(json.containsKey('error'), isFalse);
      expect(json.containsKey('channelResults'), isFalse);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      const original = NotificationResult(
        notificationId: 'n-rt',
        accepted: true,
        status: NotificationStatus.delivered,
        error: null,
        channelResults: {
          NotificationChannel.email: ChannelDeliveryResult(
            channel: NotificationChannel.email,
            success: true,
          ),
        },
      );
      final restored = NotificationResult.fromJson(original.toJson());
      expect(restored.notificationId, equals(original.notificationId));
      expect(restored.accepted, equals(original.accepted));
      expect(restored.status, equals(original.status));
      expect(restored.error, isNull);
      expect(restored.channelResults, hasLength(1));
      expect(
        restored.channelResults[NotificationChannel.email]!.success,
        isTrue,
      );
    });
  });

  // ==========================================================================
  // NotificationRecord
  // ==========================================================================
  group('NotificationRecord', () {
    test('constructs with required fields', () {
      final createdAt = DateTime.utc(2025, 6, 1);
      final updatedAt = DateTime.utc(2025, 6, 2);
      final record = NotificationRecord(
        notification: const Notification(
          notificationId: 'n-rec',
          recipientId: 'user-rec',
          type: NotificationType.info,
          title: 'Record Test',
          body: 'Record body',
        ),
        result: const NotificationResult(
          notificationId: 'n-rec',
          accepted: true,
          status: NotificationStatus.delivered,
        ),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      expect(record.notification.notificationId, equals('n-rec'));
      expect(record.result.status, equals(NotificationStatus.delivered));
      expect(record.createdAt, equals(createdAt));
      expect(record.updatedAt, equals(updatedAt));
    });

    test('fromJson creates correct instance', () {
      final record = NotificationRecord.fromJson({
        'notification': {
          'notificationId': 'n-fj',
          'recipientId': 'user-fj',
          'type': 'warning',
          'title': 'From JSON',
          'body': 'Parsed record',
        },
        'result': {
          'notificationId': 'n-fj',
          'accepted': true,
          'status': 'delivered',
        },
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-01-02T00:00:00.000Z',
      });
      expect(record.notification.title, equals('From JSON'));
      expect(record.notification.type, equals(NotificationType.warning));
      expect(record.result.accepted, isTrue);
      expect(record.createdAt, equals(DateTime.utc(2025, 1, 1)));
      expect(record.updatedAt, equals(DateTime.utc(2025, 1, 2)));
    });

    test('toJson includes all fields', () {
      final record = NotificationRecord(
        notification: const Notification(
          notificationId: 'n-tj',
          recipientId: 'user-tj',
          type: NotificationType.system,
          title: 'To JSON',
          body: 'JSON body',
        ),
        result: const NotificationResult(
          notificationId: 'n-tj',
          accepted: true,
          status: NotificationStatus.read,
        ),
        createdAt: DateTime.utc(2025, 3, 1),
        updatedAt: DateTime.utc(2025, 3, 2),
      );
      final json = record.toJson();
      expect(json['notification'], isA<Map<String, dynamic>>());
      expect(json['result'], isA<Map<String, dynamic>>());
      expect(json['createdAt'], equals('2025-03-01T00:00:00.000Z'));
      expect(json['updatedAt'], equals('2025-03-02T00:00:00.000Z'));
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = NotificationRecord(
        notification: const Notification(
          notificationId: 'n-rt',
          recipientId: 'user-rt',
          type: NotificationType.reminder,
          title: 'Roundtrip',
          body: 'RT body',
          data: {'k': 'v'},
          priority: NotificationPriority.high,
          channels: [NotificationChannel.email],
        ),
        result: const NotificationResult(
          notificationId: 'n-rt',
          accepted: true,
          status: NotificationStatus.delivered,
        ),
        createdAt: DateTime.utc(2025, 5, 1),
        updatedAt: DateTime.utc(2025, 5, 2),
      );
      final restored = NotificationRecord.fromJson(original.toJson());
      expect(
        restored.notification.notificationId,
        equals(original.notification.notificationId),
      );
      expect(restored.notification.type, equals(NotificationType.reminder));
      expect(restored.notification.priority, equals(NotificationPriority.high));
      expect(restored.result.status, equals(NotificationStatus.delivered));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.updatedAt, equals(original.updatedAt));
    });
  });

  // ==========================================================================
  // StubNotificationPort
  // ==========================================================================
  group('StubNotificationPort', () {
    test('notify records notification and returns delivered result', () async {
      final port = StubNotificationPort();
      const notification = Notification(
        notificationId: 'stub-1',
        recipientId: 'user-1',
        type: NotificationType.info,
        title: 'Stub Test',
        body: 'Test body',
      );
      final result = await port.notify(notification);
      expect(result.notificationId, equals('stub-1'));
      expect(result.accepted, isTrue);
      expect(result.status, equals(NotificationStatus.delivered));
      expect(result.error, isNull);
      expect(port.sentNotifications, hasLength(1));
      expect(port.sentNotifications.first.title, equals('Stub Test'));
    });

    test('notify with simulateSuccess=false returns failed', () async {
      final port = StubNotificationPort(simulateSuccess: false);
      const notification = Notification(
        notificationId: 'stub-f',
        recipientId: 'user-f',
        type: NotificationType.error,
        title: 'Fail Test',
        body: 'Should fail',
      );
      final result = await port.notify(notification);
      expect(result.accepted, isFalse);
      expect(result.status, equals(NotificationStatus.failed));
      expect(result.error, equals('Simulated failure'));
    });

    test('notifyBatch sends multiple notifications', () async {
      final port = StubNotificationPort();
      const notifications = [
        Notification(
          notificationId: 'batch-1',
          recipientId: 'user-1',
          type: NotificationType.info,
          title: 'Batch 1',
          body: 'Body 1',
        ),
        Notification(
          notificationId: 'batch-2',
          recipientId: 'user-2',
          type: NotificationType.info,
          title: 'Batch 2',
          body: 'Body 2',
        ),
      ];
      final results = await port.notifyBatch(notifications);
      expect(results, hasLength(2));
      expect(results[0].notificationId, equals('batch-1'));
      expect(results[1].notificationId, equals('batch-2'));
      expect(port.sentNotifications, hasLength(2));
    });

    test('getStatus returns delivered for known notification', () async {
      final port = StubNotificationPort();
      const notification = Notification(
        notificationId: 'status-1',
        recipientId: 'user-1',
        type: NotificationType.info,
        title: 'Status Test',
        body: 'Check status',
      );
      await port.notify(notification);
      final status = await port.getStatus('status-1');
      expect(status, equals(NotificationStatus.delivered));
    });

    test('getStatus returns failed when simulateSuccess is false', () async {
      final port = StubNotificationPort(simulateSuccess: false);
      const notification = Notification(
        notificationId: 'status-f',
        recipientId: 'user-f',
        type: NotificationType.info,
        title: 'Status Fail',
        body: 'Check fail status',
      );
      await port.notify(notification);
      final status = await port.getStatus('status-f');
      expect(status, equals(NotificationStatus.failed));
    });

    test('getStatus throws StateError for unknown notification', () async {
      final port = StubNotificationPort();
      expect(
        () => port.getStatus('nonexistent'),
        throwsStateError,
      );
    });

    test('getHistory returns records for sent notifications', () async {
      final port = StubNotificationPort();
      const n1 = Notification(
        notificationId: 'hist-1',
        recipientId: 'user-A',
        type: NotificationType.info,
        title: 'History 1',
        body: 'Body 1',
      );
      const n2 = Notification(
        notificationId: 'hist-2',
        recipientId: 'user-B',
        type: NotificationType.warning,
        title: 'History 2',
        body: 'Body 2',
      );
      await port.notify(n1);
      await port.notify(n2);

      final history = await port.getHistory();
      expect(history, hasLength(2));
    });

    test('getHistory filters by recipientId', () async {
      final port = StubNotificationPort();
      const n1 = Notification(
        notificationId: 'filt-1',
        recipientId: 'user-X',
        type: NotificationType.info,
        title: 'Filter 1',
        body: 'Body',
      );
      const n2 = Notification(
        notificationId: 'filt-2',
        recipientId: 'user-Y',
        type: NotificationType.info,
        title: 'Filter 2',
        body: 'Body',
      );
      await port.notify(n1);
      await port.notify(n2);

      final history = await port.getHistory(recipientId: 'user-X');
      expect(history, hasLength(1));
      expect(history.first.notification.recipientId, equals('user-X'));
    });

    test('getHistory filters by type', () async {
      final port = StubNotificationPort();
      const n1 = Notification(
        notificationId: 'type-1',
        recipientId: 'user-1',
        type: NotificationType.error,
        title: 'Error',
        body: 'Error body',
      );
      const n2 = Notification(
        notificationId: 'type-2',
        recipientId: 'user-1',
        type: NotificationType.info,
        title: 'Info',
        body: 'Info body',
      );
      await port.notify(n1);
      await port.notify(n2);

      final history = await port.getHistory(type: NotificationType.error);
      expect(history, hasLength(1));
      expect(history.first.notification.type, equals(NotificationType.error));
    });

    test('getHistory respects limit', () async {
      final port = StubNotificationPort();
      for (var i = 0; i < 5; i++) {
        await port.notify(Notification(
          notificationId: 'lim-$i',
          recipientId: 'user-1',
          type: NotificationType.info,
          title: 'Limit $i',
          body: 'Body $i',
        ));
      }
      final history = await port.getHistory(limit: 3);
      expect(history, hasLength(3));
    });

    test('cancel removes notification and returns true', () async {
      final port = StubNotificationPort();
      const notification = Notification(
        notificationId: 'cancel-1',
        recipientId: 'user-1',
        type: NotificationType.info,
        title: 'To Cancel',
        body: 'Cancel me',
      );
      await port.notify(notification);
      expect(port.sentNotifications, hasLength(1));

      final cancelled = await port.cancel('cancel-1');
      expect(cancelled, isTrue);
      expect(port.sentNotifications, isEmpty);
    });

    test('cancel returns false for unknown notification', () async {
      final port = StubNotificationPort();
      final cancelled = await port.cancel('nonexistent');
      expect(cancelled, isFalse);
    });

    test('clear removes all notifications', () async {
      final port = StubNotificationPort();
      for (var i = 0; i < 3; i++) {
        await port.notify(Notification(
          notificationId: 'clr-$i',
          recipientId: 'user-1',
          type: NotificationType.info,
          title: 'Clear $i',
          body: 'Body $i',
        ));
      }
      expect(port.sentNotifications, hasLength(3));
      port.clear();
      expect(port.sentNotifications, isEmpty);
    });
  });
}
