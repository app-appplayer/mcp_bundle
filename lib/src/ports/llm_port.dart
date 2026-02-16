/// LLM Port - Unified interface for LLM operations.
///
/// Provides abstract contracts for LLM operations that can be implemented
/// by various LLM providers (Claude, OpenAI, etc.) and used across all
/// MCP knowledge packages.
library;

import 'dart:convert';

/// LLM capabilities configuration.
class LlmCapabilities {
  /// Whether completion is supported (always true).
  final bool completion;

  /// Whether streaming completion is supported.
  final bool streaming;

  /// Whether text embeddings are supported.
  final bool embedding;

  /// Whether tool/function calling is supported.
  final bool toolCalling;

  /// Whether vision (image input) is supported.
  final bool vision;

  /// Whether audio input is supported.
  final bool audio;

  /// Maximum context window size in tokens.
  final int? maxContextTokens;

  /// Maximum output tokens per request.
  final int? maxOutputTokens;

  const LlmCapabilities({
    this.completion = true,
    this.streaming = false,
    this.embedding = false,
    this.toolCalling = false,
    this.vision = false,
    this.audio = false,
    this.maxContextTokens,
    this.maxOutputTokens,
  });

  /// Full-featured capability set.
  const LlmCapabilities.full()
      : completion = true,
        streaming = true,
        embedding = true,
        toolCalling = true,
        vision = false,
        audio = false,
        maxContextTokens = null,
        maxOutputTokens = null;

  /// Minimal capability set (completion only).
  const LlmCapabilities.minimal()
      : completion = true,
        streaming = false,
        embedding = false,
        toolCalling = false,
        vision = false,
        audio = false,
        maxContextTokens = null,
        maxOutputTokens = null;

  /// Create from JSON.
  factory LlmCapabilities.fromJson(Map<String, dynamic> json) {
    return LlmCapabilities(
      completion: json['completion'] as bool? ?? true,
      streaming: json['streaming'] as bool? ?? false,
      embedding: json['embedding'] as bool? ?? false,
      toolCalling: json['toolCalling'] as bool? ?? false,
      vision: json['vision'] as bool? ?? false,
      audio: json['audio'] as bool? ?? false,
      maxContextTokens: json['maxContextTokens'] as int?,
      maxOutputTokens: json['maxOutputTokens'] as int?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'completion': completion,
        'streaming': streaming,
        'embedding': embedding,
        'toolCalling': toolCalling,
        'vision': vision,
        'audio': audio,
        if (maxContextTokens != null) 'maxContextTokens': maxContextTokens,
        if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
      };
}

/// LLM message for multi-turn conversations.
class LlmMessage {
  /// Message role: "user", "assistant", "system", "tool".
  final String role;

  /// Message content.
  final String content;

  /// Tool calls made by assistant.
  final List<LlmToolCall>? toolCalls;

  /// Tool call ID for tool responses.
  final String? toolCallId;

  const LlmMessage({
    required this.role,
    required this.content,
    this.toolCalls,
    this.toolCallId,
  });

  /// Create a user message.
  factory LlmMessage.user(String content) {
    return LlmMessage(role: 'user', content: content);
  }

  /// Create an assistant message.
  factory LlmMessage.assistant(String content, {List<LlmToolCall>? toolCalls}) {
    return LlmMessage(role: 'assistant', content: content, toolCalls: toolCalls);
  }

  /// Create a system message.
  factory LlmMessage.system(String content) {
    return LlmMessage(role: 'system', content: content);
  }

  /// Create a tool response message.
  factory LlmMessage.tool(String toolCallId, String content) {
    return LlmMessage(role: 'tool', content: content, toolCallId: toolCallId);
  }

