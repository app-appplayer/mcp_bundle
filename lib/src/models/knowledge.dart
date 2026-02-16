/// Knowledge Section model for MCP Bundle.
///
/// Contains knowledge sources for RAG (Retrieval Augmented Generation).
library;

/// Knowledge section containing knowledge sources.
class KnowledgeSection {
  /// Schema version for knowledge section.
  final String schemaVersion;

  /// Knowledge sources.
  final List<KnowledgeSource> sources;

  /// Retriever configuration.
  final RetrieverConfig? retriever;

  /// Index configuration.
  final IndexConfig? index;

  const KnowledgeSection({
    this.schemaVersion = '1.0.0',
    this.sources = const [],
    this.retriever,
    this.index,
  });

  factory KnowledgeSection.fromJson(Map<String, dynamic> json) {
    return KnowledgeSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      sources: (json['sources'] as List<dynamic>?)
              ?.map((e) => KnowledgeSource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      retriever: json['retriever'] != null
          ? RetrieverConfig.fromJson(json['retriever'] as Map<String, dynamic>)
          : null,
      index: json['index'] != null
          ? IndexConfig.fromJson(json['index'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      if (sources.isNotEmpty)
        'sources': sources.map((s) => s.toJson()).toList(),
      if (retriever != null) 'retriever': retriever!.toJson(),
      if (index != null) 'index': index!.toJson(),
    };
  }

  /// Get source by ID.
  KnowledgeSource? getSource(String sourceId) {
    return sources.where((s) => s.id == sourceId).firstOrNull;
  }
}

/// Knowledge source definition.
class KnowledgeSource {
  /// Source identifier.
  final String id;

  /// Source name.
  final String name;

  /// Source description.
  final String? description;

  /// Source type.
  final KnowledgeSourceType type;

  /// Source content (for inline sources).
  final List<KnowledgeDocument>? documents;

  /// Source reference (for external sources).
  final SourceReference? reference;

  /// Chunking configuration.
  final ChunkingConfig? chunking;

  /// Embedding configuration.
  final EmbeddingConfig? embedding;

  /// Source metadata.
  final Map<String, dynamic> metadata;

  const KnowledgeSource({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.documents,
    this.reference,
    this.chunking,
    this.embedding,
    this.metadata = const {},
  });

  factory KnowledgeSource.fromJson(Map<String, dynamic> json) {
    return KnowledgeSource(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      type: KnowledgeSourceType.fromString(json['type'] as String? ?? 'documents'),
      documents: (json['documents'] as List<dynamic>?)
          ?.map((e) => KnowledgeDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
      reference: json['reference'] != null
          ? SourceReference.fromJson(json['reference'] as Map<String, dynamic>)
          : null,
      chunking: json['chunking'] != null
          ? ChunkingConfig.fromJson(json['chunking'] as Map<String, dynamic>)
          : null,
      embedding: json['embedding'] != null
          ? EmbeddingConfig.fromJson(json['embedding'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'type': type.name,
      if (documents != null)
        'documents': documents!.map((d) => d.toJson()).toList(),
      if (reference != null) 'reference': reference!.toJson(),
      if (chunking != null) 'chunking': chunking!.toJson(),
      if (embedding != null) 'embedding': embedding!.toJson(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}

/// Knowledge source types.
enum KnowledgeSourceType {
  /// Document collection.
  documents,

  /// Web pages.
  web,

  /// API endpoint.
  api,

  /// Database.
  database,

  /// File directory.
  directory,

  /// Git repository.
  git,

  /// Unknown type.
  unknown;

  static KnowledgeSourceType fromString(String value) {
    return KnowledgeSourceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => KnowledgeSourceType.unknown,
    );
  }
}

/// Knowledge document.
class KnowledgeDocument {
  /// Document identifier.
  final String? id;

  /// Document title.
  final String? title;

  /// Document content.
  final String content;

  /// Document format.
  final DocumentFormat format;

  /// Source URL or path.
  final String? source;

  /// Document metadata.
  final Map<String, dynamic> metadata;

  const KnowledgeDocument({
    this.id,
    this.title,
    required this.content,
    this.format = DocumentFormat.text,
    this.source,
    this.metadata = const {},
  });

  factory KnowledgeDocument.fromJson(Map<String, dynamic> json) {
    return KnowledgeDocument(
      id: json['id'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
      format: DocumentFormat.fromString(json['format'] as String? ?? 'text'),
      source: json['source'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      'content': content,
      'format': format.name,
      if (source != null) 'source': source,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}

/// Document formats.
enum DocumentFormat {
  text,
  markdown,
  html,
  json,
  xml,
  pdf,
  unknown;

  static DocumentFormat fromString(String value) {
    return DocumentFormat.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DocumentFormat.unknown,
    );
  }
}

/// Source reference for external sources.
class SourceReference {
  /// Reference type.
  final ReferenceType type;

  /// Reference URL or path.
  final String uri;

  /// Authentication configuration.
  final AuthConfig? auth;

  /// Refresh interval in seconds.
  final int? refreshIntervalSec;

  const SourceReference({
    required this.type,
    required this.uri,
    this.auth,
    this.refreshIntervalSec,
  });

  factory SourceReference.fromJson(Map<String, dynamic> json) {
    return SourceReference(
      type: ReferenceType.fromString(json['type'] as String? ?? 'file'),
      uri: json['uri'] as String? ?? '',
      auth: json['auth'] != null
          ? AuthConfig.fromJson(json['auth'] as Map<String, dynamic>)
          : null,
      refreshIntervalSec: json['refreshIntervalSec'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'uri': uri,
      if (auth != null) 'auth': auth!.toJson(),
      if (refreshIntervalSec != null) 'refreshIntervalSec': refreshIntervalSec,
    };
  }
}

/// Reference types.
enum ReferenceType {
  file,
  url,
  api,
  database,
  s3,
  gcs,
  unknown;

  static ReferenceType fromString(String value) {
    return ReferenceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReferenceType.unknown,
    );
  }
}

/// Authentication configuration.
class AuthConfig {
  /// Auth type.
  final AuthType type;

  /// Auth configuration.
  final Map<String, dynamic> config;

  const AuthConfig({
    required this.type,
    this.config = const {},
  });

  factory AuthConfig.fromJson(Map<String, dynamic> json) {
    return AuthConfig(
      type: AuthType.fromString(json['type'] as String? ?? 'none'),
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (config.isNotEmpty) 'config': config,
    };
  }
}

/// Authentication types.
enum AuthType {
  none,
  apiKey,
  basic,
  bearer,
  oauth2,
  custom,
  unknown;

  static AuthType fromString(String value) {
    return AuthType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AuthType.unknown,
    );
  }
}

/// Chunking configuration.
class ChunkingConfig {
  /// Chunking strategy.
  final ChunkingStrategy strategy;

  /// Chunk size.
  final int chunkSize;

  /// Chunk overlap.
  final int chunkOverlap;

  /// Separator pattern.
  final String? separator;

  const ChunkingConfig({
    this.strategy = ChunkingStrategy.fixedSize,
    this.chunkSize = 512,
    this.chunkOverlap = 50,
    this.separator,
  });

  factory ChunkingConfig.fromJson(Map<String, dynamic> json) {
    return ChunkingConfig(
      strategy: ChunkingStrategy.fromString(
          json['strategy'] as String? ?? 'fixedSize'),
      chunkSize: json['chunkSize'] as int? ?? 512,
      chunkOverlap: json['chunkOverlap'] as int? ?? 50,
      separator: json['separator'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'strategy': strategy.name,
      'chunkSize': chunkSize,
      'chunkOverlap': chunkOverlap,
      if (separator != null) 'separator': separator,
    };
  }
}

/// Chunking strategies.
enum ChunkingStrategy {
  fixedSize,
  sentence,
  paragraph,
  semantic,
  recursive,
  unknown;

  static ChunkingStrategy fromString(String value) {
    return ChunkingStrategy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChunkingStrategy.unknown,
    );
  }
}

/// Embedding configuration.
class EmbeddingConfig {
  /// Embedding model.
  final String model;

  /// Embedding dimensions.
  final int? dimensions;

  /// Batch size.
  final int batchSize;

  const EmbeddingConfig({
    required this.model,
    this.dimensions,
    this.batchSize = 100,
  });

  factory EmbeddingConfig.fromJson(Map<String, dynamic> json) {
    return EmbeddingConfig(
      model: json['model'] as String? ?? 'text-embedding-3-small',
      dimensions: json['dimensions'] as int?,
      batchSize: json['batchSize'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      if (dimensions != null) 'dimensions': dimensions,
      'batchSize': batchSize,
    };
  }
}

/// Retriever configuration.
class RetrieverConfig {
  /// Retrieval mode.
  final RetrievalMode mode;

  /// Top K results.
  final int topK;

  /// Minimum score threshold.
  final double? minScore;

  /// Reranking configuration.
  final RerankConfig? rerank;

  /// Hybrid search weights.
  final HybridWeights? hybridWeights;

  const RetrieverConfig({
    this.mode = RetrievalMode.similarity,
    this.topK = 5,
    this.minScore,
    this.rerank,
    this.hybridWeights,
  });

  factory RetrieverConfig.fromJson(Map<String, dynamic> json) {
    return RetrieverConfig(
      mode: RetrievalMode.fromString(json['mode'] as String? ?? 'similarity'),
      topK: json['topK'] as int? ?? 5,
      minScore: (json['minScore'] as num?)?.toDouble(),
      rerank: json['rerank'] != null
          ? RerankConfig.fromJson(json['rerank'] as Map<String, dynamic>)
          : null,
      hybridWeights: json['hybridWeights'] != null
          ? HybridWeights.fromJson(
              json['hybridWeights'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'topK': topK,
      if (minScore != null) 'minScore': minScore,
      if (rerank != null) 'rerank': rerank!.toJson(),
      if (hybridWeights != null) 'hybridWeights': hybridWeights!.toJson(),
    };
  }
}

/// Retrieval modes.
enum RetrievalMode {
  similarity,
  keyword,
  hybrid,
  mmr,
  unknown;

  static RetrievalMode fromString(String value) {
    return RetrievalMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RetrievalMode.unknown,
    );
  }
}

/// Reranking configuration.
class RerankConfig {
  /// Reranking model.
  final String model;

  /// Top N after reranking.
  final int topN;

  const RerankConfig({
    required this.model,
    required this.topN,
  });

  factory RerankConfig.fromJson(Map<String, dynamic> json) {
    return RerankConfig(
      model: json['model'] as String? ?? '',
      topN: json['topN'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'topN': topN,
    };
  }
}

/// Hybrid search weights.
class HybridWeights {
  /// Semantic search weight.
  final double semantic;

  /// Keyword search weight.
  final double keyword;

  const HybridWeights({
    this.semantic = 0.7,
    this.keyword = 0.3,
  });

  factory HybridWeights.fromJson(Map<String, dynamic> json) {
    return HybridWeights(
      semantic: (json['semantic'] as num?)?.toDouble() ?? 0.7,
      keyword: (json['keyword'] as num?)?.toDouble() ?? 0.3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semantic': semantic,
      'keyword': keyword,
    };
  }
}

/// Index configuration.
class IndexConfig {
  /// Index type.
  final IndexType type;

  /// Index-specific configuration.
  final Map<String, dynamic> config;

  /// Whether to persist index.
  final bool persist;

  /// Index path for persistence.
  final String? path;

  const IndexConfig({
    this.type = IndexType.memory,
    this.config = const {},
    this.persist = false,
    this.path,
  });

  factory IndexConfig.fromJson(Map<String, dynamic> json) {
    return IndexConfig(
      type: IndexType.fromString(json['type'] as String? ?? 'memory'),
      config: json['config'] as Map<String, dynamic>? ?? {},
      persist: json['persist'] as bool? ?? false,
      path: json['path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (config.isNotEmpty) 'config': config,
      if (persist) 'persist': persist,
      if (path != null) 'path': path,
    };
  }
}

/// Index types.
enum IndexType {
  memory,
  faiss,
  pinecone,
  qdrant,
  weaviate,
  chroma,
  unknown;

  static IndexType fromString(String value) {
    return IndexType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IndexType.unknown,
    );
  }
}
