/// `ChatSection` — the bundle's chat-UI binding surface (spec §06.5).
///
/// Top-level section on `McpBundle.chat`. Carries the composer's
/// slash-command chips plus an optional default agent id. Hosts that
/// do not surface a chat UI MAY ignore this section.
library;

/// Discriminated entry: either `template`-mode (pre-fill composer) or
/// `tool`-mode (direct dispatch). Real bundles carry the dispatch
/// either inline (`tool` + `args`) or nested (`directDispatch.{tool,
/// args}`) — the loader accepts both, the emitter writes the canonical
/// inline form.
class SlashCommand {
  const SlashCommand({
    required this.command,
    this.template,
    this.tool,
    this.args,
    this.description,
  });

  /// Slash trigger token (MUST start with `/`).
  final String command;

  /// Pre-fill text for the composer (template mode). Mutually exclusive
  /// with [tool].
  final String? template;

  /// Tool to dispatch directly (tool mode). Mutually exclusive with
  /// [template].
  final String? tool;

  /// Fixed arguments for tool-mode entries.
  final Map<String, dynamic>? args;

  /// Hint text rendered with the chip.
  final String? description;

  factory SlashCommand.fromJson(Map<String, dynamic> json) {
    // `directDispatch: {tool, args}` is the nested authoring shape some
    // existing bundles emit. Spec §06.5 carries `tool` / `args` inline;
    // we accept both and normalize on read.
    final dispatch = json['directDispatch'];
    final inlineTool = json['tool'] as String?;
    final inlineArgs = json['args'];
    String? tool = inlineTool;
    Map<String, dynamic>? args =
        inlineArgs is Map<String, dynamic> ? inlineArgs : null;
    if (dispatch is Map<String, dynamic>) {
      tool ??= dispatch['tool'] as String?;
      final da = dispatch['args'];
      args ??= da is Map<String, dynamic> ? da : null;
    }
    return SlashCommand(
      command: (json['command'] as String?) ?? '',
      template: json['template'] as String?,
      tool: tool,
      args: args,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'command': command,
        if (template != null) 'template': template,
        if (tool != null) 'tool': tool,
        if (args != null && args!.isNotEmpty) 'args': args,
        if (description != null) 'description': description,
      };

  SlashCommand copyWith({
    String? command,
    String? template,
    String? tool,
    Map<String, dynamic>? args,
    String? description,
  }) =>
      SlashCommand(
        command: command ?? this.command,
        template: template ?? this.template,
        tool: tool ?? this.tool,
        args: args ?? this.args,
        description: description ?? this.description,
      );
}

class ChatSection {
  const ChatSection({
    this.schemaVersion = '1.0.0',
    this.slashCommands = const [],
    this.agent,
  });

  /// Per spec §3.2 every typed section carries a `schemaVersion`.
  final String schemaVersion;

  /// Composer chips surfaced when the user types `/`.
  final List<SlashCommand> slashCommands;

  /// Optional default chat agent id (`agents.agents[*].id`).
  final String? agent;

  factory ChatSection.fromJson(Map<String, dynamic> json) {
    final raw = json['slashCommands'];
    return ChatSection(
      schemaVersion: (json['schemaVersion'] as String?) ?? '1.0.0',
      slashCommands: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(SlashCommand.fromJson)
              .toList()
          : const [],
      agent: json['agent'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'slashCommands': slashCommands.map((e) => e.toJson()).toList(),
        if (agent != null) 'agent': agent,
      };

  ChatSection copyWith({
    String? schemaVersion,
    List<SlashCommand>? slashCommands,
    String? agent,
  }) =>
      ChatSection(
        schemaVersion: schemaVersion ?? this.schemaVersion,
        slashCommands: slashCommands ?? this.slashCommands,
        agent: agent ?? this.agent,
      );
}
