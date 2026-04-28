/// Form Port - Interface for form document creation, validation, and management.
///
/// Provides abstract contracts for form document operations including
/// template-based document creation, schema validation, data binding,
/// patch operations, and version history tracking.
library;

// ============================================================================
// Enums
// ============================================================================

/// Status of a form document in its lifecycle.
enum FormDocumentStatus {
  /// Document is being drafted.
  draft,

  /// Document is under review.
  review,

  /// Document has been approved.
  approved,

  /// Document has been published.
  published;

  /// Parse a [FormDocumentStatus] from its string name.
  static FormDocumentStatus fromString(String value) {
    return FormDocumentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FormDocumentStatus.draft,
    );
  }
}

/// Type of content block within a form document.
enum FormBlockType {
  /// Plain text content.
  text,

  /// Heading content with level.
  heading,

  /// Tabular data.
  table,

  /// Chart visualization.
  chart,

  /// Image content.
  image,

  /// Interactive form field.
  formField,

  /// Repeatable block template.
  repeatable,

  /// Conditional block with branching.
  conditional,

  /// Live canvas scene embed — rendered against current project state
  /// via a CanvasBindingResolver. See [FormCanvasBlock].
  canvas;

  /// Parse a [FormBlockType] from its string name.
  static FormBlockType fromString(String value) {
    return FormBlockType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FormBlockType.text,
    );
  }
}

/// Source type for form data bindings.
enum FormDataSourceType {
  /// Data sourced from FactGraph.
  factgraph,

  /// Data sourced from IO adapters.
  io,

  /// Data sourced from analysis results.
  analysis,

  /// Data sourced from tool execution.
  tool,

  /// Data provided by user input.
  userInput,

  /// Data sourced from a live canvas scene (rendered to SVG/PNG/PDF bytes
  /// at resolve time). Binding `dataPath` is a `canvas://` URI describing
  /// the scene reference. Used by [FormCanvasBlock].
  canvas;

  /// Parse a [FormDataSourceType] from its string name.
  static FormDataSourceType fromString(String value) {
    return FormDataSourceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FormDataSourceType.userInput,
    );
  }
}

// ============================================================================
// Document Model
// ============================================================================

/// A form document instance created from a template.
class FormDocument {
  /// Unique document identifier.
  final String documentId;

  /// Template this document was created from.
  final String templateId;

  /// Version of the template used.
  final String templateVersion;

  /// Document metadata.
  final FormDocumentMetadata metadata;

  /// Current document status.
  final FormDocumentStatus status;

  /// Document version number.
  final int version;

  /// Sections within the document.
  final List<FormSection> sections;

  /// Document data values.
  final Map<String, dynamic> data;

  /// Optional data bindings.
  final List<FormDataBinding>? bindings;

  /// Optional validation issues.
  final List<FormValidationIssue>? validationIssues;

  // Cannot be const due to Map<String, dynamic> data field.
  FormDocument({
    required this.documentId,
    required this.templateId,
    required this.templateVersion,
    required this.metadata,
    this.status = FormDocumentStatus.draft,
    this.version = 1,
    this.sections = const [],
    this.data = const {},
    this.bindings,
    this.validationIssues,
  });

