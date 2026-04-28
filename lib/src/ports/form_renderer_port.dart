/// Form Renderer Port - Pluggable renderer for multi-format document output.
///
/// Provides abstract contracts for rendering FormDocument instances to
/// various output formats (PDF, HTML, DOCX, Markdown, AppPlayer UI).
/// Implementations live in mcp_form package.
library;

import 'form_port.dart' show FormDocument, FormResult;

// ============================================================================
// Rendering Output
// ============================================================================

/// Output from document rendering.
class FormRenderOutput {
  /// Output format (pdf, html, docx, markdown, appplayer_ui).
  final String format;

  /// Rendered content. Bytes for binary formats, String for text/structured.
  final dynamic content;

  /// Number of pages in the output.
  final int pageCount;

  /// File size in bytes, if applicable.
  final int? fileSize;

  /// When the output was generated.
  final DateTime generatedAt;

  /// Rendering performance metrics.
  final FormRenderMetrics? metrics;

  // NOT const - has dynamic content field
  FormRenderOutput({
    required this.format,
    required this.content,
    required this.pageCount,
    this.fileSize,
    required this.generatedAt,
    this.metrics,
  });

  factory FormRenderOutput.fromJson(Map<String, dynamic> json) {
    return FormRenderOutput(
      format: json['format'] as String? ?? '',
      content: json['content'],
      pageCount: json['pageCount'] as int? ?? 0,
      fileSize: json['fileSize'] as int?,
      generatedAt: json['generatedAt'] is String
          ? DateTime.parse(json['generatedAt'] as String)
          : DateTime.now(),
      metrics: json['metrics'] is Map<String, dynamic>
          ? FormRenderMetrics.fromJson(json['metrics'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'format': format,
        'content': content,
        'pageCount': pageCount,
        if (fileSize != null) 'fileSize': fileSize,
        'generatedAt': generatedAt.toIso8601String(),
        if (metrics != null) 'metrics': metrics!.toJson(),
      };
}

// ============================================================================
// Rendering Metrics
// ============================================================================

/// Rendering performance metrics.
class FormRenderMetrics {
  /// Time taken to render in milliseconds.
  final double renderTimeMs;

  /// Number of pages rendered.
  final int pageCount;

  /// Number of content overflow events.
  final int overflowCount;

  /// Number of auto-fix actions applied.
  final int autofixCount;

  /// Output file size in bytes.
  final int? fileSize;

  const FormRenderMetrics({
    required this.renderTimeMs,
    required this.pageCount,
    this.overflowCount = 0,
    this.autofixCount = 0,
    this.fileSize,
  });

  factory FormRenderMetrics.fromJson(Map<String, dynamic> json) {
    return FormRenderMetrics(
      renderTimeMs: (json['renderTimeMs'] as num?)?.toDouble() ?? 0.0,
      pageCount: json['pageCount'] as int? ?? 0,
      overflowCount: json['overflowCount'] as int? ?? 0,
      autofixCount: json['autofixCount'] as int? ?? 0,
      fileSize: json['fileSize'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'renderTimeMs': renderTimeMs,
        'pageCount': pageCount,
        'overflowCount': overflowCount,
        'autofixCount': autofixCount,
        if (fileSize != null) 'fileSize': fileSize,
      };
}

// ============================================================================
// Renderer Metadata
// ============================================================================

/// Renderer metadata and capabilities.
class FormRendererMetadata {
  /// Unique renderer identifier.
  final String rendererId;

  /// Renderer version.
  final String version;

  /// Supported output formats.
  final List<String> supportedFormats;

  /// Supported template version range.
  final String? supportedTemplateRange;

  const FormRendererMetadata({
    required this.rendererId,
    required this.version,
    required this.supportedFormats,
    this.supportedTemplateRange,
  });

  factory FormRendererMetadata.fromJson(Map<String, dynamic> json) {
    return FormRendererMetadata(
      rendererId: json['rendererId'] as String? ?? '',
      version: json['version'] as String? ?? '',
      supportedFormats:
          (json['supportedFormats'] as List<dynamic>?)?.cast<String>() ?? [],
      supportedTemplateRange: json['supportedTemplateRange'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'rendererId': rendererId,
        'version': version,
        'supportedFormats': supportedFormats,
        if (supportedTemplateRange != null)
          'supportedTemplateRange': supportedTemplateRange,
      };
}

// ============================================================================
// Abstract Port
// ============================================================================

/// Pluggable renderer for multi-format output.
///
/// Implementations:
/// - mcp_form: PdfRenderer, HtmlRenderer, DocxRenderer, MarkdownRenderer, AppPlayerUiRenderer
abstract class FormRendererPort {
  /// Render document to target format.
  Future<FormResult<FormRenderOutput>> render({
    required FormDocument document,
    required String format,
    Map<String, dynamic>? options,
  });

  /// Get supported output formats.
  List<String> supportedFormats();

  /// Get renderer metadata.
  FormRendererMetadata getMetadata();
}

// ============================================================================
// Stub Implementation
// ============================================================================

/// Stub renderer for testing.
class StubFormRendererPort implements FormRendererPort {
  @override
  Future<FormResult<FormRenderOutput>> render({
    required FormDocument document,
    required String format,
    Map<String, dynamic>? options,
  }) async {
    return FormResult<FormRenderOutput>(
      success: true,
      data: FormRenderOutput(
        format: format,
        content: '',
        pageCount: 1,
        generatedAt: DateTime.now(),
      ),
    );
  }

  @override
  List<String> supportedFormats() => ['html', 'markdown'];

  @override
  FormRendererMetadata getMetadata() => const FormRendererMetadata(
        rendererId: 'stub',
        version: '0.0.0',
        supportedFormats: ['html', 'markdown'],
      );
}
