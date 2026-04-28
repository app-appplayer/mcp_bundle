/// Analysis Data Source Port - Contract for data source adapters.
///
/// Provides abstract contracts for querying data from various sources
/// (FactGraph, MCP IO, external APIs, uploads) and retrieving source metadata.
library;

import 'analysis_port.dart';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/// Data set returned from a source query.
class AnalysisDataSet {
  /// Column definitions.
  final List<AnalysisColumnInfo> columns;

  /// Row data as list of maps.
  final List<Map<String, dynamic>> rows;

  /// Total number of rows.
  final int rowCount;

  /// Time range of the data, if temporal.
  final AnalysisTimeRange? timeRange;

  /// Additional metadata about the data set.
  final Map<String, dynamic>? metadata;

  // Not const - contains List<Map<String, dynamic>> and Map<String, dynamic>?.
  AnalysisDataSet({
    required this.columns,
    required this.rows,
    required this.rowCount,
    this.timeRange,
    this.metadata,
  });

  /// Create from JSON.
  factory AnalysisDataSet.fromJson(Map<String, dynamic> json) {
    return AnalysisDataSet(
      columns: (json['columns'] as List<dynamic>?)
              ?.map(
                (e) =>
                    AnalysisColumnInfo.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      rows: (json['rows'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      rowCount: json['rowCount'] as int? ?? 0,
      timeRange: json['timeRange'] is Map<String, dynamic>
          ? AnalysisTimeRange.fromJson(
              json['timeRange'] as Map<String, dynamic>,
            )
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'columns': columns.map((c) => c.toJson()).toList(),
        'rows': rows,
        'rowCount': rowCount,
        if (timeRange != null) 'timeRange': timeRange!.toJson(),
        if (metadata != null) 'metadata': metadata,
      };
}

// ---------------------------------------------------------------------------
// Port
// ---------------------------------------------------------------------------

/// Contract for data source adapters.
///
/// Implementations:
/// - mcp_analysis: IoSourceAdapter, ApiSourceAdapter, UploadSourceAdapter
abstract class AnalysisDataSourcePort {
  /// Fetch data from source based on spec.
  Future<AnalysisDataSet> queryData({
    required AnalysisSourceType sourceType,
    required String query,
    Map<String, dynamic>? filter,
    AnalysisTimeRange? timeRange,
  });

  /// Retrieve source metadata (schema, columns, types, units).
  Future<AnalysisSourceSchema> getSourceMetadata({
    required AnalysisSourceType sourceType,
    required String query,
  });

  /// Check if source is accessible.
  Future<bool> isAvailable(AnalysisSourceType sourceType);
}

// ---------------------------------------------------------------------------
// Stub
// ---------------------------------------------------------------------------

/// Stub data source port for testing.
class StubAnalysisDataSourcePort implements AnalysisDataSourcePort {
  @override
  Future<AnalysisDataSet> queryData({
    required AnalysisSourceType sourceType,
    required String query,
    Map<String, dynamic>? filter,
    AnalysisTimeRange? timeRange,
  }) async {
    return AnalysisDataSet(
      columns: [],
      rows: [],
      rowCount: 0,
    );
  }

  @override
  Future<AnalysisSourceSchema> getSourceMetadata({
    required AnalysisSourceType sourceType,
    required String query,
  }) async {
    return const AnalysisSourceSchema(columns: []);
  }

  @override
  Future<bool> isAvailable(AnalysisSourceType sourceType) async => true;
}