  /// Create from JSON.
  factory LlmMessage.fromJson(Map<String, dynamic> json) {
    return LlmMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      toolCalls: (json['toolCalls'] as List<dynamic>?)
          ?.map((e) => LlmToolCall.fromJson(e as Map<String, dynamic>))
          .toList(),
      toolCallId: json['toolCallId'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        if (toolCalls != null)
          'toolCalls': toolCalls!.map((t) => t.toJson()).toList(),
        if (toolCallId != null) 'toolCallId': toolCallId,
      };
}

/// LLM request.
///
/// Supports two patterns:
/// - Simple: Use `prompt` for single-turn completion
/// - Conversation: Use `messages` for multi-turn conversations
class LlmRequest {
  /// User prompt (for simple single-turn requests).
  final String? prompt;

  /// Messages in the conversation (for multi-turn requests).
  final List<LlmMessage>? messages;

  /// System prompt.
  final String? systemPrompt;

  /// Model identifier.
  final String? model;

  /// Sampling temperature (0.0-2.0).
  final double? temperature;

  /// Maximum tokens to generate.
  final int? maxTokens;

  /// Response format (text, json).
  final String? responseFormat;

  /// Tools available for the LLM.
  final List<LlmTool>? tools;

  /// Additional options.
  final Map<String, dynamic>? options;

  const LlmRequest({
    this.prompt,
    this.messages,
    this.systemPrompt,
    this.model,
    this.temperature,
    this.maxTokens,
    this.responseFormat,
    this.tools,
    this.options,
  }) : assert(prompt != null || messages != null,
            'Either prompt or messages must be provided');

  /// Create a simple request with a single prompt.
  factory LlmRequest.simple(String prompt, {String? systemPrompt}) {
    return LlmRequest(prompt: prompt, systemPrompt: systemPrompt);
  }

  /// Create a conversation request with messages.
  factory LlmRequest.conversation(
    List<LlmMessage> messages, {
    String? systemPrompt,
    int? maxTokens,
    double? temperature,
    List<LlmTool>? tools,
  }) {
    return LlmRequest(
      messages: messages,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      temperature: temperature,
      tools: tools,
    );
  }

  /// Get effective messages (converts prompt to message if needed).
  List<LlmMessage> get effectiveMessages {
    if (messages != null) return messages!;
    return [LlmMessage.user(prompt!)];
  }

  /// Get effective prompt (first user message content if using messages).
  String get effectivePrompt {
    if (prompt != null) return prompt!;
    final userMsg = messages!.firstWhere(
      (m) => m.role == 'user',
      orElse: () => messages!.first,
    );
    return userMsg.content;
  }

