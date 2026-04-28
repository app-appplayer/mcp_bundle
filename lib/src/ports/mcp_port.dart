/// MCP Port (unified) - Model Context Protocol client interface.
///
/// Capability-named port for MCP protocol access. This is the **unified**
/// standard port — it supersedes the simple-form McpPort in
/// `knowledge_ports.dart` (deprecated in Phase 1a, removed in Phase 9) and
/// the rich-form definition in `mcp_skill/ports/mcp_port.dart` (removed in
/// Phase 3 per REDESIGN-PLAN.md).
///
/// Supports multi-server routing via optional `serverId`, resource
/// subscription, and prompt retrieval.
///
/// Provider: `mcp_client` or host.
library;

/// Port for Model Context Protocol operations.
///
/// Provides tool invocation, resource reading, subscription, and prompt
/// retrieval against one or more MCP servers.
abstract class McpPort {
  /// Call a tool on the specified server (or the default server).
  Future<ToolResult> callTool(
    String name,
    Map<String, dynamic> arguments, {
    String? serverId,
  });

  /// Read a resource from the specified server.
  ///
  /// Returns [ResourceContent] with URI, MIME type, and content payload.
  Future<ResourceContent> readResource(
    String uri, {
    String? serverId,
  });

  /// List tools available on the specified server (or all servers).
  Future<List<ToolInfo>> listTools({String? serverId});

  /// List resources available on the specified server (or all servers).
  Future<List<ResourceInfo>> listResources({String? serverId});

  /// Subscribe to resource changes.
  ///
  /// Returns `null` when the provider does not support subscription.
  Stream<ResourceContent>? subscribeResource(
    String uri, {
    String? serverId,
  });

  /// Get a prompt template by name.
  ///
  /// Returns `null` when the provider does not support prompts.
  Future<PromptTemplate?> getPrompt(
    String name, {
    String? serverId,
    Map<String, dynamic>? arguments,
  });

  /// Check whether the port is connected to a server.
  ///
  /// With [serverId] specified, checks that server; otherwise reports
  /// aggregate connection state.
  Future<bool> isConnected({String? serverId});
}

/// Tool execution result.
class ToolResult {
  /// Result content.
  final dynamic content;

  /// Whether execution resulted in error.
  final bool isError;

  /// Error message if any.
  final String? errorMessage;

  const ToolResult({
    required this.content,
    this.isError = false,
    this.errorMessage,
  });

  /// Create success result.
  factory ToolResult.success(dynamic content) {
    return ToolResult(content: content);
  }

  /// Create error result.
  factory ToolResult.error(String message) {
    return ToolResult(content: null, isError: true, errorMessage: message);
  }
}

/// Resource content read from an MCP server.
///
/// Unified shape that absorbs the legacy `McpResource` (simple-form) and
/// the `ResourceContent` from `mcp_skill`. See REDESIGN-PLAN §3.3 Open
/// Question 8 — resolution: adopt this merged shape.
class ResourceContent {
  /// Resource URI.
  final String uri;

  /// MIME type.
  final String? mimeType;

  /// Text content (null when binary).
  final String? text;

  /// Binary content (null when text).
  final List<int>? bytes;

  /// Metadata.
  final Map<String, dynamic>? metadata;

  const ResourceContent({
    required this.uri,
    this.mimeType,
    this.text,
    this.bytes,
    this.metadata,
  });

  /// Whether this resource is text-based.
  bool get isText => text != null;

  /// Whether this resource is binary.
  bool get isBinary => bytes != null;
}

/// Tool information.
class ToolInfo {
  /// Tool name.
  final String name;

  /// Tool description.
  final String? description;

  /// Input schema (JSON Schema).
  final Map<String, dynamic>? inputSchema;

  /// Optional server identifier that advertises this tool.
  final String? serverId;

  const ToolInfo({
    required this.name,
    this.description,
    this.inputSchema,
    this.serverId,
  });
}

/// Resource information.
class ResourceInfo {
  /// Resource URI.
  final String uri;

  /// Resource name.
  final String name;

  /// Description.
  final String? description;

  /// MIME type.
  final String? mimeType;

  /// Optional server identifier that advertises this resource.
  final String? serverId;

  const ResourceInfo({
    required this.uri,
    required this.name,
    this.description,
    this.mimeType,
    this.serverId,
  });
}

/// MCP prompt template.
class PromptTemplate {
  /// Prompt name.
  final String name;

  /// Rendered prompt text (after argument substitution).
  final String text;

  /// Prompt description.
  final String? description;

  /// Template argument definitions.
  final Map<String, dynamic>? arguments;

  const PromptTemplate({
    required this.name,
    required this.text,
    this.description,
    this.arguments,
  });
}

/// Stub MCP port for testing.
class StubMcpPort implements McpPort {
  const StubMcpPort();

  @override
  Future<ToolResult> callTool(
    String name,
    Map<String, dynamic> arguments, {
    String? serverId,
  }) async {
    return const ToolResult(content: 'Stub tool result');
  }

  @override
  Future<ResourceContent> readResource(
    String uri, {
    String? serverId,
  }) async {
    return ResourceContent(uri: uri, text: '');
  }

  @override
  Future<List<ToolInfo>> listTools({String? serverId}) async {
    return [];
  }

  @override
  Future<List<ResourceInfo>> listResources({String? serverId}) async {
    return [];
  }

  @override
  Stream<ResourceContent>? subscribeResource(
    String uri, {
    String? serverId,
  }) {
    return null;
  }

  @override
  Future<PromptTemplate?> getPrompt(
    String name, {
    String? serverId,
    Map<String, dynamic>? arguments,
  }) async {
    return null;
  }

  @override
  Future<bool> isConnected({String? serverId}) async => true;
}
