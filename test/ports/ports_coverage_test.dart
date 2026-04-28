// Comprehensive port coverage tests for llm_port, metric_port, and event_port.

import 'dart:async';
import 'dart:convert';

// Hide IO `AssetNotFoundException` so the knowledge variant (from
// `knowledge_types.dart`) wins name resolution.
import 'package:mcp_bundle/mcp_bundle.dart' hide AssetNotFoundException;
import 'package:mcp_bundle/src/ports/llm_port.dart';
import 'package:mcp_bundle/src/ports/metric_port.dart';
import 'package:mcp_bundle/src/ports/event_port.dart';
import 'package:mcp_bundle/src/types/knowledge_types.dart';
import 'package:mcp_bundle/src/models/skill/skill_factgraph_types.dart'
    show SkillContextBundle;
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Concrete LlmPort subclass for testing abstract default methods.
// ---------------------------------------------------------------------------
class _TestLlmPort extends LlmPort {
  @override
  LlmCapabilities get capabilities => const LlmCapabilities.full();

  @override
  Future<LlmResponse> complete(LlmRequest request) async =>
      const LlmResponse(content: 'test');

  @override
  Future<List<double>> embed(String text) async => [0.1, 0.2, 0.3];
}

// Minimal port with no embedding / streaming support.
class _MinimalLlmPort extends LlmPort {
  @override
  LlmCapabilities get capabilities => const LlmCapabilities.minimal();

  @override
  Future<LlmResponse> complete(LlmRequest request) async =>
      const LlmResponse(content: 'minimal');
}

