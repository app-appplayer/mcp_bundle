/// Channel Port - Universal bidirectional communication interface.
///
/// This port provides a unified interface for channel communication
/// across the MCP ecosystem:
/// - mcp_channel: Slack, Telegram, Discord connectors
/// - mcp_server: HTTP, WebSocket, stdio transport
/// - mcp_client: HTTP, WebSocket transport
/// - mcp_knowledge: Store/retrieve channel events
library;

import 'dart:async';

// ============================================================================
// Channel Identity
// ============================================================================

/// Identifies a channel platform (e.g., 'slack', 'telegram', 'http', 'websocket').
class ChannelIdentity {
  /// Platform identifier.
  final String platform;

  /// Channel-specific identifier (e.g., workspace ID, server ID).
  final String channelId;

  /// Optional display name.
  final String? displayName;

  const ChannelIdentity({
    required this.platform,
    required this.channelId,
    this.displayName,
  });

  /// Create from JSON.
  factory ChannelIdentity.fromJson(Map<String, dynamic> json) {
    return ChannelIdentity(
      platform: json['platform'] as String,
      channelId: json['channelId'] as String,
      displayName: json['displayName'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'platform': platform,
        'channelId': channelId,
        if (displayName != null) 'displayName': displayName,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelIdentity &&
          platform == other.platform &&
          channelId == other.channelId;

  @override
  int get hashCode => Object.hash(platform, channelId);

  @override
  String toString() => 'ChannelIdentity($platform:$channelId)';
}

// ============================================================================
// Conversation Key
// ============================================================================

/// Unique key for a conversation within a channel.
class ConversationKey {
  /// Channel identity.
  final ChannelIdentity channel;

  /// Conversation-specific identifier (e.g., thread ID, DM ID).
  final String conversationId;

  /// Optional user identifier.
  final String? userId;

  const ConversationKey({
    required this.channel,
    required this.conversationId,
    this.userId,
  });

  /// Create from JSON.
  factory ConversationKey.fromJson(Map<String, dynamic> json) {
    return ConversationKey(
      channel:
          ChannelIdentity.fromJson(json['channel'] as Map<String, dynamic>),
      conversationId: json['conversationId'] as String,
      userId: json['userId'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'channel': channel.toJson(),
        'conversationId': conversationId,
        if (userId != null) 'userId': userId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationKey &&
          channel == other.channel &&
          conversationId == other.conversationId;

  @override
  int get hashCode => Object.hash(channel, conversationId);

  @override
  String toString() =>
      'ConversationKey(${channel.platform}:$conversationId)';
}

// ============================================================================
// Channel Attachment
// ============================================================================

/// Attachment in a channel event.
class ChannelAttachment {
  /// Attachment type (image, file, audio, video).
  final String type;

  /// URL or path to the attachment.
  final String url;

  /// Original filename.
  final String? filename;

  /// MIME type.
  final String? mimeType;

  /// File size in bytes.
  final int? size;

  const ChannelAttachment({
    required this.type,
    required this.url,
    this.filename,
    this.mimeType,
    this.size,
  });

  /// Create from JSON.
  factory ChannelAttachment.fromJson(Map<String, dynamic> json) {
    return ChannelAttachment(
      type: json['type'] as String,
      url: json['url'] as String,
      filename: json['filename'] as String?,
      mimeType: json['mimeType'] as String?,
      size: json['size'] as int?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'type': type,
        'url': url,
        if (filename != null) 'filename': filename,
        if (mimeType != null) 'mimeType': mimeType,
        if (size != null) 'size': size,
      };
}

// ============================================================================
// Channel Event
// ============================================================================

/// Event received from a channel.
class ChannelEvent {
  /// Unique event ID (for idempotency).
  final String id;

  /// Conversation this event belongs to.
  final ConversationKey conversation;

  /// Event type (message, reaction, file, etc.).
  final String type;

  /// Text content (if applicable).
  final String? text;

  /// User who triggered the event.
  final String? userId;

  /// User display name.
  final String? userName;

  /// Event timestamp.
  final DateTime timestamp;

  /// Attached files or media.
  final List<ChannelAttachment>? attachments;

  /// Platform-specific metadata.
  final Map<String, dynamic>? metadata;

  const ChannelEvent({
    required this.id,
    required this.conversation,
    required this.type,
    this.text,
    this.userId,
    this.userName,
    required this.timestamp,
    this.attachments,
    this.metadata,
  });

  /// Create a message event.
  factory ChannelEvent.message({
    required String id,
    required ConversationKey conversation,
    required String text,
    String? userId,
    String? userName,
    DateTime? timestamp,
    List<ChannelAttachment>? attachments,
    Map<String, dynamic>? metadata,
  }) {
    return ChannelEvent(
      id: id,
      conversation: conversation,
      type: 'message',
      text: text,
      userId: userId,
      userName: userName,
      timestamp: timestamp ?? DateTime.now(),
      attachments: attachments,
      metadata: metadata,
    );
  }

  /// Create from JSON.
  factory ChannelEvent.fromJson(Map<String, dynamic> json) {
    return ChannelEvent(
      id: json['id'] as String,
      conversation:
          ConversationKey.fromJson(json['conversation'] as Map<String, dynamic>),
      type: json['type'] as String,
      text: json['text'] as String?,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => ChannelAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation': conversation.toJson(),
        'type': type,
        if (text != null) 'text': text,
        if (userId != null) 'userId': userId,
        if (userName != null) 'userName': userName,
        'timestamp': timestamp.toIso8601String(),
        if (attachments != null)
          'attachments': attachments!.map((a) => a.toJson()).toList(),
        if (metadata != null) 'metadata': metadata,
      };
}

// ============================================================================
// Channel Response
// ============================================================================

/// Response to send to a channel.
class ChannelResponse {
  /// Target conversation.
  final ConversationKey conversation;

  /// Response type (text, rich, file, etc.).
  final String type;

  /// Text content.
  final String? text;

  /// Rich content blocks (for platforms that support them).
  final List<Map<String, dynamic>>? blocks;

  /// Attachments to send.
  final List<ChannelAttachment>? attachments;

  /// Reply to a specific message ID.
  final String? replyTo;

  /// Platform-specific options.
  final Map<String, dynamic>? options;

  const ChannelResponse({
    required this.conversation,
    required this.type,
    this.text,
    this.blocks,
    this.attachments,
    this.replyTo,
    this.options,
  });

  /// Create a text response.
  factory ChannelResponse.text({
    required ConversationKey conversation,
    required String text,
    String? replyTo,
    Map<String, dynamic>? options,
  }) {
    return ChannelResponse(
      conversation: conversation,
      type: 'text',
      text: text,
      replyTo: replyTo,
      options: options,
    );
  }

  /// Create a rich response with blocks.
  factory ChannelResponse.rich({
    required ConversationKey conversation,
    required List<Map<String, dynamic>> blocks,
    String? text,
    String? replyTo,
    Map<String, dynamic>? options,
  }) {
    return ChannelResponse(
      conversation: conversation,
      type: 'rich',
      text: text,
      blocks: blocks,
      replyTo: replyTo,
      options: options,
    );
  }

  /// Create from JSON.
  factory ChannelResponse.fromJson(Map<String, dynamic> json) {
    return ChannelResponse(
      conversation:
          ConversationKey.fromJson(json['conversation'] as Map<String, dynamic>),
      type: json['type'] as String,
      text: json['text'] as String?,
      blocks: (json['blocks'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => ChannelAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      replyTo: json['replyTo'] as String?,
      options: json['options'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'conversation': conversation.toJson(),
        'type': type,
        if (text != null) 'text': text,
        if (blocks != null) 'blocks': blocks,
        if (attachments != null)
          'attachments': attachments!.map((a) => a.toJson()).toList(),
        if (replyTo != null) 'replyTo': replyTo,
        if (options != null) 'options': options,
      };
}

// ============================================================================
// Channel Capabilities
// ============================================================================

/// Capabilities of a channel implementation.
class ChannelCapabilities {
  /// Whether text messages are supported.
  final bool text;

  /// Whether rich/block messages are supported.
  final bool richMessages;

  /// Whether file attachments are supported.
  final bool attachments;

  /// Whether reactions are supported.
  final bool reactions;

  /// Whether threads are supported.
  final bool threads;

  /// Whether editing sent messages is supported.
  final bool editing;

  /// Whether deleting sent messages is supported.
  final bool deleting;

  /// Whether typing indicators are supported.
  final bool typingIndicator;

  /// Maximum message length (null = unlimited).
  final int? maxMessageLength;

  const ChannelCapabilities({
    this.text = true,
    this.richMessages = false,
    this.attachments = false,
    this.reactions = false,
    this.threads = false,
    this.editing = false,
    this.deleting = false,
    this.typingIndicator = false,
    this.maxMessageLength,
  });

  /// Full-featured channel.
  const ChannelCapabilities.full()
      : text = true,
        richMessages = true,
        attachments = true,
        reactions = true,
        threads = true,
        editing = true,
        deleting = true,
        typingIndicator = true,
        maxMessageLength = null;

  /// Text-only channel.
  const ChannelCapabilities.textOnly()
      : text = true,
        richMessages = false,
        attachments = false,
        reactions = false,
        threads = false,
        editing = false,
        deleting = false,
        typingIndicator = false,
        maxMessageLength = null;

  /// Create from JSON.
  factory ChannelCapabilities.fromJson(Map<String, dynamic> json) {
    return ChannelCapabilities(
      text: json['text'] as bool? ?? true,
      richMessages: json['richMessages'] as bool? ?? false,
      attachments: json['attachments'] as bool? ?? false,
      reactions: json['reactions'] as bool? ?? false,
      threads: json['threads'] as bool? ?? false,
      editing: json['editing'] as bool? ?? false,
      deleting: json['deleting'] as bool? ?? false,
      typingIndicator: json['typingIndicator'] as bool? ?? false,
      maxMessageLength: json['maxMessageLength'] as int?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'text': text,
        'richMessages': richMessages,
        'attachments': attachments,
        'reactions': reactions,
        'threads': threads,
        'editing': editing,
        'deleting': deleting,
        'typingIndicator': typingIndicator,
        if (maxMessageLength != null) 'maxMessageLength': maxMessageLength,
      };
}

// ============================================================================
// Channel Port Interface
// ============================================================================

/// Abstract port for bidirectional channel communication.
///
/// Implementations:
/// - mcp_channel: SlackChannelPort, TelegramChannelPort, DiscordChannelPort
/// - mcp_server: HttpChannelPort, WebSocketChannelPort, StdioChannelPort
/// - mcp_client: HttpClientChannelPort, WebSocketClientChannelPort
abstract class ChannelPort {
  /// Channel identity.
  ChannelIdentity get identity;

  /// Capabilities of this channel.
  ChannelCapabilities get capabilities;

  /// Stream of incoming events.
  Stream<ChannelEvent> get events;

  /// Start receiving events.
  Future<void> start();

  /// Stop receiving events.
  Future<void> stop();

  /// Send a response to the channel.
  Future<void> send(ChannelResponse response);

  /// Send typing indicator (if supported).
  Future<void> sendTyping(ConversationKey conversation) async {
    // Default no-op; override if supported
  }

  /// Edit a previously sent message (if supported).
  Future<void> edit(String messageId, ChannelResponse response) {
    throw UnsupportedError('Editing not supported by this channel');
  }

  /// Delete a previously sent message (if supported).
  Future<void> delete(String messageId) {
    throw UnsupportedError('Deleting not supported by this channel');
  }

  /// Add a reaction to a message (if supported).
  Future<void> react(String messageId, String reaction) {
    throw UnsupportedError('Reactions not supported by this channel');
  }
}

// ============================================================================
// Stub Implementations
// ============================================================================

/// Stub channel port for testing.
class StubChannelPort implements ChannelPort {
  final _controller = StreamController<ChannelEvent>.broadcast();

  /// List of sent responses (for testing verification).
  final List<ChannelResponse> sentResponses = [];

  @override
  ChannelIdentity get identity => const ChannelIdentity(
        platform: 'stub',
        channelId: 'test',
      );

  @override
  ChannelCapabilities get capabilities => const ChannelCapabilities.textOnly();

  @override
  Stream<ChannelEvent> get events => _controller.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {
    await _controller.close();
  }

  @override
  Future<void> send(ChannelResponse response) async {
    sentResponses.add(response);
  }

  @override
  Future<void> sendTyping(ConversationKey conversation) async {}

  @override
  Future<void> edit(String messageId, ChannelResponse response) {
    throw UnsupportedError('Editing not supported by stub channel');
  }

  @override
  Future<void> delete(String messageId) {
    throw UnsupportedError('Deleting not supported by stub channel');
  }

  @override
  Future<void> react(String messageId, String reaction) {
    throw UnsupportedError('Reactions not supported by stub channel');
  }

  /// Simulate receiving an event (for testing).
  void simulateEvent(ChannelEvent event) {
    _controller.add(event);
  }
}

/// Echo channel port that echoes back messages.
class EchoChannelPort implements ChannelPort {
  final _controller = StreamController<ChannelEvent>.broadcast();

  @override
  ChannelIdentity get identity => const ChannelIdentity(
        platform: 'echo',
        channelId: 'echo',
      );

  @override
  ChannelCapabilities get capabilities => const ChannelCapabilities.textOnly();

  @override
  Stream<ChannelEvent> get events => _controller.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {
    await _controller.close();
  }

  @override
  Future<void> send(ChannelResponse response) async {
    _controller.add(ChannelEvent.message(
      id: 'echo-${DateTime.now().millisecondsSinceEpoch}',
      conversation: response.conversation,
      text: 'Echo: ${response.text ?? "[no text]"}',
    ));
  }

  @override
  Future<void> sendTyping(ConversationKey conversation) async {}

  @override
  Future<void> edit(String messageId, ChannelResponse response) {
    throw UnsupportedError('Editing not supported by echo channel');
  }

  @override
  Future<void> delete(String messageId) {
    throw UnsupportedError('Deleting not supported by echo channel');
  }

  @override
  Future<void> react(String messageId, String reaction) {
    throw UnsupportedError('Reactions not supported by echo channel');
  }
}
