/// FormTemplatePort - Template storage, retrieval, and version management.
///
/// Provides form template lifecycle operations including save, retrieve,
/// list, version history, and delete. Templates bundle a FormSchema with
/// layout policies, sections, i18n strings, and an optional manifest.
///
/// Implementations: mcp_form
library;

import 'form_port.dart';

// ============================================================================
// Types
// ============================================================================

/// Form template definition.
class FormTemplate {
  /// Unique template identifier.
  final String templateId;

  /// Semantic version string.
  final String version;

  /// Human-readable template name.
  final String name;

  /// Optional description of the template.
  final String? description;

  /// Schema defining the template fields and validation.
  final FormSchema schema;

  /// Layout policy for rendering the template.
  final FormLayoutPolicy layoutPolicy;

  /// Default sections for the template.
  final List<FormSection> defaultSections;

  /// Optional locale identifier (e.g., 'en', 'ko').
  final String? locale;

  /// Optional list of component identifiers used by the template.
  final List<String>? components;

  /// Optional internationalisation key-value pairs.
  final Map<String, String>? i18nStrings;

  /// Optional manifest with dependencies and compatibility info.
  final FormTemplateManifest? manifest;

  // NOT const - FormSchema and FormLayoutPolicy contain non-const types.
  FormTemplate({
    required this.templateId,
    required this.version,
    required this.name,
    this.description,
    required this.schema,
    required this.layoutPolicy,
    this.defaultSections = const [],
    this.locale,
    this.components,
    this.i18nStrings,
    this.manifest,
  });

