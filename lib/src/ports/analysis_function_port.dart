/// Analysis Function Port - Contract for pluggable analysis function
/// registration and execution.
///
/// Provides abstract contracts for registering, discovering, and executing
/// analysis functions (built-in and plugin-provided) against data sets.
library;

import 'analysis_datasource_port.dart';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/// Information about a registered analysis function.
class AnalysisFunctionInfo {
  /// Function name (e.g., descriptive_stats, anomaly_detect).
  final String functionName;

  /// Human-readable description.
  final String description;

  /// Parameter schemas keyed by parameter name.
  final Map<String, AnalysisParameterSchema> parameters;

  /// Supported data types (numeric, temporal, categorical, event).
  final List<String> supportedDataTypes;

  /// Plugin identifier, if external.
  final String? plugin;

  /// Spec version range this function supports.
  final String? specVersionRange;

  // NOT const - has Map with non-const values
  AnalysisFunctionInfo({
    required this.functionName,
    required this.description,
    this.parameters = const {},
    this.supportedDataTypes = const [],
    this.plugin,
    this.specVersionRange,
  });

  factory AnalysisFunctionInfo.fromJson(Map<String, dynamic> json) {
    return AnalysisFunctionInfo(
      functionName: json['functionName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      parameters: (json['parameters'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              k,
              AnalysisParameterSchema.fromJson(v as Map<String, dynamic>),
            ),
          ) ??
          {},
      supportedDataTypes:
          (json['supportedDataTypes'] as List<dynamic>?)?.cast<String>() ?? [],
      plugin: json['plugin'] as String?,
      specVersionRange: json['specVersionRange'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'functionName': functionName,
        'description': description,
        if (parameters.isNotEmpty)
          'parameters': parameters.map((k, v) => MapEntry(k, v.toJson())),
        if (supportedDataTypes.isNotEmpty)
          'supportedDataTypes': supportedDataTypes,
        if (plugin != null) 'plugin': plugin,
        if (specVersionRange != null) 'specVersionRange': specVersionRange,
      };
}

/// Schema for a function parameter.
class AnalysisParameterSchema {
  /// Parameter name.
  final String name;

  /// Parameter type (int, double, string, boolean, array).
  final String type;

  /// Default value.
  final dynamic defaultValue;

  /// Description.
  final String? description;

  /// Minimum value constraint.
  final dynamic min;

  /// Maximum value constraint.
  final dynamic max;

  // NOT const - has dynamic fields
  AnalysisParameterSchema({
    required this.name,
    required this.type,
    this.defaultValue,
    this.description,
    this.min,
    this.max,
  });

  factory AnalysisParameterSchema.fromJson(Map<String, dynamic> json) {
    return AnalysisParameterSchema(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'string',
      defaultValue: json['defaultValue'],
      description: json['description'] as String?,
      min: json['min'],
      max: json['max'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        if (defaultValue != null) 'defaultValue': defaultValue,
        if (description != null) 'description': description,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
      };
}

/// Result from executing an analysis function.
class AnalysisFunctionResult {
  /// Function that was executed.
  final String functionName;

  /// Result data.
  final Map<String, dynamic> results;

  /// Execution time.
  final Duration executionTime;

  /// Additional metadata.
  final Map<String, dynamic>? metadata;

  // NOT const - has Duration and Map<String, dynamic>
  AnalysisFunctionResult({
    required this.functionName,
    required this.results,
    required this.executionTime,
    this.metadata,
  });

  factory AnalysisFunctionResult.fromJson(Map<String, dynamic> json) {
    return AnalysisFunctionResult(
      functionName: json['functionName'] as String? ?? '',
      results: json['results'] as Map<String, dynamic>? ?? {},
      executionTime: Duration(
        milliseconds: json['executionTimeMs'] as int? ?? 0,
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'functionName': functionName,
        'results': results,
        'executionTimeMs': executionTime.inMilliseconds,
        if (metadata != null) 'metadata': metadata,
      };
}

// ---------------------------------------------------------------------------
// Port
// ---------------------------------------------------------------------------

/// Contract for pluggable analysis function registration and execution.
///
/// Built-in functions:
/// - descriptive_stats: min, max, avg, std, percentiles
/// - anomaly_detect: threshold, z-score, IQR, simple EWMA
/// - event_analysis: frequency count, MTBF, MTTR, state transitions
/// - time_series_analysis: moving average, trend line
/// - correlation_regression: correlation coefficient, linear regression
/// - rule_based_classification: conditional rule-based label assignment
///
/// Implementations: mcp_analysis (FunctionCatalog)
abstract class AnalysisFunctionPort {
  /// Register a new analysis function.
  Future<void> registerFunction(AnalysisFunctionInfo function);

  /// List available functions with parameter schemas.
  Future<List<AnalysisFunctionInfo>> getFunctionCatalog();

  /// Execute an analysis function on a data set.
  Future<AnalysisFunctionResult> executeFunction({
    required String functionName,
    required Map<String, dynamic> parameters,
    required AnalysisDataSet data,
  });

  /// Unregister a function.
  Future<void> unregisterFunction(String functionName);
}

// ---------------------------------------------------------------------------
// Stub
// ---------------------------------------------------------------------------

/// Stub function port for testing.
class StubAnalysisFunctionPort implements AnalysisFunctionPort {
  final Map<String, AnalysisFunctionInfo> _functions = {};

  @override
  Future<void> registerFunction(AnalysisFunctionInfo function) async {
    _functions[function.functionName] = function;
  }

  @override
  Future<List<AnalysisFunctionInfo>> getFunctionCatalog() async {
    return _functions.values.toList();
  }

  @override
  Future<AnalysisFunctionResult> executeFunction({
    required String functionName,
    required Map<String, dynamic> parameters,
    required AnalysisDataSet data,
  }) async {
    return AnalysisFunctionResult(
      functionName: functionName,
      results: {},
      executionTime: Duration.zero,
    );
  }

  @override
  Future<void> unregisterFunction(String functionName) async {
    _functions.remove(functionName);
  }

  void clear() {
    _functions.clear();
  }
}
