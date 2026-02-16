import 'package:test/test.dart';
import 'package:mcp_bundle/ports.dart';

void main() {
  group('LlmPort', () {
    test('LlmCapabilities creates with defaults', () {
      const caps = LlmCapabilities();
      expect(caps.completion, isTrue);
      expect(caps.streaming, isFalse);
      expect(caps.embedding, isFalse);
      expect(caps.toolCalling, isFalse);
    });

    test('LlmCapabilities.full enables all features', () {
      const caps = LlmCapabilities.full();
      expect(caps.completion, isTrue);
      expect(caps.streaming, isTrue);
      expect(caps.embedding, isTrue);
      expect(caps.toolCalling, isTrue);
    });

    test('LlmCapabilities serializes and deserializes', () {
      const caps = LlmCapabilities(
        streaming: true,
        embedding: true,
        maxContextTokens: 8192,
      );
      final json = caps.toJson();
      final restored = LlmCapabilities.fromJson(json);
      expect(restored.streaming, isTrue);
      expect(restored.embedding, isTrue);
      expect(restored.maxContextTokens, equals(8192));
    });

    test('LlmRequest creates with prompt', () {
      final req = LlmRequest(prompt: 'Hello');
      expect(req.prompt, equals('Hello'));
      expect(req.systemPrompt, isNull);
      expect(req.model, isNull);
      expect(req.effectivePrompt, equals('Hello'));
    });

    test('LlmRequest.simple factory works', () {
      final req = LlmRequest.simple('Test', systemPrompt: 'System');
      expect(req.prompt, equals('Test'));
      expect(req.systemPrompt, equals('System'));
    });

    test('LlmMessage creates correctly', () {
      final userMsg = LlmMessage.user('Hello');
      expect(userMsg.role, equals('user'));
      expect(userMsg.content, equals('Hello'));

      final assistantMsg = LlmMessage.assistant('Hi there');
      expect(assistantMsg.role, equals('assistant'));

      final systemMsg = LlmMessage.system('You are helpful');
      expect(systemMsg.role, equals('system'));

      final toolMsg = LlmMessage.tool('call_1', 'result');
      expect(toolMsg.role, equals('tool'));
      expect(toolMsg.toolCallId, equals('call_1'));
    });

    test('LlmRequest.conversation creates with messages', () {
      final req = LlmRequest.conversation([
        LlmMessage.user('Hello'),
        LlmMessage.assistant('Hi!'),
        LlmMessage.user('How are you?'),
      ]);
      expect(req.messages?.length, equals(3));
      expect(req.effectivePrompt, equals('Hello'));
      expect(req.effectiveMessages.length, equals(3));
    });

    test('LlmRequest effectiveMessages converts prompt to message', () {
      final req = LlmRequest(prompt: 'Hello');
      final messages = req.effectiveMessages;
      expect(messages.length, equals(1));
      expect(messages.first.role, equals('user'));
      expect(messages.first.content, equals('Hello'));
    });

    test('LlmResponse hasToolCalls works correctly', () {
      const noTools = LlmResponse(content: 'Hello');
      expect(noTools.hasToolCalls, isFalse);

      const withTools = LlmResponse(
        content: '',
        toolCalls: [LlmToolCall(id: '1', name: 'test', arguments: {})],
      );
      expect(withTools.hasToolCalls, isTrue);
    });

    test('LlmResponse creates with content', () {
      const res = LlmResponse(content: 'Response');
      expect(res.content, equals('Response'));
      expect(res.usage, isNull);
    });

    test('LlmUsage calculates totalTokens', () {
      const usage = LlmUsage(inputTokens: 100, outputTokens: 50);
      expect(usage.totalTokens, equals(150));
    });

    test('LlmTool serializes correctly', () {
      const tool = LlmTool(
        name: 'get_weather',
        description: 'Get weather info',
        parameters: {'type': 'object', 'properties': {}},
      );
      final json = tool.toJson();
      expect(json['name'], equals('get_weather'));
      expect(json['description'], equals('Get weather info'));
    });

    test('LlmToolCall parses JSON arguments', () {
      final call = LlmToolCall.fromJson({
        'id': 'call_1',
        'name': 'test',
        'arguments': '{"key": "value"}',
      });
      expect(call.arguments['key'], equals('value'));
    });

    test('StubLlmPort returns empty response', () async {
      final port = StubLlmPort();
      final res = await port.complete(const LlmRequest(prompt: 'Test'));
      expect(res.content, isEmpty);
    });

    test('StubLlmPort returns zero embeddings', () async {
      final port = StubLlmPort();
      final emb = await port.embed('Test');
      expect(emb.length, equals(384));
      expect(emb.every((v) => v == 0.0), isTrue);
    });

    test('EmptyLlmPort throws on complete', () {
      final port = EmptyLlmPort();
      expect(
        () => port.complete(const LlmRequest(prompt: 'Test')),
        throwsUnimplementedError,
      );
    });

    test('cosineSimilarity computes correctly', () {
      final a = [1.0, 0.0, 0.0];
      final b = [1.0, 0.0, 0.0];
      expect(cosineSimilarity(a, b), closeTo(1.0, 0.001));

      final c = [1.0, 0.0, 0.0];
      final d = [0.0, 1.0, 0.0];
      expect(cosineSimilarity(c, d), closeTo(0.0, 0.001));
    });

    test('LlmPort hasCapability checks correctly', () {
      final port = StubLlmPort();
      expect(port.hasCapability('completion'), isTrue);
      expect(port.hasCapability('streaming'), isFalse);
      expect(port.hasCapability('unknown'), isFalse);
    });
  });

  group('StoragePort', () {
    test('InMemoryKvStoragePort stores and retrieves', () async {
      final storage = InMemoryKvStoragePort();
      await storage.set('key1', 'value1');
      expect(await storage.get('key1'), equals('value1'));
      expect(await storage.exists('key1'), isTrue);
      expect(await storage.exists('key2'), isFalse);
    });

    test('InMemoryKvStoragePort lists keys', () async {
      final storage = InMemoryKvStoragePort();
      await storage.set('prefix:a', 1);
      await storage.set('prefix:b', 2);
      await storage.set('other:c', 3);

      final allKeys = await storage.keys();
      expect(allKeys.length, equals(3));

      final prefixKeys = await storage.keys(prefix: 'prefix:');
      expect(prefixKeys.length, equals(2));
    });

    test('InMemoryKvStoragePort clears all', () async {
      final storage = InMemoryKvStoragePort();
      await storage.set('a', 1);
      await storage.set('b', 2);
      await storage.clear();
      expect(await storage.keys(), isEmpty);
    });

    test('InMemoryStoragePort CRUD operations', () async {
      final storage = InMemoryStoragePort<String>();
      await storage.save('id1', 'data1');
      expect(await storage.get('id1'), equals('data1'));
      expect(await storage.exists('id1'), isTrue);

      await storage.delete('id1');
      expect(await storage.get('id1'), isNull);
      expect(await storage.exists('id1'), isFalse);
    });
  });

  group('MetricPort', () {
    test('MetricValue creates with required fields', () {
      final now = DateTime.now();
      final value = MetricValue(value: 0.75, timestamp: now);
      expect(value.value, equals(0.75));
      expect(value.timestamp, equals(now));
    });

    test('MetricValue serializes and deserializes', () {
      final value = MetricValue(
        value: 0.5,
        timestamp: DateTime.utc(2025, 1, 1),
        confidence: 0.9,
      );
      final json = value.toJson();
      final restored = MetricValue.fromJson(json);
      expect(restored.value, equals(0.5));
      expect(restored.confidence, equals(0.9));
    });

    test('StubMetricPort returns default value', () async {
      final port = StubMetricPort();
      final value = await port.compute('test', {});
      expect(value.value, equals(0.5));
      expect(value.confidence, equals(1.0));
    });
  });

  group('EventPort', () {
    test('PortEvent creates with required fields', () {
      final now = DateTime.now();
      final event = PortEvent(
        type: 'test.event',
        payload: {'key': 'value'},
        timestamp: now,
      );
      expect(event.type, equals('test.event'));
      expect(event.payload['key'], equals('value'));
    });

    test('PortEvent serializes and deserializes', () {
      final event = PortEvent(
        type: 'test',
        payload: {'data': 123},
        timestamp: DateTime.utc(2025, 1, 1),
        source: 'test-source',
      );
      final json = event.toJson();
      final restored = PortEvent.fromJson(json);
      expect(restored.type, equals('test'));
      expect(restored.source, equals('test-source'));
    });

    test('InMemoryEventPort publishes and subscribes', () async {
      final port = InMemoryEventPort();
      final events = <PortEvent>[];

      port.subscribe('test').listen(events.add);

      await port.publish(PortEvent(
        type: 'test',
        payload: {'n': 1},
        timestamp: DateTime.now(),
      ));

      await port.publish(PortEvent(
        type: 'other',
        payload: {'n': 2},
        timestamp: DateTime.now(),
      ));

      await Future.delayed(const Duration(milliseconds: 10));

      expect(events.length, equals(1));
      expect(events.first.payload['n'], equals(1));

      port.dispose();
    });
  });
}
