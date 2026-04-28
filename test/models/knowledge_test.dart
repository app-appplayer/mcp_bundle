import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────
  // KnowledgeSection
  // ─────────────────────────────────────────────────────────────────
  group('KnowledgeSection', () {
    test('fromJson with empty JSON uses defaults', () {
      final section = KnowledgeSection.fromJson({});

      expect(section.schemaVersion, equals('1.0.0'));
      expect(section.sources, isEmpty);
      expect(section.retriever, isNull);
      expect(section.index, isNull);
    });

    test('toJson with defaults omits empty sources, null retriever, null index',
        () {
      const section = KnowledgeSection();
      final json = section.toJson();

      expect(json['schemaVersion'], equals('1.0.0'));
      expect(json.containsKey('sources'), isFalse);
      expect(json.containsKey('retriever'), isFalse);
      expect(json.containsKey('index'), isFalse);
    });

    test('fromJson → toJson roundtrip with sources', () {
      final json = {
        'schemaVersion': '2.0.0',
        'sources': [
          {
            'id': 'src-1',
            'name': 'Test Source',
            'type': 'documents',
          },
        ],
      };

      final section = KnowledgeSection.fromJson(json);
      final output = section.toJson();

      expect(output['schemaVersion'], equals('2.0.0'));
      expect((output['sources'] as List).length, equals(1));
      expect(
          ((output['sources'] as List)[0] as Map<String, dynamic>)['id'],
          equals('src-1'));
    });

    test('fromJson → toJson roundtrip with retriever and index', () {
      final json = {
        'schemaVersion': '1.0.0',
        'sources': <Map<String, dynamic>>[],
        'retriever': {
          'mode': 'hybrid',
          'topK': 10,
        },
        'index': {
          'type': 'faiss',
          'persist': true,
          'path': '/data/index',
        },
      };

      final section = KnowledgeSection.fromJson(json);

      expect(section.retriever, isNotNull);
      expect(section.retriever!.mode, equals(RetrievalMode.hybrid));
      expect(section.retriever!.topK, equals(10));
      expect(section.index, isNotNull);
      expect(section.index!.type, equals(IndexType.faiss));
      expect(section.index!.persist, isTrue);
      expect(section.index!.path, equals('/data/index'));

      final output = section.toJson();
      expect(output['retriever'], isNotNull);
      expect(output['index'], isNotNull);
    });

    test('getSource returns matching source by id', () {
      final section = KnowledgeSection.fromJson({
        'sources': [
          {'id': 'alpha', 'name': 'Alpha', 'type': 'documents'},
          {'id': 'beta', 'name': 'Beta', 'type': 'web'},
        ],
      });

      final found = section.getSource('beta');
      expect(found, isNotNull);
      expect(found!.name, equals('Beta'));
      expect(found.type, equals(KnowledgeSourceType.web));
    });

    test('getSource returns null when id not found', () {
      final section = KnowledgeSection.fromJson({
        'sources': [
          {'id': 'alpha', 'name': 'Alpha', 'type': 'documents'},
        ],
      });

      expect(section.getSource('nonexistent'), isNull);
    });

    test('getSource returns null on empty sources', () {
      const section = KnowledgeSection();
      expect(section.getSource('any'), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // KnowledgeSource
  // ─────────────────────────────────────────────────────────────────
  group('KnowledgeSource', () {
    test('fromJson with minimal fields', () {
      final source = KnowledgeSource.fromJson({
        'id': 'src-1',
        'name': 'Docs',
        'type': 'documents',
      });

      expect(source.id, equals('src-1'));
      expect(source.name, equals('Docs'));
      expect(source.type, equals(KnowledgeSourceType.documents));
      expect(source.description, isNull);
      expect(source.documents, isNull);
      expect(source.reference, isNull);
      expect(source.chunking, isNull);
      expect(source.embedding, isNull);
      expect(source.metadata, isEmpty);
    });

    test('fromJson with empty JSON uses defaults', () {
      final source = KnowledgeSource.fromJson({});

      expect(source.id, equals(''));
      expect(source.name, equals(''));
      expect(source.type, equals(KnowledgeSourceType.documents));
      expect(source.metadata, isEmpty);
    });

    test('toJson with minimal fields omits optional fields', () {
      const source = KnowledgeSource(
        id: 'src-1',
        name: 'Docs',
        type: KnowledgeSourceType.documents,
      );
      final json = source.toJson();

      expect(json['id'], equals('src-1'));
      expect(json['name'], equals('Docs'));
      expect(json['type'], equals('documents'));
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('documents'), isFalse);
      expect(json.containsKey('reference'), isFalse);
      expect(json.containsKey('chunking'), isFalse);
      expect(json.containsKey('embedding'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('fromJson → toJson roundtrip with all fields', () {
      final json = {
        'id': 'src-full',
        'name': 'Full Source',
        'description': 'A full knowledge source',
        'type': 'api',
        'documents': [
          {'content': 'Hello world', 'format': 'text'},
        ],
        'reference': {
          'type': 'url',
          'uri': 'https://example.com/data',
        },
        'chunking': {
          'strategy': 'sentence',
          'chunkSize': 256,
          'chunkOverlap': 25,
        },
        'embedding': {
          'model': 'text-embedding-ada-002',
          'dimensions': 1536,
          'batchSize': 50,
        },
        'metadata': {'category': 'test', 'priority': 1},
      };

      final source = KnowledgeSource.fromJson(json);
      final output = source.toJson();

      expect(output['id'], equals('src-full'));
      expect(output['name'], equals('Full Source'));
      expect(output['description'], equals('A full knowledge source'));
      expect(output['type'], equals('api'));
      expect(output['documents'], isNotNull);
      expect((output['documents'] as List).length, equals(1));
      expect(output['reference'], isNotNull);
      expect(output['chunking'], isNotNull);
      expect(output['embedding'], isNotNull);
      expect(output['metadata'], equals({'category': 'test', 'priority': 1}));
    });

    test('toJson includes metadata only when non-empty', () {
      const withMeta = KnowledgeSource(
        id: 'x',
        name: 'X',
        type: KnowledgeSourceType.web,
        metadata: {'key': 'value'},
      );
      const withoutMeta = KnowledgeSource(
        id: 'y',
        name: 'Y',
        type: KnowledgeSourceType.web,
      );

      expect(withMeta.toJson().containsKey('metadata'), isTrue);
      expect(withoutMeta.toJson().containsKey('metadata'), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // KnowledgeSourceType
  // ─────────────────────────────────────────────────────────────────
  group('KnowledgeSourceType', () {
    test('fromString parses "documents"', () {
      expect(KnowledgeSourceType.fromString('documents'),
          equals(KnowledgeSourceType.documents));
    });

    test('fromString parses "web"', () {
      expect(KnowledgeSourceType.fromString('web'),
          equals(KnowledgeSourceType.web));
    });

    test('fromString parses "api"', () {
      expect(KnowledgeSourceType.fromString('api'),
          equals(KnowledgeSourceType.api));
    });

    test('fromString parses "database"', () {
      expect(KnowledgeSourceType.fromString('database'),
          equals(KnowledgeSourceType.database));
    });

    test('fromString parses "directory"', () {
      expect(KnowledgeSourceType.fromString('directory'),
          equals(KnowledgeSourceType.directory));
    });

    test('fromString parses "git"', () {
      expect(KnowledgeSourceType.fromString('git'),
          equals(KnowledgeSourceType.git));
    });

    test('fromString returns unknown for unrecognized value', () {
      expect(KnowledgeSourceType.fromString('foobar'),
          equals(KnowledgeSourceType.unknown));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // KnowledgeDocument
  // ─────────────────────────────────────────────────────────────────
  group('KnowledgeDocument', () {
    test('fromJson with minimal fields', () {
      final doc = KnowledgeDocument.fromJson({
        'content': 'Some content',
      });

      expect(doc.content, equals('Some content'));
      expect(doc.format, equals(DocumentFormat.text));
      expect(doc.id, isNull);
      expect(doc.title, isNull);
      expect(doc.source, isNull);
      expect(doc.metadata, isEmpty);
    });

    test('fromJson with empty JSON uses defaults', () {
      final doc = KnowledgeDocument.fromJson({});

      expect(doc.content, equals(''));
      expect(doc.format, equals(DocumentFormat.text));
      expect(doc.metadata, isEmpty);
    });

    test('toJson with minimal fields omits optional fields', () {
      const doc = KnowledgeDocument(content: 'Hello');
      final json = doc.toJson();

      expect(json['content'], equals('Hello'));
      expect(json['format'], equals('text'));
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('title'), isFalse);
      expect(json.containsKey('source'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('fromJson → toJson roundtrip with all fields', () {
      final json = {
        'id': 'doc-1',
        'title': 'Test Document',
        'content': 'Document content here',
        'format': 'markdown',
        'source': '/path/to/file.md',
        'metadata': {'author': 'alice', 'version': 2},
      };

      final doc = KnowledgeDocument.fromJson(json);
      final output = doc.toJson();

      expect(output['id'], equals('doc-1'));
      expect(output['title'], equals('Test Document'));
      expect(output['content'], equals('Document content here'));
      expect(output['format'], equals('markdown'));
      expect(output['source'], equals('/path/to/file.md'));
      expect(output['metadata'], equals({'author': 'alice', 'version': 2}));
    });

    test('format defaults to text when not specified in constructor', () {
      const doc = KnowledgeDocument(content: 'test');
      expect(doc.format, equals(DocumentFormat.text));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // DocumentFormat
  // ─────────────────────────────────────────────────────────────────
  group('DocumentFormat', () {
    test('fromString parses "text"', () {
      expect(DocumentFormat.fromString('text'), equals(DocumentFormat.text));
    });

    test('fromString parses "markdown"', () {
      expect(
          DocumentFormat.fromString('markdown'), equals(DocumentFormat.markdown));
    });

    test('fromString parses "html"', () {
      expect(DocumentFormat.fromString('html'), equals(DocumentFormat.html));
    });

    test('fromString parses "json"', () {
      expect(DocumentFormat.fromString('json'), equals(DocumentFormat.json));
    });

    test('fromString parses "xml"', () {
      expect(DocumentFormat.fromString('xml'), equals(DocumentFormat.xml));
    });

    test('fromString parses "pdf"', () {
      expect(DocumentFormat.fromString('pdf'), equals(DocumentFormat.pdf));
    });

    test('fromString returns unknown for unrecognized value', () {
      expect(
          DocumentFormat.fromString('docx'), equals(DocumentFormat.unknown));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // SourceReference
  // ─────────────────────────────────────────────────────────────────
  group('SourceReference', () {
    test('fromJson with minimal fields', () {
      final ref = SourceReference.fromJson({
        'type': 'file',
        'uri': '/data/docs',
      });

      expect(ref.type, equals(ReferenceType.file));
      expect(ref.uri, equals('/data/docs'));
      expect(ref.auth, isNull);
      expect(ref.refreshIntervalSec, isNull);
    });

    test('fromJson with empty JSON uses defaults', () {
      final ref = SourceReference.fromJson({});

      expect(ref.type, equals(ReferenceType.file));
      expect(ref.uri, equals(''));
      expect(ref.auth, isNull);
      expect(ref.refreshIntervalSec, isNull);
    });

    test('toJson with minimal fields omits optional fields', () {
      const ref = SourceReference(
        type: ReferenceType.url,
        uri: 'https://example.com',
      );
      final json = ref.toJson();

      expect(json['type'], equals('url'));
      expect(json['uri'], equals('https://example.com'));
      expect(json.containsKey('auth'), isFalse);
      expect(json.containsKey('refreshIntervalSec'), isFalse);
    });

    test('fromJson → toJson roundtrip with auth and refreshIntervalSec', () {
      final json = {
        'type': 'api',
        'uri': 'https://api.example.com/docs',
        'auth': {
          'type': 'bearer',
          'config': {'token': 'abc123'},
        },
        'refreshIntervalSec': 3600,
      };

      final ref = SourceReference.fromJson(json);
      final output = ref.toJson();

      expect(output['type'], equals('api'));
      expect(output['uri'], equals('https://api.example.com/docs'));
      expect(output['auth'], isNotNull);
      expect((output['auth'] as Map)['type'], equals('bearer'));
      expect(output['refreshIntervalSec'], equals(3600));
    });

    test('fromJson → toJson roundtrip preserves all reference types', () {
      for (final typeName in ['file', 'url', 'api', 'database', 's3', 'gcs']) {
        final ref = SourceReference.fromJson({
          'type': typeName,
          'uri': 'test://$typeName',
        });
        final output = ref.toJson();
        expect(output['type'], equals(typeName));
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // ReferenceType
  // ─────────────────────────────────────────────────────────────────
  group('ReferenceType', () {
    test('fromString parses "file"', () {
      expect(ReferenceType.fromString('file'), equals(ReferenceType.file));
    });

    test('fromString parses "url"', () {
      expect(ReferenceType.fromString('url'), equals(ReferenceType.url));
    });

    test('fromString parses "api"', () {
      expect(ReferenceType.fromString('api'), equals(ReferenceType.api));
    });

    test('fromString parses "database"', () {
      expect(
          ReferenceType.fromString('database'), equals(ReferenceType.database));
    });

    test('fromString parses "s3"', () {
      expect(ReferenceType.fromString('s3'), equals(ReferenceType.s3));
    });

    test('fromString parses "gcs"', () {
      expect(ReferenceType.fromString('gcs'), equals(ReferenceType.gcs));
    });

    test('fromString returns unknown for unrecognized value', () {
      expect(
          ReferenceType.fromString('azure'), equals(ReferenceType.unknown));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // AuthConfig
  // ─────────────────────────────────────────────────────────────────
  group('AuthConfig', () {
    test('fromJson with minimal fields', () {
      final auth = AuthConfig.fromJson({'type': 'apiKey'});

      expect(auth.type, equals(AuthType.apiKey));
      expect(auth.config, isEmpty);
    });

    test('fromJson with empty JSON uses defaults', () {
      final auth = AuthConfig.fromJson({});

      expect(auth.type, equals(AuthType.none));
      expect(auth.config, isEmpty);
    });

    test('toJson omits config when empty', () {
      const auth = AuthConfig(type: AuthType.basic);
      final json = auth.toJson();

      expect(json['type'], equals('basic'));
      expect(json.containsKey('config'), isFalse);
    });

    test('fromJson → toJson roundtrip with config', () {
      final json = {
        'type': 'oauth2',
        'config': {
          'clientId': 'my-client',
          'clientSecret': 'secret',
          'tokenUrl': 'https://auth.example.com/token',
        },
      };

      final auth = AuthConfig.fromJson(json);
      final output = auth.toJson();

      expect(output['type'], equals('oauth2'));
      expect(output['config'], isNotNull);
      expect((output['config'] as Map)['clientId'], equals('my-client'));
      expect((output['config'] as Map)['clientSecret'], equals('secret'));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // AuthType
  // ─────────────────────────────────────────────────────────────────
  group('AuthType', () {
    test('fromString parses "none"', () {
      expect(AuthType.fromString('none'), equals(AuthType.none));
    });

    test('fromString parses "apiKey"', () {
      expect(AuthType.fromString('apiKey'), equals(AuthType.apiKey));
    });

    test('fromString parses "basic"', () {
      expect(AuthType.fromString('basic'), equals(AuthType.basic));
    });

    test('fromString parses "bearer"', () {
      expect(AuthType.fromString('bearer'), equals(AuthType.bearer));
    });

    test('fromString parses "oauth2"', () {
      expect(AuthType.fromString('oauth2'), equals(AuthType.oauth2));
    });

    test('fromString parses "custom"', () {
      expect(AuthType.fromString('custom'), equals(AuthType.custom));
    });

    test('fromString returns unknown for unrecognized value', () {
      expect(AuthType.fromString('kerberos'), equals(AuthType.unknown));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // ChunkingConfig
  // ─────────────────────────────────────────────────────────────────
  group('ChunkingConfig', () {
    test('fromJson with empty JSON uses defaults', () {
      final config = ChunkingConfig.fromJson({});

      expect(config.strategy, equals(ChunkingStrategy.fixedSize));
      expect(config.chunkSize, equals(512));
      expect(config.chunkOverlap, equals(50));
      expect(config.separator, isNull);
    });

    test('constructor defaults match fromJson defaults', () {
      const config = ChunkingConfig();

      expect(config.strategy, equals(ChunkingStrategy.fixedSize));
      expect(config.chunkSize, equals(512));
      expect(config.chunkOverlap, equals(50));
      expect(config.separator, isNull);
    });

    test('toJson omits separator when null', () {
      const config = ChunkingConfig();
      final json = config.toJson();

      expect(json['strategy'], equals('fixedSize'));
      expect(json['chunkSize'], equals(512));
      expect(json['chunkOverlap'], equals(50));
      expect(json.containsKey('separator'), isFalse);
    });

    test('fromJson → toJson roundtrip with all fields', () {
      final json = {
        'strategy': 'paragraph',
        'chunkSize': 1024,
        'chunkOverlap': 100,
        'separator': '\n\n',
      };

      final config = ChunkingConfig.fromJson(json);
      final output = config.toJson();

      expect(output['strategy'], equals('paragraph'));
      expect(output['chunkSize'], equals(1024));
      expect(output['chunkOverlap'], equals(100));
      expect(output['separator'], equals('\n\n'));
    });

    test('fromJson with custom values overrides defaults', () {
      final config = ChunkingConfig.fromJson({
        'strategy': 'semantic',
        'chunkSize': 2048,
        'chunkOverlap': 200,
      });

      expect(config.strategy, equals(ChunkingStrategy.semantic));
      expect(config.chunkSize, equals(2048));
      expect(config.chunkOverlap, equals(200));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // ChunkingStrategy
  // ─────────────────────────────────────────────────────────────────
  group('ChunkingStrategy', () {
    test('fromString parses "fixedSize"', () {
      expect(ChunkingStrategy.fromString('fixedSize'),
          equals(ChunkingStrategy.fixedSize));
    });

    test('fromString parses "sentence"', () {
      expect(ChunkingStrategy.fromString('sentence'),
          equals(ChunkingStrategy.sentence));
    });

    test('fromString parses "paragraph"', () {
      expect(ChunkingStrategy.fromString('paragraph'),
          equals(ChunkingStrategy.paragraph));
    });

    test('fromString parses "semantic"', () {
      expect(ChunkingStrategy.fromString('semantic'),
          equals(ChunkingStrategy.semantic));
    });

    test('fromString parses "recursive"', () {
      expect(ChunkingStrategy.fromString('recursive'),
          equals(ChunkingStrategy.recursive));
    });

    test('fromString returns unknown for unrecognized value', () {
      expect(ChunkingStrategy.fromString('custom'),
          equals(ChunkingStrategy.unknown));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // EmbeddingConfig
  // ─────────────────────────────────────────────────────────────────
  group('EmbeddingConfig', () {
    test('fromJson with empty JSON uses defaults', () {
      final config = EmbeddingConfig.fromJson({});

      expect(config.model, equals('text-embedding-3-small'));
      expect(config.dimensions, isNull);
      expect(config.batchSize, equals(100));
    });

    test('constructor defaults for batchSize', () {
      const config = EmbeddingConfig(model: 'my-model');

      expect(config.batchSize, equals(100));
      expect(config.dimensions, isNull);
    });

    test('toJson omits dimensions when null', () {
      const config = EmbeddingConfig(model: 'my-model');
      final json = config.toJson();

      expect(json['model'], equals('my-model'));
      expect(json['batchSize'], equals(100));
      expect(json.containsKey('dimensions'), isFalse);
    });

    test('fromJson → toJson roundtrip with all fields', () {
      final json = {
        'model': 'text-embedding-ada-002',
        'dimensions': 1536,
        'batchSize': 50,
      };

      final config = EmbeddingConfig.fromJson(json);
      final output = config.toJson();

      expect(output['model'], equals('text-embedding-ada-002'));
      expect(output['dimensions'], equals(1536));
      expect(output['batchSize'], equals(50));
    });

    test('fromJson with custom model and batchSize', () {
      final config = EmbeddingConfig.fromJson({
        'model': 'cohere-embed-v3',
        'batchSize': 200,
      });

      expect(config.model, equals('cohere-embed-v3'));
      expect(config.batchSize, equals(200));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // RetrieverConfig
  // ─────────────────────────────────────────────────────────────────
  group('RetrieverConfig', () {
    test('fromJson with empty JSON uses defaults', () {
      final config = RetrieverConfig.fromJson({});

      expect(config.mode, equals(RetrievalMode.similarity));
      expect(config.topK, equals(5));
      expect(config.minScore, isNull);
      expect(config.rerank, isNull);
      expect(config.hybridWeights, isNull);
    });

    test('constructor defaults match fromJson defaults', () {
      const config = RetrieverConfig();

      expect(config.mode, equals(RetrievalMode.similarity));
      expect(config.topK, equals(5));
      expect(config.minScore, isNull);
      expect(config.rerank, isNull);
      expect(config.hybridWeights, isNull);
    });

    test('toJson with defaults omits optional fields', () {
      const config = RetrieverConfig();
      final json = config.toJson();

      expect(json['mode'], equals('similarity'));
      expect(json['topK'], equals(5));
      expect(json.containsKey('minScore'), isFalse);
      expect(json.containsKey('rerank'), isFalse);
      expect(json.containsKey('hybridWeights'), isFalse);
    });

    test('fromJson → toJson roundtrip with all fields', () {
      final json = {
        'mode': 'hybrid',
        'topK': 10,
        'minScore': 0.75,
        'rerank': {
          'model': 'cross-encoder/ms-marco',
          'topN': 5,
        },
        'hybridWeights': {
          'semantic': 0.6,
          'keyword': 0.4,
        },
      };

      final config = RetrieverConfig.fromJson(json);
      final output = config.toJson();

      expect(output['mode'], equals('hybrid'));
      expect(output['topK'], equals(10));
      expect(output['minScore'], equals(0.75));
      expect(output['rerank'], isNotNull);
      expect((output['rerank'] as Map)['model'],
          equals('cross-encoder/ms-marco'));
      expect((output['rerank'] as Map)['topN'], equals(5));
      expect(output['hybridWeights'], isNotNull);
      expect((output['hybridWeights'] as Map)['semantic'], equals(0.6));
      expect((output['hybridWeights'] as Map)['keyword'], equals(0.4));
    });

    test('fromJson with rerank only', () {
      final config = RetrieverConfig.fromJson({
        'mode': 'similarity',
        'rerank': {
          'model': 'reranker-v1',
          'topN': 3,
        },
      });

      expect(config.rerank, isNotNull);
      expect(config.rerank!.model, equals('reranker-v1'));
      expect(config.rerank!.topN, equals(3));
      expect(config.hybridWeights, isNull);
    });

    test('fromJson with hybridWeights only', () {
      final config = RetrieverConfig.fromJson({
        'mode': 'hybrid',
        'hybridWeights': {
          'semantic': 0.8,
          'keyword': 0.2,
        },
      });

      expect(config.hybridWeights, isNotNull);
      expect(config.hybridWeights!.semantic, equals(0.8));
      expect(config.hybridWeights!.keyword, equals(0.2));
      expect(config.rerank, isNull);
    });

    test('fromJson parses minScore as double from num', () {
      final config = RetrieverConfig.fromJson({
        'minScore': 1,
      });

      expect(config.minScore, equals(1.0));
      expect(config.minScore, isA<double>());
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // RetrievalMode
  // ─────────────────────────────────────────────────────────────────
  group('RetrievalMode', () {
    test('fromString parses "similarity"', () {
      expect(RetrievalMode.fromString('similarity'),
          equals(RetrievalMode.similarity));
    });

    test('fromString parses "keyword"', () {
      expect(
          RetrievalMode.fromString('keyword'), equals(RetrievalMode.keyword));
    });

    test('fromString parses "hybrid"', () {
      expect(
          RetrievalMode.fromString('hybrid'), equals(RetrievalMode.hybrid));
    });

    test('fromString parses "mmr"', () {
      expect(RetrievalMode.fromString('mmr'), equals(RetrievalMode.mmr));
    });

    test('fromString returns unknown for unrecognized value', () {
      expect(RetrievalMode.fromString('bm25'), equals(RetrievalMode.unknown));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // RerankConfig
  // ─────────────────────────────────────────────────────────────────
  group('RerankConfig', () {
    test('fromJson with all fields', () {
      final config = RerankConfig.fromJson({
        'model': 'cross-encoder/ms-marco',
        'topN': 5,
      });

      expect(config.model, equals('cross-encoder/ms-marco'));
      expect(config.topN, equals(5));
    });

    test('fromJson with empty JSON uses defaults', () {
      final config = RerankConfig.fromJson({});

      expect(config.model, equals(''));
      expect(config.topN, equals(3));
    });

    test('toJson includes all fields', () {
      const config = RerankConfig(model: 'reranker-v2', topN: 7);
      final json = config.toJson();

      expect(json['model'], equals('reranker-v2'));
      expect(json['topN'], equals(7));
    });

    test('fromJson → toJson roundtrip', () {
      final original = {'model': 'bge-reranker', 'topN': 10};

      final config = RerankConfig.fromJson(original);
      final output = config.toJson();

      expect(output['model'], equals('bge-reranker'));
      expect(output['topN'], equals(10));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // HybridWeights
  // ─────────────────────────────────────────────────────────────────
  group('HybridWeights', () {
    test('fromJson with empty JSON uses defaults', () {
      final weights = HybridWeights.fromJson({});

      expect(weights.semantic, equals(0.7));
      expect(weights.keyword, equals(0.3));
    });

    test('constructor defaults', () {
      const weights = HybridWeights();

      expect(weights.semantic, equals(0.7));
      expect(weights.keyword, equals(0.3));
    });

    test('toJson includes both fields', () {
      const weights = HybridWeights();
      final json = weights.toJson();

      expect(json['semantic'], equals(0.7));
      expect(json['keyword'], equals(0.3));
    });

    test('fromJson → toJson roundtrip with custom values', () {
      final json = {
        'semantic': 0.5,
        'keyword': 0.5,
      };

      final weights = HybridWeights.fromJson(json);
      final output = weights.toJson();

      expect(output['semantic'], equals(0.5));
      expect(output['keyword'], equals(0.5));
    });

    test('fromJson handles int values by converting to double', () {
      final weights = HybridWeights.fromJson({
        'semantic': 1,
        'keyword': 0,
      });

      expect(weights.semantic, equals(1.0));
      expect(weights.semantic, isA<double>());
      expect(weights.keyword, equals(0.0));
      expect(weights.keyword, isA<double>());
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // IndexConfig
  // ─────────────────────────────────────────────────────────────────
  group('IndexConfig', () {
    test('fromJson with empty JSON uses defaults', () {
      final config = IndexConfig.fromJson({});

      expect(config.type, equals(IndexType.memory));
      expect(config.config, isEmpty);
      expect(config.persist, isFalse);
      expect(config.path, isNull);
    });

    test('constructor defaults match fromJson defaults', () {
      const config = IndexConfig();

      expect(config.type, equals(IndexType.memory));
      expect(config.config, isEmpty);
      expect(config.persist, isFalse);
      expect(config.path, isNull);
    });

    test('toJson with defaults omits optional fields', () {
      const config = IndexConfig();
      final json = config.toJson();

      expect(json['type'], equals('memory'));
      expect(json.containsKey('config'), isFalse);
      expect(json.containsKey('persist'), isFalse);
      expect(json.containsKey('path'), isFalse);
    });

    test('toJson includes persist only when true', () {
      const withPersist = IndexConfig(persist: true);
      const withoutPersist = IndexConfig(persist: false);

      expect(withPersist.toJson().containsKey('persist'), isTrue);
      expect(withPersist.toJson()['persist'], isTrue);
      expect(withoutPersist.toJson().containsKey('persist'), isFalse);
    });

    test('toJson includes config only when non-empty', () {
      const withConfig = IndexConfig(config: {'region': 'us-east-1'});
      const withoutConfig = IndexConfig();

      expect(withConfig.toJson().containsKey('config'), isTrue);
      expect(withoutConfig.toJson().containsKey('config'), isFalse);
    });

    test('fromJson → toJson roundtrip with all fields', () {
      final json = {
        'type': 'pinecone',
        'config': {
          'apiKey': 'pk-xxxx',
          'environment': 'us-east-1',
          'indexName': 'knowledge-base',
        },
        'persist': true,
        'path': '/data/pinecone-cache',
      };

      final config = IndexConfig.fromJson(json);
      final output = config.toJson();

      expect(output['type'], equals('pinecone'));
      expect(output['config'], isNotNull);
      expect((output['config'] as Map)['indexName'], equals('knowledge-base'));
      expect(output['persist'], isTrue);
      expect(output['path'], equals('/data/pinecone-cache'));
    });

    test('fromJson with various index types', () {
      for (final typeName in [
        'memory',
        'faiss',
        'pinecone',
        'qdrant',
        'weaviate',
        'chroma',
      ]) {
        final config = IndexConfig.fromJson({'type': typeName});
        expect(config.type.name, equals(typeName));
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // IndexType
  // ─────────────────────────────────────────────────────────────────
  group('IndexType', () {
    test('fromString parses "memory"', () {
      expect(IndexType.fromString('memory'), equals(IndexType.memory));
    });

    test('fromString parses "faiss"', () {
      expect(IndexType.fromString('faiss'), equals(IndexType.faiss));
    });

    test('fromString parses "pinecone"', () {
      expect(IndexType.fromString('pinecone'), equals(IndexType.pinecone));
    });

    test('fromString parses "qdrant"', () {
      expect(IndexType.fromString('qdrant'), equals(IndexType.qdrant));
    });

    test('fromString parses "weaviate"', () {
      expect(IndexType.fromString('weaviate'), equals(IndexType.weaviate));
    });

    test('fromString parses "chroma"', () {
      expect(IndexType.fromString('chroma'), equals(IndexType.chroma));
    });

    test('fromString returns unknown for unrecognized value', () {
      expect(IndexType.fromString('elasticsearch'), equals(IndexType.unknown));
    });
  });
}