  /// Create from JSON.
  factory FormTemplate.fromJson(Map<String, dynamic> json) {
    return FormTemplate(
      templateId: json['templateId'] as String,
      version: json['version'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      schema: FormSchema.fromJson(json['schema'] as Map<String, dynamic>),
      layoutPolicy: FormLayoutPolicy.fromJson(
          json['layoutPolicy'] as Map<String, dynamic>),
      defaultSections: (json['defaultSections'] as List<dynamic>?)
              ?.map((e) => FormSection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      locale: json['locale'] as String?,
      components: (json['components'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      i18nStrings: (json['i18nStrings'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)),
      manifest: json['manifest'] != null
          ? FormTemplateManifest.fromJson(
              json['manifest'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'version': version,
        'name': name,
        if (description != null) 'description': description,
        'schema': schema.toJson(),
        'layoutPolicy': layoutPolicy.toJson(),
        if (defaultSections.isNotEmpty)
          'defaultSections': defaultSections.map((s) => s.toJson()).toList(),
        if (locale != null) 'locale': locale,
        if (components != null) 'components': components,
        if (i18nStrings != null) 'i18nStrings': i18nStrings,
        if (manifest != null) 'manifest': manifest!.toJson(),
      };
}

/// Template manifest with dependencies and compatibility.
class FormTemplateManifest {
  /// Dependencies required by the template.
  final List<FormTemplateDependency> dependencies;

  /// Engine version range for compatibility (e.g., '>=1.0.0 <2.0.0').
  final String compatRange;

  /// Optional metadata key-value pairs.
  final Map<String, dynamic>? metadata;

  // NOT const - has Map<String, dynamic>? metadata.
  FormTemplateManifest({
    this.dependencies = const [],
    required this.compatRange,
    this.metadata,
  });

  /// Create from JSON.
  factory FormTemplateManifest.fromJson(Map<String, dynamic> json) {
    return FormTemplateManifest(
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((e) =>
                  FormTemplateDependency.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      compatRange: json['compatRange'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        if (dependencies.isNotEmpty)
          'dependencies': dependencies.map((d) => d.toJson()).toList(),
        'compatRange': compatRange,
        if (metadata != null) 'metadata': metadata,
      };
}

/// Template dependency entry.
class FormTemplateDependency {
  /// Component identifier.
  final String componentId;

  /// Required version.
  final String version;

  /// Optional dependency type (e.g., 'font', 'icon', 'chart').
  final String? type;

  const FormTemplateDependency({
    required this.componentId,
    required this.version,
    this.type,
  });

  /// Create from JSON.
  factory FormTemplateDependency.fromJson(Map<String, dynamic> json) {
    return FormTemplateDependency(
      componentId: json['componentId'] as String,
      version: json['version'] as String,
      type: json['type'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'componentId': componentId,
        'version': version,
        if (type != null) 'type': type,
      };
}

/// Template version history entry.
class FormTemplateVersion {
  /// Template identifier.
  final String templateId;

  /// Semantic version string.
  final String version;

  /// When this version was created.
  final DateTime createdAt;

  /// Optional author of this version.
  final String? author;

  /// Optional description of changes in this version.
  final String? changeDescription;

  FormTemplateVersion({
    required this.templateId,
    required this.version,
    required this.createdAt,
    this.author,
    this.changeDescription,
  });

  /// Create from JSON.
  factory FormTemplateVersion.fromJson(Map<String, dynamic> json) {
    return FormTemplateVersion(
      templateId: json['templateId'] as String,
      version: json['version'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      author: json['author'] as String?,
      changeDescription: json['changeDescription'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        if (author != null) 'author': author,
        if (changeDescription != null) 'changeDescription': changeDescription,
      };
}

// ============================================================================
// Port Interface
// ============================================================================

/// Template storage, retrieval, and version management.
///
/// Implementations: mcp_form
abstract class FormTemplatePort {
  /// Save or update a template.
  Future<FormResult<FormTemplate>> saveTemplate({
    required FormTemplate template,
  });

  /// Retrieve template by ID and optional version.
  Future<FormResult<FormTemplate>> getTemplate({
    required String templateId,
    String? version,
  });

  /// List templates with optional search.
  Future<FormResult<List<FormTemplate>>> listTemplates({
    String? search,
    int? limit,
    int? offset,
  });

  /// Get template version history.
  Future<FormResult<List<FormTemplateVersion>>> getTemplateVersions({
    required String templateId,
  });

  /// Delete template (version-specific or all).
  Future<FormResult<void>> deleteTemplate({
    required String templateId,
    String? version,
  });
}

// ============================================================================
// Stub Implementation
// ============================================================================

/// Stub template port for testing.
class StubFormTemplatePort implements FormTemplatePort {
  final Map<String, FormTemplate> _templates = {};

  @override
  Future<FormResult<FormTemplate>> saveTemplate({
    required FormTemplate template,
  }) async {
    _templates[template.templateId] = template;
    return FormResult<FormTemplate>(success: true, data: template);
  }

  @override
  Future<FormResult<FormTemplate>> getTemplate({
    required String templateId,
    String? version,
  }) async {
    final template = _templates[templateId];
    if (template == null) {
      return FormResult<FormTemplate>(
        success: false,
        error: FormError(code: 'not_found', message: 'Template not found'),
      );
    }
    return FormResult<FormTemplate>(success: true, data: template);
  }

  @override
  Future<FormResult<List<FormTemplate>>> listTemplates({
    String? search,
    int? limit,
    int? offset,
  }) async {
    var results = _templates.values.toList();
    if (search != null) {
      results = results.where((t) => t.name.contains(search)).toList();
    }
    return FormResult<List<FormTemplate>>(success: true, data: results);
  }

  @override
  Future<FormResult<List<FormTemplateVersion>>> getTemplateVersions({
    required String templateId,
  }) async {
    return FormResult<List<FormTemplateVersion>>(success: true, data: []);
  }

  @override
  Future<FormResult<void>> deleteTemplate({
    required String templateId,
    String? version,
  }) async {
    _templates.remove(templateId);
    return FormResult<void>(success: true);
  }

  /// Clear all stored templates.
  void clear() {
    _templates.clear();
  }
}
