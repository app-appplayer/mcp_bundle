import 'dart:async';

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  // ==========================================================================
  // ChannelIdentity
  // ==========================================================================
  group('ChannelIdentity', () {
    test('constructs with required fields', () {
      const identity = ChannelIdentity(
        platform: 'slack',
        channelId: 'C12345',
      );
      expect(identity.platform, equals('slack'));
      expect(identity.channelId, equals('C12345'));
      expect(identity.displayName, isNull);
    });

    test('constructs with all fields', () {
      const identity = ChannelIdentity(
        platform: 'telegram',
        channelId: 'T99',
        displayName: 'My Channel',
      );
      expect(identity.platform, equals('telegram'));
      expect(identity.channelId, equals('T99'));
      expect(identity.displayName, equals('My Channel'));
    });

    test('fromJson creates correct instance with all fields', () {
      final identity = ChannelIdentity.fromJson({
        'platform': 'discord',
        'channelId': 'D001',
        'displayName': 'General',
      });
      expect(identity.platform, equals('discord'));
      expect(identity.channelId, equals('D001'));
      expect(identity.displayName, equals('General'));
    });

    test('fromJson creates instance without optional fields', () {
      final identity = ChannelIdentity.fromJson({
        'platform': 'http',
        'channelId': 'H100',
      });
      expect(identity.platform, equals('http'));
      expect(identity.channelId, equals('H100'));
      expect(identity.displayName, isNull);
    });

    test('toJson includes all fields when present', () {
      const identity = ChannelIdentity(
        platform: 'slack',
        channelId: 'C1',
        displayName: 'Test',
      );
      final json = identity.toJson();
      expect(json['platform'], equals('slack'));
      expect(json['channelId'], equals('C1'));
      expect(json['displayName'], equals('Test'));
    });

    test('toJson omits null displayName', () {
      const identity = ChannelIdentity(
        platform: 'http',
        channelId: 'H1',
      );
      final json = identity.toJson();
      expect(json.containsKey('displayName'), isFalse);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      const original = ChannelIdentity(
        platform: 'websocket',
        channelId: 'WS42',
        displayName: 'Live Feed',
      );
      final json = original.toJson();
      final restored = ChannelIdentity.fromJson(json);
      expect(restored.platform, equals(original.platform));
      expect(restored.channelId, equals(original.channelId));
      expect(restored.displayName, equals(original.displayName));
    });

    test('fromJson/toJson roundtrip without optional fields', () {
      const original = ChannelIdentity(
        platform: 'stdio',
        channelId: 'S1',
      );
      final restored = ChannelIdentity.fromJson(original.toJson());
      expect(restored.platform, equals(original.platform));
      expect(restored.channelId, equals(original.channelId));
      expect(restored.displayName, isNull);
    });

    test('equality compares platform and channelId', () {
      const a = ChannelIdentity(platform: 'slack', channelId: 'C1');
      const b = ChannelIdentity(platform: 'slack', channelId: 'C1');
      const c = ChannelIdentity(platform: 'slack', channelId: 'C2');
      const d = ChannelIdentity(platform: 'telegram', channelId: 'C1');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });

    test('equality ignores displayName', () {
      const a = ChannelIdentity(
        platform: 'slack',
        channelId: 'C1',
        displayName: 'Name A',
      );
      const b = ChannelIdentity(
        platform: 'slack',
        channelId: 'C1',
        displayName: 'Name B',
      );
      expect(a, equals(b));
    });

    test('hashCode is consistent with equality', () {
      const a = ChannelIdentity(platform: 'slack', channelId: 'C1');
      const b = ChannelIdentity(platform: 'slack', channelId: 'C1');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs for different identities', () {
      const a = ChannelIdentity(platform: 'slack', channelId: 'C1');
      const b = ChannelIdentity(platform: 'slack', channelId: 'C2');
      // Not guaranteed to differ, but highly likely for different inputs
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('toString returns formatted string', () {
      const identity = ChannelIdentity(
        platform: 'slack',
        channelId: 'C1',
      );
      expect(identity.toString(), equals('ChannelIdentity(slack:C1)'));
    });
  });

  // ==========================================================================
  // ConversationKey
  // ==========================================================================
  group('ConversationKey', () {
    const channel = ChannelIdentity(platform: 'slack', channelId: 'C1');

    test('constructs with required fields', () {
      const key = ConversationKey(
        channel: channel,
        conversationId: 'conv-1',
      );
      expect(key.channel, equals(channel));
      expect(key.conversationId, equals('conv-1'));
      expect(key.userId, isNull);
    });

    test('constructs with all fields', () {
      const key = ConversationKey(
        channel: channel,
        conversationId: 'conv-2',
        userId: 'user-42',
      );
      expect(key.userId, equals('user-42'));
    });

    test('fromJson creates correct instance', () {
      final key = ConversationKey.fromJson({
        'channel': {'platform': 'telegram', 'channelId': 'T1'},
        'conversationId': 'thread-5',
        'userId': 'U100',
      });
      expect(key.channel.platform, equals('telegram'));
      expect(key.channel.channelId, equals('T1'));
      expect(key.conversationId, equals('thread-5'));
      expect(key.userId, equals('U100'));
    });

    test('fromJson works without optional userId', () {
      final key = ConversationKey.fromJson({
        'channel': {'platform': 'http', 'channelId': 'H1'},
        'conversationId': 'req-1',
      });
      expect(key.userId, isNull);
    });

    test('toJson includes all fields when present', () {
      const key = ConversationKey(
        channel: channel,
        conversationId: 'conv-3',
        userId: 'U5',
      );
      final json = key.toJson();
      expect(json['channel'], isA<Map<String, dynamic>>());
      expect(json['conversationId'], equals('conv-3'));
      expect(json['userId'], equals('U5'));
    });

    test('toJson omits null userId', () {
      const key = ConversationKey(
        channel: channel,
        conversationId: 'conv-4',
      );
      final json = key.toJson();
      expect(json.containsKey('userId'), isFalse);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      const original = ConversationKey(
        channel: ChannelIdentity(
          platform: 'discord',
          channelId: 'D1',
          displayName: 'Guild',
        ),
        conversationId: 'thread-9',
        userId: 'U77',
      );
      final restored = ConversationKey.fromJson(original.toJson());
      expect(restored.channel.platform, equals('discord'));
      expect(restored.channel.channelId, equals('D1'));
      expect(restored.conversationId, equals('thread-9'));
      expect(restored.userId, equals('U77'));
    });

    test('equality compares channel and conversationId', () {
      const a = ConversationKey(channel: channel, conversationId: 'c1');
      const b = ConversationKey(channel: channel, conversationId: 'c1');
      const c = ConversationKey(channel: channel, conversationId: 'c2');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('equality ignores userId', () {
      const a = ConversationKey(
        channel: channel,
        conversationId: 'c1',
        userId: 'U1',
      );
      const b = ConversationKey(
        channel: channel,
        conversationId: 'c1',
        userId: 'U2',
      );
      expect(a, equals(b));
    });

    test('hashCode is consistent with equality', () {
      const a = ConversationKey(channel: channel, conversationId: 'c1');
      const b = ConversationKey(channel: channel, conversationId: 'c1');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns formatted string', () {
      const key = ConversationKey(channel: channel, conversationId: 'conv-1');
      expect(key.toString(), equals('ConversationKey(slack:conv-1)'));
    });
  });

  // ==========================================================================
  // ChannelAttachment
  // ==========================================================================
  group('ChannelAttachment', () {
    test('constructs with required fields only', () {
      const att = ChannelAttachment(
        type: 'image',
        url: 'https://example.com/image.png',
      );
      expect(att.type, equals('image'));
      expect(att.url, equals('https://example.com/image.png'));
      expect(att.filename, isNull);
      expect(att.mimeType, isNull);
      expect(att.size, isNull);
    });

    test('constructs with all fields', () {
      const att = ChannelAttachment(
        type: 'file',
        url: 'https://example.com/doc.pdf',
        filename: 'doc.pdf',
        mimeType: 'application/pdf',
        size: 1024,
      );
      expect(att.filename, equals('doc.pdf'));
      expect(att.mimeType, equals('application/pdf'));
      expect(att.size, equals(1024));
    });

    test('fromJson creates correct instance with all fields', () {
      final att = ChannelAttachment.fromJson({
        'type': 'audio',
        'url': 'https://example.com/audio.mp3',
        'filename': 'audio.mp3',
        'mimeType': 'audio/mpeg',
        'size': 5120,
      });
      expect(att.type, equals('audio'));
      expect(att.url, equals('https://example.com/audio.mp3'));
      expect(att.filename, equals('audio.mp3'));
      expect(att.mimeType, equals('audio/mpeg'));
      expect(att.size, equals(5120));
    });

    test('fromJson creates instance without optional fields', () {
      final att = ChannelAttachment.fromJson({
        'type': 'video',
        'url': 'https://example.com/video.mp4',
      });
      expect(att.filename, isNull);
      expect(att.mimeType, isNull);
      expect(att.size, isNull);
    });

    test('toJson includes all fields when present', () {
      const att = ChannelAttachment(
        type: 'image',
        url: 'https://example.com/img.jpg',
        filename: 'img.jpg',
        mimeType: 'image/jpeg',
        size: 2048,
      );
      final json = att.toJson();
      expect(json['type'], equals('image'));
      expect(json['url'], equals('https://example.com/img.jpg'));
      expect(json['filename'], equals('img.jpg'));
      expect(json['mimeType'], equals('image/jpeg'));
      expect(json['size'], equals(2048));
    });

    test('toJson omits null optional fields', () {
      const att = ChannelAttachment(
        type: 'file',
        url: 'https://example.com/file.bin',
      );
      final json = att.toJson();
      expect(json.containsKey('filename'), isFalse);
      expect(json.containsKey('mimeType'), isFalse);
      expect(json.containsKey('size'), isFalse);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      const original = ChannelAttachment(
        type: 'file',
        url: 'https://example.com/data.csv',
        filename: 'data.csv',
        mimeType: 'text/csv',
        size: 999,
      );
      final restored = ChannelAttachment.fromJson(original.toJson());
      expect(restored.type, equals(original.type));
      expect(restored.url, equals(original.url));
      expect(restored.filename, equals(original.filename));
      expect(restored.mimeType, equals(original.mimeType));
      expect(restored.size, equals(original.size));
    });
  });

  // ==========================================================================
  // ChannelEvent
  // ==========================================================================
  group('ChannelEvent', () {
    const channel = ChannelIdentity(platform: 'slack', channelId: 'C1');
    const conversation = ConversationKey(
      channel: channel,
      conversationId: 'thread-1',
    );

    test('constructs with required fields', () {
      final ts = DateTime.utc(2025, 6, 15, 10, 30);
      final event = ChannelEvent(
        id: 'evt-1',
        conversation: conversation,
        type: 'message',
        timestamp: ts,
      );
      expect(event.id, equals('evt-1'));
      expect(event.conversation, equals(conversation));
      expect(event.type, equals('message'));
      expect(event.timestamp, equals(ts));
      expect(event.text, isNull);
      expect(event.userId, isNull);
      expect(event.userName, isNull);
      expect(event.attachments, isNull);
      expect(event.metadata, isNull);
    });

    test('constructs with all fields', () {
      final ts = DateTime.utc(2025, 6, 15);
      final event = ChannelEvent(
        id: 'evt-2',
        conversation: conversation,
        type: 'message',
        text: 'Hello world',
        userId: 'U1',
        userName: 'Alice',
        timestamp: ts,
        attachments: const [
          ChannelAttachment(type: 'image', url: 'https://example.com/pic.png'),
        ],
        metadata: const {'thread_ts': '12345'},
      );
      expect(event.text, equals('Hello world'));
      expect(event.userId, equals('U1'));
      expect(event.userName, equals('Alice'));
      expect(event.attachments, hasLength(1));
      expect(event.metadata!['thread_ts'], equals('12345'));
    });

    test('message factory creates with type "message"', () {
      final event = ChannelEvent.message(
        id: 'msg-1',
        conversation: conversation,
        text: 'Hi there',
        userId: 'U5',
        userName: 'Bob',
      );
      expect(event.type, equals('message'));
      expect(event.text, equals('Hi there'));
      expect(event.userId, equals('U5'));
      expect(event.userName, equals('Bob'));
      expect(event.timestamp, isNotNull);
    });

    test('message factory uses provided timestamp', () {
      final ts = DateTime.utc(2025, 1, 1);
      final event = ChannelEvent.message(
        id: 'msg-2',
        conversation: conversation,
        text: 'test',
        timestamp: ts,
      );
      expect(event.timestamp, equals(ts));
    });

    test('message factory uses DateTime.now() when timestamp omitted', () {
      final before = DateTime.now();
      final event = ChannelEvent.message(
        id: 'msg-3',
        conversation: conversation,
        text: 'test',
      );
      final after = DateTime.now();
      // Timestamp should be between before and after
      expect(
        event.timestamp.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before.millisecondsSinceEpoch),
      );
      expect(
        event.timestamp.millisecondsSinceEpoch,
        lessThanOrEqualTo(after.millisecondsSinceEpoch),
      );
    });

    test('message factory supports attachments', () {
      final event = ChannelEvent.message(
        id: 'msg-4',
        conversation: conversation,
        text: 'See attached',
        attachments: const [
          ChannelAttachment(type: 'file', url: 'https://example.com/f.zip'),
        ],
      );
      expect(event.attachments, hasLength(1));
      expect(event.attachments!.first.type, equals('file'));
    });

    test('fromJson creates correct instance', () {
      final event = ChannelEvent.fromJson({
        'id': 'evt-10',
        'conversation': {
          'channel': {'platform': 'slack', 'channelId': 'C1'},
          'conversationId': 'thread-1',
        },
        'type': 'reaction',
        'text': '+1',
        'userId': 'U3',
        'userName': 'Charlie',
        'timestamp': '2025-06-15T12:00:00.000Z',
        'metadata': {'emoji': 'thumbsup'},
      });
      expect(event.id, equals('evt-10'));
      expect(event.type, equals('reaction'));
      expect(event.text, equals('+1'));
      expect(event.userId, equals('U3'));
      expect(event.userName, equals('Charlie'));
      expect(event.metadata!['emoji'], equals('thumbsup'));
    });

    test('fromJson parses attachments correctly', () {
      final event = ChannelEvent.fromJson({
        'id': 'evt-11',
        'conversation': {
          'channel': {'platform': 'telegram', 'channelId': 'T1'},
          'conversationId': 'dm-1',
        },
        'type': 'file',
        'timestamp': '2025-01-01T00:00:00.000Z',
        'attachments': [
          {
            'type': 'image',
            'url': 'https://example.com/photo.jpg',
            'filename': 'photo.jpg',
          },
          {
            'type': 'file',
            'url': 'https://example.com/doc.pdf',
          },
        ],
      });
      expect(event.attachments, hasLength(2));
      expect(event.attachments![0].filename, equals('photo.jpg'));
      expect(event.attachments![1].type, equals('file'));
    });

    test('toJson includes all present fields', () {
      final ts = DateTime.utc(2025, 3, 10, 8, 0);
      final event = ChannelEvent(
        id: 'evt-20',
        conversation: conversation,
        type: 'message',
        text: 'Hello',
        userId: 'U10',
        userName: 'Dave',
        timestamp: ts,
        attachments: const [
          ChannelAttachment(type: 'image', url: 'https://example.com/i.png'),
        ],
        metadata: const {'custom': 'data'},
      );
      final json = event.toJson();
      expect(json['id'], equals('evt-20'));
      expect(json['type'], equals('message'));
      expect(json['text'], equals('Hello'));
      expect(json['userId'], equals('U10'));
      expect(json['userName'], equals('Dave'));
      expect(json['timestamp'], equals('2025-03-10T08:00:00.000Z'));
      expect(json['attachments'], isA<List<dynamic>>());
      expect(json['metadata'], isA<Map<String, dynamic>>());
    });

    test('toJson omits null optional fields', () {
      final event = ChannelEvent(
        id: 'evt-21',
        conversation: conversation,
        type: 'ping',
        timestamp: DateTime.utc(2025, 1, 1),
      );
      final json = event.toJson();
      expect(json.containsKey('text'), isFalse);
      expect(json.containsKey('userId'), isFalse);
      expect(json.containsKey('userName'), isFalse);
      expect(json.containsKey('attachments'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final original = ChannelEvent(
        id: 'evt-roundtrip',
        conversation: conversation,
        type: 'message',
        text: 'Roundtrip test',
        userId: 'U99',
        userName: 'Eve',
        timestamp: DateTime.utc(2025, 7, 4, 12, 0),
        attachments: const [
          ChannelAttachment(
            type: 'file',
            url: 'https://example.com/file.txt',
            filename: 'file.txt',
            mimeType: 'text/plain',
            size: 256,
          ),
        ],
        metadata: const {'key': 'value'},
      );
      final restored = ChannelEvent.fromJson(original.toJson());
      expect(restored.id, equals(original.id));
      expect(restored.type, equals(original.type));
      expect(restored.text, equals(original.text));
      expect(restored.userId, equals(original.userId));
      expect(restored.userName, equals(original.userName));
      expect(restored.timestamp, equals(original.timestamp));
      expect(restored.attachments, hasLength(1));
      expect(restored.attachments!.first.filename, equals('file.txt'));
      expect(restored.metadata!['key'], equals('value'));
    });
  });

  // ==========================================================================
  // ChannelResponse
  // ==========================================================================
  group('ChannelResponse', () {
    const channel = ChannelIdentity(platform: 'slack', channelId: 'C1');
    const conversation = ConversationKey(
      channel: channel,
      conversationId: 'thread-1',
    );

    test('constructs with required fields', () {
      const response = ChannelResponse(
        conversation: conversation,
        type: 'text',
      );
      expect(response.conversation, equals(conversation));
      expect(response.type, equals('text'));
      expect(response.text, isNull);
      expect(response.blocks, isNull);
      expect(response.attachments, isNull);
      expect(response.replyTo, isNull);
      expect(response.options, isNull);
    });

    test('text factory creates text response', () {
      final response = ChannelResponse.text(
        conversation: conversation,
        text: 'Hello!',
      );
      expect(response.type, equals('text'));
      expect(response.text, equals('Hello!'));
      expect(response.blocks, isNull);
    });

    test('text factory supports replyTo and options', () {
      final response = ChannelResponse.text(
        conversation: conversation,
        text: 'Reply here',
        replyTo: 'msg-99',
        options: const {'ephemeral': true},
      );
      expect(response.replyTo, equals('msg-99'));
      expect(response.options!['ephemeral'], isTrue);
    });

    test('rich factory creates rich response with blocks', () {
      final response = ChannelResponse.rich(
        conversation: conversation,
        blocks: const [
          {'type': 'section', 'text': 'Block 1'},
          {'type': 'divider'},
        ],
        text: 'Fallback text',
      );
      expect(response.type, equals('rich'));
      expect(response.blocks, hasLength(2));
      expect(response.text, equals('Fallback text'));
    });

    test('rich factory supports replyTo and options', () {
      final response = ChannelResponse.rich(
        conversation: conversation,
        blocks: const [
          {'type': 'header', 'text': 'Title'},
        ],
        replyTo: 'msg-50',
        options: const {'unfurl_links': false},
      );
      expect(response.replyTo, equals('msg-50'));
      expect(response.options!['unfurl_links'], isFalse);
    });

    test('fromJson creates correct instance', () {
      final response = ChannelResponse.fromJson({
        'conversation': {
          'channel': {'platform': 'slack', 'channelId': 'C1'},
          'conversationId': 'thread-1',
        },
        'type': 'text',
        'text': 'Parsed message',
        'replyTo': 'msg-77',
        'options': {'markdown': true},
      });
      expect(response.type, equals('text'));
      expect(response.text, equals('Parsed message'));
      expect(response.replyTo, equals('msg-77'));
      expect(response.options!['markdown'], isTrue);
    });

    test('fromJson parses blocks correctly', () {
      final response = ChannelResponse.fromJson({
        'conversation': {
          'channel': {'platform': 'slack', 'channelId': 'C1'},
          'conversationId': 'thread-1',
        },
        'type': 'rich',
        'blocks': [
          {'type': 'section', 'text': 'Block content'},
        ],
      });
      expect(response.blocks, hasLength(1));
      expect(response.blocks!.first['type'], equals('section'));
    });

    test('fromJson parses attachments correctly', () {
      final response = ChannelResponse.fromJson({
        'conversation': {
          'channel': {'platform': 'telegram', 'channelId': 'T1'},
          'conversationId': 'dm-2',
        },
        'type': 'file',
        'attachments': [
          {'type': 'image', 'url': 'https://example.com/img.png'},
        ],
      });
      expect(response.attachments, hasLength(1));
      expect(response.attachments!.first.url,
          equals('https://example.com/img.png'));
    });

    test('toJson includes all fields when present', () {
      const response = ChannelResponse(
        conversation: conversation,
        type: 'rich',
        text: 'Fallback',
        blocks: [
          {'type': 'section'},
        ],
        attachments: [
          ChannelAttachment(type: 'file', url: 'https://example.com/f.bin'),
        ],
        replyTo: 'msg-1',
        options: {'opt': 'val'},
      );
      final json = response.toJson();
      expect(json['type'], equals('rich'));
      expect(json['text'], equals('Fallback'));
      expect(json['blocks'], isA<List<dynamic>>());
      expect(json['attachments'], isA<List<dynamic>>());
      expect(json['replyTo'], equals('msg-1'));
      expect(json['options'], isA<Map<String, dynamic>>());
    });

    test('toJson omits null optional fields', () {
      const response = ChannelResponse(
        conversation: conversation,
        type: 'text',
      );
      final json = response.toJson();
      expect(json.containsKey('text'), isFalse);
      expect(json.containsKey('blocks'), isFalse);
      expect(json.containsKey('attachments'), isFalse);
      expect(json.containsKey('replyTo'), isFalse);
      expect(json.containsKey('options'), isFalse);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      const original = ChannelResponse(
        conversation: conversation,
        type: 'rich',
        text: 'Roundtrip',
        blocks: [
          {'type': 'section', 'text': 'Test block'},
        ],
        attachments: [
          ChannelAttachment(
            type: 'image',
            url: 'https://example.com/img.png',
            filename: 'img.png',
          ),
        ],
        replyTo: 'msg-original',
        options: {'key': 'value'},
      );
      final restored = ChannelResponse.fromJson(original.toJson());
      expect(restored.type, equals(original.type));
      expect(restored.text, equals(original.text));
      expect(restored.blocks, hasLength(1));
      expect(restored.attachments, hasLength(1));
      expect(restored.replyTo, equals(original.replyTo));
      expect(restored.options!['key'], equals('value'));
    });
  });

  // ==========================================================================
  // ChannelCapabilities
  // ==========================================================================
  group('ChannelCapabilities', () {
    test('default constructor has text enabled only', () {
      const caps = ChannelCapabilities();
      expect(caps.text, isTrue);
      expect(caps.richMessages, isFalse);
      expect(caps.attachments, isFalse);
      expect(caps.reactions, isFalse);
      expect(caps.threads, isFalse);
      expect(caps.editing, isFalse);
      expect(caps.deleting, isFalse);
      expect(caps.typingIndicator, isFalse);
      expect(caps.maxMessageLength, isNull);
    });

    test('full factory enables all boolean capabilities', () {
      const caps = ChannelCapabilities.full();
      expect(caps.text, isTrue);
      expect(caps.richMessages, isTrue);
      expect(caps.attachments, isTrue);
      expect(caps.reactions, isTrue);
      expect(caps.threads, isTrue);
      expect(caps.editing, isTrue);
      expect(caps.deleting, isTrue);
      expect(caps.typingIndicator, isTrue);
      expect(caps.maxMessageLength, isNull);
    });

    test('textOnly factory enables text only', () {
      const caps = ChannelCapabilities.textOnly();
      expect(caps.text, isTrue);
      expect(caps.richMessages, isFalse);
      expect(caps.attachments, isFalse);
      expect(caps.reactions, isFalse);
      expect(caps.threads, isFalse);
      expect(caps.editing, isFalse);
      expect(caps.deleting, isFalse);
      expect(caps.typingIndicator, isFalse);
      expect(caps.maxMessageLength, isNull);
    });

    test('constructor allows custom configuration', () {
      const caps = ChannelCapabilities(
        text: true,
        richMessages: true,
        attachments: true,
        reactions: false,
        threads: true,
        editing: false,
        deleting: false,
        typingIndicator: true,
        maxMessageLength: 4000,
      );
      expect(caps.richMessages, isTrue);
      expect(caps.attachments, isTrue);
      expect(caps.reactions, isFalse);
      expect(caps.threads, isTrue);
      expect(caps.maxMessageLength, equals(4000));
    });

    test('fromJson creates correct instance', () {
      final caps = ChannelCapabilities.fromJson({
        'text': true,
        'richMessages': true,
        'attachments': false,
        'reactions': true,
        'threads': false,
        'editing': true,
        'deleting': false,
        'typingIndicator': true,
        'maxMessageLength': 2000,
      });
      expect(caps.text, isTrue);
      expect(caps.richMessages, isTrue);
      expect(caps.attachments, isFalse);
      expect(caps.reactions, isTrue);
      expect(caps.threads, isFalse);
      expect(caps.editing, isTrue);
      expect(caps.deleting, isFalse);
      expect(caps.typingIndicator, isTrue);
      expect(caps.maxMessageLength, equals(2000));
    });

    test('fromJson uses defaults for missing fields', () {
      final caps = ChannelCapabilities.fromJson({});
      expect(caps.text, isTrue);
      expect(caps.richMessages, isFalse);
      expect(caps.attachments, isFalse);
      expect(caps.maxMessageLength, isNull);
    });

    test('toJson includes all boolean fields', () {
      const caps = ChannelCapabilities.full();
      final json = caps.toJson();
      expect(json['text'], isTrue);
      expect(json['richMessages'], isTrue);
      expect(json['attachments'], isTrue);
      expect(json['reactions'], isTrue);
      expect(json['threads'], isTrue);
      expect(json['editing'], isTrue);
      expect(json['deleting'], isTrue);
      expect(json['typingIndicator'], isTrue);
    });

    test('toJson omits null maxMessageLength', () {
      const caps = ChannelCapabilities();
      final json = caps.toJson();
      expect(json.containsKey('maxMessageLength'), isFalse);
    });

    test('toJson includes maxMessageLength when set', () {
      const caps = ChannelCapabilities(maxMessageLength: 5000);
      final json = caps.toJson();
      expect(json['maxMessageLength'], equals(5000));
    });

    test('fromJson/toJson roundtrip preserves data', () {
      const original = ChannelCapabilities(
        text: true,
        richMessages: true,
        attachments: false,
        reactions: true,
        threads: true,
        editing: false,
        deleting: true,
        typingIndicator: false,
        maxMessageLength: 3000,
      );
      final restored = ChannelCapabilities.fromJson(original.toJson());
      expect(restored.text, equals(original.text));
      expect(restored.richMessages, equals(original.richMessages));
      expect(restored.attachments, equals(original.attachments));
      expect(restored.reactions, equals(original.reactions));
      expect(restored.threads, equals(original.threads));
      expect(restored.editing, equals(original.editing));
      expect(restored.deleting, equals(original.deleting));
      expect(restored.typingIndicator, equals(original.typingIndicator));
      expect(restored.maxMessageLength, equals(original.maxMessageLength));
    });
  });

  // ==========================================================================
  // StubChannelPort
  // ==========================================================================
  group('StubChannelPort', () {
    test('identity is stub:test', () {
      final port = StubChannelPort();
      expect(port.identity.platform, equals('stub'));
      expect(port.identity.channelId, equals('test'));
    });

    test('capabilities is textOnly', () {
      final port = StubChannelPort();
      expect(port.capabilities.text, isTrue);
      expect(port.capabilities.richMessages, isFalse);
      expect(port.capabilities.attachments, isFalse);
    });

    test('start completes without error', () async {
      final port = StubChannelPort();
      await expectLater(port.start(), completes);
    });

    test('stop completes without error', () async {
      final port = StubChannelPort();
      await expectLater(port.stop(), completes);
    });

    test('send records responses', () async {
      final port = StubChannelPort();
      const channel = ChannelIdentity(platform: 'stub', channelId: 'test');
      const conv =
          ConversationKey(channel: channel, conversationId: 'conv-1');
      final response = ChannelResponse.text(
        conversation: conv,
        text: 'Hello',
      );

      await port.send(response);
      expect(port.sentResponses, hasLength(1));
      expect(port.sentResponses.first.text, equals('Hello'));
    });

    test('send accumulates multiple responses', () async {
      final port = StubChannelPort();
      const channel = ChannelIdentity(platform: 'stub', channelId: 'test');
      const conv =
          ConversationKey(channel: channel, conversationId: 'conv-1');

      await port.send(ChannelResponse.text(
        conversation: conv,
        text: 'First',
      ));
      await port.send(ChannelResponse.text(
        conversation: conv,
        text: 'Second',
      ));
      await port.send(ChannelResponse.text(
        conversation: conv,
        text: 'Third',
      ));

      expect(port.sentResponses, hasLength(3));
      expect(port.sentResponses[0].text, equals('First'));
      expect(port.sentResponses[1].text, equals('Second'));
      expect(port.sentResponses[2].text, equals('Third'));
    });

    test('simulateEvent emits on events stream', () async {
      final port = StubChannelPort();
      const channel = ChannelIdentity(platform: 'stub', channelId: 'test');
      const conv =
          ConversationKey(channel: channel, conversationId: 'conv-1');

      final events = <ChannelEvent>[];
      final sub = port.events.listen(events.add);

      port.simulateEvent(ChannelEvent.message(
        id: 'sim-1',
        conversation: conv,
        text: 'Simulated',
        timestamp: DateTime.utc(2025, 1, 1),
      ));

      // Allow stream to deliver
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events, hasLength(1));
      expect(events.first.text, equals('Simulated'));

      await sub.cancel();
      await port.stop();
    });

    test('sendTyping completes without error', () async {
      final port = StubChannelPort();
      const channel = ChannelIdentity(platform: 'stub', channelId: 'test');
      const conv =
          ConversationKey(channel: channel, conversationId: 'conv-1');
      await expectLater(port.sendTyping(conv), completes);
    });

    test('edit throws UnsupportedError', () {
      final port = StubChannelPort();
      const channel = ChannelIdentity(platform: 'stub', channelId: 'test');
      const conv =
          ConversationKey(channel: channel, conversationId: 'conv-1');
      expect(
        () => port.edit(
          'msg-1',
          ChannelResponse.text(conversation: conv, text: 'edited'),
        ),
        throwsUnsupportedError,
      );
    });

    test('delete throws UnsupportedError', () {
      final port = StubChannelPort();
      expect(
        () => port.delete('msg-1'),
        throwsUnsupportedError,
      );
    });

    test('react throws UnsupportedError', () {
      final port = StubChannelPort();
      expect(
        () => port.react('msg-1', 'thumbsup'),
        throwsUnsupportedError,
      );
    });
  });

  // ==========================================================================
  // EchoChannelPort
  // ==========================================================================
  group('EchoChannelPort', () {
    test('identity is echo:echo', () {
      final port = EchoChannelPort();
      expect(port.identity.platform, equals('echo'));
      expect(port.identity.channelId, equals('echo'));
    });

    test('capabilities is textOnly', () {
      final port = EchoChannelPort();
      expect(port.capabilities.text, isTrue);
      expect(port.capabilities.richMessages, isFalse);
    });

    test('start completes without error', () async {
      final port = EchoChannelPort();
      await expectLater(port.start(), completes);
    });

    test('stop completes without error', () async {
      final port = EchoChannelPort();
      await expectLater(port.stop(), completes);
    });

    test('send echoes back the text as event', () async {
      final port = EchoChannelPort();
      const channel = ChannelIdentity(platform: 'echo', channelId: 'echo');
      const conv =
          ConversationKey(channel: channel, conversationId: 'conv-1');

      final events = <ChannelEvent>[];
      final sub = port.events.listen(events.add);

      await port.send(ChannelResponse.text(
        conversation: conv,
        text: 'Hello',
      ));

      // Allow stream to deliver
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events, hasLength(1));
      expect(events.first.text, equals('Echo: Hello'));
      expect(events.first.type, equals('message'));
      expect(events.first.id, startsWith('echo-'));

      await sub.cancel();
      await port.stop();
    });

    test('send echoes "[no text]" when text is null', () async {
      final port = EchoChannelPort();
      const channel = ChannelIdentity(platform: 'echo', channelId: 'echo');
      const conv =
          ConversationKey(channel: channel, conversationId: 'conv-1');

      final events = <ChannelEvent>[];
      final sub = port.events.listen(events.add);

      await port.send(const ChannelResponse(
        conversation: conv,
        type: 'file',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events, hasLength(1));
      expect(events.first.text, equals('Echo: [no text]'));

      await sub.cancel();
      await port.stop();
    });

    test('sendTyping completes without error', () async {
      final port = EchoChannelPort();
      const channel = ChannelIdentity(platform: 'echo', channelId: 'echo');
      const conv =
          ConversationKey(channel: channel, conversationId: 'conv-1');
      await expectLater(port.sendTyping(conv), completes);
    });

    test('edit throws UnsupportedError', () {
      final port = EchoChannelPort();
      const channel = ChannelIdentity(platform: 'echo', channelId: 'echo');
      const conv =
          ConversationKey(channel: channel, conversationId: 'conv-1');
      expect(
        () => port.edit(
          'msg-1',
          ChannelResponse.text(conversation: conv, text: 'edited'),
        ),
        throwsUnsupportedError,
      );
    });

    test('delete throws UnsupportedError', () {
      final port = EchoChannelPort();
      expect(
        () => port.delete('msg-1'),
        throwsUnsupportedError,
      );
    });

    test('react throws UnsupportedError', () {
      final port = EchoChannelPort();
      expect(
        () => port.react('msg-1', 'thumbsup'),
        throwsUnsupportedError,
      );
    });
  });
}
