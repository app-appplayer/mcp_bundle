/// UiPort - Interface for bidirectional UI definition ↔ bundle transformation.
///
/// Provides contracts for converting between McpBundle and runtime-consumable
/// UI definition JSON. Read adapters convert bundles into UI definitions;
/// write adapters convert generated UI definitions back into bundle sections.
library;

import '../models/bundle.dart';
import '../models/ui_section.dart';

// =============================================================================
// Result Type
// =============================================================================

/// Result wrapper for UiPort operations.
///
/// All UiPort methods return this type instead of throwing exceptions.
/// [success] is `false` when [error] is present. Warnings may be present
/// even when [success] is `true`.
class UiResult<T> {
  const UiResult({
    required this.success,
    this.data,
    this.error,
    this.warnings,
  });

  /// Create a successful result.
  const UiResult.ok(T this.data)
      : success = true,
        error = null,
        warnings = null;

  /// Create a failed result.
  const UiResult.fail(UiError this.error)
      : success = false,
        data = null,
        warnings = null;

  /// Create a successful result with warnings.
  const UiResult.okWithWarnings(T this.data, List<UiError> this.warnings)
      : success = true,
        error = null;

  /// Create from JSON with a converter for the generic data field.
  factory UiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) dataFromJson,
  ) {
    return UiResult(
      success: json['success'] as bool,
      data: json['data'] != null
          ? dataFromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error'] != null
          ? UiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      warnings: (json['warnings'] as List<dynamic>?)
          ?.map((e) => UiError.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Whether the operation succeeded.
  final bool success;

  /// Result data on success.
  final T? data;

  /// Error details on failure.
  final UiError? error;

  /// Optional warnings from the operation.
  final List<UiError>? warnings;

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

/// Structured error for UiPort operations.
class UiError {
  UiError({
    required this.code,
    required this.message,
    this.path,
    this.context,
  });

  factory UiError.fromJson(Map<String, dynamic> json) => UiError(
        code: json['code'] as String,
        message: json['message'] as String,
        path: json['path'] as String?,
        context: json['context'] as Map<String, dynamic>?,
      );

  /// Machine-readable error code.
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
      'UiError($code: $message${path != null ? ' at $path' : ''})';
}

// =============================================================================
// Write Output Type
// =============================================================================

/// Output of the write operation ([UiPort.fromDefinition]).
///
/// Contains the extracted [UiSection] and manifest metadata map.
/// The caller merges [manifestMetadata] into [BundleManifest] via `copyWith()`.
class UiWriteOutput {
  UiWriteOutput({
    required this.uiSection,
    required this.manifestMetadata,
  });

  /// Extracted UI section (routes, pages, theme, navigation, state).
  final UiSection uiSection;

  /// Extracted manifest metadata as JSON.
  ///
  /// Keys may include: id, name, version, description, icon, splash,
  /// category, publisher, createdAt, updatedAt, screenshots.
  final Map<String, dynamic> manifestMetadata;
}

// =============================================================================
// Port Interface
// =============================================================================

/// Abstract port for bidirectional UI definition ↔ bundle transformation.
///
/// Read adapters implement [toDefinition] and [toAppInfo].
/// Write adapters implement [fromDefinition].
/// Single-direction adapters throw [UnsupportedError] for unsupported methods.
abstract class UiPort {
  /// Read: Convert [McpBundle] into runtime-consumable UI definition JSON.
  ///
  /// The returned JSON represents a runtime-consumable UI definition.
  /// `bundle://` URIs in icon/splash/screenshots are resolved by the adapter
  /// (implementation may use `BundleStoragePort.readAsset()` for resolution).
  Future<UiResult<Map<String, dynamic>>> toDefinition(McpBundle bundle);

  /// Read: Extract lightweight app info for discovery/listing.
  ///
  /// Returns a subset of metadata (id, name, version, description, icon,
  /// category, publisher) suitable for app info resource.
  /// Icon is resolved (never raw `bundle://`).
  Future<UiResult<Map<String, dynamic>>> toAppInfo(McpBundle bundle);

  /// Write: Convert UI definition JSON into bundle-compatible sections.
  ///
  /// Extracts [UiSection] (routes, theme, state, navigation) and manifest
  /// metadata from the provided UI definition JSON.
  /// `bundle://` URIs are preserved as-is (resolution is read adapter's concern).
  Future<UiResult<UiWriteOutput>> fromDefinition(
      Map<String, dynamic> definitionJson);
}

// =============================================================================
// Stub Implementation
// =============================================================================

/// Stub implementation of [UiPort] for testing.
///
/// Returns minimal valid responses for all operations.
class StubUiPort implements UiPort {
  @override
  Future<UiResult<Map<String, dynamic>>> toDefinition(McpBundle bundle) async {
    return UiResult.ok(<String, dynamic>{
      'type': 'application',
      'title': bundle.manifest.name,
      'version': bundle.manifest.version,
    });
  }

  @override
  Future<UiResult<Map<String, dynamic>>> toAppInfo(McpBundle bundle) async {
    return UiResult.ok(<String, dynamic>{
      'id': bundle.manifest.id,
      'name': bundle.manifest.name,
      'version': bundle.manifest.version,
      if (bundle.manifest.description != null)
        'description': bundle.manifest.description,
      if (bundle.manifest.icon != null) 'icon': bundle.manifest.icon,
      if (bundle.manifest.category != null)
        'category': bundle.manifest.category!.name,
    });
  }

  @override
  Future<UiResult<UiWriteOutput>> fromDefinition(
      Map<String, dynamic> definitionJson) async {
    return UiResult.ok(UiWriteOutput(
      uiSection: const UiSection(),
      manifestMetadata: <String, dynamic>{
        if (definitionJson['title'] != null) 'name': definitionJson['title'],
        if (definitionJson['version'] != null)
          'version': definitionJson['version'],
        if (definitionJson['id'] != null) 'id': definitionJson['id'],
        if (definitionJson['description'] != null)
          'description': definitionJson['description'],
      },
    ));
  }
}