void main() {
  // =======================================================================
  // LLM PORT
  // =======================================================================
  group('LlmMessage', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'role': 'user',
        'content': 'Hello',
        'toolCalls': [
          {'id': 'tc1', 'name': 'fn', 'arguments': <String, dynamic>{'a': 1}}
        ],
        'toolCallId': 'tc0',
      };
      final msg = LlmMessage.fromJson(json);
      expect(msg.role, 'user');
      expect(msg.content, 'Hello');
      expect(msg.toolCalls, isNotNull);
      expect(msg.toolCalls!.first.id, 'tc1');
      expect(msg.toolCallId, 'tc0');

      final out = msg.toJson();
      expect(out['role'], 'user');
      expect(out['content'], 'Hello');
      expect(out['toolCalls'], isList);
      expect(out['toolCallId'], 'tc0');
    });

    test('fromJson / toJson without optional fields', () {
      final json = {'role': 'user', 'content': 'Hi'};
      final msg = LlmMessage.fromJson(json);
      expect(msg.toolCalls, isNull);
      expect(msg.toolCallId, isNull);

      final out = msg.toJson();
      expect(out.containsKey('toolCalls'), isFalse);
      expect(out.containsKey('toolCallId'), isFalse);
    });

    test('.user() factory', () {
      final msg = LlmMessage.user('question');
      expect(msg.role, 'user');
      expect(msg.content, 'question');
      expect(msg.toolCalls, isNull);
      expect(msg.toolCallId, isNull);
    });

    test('.assistant() factory', () {
      final tc = const LlmToolCall(id: 'c1', name: 'f', arguments: {});
      final msg = LlmMessage.assistant('answer', toolCalls: [tc]);
      expect(msg.role, 'assistant');
      expect(msg.content, 'answer');
      expect(msg.toolCalls, hasLength(1));
    });

    test('.assistant() factory without toolCalls', () {
      final msg = LlmMessage.assistant('answer');
      expect(msg.role, 'assistant');
      expect(msg.toolCalls, isNull);
    });

    test('.system() factory', () {
      final msg = LlmMessage.system('You are a bot.');
      expect(msg.role, 'system');
      expect(msg.content, 'You are a bot.');
    });

    test('.tool() factory', () {
      final msg = LlmMessage.tool('tc42', 'result-data');
      expect(msg.role, 'tool');
      expect(msg.content, 'result-data');
      expect(msg.toolCallId, 'tc42');
    });
  });

  group('LlmRequest', () {
    test('fromJson / toJson round-trip with all fields', () {
      final json = {
        'prompt': 'Say hi',
        'messages': [
          {'role': 'user', 'content': 'hi'}
        ],
        'systemPrompt': 'Be concise',
        'model': 'gpt-4',
        'temperature': 0.7,
        'maxTokens': 100,
        'responseFormat': 'json',
        'tools': [
          {
            'name': 'lookup',
            'description': 'Lookup data',
            'parameters': <String, dynamic>{'type': 'object'}
          }
        ],
        'options': <String, dynamic>{'topP': 0.9},
      };
      final req = LlmRequest.fromJson(json);
      expect(req.prompt, 'Say hi');
      expect(req.messages, hasLength(1));
      expect(req.systemPrompt, 'Be concise');
      expect(req.model, 'gpt-4');
      expect(req.temperature, 0.7);
      expect(req.maxTokens, 100);
      expect(req.responseFormat, 'json');
      expect(req.tools, hasLength(1));
      expect(req.options!['topP'], 0.9);

      final out = req.toJson();
      expect(out['prompt'], 'Say hi');
      expect(out['messages'], isList);
      expect(out['systemPrompt'], 'Be concise');
      expect(out['model'], 'gpt-4');
      expect(out['temperature'], 0.7);
      expect(out['maxTokens'], 100);
      expect(out['responseFormat'], 'json');
      expect(out['tools'], isList);
      expect(out['options'], isMap);
    });

    test('toJson omits null optional fields', () {
      final req = LlmRequest.simple('hello');
      final out = req.toJson();
      expect(out.containsKey('messages'), isFalse);
      expect(out.containsKey('systemPrompt'), isFalse);
      expect(out.containsKey('model'), isFalse);
      expect(out.containsKey('temperature'), isFalse);
      expect(out.containsKey('maxTokens'), isFalse);
      expect(out.containsKey('responseFormat'), isFalse);
      expect(out.containsKey('tools'), isFalse);
      expect(out.containsKey('options'), isFalse);
    });

    test('.simple() factory', () {
      final req = LlmRequest.simple('prompt text', systemPrompt: 'sys');
      expect(req.prompt, 'prompt text');
      expect(req.systemPrompt, 'sys');
      expect(req.messages, isNull);
    });

    test('.conversation() factory', () {
      final msgs = [LlmMessage.user('hi'), LlmMessage.assistant('hey')];
      final tools = [
        const LlmTool(
            name: 'fn',
            description: 'desc',
            parameters: <String, dynamic>{})
      ];
      final req = LlmRequest.conversation(
        msgs,
        systemPrompt: 'Be brief',
        maxTokens: 50,
        temperature: 0.3,
        tools: tools,
      );
      expect(req.messages, hasLength(2));
      expect(req.systemPrompt, 'Be brief');
      expect(req.maxTokens, 50);
      expect(req.temperature, 0.3);
      expect(req.tools, hasLength(1));
      expect(req.prompt, isNull);
    });

    test('effectiveMessages - from prompt', () {
      final req = LlmRequest.simple('hi');
      final msgs = req.effectiveMessages;
      expect(msgs, hasLength(1));
      expect(msgs.first.role, 'user');
      expect(msgs.first.content, 'hi');
    });

    test('effectiveMessages - from messages list', () {
      final req = LlmRequest.conversation(
          [LlmMessage.system('sys'), LlmMessage.user('q')]);
      expect(req.effectiveMessages, hasLength(2));
    });

    test('effectivePrompt - from prompt field', () {
      final req = LlmRequest.simple('hello world');
      expect(req.effectivePrompt, 'hello world');
    });

    test('effectivePrompt - from messages (finds first user message)', () {
      final req = LlmRequest.conversation([
        LlmMessage.system('system-msg'),
        LlmMessage.user('the question'),
      ]);
      expect(req.effectivePrompt, 'the question');
    });

    test('effectivePrompt - from messages (falls back to first message)', () {
      final req = LlmRequest.conversation([
        LlmMessage.system('only-system'),
      ]);
      expect(req.effectivePrompt, 'only-system');
    });
  });

  group('LlmResponse', () {
    test('fromJson / toJson round-trip with all fields', () {
      final json = {
        'content': 'Hello!',
        'usage': {'inputTokens': 10, 'outputTokens': 20},
        'model': 'claude-3',
        'finishReason': 'stop',
        'toolCalls': [
          {
            'id': 'tc1',
            'name': 'search',
            'arguments': <String, dynamic>{'q': 'dart'}
          }
        ],
        'metadata': <String, dynamic>{'latency': 120},
      };
      final resp = LlmResponse.fromJson(json);
      expect(resp.content, 'Hello!');
      expect(resp.usage!.inputTokens, 10);
      expect(resp.model, 'claude-3');
      expect(resp.finishReason, 'stop');
      expect(resp.toolCalls, hasLength(1));
      expect(resp.metadata!['latency'], 120);

      final out = resp.toJson();
      expect(out['content'], 'Hello!');
      expect(out['usage'], isMap);
      expect(out['model'], 'claude-3');
      expect(out['finishReason'], 'stop');
      expect(out['toolCalls'], isList);
      expect(out['metadata'], isMap);
    });

    test('fromJson reads stopReason as finishReason fallback', () {
      final resp = LlmResponse.fromJson({
        'content': 'hi',
        'stopReason': 'end_turn',
      });
      expect(resp.finishReason, 'end_turn');
      expect(resp.stopReason, 'end_turn');
    });

    test('toJson omits null optional fields', () {
      const resp = LlmResponse(content: 'hi');
      final out = resp.toJson();
      expect(out.containsKey('usage'), isFalse);
      expect(out.containsKey('model'), isFalse);
      expect(out.containsKey('finishReason'), isFalse);
      expect(out.containsKey('toolCalls'), isFalse);
      expect(out.containsKey('metadata'), isFalse);
    });

    test('hasToolCalls returns true when tool calls present', () {
      const resp = LlmResponse(
        content: '',
        toolCalls: [LlmToolCall(id: 'x', name: 'fn', arguments: {})],
      );
      expect(resp.hasToolCalls, isTrue);
    });

    test('hasToolCalls returns false when null', () {
      const resp = LlmResponse(content: '');
      expect(resp.hasToolCalls, isFalse);
    });

    test('hasToolCalls returns false when empty list', () {
      const resp = LlmResponse(content: '', toolCalls: []);
      expect(resp.hasToolCalls, isFalse);
    });

    test('stopReason alias returns finishReason', () {
      const resp = LlmResponse(content: '', finishReason: 'length');
      expect(resp.stopReason, 'length');
    });

    test('stopReason alias returns null when finishReason is null', () {
      const resp = LlmResponse(content: '');
      expect(resp.stopReason, isNull);
    });
  });

  group('LlmUsage', () {
    test('fromJson / toJson round-trip', () {
      final usage =
          LlmUsage.fromJson({'inputTokens': 5, 'outputTokens': 15});
      expect(usage.inputTokens, 5);
      expect(usage.outputTokens, 15);

      final out = usage.toJson();
      expect(out['inputTokens'], 5);
      expect(out['outputTokens'], 15);
    });

    test('fromJson supports promptTokens alias', () {
      final usage = LlmUsage.fromJson({'promptTokens': 8, 'outputTokens': 3});
      expect(usage.inputTokens, 8);
    });

    test('fromJson supports completionTokens alias', () {
      final usage =
          LlmUsage.fromJson({'inputTokens': 1, 'completionTokens': 9});
      expect(usage.outputTokens, 9);
    });

    test('fromJson defaults to 0 when no token fields present', () {
      final usage = LlmUsage.fromJson(<String, dynamic>{});
      expect(usage.inputTokens, 0);
      expect(usage.outputTokens, 0);
    });

    test('totalTokens computes sum', () {
      const usage = LlmUsage(inputTokens: 10, outputTokens: 20);
      expect(usage.totalTokens, 30);
    });
  });

  group('LlmChunk', () {
    test('fromJson / toJson round-trip with all fields', () {
      final json = {
        'content': 'partial',
        'isDone': true,
        'toolCall': {
          'id': 'tc1',
          'name': 'fn',
          'arguments': <String, dynamic>{}
        },
        'usage': {'inputTokens': 5, 'outputTokens': 10},
        'index': 3,
      };
      final chunk = LlmChunk.fromJson(json);
      expect(chunk.content, 'partial');
      expect(chunk.isDone, isTrue);
      expect(chunk.toolCall, isNotNull);
      expect(chunk.usage, isNotNull);
      expect(chunk.index, 3);

      final out = chunk.toJson();
      expect(out['content'], 'partial');
      expect(out['isDone'], isTrue);
      expect(out['toolCall'], isMap);
      expect(out['usage'], isMap);
      expect(out['index'], 3);
    });

    test('fromJson defaults isDone to false', () {
      final chunk = LlmChunk.fromJson({'content': 'x'});
      expect(chunk.isDone, isFalse);
    });

    test('toJson omits null optional fields', () {
      const chunk = LlmChunk();
      final out = chunk.toJson();
      expect(out.containsKey('content'), isFalse);
      expect(out['isDone'], isFalse);
      expect(out.containsKey('toolCall'), isFalse);
      expect(out.containsKey('usage'), isFalse);
      expect(out.containsKey('index'), isFalse);
    });
  });

  group('LlmTool', () {
    test('fromJson / toJson round-trip via parameters key', () {
      final json = {
        'name': 'search',
        'description': 'Search the web',
        'parameters': <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{}
        },
      };
      final tool = LlmTool.fromJson(json);
      expect(tool.name, 'search');
      expect(tool.description, 'Search the web');
      expect(tool.parameters['type'], 'object');

      final out = tool.toJson();
      expect(out['name'], 'search');
      expect(out['description'], 'Search the web');
      expect(out['parameters'], isMap);
    });

    test('fromJson supports inputSchema key', () {
      final json = {
        'name': 'calc',
        'description': 'Calculator',
        'inputSchema': <String, dynamic>{'type': 'object'},
      };
      final tool = LlmTool.fromJson(json);
      expect(tool.parameters['type'], 'object');
    });

    test('inputSchema alias returns parameters', () {
      const tool = LlmTool(
        name: 't',
        description: 'd',
        parameters: <String, dynamic>{'type': 'string'},
      );
      expect(tool.inputSchema, same(tool.parameters));
    });
  });

  group('LlmToolCall', () {
    test('fromJson / toJson round-trip with map arguments', () {
      final json = {
        'id': 'call_1',
        'name': 'fn',
        'arguments': <String, dynamic>{'key': 'val'},
      };
      final tc = LlmToolCall.fromJson(json);
      expect(tc.id, 'call_1');
      expect(tc.name, 'fn');
      expect(tc.arguments['key'], 'val');

      final out = tc.toJson();
      expect(out['id'], 'call_1');
      expect(out['name'], 'fn');
      expect(out['arguments'], isMap);
    });

    test('fromJson parses JSON string arguments', () {
      final json = {
        'id': 'call_2',
        'name': 'fn2',
        'arguments': jsonEncode({'x': 42}),
      };
      final tc = LlmToolCall.fromJson(json);
      expect(tc.arguments['x'], 42);
    });

    test('fromJson returns empty map for invalid JSON string arguments', () {
      final json = {
        'id': 'call_3',
        'name': 'fn3',
        'arguments': '{not-valid-json',
      };
      final tc = LlmToolCall.fromJson(json);
      expect(tc.arguments, isEmpty);
    });
  });

  group('LlmCapabilities', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'completion': true,
        'streaming': true,
        'embedding': true,
        'toolCalling': true,
        'vision': false,
        'audio': false,
        'rag': true,
        'maxContextTokens': 128000,
        'maxOutputTokens': 4096,
      };
      final cap = LlmCapabilities.fromJson(json);
      expect(cap.completion, isTrue);
      expect(cap.streaming, isTrue);
      expect(cap.embedding, isTrue);
      expect(cap.toolCalling, isTrue);
      expect(cap.vision, isFalse);
      expect(cap.audio, isFalse);
      expect(cap.rag, isTrue);
      expect(cap.maxContextTokens, 128000);
      expect(cap.maxOutputTokens, 4096);

      final out = cap.toJson();
      expect(out['completion'], isTrue);
      expect(out['rag'], isTrue);
      expect(out['maxContextTokens'], 128000);
      expect(out['maxOutputTokens'], 4096);
    });

    test('fromJson defaults', () {
      final cap = LlmCapabilities.fromJson(<String, dynamic>{});
      expect(cap.completion, isTrue);
      expect(cap.streaming, isFalse);
      expect(cap.embedding, isFalse);
      expect(cap.toolCalling, isFalse);
      expect(cap.vision, isFalse);
      expect(cap.audio, isFalse);
      expect(cap.rag, isFalse);
      expect(cap.maxContextTokens, isNull);
      expect(cap.maxOutputTokens, isNull);
    });

    test('toJson omits null maxContextTokens / maxOutputTokens', () {
      const cap = LlmCapabilities();
      final out = cap.toJson();
      expect(out.containsKey('maxContextTokens'), isFalse);
      expect(out.containsKey('maxOutputTokens'), isFalse);
    });

    test('.full() constructor', () {
      const cap = LlmCapabilities.full();
      expect(cap.completion, isTrue);
      expect(cap.streaming, isTrue);
      expect(cap.embedding, isTrue);
      expect(cap.toolCalling, isTrue);
      expect(cap.vision, isTrue);
      expect(cap.audio, isTrue);
      expect(cap.rag, isTrue);
    });

    test('.minimal() constructor', () {
      const cap = LlmCapabilities.minimal();
      expect(cap.completion, isTrue);
      expect(cap.streaming, isFalse);
      expect(cap.embedding, isFalse);
      expect(cap.toolCalling, isFalse);
      expect(cap.vision, isFalse);
      expect(cap.audio, isFalse);
      expect(cap.rag, isFalse);
    });
  });

  group('LlmPort (abstract methods via _TestLlmPort)', () {
    late _TestLlmPort port;

    setUp(() {
      port = _TestLlmPort();
    });

    test('hasCapability - completion', () {
      expect(port.hasCapability('completion'), isTrue);
    });

    test('hasCapability - streaming', () {
      expect(port.hasCapability('streaming'), isTrue);
    });

    test('hasCapability - embedding', () {
      expect(port.hasCapability('embedding'), isTrue);
    });

    test('hasCapability - toolCalling', () {
      expect(port.hasCapability('toolCalling'), isTrue);
    });

    test('hasCapability - vision', () {
      expect(port.hasCapability('vision'), isTrue);
    });

    test('hasCapability - audio', () {
      expect(port.hasCapability('audio'), isTrue);
    });

    test('hasCapability - rag', () {
      expect(port.hasCapability('rag'), isTrue);
    });

    test('hasCapability - unknown returns false', () {
      expect(port.hasCapability('unknownCap'), isFalse);
    });

    test('isAvailable defaults to true', () async {
      expect(await port.isAvailable(), isTrue);
    });

    test('completeStream throws UnsupportedError by default', () {
      final minimal = _MinimalLlmPort();
      expect(
        () => minimal.completeStream(LlmRequest.simple('hi')),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('completeWithContext throws UnsupportedError by default', () {
      final minimal = _MinimalLlmPort();
      final request = LlmRequest.simple('hi');
      final context = ContextBundle.empty();
      expect(
        () => minimal.completeWithContext(request, context),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('embed on minimal port throws UnsupportedError', () {
      final minimal = _MinimalLlmPort();
      expect(
        () => minimal.embed('text'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('embedBatch delegates to embed', () async {
      final results = await port.embedBatch(['a', 'b']);
      expect(results, hasLength(2));
      expect(results[0], [0.1, 0.2, 0.3]);
      expect(results[1], [0.1, 0.2, 0.3]);
    });

    test('similarity delegates to embed + cosineSimilarity', () async {
      // _TestLlmPort.embed always returns [0.1, 0.2, 0.3], so
      // similarity of identical vectors should be ~1.0.
      final sim = await port.similarity('a', 'b');
      expect(sim, closeTo(1.0, 1e-6));
    });

    test('completeWithTools throws UnsupportedError by default', () {
      final minimal = _MinimalLlmPort();
      expect(
        () => minimal.completeWithTools(LlmRequest.simple('q'), []),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('cosineSimilarity', () {
    test('identical vectors yields 1.0', () {
      final v = [1.0, 0.0, 0.0];
      expect(cosineSimilarity(v, v), closeTo(1.0, 1e-9));
    });

    test('orthogonal vectors yields 0.0', () {
      expect(cosineSimilarity([1, 0, 0], [0, 1, 0]), closeTo(0.0, 1e-9));
    });

    test('opposite vectors yields -1.0', () {
      expect(cosineSimilarity([1, 0], [-1, 0]), closeTo(-1.0, 1e-9));
    });

    test('different lengths returns 0.0', () {
      expect(cosineSimilarity([1, 2], [1, 2, 3]), 0.0);
    });

    test('empty vectors returns 0.0', () {
      expect(cosineSimilarity([], []), 0.0);
    });

    test('zero vector A returns 0.0', () {
      expect(cosineSimilarity([0, 0, 0], [1, 2, 3]), 0.0);
    });

    test('zero vector B returns 0.0', () {
      expect(cosineSimilarity([1, 2, 3], [0, 0, 0]), 0.0);
    });

    test('both zero vectors returns 0.0', () {
      expect(cosineSimilarity([0, 0], [0, 0]), 0.0);
    });

    test('general case with known values', () {
      // cos([1,2,3], [4,5,6]) = 32 / (sqrt(14) * sqrt(77))
      final sim = cosineSimilarity([1, 2, 3], [4, 5, 6]);
      final expected = 32.0 / (3.7416573867739413 * 8.774964387392123);
      expect(sim, closeTo(expected, 1e-6));
    });
  });

  group('StubLlmPort', () {
    late StubLlmPort port;

    setUp(() {
      port = StubLlmPort();
    });

    test('capabilities are minimal', () {
      expect(port.capabilities.completion, isTrue);
      expect(port.capabilities.streaming, isFalse);
      expect(port.capabilities.embedding, isFalse);
    });

    test('complete returns empty content', () async {
      final resp = await port.complete(LlmRequest.simple('test'));
      expect(resp.content, '');
    });

    test('embed returns 384 zeros', () async {
      final embedding = await port.embed('anything');
      expect(embedding, hasLength(384));
      expect(embedding.every((v) => v == 0.0), isTrue);
    });

    test('similarity returns 0.0', () async {
      final sim = await port.similarity('a', 'b');
      expect(sim, 0.0);
    });
  });

  group('EmptyLlmPort', () {
    late EmptyLlmPort port;

    setUp(() {
      port = EmptyLlmPort();
    });

    test('capabilities are minimal', () {
      expect(port.capabilities.completion, isTrue);
      expect(port.capabilities.streaming, isFalse);
    });

    test('complete throws UnimplementedError', () {
      expect(
        () => port.complete(LlmRequest.simple('test')),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  // =======================================================================
  // KNOWLEDGE PORT
  // =======================================================================
  group('RetrievalResult', () {
    test('fromJson / toJson round-trip with all fields', () {
      final json = {
        'passages': [
          {'id': 'p1', 'content': 'text', 'score': 0.95},
        ],
        'metadata': <String, dynamic>{'source': 'test'},
        'totalMatches': 42,
      };
      final result = RetrievalResult.fromJson(json);
      expect(result.passages, hasLength(1));
      expect(result.metadata!['source'], 'test');
      expect(result.totalMatches, 42);

      final out = result.toJson();
      expect(out['passages'], isList);
      expect(out['metadata'], isMap);
      expect(out['totalMatches'], 42);
    });

    test('toJson omits null optional fields', () {
      const result = RetrievalResult(passages: []);
      final out = result.toJson();
      expect(out.containsKey('metadata'), isFalse);
      expect(out.containsKey('totalMatches'), isFalse);
    });

    test('isEmpty returns true for empty passages', () {
      const result = RetrievalResult(passages: []);
      expect(result.isEmpty, isTrue);
      expect(result.isNotEmpty, isFalse);
    });

    test('isNotEmpty returns true when passages exist', () {
      const result = RetrievalResult(passages: [
        RetrievedPassage(id: 'p1', content: 'c', score: 0.9),
      ]);
      expect(result.isNotEmpty, isTrue);
      expect(result.isEmpty, isFalse);
    });
  });

  group('RetrievedPassage', () {
    test('fromJson / toJson round-trip with all fields', () {
      final json = {
        'id': 'p1',
        'content': 'passage text',
        'score': 0.88,
        'sourceId': 'doc1',
        'sourceUri': 'file:///doc.txt',
        'position': {
          'startOffset': 0,
          'endOffset': 100,
          'page': 2,
          'section': 'intro',
        },
        'metadata': <String, dynamic>{'tag': 'test'},
      };
      final passage = RetrievedPassage.fromJson(json);
      expect(passage.id, 'p1');
      expect(passage.content, 'passage text');
      expect(passage.score, 0.88);
      expect(passage.sourceId, 'doc1');
      expect(passage.sourceUri, 'file:///doc.txt');
      expect(passage.position, isNotNull);
      expect(passage.position!.startOffset, 0);
      expect(passage.position!.page, 2);
      expect(passage.metadata!['tag'], 'test');

      final out = passage.toJson();
      expect(out['id'], 'p1');
      expect(out['sourceId'], 'doc1');
      expect(out['position'], isMap);
      expect(out['metadata'], isMap);
    });

    test('fromJson / toJson without optional fields', () {
      final json = {
        'id': 'p2',
        'content': 'minimal',
        'score': 0.5,
      };
      final passage = RetrievedPassage.fromJson(json);
      expect(passage.sourceId, isNull);
      expect(passage.sourceUri, isNull);
      expect(passage.position, isNull);
      expect(passage.metadata, isNull);

      final out = passage.toJson();
      expect(out.containsKey('sourceId'), isFalse);
      expect(out.containsKey('sourceUri'), isFalse);
      expect(out.containsKey('position'), isFalse);
      expect(out.containsKey('metadata'), isFalse);
    });
  });

  group('PassagePosition', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'startOffset': 10,
        'endOffset': 50,
        'page': 3,
        'section': 'chapter1',
      };
      final pos = PassagePosition.fromJson(json);
      expect(pos.startOffset, 10);
      expect(pos.endOffset, 50);
      expect(pos.page, 3);
      expect(pos.section, 'chapter1');

      final out = pos.toJson();
      expect(out['startOffset'], 10);
      expect(out['endOffset'], 50);
      expect(out['page'], 3);
      expect(out['section'], 'chapter1');
    });

    test('fromJson with all null fields', () {
      final pos = PassagePosition.fromJson(<String, dynamic>{});
      expect(pos.startOffset, isNull);
      expect(pos.endOffset, isNull);
      expect(pos.page, isNull);
      expect(pos.section, isNull);
    });

    test('toJson omits null fields', () {
      const pos = PassagePosition();
      final out = pos.toJson();
      expect(out, isEmpty);
    });
  });

  group('AssetContent', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'assetId': 'asset1',
        'mimeType': 'text/plain',
        'content': 'Hello world',
        'size': 11,
        'hash': 'abc123',
        'metadata': <String, dynamic>{'encoding': 'utf-8'},
      };
      final asset = AssetContent.fromJson(json);
      expect(asset.assetId, 'asset1');
      expect(asset.mimeType, 'text/plain');
      expect(asset.content, 'Hello world');
      expect(asset.size, 11);
      expect(asset.hash, 'abc123');
      expect(asset.metadata!['encoding'], 'utf-8');

      final out = asset.toJson();
      expect(out['assetId'], 'asset1');
      expect(out['mimeType'], 'text/plain');
      expect(out['content'], 'Hello world');
      expect(out['size'], 11);
      expect(out['hash'], 'abc123');
    });

    test('toJson omits null optional fields', () {
      const asset = AssetContent(
        assetId: 'a',
        mimeType: 'text/plain',
        content: 'x',
      );
      final out = asset.toJson();
      expect(out.containsKey('size'), isFalse);
      expect(out.containsKey('hash'), isFalse);
      expect(out.containsKey('metadata'), isFalse);
    });

    test('asString returns content when it is a String', () {
      const asset = AssetContent(
        assetId: 'a',
        mimeType: 'text/plain',
        content: 'hello',
      );
      expect(asset.asString, 'hello');
      expect(asset.asBytes, isNull);
    });

    test('asBytes returns content when it is a List<int>', () {
      final bytes = <int>[72, 101, 108, 108, 111];
      final asset = AssetContent(
        assetId: 'b',
        mimeType: 'application/octet-stream',
        content: bytes,
      );
      expect(asset.asBytes, bytes);
      expect(asset.asString, isNull);
    });

    test('asString returns null when content is not String', () {
      const asset = AssetContent(
        assetId: 'c',
        mimeType: 'application/json',
        content: 42,
      );
      expect(asset.asString, isNull);
      expect(asset.asBytes, isNull);
    });
  });

  group('RetrieverInfo', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'id': 'r1',
        'name': 'Main Retriever',
        'type': 'vector',
        'sourceRefs': ['src1', 'src2'],
        'description': 'Primary vector retriever',
      };
      final info = RetrieverInfo.fromJson(json);
      expect(info.id, 'r1');
      expect(info.name, 'Main Retriever');
      expect(info.type, 'vector');
      expect(info.sourceRefs, ['src1', 'src2']);
      expect(info.description, 'Primary vector retriever');

      final out = info.toJson();
      expect(out['id'], 'r1');
      expect(out['name'], 'Main Retriever');
      expect(out['type'], 'vector');
      expect(out['sourceRefs'], ['src1', 'src2']);
      expect(out['description'], 'Primary vector retriever');
    });

    test('toJson omits null description', () {
      const info = RetrieverInfo(
        id: 'r2',
        name: 'R',
        type: 'keyword',
        sourceRefs: [],
      );
      final out = info.toJson();
      expect(out.containsKey('description'), isFalse);
    });
  });

  group('IndexBuildConfig', () {
    test('fromJson / toJson round-trip with all fields', () {
      final json = {
        'assetRefs': ['a1', 'a2'],
        'sourceRefs': ['s1'],
        'embeddingModel': 'text-embedding-3',
        'chunkSize': 512,
        'chunkOverlap': 64,
        'options': <String, dynamic>{'normalize': true},
      };
      final cfg = IndexBuildConfig.fromJson(json);
      expect(cfg.assetRefs, ['a1', 'a2']);
      expect(cfg.sourceRefs, ['s1']);
      expect(cfg.embeddingModel, 'text-embedding-3');
      expect(cfg.chunkSize, 512);
      expect(cfg.chunkOverlap, 64);
      expect(cfg.options!['normalize'], isTrue);

      final out = cfg.toJson();
      expect(out['assetRefs'], ['a1', 'a2']);
      expect(out['sourceRefs'], ['s1']);
      expect(out['embeddingModel'], 'text-embedding-3');
      expect(out['chunkSize'], 512);
      expect(out['chunkOverlap'], 64);
      expect(out['options'], isMap);
    });

    test('toJson omits null optional fields', () {
      const cfg = IndexBuildConfig(assetRefs: ['a1']);
      final out = cfg.toJson();
      expect(out.containsKey('sourceRefs'), isFalse);
      expect(out.containsKey('embeddingModel'), isFalse);
      expect(out.containsKey('chunkSize'), isFalse);
      expect(out.containsKey('chunkOverlap'), isFalse);
      expect(out.containsKey('options'), isFalse);
    });
  });

  group('AssetNotFoundException', () {
    test('toString includes asset ID', () {
      final ex = AssetNotFoundException('missing-asset');
      expect(
        ex.toString(),
        'AssetNotFoundException: Asset not found: missing-asset',
      );
    });
  });

  group('RetrieverNotFoundException', () {
    test('toString includes retriever ID', () {
      final ex = RetrieverNotFoundException('missing-ret');
      expect(
        ex.toString(),
        'RetrieverNotFoundException: Retriever not found: missing-ret',
      );
    });
  });

  // =======================================================================
  // METRIC PORT
  // =======================================================================
  group('MetricEvent', () {
    test('fromJson / toJson round-trip', () {
      final ts = DateTime.utc(2025, 6, 15, 12, 0);
      final json = {
        'name': 'accuracy',
        'value': {
          'value': 0.95,
          'timestamp': ts.toIso8601String(),
          'confidence': 0.9,
          'metadata': <String, dynamic>{'source': 'eval'},
        },
        'eventType': 'update',
      };
      final event = MetricEvent.fromJson(json);
      expect(event.name, 'accuracy');
      expect(event.value.value, 0.95);
      expect(event.value.timestamp, ts);
      expect(event.value.confidence, 0.9);
      expect(event.eventType, 'update');

      final out = event.toJson();
      expect(out['name'], 'accuracy');
      expect(out['value'], isMap);
      expect(out['eventType'], 'update');
    });
  });

  group('MetricValue', () {
    test('fromJson / toJson round-trip with all fields', () {
      final ts = DateTime.utc(2025, 1, 1);
      final json = {
        'value': 3.14,
        'timestamp': ts.toIso8601String(),
        'confidence': 0.8,
        'metadata': <String, dynamic>{'unit': 'percent'},
      };
      final mv = MetricValue.fromJson(json);
      expect(mv.value, 3.14);
      expect(mv.timestamp, ts);
      expect(mv.confidence, 0.8);
      expect(mv.metadata!['unit'], 'percent');

      final out = mv.toJson();
      expect(out['value'], 3.14);
      expect(out['timestamp'], ts.toIso8601String());
      expect(out['confidence'], 0.8);
      expect(out['metadata'], isMap);
    });

    test('toJson omits null optional fields', () {
      final mv = MetricValue(
        value: 1.0,
        timestamp: DateTime.utc(2025, 1, 1),
      );
      final out = mv.toJson();
      expect(out.containsKey('confidence'), isFalse);
      expect(out.containsKey('metadata'), isFalse);
    });
  });

  group('StubMetricPort', () {
    late StubMetricPort port;

    setUp(() {
      port = StubMetricPort();
    });

    test('compute returns default metric value', () async {
      final mv = await port.compute('test', {'key': 'val'});
      expect(mv.value, 0.5);
      expect(mv.confidence, 1.0);
    });

    test('record completes without error', () async {
      await expectLater(
        port.record('latency', 120.0, tags: {'env': 'prod'}),
        completes,
      );
    });

    test('watch returns empty stream', () async {
      final events = await port.watch('metric').toList();
      expect(events, isEmpty);
    });

    test('history returns empty list', () async {
      final history = await port.history(
        'metric',
        start: DateTime.utc(2025, 1, 1),
        end: DateTime.utc(2025, 12, 31),
        limit: 100,
      );
      expect(history, isEmpty);
    });
  });

  // =======================================================================
  // EVENT PORT
  // =======================================================================
  group('PortEvent', () {
    test('fromJson / toJson round-trip with all fields', () {
      final ts = DateTime.utc(2025, 6, 1, 10, 30);
      final json = {
        'type': 'skill.completed',
        'payload': <String, dynamic>{'skillId': 's1', 'status': 'ok'},
        'timestamp': ts.toIso8601String(),
        'source': 'skill-engine',
      };
      final event = PortEvent.fromJson(json);
      expect(event.type, 'skill.completed');
      expect(event.payload['skillId'], 's1');
      expect(event.timestamp, ts);
      expect(event.source, 'skill-engine');

      final out = event.toJson();
      expect(out['type'], 'skill.completed');
      expect(out['payload'], isMap);
      expect(out['timestamp'], ts.toIso8601String());
      expect(out['source'], 'skill-engine');
    });

    test('toJson omits null source', () {
      final event = PortEvent(
        type: 'test',
        payload: <String, dynamic>{},
        timestamp: DateTime.utc(2025, 1, 1),
      );
      final out = event.toJson();
      expect(out.containsKey('source'), isFalse);
    });
  });

  group('InMemoryEventPort', () {
    late InMemoryEventPort port;

    setUp(() {
      port = InMemoryEventPort();
    });

    tearDown(() {
      port.dispose();
    });

    test('publish and subscribe flow', () async {
      final ts = DateTime.utc(2025, 1, 1);
      final event = PortEvent(
        type: 'test.event',
        payload: <String, dynamic>{'data': 1},
        timestamp: ts,
      );

      final futureEvents = port.subscribe('test.event').take(1).toList();

      await port.publish(event);

      final received = await futureEvents;
      expect(received, hasLength(1));
      expect(received.first.type, 'test.event');
      expect(received.first.payload['data'], 1);
    });

    test('subscribe filters by event type', () async {
      final ts = DateTime.utc(2025, 1, 1);
      final eventA = PortEvent(
        type: 'type.a',
        payload: <String, dynamic>{},
        timestamp: ts,
      );
      final eventB = PortEvent(
        type: 'type.b',
        payload: <String, dynamic>{},
        timestamp: ts,
      );

      final futureA = port.subscribe('type.a').take(1).toList();

      await port.publish(eventB);
      await port.publish(eventA);

      final received = await futureA;
      expect(received, hasLength(1));
      expect(received.first.type, 'type.a');
    });

    test('subscribeAll receives all events', () async {
      final ts = DateTime.utc(2025, 1, 1);
      final event1 = PortEvent(
        type: 'alpha',
        payload: <String, dynamic>{},
        timestamp: ts,
      );
      final event2 = PortEvent(
        type: 'beta',
        payload: <String, dynamic>{},
        timestamp: ts,
      );

      final futureAll = port.subscribeAll().take(2).toList();

      await port.publish(event1);
      await port.publish(event2);

      final received = await futureAll;
      expect(received, hasLength(2));
      expect(received[0].type, 'alpha');
      expect(received[1].type, 'beta');
    });

    test('unsubscribe is a no-op (does not throw)', () async {
      await expectLater(port.unsubscribe('any.type'), completes);
    });
  });
}
