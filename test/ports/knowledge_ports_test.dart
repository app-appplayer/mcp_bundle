import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  // ===========================================================================
  // QueryFilter
  // ===========================================================================
  group('QueryFilter', () {
    test('creates with default values', () {
      const filter = QueryFilter();
      expect(filter.conditions, isEmpty);
      expect(filter.limit, isNull);
      expect(filter.offset, isNull);
      expect(filter.orderBy, isNull);
      expect(filter.descending, isFalse);
    });

    test('creates with all parameters', () {
      const filter = QueryFilter(
        conditions: {'status': 'active'},
        limit: 10,
        offset: 5,
        orderBy: 'createdAt',
        descending: true,
      );
      expect(filter.conditions, equals({'status': 'active'}));
      expect(filter.limit, equals(10));
      expect(filter.offset, equals(5));
      expect(filter.orderBy, equals('createdAt'));
      expect(filter.descending, isTrue);
    });

    test('empty filter has no conditions', () {
      expect(QueryFilter.empty.conditions, isEmpty);
      expect(QueryFilter.empty.limit, isNull);
      expect(QueryFilter.empty.offset, isNull);
      expect(QueryFilter.empty.orderBy, isNull);
      expect(QueryFilter.empty.descending, isFalse);
    });
  });

  // ===========================================================================
  // InMemoryCollectionStoragePort
  // ===========================================================================
  group('InMemoryCollectionStoragePort', () {
    late InMemoryCollectionStoragePort storage;

    setUp(() {
      storage = InMemoryCollectionStoragePort();
    });

    test('save and get item', () async {
      await storage.save('users', 'u1', {'name': 'Alice', 'age': 30});
      final result = await storage.get('users', 'u1');
      expect(result, isNotNull);
      expect(result!['name'], equals('Alice'));
      expect(result['age'], equals(30));
    });

    test('get returns null for non-existent item', () async {
      final result = await storage.get('users', 'missing');
      expect(result, isNull);
    });

    test('get returns null for non-existent collection', () async {
      final result = await storage.get('nonexistent', 'id1');
      expect(result, isNull);
    });

    test('save overwrites existing item', () async {
      await storage.save('users', 'u1', {'name': 'Alice'});
      await storage.save('users', 'u1', {'name': 'Bob'});
      final result = await storage.get('users', 'u1');
      expect(result!['name'], equals('Bob'));
    });

    test('save to multiple collections', () async {
      await storage.save('users', 'u1', {'name': 'Alice'});
      await storage.save('products', 'p1', {'title': 'Widget'});

      final user = await storage.get('users', 'u1');
      final product = await storage.get('products', 'p1');
      expect(user!['name'], equals('Alice'));
      expect(product!['title'], equals('Widget'));
    });

    test('delete removes item', () async {
      await storage.save('users', 'u1', {'name': 'Alice'});
      await storage.delete('users', 'u1');
      final result = await storage.get('users', 'u1');
      expect(result, isNull);
    });

    test('delete on non-existent collection does not throw', () async {
      await storage.delete('nonexistent', 'id1');
    });

    test('delete on non-existent item does not throw', () async {
      await storage.save('users', 'u1', {'name': 'Alice'});
      await storage.delete('users', 'missing');
      final result = await storage.get('users', 'u1');
      expect(result, isNotNull);
    });

    test('exists returns true for existing item', () async {
      await storage.save('users', 'u1', {'name': 'Alice'});
      expect(await storage.exists('users', 'u1'), isTrue);
    });

    test('exists returns false for non-existent item', () async {
      expect(await storage.exists('users', 'missing'), isFalse);
    });

    test('exists returns false for non-existent collection', () async {
      expect(await storage.exists('nonexistent', 'id1'), isFalse);
    });

    test('listIds returns all IDs in collection', () async {
      await storage.save('users', 'u1', {'name': 'Alice'});
      await storage.save('users', 'u2', {'name': 'Bob'});
      await storage.save('users', 'u3', {'name': 'Charlie'});

      final ids = await storage.listIds('users');
      expect(ids, hasLength(3));
      expect(ids, containsAll(['u1', 'u2', 'u3']));
    });

    test('listIds returns empty for non-existent collection', () async {
      final ids = await storage.listIds('nonexistent');
      expect(ids, isEmpty);
    });

    test('query returns all items with empty filter', () async {
      await storage.save('users', 'u1', {'name': 'Alice'});
      await storage.save('users', 'u2', {'name': 'Bob'});

      final results = await storage.query('users', QueryFilter.empty);
      expect(results, hasLength(2));
    });

    test('query returns empty for non-existent collection', () async {
      final results = await storage.query('nonexistent', QueryFilter.empty);
      expect(results, isEmpty);
    });

    test('query respects limit', () async {
      await storage.save('items', 'i1', {'val': 1});
      await storage.save('items', 'i2', {'val': 2});
      await storage.save('items', 'i3', {'val': 3});

      final results = await storage.query(
        'items',
        const QueryFilter(limit: 2),
      );
      expect(results, hasLength(2));
    });

    test('query respects offset', () async {
      await storage.save('items', 'i1', {'val': 1});
      await storage.save('items', 'i2', {'val': 2});
      await storage.save('items', 'i3', {'val': 3});

      final results = await storage.query(
        'items',
        const QueryFilter(offset: 1),
      );
      expect(results, hasLength(2));
    });

    test('query respects offset and limit together', () async {
      await storage.save('items', 'i1', {'val': 1});
      await storage.save('items', 'i2', {'val': 2});
      await storage.save('items', 'i3', {'val': 3});
      await storage.save('items', 'i4', {'val': 4});

      final results = await storage.query(
        'items',
        const QueryFilter(offset: 1, limit: 2),
      );
      expect(results, hasLength(2));
    });

    test('query with offset zero returns all items', () async {
      await storage.save('items', 'i1', {'val': 1});
      await storage.save('items', 'i2', {'val': 2});

      final results = await storage.query(
        'items',
        const QueryFilter(offset: 0),
      );
      expect(results, hasLength(2));
    });

    test('query with offset beyond data returns empty', () async {
      await storage.save('items', 'i1', {'val': 1});

      final results = await storage.query(
        'items',
        const QueryFilter(offset: 10),
      );
      expect(results, isEmpty);
    });

    test('clear removes all data', () async {
      await storage.save('users', 'u1', {'name': 'Alice'});
      await storage.save('products', 'p1', {'title': 'Widget'});

      storage.clear();

      expect(await storage.get('users', 'u1'), isNull);
      expect(await storage.get('products', 'p1'), isNull);
      expect(await storage.listIds('users'), isEmpty);
    });
  });

  // ===========================================================================
  // ToolResult
  // ===========================================================================
  group('ToolResult', () {
    test('creates with required fields', () {
      const result = ToolResult(content: 'data');
      expect(result.content, equals('data'));
      expect(result.isError, isFalse);
      expect(result.errorMessage, isNull);
    });

    test('creates with all fields', () {
      const result = ToolResult(
        content: null,
        isError: true,
        errorMessage: 'Something went wrong',
      );
      expect(result.content, isNull);
      expect(result.isError, isTrue);
      expect(result.errorMessage, equals('Something went wrong'));
    });

    test('success factory creates non-error result', () {
      final result = ToolResult.success({'key': 'value'});
      expect(result.content, equals({'key': 'value'}));
      expect(result.isError, isFalse);
      expect(result.errorMessage, isNull);
    });

    test('error factory creates error result', () {
      final result = ToolResult.error('failed');
      expect(result.content, isNull);
      expect(result.isError, isTrue);
      expect(result.errorMessage, equals('failed'));
    });

    test('success with null content', () {
      final result = ToolResult.success(null);
      expect(result.content, isNull);
      expect(result.isError, isFalse);
    });

    test('success with various content types', () {
      final stringResult = ToolResult.success('text');
      expect(stringResult.content, equals('text'));

      final intResult = ToolResult.success(42);
      expect(intResult.content, equals(42));

      final listResult = ToolResult.success([1, 2, 3]);
      expect(listResult.content, equals([1, 2, 3]));
    });
  });

  // ===========================================================================
  // ResourceContent (unified — replaces legacy McpResource)
  // ===========================================================================
  group('ResourceContent', () {
    test('creates with required fields only', () {
      const resource = ResourceContent(uri: 'file:///test');
      expect(resource.uri, equals('file:///test'));
      expect(resource.text, isNull);
      expect(resource.bytes, isNull);
      expect(resource.mimeType, isNull);
      expect(resource.metadata, isNull);
    });

    test('creates with text content', () {
      const resource = ResourceContent(
        uri: 'file:///test.json',
        mimeType: 'application/json',
        text: '{"key": "value"}',
        metadata: {'size': 16},
      );
      expect(resource.uri, equals('file:///test.json'));
      expect(resource.mimeType, equals('application/json'));
      expect(resource.text, equals('{"key": "value"}'));
      expect(resource.isText, isTrue);
      expect(resource.isBinary, isFalse);
      expect(resource.metadata!['size'], equals(16));
    });

    test('creates with binary content', () {
      const resource = ResourceContent(
        uri: 'file:///blob.bin',
        mimeType: 'application/octet-stream',
        bytes: [1, 2, 3, 4],
      );
      expect(resource.bytes, equals([1, 2, 3, 4]));
      expect(resource.isBinary, isTrue);
      expect(resource.isText, isFalse);
    });
  });

  // ===========================================================================
  // ToolInfo
  // ===========================================================================
  group('ToolInfo', () {
    test('creates with required fields', () {
      const info = ToolInfo(name: 'get_data');
      expect(info.name, equals('get_data'));
      expect(info.description, isNull);
      expect(info.inputSchema, isNull);
    });

    test('creates with all fields', () {
      const info = ToolInfo(
        name: 'search',
        description: 'Search for items',
        inputSchema: {
          'type': 'object',
          'properties': {'query': 'string'},
        },
      );
      expect(info.name, equals('search'));
      expect(info.description, equals('Search for items'));
      expect(info.inputSchema, isNotNull);
    });
  });

  // ===========================================================================
  // ResourceInfo
  // ===========================================================================
  group('ResourceInfo', () {
    test('creates with required fields', () {
      const info = ResourceInfo(uri: 'file:///data', name: 'data');
      expect(info.uri, equals('file:///data'));
      expect(info.name, equals('data'));
      expect(info.description, isNull);
      expect(info.mimeType, isNull);
    });

    test('creates with all fields', () {
      const info = ResourceInfo(
        uri: 'file:///config.json',
        name: 'config',
        description: 'Configuration file',
        mimeType: 'application/json',
      );
      expect(info.uri, equals('file:///config.json'));
      expect(info.name, equals('config'));
      expect(info.description, equals('Configuration file'));
      expect(info.mimeType, equals('application/json'));
    });
  });

  // ===========================================================================
  // StubMcpPort
  // ===========================================================================
  group('StubMcpPort', () {
    late StubMcpPort port;

    setUp(() {
      port = const StubMcpPort();
    });

    test('callTool returns stub result', () async {
      final result = await port.callTool('test_tool', {'arg': 'value'});
      expect(result.content, equals('Stub tool result'));
      expect(result.isError, isFalse);
    });

    test('readResource returns empty resource with matching uri', () async {
      final resource = await port.readResource('file:///test');
      expect(resource.uri, equals('file:///test'));
      expect(resource.text, isEmpty);
    });

    test('listTools returns empty list', () async {
      final tools = await port.listTools();
      expect(tools, isEmpty);
    });

    test('listResources returns empty list', () async {
      final resources = await port.listResources();
      expect(resources, isEmpty);
    });

    test('isConnected returns true', () async {
      final connected = await port.isConnected();
      expect(connected, isTrue);
    });
  });

  // ===========================================================================
  // EvidenceFragment
  // ===========================================================================
  group('EvidenceFragment', () {
    test('creates with required fields', () {
      const fragment = EvidenceFragment(
        text: 'The sky is blue',
        type: 'fact',
        confidence: 0.95,
      );
      expect(fragment.text, equals('The sky is blue'));
      expect(fragment.type, equals('fact'));
      expect(fragment.confidence, equals(0.95));
      expect(fragment.sourceOffset, isNull);
      expect(fragment.sourceLength, isNull);
    });

    test('creates with all fields', () {
      const fragment = EvidenceFragment(
        text: 'Temperature is 25C',
        type: 'measurement',
        confidence: 0.8,
        sourceOffset: 10,
        sourceLength: 18,
      );
      expect(fragment.text, equals('Temperature is 25C'));
      expect(fragment.sourceOffset, equals(10));
      expect(fragment.sourceLength, equals(18));
    });
  });

  // ===========================================================================
  // StubEvidencePort
  // ===========================================================================
  group('StubEvidencePort', () {
    late StubEvidencePort port;

    setUp(() {
      port = const StubEvidencePort();
    });

    test('extractFragments returns empty list', () async {
      final fragments = await port.extractFragments(
        'Some content here',
        'text/plain',
      );
      expect(fragments, isEmpty);
    });

    test('computeConfidence returns 0.5', () async {
      final confidence = await port.computeConfidence('any fragment');
      expect(confidence, equals(0.5));
    });

    test('classifyFragment returns unknown', () async {
      final type = await port.classifyFragment('any fragment');
      expect(type, equals('unknown'));
    });
  });

  // ===========================================================================
  // StubExpressionPort
  // ===========================================================================
  group('StubExpressionPort', () {
    late StubExpressionPort port;

    setUp(() {
      port = const StubExpressionPort();
    });

    test('format replaces single variable', () {
      final result = port.format(
        'Hello, {{name}}!',
        {'name': 'World'},
      );
      expect(result, equals('Hello, World!'));
    });

    test('format replaces multiple variables', () {
      final result = port.format(
        '{{greeting}}, {{name}}! You are {{age}} years old.',
        {'greeting': 'Hi', 'name': 'Alice', 'age': 30},
      );
      expect(result, equals('Hi, Alice! You are 30 years old.'));
    });

    test('format with no variables returns template unchanged', () {
      final result = port.format('No variables here', {});
      expect(result, equals('No variables here'));
    });

    test('format leaves unmatched placeholders', () {
      final result = port.format(
        '{{found}} and {{missing}}',
        {'found': 'yes'},
      );
      expect(result, equals('yes and {{missing}}'));
    });

    test('format handles repeated variable', () {
      final result = port.format(
        '{{x}} + {{x}} = {{sum}}',
        {'x': '2', 'sum': '4'},
      );
      expect(result, equals('2 + 2 = 4'));
    });

    test('validate always returns true', () {
      expect(port.validate('any template'), isTrue);
      expect(port.validate(''), isTrue);
      expect(port.validate('{{var}}'), isTrue);
    });

    test('extractVariables finds single variable', () {
      final vars = port.extractVariables('Hello {{name}}');
      expect(vars, equals(['name']));
    });

    test('extractVariables finds multiple variables', () {
      final vars = port.extractVariables('{{a}} and {{b}} and {{c}}');
      expect(vars, equals(['a', 'b', 'c']));
    });

    test('extractVariables returns empty for no variables', () {
      final vars = port.extractVariables('No variables here');
      expect(vars, isEmpty);
    });

    test('extractVariables handles duplicate variables', () {
      final vars = port.extractVariables('{{x}} + {{x}}');
      expect(vars, equals(['x', 'x']));
    });

    test('extractVariables handles adjacent variables', () {
      final vars = port.extractVariables('{{a}}{{b}}');
      expect(vars, equals(['a', 'b']));
    });
  });
}
