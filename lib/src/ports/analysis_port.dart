/// Analysis Port - Unified interface for data analysis operations.
///
/// Provides abstract contracts for analysis specification, execution,
/// artifact management, and alerting that can be used across all MCP
/// knowledge packages.
library;

// ============================================================================
// Enums
// ============================================================================

/// Source type for analysis input data.
enum AnalysisSourceType {
  /// Data from FactGraph.
  factgraph,

  /// Data from MCP I/O subsystem.
  mcpIo,

  /// Data from an external system.
  external,

  /// Data uploaded directly.
  upload;

  /// Parse from string with safe default.
  static AnalysisSourceType fromString(String value) {
    return AnalysisSourceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnalysisSourceType.factgraph,
    );
  }
}

/// Execution mode for an analysis job.
enum AnalysisExecutionMode {
  /// Batch processing of a complete dataset.
  batch,

  /// Streaming incremental processing.
  streaming,

  /// Ad-hoc one-off analysis.
  adhoc;

  /// Parse from string with safe default.
  static AnalysisExecutionMode fromString(String value) {
    return AnalysisExecutionMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnalysisExecutionMode.batch,
    );
  }
}

/// Status of an analysis job.
enum AnalysisJobStatus {
  /// Job is waiting in the queue.
  queued,

  /// Job is currently executing.
  running,

  /// Job finished successfully.
  completed,

  /// Job encountered an error.
  failed,

  /// Job was canceled by the user.
  canceled;

  /// Parse from string with safe default.
  static AnalysisJobStatus fromString(String value) {
    return AnalysisJobStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnalysisJobStatus.queued,
    );
  }
}

/// Type of analysis artifact produced.
enum AnalysisArtifactType {
  /// Single numeric metric value.
  metric,

  /// Time-series data points.
  series,

  /// Tabular data (rows and columns).
  table,

  /// Chart with axes and series.
  chart,

  /// Textual summary with evidence links.
  summary,

  /// Alert rule definition.
  alert,

  /// Trained or fitted model.
  model;

  /// Parse from string with safe default.
  static AnalysisArtifactType fromString(String value) {
    return AnalysisArtifactType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnalysisArtifactType.metric,
    );
  }
}

/// Severity level for analysis alerts.
enum AnalysisAlertSeverity {
  /// Informational alert.
  info,

  /// Warning alert.
  warn,

  /// Critical alert requiring immediate attention.
  critical;

  /// Parse from string with safe default.
  static AnalysisAlertSeverity fromString(String value) {
    return AnalysisAlertSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnalysisAlertSeverity.info,
    );
  }
}

// ============================================================================
// Spec Types
// ============================================================================

/// Metadata associated with an analysis specification.
class AnalysisSpecMetadata {
  /// Author of the specification.
  final String? author;

  /// Tags for categorization and search.
  final List<String> tags;

  /// Human-readable description of the specification.
  final String? description;

  const AnalysisSpecMetadata({
    this.author,
    this.tags = const [],
    this.description,
  });