  /// Create from JSON.
  factory LlmRequest.fromJson(Map<String, dynamic> json) {
    return LlmRequest(
      prompt: json['prompt'] as String?,
      messages: (json['messages'] as List<dynamic>?)
          ?.map((e) => LlmMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      systemPrompt: json['systemPrompt'] as String?,
      model: json['model'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      maxTokens: json['maxTokens'] as int?,
      responseFormat: json['responseFormat'] as String?,
      tools: (json['tools'] as List<dynamic>?)
          ?.map((e) => LlmTool.fromJson(e as Map<String, dynamic>))
          .toList(),
      options: json['options'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        if (prompt != null) 'prompt': prompt,
        if (messages != null)
          'messages': messages!.map((m) => m.toJson()).toList(),
        if (systemPrompt != null) 'systemPrompt': systemPrompt,
        if (model != null) 'model': model,
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'maxTokens': maxTokens,
        if (responseFormat != null) 'responseFormat': responseFormat,
        if (tools != null) 'tools': tools!.map((t) => t.toJson()).toList(),
        if (options != null) 'options': options,
      };
}

/// LLM response.
class LlmResponse {
  /// Response content.
  final String content;

  /// Token usage.
  final LlmUsage? usage;

  /// Model used.
  final String? model;

  /// Finish reason (stop, length, tool_calls).
  final String? finishReason;

  /// Tool calls from the model.
  final List<LlmToolCall>? toolCalls;

  /// Response metadata.
  final Map<String, dynamic>? metadata;

  const LlmResponse({
    required this.content,
    this.usage,
    this.model,
    this.finishReason,
    this.toolCalls,
    this.metadata,
  });

  /// Whether the response contains tool calls.
  bool get hasToolCalls => toolCalls != null && toolCalls!.isNotEmpty;

  /// Alias for finishReason for compatibility.
  String? get stopReason => finishReason;

  /// Create from JSON.
  factory LlmResponse.fromJson(Map<String, dynamic> json) {
    return LlmResponse(
      content: json['content'] as String,
      usage: json['usage'] != null
          ? LlmUsage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
      model: json['model'] as String?,
      finishReason:
          json['finishReason'] as String? ?? json['stopReason'] as String?,
      toolCalls: (json['toolCalls'] as List<dynamic>?)
          ?.map((e) => LlmToolCall.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'content': content,
        if (usage != null) 'usage': usage!.toJson(),
        if (model != null) 'model': model,
        if (finishReason != null) 'finishReason': finishReason,
        if (toolCalls != null)
          'toolCalls': toolCalls!.map((t) => t.toJson()).toList(),
        if (metadata != null) 'metadata': metadata,
      };
}

/// Token usage information.
class LlmUsage {
  /// Input/prompt tokens.
  final int inputTokens;

  /// Output/completion tokens.
  final int outputTokens;

  const LlmUsage({
    required this.inputTokens,
    required this.outputTokens,
  });

  /// Total tokens.
  int get totalTokens => inputTokens + outputTokens;

  /// Create from JSON.
  factory LlmUsage.fromJson(Map<String, dynamic> json) {
    return LlmUsage(
      inputTokens:
          json['inputTokens'] as int? ?? json['promptTokens'] as int? ?? 0,
      outputTokens: json['outputTokens'] as int? ??
          json['completionTokens'] as int? ??
          0,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
      };
}

/// Streaming chunk.
class LlmChunk {
  /// Content delta.
  final String? content;

  /// Whether this is the final chunk.
  final bool isDone;

  /// Tool call in progress.
  final LlmToolCall? toolCall;

  /// Final usage (only in last chunk).
  final LlmUsage? usage;

  /// Index in the stream.
  final int? index;

  const LlmChunk({
    this.content,
    this.isDone = false,
    this.toolCall,
    this.usage,
    this.index,
  });

  /// Create from JSON.
  factory LlmChunk.fromJson(Map<String, dynamic> json) {
    return LlmChunk(
      content: json['content'] as String?,
      isDone: json['isDone'] as bool? ?? false,
      toolCall: json['toolCall'] != null
          ? LlmToolCall.fromJson(json['toolCall'] as Map<String, dynamic>)
          : null,
      usage: json['usage'] != null
          ? LlmUsage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
      index: json['index'] as int?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        if (content != null) 'content': content,
        'isDone': isDone,
        if (toolCall != null) 'toolCall': toolCall!.toJson(),
        if (usage != null) 'usage': usage!.toJson(),
        if (index != null) 'index': index,
      };
}

/// Tool definition for function calling.
class LlmTool {
  /// Tool name.
  final String name;

  /// Tool description.
  final String description;

  /// JSON Schema for parameters.
  final Map<String, dynamic> parameters;

  const LlmTool({
    required this.name,
    required this.description,
    required this.parameters,
  });

  /// Alias for parameters (for compatibility with inputSchema naming).
  Map<String, dynamic> get inputSchema => parameters;

  /// Create from JSON (supports both 'parameters' and 'inputSchema').
  factory LlmTool.fromJson(Map<String, dynamic> json) {
    return LlmTool(
      name: json['name'] as String,
      description: json['description'] as String,
      parameters: json['parameters'] as Map<String, dynamic>? ??
          json['inputSchema'] as Map<String, dynamic>,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'parameters': parameters,
      };
}

/// Tool call from LLM.
class LlmToolCall {
  /// Unique call ID.
  final String id;

  /// Tool name.
  final String name;

  /// Parsed arguments.
  final Map<String, dynamic> arguments;

  const LlmToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  /// Create from JSON.
  factory LlmToolCall.fromJson(Map<String, dynamic> json) {
    return LlmToolCall(
      id: json['id'] as String,
      name: json['name'] as String,
      arguments: json['arguments'] is String
          ? _parseJson(json['arguments'] as String)
          : json['arguments'] as Map<String, dynamic>,
    );
  }

  static Map<String, dynamic> _parseJson(String s) {
    try {
      return Map<String, dynamic>.from(
        const JsonDecoder().convert(s) as Map,
      );
    } catch (_) {
      return {};
    }
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'arguments': arguments,
      };
}

/// Abstract LLM Port interface.
abstract class LlmPort {
  /// Runtime capabilities of this LLM implementation.
  LlmCapabilities get capabilities;

  /// Check if the LLM is available.
  Future<bool> isAvailable() async => true;

  /// Check if a specific capability is supported.
  bool hasCapability(String capability) {
    switch (capability) {
      case 'completion':
        return capabilities.completion;
      case 'streaming':
        return capabilities.streaming;
      case 'embedding':
        return capabilities.embedding;
      case 'toolCalling':
        return capabilities.toolCalling;
      case 'vision':
        return capabilities.vision;
      case 'audio':
        return capabilities.audio;
      default:
        return false;
    }
  }

  /// Complete a request (required).
  Future<LlmResponse> complete(LlmRequest request);

  /// Streaming completion (optional - check capabilities.streaming).
  Stream<LlmChunk> completeStream(LlmRequest request) {
    throw UnsupportedError('Streaming not supported by this LLM');
  }

  /// Generate text embeddings (optional - check capabilities.embedding).
  Future<List<double>> embed(String text) {
    throw UnsupportedError('Embedding not supported by this LLM');
  }

  /// Batch embeddings for efficiency.
  Future<List<List<double>>> embedBatch(List<String> texts) async {
    return Future.wait(texts.map(embed));
  }

  /// Compute semantic similarity using embeddings.
  Future<double> similarity(String text1, String text2) async {
    final emb1 = await embed(text1);
    final emb2 = await embed(text2);
    return cosineSimilarity(emb1, emb2);
  }

  /// Complete with tool calling (optional - check capabilities.toolCalling).
  Future<LlmResponse> completeWithTools(
    LlmRequest request,
    List<LlmTool> tools,
  ) {
    throw UnsupportedError('Tool calling not supported by this LLM');
  }
}

/// Cosine similarity helper.
double cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length || a.isEmpty) return 0.0;

  double dot = 0.0, normA = 0.0, normB = 0.0;
  for (int i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  if (normA == 0.0 || normB == 0.0) return 0.0;
  return dot / (_sqrt(normA) * _sqrt(normB));
}

double _sqrt(double x) {
  if (x <= 0) return 0;
  double g = x / 2;
  for (int i = 0; i < 20; i++) {
    g = (g + x / g) / 2;
  }
  return g;
}

/// Stub LLM port for testing.
class StubLlmPort extends LlmPort {
  @override
  LlmCapabilities get capabilities => const LlmCapabilities.minimal();

  @override
  Future<LlmResponse> complete(LlmRequest request) async {
    return const LlmResponse(content: '');
  }

  @override
  Future<List<double>> embed(String text) async {
    return List.filled(384, 0.0);
  }

  @override
  Future<double> similarity(String text1, String text2) async {
    return 0.0;
  }
}

/// Empty LLM port that throws on use.
class EmptyLlmPort extends LlmPort {
  @override
  LlmCapabilities get capabilities => const LlmCapabilities.minimal();

  @override
  Future<LlmResponse> complete(LlmRequest request) {
    throw UnimplementedError('LlmPort not configured');
  }
}
