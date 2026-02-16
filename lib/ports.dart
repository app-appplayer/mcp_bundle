/// Port Contracts - Unified interfaces for MCP ecosystem.
///
/// This library exports all port contracts defined in mcp_bundle.
/// Use this for accessing LLM, storage, metric, and event ports.
///
/// Example:
/// ```dart
/// import 'package:mcp_bundle/ports.dart';
///
/// class MyLlmAdapter extends LlmPort {
///   @override
///   LlmCapabilities get capabilities => const LlmCapabilities.full();
///
///   @override
///   Future<LlmResponse> complete(LlmRequest request) async {
///     // Implementation
///   }
/// }
/// ```
library ports;

export 'src/ports/ports.dart';
