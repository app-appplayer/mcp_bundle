/// FlowPort - Interface for bidirectional Flow definition ↔ bundle transformation.
///
/// Provides contracts for converting between McpBundle and runtime-consumable
/// Flow definition JSON. Read adapters convert bundles into Flow definitions;
/// write adapters convert generated Flow definitions back into bundle sections.
library;

import '../models/bundle.dart';
import '../models/flow_section.dart';

// =============================================================================
// Result Type
// =============================================================================

/// Result wrapper for FlowPort operations.
///
/// All FlowPort methods return this type instead of throwing exceptions.
/// [success] is `false` when [error] is present. Warnings may be present
/// even when [success] is `true`.
class FlowResult<T> {
  const FlowResult({
    required this.success,
    this.data,
    this.error,
    this.warnings,
  });

  /// Create a successful result.
  const FlowResult.ok(T this.data)
      : success = true,
        error = null,
        warnings = null;

  /// Create a failed result.
  const FlowResult.fail(FlowError this.error)
      : success = false,
        data = null,
        warnings = null;

  /// Create a successful result with warnings.
  const FlowResult.okWithWarnings(T this.data, List<FlowError> this.warnings)
      : success = true,
        error = null;

  /// Create from JSON with a converter for the generic data field.
  factory FlowResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) dataFromJson,
  ) {
    return FlowResult(
      success: json['success'] as bool,
      data: json['data'] != null
          ? dataFromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error'] != null
          ? FlowError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      warnings: (json['warnings'] as List<dynamic>?)
          ?.map((e) => FlowError.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Whether the operation succeeded.
  final bool success;

  /// Result data on success.
  final T? data;

  /// Error details on failure.
  final FlowError? error;

  /// Optional warnings from the operation.
  final List<FlowError>? warnings;

  /// Serialize to JSON with a converter for the generic data field.
  Map<String, dynamic> toJson([
    Map<String, dynamic> Function(T)? dataToJson,
  ]) {
    return {
      'success': success,
      if (data != null && dataToJson != null) 'data': dataToJson(data as T),
      if (error != null) 'error': error!.toJson(),
      if (warnings != null)
        'warnings': warnings!.map((w) => w.toJson()).toList(),
    };
  }
}

// =============================================================================
// Error Type
// =============================================================================

/// Structured error for FlowPort operations.
class FlowError {
  FlowError({
    required this.code,
    required this.message,
    this.path,
    this.context,
  });

  factory FlowError.fromJson(Map<String, dynamic> json) => FlowError(
        code: json['code'] as String,
        message: json['message'] as String,
        path: json['path'] as String?,
        context: json['context'] as Map<String, dynamic>?,
      );

  /// Machine-readable error code.
  ///
  /// Standard codes:
  /// - `MISSING_FLOW_SECTION` — McpBundle does not contain a FlowSection
  /// - `INVALID_MANIFEST` — Required manifest fields missing or empty
  /// - `INVALID_FLOW_DEFINITION` — FlowDefinition has structural errors
  /// - `INVALID_STEP_TYPE` — Unknown or unsupported step type
  /// - `INVALID_TRIGGER_TYPE` — Unknown or unsupported trigger type
  /// - `CONVERSION_ERROR` — General conversion failure
  final String code;

  /// Human-readable error message.
  final String message;

  /// JSON path where the error occurred.
  final String? path;

  /// Additional context for the error.
  final Map<String, dynamic>? context;

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        if (path != null) 'path': path,
        if (context != null) 'context': context,
      };

  @override
  String toString() =>
      'FlowError($code: $message${path != null ? ' at $path' : ''})';
}

// =============================================================================
// Write Output Type
// =============================================================================

/// Output of the write operation ([FlowPort.fromDefinition]).
///
/// Contains the extracted [FlowSection] and manifest metadata map.
/// The caller merges [manifestMetadata] into [BundleManifest] via `copyWith()`.
class FlowWriteOutput {
  FlowWriteOutput({
    required this.flowSection,
    required this.manifestMetadata,
  });

  /// Extracted Flow section (flows, sharedState, errorHandlers).
  final FlowSection flowSection;

  /// Extracted manifest metadata as JSON.
  ///
  /// Keys may include: id, name, version, description.
  final Map<String, dynamic> manifestMetadata;
}

// =============================================================================
// Port Interface
// =============================================================================

/// Abstract port for bidirectional Flow definition ↔ bundle transformation.
///
/// Read adapters implement [toDefinition] and [toFlowInfo].
/// Write adapters implement [fromDefinition].
/// Single-direction adapters throw [UnsupportedError] for unsupported methods.
abstract class FlowPort {
  /// Read: Convert [McpBundle] into runtime-consumable Flow definition JSON.
  Future<FlowResult<Map<String, dynamic>>> toDefinition(McpBundle bundle);

  /// Read: Extract lightweight Flow info for discovery/listing.
  Future<FlowResult<Map<String, dynamic>>> toFlowInfo(McpBundle bundle);

  /// Write: Convert Flow definition JSON into bundle-compatible sections.
  Future<FlowResult<FlowWriteOutput>> fromDefinition(
      Map<String, dynamic> definitionJson);
}

// =============================================================================
// Stub Implementation
// =============================================================================

/// Stub implementation of [FlowPort] for testing.
///
/// Returns minimal valid responses for all operations.
class StubFlowPort implements FlowPort {
  @override
  Future<FlowResult<Map<String, dynamic>>> toDefinition(
      McpBundle bundle) async {
    final flowSection = bundle.flow ?? const FlowSection();
    return FlowResult.ok(<String, dynamic>{
      'id': bundle.manifest.id,
      'name': bundle.manifest.name,
      'version': bundle.manifest.version,
      'schemaVersion': flowSection.schemaVersion,
      'flows': <Map<String, dynamic>>[],
    });
  }

  @override
  Future<FlowResult<Map<String, dynamic>>> toFlowInfo(
      McpBundle bundle) async {
    return FlowResult.ok(<String, dynamic>{
      'id': bundle.manifest.id,
      'name': bundle.manifest.name,
      'version': bundle.manifest.version,
      if (bundle.manifest.description != null)
        'description': bundle.manifest.description,
      'flows': <Map<String, dynamic>>[],
    });
  }

  @override
  Future<FlowResult<FlowWriteOutput>> fromDefinition(
      Map<String, dynamic> definitionJson) async {
    return FlowResult.ok(FlowWriteOutput(
      flowSection: const FlowSection(),
      manifestMetadata: <String, dynamic>{
        if (definitionJson['id'] != null) 'id': definitionJson['id'],
        if (definitionJson['name'] != null) 'name': definitionJson['name'],
        if (definitionJson['version'] != null)
          'version': definitionJson['version'],
        if (definitionJson['description'] != null)
          'description': definitionJson['description'],
      },
    ));
  }
}