  /// Create from JSON.
  factory FormDocument.fromJson(Map<String, dynamic> json) {
    return FormDocument(
      documentId: json['documentId'] as String,
      templateId: json['templateId'] as String,
      templateVersion: json['templateVersion'] as String,
      metadata: FormDocumentMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
      status: FormDocumentStatus.fromString(
        json['status'] as String? ?? 'draft',
      ),
      version: json['version'] as int? ?? 1,
      sections: (json['sections'] as List<dynamic>?)
              ?.map(
                (e) => FormSection.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      data: json['data'] as Map<String, dynamic>? ?? {},
      bindings: (json['bindings'] as List<dynamic>?)
          ?.map((e) => FormDataBinding.fromJson(e as Map<String, dynamic>))
          .toList(),
      validationIssues: (json['validationIssues'] as List<dynamic>?)
          ?.map(
            (e) => FormValidationIssue.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'templateId': templateId,
        'templateVersion': templateVersion,
        'metadata': metadata.toJson(),
        'status': status.name,
        'version': version,
        'sections': sections.map((s) => s.toJson()).toList(),
        if (data.isNotEmpty) 'data': data,
        if (bindings != null)
          'bindings': bindings!.map((b) => b.toJson()).toList(),
        if (validationIssues != null)
          'validationIssues':
              validationIssues!.map((v) => v.toJson()).toList(),
      };
}

/// Metadata associated with a form document.
class FormDocumentMetadata {
  /// Author of the document.
  final String author;

  /// When the document was created.
  final DateTime createdAt;

  /// When the document was last modified.
  final DateTime? modifiedAt;

  /// When the document was published.
  final DateTime? publishedAt;

  /// Data source identifier.
  final String? dataSource;

  /// Engine version used to create the document.
  final String? engineVersion;

  const FormDocumentMetadata({
    required this.author,
    required this.createdAt,
    this.modifiedAt,
    this.publishedAt,
    this.dataSource,
    this.engineVersion,
  });

  /// Create from JSON.
  factory FormDocumentMetadata.fromJson(Map<String, dynamic> json) {
    return FormDocumentMetadata(
      author: json['author'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
      dataSource: json['dataSource'] as String?,
      engineVersion: json['engineVersion'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'author': author,
        'createdAt': createdAt.toIso8601String(),
        if (modifiedAt != null) 'modifiedAt': modifiedAt!.toIso8601String(),
        if (publishedAt != null)
          'publishedAt': publishedAt!.toIso8601String(),
        if (dataSource != null) 'dataSource': dataSource,
        if (engineVersion != null) 'engineVersion': engineVersion,
      };
}

/// A version entry in the document history.
class FormDocumentVersion {
  /// Version number.
  final int versionNumber;

  /// When this version was created.
  final DateTime timestamp;

  /// Author of this version.
  final String author;

  /// Optional description of changes.
  final String? changeDescription;

  /// Optional diff from previous version.
  final Map<String, dynamic>? diff;

  // Cannot be const due to Map<String, dynamic>? diff field.
  FormDocumentVersion({
    required this.versionNumber,
    required this.timestamp,
    required this.author,
    this.changeDescription,
    this.diff,
  });

  /// Create from JSON.
  factory FormDocumentVersion.fromJson(Map<String, dynamic> json) {
    return FormDocumentVersion(
      versionNumber: json['versionNumber'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      author: json['author'] as String,
      changeDescription: json['changeDescription'] as String?,
      diff: json['diff'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'versionNumber': versionNumber,
        'timestamp': timestamp.toIso8601String(),
        'author': author,
        if (changeDescription != null) 'changeDescription': changeDescription,
        if (diff != null) 'diff': diff,
      };
}

/// A section within a form document.
class FormSection {
  /// Unique section identifier.
  final String sectionId;

  /// Section ordering index.
  final int index;

  /// Optional section title.
  final String? title;

  /// Optional section description.
  final String? description;

  /// Blocks within this section.
  final List<FormBlock> blocks;

  const FormSection({
    required this.sectionId,
    required this.index,
    this.title,
    this.description,
    this.blocks = const [],
  });

  /// Create from JSON.
  factory FormSection.fromJson(Map<String, dynamic> json) {
    return FormSection(
      sectionId: json['sectionId'] as String,
      index: json['index'] as int,
      title: json['title'] as String?,
      description: json['description'] as String?,
      blocks: (json['blocks'] as List<dynamic>?)
              ?.map(
                (e) => FormBlock.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'sectionId': sectionId,
        'index': index,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        'blocks': blocks.map((b) => b.toJson()).toList(),
      };
}

// ============================================================================
// Block Hierarchy
// ============================================================================

/// Abstract base class for content blocks within a form document.
///
/// Use [FormBlock.fromJson] factory to deserialize, which dispatches
/// to the correct subtype based on the 'type' field.
abstract class FormBlock {
  /// Unique block identifier.
  final String blockId;

  /// Type of this block.
  final FormBlockType type;

  /// Block ordering index.
  final int index;

  /// Optional style properties.
  final Map<String, dynamic>? style;

  // Cannot be const due to Map<String, dynamic>? style field.
  FormBlock({
    required this.blockId,
    required this.type,
    required this.index,
    this.style,
  });

  /// Create the appropriate [FormBlock] subtype from JSON.
  ///
  /// Dispatches based on the 'type' field to the correct subtype.
  factory FormBlock.fromJson(Map<String, dynamic> json) {
    final blockType = FormBlockType.fromString(json['type'] as String);
    switch (blockType) {
      case FormBlockType.text:
        return FormTextBlock.fromJson(json);
      case FormBlockType.heading:
        return FormHeadingBlock.fromJson(json);
      case FormBlockType.table:
        return FormTableBlock.fromJson(json);
      case FormBlockType.chart:
        return FormChartBlock.fromJson(json);
      case FormBlockType.image:
        return FormImageBlock.fromJson(json);
      case FormBlockType.formField:
        return FormFieldBlock.fromJson(json);
      case FormBlockType.repeatable:
        return FormRepeatableBlock.fromJson(json);
      case FormBlockType.conditional:
        return FormConditionalBlock.fromJson(json);
      case FormBlockType.canvas:
        return FormCanvasBlock.fromJson(json);
    }
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson();

  /// Serialize common base fields to a map.
  Map<String, dynamic> baseToJson() => {
        'blockId': blockId,
        'type': type.name,
        'index': index,
        if (style != null) 'style': style,
      };
}

/// A plain text content block.
class FormTextBlock extends FormBlock {
  /// Text content.
  final String content;

  /// Content format (e.g., 'plain', 'markdown', 'html').
  final String format;

  FormTextBlock({
    required super.blockId,
    required super.index,
    super.style,
    required this.content,
    this.format = 'plain',
  }) : super(type: FormBlockType.text);

  /// Create from JSON.
  factory FormTextBlock.fromJson(Map<String, dynamic> json) {
    return FormTextBlock(
      blockId: json['blockId'] as String,
      index: json['index'] as int,
      style: json['style'] as Map<String, dynamic>?,
      content: json['content'] as String,
      format: json['format'] as String? ?? 'plain',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'content': content,
        'format': format,
      };
}

/// A heading content block with level.
class FormHeadingBlock extends FormBlock {
  /// Heading text.
  final String content;

  /// Heading level (1-6).
  final int level;

  /// Whether automatic numbering is applied.
  final bool? numbering;

  FormHeadingBlock({
    required super.blockId,
    required super.index,
    super.style,
    required this.content,
    this.level = 1,
    this.numbering,
  }) : super(type: FormBlockType.heading);

  /// Create from JSON.
  factory FormHeadingBlock.fromJson(Map<String, dynamic> json) {
    return FormHeadingBlock(
      blockId: json['blockId'] as String,
      index: json['index'] as int,
      style: json['style'] as Map<String, dynamic>?,
      content: json['content'] as String,
      level: json['level'] as int? ?? 1,
      numbering: json['numbering'] as bool?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'content': content,
        'level': level,
        if (numbering != null) 'numbering': numbering,
      };
}

/// A table content block with columns and rows.
class FormTableBlock extends FormBlock {
  /// Table column definitions.
  final List<FormTableColumn> columns;

  /// Table row data.
  final List<FormTableRow> rows;

  /// Whether the header row repeats on each page.
  final bool headerRepeat;

  /// Maximum number of rows allowed.
  final int? maxRows;

  /// Unit label for the table data.
  final String? unit;

  FormTableBlock({
    required super.blockId,
    required super.index,
    super.style,
    required this.columns,
    this.rows = const [],
    this.headerRepeat = false,
    this.maxRows,
    this.unit,
  }) : super(type: FormBlockType.table);

  /// Create from JSON.
  factory FormTableBlock.fromJson(Map<String, dynamic> json) {
    return FormTableBlock(
      blockId: json['blockId'] as String,
      index: json['index'] as int,
      style: json['style'] as Map<String, dynamic>?,
      columns: (json['columns'] as List<dynamic>?)
              ?.map(
                (e) => FormTableColumn.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      rows: (json['rows'] as List<dynamic>?)
              ?.map(
                (e) => FormTableRow.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      headerRepeat: json['headerRepeat'] as bool? ?? false,
      maxRows: json['maxRows'] as int?,
      unit: json['unit'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'columns': columns.map((c) => c.toJson()).toList(),
        'rows': rows.map((r) => r.toJson()).toList(),
        'headerRepeat': headerRepeat,
        if (maxRows != null) 'maxRows': maxRows,
        if (unit != null) 'unit': unit,
      };
}

/// A chart visualization block.
class FormChartBlock extends FormBlock {
  /// Chart type (e.g., 'bar', 'line', 'pie').
  final String chartType;

  /// Chart data series.
  final List<dynamic> data;

  /// Optional chart title.
  final String? title;

  /// X-axis configuration.
  final FormAxisConfig? xAxis;

  /// Y-axis configuration.
  final FormAxisConfig? yAxis;

  /// Unit label for the chart data.
  final String? unit;

  FormChartBlock({
    required super.blockId,
    required super.index,
    super.style,
    required this.chartType,
    this.data = const [],
    this.title,
    this.xAxis,
    this.yAxis,
    this.unit,
  }) : super(type: FormBlockType.chart);

  /// Create from JSON.
  factory FormChartBlock.fromJson(Map<String, dynamic> json) {
    return FormChartBlock(
      blockId: json['blockId'] as String,
      index: json['index'] as int,
      style: json['style'] as Map<String, dynamic>?,
      chartType: json['chartType'] as String,
      data: json['data'] as List<dynamic>? ?? [],
      title: json['title'] as String?,
      xAxis: json['xAxis'] != null
          ? FormAxisConfig.fromJson(json['xAxis'] as Map<String, dynamic>)
          : null,
      yAxis: json['yAxis'] != null
          ? FormAxisConfig.fromJson(json['yAxis'] as Map<String, dynamic>)
          : null,
      unit: json['unit'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'chartType': chartType,
        'data': data,
        if (title != null) 'title': title,
        if (xAxis != null) 'xAxis': xAxis!.toJson(),
        if (yAxis != null) 'yAxis': yAxis!.toJson(),
        if (unit != null) 'unit': unit,
      };
}

/// An image content block.
class FormImageBlock extends FormBlock {
  /// Image source URL or path.
  final String src;

  /// Alternative text for the image.
  final String? alt;

  /// Maximum width in logical pixels.
  final double? maxWidth;

  /// Aspect ratio (width / height).
  final double? aspectRatio;

  FormImageBlock({
    required super.blockId,
    required super.index,
    super.style,
    required this.src,
    this.alt,
    this.maxWidth,
    this.aspectRatio,
  }) : super(type: FormBlockType.image);

  /// Create from JSON.
  factory FormImageBlock.fromJson(Map<String, dynamic> json) {
    return FormImageBlock(
      blockId: json['blockId'] as String,
      index: json['index'] as int,
      style: json['style'] as Map<String, dynamic>?,
      src: json['src'] as String,
      alt: json['alt'] as String?,
      maxWidth: (json['maxWidth'] as num?)?.toDouble(),
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'src': src,
        if (alt != null) 'alt': alt,
        if (maxWidth != null) 'maxWidth': maxWidth,
        if (aspectRatio != null) 'aspectRatio': aspectRatio,
      };
}

/// A live canvas scene embed.
///
/// Unlike [FormImageBlock] (static bitmap) or [FormChartBlock] (structured
/// data), this block references a scene in the host project and is rendered
/// against the **current project state** at document render time by a
/// `CanvasBindingResolver`. Typical uses: embed a schematic page, a PCB
/// top view, a mechanical 3D assembly, or a generated UI preview inside
/// a design-spec document.
///
/// The block is format-agnostic at the data layer: it carries a [target]
/// reference plus render hints. The host (e.g. Designer) wires a resolver
/// that knows how to project the current scene into bytes of the requested
/// [format]. Renderers that cannot consume vector output fall back to
/// [fallback] — typically a bitmap.
class FormCanvasBlock extends FormBlock {
  /// Scene reference — resolver-specific. Examples:
  ///   `canvas://schematic.main`
  ///   `canvas://pcb.top-view`
  ///   `canvas://mechanical.assembly#exploded`
  final String target;

  /// Canvas editor mode the resolver should render in.
  /// One of: `'canvas'` (2D/3D engineering), `'ui'` (UI editor runtime),
  /// `'form'` (nested document — resolver may reject).
  final String mode;

  /// Preferred output format. One of: `'svg'`, `'png'`, `'pdf-vector'`,
  /// `'json'`. If the active document renderer does not support the
  /// requested format it SHOULD downgrade via [fallback].
  final String format;

  /// Fallback strategy when [format] is not supported by the active
  /// renderer. `'bitmap'` (default) raster-rasterises into PNG at the
  /// block's physical size; `'skip'` emits a placeholder.
  final String fallback;

  /// Optional viewport hint — resolver-specific map (e.g. `{zoom: 1.2,
  /// center: [x, y]}`). Opaque to mcp_form; passed through to the resolver.
  final Map<String, dynamic>? viewport;

  /// Maximum rendered width in logical pixels (renderer decides how to
  /// scale if narrower, e.g. to fit document width).
  final double? maxWidth;

  /// Aspect ratio (width / height). Enforced by the renderer so page
  /// layout stays stable across scene updates.
  final double? aspectRatio;

  /// Optional caption — rendered below the scene by most renderers.
  final String? caption;

  /// Alternative text for accessibility / fallback text formats.
  final String? alt;

  FormCanvasBlock({
    required super.blockId,
    required super.index,
    super.style,
    required this.target,
    this.mode = 'canvas',
    this.format = 'svg',
    this.fallback = 'bitmap',
    this.viewport,
    this.maxWidth,
    this.aspectRatio,
    this.caption,
    this.alt,
  }) : super(type: FormBlockType.canvas);

  factory FormCanvasBlock.fromJson(Map<String, dynamic> json) {
    return FormCanvasBlock(
      blockId: json['blockId'] as String,
      index: json['index'] as int,
      style: json['style'] as Map<String, dynamic>?,
      target: json['target'] as String,
      mode: json['mode'] as String? ?? 'canvas',
      format: json['format'] as String? ?? 'svg',
      fallback: json['fallback'] as String? ?? 'bitmap',
      viewport: json['viewport'] as Map<String, dynamic>?,
      maxWidth: (json['maxWidth'] as num?)?.toDouble(),
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
      caption: json['caption'] as String?,
      alt: json['alt'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'target': target,
        'mode': mode,
        'format': format,
        'fallback': fallback,
        if (viewport != null) 'viewport': viewport,
        if (maxWidth != null) 'maxWidth': maxWidth,
        if (aspectRatio != null) 'aspectRatio': aspectRatio,
        if (caption != null) 'caption': caption,
        if (alt != null) 'alt': alt,
      };
}

/// An interactive form field block.
class FormFieldBlock extends FormBlock {
  /// Field name for data binding.
  final String fieldName;

  /// Field type (e.g., 'text', 'number', 'date', 'select').
  final String fieldType;

  /// Placeholder text.
  final String? placeholder;

  /// Options for select/radio/checkbox fields.
  final List<dynamic>? options;

  /// Constraints for the field value.
  final Map<String, dynamic>? constraints;

  FormFieldBlock({
    required super.blockId,
    required super.index,
    super.style,
    required this.fieldName,
    required this.fieldType,
    this.placeholder,
    this.options,
    this.constraints,
  }) : super(type: FormBlockType.formField);

  /// Create from JSON.
  factory FormFieldBlock.fromJson(Map<String, dynamic> json) {
    return FormFieldBlock(
      blockId: json['blockId'] as String,
      index: json['index'] as int,
      style: json['style'] as Map<String, dynamic>?,
      fieldName: json['fieldName'] as String,
      fieldType: json['fieldType'] as String,
      placeholder: json['placeholder'] as String?,
      options: json['options'] as List<dynamic>?,
      constraints: json['constraints'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'fieldName': fieldName,
        'fieldType': fieldType,
        if (placeholder != null) 'placeholder': placeholder,
        if (options != null) 'options': options,
        if (constraints != null) 'constraints': constraints,
      };
}

/// A repeatable block that generates multiple instances from a template.
class FormRepeatableBlock extends FormBlock {
  /// Template blocks to repeat for each item.
  /// Each item instance consists of all blocks in this list.
  final List<FormBlock> itemTemplate;

  /// Data binding path for the items collection.
  final String? itemsBinding;

  /// Minimum number of items.
  final int? minItems;

  /// Maximum number of items.
  final int? maxItems;

  FormRepeatableBlock({
    required super.blockId,
    required super.index,
    super.style,
    required this.itemTemplate,
    this.itemsBinding,
    this.minItems,
    this.maxItems,
  }) : super(type: FormBlockType.repeatable);

  /// Create from JSON.
  factory FormRepeatableBlock.fromJson(Map<String, dynamic> json) {
    return FormRepeatableBlock(
      blockId: json['blockId'] as String,
      index: json['index'] as int,
      style: json['style'] as Map<String, dynamic>?,
      itemTemplate: (json['itemTemplate'] as List<dynamic>)
          .map((e) => FormBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemsBinding: json['itemsBinding'] as String?,
      minItems: json['minItems'] as int?,
      maxItems: json['maxItems'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'itemTemplate': itemTemplate.map((b) => b.toJson()).toList(),
        if (itemsBinding != null) 'itemsBinding': itemsBinding,
        if (minItems != null) 'minItems': minItems,
        if (maxItems != null) 'maxItems': maxItems,
      };
}

/// A conditional block that renders different content based on a condition.
class FormConditionalBlock extends FormBlock {
  /// Condition expression to evaluate.
  final String condition;

  /// Block to render when the condition is true.
  final FormBlock thenBlock;

  /// Optional block to render when the condition is false.
  final FormBlock? elseBlock;

  FormConditionalBlock({
    required super.blockId,
    required super.index,
    super.style,
    required this.condition,
    required this.thenBlock,
    this.elseBlock,
  }) : super(type: FormBlockType.conditional);

  /// Create from JSON.
  factory FormConditionalBlock.fromJson(Map<String, dynamic> json) {
    return FormConditionalBlock(
      blockId: json['blockId'] as String,
      index: json['index'] as int,
      style: json['style'] as Map<String, dynamic>?,
      condition: json['condition'] as String,
      thenBlock: FormBlock.fromJson(
        json['thenBlock'] as Map<String, dynamic>,
      ),
      elseBlock: json['elseBlock'] != null
          ? FormBlock.fromJson(json['elseBlock'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'condition': condition,
        'thenBlock': thenBlock.toJson(),
        if (elseBlock != null) 'elseBlock': elseBlock!.toJson(),
      };
}

// ============================================================================
// Table / Chart Helpers
// ============================================================================

/// Column definition for a table block.
class FormTableColumn {
  /// Unique column identifier.
  final String id;

  /// Column display title.
  final String title;

  /// Data type of the column (e.g., 'string', 'number', 'date').
  final String type;

  /// Optional column width.
  final double? width;

  /// Optional column alignment ('left', 'center', 'right').
  final String? alignment;

  const FormTableColumn({
    required this.id,
    required this.title,
    required this.type,
    this.width,
    this.alignment,
  });

  /// Create from JSON.
  factory FormTableColumn.fromJson(Map<String, dynamic> json) {
    return FormTableColumn(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      width: (json['width'] as num?)?.toDouble(),
      alignment: json['alignment'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        if (width != null) 'width': width,
        if (alignment != null) 'alignment': alignment,
      };
}

/// A row of data in a table block.
class FormTableRow {
  /// Cell values keyed by column id.
  final Map<String, dynamic> cells;

  /// Optional row-level attributes.
  final Map<String, dynamic>? attributes;

  // Cannot be const due to Map<String, dynamic> fields.
  FormTableRow({
    required this.cells,
    this.attributes,
  });

  /// Create from JSON.
  factory FormTableRow.fromJson(Map<String, dynamic> json) {
    return FormTableRow(
      cells: Map<String, dynamic>.from(json['cells'] as Map? ?? {}),
      attributes: json['attributes'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'cells': cells,
        if (attributes != null) 'attributes': attributes,
      };
}

/// Axis configuration for a chart block.
class FormAxisConfig {
  /// Axis label.
  final String? label;

  /// Unit for the axis values.
  final String? unit;

  /// Minimum axis value.
  final double? min;

  /// Maximum axis value.
  final double? max;

  const FormAxisConfig({
    this.label,
    this.unit,
    this.min,
    this.max,
  });

  /// Create from JSON.
  factory FormAxisConfig.fromJson(Map<String, dynamic> json) {
    return FormAxisConfig(
      label: json['label'] as String?,
      unit: json['unit'] as String?,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        if (label != null) 'label': label,
        if (unit != null) 'unit': unit,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
      };
}

// ============================================================================
// Schema & Layout
// ============================================================================

/// Schema definition for form validation.
class FormSchema {
  /// Field definitions.
  final List<FormSchemaField> fields;

  /// Validation rules.
  final List<FormSchemaRule> rules;

  /// Whether strict mode is enabled (reject unknown fields).
  final bool strict;

  const FormSchema({
    this.fields = const [],
    this.rules = const [],
    this.strict = false,
  });

  /// Create from JSON.
  factory FormSchema.fromJson(Map<String, dynamic> json) {
    return FormSchema(
      fields: (json['fields'] as List<dynamic>?)
              ?.map(
                (e) => FormSchemaField.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      rules: (json['rules'] as List<dynamic>?)
              ?.map(
                (e) => FormSchemaRule.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      strict: json['strict'] as bool? ?? false,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'fields': fields.map((f) => f.toJson()).toList(),
        'rules': rules.map((r) => r.toJson()).toList(),
        'strict': strict,
      };
}

/// A field definition within a form schema.
class FormSchemaField {
  /// Field name.
  final String name;

  /// Field data type (e.g., 'string', 'number', 'boolean', 'date').
  final String type;

  /// Whether the field is required.
  final bool required;

  /// Display label.
  final String? label;

  /// Placeholder text.
  final String? placeholder;

  /// Expected format (e.g., 'email', 'url', 'date-time').
  final String? format;

  /// Minimum value (for numeric types).
  final dynamic minValue;

  /// Maximum value (for numeric types).
  final dynamic maxValue;

  /// Regular expression pattern for validation.
  final String? pattern;

  /// Allowed enumeration values.
  final List<dynamic>? enumValues;

  /// Field description.
  final String? description;

  /// Whether this field contains sensitive data.
  final bool sensitive;

  // Cannot be const due to dynamic fields.
  FormSchemaField({
    required this.name,
    required this.type,
    this.required = false,
    this.label,
    this.placeholder,
    this.format,
    this.minValue,
    this.maxValue,
    this.pattern,
    this.enumValues,
    this.description,
    this.sensitive = false,
  });

  /// Create from JSON.
  factory FormSchemaField.fromJson(Map<String, dynamic> json) {
    return FormSchemaField(
      name: json['name'] as String,
      type: json['type'] as String,
      required: json['required'] as bool? ?? false,
      label: json['label'] as String?,
      placeholder: json['placeholder'] as String?,
      format: json['format'] as String?,
      minValue: json['minValue'],
      maxValue: json['maxValue'],
      pattern: json['pattern'] as String?,
      enumValues: json['enumValues'] as List<dynamic>?,
      description: json['description'] as String?,
      sensitive: json['sensitive'] as bool? ?? false,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'required': required,
        if (label != null) 'label': label,
        if (placeholder != null) 'placeholder': placeholder,
        if (format != null) 'format': format,
        if (minValue != null) 'minValue': minValue,
        if (maxValue != null) 'maxValue': maxValue,
        if (pattern != null) 'pattern': pattern,
        if (enumValues != null) 'enumValues': enumValues,
        if (description != null) 'description': description,
        if (sensitive) 'sensitive': sensitive,
      };
}

/// A validation rule within a form schema.
class FormSchemaRule {
  /// Unique rule identifier.
  final String ruleId;

  /// Human-readable description of the rule.
  final String description;

  /// Expression to evaluate for validation.
  final String expression;

  /// Error message to display when the rule fails.
  final String? errorMessage;

  const FormSchemaRule({
    required this.ruleId,
    required this.description,
    required this.expression,
    this.errorMessage,
  });

  /// Create from JSON.
  factory FormSchemaRule.fromJson(Map<String, dynamic> json) {
    return FormSchemaRule(
      ruleId: json['ruleId'] as String,
      description: json['description'] as String,
      expression: json['expression'] as String,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'ruleId': ruleId,
        'description': description,
        'expression': expression,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };
}

/// Layout policy for form document rendering.
class FormLayoutPolicy {
  /// Page size configuration.
  final FormPageSize pageSize;

  /// Page margins.
  final FormMargins margins;

  /// Primary font family.
  final String fontFamily;

  /// Font policy configuration.
  final FormFontPolicy fontPolicy;

  /// Number of grid columns for layout.
  final int gridColumns;

  /// Maximum number of rows in tables.
  final int? maxTableRows;

  /// Maximum line length in characters.
  final int? maxLineLength;

  /// Whether automatic text wrapping is enabled.
  final bool autoWrap;

  /// Whether automatic scaling is enabled.
  final bool autoScale;

  const FormLayoutPolicy({
    required this.pageSize,
    required this.margins,
    this.fontFamily = 'sans-serif',
    required this.fontPolicy,
    this.gridColumns = 12,
    this.maxTableRows,
    this.maxLineLength,
    this.autoWrap = true,
    this.autoScale = false,
  });

  /// Create from JSON.
  factory FormLayoutPolicy.fromJson(Map<String, dynamic> json) {
    return FormLayoutPolicy(
      pageSize: FormPageSize.fromJson(
        json['pageSize'] as Map<String, dynamic>,
      ),
      margins: FormMargins.fromJson(
        json['margins'] as Map<String, dynamic>,
      ),
      fontFamily: json['fontFamily'] as String? ?? 'sans-serif',
      fontPolicy: FormFontPolicy.fromJson(
        json['fontPolicy'] as Map<String, dynamic>,
      ),
      gridColumns: json['gridColumns'] as int? ?? 12,
      maxTableRows: json['maxTableRows'] as int?,
      maxLineLength: json['maxLineLength'] as int?,
      autoWrap: json['autoWrap'] as bool? ?? true,
      autoScale: json['autoScale'] as bool? ?? false,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'pageSize': pageSize.toJson(),
        'margins': margins.toJson(),
        'fontFamily': fontFamily,
        'fontPolicy': fontPolicy.toJson(),
        'gridColumns': gridColumns,
        if (maxTableRows != null) 'maxTableRows': maxTableRows,
        if (maxLineLength != null) 'maxLineLength': maxLineLength,
        'autoWrap': autoWrap,
        'autoScale': autoScale,
      };
}

/// Page size configuration for form layout.
class FormPageSize {
  /// Named page size (e.g., 'A4', 'Letter').
  final String size;

  /// Width in millimeters.
  final double width;

  /// Height in millimeters.
  final double height;

  /// Page orientation ('portrait' or 'landscape').
  final String orientation;

  const FormPageSize({
    required this.size,
    required this.width,
    required this.height,
    this.orientation = 'portrait',
  });

  /// Create from JSON.
  factory FormPageSize.fromJson(Map<String, dynamic> json) {
    return FormPageSize(
      size: json['size'] as String,
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      orientation: json['orientation'] as String? ?? 'portrait',
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'size': size,
        'width': width,
        'height': height,
        'orientation': orientation,
      };
}

/// Margin configuration for form layout.
class FormMargins {
  /// Top margin in millimeters.
  final double top;

  /// Right margin in millimeters.
  final double right;

  /// Bottom margin in millimeters.
  final double bottom;

  /// Left margin in millimeters.
  final double left;

  const FormMargins({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  /// Create from JSON.
  factory FormMargins.fromJson(Map<String, dynamic> json) {
    return FormMargins(
      top: (json['top'] as num).toDouble(),
      right: (json['right'] as num).toDouble(),
      bottom: (json['bottom'] as num).toDouble(),
      left: (json['left'] as num).toDouble(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'top': top,
        'right': right,
        'bottom': bottom,
        'left': left,
      };
}

/// Font policy configuration for form layout.
class FormFontPolicy {
  /// Default font family name.
  final String defaultFont;

  /// Default font size in points.
  final double defaultSize;

  /// Heading font size in points.
  final double headingSize;

  /// Body text font size in points.
  final double bodySize;

  /// Minimum font size in points.
  final double minSize;

  const FormFontPolicy({
    required this.defaultFont,
    required this.defaultSize,
    required this.headingSize,
    required this.bodySize,
    required this.minSize,
  });

  /// Create from JSON.
  factory FormFontPolicy.fromJson(Map<String, dynamic> json) {
    return FormFontPolicy(
      defaultFont: json['defaultFont'] as String,
      defaultSize: (json['defaultSize'] as num).toDouble(),
      headingSize: (json['headingSize'] as num).toDouble(),
      bodySize: (json['bodySize'] as num).toDouble(),
      minSize: (json['minSize'] as num).toDouble(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'defaultFont': defaultFont,
        'defaultSize': defaultSize,
        'headingSize': headingSize,
        'bodySize': bodySize,
        'minSize': minSize,
      };
}

// ============================================================================
// Binding, Patch, Validation
// ============================================================================

/// A data binding that connects a form field to a data source.
class FormDataBinding {
  /// Unique binding identifier.
  final String bindingId;

  /// Path to the field in the form document.
  final String fieldPath;

  /// Path to the data in the source.
  final String dataPath;

  /// Type of data source.
  final FormDataSourceType source;

  /// Query expression for the source.
  final String? sourceQuery;

  /// Tool name for tool-based sources.
  final String? toolName;

  /// Parameters for tool-based sources.
  final Map<String, dynamic>? toolParams;

  /// Transform expression to apply to the data.
  final String? transform;

  /// Whether this binding is required.
  final bool required;

  /// Default value if the binding cannot be resolved.
  final dynamic defaultValue;

  /// Whether the binding has been filled with data.
  final bool isFilled;

  /// When the binding was filled.
  final DateTime? filledAt;

  // Cannot be const due to Map<String, dynamic>? toolParams field.
  FormDataBinding({
    required this.bindingId,
    required this.fieldPath,
    required this.dataPath,
    required this.source,
    this.sourceQuery,
    this.toolName,
    this.toolParams,
    this.transform,
    this.required = false,
    this.defaultValue,
    this.isFilled = false,
    this.filledAt,
  });

  /// Create from JSON.
  factory FormDataBinding.fromJson(Map<String, dynamic> json) {
    return FormDataBinding(
      bindingId: json['bindingId'] as String,
      fieldPath: json['fieldPath'] as String,
      dataPath: json['dataPath'] as String,
      source: FormDataSourceType.fromString(
        json['source'] as String? ?? 'userInput',
      ),
      sourceQuery: json['sourceQuery'] as String?,
      toolName: json['toolName'] as String?,
      toolParams: json['toolParams'] as Map<String, dynamic>?,
      transform: json['transform'] as String?,
      required: json['required'] as bool? ?? false,
      defaultValue: json['defaultValue'],
      isFilled: json['isFilled'] as bool? ?? false,
      filledAt: json['filledAt'] != null
          ? DateTime.parse(json['filledAt'] as String)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'bindingId': bindingId,
        'fieldPath': fieldPath,
        'dataPath': dataPath,
        'source': source.name,
        if (sourceQuery != null) 'sourceQuery': sourceQuery,
        if (toolName != null) 'toolName': toolName,
        if (toolParams != null) 'toolParams': toolParams,
        if (transform != null) 'transform': transform,
        'required': required,
        if (defaultValue != null) 'defaultValue': defaultValue,
        'isFilled': isFilled,
        if (filledAt != null) 'filledAt': filledAt!.toIso8601String(),
      };
}

/// A JSON Patch operation for updating a form document.
class FormPatchOperation {
  /// Operation type (e.g., 'add', 'remove', 'replace', 'move', 'copy', 'test').
  final String op;

  /// Target path in the document.
  final String path;

  /// Value for add/replace/test operations.
  final dynamic value;

  /// Source path for move/copy operations.
  final String? from;

  // Cannot be const due to dynamic value field.
  FormPatchOperation({
    required this.op,
    required this.path,
    this.value,
    this.from,
  });

  /// Create from JSON.
  factory FormPatchOperation.fromJson(Map<String, dynamic> json) {
    return FormPatchOperation(
      op: json['op'] as String,
      path: json['path'] as String,
      value: json['value'],
      from: json['from'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'op': op,
        'path': path,
        if (value != null) 'value': value,
        if (from != null) 'from': from,
      };
}

/// Result of a form document validation.
class FormValidationResult {
  /// Whether the document is valid.
  final bool isValid;

  /// List of validation issues found.
  final List<FormValidationIssue> issues;

  /// Auto-fix actions that were applied.
  final List<FormAutoFixAction>? appliedFixes;

  const FormValidationResult({
    required this.isValid,
    this.issues = const [],
    this.appliedFixes,
  });

  /// Create from JSON.
  factory FormValidationResult.fromJson(Map<String, dynamic> json) {
    return FormValidationResult(
      isValid: json['isValid'] as bool,
      issues: (json['issues'] as List<dynamic>?)
              ?.map(
                (e) => FormValidationIssue.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      appliedFixes: (json['appliedFixes'] as List<dynamic>?)
          ?.map(
            (e) => FormAutoFixAction.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'issues': issues.map((i) => i.toJson()).toList(),
        if (appliedFixes != null)
          'appliedFixes': appliedFixes!.map((f) => f.toJson()).toList(),
      };
}

/// A validation issue found during document validation.
class FormValidationIssue {
  /// Issue code for programmatic handling.
  final String code;

  /// Human-readable issue message.
  final String message;

  /// Path to the problematic field or block.
  final String path;

  /// Severity level (e.g., 'error', 'warning', 'info').
  final String? severity;

  /// Additional context for the issue.
  final Map<String, dynamic>? context;

  // Cannot be const due to Map<String, dynamic>? context field.
  FormValidationIssue({
    required this.code,
    required this.message,
    required this.path,
    this.severity,
    this.context,
  });

  /// Create from JSON.
  factory FormValidationIssue.fromJson(Map<String, dynamic> json) {
    return FormValidationIssue(
      code: json['code'] as String,
      message: json['message'] as String,
      path: json['path'] as String,
      severity: json['severity'] as String?,
      context: json['context'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        'path': path,
        if (severity != null) 'severity': severity,
        if (context != null) 'context': context,
      };
}

/// An auto-fix action applied during validation.
class FormAutoFixAction {
  /// Action type (e.g., 'set_default', 'trim', 'coerce').
  final String action;

  /// Path to the field that was fixed.
  final String path;

  /// Description of the fix applied.
  final String description;

  /// Additional details about the fix.
  final Map<String, dynamic>? details;

  // Cannot be const due to Map<String, dynamic>? details field.
  FormAutoFixAction({
    required this.action,
    required this.path,
    required this.description,
    this.details,
  });

  /// Create from JSON.
  factory FormAutoFixAction.fromJson(Map<String, dynamic> json) {
    return FormAutoFixAction(
      action: json['action'] as String,
      path: json['path'] as String,
      description: json['description'] as String,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'action': action,
        'path': path,
        'description': description,
        if (details != null) 'details': details,
      };
}

/// Generic result wrapper for form operations.
///
/// The [fromJson] factory requires a converter function to deserialize
/// the generic data field.
class FormResult<T> {
  /// Whether the operation succeeded.
  final bool success;

  /// Result data on success.
  final T? data;

  /// Error details on failure.
  final FormError? error;

  /// Optional warnings from the operation.
  final List<FormError>? warnings;

  const FormResult({
    required this.success,
    this.data,
    this.error,
    this.warnings,
  });

  /// Create a successful result.
  const FormResult.ok(T this.data)
      : success = true,
        error = null,
        warnings = null;

  /// Create a failed result.
  const FormResult.fail(FormError this.error)
      : success = false,
        data = null,
        warnings = null;

  /// Create from JSON with a converter for the generic data field.
  factory FormResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) dataFromJson,
  ) {
    return FormResult(
      success: json['success'] as bool,
      data: json['data'] != null
          ? dataFromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error'] != null
          ? FormError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      warnings: (json['warnings'] as List<dynamic>?)
          ?.map((e) => FormError.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert to JSON.
  ///
  /// The [dataToJson] function serializes the generic data field.
  /// If not provided, the data is included as-is (assumes it is
  /// already JSON-compatible or has a toJson method).
  Map<String, dynamic> toJson([
    Map<String, dynamic> Function(T)? dataToJson,
  ]) =>
      {
        'success': success,
        if (data != null)
          'data': dataToJson != null ? dataToJson(data as T) : data,
        if (error != null) 'error': error!.toJson(),
        if (warnings != null)
          'warnings': warnings!.map((w) => w.toJson()).toList(),
      };
}

/// Error details for form operations.
class FormError {
  /// Error code for programmatic handling.
  final String code;

  /// Human-readable error message.
  final String message;

  /// Path to the source of the error.
  final String? path;

  /// Additional error context.
  final Map<String, dynamic>? context;

  /// Suggested fix or next action.
  final String? suggestion;

  // Cannot be const due to Map<String, dynamic>? context field.
  FormError({
    required this.code,
    required this.message,
    this.path,
    this.context,
    this.suggestion,
  });

  /// Create from JSON.
  factory FormError.fromJson(Map<String, dynamic> json) {
    return FormError(
      code: json['code'] as String,
      message: json['message'] as String,
      path: json['path'] as String?,
      context: json['context'] as Map<String, dynamic>?,
      suggestion: json['suggestion'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        if (path != null) 'path': path,
        if (context != null) 'context': context,
        if (suggestion != null) 'suggestion': suggestion,
      };
}

// ============================================================================
// Form Port Interface
// ============================================================================

/// Abstract port for form document operations.
///
/// Provides contracts for creating, validating, querying, patching,
/// and tracking version history of form documents.
abstract class FormPort {
  /// Create a new form document from a template with initial data.
  Future<FormResult<FormDocument>> createDocument({
    required String templateId,
    required Map<String, dynamic> initialData,
    String? documentId,
    String? author,
  });

  /// Validate a form document, optionally applying auto-fixes.
  Future<FormResult<FormValidationResult>> validate({
    required FormDocument document,
    bool autoFix = false,
  });

  /// Retrieve a form document by its identifier.
  Future<FormResult<FormDocument>> getDocument({
    required String documentId,
  });

  /// List form documents with optional filtering.
  Future<FormResult<List<FormDocument>>> listDocuments({
    String? templateId,
    String? status,
    int? limit,
    int? offset,
  });

  /// Apply patch operations to a form document.
  Future<FormResult<FormDocument>> patch({
    required String documentId,
    required List<FormPatchOperation> operations,
    required int targetVersion,
  });

  /// Retrieve the version history of a form document.
  Future<FormResult<List<FormDocumentVersion>>> getDocumentHistory({
    required String documentId,
  });
}

// ============================================================================
// Stub Implementation
// ============================================================================

/// Stub form port for testing.
class StubFormPort implements FormPort {
  /// In-memory document store.
  final Map<String, FormDocument> _documents = {};

  @override
  Future<FormResult<FormDocument>> createDocument({
    required String templateId,
    required Map<String, dynamic> initialData,
    String? documentId,
    String? author,
  }) async {
    final id = documentId ?? 'doc-${DateTime.now().millisecondsSinceEpoch}';
    final document = FormDocument(
      documentId: id,
      templateId: templateId,
      templateVersion: '1.0.0',
      metadata: FormDocumentMetadata(
        author: author ?? 'stub',
        createdAt: DateTime.now(),
      ),
      status: FormDocumentStatus.draft,
      version: 1,
      data: initialData,
    );
    _documents[id] = document;
    return FormResult.ok(document);
  }

  @override
  Future<FormResult<FormValidationResult>> validate({
    required FormDocument document,
    bool autoFix = false,
  }) async {
    return const FormResult.ok(
      FormValidationResult(isValid: true),
    );
  }

  @override
  Future<FormResult<FormDocument>> getDocument({
    required String documentId,
  }) async {
    final document = _documents[documentId];
    if (document == null) {
      return FormResult.fail(
        FormError(
          code: 'NOT_FOUND',
          message: 'Document not found: $documentId',
        ),
      );
    }
    return FormResult.ok(document);
  }

  @override
  Future<FormResult<List<FormDocument>>> listDocuments({
    String? templateId,
    String? status,
    int? limit,
    int? offset,
  }) async {
    var results = _documents.values.toList();

    if (templateId != null) {
      results = results.where((d) => d.templateId == templateId).toList();
    }
    if (status != null) {
      results = results.where((d) => d.status.name == status).toList();
    }

    final start = offset ?? 0;
    if (start > 0 && start < results.length) {
      results = results.sublist(start);
    }
    if (limit != null && limit < results.length) {
      results = results.sublist(0, limit);
    }

    return FormResult.ok(results);
  }

  @override
  Future<FormResult<FormDocument>> patch({
    required String documentId,
    required List<FormPatchOperation> operations,
    required int targetVersion,
  }) async {
    final document = _documents[documentId];
    if (document == null) {
      return FormResult.fail(
        FormError(
          code: 'NOT_FOUND',
          message: 'Document not found: $documentId',
        ),
      );
    }
    return FormResult.ok(document);
  }

  @override
  Future<FormResult<List<FormDocumentVersion>>> getDocumentHistory({
    required String documentId,
  }) async {
    return const FormResult.ok([]);
  }
}