  /// Create from JSON.
  factory AnalysisSpecMetadata.fromJson(Map<String, dynamic> json) {
    return AnalysisSpecMetadata(
      author: json['author'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      description: json['description'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        if (author != null) 'author': author,
        if (tags.isNotEmpty) 'tags': tags,
        if (description != null) 'description': description,
      };
}

/// Time range for analysis input data.
class AnalysisTimeRange {
  /// Start of the time range (inclusive).
  final DateTime start;

  /// End of the time range (inclusive).
  final DateTime end;

  const AnalysisTimeRange({
    required this.start,
    required this.end,
  });

  /// Create from JSON.
  factory AnalysisTimeRange.fromJson(Map<String, dynamic> json) {
    return AnalysisTimeRange(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      };
}

/// Column metadata for an analysis source schema.
class AnalysisColumnInfo {
  /// Column name.
  final String name;

  /// Column data type (string, int, double, bool, datetime).
  final String type;

  /// Optional unit for the column values.
  final String? unit;

  const AnalysisColumnInfo({
    required this.name,
    required this.type,
    this.unit,
  });

  /// Create from JSON.
  factory AnalysisColumnInfo.fromJson(Map<String, dynamic> json) {
    return AnalysisColumnInfo(
      name: json['name'] as String,
      type: json['type'] as String,
      unit: json['unit'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        if (unit != null) 'unit': unit,
      };
}

/// Schema describing the structure of an analysis input source.
class AnalysisSourceSchema {
  /// Column definitions.
  final List<AnalysisColumnInfo> columns;

  /// Name of the timestamp field, if any.
  final String? timestampField;

  const AnalysisSourceSchema({
    required this.columns,
    this.timestampField,
  });

  /// Create from JSON.
  factory AnalysisSourceSchema.fromJson(Map<String, dynamic> json) {
    return AnalysisSourceSchema(
      columns: (json['columns'] as List<dynamic>)
          .map((e) => AnalysisColumnInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      timestampField: json['timestampField'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'columns': columns.map((c) => c.toJson()).toList(),
        if (timestampField != null) 'timestampField': timestampField,
      };
}

/// Definition of an analysis input source.
class AnalysisInputSource {
  /// Type of the data source.
  final AnalysisSourceType sourceType;

  /// Optional query string for selecting data.
  final String? query;

  /// Optional filter criteria as key-value pairs.
  final Map<String, dynamic>? filter;

  /// Optional time range to restrict input data.
  final AnalysisTimeRange? timeRange;

  /// Optional schema describing the source structure.
  final AnalysisSourceSchema? schema;

  /// Cannot be const due to Map<String, dynamic> field.
  AnalysisInputSource({
    required this.sourceType,
    this.query,
    this.filter,
    this.timeRange,
    this.schema,
  });

  /// Create from JSON.
  factory AnalysisInputSource.fromJson(Map<String, dynamic> json) {
    return AnalysisInputSource(
      sourceType:
          AnalysisSourceType.fromString(json['sourceType'] as String),
      query: json['query'] as String?,
      filter: json['filter'] as Map<String, dynamic>?,
      timeRange: json['timeRange'] != null
          ? AnalysisTimeRange.fromJson(
              json['timeRange'] as Map<String, dynamic>)
          : null,
      schema: json['schema'] != null
          ? AnalysisSourceSchema.fromJson(
              json['schema'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'sourceType': sourceType.name,
        if (query != null) 'query': query,
        if (filter != null) 'filter': filter,
        if (timeRange != null) 'timeRange': timeRange!.toJson(),
        if (schema != null) 'schema': schema!.toJson(),
      };
}

/// A data transformation step applied before analysis.
class AnalysisTransform {
  /// Transform name (filter, resample, join, clip, fillna, sort, convert).
  final String name;

  /// Transform-specific parameters.
  final Map<String, dynamic> parameters;

  /// Cannot be const due to Map<String, dynamic> field.
  AnalysisTransform({
    required this.name,
    required this.parameters,
  });

  /// Create from JSON.
  factory AnalysisTransform.fromJson(Map<String, dynamic> json) {
    return AnalysisTransform(
      name: json['name'] as String,
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'name': name,
        'parameters': parameters,
      };
}

/// An individual analysis computation step.
class AnalysisStep {
  /// Analysis function name (descriptive_stats, anomaly_detect,
  /// event_analysis, etc.).
  final String function;

  /// Function-specific parameters.
  final Map<String, dynamic> parameters;

  /// Cannot be const due to Map<String, dynamic> field.
  AnalysisStep({
    required this.function,
    required this.parameters,
  });

  /// Create from JSON.
  factory AnalysisStep.fromJson(Map<String, dynamic> json) {
    return AnalysisStep(
      function: json['function'] as String,
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'function': function,
        'parameters': parameters,
      };
}

/// Definition of an expected analysis output artifact.
class AnalysisOutputDef {
  /// Type of artifact to produce.
  final AnalysisArtifactType type;

  /// Name for the output artifact.
  final String name;

  /// Optional output-specific parameters.
  final Map<String, dynamic>? parameters;

  /// Cannot be const due to Map<String, dynamic> field.
  AnalysisOutputDef({
    required this.type,
    required this.name,
    this.parameters,
  });

  /// Create from JSON.
  factory AnalysisOutputDef.fromJson(Map<String, dynamic> json) {
    return AnalysisOutputDef(
      type: AnalysisArtifactType.fromString(json['type'] as String),
      name: json['name'] as String,
      parameters: json['parameters'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'name': name,
        if (parameters != null) 'parameters': parameters,
      };
}

/// Complete analysis specification describing inputs, transforms,
/// analysis steps, and expected outputs.
class AnalysisSpec {
  /// Unique specification identifier.
  final String specId;

  /// Specification version string.
  final String version;

  /// Input data sources.
  final List<AnalysisInputSource> inputSources;

  /// Data transformation steps applied before analysis.
  final List<AnalysisTransform> transforms;

  /// Analysis computation steps.
  final List<AnalysisStep> analysisSteps;

  /// Expected output artifact definitions.
  final List<AnalysisOutputDef> outputs;

  /// Global parameters for the analysis.
  final Map<String, dynamic> parameters;

  /// Specification metadata.
  final AnalysisSpecMetadata metadata;

  /// Cannot be const due to Map<String, dynamic> field.
  AnalysisSpec({
    required this.specId,
    required this.version,
    required this.inputSources,
    this.transforms = const [],
    required this.analysisSteps,
    required this.outputs,
    this.parameters = const {},
    required this.metadata,
  });

  /// Create from JSON.
  factory AnalysisSpec.fromJson(Map<String, dynamic> json) {
    return AnalysisSpec(
      specId: json['specId'] as String,
      version: json['version'] as String,
      inputSources: (json['inputSources'] as List<dynamic>)
          .map(
              (e) => AnalysisInputSource.fromJson(e as Map<String, dynamic>))
          .toList(),
      transforms: (json['transforms'] as List<dynamic>?)
              ?.map((e) =>
                  AnalysisTransform.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      analysisSteps: (json['analysisSteps'] as List<dynamic>)
          .map((e) => AnalysisStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      outputs: (json['outputs'] as List<dynamic>)
          .map((e) => AnalysisOutputDef.fromJson(e as Map<String, dynamic>))
          .toList(),
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
      metadata: AnalysisSpecMetadata.fromJson(
          json['metadata'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'specId': specId,
        'version': version,
        'inputSources': inputSources.map((s) => s.toJson()).toList(),
        if (transforms.isNotEmpty)
          'transforms': transforms.map((t) => t.toJson()).toList(),
        'analysisSteps': analysisSteps.map((s) => s.toJson()).toList(),
        'outputs': outputs.map((o) => o.toJson()).toList(),
        if (parameters.isNotEmpty) 'parameters': parameters,
        'metadata': metadata.toJson(),
      };
}

// ============================================================================
// Job Types
// ============================================================================

/// Log entry for an analysis job step execution.
class AnalysisJobLog {
  /// Name of the step that produced this log entry.
  final String step;

  /// Timestamp when the step completed.
  final DateTime timestamp;

  /// Number of input records processed.
  final int inputSize;

  /// Number of output records produced.
  final int outputSize;

  /// Wall-clock execution time for the step.
  final Duration executionTime;

  /// Cannot be const due to Duration field.
  AnalysisJobLog({
    required this.step,
    required this.timestamp,
    required this.inputSize,
    required this.outputSize,
    required this.executionTime,
  });

  /// Create from JSON.
  factory AnalysisJobLog.fromJson(Map<String, dynamic> json) {
    return AnalysisJobLog(
      step: json['step'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      inputSize: json['inputSize'] as int? ?? 0,
      outputSize: json['outputSize'] as int? ?? 0,
      executionTime:
          Duration(milliseconds: json['executionTimeMs'] as int? ?? 0),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'step': step,
        'timestamp': timestamp.toIso8601String(),
        'inputSize': inputSize,
        'outputSize': outputSize,
        'executionTimeMs': executionTime.inMilliseconds,
      };
}

/// Error that occurred during analysis execution.
class AnalysisError {
  /// Error code (e.g., source.unavailable, transform.failed).
  final String code;

  /// Human-readable error message.
  final String message;

  /// Additional error details.
  final Map<String, dynamic>? details;

  /// Name of the step where the error occurred.
  final String? step;

  /// Timestamp when the error occurred.
  final DateTime? timestamp;

  /// Cannot be const due to Map<String, dynamic> field.
  AnalysisError({
    required this.code,
    required this.message,
    this.details,
    this.step,
    this.timestamp,
  });

  /// Create from JSON.
  factory AnalysisError.fromJson(Map<String, dynamic> json) {
    return AnalysisError(
      code: json['code'] as String,
      message: json['message'] as String,
      details: json['details'] as Map<String, dynamic>?,
      step: json['step'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        if (details != null) 'details': details,
        if (step != null) 'step': step,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      };
}

/// Represents a running or completed analysis job.
class AnalysisJob {
  /// Unique job identifier.
  final String jobId;

  /// Identifier of the spec this job executes.
  final String specId;

  /// Version of the spec used.
  final String specVersion;

  /// Execution mode for this job.
  final AnalysisExecutionMode mode;

  /// Current status of the job.
  final AnalysisJobStatus status;

  /// Progress from 0.0 (not started) to 1.0 (complete).
  final double progress;

  /// Timestamp when the job was created.
  final DateTime createdAt;

  /// Timestamp when the job started executing.
  final DateTime? startTime;

  /// Timestamp when the job finished.
  final DateTime? endTime;

  /// Time range of the input data processed.
  final AnalysisTimeRange? inputRange;

  /// Runtime parameters provided for this job.
  final Map<String, dynamic> parameters;

  /// IDs of artifacts produced by this job.
  final List<String> artifactIds;

  /// Step execution logs.
  final List<AnalysisJobLog> logs;

  /// Errors encountered during execution.
  final List<AnalysisError> errors;

  /// Cannot be const due to Map<String, dynamic> field.
  AnalysisJob({
    required this.jobId,
    required this.specId,
    required this.specVersion,
    required this.mode,
    required this.status,
    this.progress = 0.0,
    required this.createdAt,
    this.startTime,
    this.endTime,
    this.inputRange,
    this.parameters = const {},
    this.artifactIds = const [],
    this.logs = const [],
    this.errors = const [],
  });

  /// Create from JSON.
  factory AnalysisJob.fromJson(Map<String, dynamic> json) {
    return AnalysisJob(
      jobId: json['jobId'] as String,
      specId: json['specId'] as String,
      specVersion: json['specVersion'] as String,
      mode: AnalysisExecutionMode.fromString(json['mode'] as String),
      status: AnalysisJobStatus.fromString(json['status'] as String),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      inputRange: json['inputRange'] != null
          ? AnalysisTimeRange.fromJson(
              json['inputRange'] as Map<String, dynamic>)
          : null,
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
      artifactIds: (json['artifactIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      logs: (json['logs'] as List<dynamic>?)
              ?.map(
                  (e) => AnalysisJobLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      errors: (json['errors'] as List<dynamic>?)
              ?.map(
                  (e) => AnalysisError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'specId': specId,
        'specVersion': specVersion,
        'mode': mode.name,
        'status': status.name,
        'progress': progress,
        'createdAt': createdAt.toIso8601String(),
        if (startTime != null) 'startTime': startTime!.toIso8601String(),
        if (endTime != null) 'endTime': endTime!.toIso8601String(),
        if (inputRange != null) 'inputRange': inputRange!.toJson(),
        if (parameters.isNotEmpty) 'parameters': parameters,
        if (artifactIds.isNotEmpty) 'artifactIds': artifactIds,
        if (logs.isNotEmpty)
          'logs': logs.map((l) => l.toJson()).toList(),
        if (errors.isNotEmpty)
          'errors': errors.map((e) => e.toJson()).toList(),
      };
}

// ============================================================================
// Artifact Types
// ============================================================================

/// Provenance metadata for an analysis artifact.
class AnalysisArtifactProvenance {
  /// Version of the artifact.
  final String version;

  /// Tags for categorization.
  final List<String> tags;

  /// Timestamp when the artifact was created.
  final DateTime createdAt;

  /// URI of the data source that produced this artifact.
  final String? sourceUri;

  /// Query used to produce this artifact.
  final String? sourceQuery;

  /// Time range of the input data.
  final AnalysisTimeRange? inputRange;

  /// Identifier of the spec that produced this artifact.
  final String specId;

  /// Version of the spec that produced this artifact.
  final String specVersion;

  const AnalysisArtifactProvenance({
    required this.version,
    this.tags = const [],
    required this.createdAt,
    this.sourceUri,
    this.sourceQuery,
    this.inputRange,
    required this.specId,
    required this.specVersion,
  });

  /// Create from JSON.
  factory AnalysisArtifactProvenance.fromJson(Map<String, dynamic> json) {
    return AnalysisArtifactProvenance(
      version: json['version'] as String,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      sourceUri: json['sourceUri'] as String?,
      sourceQuery: json['sourceQuery'] as String?,
      inputRange: json['inputRange'] != null
          ? AnalysisTimeRange.fromJson(
              json['inputRange'] as Map<String, dynamic>)
          : null,
      specId: json['specId'] as String,
      specVersion: json['specVersion'] as String,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'version': version,
        if (tags.isNotEmpty) 'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        if (sourceUri != null) 'sourceUri': sourceUri,
        if (sourceQuery != null) 'sourceQuery': sourceQuery,
        if (inputRange != null) 'inputRange': inputRange!.toJson(),
        'specId': specId,
        'specVersion': specVersion,
      };
}

/// Base class for analysis artifacts.
///
/// Named AnalysisArtifact to avoid conflict with Artifact in
/// skill_result.dart.
abstract class AnalysisArtifact {
  /// Unique artifact identifier.
  final String artifactId;

  /// Type of this artifact.
  final AnalysisArtifactType type;

  /// Human-readable artifact name.
  final String name;

  /// Provenance metadata describing origin and lineage.
  final AnalysisArtifactProvenance provenance;

  /// Base constructor for subclasses.
  AnalysisArtifact({
    required this.artifactId,
    required this.type,
    required this.name,
    required this.provenance,
  });

  /// Factory that dispatches to the correct subclass based on the 'type'
  /// field in the JSON.
  factory AnalysisArtifact.fromJson(Map<String, dynamic> json) {
    final artifactType =
        AnalysisArtifactType.fromString(json['type'] as String);
    switch (artifactType) {
      case AnalysisArtifactType.metric:
        return AnalysisMetricArtifact.fromJson(json);
      case AnalysisArtifactType.series:
        return AnalysisSeriesArtifact.fromJson(json);
      case AnalysisArtifactType.table:
        return AnalysisTableArtifact.fromJson(json);
      case AnalysisArtifactType.chart:
        return AnalysisChartArtifact.fromJson(json);
      case AnalysisArtifactType.summary:
        return AnalysisSummaryArtifact.fromJson(json);
      case AnalysisArtifactType.alert:
        return AnalysisAlertRuleArtifact.fromJson(json);
      case AnalysisArtifactType.model:
        return AnalysisModelArtifact.fromJson(json);
    }
  }

  /// Convert to JSON. Subclasses must implement this.
  Map<String, dynamic> toJson();

  /// Serialize base fields shared by all artifact types.
  Map<String, dynamic> baseToJson() => {
        'artifactId': artifactId,
        'type': type.name,
        'name': name,
        'provenance': provenance.toJson(),
      };
}

/// A time-indexed data point in a series.
class AnalysisTimePoint {
  /// Timestamp of the data point.
  final DateTime t;

  /// Value at this timestamp.
  final dynamic v;

  /// Cannot be const due to dynamic field.
  AnalysisTimePoint({
    required this.t,
    required this.v,
  });

  /// Create from JSON.
  factory AnalysisTimePoint.fromJson(Map<String, dynamic> json) {
    return AnalysisTimePoint(
      t: DateTime.parse(json['t'] as String),
      v: json['v'],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        't': t.toIso8601String(),
        'v': v,
      };
}

/// Axis metadata for chart artifacts.
class AnalysisAxisMeta {
  /// Axis label text.
  final String label;

  /// Axis scale type (linear, logarithmic, time, category).
  final String type;

  /// Minimum axis value.
  final dynamic min;

  /// Maximum axis value.
  final dynamic max;

  /// Cannot be const due to dynamic fields.
  AnalysisAxisMeta({
    required this.label,
    required this.type,
    this.min,
    this.max,
  });

  /// Create from JSON.
  factory AnalysisAxisMeta.fromJson(Map<String, dynamic> json) {
    return AnalysisAxisMeta(
      label: json['label'] as String,
      type: json['type'] as String,
      min: json['min'],
      max: json['max'],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'label': label,
        'type': type,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
      };
}

/// Evidence link referencing source data for a summary artifact.
class AnalysisEvidenceLink {
  /// URI pointing to the evidence data.
  final String uri;

  /// Optional query that produced the evidence.
  final String? query;

  /// Optional time range of the referenced data.
  final AnalysisTimeRange? dataRange;

  const AnalysisEvidenceLink({
    required this.uri,
    this.query,
    this.dataRange,
  });

  /// Create from JSON.
  factory AnalysisEvidenceLink.fromJson(Map<String, dynamic> json) {
    return AnalysisEvidenceLink(
      uri: json['uri'] as String,
      query: json['query'] as String?,
      dataRange: json['dataRange'] != null
          ? AnalysisTimeRange.fromJson(
              json['dataRange'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'uri': uri,
        if (query != null) 'query': query,
        if (dataRange != null) 'dataRange': dataRange!.toJson(),
      };
}

/// Artifact containing a single numeric metric value.
class AnalysisMetricArtifact extends AnalysisArtifact {
  /// The metric value.
  final dynamic value;

  /// Unit of measurement.
  final String unit;

  /// Time range over which the metric was computed.
  final AnalysisTimeRange timeRange;

  /// Cannot be const due to dynamic field.
  AnalysisMetricArtifact({
    required super.artifactId,
    required super.name,
    required super.provenance,
    required this.value,
    required this.unit,
    required this.timeRange,
  }) : super(type: AnalysisArtifactType.metric);

  /// Create from JSON.
  factory AnalysisMetricArtifact.fromJson(Map<String, dynamic> json) {
    return AnalysisMetricArtifact(
      artifactId: json['artifactId'] as String,
      name: json['name'] as String,
      provenance: AnalysisArtifactProvenance.fromJson(
          json['provenance'] as Map<String, dynamic>),
      value: json['value'],
      unit: json['unit'] as String,
      timeRange: AnalysisTimeRange.fromJson(
          json['timeRange'] as Map<String, dynamic>),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'value': value,
        'unit': unit,
        'timeRange': timeRange.toJson(),
      };
}

/// Artifact containing time-series data points.
class AnalysisSeriesArtifact extends AnalysisArtifact {
  /// Ordered list of time-indexed data points.
  final List<AnalysisTimePoint> points;

  /// Unit of measurement for the series values.
  final String unit;

  AnalysisSeriesArtifact({
    required super.artifactId,
    required super.name,
    required super.provenance,
    required this.points,
    required this.unit,
  }) : super(type: AnalysisArtifactType.series);

  /// Create from JSON.
  factory AnalysisSeriesArtifact.fromJson(Map<String, dynamic> json) {
    return AnalysisSeriesArtifact(
      artifactId: json['artifactId'] as String,
      name: json['name'] as String,
      provenance: AnalysisArtifactProvenance.fromJson(
          json['provenance'] as Map<String, dynamic>),
      points: (json['points'] as List<dynamic>)
          .map((e) => AnalysisTimePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      unit: json['unit'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'points': points.map((p) => p.toJson()).toList(),
        'unit': unit,
      };
}

/// Artifact containing tabular data.
class AnalysisTableArtifact extends AnalysisArtifact {
  /// Column names.
  final List<String> columns;

  /// Row data as a list of column-value maps.
  final List<Map<String, dynamic>> rows;

  /// Optional mapping of column name to unit.
  final Map<String, String>? columnUnits;

  /// Cannot be const due to Map<String, dynamic> in rows.
  AnalysisTableArtifact({
    required super.artifactId,
    required super.name,
    required super.provenance,
    required this.columns,
    required this.rows,
    this.columnUnits,
  }) : super(type: AnalysisArtifactType.table);

  /// Create from JSON.
  factory AnalysisTableArtifact.fromJson(Map<String, dynamic> json) {
    return AnalysisTableArtifact(
      artifactId: json['artifactId'] as String,
      name: json['name'] as String,
      provenance: AnalysisArtifactProvenance.fromJson(
          json['provenance'] as Map<String, dynamic>),
      columns: (json['columns'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      rows: (json['rows'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      columnUnits: (json['columnUnits'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'columns': columns,
        'rows': rows,
        if (columnUnits != null) 'columnUnits': columnUnits,
      };
}

/// Artifact containing chart data with axes and multiple series.
class AnalysisChartArtifact extends AnalysisArtifact {
  /// Data series to plot.
  final List<AnalysisSeriesArtifact> series;

  /// X-axis metadata.
  final AnalysisAxisMeta xAxis;

  /// Y-axis metadata.
  final AnalysisAxisMeta yAxis;

  /// Optional mapping of series name to unit.
  final Map<String, String>? units;

  AnalysisChartArtifact({
    required super.artifactId,
    required super.name,
    required super.provenance,
    required this.series,
    required this.xAxis,
    required this.yAxis,
    this.units,
  }) : super(type: AnalysisArtifactType.chart);

  /// Create from JSON.
  factory AnalysisChartArtifact.fromJson(Map<String, dynamic> json) {
    return AnalysisChartArtifact(
      artifactId: json['artifactId'] as String,
      name: json['name'] as String,
      provenance: AnalysisArtifactProvenance.fromJson(
          json['provenance'] as Map<String, dynamic>),
      series: (json['series'] as List<dynamic>)
          .map((e) =>
              AnalysisSeriesArtifact.fromJson(e as Map<String, dynamic>))
          .toList(),
      xAxis: AnalysisAxisMeta.fromJson(
          json['xAxis'] as Map<String, dynamic>),
      yAxis: AnalysisAxisMeta.fromJson(
          json['yAxis'] as Map<String, dynamic>),
      units: (json['units'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'series': series.map((s) => s.toJson()).toList(),
        'xAxis': xAxis.toJson(),
        'yAxis': yAxis.toJson(),
        if (units != null) 'units': units,
      };
}

/// Artifact containing a textual summary with evidence links.
class AnalysisSummaryArtifact extends AnalysisArtifact {
  /// Summary text.
  final String text;

  /// Links to evidence data supporting the summary.
  final List<AnalysisEvidenceLink> evidenceLinks;

  AnalysisSummaryArtifact({
    required super.artifactId,
    required super.name,
    required super.provenance,
    required this.text,
    this.evidenceLinks = const [],
  }) : super(type: AnalysisArtifactType.summary);

  /// Create from JSON.
  factory AnalysisSummaryArtifact.fromJson(Map<String, dynamic> json) {
    return AnalysisSummaryArtifact(
      artifactId: json['artifactId'] as String,
      name: json['name'] as String,
      provenance: AnalysisArtifactProvenance.fromJson(
          json['provenance'] as Map<String, dynamic>),
      text: json['text'] as String,
      evidenceLinks: (json['evidenceLinks'] as List<dynamic>?)
              ?.map((e) =>
                  AnalysisEvidenceLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'text': text,
        if (evidenceLinks.isNotEmpty)
          'evidenceLinks':
              evidenceLinks.map((l) => l.toJson()).toList(),
      };
}

/// Artifact defining an alert rule with condition and severity.
class AnalysisAlertRuleArtifact extends AnalysisArtifact {
  /// Condition expression (e.g., "temperature > 80").
  final String condition;

  /// Alert severity level.
  final AnalysisAlertSeverity severity;

  /// Optional webhook or action hook URI to invoke on trigger.
  final String? actionHook;

  AnalysisAlertRuleArtifact({
    required super.artifactId,
    required super.name,
    required super.provenance,
    required this.condition,
    required this.severity,
    this.actionHook,
  }) : super(type: AnalysisArtifactType.alert);

  /// Create from JSON.
  factory AnalysisAlertRuleArtifact.fromJson(Map<String, dynamic> json) {
    return AnalysisAlertRuleArtifact(
      artifactId: json['artifactId'] as String,
      name: json['name'] as String,
      provenance: AnalysisArtifactProvenance.fromJson(
          json['provenance'] as Map<String, dynamic>),
      condition: json['condition'] as String,
      severity:
          AnalysisAlertSeverity.fromString(json['severity'] as String),
      actionHook: json['actionHook'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'condition': condition,
        'severity': severity.name,
        if (actionHook != null) 'actionHook': actionHook,
      };
}

/// Artifact containing a trained or fitted model.
class AnalysisModelArtifact extends AnalysisArtifact {
  /// Model parameters.
  final Map<String, dynamic> parameters;

  /// Version of the model.
  final String modelVersion;

  /// Performance metrics (e.g., accuracy, RMSE).
  final Map<String, dynamic> performanceMetrics;

  /// Cannot be const due to Map<String, dynamic> fields.
  AnalysisModelArtifact({
    required super.artifactId,
    required super.name,
    required super.provenance,
    required this.parameters,
    required this.modelVersion,
    required this.performanceMetrics,
  }) : super(type: AnalysisArtifactType.model);

  /// Create from JSON.
  factory AnalysisModelArtifact.fromJson(Map<String, dynamic> json) {
    return AnalysisModelArtifact(
      artifactId: json['artifactId'] as String,
      name: json['name'] as String,
      provenance: AnalysisArtifactProvenance.fromJson(
          json['provenance'] as Map<String, dynamic>),
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
      modelVersion: json['modelVersion'] as String,
      performanceMetrics:
          json['performanceMetrics'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'parameters': parameters,
        'modelVersion': modelVersion,
        'performanceMetrics': performanceMetrics,
      };
}

/// Evaluated alert result indicating whether a condition was triggered.
class AnalysisAlert {
  /// Identifier of the alert rule that was evaluated.
  final String alertRuleId;

  /// Severity of the alert.
  final AnalysisAlertSeverity severity;

  /// Timestamp of the evaluation.
  final DateTime timestamp;

  /// Condition expression that was evaluated.
  final String condition;

  /// Current value that was tested against the condition.
  final dynamic currentValue;

  /// Whether the alert condition was triggered.
  final bool triggered;

  /// Optional action hook URI to invoke if triggered.
  final String? actionHook;

  /// Cannot be const due to dynamic field.
  AnalysisAlert({
    required this.alertRuleId,
    required this.severity,
    required this.timestamp,
    required this.condition,
    required this.currentValue,
    required this.triggered,
    this.actionHook,
  });

  /// Create from JSON.
  factory AnalysisAlert.fromJson(Map<String, dynamic> json) {
    return AnalysisAlert(
      alertRuleId: json['alertRuleId'] as String,
      severity:
          AnalysisAlertSeverity.fromString(json['severity'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      condition: json['condition'] as String,
      currentValue: json['currentValue'],
      triggered: json['triggered'] as bool,
      actionHook: json['actionHook'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'alertRuleId': alertRuleId,
        'severity': severity.name,
        'timestamp': timestamp.toIso8601String(),
        'condition': condition,
        'currentValue': currentValue,
        'triggered': triggered,
        if (actionHook != null) 'actionHook': actionHook,
      };
}

// ============================================================================
// Port Interface
// ============================================================================

/// Abstract port for analysis operations.
///
/// Provides contracts for managing analysis specifications, running analysis
/// jobs, retrieving artifacts, and evaluating alert rules.
abstract class AnalysisPort {
  /// List available analysis specifications.
  Future<List<AnalysisSpec>> listSpecs({
    String? search,
    int? limit,
    int? offset,
  });

  /// Run an analysis job using the given spec and parameters.
  Future<AnalysisJob> runAnalysis({
    required String specId,
    required Map<String, dynamic> parameters,
    AnalysisExecutionMode mode = AnalysisExecutionMode.batch,
    AnalysisTimeRange? timeRange,
  });

  /// Get a job by ID, or null if not found.
  Future<AnalysisJob?> getJob(String jobId);

  /// Get artifacts filtered by various criteria.
  Future<List<AnalysisArtifact>> getArtifacts({
    String? jobId,
    String? specId,
    AnalysisArtifactType? type,
    List<String>? tags,
    AnalysisTimeRange? timeRange,
    int? limit,
  });

  /// Create a new analysis specification.
  Future<AnalysisSpec> createSpec(AnalysisSpec spec);

  /// Update an existing analysis specification.
  Future<AnalysisSpec> updateSpec(String specId, AnalysisSpec spec);

  /// Evaluate an alert rule and return the result.
  Future<AnalysisAlert> evaluateAlert(String alertRuleId);
}

// ============================================================================
// Stub Implementation
// ============================================================================

/// Stub implementation of [AnalysisPort] for testing.
class StubAnalysisPort implements AnalysisPort {
  /// In-memory list of analysis specifications.
  final List<AnalysisSpec> _specs = [];

  /// In-memory map of job ID to analysis job.
  final Map<String, AnalysisJob> _jobs = {};

  @override
  Future<List<AnalysisSpec>> listSpecs({
    String? search,
    int? limit,
    int? offset,
  }) async {
    var results = List<AnalysisSpec>.from(_specs);

    // Apply search filter on specId and description.
    if (search != null && search.isNotEmpty) {
      final query = search.toLowerCase();
      results = results.where((s) {
        final matchId = s.specId.toLowerCase().contains(query);
        final matchDesc =
            s.metadata.description?.toLowerCase().contains(query) ?? false;
        return matchId || matchDesc;
      }).toList();
    }

    // Apply offset.
    if (offset != null && offset > 0 && offset < results.length) {
      results = results.sublist(offset);
    }

    // Apply limit.
    if (limit != null && limit > 0 && limit < results.length) {
      results = results.sublist(0, limit);
    }

    return results;
  }

  @override
  Future<AnalysisJob> runAnalysis({
    required String specId,
    required Map<String, dynamic> parameters,
    AnalysisExecutionMode mode = AnalysisExecutionMode.batch,
    AnalysisTimeRange? timeRange,
  }) async {
    final now = DateTime.now();
    final jobId = 'job_${_jobs.length}';
    final job = AnalysisJob(
      jobId: jobId,
      specId: specId,
      specVersion: '1.0.0',
      mode: mode,
      status: AnalysisJobStatus.completed,
      progress: 1.0,
      createdAt: now,
      startTime: now,
      endTime: now,
      inputRange: timeRange,
      parameters: parameters,
    );
    _jobs[jobId] = job;
    return job;
  }

  @override
  Future<AnalysisJob?> getJob(String jobId) async {
    return _jobs[jobId];
  }

  @override
  Future<List<AnalysisArtifact>> getArtifacts({
    String? jobId,
    String? specId,
    AnalysisArtifactType? type,
    List<String>? tags,
    AnalysisTimeRange? timeRange,
    int? limit,
  }) async {
    return [];
  }

  @override
  Future<AnalysisSpec> createSpec(AnalysisSpec spec) async {
    _specs.add(spec);
    return spec;
  }

  @override
  Future<AnalysisSpec> updateSpec(String specId, AnalysisSpec spec) async {
    final index = _specs.indexWhere((s) => s.specId == specId);
    if (index >= 0) {
      _specs[index] = spec;
    } else {
      _specs.add(spec);
    }
    return spec;
  }

  @override
  Future<AnalysisAlert> evaluateAlert(String alertRuleId) async {
    return AnalysisAlert(
      alertRuleId: alertRuleId,
      severity: AnalysisAlertSeverity.info,
      timestamp: DateTime.now(),
      condition: 'stub_condition',
      currentValue: 0,
      triggered: false,
    );
  }

  /// Clear all stored data (for test reset).
  void clear() {
    _specs.clear();
    _jobs.clear();
  }
}
