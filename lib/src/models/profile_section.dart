/// Profile section models for MCP Bundle.
///
/// Contains profile definitions that can be bundled with the application.
library;

/// A section containing profile definitions.
class ProfilesSection {
  /// List of profiles in this section.
  final List<ProfileDefinition> profiles;

  const ProfilesSection({
    this.profiles = const [],
  });

  /// Create from JSON.
  factory ProfilesSection.fromJson(Map<String, dynamic> json) {
    return ProfilesSection(
      profiles: (json['profiles'] as List<dynamic>?)
              ?.map((e) => ProfileDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'profiles': profiles.map((p) => p.toJson()).toList(),
      };

  /// Check if section is empty.
  bool get isEmpty => profiles.isEmpty;

  /// Check if section is not empty.
  bool get isNotEmpty => profiles.isNotEmpty;

  /// Get profile by ID.
  ProfileDefinition? getProfile(String id) {
    for (final profile in profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  /// Create a copy with modifications.
  ProfilesSection copyWith({
    List<ProfileDefinition>? profiles,
  }) {
    return ProfilesSection(
      profiles: profiles ?? this.profiles,
    );
  }
}

/// A profile definition within a bundle.
class ProfileDefinition {
  /// Profile identifier.
  final String id;

  /// Profile name.
  final String name;

  /// Profile description.
  final String? description;

  /// Profile version.
  final String version;

  /// Profile sections (content blocks).
  final List<ProfileContentSection> sections;

  /// Profile capabilities.
  final List<String> capabilities;

  /// Profile variables.
  final Map<String, dynamic> variables;

  /// Profile metadata.
  final Map<String, dynamic> metadata;

  const ProfileDefinition({
    required this.id,
    required this.name,
    this.description,
    this.version = '1.0.0',
    this.sections = const [],
    this.capabilities = const [],
    this.variables = const {},
    this.metadata = const {},
  });

  /// Create from JSON.
  factory ProfileDefinition.fromJson(Map<String, dynamic> json) {
    return ProfileDefinition(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      version: json['version'] as String? ?? '1.0.0',
      sections: (json['sections'] as List<dynamic>?)
              ?.map(
                  (e) => ProfileContentSection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      variables: json['variables'] as Map<String, dynamic>? ?? {},
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'version': version,
        if (sections.isNotEmpty)
          'sections': sections.map((s) => s.toJson()).toList(),
        if (capabilities.isNotEmpty) 'capabilities': capabilities,
        if (variables.isNotEmpty) 'variables': variables,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Create a copy with modifications.
  ProfileDefinition copyWith({
    String? id,
    String? name,
    String? description,
    String? version,
    List<ProfileContentSection>? sections,
    List<String>? capabilities,
    Map<String, dynamic>? variables,
    Map<String, dynamic>? metadata,
  }) {
    return ProfileDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      sections: sections ?? this.sections,
      capabilities: capabilities ?? this.capabilities,
      variables: variables ?? this.variables,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// A content section within a profile.
class ProfileContentSection {
  /// Section name/identifier.
  final String name;

  /// Section content (prompt text, instructions, etc.).
  final String content;

  /// Section priority (higher = more important).
  final int priority;

  /// Condition expression for conditional inclusion.
  final String? condition;

  const ProfileContentSection({
    required this.name,
    required this.content,
    this.priority = 0,
    this.condition,
  });

  /// Create from JSON.
  factory ProfileContentSection.fromJson(Map<String, dynamic> json) {
    return ProfileContentSection(
      name: json['name'] as String? ?? '',
      content: json['content'] as String? ?? '',
      priority: json['priority'] as int? ?? 0,
      condition: json['condition'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'name': name,
        'content': content,
        if (priority != 0) 'priority': priority,
        if (condition != null) 'condition': condition,
      };

  /// Create a copy with modifications.
  ProfileContentSection copyWith({
    String? name,
    String? content,
    int? priority,
    String? condition,
  }) {
    return ProfileContentSection(
      name: name ?? this.name,
      content: content ?? this.content,
      priority: priority ?? this.priority,
      condition: condition ?? this.condition,
    );
  }
}
