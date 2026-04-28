import 'package:test/test.dart';
import 'package:mcp_bundle/ports.dart';

void main() {
  // ==========================================================================
  // FormPort
  // ==========================================================================
  group('FormPort', () {
    // ------------------------------------------------------------------------
    // Enums
    // ------------------------------------------------------------------------
    group('FormDocumentStatus', () {
      test('has all expected values', () {
        expect(FormDocumentStatus.values.length, equals(4));
        expect(FormDocumentStatus.values, contains(FormDocumentStatus.draft));
        expect(FormDocumentStatus.values, contains(FormDocumentStatus.review));
        expect(
          FormDocumentStatus.values,
          contains(FormDocumentStatus.approved),
        );
        expect(
          FormDocumentStatus.values,
          contains(FormDocumentStatus.published),
        );
      });

      test('fromString parses valid names', () {
        expect(
          FormDocumentStatus.fromString('draft'),
          equals(FormDocumentStatus.draft),
        );
        expect(
          FormDocumentStatus.fromString('review'),
          equals(FormDocumentStatus.review),
        );
        expect(
          FormDocumentStatus.fromString('approved'),
          equals(FormDocumentStatus.approved),
        );
        expect(
          FormDocumentStatus.fromString('published'),
          equals(FormDocumentStatus.published),
        );
      });

      test('fromString defaults to draft for unknown value', () {
        expect(
          FormDocumentStatus.fromString('invalid'),
          equals(FormDocumentStatus.draft),
        );
        expect(
          FormDocumentStatus.fromString(''),
          equals(FormDocumentStatus.draft),
        );
      });
    });

    group('FormBlockType', () {
      test('has all expected values', () {
        expect(FormBlockType.values.length, equals(9));
        expect(FormBlockType.values, contains(FormBlockType.text));
        expect(FormBlockType.values, contains(FormBlockType.heading));
        expect(FormBlockType.values, contains(FormBlockType.table));
        expect(FormBlockType.values, contains(FormBlockType.chart));
        expect(FormBlockType.values, contains(FormBlockType.image));
        expect(FormBlockType.values, contains(FormBlockType.formField));
        expect(FormBlockType.values, contains(FormBlockType.repeatable));
        expect(FormBlockType.values, contains(FormBlockType.conditional));
        expect(FormBlockType.values, contains(FormBlockType.canvas));
      });

      test('fromString parses valid names', () {
        expect(
          FormBlockType.fromString('text'),
          equals(FormBlockType.text),
        );
        expect(
          FormBlockType.fromString('heading'),
          equals(FormBlockType.heading),
        );
        expect(
          FormBlockType.fromString('table'),
          equals(FormBlockType.table),
        );
        expect(
          FormBlockType.fromString('chart'),
          equals(FormBlockType.chart),
        );
        expect(
          FormBlockType.fromString('image'),
          equals(FormBlockType.image),
        );
        expect(
          FormBlockType.fromString('formField'),
          equals(FormBlockType.formField),
        );
        expect(
          FormBlockType.fromString('repeatable'),
          equals(FormBlockType.repeatable),
        );
        expect(
          FormBlockType.fromString('conditional'),
          equals(FormBlockType.conditional),
        );
      });

      test('fromString defaults to text for unknown value', () {
        expect(
          FormBlockType.fromString('unknown'),
          equals(FormBlockType.text),
        );
      });
    });

    group('FormDataSourceType', () {
      test('has all expected values', () {
        expect(FormDataSourceType.values.length, equals(6));
        expect(
          FormDataSourceType.values,
          contains(FormDataSourceType.factgraph),
        );
        expect(FormDataSourceType.values, contains(FormDataSourceType.io));
        expect(
          FormDataSourceType.values,
          contains(FormDataSourceType.analysis),
        );
        expect(FormDataSourceType.values, contains(FormDataSourceType.tool));
        expect(
          FormDataSourceType.values,
          contains(FormDataSourceType.userInput),
        );
        expect(
          FormDataSourceType.values,
          contains(FormDataSourceType.canvas),
        );
      });

      test('fromString parses valid names', () {
        expect(
          FormDataSourceType.fromString('factgraph'),
          equals(FormDataSourceType.factgraph),
        );
        expect(
          FormDataSourceType.fromString('io'),
          equals(FormDataSourceType.io),
        );
        expect(
          FormDataSourceType.fromString('analysis'),
          equals(FormDataSourceType.analysis),
        );
        expect(
          FormDataSourceType.fromString('tool'),
          equals(FormDataSourceType.tool),
        );
        expect(
          FormDataSourceType.fromString('userInput'),
          equals(FormDataSourceType.userInput),
        );
      });

      test('fromString defaults to userInput for unknown value', () {
        expect(
          FormDataSourceType.fromString('unknown'),
          equals(FormDataSourceType.userInput),
        );
      });
    });

    // ------------------------------------------------------------------------
    // FormDocumentMetadata
    // ------------------------------------------------------------------------
    group('FormDocumentMetadata', () {
      test('creates with required fields', () {
        final now = DateTime.utc(2025, 6, 1);
        final meta = FormDocumentMetadata(
          author: 'tester',
          createdAt: now,
        );
        expect(meta.author, equals('tester'));
        expect(meta.createdAt, equals(now));
        expect(meta.modifiedAt, isNull);
        expect(meta.publishedAt, isNull);
        expect(meta.dataSource, isNull);
        expect(meta.engineVersion, isNull);
      });

      test('serialization round-trip', () {
        final now = DateTime.utc(2025, 6, 1);
        final modified = DateTime.utc(2025, 6, 2);
        final meta = FormDocumentMetadata(
          author: 'author1',
          createdAt: now,
          modifiedAt: modified,
          dataSource: 'db',
          engineVersion: '2.0.0',
        );
        final json = meta.toJson();
        final restored = FormDocumentMetadata.fromJson(json);
        expect(restored.author, equals('author1'));
        expect(restored.createdAt, equals(now));
        expect(restored.modifiedAt, equals(modified));
        expect(restored.dataSource, equals('db'));
        expect(restored.engineVersion, equals('2.0.0'));
      });

      test('toJson omits null optional fields', () {
        final meta = FormDocumentMetadata(
          author: 'a',
          createdAt: DateTime.utc(2025, 1, 1),
        );
        final json = meta.toJson();
        expect(json.containsKey('modifiedAt'), isFalse);
        expect(json.containsKey('publishedAt'), isFalse);
        expect(json.containsKey('dataSource'), isFalse);
        expect(json.containsKey('engineVersion'), isFalse);
      });
    });

    // ------------------------------------------------------------------------
    // FormDocumentVersion
    // ------------------------------------------------------------------------
    group('FormDocumentVersion', () {
      test('creates with required fields', () {
        final ts = DateTime.utc(2025, 7, 1);
        final ver = FormDocumentVersion(
          versionNumber: 3,
          timestamp: ts,
          author: 'editor',
        );
        expect(ver.versionNumber, equals(3));
        expect(ver.timestamp, equals(ts));
        expect(ver.author, equals('editor'));
        expect(ver.changeDescription, isNull);
        expect(ver.diff, isNull);
      });

      test('serialization round-trip with optional fields', () {
        final ts = DateTime.utc(2025, 7, 1);
        final ver = FormDocumentVersion(
          versionNumber: 2,
          timestamp: ts,
          author: 'editor',
          changeDescription: 'Fixed typo',
          diff: {'field': 'old->new'},
        );
        final json = ver.toJson();
        final restored = FormDocumentVersion.fromJson(json);
        expect(restored.versionNumber, equals(2));
        expect(restored.author, equals('editor'));
        expect(restored.changeDescription, equals('Fixed typo'));
        expect(restored.diff, isNotNull);
        expect(restored.diff!['field'], equals('old->new'));
      });
    });

    // ------------------------------------------------------------------------
    // FormDocument
    // ------------------------------------------------------------------------
    group('FormDocument', () {
      FormDocumentMetadata makeMetadata() {
        return FormDocumentMetadata(
          author: 'test',
          createdAt: DateTime.utc(2025, 1, 1),
        );
      }

      test('creates with defaults', () {
        final doc = FormDocument(
          documentId: 'doc-1',
          templateId: 'tmpl-1',
          templateVersion: '1.0.0',
          metadata: makeMetadata(),
        );
        expect(doc.documentId, equals('doc-1'));
        expect(doc.templateId, equals('tmpl-1'));
        expect(doc.templateVersion, equals('1.0.0'));
        expect(doc.status, equals(FormDocumentStatus.draft));
        expect(doc.version, equals(1));
        expect(doc.sections, isEmpty);
        expect(doc.data, isEmpty);
        expect(doc.bindings, isNull);
        expect(doc.validationIssues, isNull);
      });

      test('serialization round-trip', () {
        final doc = FormDocument(
          documentId: 'doc-2',
          templateId: 'tmpl-2',
          templateVersion: '2.0.0',
          metadata: makeMetadata(),
          status: FormDocumentStatus.review,
          version: 3,
          data: {'key': 'value'},
          sections: [
            const FormSection(
              sectionId: 'sec-1',
              index: 0,
              title: 'Introduction',
            ),
          ],
        );
        final json = doc.toJson();
        final restored = FormDocument.fromJson(json);
        expect(restored.documentId, equals('doc-2'));
        expect(restored.templateId, equals('tmpl-2'));
        expect(restored.templateVersion, equals('2.0.0'));
        expect(restored.status, equals(FormDocumentStatus.review));
        expect(restored.version, equals(3));
        expect(restored.data['key'], equals('value'));
        expect(restored.sections.length, equals(1));
        expect(restored.sections.first.title, equals('Introduction'));
      });

      test('toJson omits empty data and null optional fields', () {
        final doc = FormDocument(
          documentId: 'doc-3',
          templateId: 'tmpl-3',
          templateVersion: '1.0.0',
          metadata: makeMetadata(),
        );
        final json = doc.toJson();
        expect(json.containsKey('data'), isFalse);
        expect(json.containsKey('bindings'), isFalse);
        expect(json.containsKey('validationIssues'), isFalse);
      });

      test('serialization with bindings and validation issues', () {
        final now = DateTime.utc(2025, 3, 15);
        final doc = FormDocument(
          documentId: 'doc-4',
          templateId: 'tmpl-4',
          templateVersion: '1.0.0',
          metadata: makeMetadata(),
          bindings: [
            FormDataBinding(
              bindingId: 'b1',
              fieldPath: '/sections/0/blocks/0',
              dataPath: 'facts.revenue',
              source: FormDataSourceType.factgraph,
              isFilled: true,
              filledAt: now,
            ),
          ],
          validationIssues: [
            FormValidationIssue(
              code: 'REQUIRED',
              message: 'Field is required',
              path: '/data/name',
              severity: 'error',
            ),
          ],
        );
        final json = doc.toJson();
        final restored = FormDocument.fromJson(json);
        expect(restored.bindings, isNotNull);
        expect(restored.bindings!.length, equals(1));
        expect(restored.bindings!.first.bindingId, equals('b1'));
        expect(restored.bindings!.first.source,
            equals(FormDataSourceType.factgraph));
        expect(restored.bindings!.first.isFilled, isTrue);
        expect(restored.validationIssues, isNotNull);
        expect(restored.validationIssues!.length, equals(1));
        expect(restored.validationIssues!.first.code, equals('REQUIRED'));
        expect(restored.validationIssues!.first.severity, equals('error'));
      });
    });

    // ------------------------------------------------------------------------
    // FormSection
    // ------------------------------------------------------------------------
    group('FormSection', () {
      test('creates with defaults', () {
        const section = FormSection(sectionId: 's1', index: 0);
        expect(section.sectionId, equals('s1'));
        expect(section.index, equals(0));
        expect(section.title, isNull);
        expect(section.description, isNull);
        expect(section.blocks, isEmpty);
      });

      test('serialization round-trip', () {
        const section = FormSection(
          sectionId: 's2',
          index: 1,
          title: 'Summary',
          description: 'Overview of inspection results',
        );
        final json = section.toJson();
        final restored = FormSection.fromJson(json);
        expect(restored.sectionId, equals('s2'));
        expect(restored.index, equals(1));
        expect(restored.title, equals('Summary'));
        expect(
          restored.description,
          equals('Overview of inspection results'),
        );
      });

      test('toJson omits null description', () {
        const section = FormSection(sectionId: 's3', index: 0);
        final json = section.toJson();
        expect(json.containsKey('description'), isFalse);
      });
    });

    // ------------------------------------------------------------------------
    // FormBlock subtypes and fromJson dispatch
    // ------------------------------------------------------------------------
    group('FormBlock.fromJson dispatch', () {
      test('dispatches text type to FormTextBlock', () {
        final json = {
          'blockId': 'b1',
          'type': 'text',
          'index': 0,
          'content': 'Hello world',
          'format': 'markdown',
        };
        final block = FormBlock.fromJson(json);
        expect(block, isA<FormTextBlock>());
        final textBlock = block as FormTextBlock;
        expect(textBlock.content, equals('Hello world'));
        expect(textBlock.format, equals('markdown'));
        expect(textBlock.type, equals(FormBlockType.text));
      });

      test('dispatches heading type to FormHeadingBlock', () {
        final json = {
          'blockId': 'b2',
          'type': 'heading',
          'index': 0,
          'content': 'Title',
          'level': 2,
          'numbering': true,
        };
        final block = FormBlock.fromJson(json);
        expect(block, isA<FormHeadingBlock>());
        final heading = block as FormHeadingBlock;
        expect(heading.content, equals('Title'));
        expect(heading.level, equals(2));
        expect(heading.numbering, isTrue);
      });

      test('dispatches table type to FormTableBlock', () {
        final json = {
          'blockId': 'b3',
          'type': 'table',
          'index': 0,
          'columns': [
            {'id': 'col1', 'title': 'Name', 'type': 'string'},
          ],
          'rows': [
            {
              'cells': {'col1': 'Alice'},
            },
          ],
          'headerRepeat': true,
          'maxRows': 100,
          'unit': 'KRW',
        };
        final block = FormBlock.fromJson(json);
        expect(block, isA<FormTableBlock>());
        final table = block as FormTableBlock;
        expect(table.columns.length, equals(1));
        expect(table.columns.first.id, equals('col1'));
        expect(table.rows.length, equals(1));
        expect(table.headerRepeat, isTrue);
        expect(table.maxRows, equals(100));
        expect(table.unit, equals('KRW'));
      });

      test('dispatches chart type to FormChartBlock', () {
        final json = {
          'blockId': 'b4',
          'type': 'chart',
          'index': 0,
          'chartType': 'bar',
          'data': [1, 2, 3],
          'title': 'Revenue',
          'xAxis': {'label': 'Month', 'unit': 'mo'},
          'yAxis': {'label': 'Amount', 'min': 0.0, 'max': 1000.0},
          'unit': 'USD',
        };
        final block = FormBlock.fromJson(json);
        expect(block, isA<FormChartBlock>());
        final chart = block as FormChartBlock;
        expect(chart.chartType, equals('bar'));
        expect(chart.data.length, equals(3));
        expect(chart.title, equals('Revenue'));
        expect(chart.xAxis, isNotNull);
        expect(chart.xAxis!.label, equals('Month'));
        expect(chart.yAxis, isNotNull);
        expect(chart.yAxis!.min, equals(0.0));
        expect(chart.yAxis!.max, equals(1000.0));
        expect(chart.unit, equals('USD'));
      });

      test('dispatches image type to FormImageBlock', () {
        final json = {
          'blockId': 'b5',
          'type': 'image',
          'index': 0,
          'src': 'https://example.com/logo.png',
          'alt': 'Company logo',
          'maxWidth': 300.0,
          'aspectRatio': 1.5,
        };
        final block = FormBlock.fromJson(json);
        expect(block, isA<FormImageBlock>());
        final image = block as FormImageBlock;
        expect(image.src, equals('https://example.com/logo.png'));
        expect(image.alt, equals('Company logo'));
        expect(image.maxWidth, equals(300.0));
        expect(image.aspectRatio, equals(1.5));
      });

      test('dispatches canvas type to FormCanvasBlock (live scene embed)', () {
        final json = {
          'blockId': 'b5c',
          'type': 'canvas',
          'index': 0,
          'target': 'canvas://schematic.main',
          'mode': 'canvas',
          'format': 'svg',
          'fallback': 'bitmap',
          'viewport': {'zoom': 1.2},
          'caption': 'Main schematic',
          'maxWidth': 600.0,
          'aspectRatio': 1.4142,
        };
        final block = FormBlock.fromJson(json);
        expect(block, isA<FormCanvasBlock>());
        final canvas = block as FormCanvasBlock;
        expect(canvas.target, equals('canvas://schematic.main'));
        expect(canvas.mode, equals('canvas'));
        expect(canvas.format, equals('svg'));
        expect(canvas.fallback, equals('bitmap'));
        expect(canvas.viewport, equals({'zoom': 1.2}));
        expect(canvas.caption, equals('Main schematic'));
        expect(canvas.maxWidth, equals(600.0));
        expect(canvas.aspectRatio, closeTo(1.4142, 1e-6));
      });

      test('FormCanvasBlock defaults when only target given', () {
        final block = FormCanvasBlock(
          blockId: 'b5c2',
          index: 0,
          target: 'canvas://ui.home',
        );
        expect(block.mode, equals('canvas'));
        expect(block.format, equals('svg'));
        expect(block.fallback, equals('bitmap'));
        // Round-trip toJson → fromJson.
        final restored = FormCanvasBlock.fromJson(block.toJson());
        expect(restored.target, equals('canvas://ui.home'));
        expect(restored.mode, equals('canvas'));
        expect(restored.format, equals('svg'));
        expect(restored.fallback, equals('bitmap'));
      });

      test('dispatches formField type to FormFieldBlock', () {
        final json = {
          'blockId': 'b6',
          'type': 'formField',
          'index': 0,
          'fieldName': 'companyName',
          'fieldType': 'text',
          'placeholder': 'Enter company name',
          'options': ['opt1', 'opt2'],
          'constraints': {'maxLength': 100},
        };
        final block = FormBlock.fromJson(json);
        expect(block, isA<FormFieldBlock>());
        final field = block as FormFieldBlock;
        expect(field.fieldName, equals('companyName'));
        expect(field.fieldType, equals('text'));
        expect(field.placeholder, equals('Enter company name'));
        expect(field.options, isNotNull);
        expect(field.options!.length, equals(2));
        expect(field.constraints, isNotNull);
        expect(field.constraints!['maxLength'], equals(100));
      });

      test('dispatches repeatable type to FormRepeatableBlock', () {
        final json = {
          'blockId': 'b7',
          'type': 'repeatable',
          'index': 0,
          'itemTemplate': [
            {
              'blockId': 'inner1',
              'type': 'text',
              'index': 0,
              'content': 'Item Name',
            },
            {
              'blockId': 'inner2',
              'type': 'formField',
              'index': 1,
              'fieldName': 'quantity',
              'fieldType': 'number',
            },
          ],
          'itemsBinding': 'data.items',
          'minItems': 1,
          'maxItems': 10,
        };
        final block = FormBlock.fromJson(json);
        expect(block, isA<FormRepeatableBlock>());
        final repeatable = block as FormRepeatableBlock;
        expect(repeatable.itemTemplate.length, equals(2));
        expect(repeatable.itemTemplate[0], isA<FormTextBlock>());
        expect(repeatable.itemTemplate[1], isA<FormFieldBlock>());
        expect(repeatable.itemsBinding, equals('data.items'));
        expect(repeatable.minItems, equals(1));
        expect(repeatable.maxItems, equals(10));
      });

      test('dispatches conditional type to FormConditionalBlock', () {
        final json = {
          'blockId': 'b8',
          'type': 'conditional',
          'index': 0,
          'condition': 'data.showDetails == true',
          'thenBlock': {
            'blockId': 'then1',
            'type': 'text',
            'index': 0,
            'content': 'Details shown',
          },
          'elseBlock': {
            'blockId': 'else1',
            'type': 'heading',
            'index': 0,
            'content': 'Hidden',
            'level': 3,
          },
        };
        final block = FormBlock.fromJson(json);
        expect(block, isA<FormConditionalBlock>());
        final conditional = block as FormConditionalBlock;
        expect(conditional.condition, equals('data.showDetails == true'));
        expect(conditional.thenBlock, isA<FormTextBlock>());
        expect(conditional.elseBlock, isA<FormHeadingBlock>());
      });

      test('conditional block without elseBlock', () {
        final json = {
          'blockId': 'b9',
          'type': 'conditional',
          'index': 0,
          'condition': 'x > 0',
          'thenBlock': {
            'blockId': 'then2',
            'type': 'text',
            'index': 0,
            'content': 'Positive',
          },
        };
        final block = FormBlock.fromJson(json) as FormConditionalBlock;
        expect(block.elseBlock, isNull);
      });

      test('unknown type defaults to text in fromString then dispatches', () {
        final json = {
          'blockId': 'bX',
          'type': 'unknown_type',
          'index': 0,
          'content': 'fallback',
        };
        final block = FormBlock.fromJson(json);
        expect(block, isA<FormTextBlock>());
      });
    });

    // ------------------------------------------------------------------------
    // FormBlock subtypes - individual serialization round-trips
    // ------------------------------------------------------------------------
    group('FormTextBlock', () {
      test('creates with defaults', () {
        final block = FormTextBlock(
          blockId: 't1',
          index: 0,
          content: 'Hello',
        );
        expect(block.format, equals('plain'));
        expect(block.type, equals(FormBlockType.text));
        expect(block.style, isNull);
      });

      test('serialization round-trip', () {
        final block = FormTextBlock(
          blockId: 't2',
          index: 1,
          content: '# Markdown',
          format: 'markdown',
          style: {'color': 'red'},
        );
        final json = block.toJson();
        final restored = FormTextBlock.fromJson(json);
        expect(restored.blockId, equals('t2'));
        expect(restored.index, equals(1));
        expect(restored.content, equals('# Markdown'));
        expect(restored.format, equals('markdown'));
        expect(restored.style, isNotNull);
        expect(restored.style!['color'], equals('red'));
      });
    });

    group('FormHeadingBlock', () {
      test('creates with defaults', () {
        final block = FormHeadingBlock(
          blockId: 'h1',
          index: 0,
          content: 'Title',
        );
        expect(block.level, equals(1));
        expect(block.numbering, isNull);
        expect(block.type, equals(FormBlockType.heading));
      });

      test('serialization round-trip', () {
        final block = FormHeadingBlock(
          blockId: 'h2',
          index: 1,
          content: 'Section',
          level: 3,
          numbering: true,
        );
        final json = block.toJson();
        final restored = FormHeadingBlock.fromJson(json);
        expect(restored.content, equals('Section'));
        expect(restored.level, equals(3));
        expect(restored.numbering, isTrue);
      });

      test('toJson omits null numbering', () {
        final block = FormHeadingBlock(
          blockId: 'h3',
          index: 0,
          content: 'X',
        );
        final json = block.toJson();
        expect(json.containsKey('numbering'), isFalse);
      });
    });

    group('FormTableBlock', () {
      test('creates with defaults', () {
        final block = FormTableBlock(
          blockId: 'tbl1',
          index: 0,
          columns: [],
        );
        expect(block.rows, isEmpty);
        expect(block.headerRepeat, isFalse);
        expect(block.maxRows, isNull);
        expect(block.unit, isNull);
        expect(block.type, equals(FormBlockType.table));
      });

      test('serialization round-trip', () {
        final block = FormTableBlock(
          blockId: 'tbl2',
          index: 0,
          columns: [
            const FormTableColumn(
              id: 'c1',
              title: 'Name',
              type: 'string',
              width: 150.0,
            ),
            const FormTableColumn(id: 'c2', title: 'Age', type: 'number'),
          ],
          rows: [
            FormTableRow(
              cells: {'c1': 'Alice', 'c2': 30},
              attributes: {'highlight': true},
            ),
          ],
          headerRepeat: true,
          maxRows: 50,
          unit: 'USD',
        );
        final json = block.toJson();
        final restored = FormTableBlock.fromJson(json);
        expect(restored.columns.length, equals(2));
        expect(restored.columns.first.width, equals(150.0));
        expect(restored.columns.last.width, isNull);
        expect(restored.rows.length, equals(1));
        expect(restored.rows.first.cells['c1'], equals('Alice'));
        expect(restored.rows.first.attributes!['highlight'], isTrue);
        expect(restored.headerRepeat, isTrue);
        expect(restored.maxRows, equals(50));
        expect(restored.unit, equals('USD'));
      });
    });

    group('FormTableColumn', () {
      test('serialization round-trip', () {
        const col = FormTableColumn(
          id: 'col1',
          title: 'Revenue',
          type: 'number',
          width: 200.0,
          alignment: 'right',
        );
        final json = col.toJson();
        final restored = FormTableColumn.fromJson(json);
        expect(restored.id, equals('col1'));
        expect(restored.title, equals('Revenue'));
        expect(restored.type, equals('number'));
        expect(restored.width, equals(200.0));
        expect(restored.alignment, equals('right'));
      });

      test('toJson omits null optional fields', () {
        const col = FormTableColumn(id: 'c', title: 'T', type: 'string');
        final json = col.toJson();
        expect(json.containsKey('width'), isFalse);
        expect(json.containsKey('alignment'), isFalse);
      });
    });

    group('FormTableRow', () {
      test('serialization round-trip', () {
        final row = FormTableRow(
          cells: {'col1': 1, 'col2': 'two', 'col3': true},
          attributes: {'rowType': 'summary'},
        );
        final json = row.toJson();
        final restored = FormTableRow.fromJson(json);
        expect(restored.cells.length, equals(3));
        expect(restored.cells['col1'], equals(1));
        expect(restored.cells['col2'], equals('two'));
        expect(restored.cells['col3'], isTrue);
        expect(restored.attributes!['rowType'], equals('summary'));
      });

      test('toJson omits null attributes', () {
        final row = FormTableRow(cells: {});
        final json = row.toJson();
        expect(json.containsKey('attributes'), isFalse);
      });
    });

    group('FormChartBlock', () {
      test('creates with defaults', () {
        final block = FormChartBlock(
          blockId: 'ch1',
          index: 0,
          chartType: 'pie',
        );
        expect(block.data, isEmpty);
        expect(block.title, isNull);
        expect(block.xAxis, isNull);
        expect(block.yAxis, isNull);
        expect(block.unit, isNull);
        expect(block.type, equals(FormBlockType.chart));
      });

      test('serialization round-trip', () {
        final block = FormChartBlock(
          blockId: 'ch2',
          index: 1,
          chartType: 'line',
          data: [10, 20, 30],
          title: 'Trend',
          xAxis: const FormAxisConfig(label: 'X', unit: 'day'),
          yAxis: const FormAxisConfig(label: 'Y', min: 0.0, max: 100.0),
          unit: 'count',
        );
        final json = block.toJson();
        final restored = FormChartBlock.fromJson(json);
        expect(restored.chartType, equals('line'));
        expect(restored.data.length, equals(3));
        expect(restored.title, equals('Trend'));
        expect(restored.xAxis!.label, equals('X'));
        expect(restored.xAxis!.unit, equals('day'));
        expect(restored.yAxis!.min, equals(0.0));
        expect(restored.yAxis!.max, equals(100.0));
        expect(restored.unit, equals('count'));
      });
    });

    group('FormAxisConfig', () {
      test('creates with all null', () {
        const config = FormAxisConfig();
        expect(config.label, isNull);
        expect(config.unit, isNull);
        expect(config.min, isNull);
        expect(config.max, isNull);
      });

      test('serialization round-trip', () {
        const config = FormAxisConfig(
          label: 'Time',
          unit: 'ms',
          min: 0.0,
          max: 500.0,
        );
        final json = config.toJson();
        final restored = FormAxisConfig.fromJson(json);
        expect(restored.label, equals('Time'));
        expect(restored.unit, equals('ms'));
        expect(restored.min, equals(0.0));
        expect(restored.max, equals(500.0));
      });

      test('toJson omits null fields', () {
        const config = FormAxisConfig();
        final json = config.toJson();
        expect(json, isEmpty);
      });
    });

    group('FormImageBlock', () {
      test('creates with required fields only', () {
        final block = FormImageBlock(
          blockId: 'img1',
          index: 0,
          src: '/images/photo.jpg',
        );
        expect(block.alt, isNull);
        expect(block.maxWidth, isNull);
        expect(block.aspectRatio, isNull);
        expect(block.type, equals(FormBlockType.image));
      });

      test('serialization round-trip', () {
        final block = FormImageBlock(
          blockId: 'img2',
          index: 0,
          src: 'https://cdn.example.com/img.png',
          alt: 'Alt text',
          maxWidth: 640.0,
          aspectRatio: 1.777,
        );
        final json = block.toJson();
        final restored = FormImageBlock.fromJson(json);
        expect(restored.src, equals('https://cdn.example.com/img.png'));
        expect(restored.alt, equals('Alt text'));
        expect(restored.maxWidth, equals(640.0));
        expect(restored.aspectRatio, equals(1.777));
      });
    });

    group('FormFieldBlock', () {
      test('creates with required fields only', () {
        final block = FormFieldBlock(
          blockId: 'ff1',
          index: 0,
          fieldName: 'email',
          fieldType: 'text',
        );
        expect(block.placeholder, isNull);
        expect(block.options, isNull);
        expect(block.constraints, isNull);
        expect(block.type, equals(FormBlockType.formField));
      });

      test('serialization round-trip', () {
        final block = FormFieldBlock(
          blockId: 'ff2',
          index: 1,
          fieldName: 'country',
          fieldType: 'select',
          placeholder: 'Choose a country',
          options: ['US', 'KR', 'JP'],
          constraints: {'required': true},
        );
        final json = block.toJson();
        final restored = FormFieldBlock.fromJson(json);
        expect(restored.fieldName, equals('country'));
        expect(restored.fieldType, equals('select'));
        expect(restored.placeholder, equals('Choose a country'));
        expect(restored.options!.length, equals(3));
        expect(restored.constraints!['required'], isTrue);
      });
    });

    group('FormRepeatableBlock', () {
      test('creates with required fields only', () {
        final inner = FormTextBlock(
          blockId: 'inner1',
          index: 0,
          content: 'Template',
        );
        final block = FormRepeatableBlock(
          blockId: 'rep1',
          index: 0,
          itemTemplate: [inner],
        );
        expect(block.itemTemplate.length, equals(1));
        expect(block.itemsBinding, isNull);
        expect(block.minItems, isNull);
        expect(block.maxItems, isNull);
        expect(block.type, equals(FormBlockType.repeatable));
      });

      test('serialization round-trip with multiple templates', () {
        final heading = FormHeadingBlock(
          blockId: 'inner2',
          index: 0,
          content: 'Item heading',
          level: 2,
        );
        final field = FormFieldBlock(
          blockId: 'inner3',
          index: 1,
          fieldName: 'quantity',
          fieldType: 'number',
        );
        final block = FormRepeatableBlock(
          blockId: 'rep2',
          index: 0,
          itemTemplate: [heading, field],
          itemsBinding: 'data.entries',
          minItems: 2,
          maxItems: 20,
        );
        final json = block.toJson();
        final restored = FormRepeatableBlock.fromJson(json);
        expect(restored.itemTemplate.length, equals(2));
        expect(restored.itemTemplate[0], isA<FormHeadingBlock>());
        expect(
          (restored.itemTemplate[0] as FormHeadingBlock).level,
          equals(2),
        );
        expect(restored.itemTemplate[1], isA<FormFieldBlock>());
        expect(
          (restored.itemTemplate[1] as FormFieldBlock).fieldName,
          equals('quantity'),
        );
        expect(restored.itemsBinding, equals('data.entries'));
        expect(restored.minItems, equals(2));
        expect(restored.maxItems, equals(20));
      });
    });

    group('FormConditionalBlock', () {
      test('serialization round-trip with else block', () {
        final block = FormConditionalBlock(
          blockId: 'cond1',
          index: 0,
          condition: 'amount > 0',
          thenBlock: FormTextBlock(
            blockId: 'then1',
            index: 0,
            content: 'Positive',
          ),
          elseBlock: FormTextBlock(
            blockId: 'else1',
            index: 0,
            content: 'Zero or negative',
          ),
        );
        final json = block.toJson();
        final restored = FormConditionalBlock.fromJson(json);
        expect(restored.condition, equals('amount > 0'));
        expect(restored.thenBlock, isA<FormTextBlock>());
        expect(
          (restored.thenBlock as FormTextBlock).content,
          equals('Positive'),
        );
        expect(restored.elseBlock, isNotNull);
        expect(
          (restored.elseBlock! as FormTextBlock).content,
          equals('Zero or negative'),
        );
      });

      test('toJson omits null elseBlock', () {
        final block = FormConditionalBlock(
          blockId: 'cond2',
          index: 0,
          condition: 'flag',
          thenBlock: FormTextBlock(
            blockId: 'then2',
            index: 0,
            content: 'Yes',
          ),
        );
        final json = block.toJson();
        expect(json.containsKey('elseBlock'), isFalse);
      });
    });

    // ------------------------------------------------------------------------
    // FormBlock baseToJson includes style when present
    // ------------------------------------------------------------------------
    group('FormBlock style', () {
      test('baseToJson includes style when present', () {
        final block = FormTextBlock(
          blockId: 'styled',
          index: 0,
          content: 'Styled text',
          style: {'bold': true, 'fontSize': 14},
        );
        final json = block.toJson();
        expect(json.containsKey('style'), isTrue);
        expect((json['style'] as Map<String, dynamic>)['bold'], isTrue);
      });

      test('baseToJson omits style when null', () {
        final block = FormTextBlock(
          blockId: 'unstyled',
          index: 0,
          content: 'Plain text',
        );
        final json = block.toJson();
        expect(json.containsKey('style'), isFalse);
      });
    });

    // ------------------------------------------------------------------------
    // FormSchema & FormLayoutPolicy
    // ------------------------------------------------------------------------
    group('FormSchema', () {
      test('creates with defaults', () {
        const schema = FormSchema();
        expect(schema.fields, isEmpty);
        expect(schema.rules, isEmpty);
        expect(schema.strict, isFalse);
      });

      test('serialization round-trip', () {
        final schema = FormSchema(
          fields: [
            FormSchemaField(
              name: 'revenue',
              type: 'number',
              required: true,
              label: 'Revenue',
              placeholder: 'Enter revenue',
              format: 'currency',
              minValue: 0,
              maxValue: 999999999,
              description: 'Annual revenue',
              sensitive: true,
            ),
            FormSchemaField(
              name: 'status',
              type: 'string',
              enumValues: ['active', 'inactive'],
              pattern: r'^[a-z]+$',
            ),
          ],
          rules: [
            const FormSchemaRule(
              ruleId: 'r1',
              description: 'Revenue must be positive',
              expression: 'revenue >= 0',
              errorMessage: 'Revenue cannot be negative',
            ),
          ],
          strict: true,
        );
        final json = schema.toJson();
        final restored = FormSchema.fromJson(json);
        expect(restored.fields.length, equals(2));
        expect(restored.fields.first.name, equals('revenue'));
        expect(restored.fields.first.required, isTrue);
        expect(restored.fields.first.label, equals('Revenue'));
        expect(restored.fields.first.sensitive, isTrue);
        expect(restored.fields.first.minValue, equals(0));
        expect(restored.fields.last.enumValues!.length, equals(2));
        expect(restored.fields.last.pattern, equals(r'^[a-z]+$'));
        expect(restored.rules.length, equals(1));
        expect(restored.rules.first.ruleId, equals('r1'));
        expect(restored.rules.first.errorMessage,
            equals('Revenue cannot be negative'));
        expect(restored.strict, isTrue);
      });
    });

    group('FormSchemaField', () {
      test('creates with defaults', () {
        final field = FormSchemaField(name: 'x', type: 'string');
        expect(field.required, isFalse);
        expect(field.sensitive, isFalse);
        expect(field.label, isNull);
        expect(field.placeholder, isNull);
        expect(field.format, isNull);
        expect(field.minValue, isNull);
        expect(field.maxValue, isNull);
        expect(field.pattern, isNull);
        expect(field.enumValues, isNull);
        expect(field.description, isNull);
      });

      test('toJson omits null fields and non-sensitive default', () {
        final field = FormSchemaField(name: 'x', type: 'string');
        final json = field.toJson();
        expect(json.containsKey('label'), isFalse);
        expect(json.containsKey('placeholder'), isFalse);
        expect(json.containsKey('format'), isFalse);
        expect(json.containsKey('minValue'), isFalse);
        expect(json.containsKey('maxValue'), isFalse);
        expect(json.containsKey('pattern'), isFalse);
        expect(json.containsKey('enumValues'), isFalse);
        expect(json.containsKey('description'), isFalse);
        // sensitive defaults to false, so it should be omitted
        expect(json.containsKey('sensitive'), isFalse);
      });
    });

    group('FormSchemaRule', () {
      test('serialization round-trip', () {
        const rule = FormSchemaRule(
          ruleId: 'rule1',
          description: 'Must be positive',
          expression: 'value > 0',
          errorMessage: 'Value is not positive',
        );
        final json = rule.toJson();
        final restored = FormSchemaRule.fromJson(json);
        expect(restored.ruleId, equals('rule1'));
        expect(restored.description, equals('Must be positive'));
        expect(restored.expression, equals('value > 0'));
        expect(restored.errorMessage, equals('Value is not positive'));
      });

      test('toJson omits null errorMessage', () {
        const rule = FormSchemaRule(
          ruleId: 'r',
          description: 'd',
          expression: 'e',
        );
        final json = rule.toJson();
        expect(json.containsKey('errorMessage'), isFalse);
      });
    });

    group('FormLayoutPolicy', () {
      FormLayoutPolicy makePolicy() {
        return const FormLayoutPolicy(
          pageSize: FormPageSize(
            size: 'A4',
            width: 595.0,
            height: 842.0,
          ),
          margins: FormMargins(
            top: 72.0,
            right: 72.0,
            bottom: 72.0,
            left: 72.0,
          ),
          fontPolicy: FormFontPolicy(
            defaultFont: 'Noto Sans',
            defaultSize: 12.0,
            headingSize: 18.0,
            bodySize: 11.0,
            minSize: 8.0,
          ),
        );
      }

      test('creates with defaults', () {
        final policy = makePolicy();
        expect(policy.fontFamily, equals('sans-serif'));
        expect(policy.gridColumns, equals(12));
        expect(policy.maxTableRows, isNull);
        expect(policy.maxLineLength, isNull);
        expect(policy.autoWrap, isTrue);
        expect(policy.autoScale, isFalse);
      });

      test('serialization round-trip', () {
        const policy = FormLayoutPolicy(
          pageSize: FormPageSize(
            size: 'Letter',
            width: 612.0,
            height: 792.0,
            orientation: 'landscape',
          ),
          margins: FormMargins(
            top: 36.0,
            right: 36.0,
            bottom: 36.0,
            left: 36.0,
          ),
          fontFamily: 'Roboto',
          fontPolicy: FormFontPolicy(
            defaultFont: 'Roboto',
            defaultSize: 10.0,
            headingSize: 16.0,
            bodySize: 10.0,
            minSize: 7.0,
          ),
          gridColumns: 24,
          maxTableRows: 200,
          maxLineLength: 80,
          autoWrap: false,
          autoScale: true,
        );
        final json = policy.toJson();
        final restored = FormLayoutPolicy.fromJson(json);
        expect(restored.pageSize.size, equals('Letter'));
        expect(restored.pageSize.orientation, equals('landscape'));
        expect(restored.margins.top, equals(36.0));
        expect(restored.fontFamily, equals('Roboto'));
        expect(restored.fontPolicy.defaultFont, equals('Roboto'));
        expect(restored.fontPolicy.defaultSize, equals(10.0));
        expect(restored.fontPolicy.headingSize, equals(16.0));
        expect(restored.fontPolicy.bodySize, equals(10.0));
        expect(restored.fontPolicy.minSize, equals(7.0));
        expect(restored.gridColumns, equals(24));
        expect(restored.maxTableRows, equals(200));
        expect(restored.maxLineLength, equals(80));
        expect(restored.autoWrap, isFalse);
        expect(restored.autoScale, isTrue);
      });
    });

    group('FormPageSize', () {
      test('creates with default orientation', () {
        const ps = FormPageSize(size: 'A4', width: 595.0, height: 842.0);
        expect(ps.orientation, equals('portrait'));
      });

      test('serialization round-trip', () {
        const ps = FormPageSize(
          size: 'A3',
          width: 842.0,
          height: 1190.0,
          orientation: 'landscape',
        );
        final json = ps.toJson();
        final restored = FormPageSize.fromJson(json);
        expect(restored.size, equals('A3'));
        expect(restored.width, equals(842.0));
        expect(restored.height, equals(1190.0));
        expect(restored.orientation, equals('landscape'));
      });
    });

    group('FormMargins', () {
      test('serialization round-trip', () {
        const margins = FormMargins(
          top: 10.0,
          right: 20.0,
          bottom: 30.0,
          left: 40.0,
        );
        final json = margins.toJson();
        final restored = FormMargins.fromJson(json);
        expect(restored.top, equals(10.0));
        expect(restored.right, equals(20.0));
        expect(restored.bottom, equals(30.0));
        expect(restored.left, equals(40.0));
      });
    });

    group('FormFontPolicy', () {
      test('serialization round-trip', () {
        const fp = FormFontPolicy(
          defaultFont: 'Arial',
          defaultSize: 12.0,
          headingSize: 20.0,
          bodySize: 11.0,
          minSize: 6.0,
        );
        final json = fp.toJson();
        final restored = FormFontPolicy.fromJson(json);
        expect(restored.defaultFont, equals('Arial'));
        expect(restored.defaultSize, equals(12.0));
        expect(restored.headingSize, equals(20.0));
        expect(restored.bodySize, equals(11.0));
        expect(restored.minSize, equals(6.0));
      });
    });

    // ------------------------------------------------------------------------
    // Binding, Patch, Validation
    // ------------------------------------------------------------------------
    group('FormDataBinding', () {
      test('creates with defaults', () {
        final binding = FormDataBinding(
          bindingId: 'bd1',
          fieldPath: '/data/name',
          dataPath: 'facts.name',
          source: FormDataSourceType.factgraph,
        );
        expect(binding.required, isFalse);
        expect(binding.isFilled, isFalse);
        expect(binding.defaultValue, isNull);
        expect(binding.sourceQuery, isNull);
        expect(binding.toolName, isNull);
        expect(binding.toolParams, isNull);
        expect(binding.transform, isNull);
        expect(binding.filledAt, isNull);
      });

      test('serialization round-trip with all fields', () {
        final filledTime = DateTime.utc(2025, 5, 10);
        final binding = FormDataBinding(
          bindingId: 'bd2',
          fieldPath: '/sections/0/blocks/1',
          dataPath: 'tool.result',
          source: FormDataSourceType.tool,
          sourceQuery: 'SELECT * FROM results',
          toolName: 'analyze',
          toolParams: {'depth': 3},
          transform: 'toUpperCase()',
          required: true,
          defaultValue: 'N/A',
          isFilled: true,
          filledAt: filledTime,
        );
        final json = binding.toJson();
        final restored = FormDataBinding.fromJson(json);
        expect(restored.bindingId, equals('bd2'));
        expect(restored.source, equals(FormDataSourceType.tool));
        expect(restored.sourceQuery, equals('SELECT * FROM results'));
        expect(restored.toolName, equals('analyze'));
        expect(restored.toolParams!['depth'], equals(3));
        expect(restored.transform, equals('toUpperCase()'));
        expect(restored.required, isTrue);
        expect(restored.defaultValue, equals('N/A'));
        expect(restored.isFilled, isTrue);
        expect(restored.filledAt, equals(filledTime));
      });

      test('toJson omits null optional fields', () {
        final binding = FormDataBinding(
          bindingId: 'bd3',
          fieldPath: '/f',
          dataPath: 'd',
          source: FormDataSourceType.userInput,
        );
        final json = binding.toJson();
        expect(json.containsKey('sourceQuery'), isFalse);
        expect(json.containsKey('toolName'), isFalse);
        expect(json.containsKey('toolParams'), isFalse);
        expect(json.containsKey('transform'), isFalse);
        expect(json.containsKey('defaultValue'), isFalse);
        expect(json.containsKey('filledAt'), isFalse);
      });
    });

    group('FormPatchOperation', () {
      test('creates with required fields', () {
        final op = FormPatchOperation(op: 'add', path: '/data/name');
        expect(op.value, isNull);
        expect(op.from, isNull);
      });

      test('serialization round-trip', () {
        final op = FormPatchOperation(
          op: 'replace',
          path: '/data/amount',
          value: 42,
        );
        final json = op.toJson();
        final restored = FormPatchOperation.fromJson(json);
        expect(restored.op, equals('replace'));
        expect(restored.path, equals('/data/amount'));
        expect(restored.value, equals(42));
      });

      test('serialization round-trip with from field', () {
        final op = FormPatchOperation(
          op: 'move',
          path: '/data/newField',
          from: '/data/oldField',
        );
        final json = op.toJson();
        final restored = FormPatchOperation.fromJson(json);
        expect(restored.op, equals('move'));
        expect(restored.from, equals('/data/oldField'));
      });
    });

    group('FormValidationResult', () {
      test('creates valid result with defaults', () {
        const result = FormValidationResult(isValid: true);
        expect(result.isValid, isTrue);
        expect(result.issues, isEmpty);
        expect(result.appliedFixes, isNull);
      });

      test('serialization round-trip', () {
        final result = FormValidationResult(
          isValid: false,
          issues: [
            FormValidationIssue(
              code: 'REQUIRED',
              message: 'Missing field',
              path: '/data/x',
              severity: 'error',
              context: {'field': 'x'},
            ),
          ],
          appliedFixes: [
            FormAutoFixAction(
              action: 'set_default',
              path: '/data/y',
              description: 'Set default value',
              details: {'value': 0},
            ),
          ],
        );
        final json = result.toJson();
        final restored = FormValidationResult.fromJson(json);
        expect(restored.isValid, isFalse);
        expect(restored.issues.length, equals(1));
        expect(restored.issues.first.code, equals('REQUIRED'));
        expect(restored.issues.first.severity, equals('error'));
        expect(restored.issues.first.context!['field'], equals('x'));
        expect(restored.appliedFixes, isNotNull);
        expect(restored.appliedFixes!.length, equals(1));
        expect(restored.appliedFixes!.first.action, equals('set_default'));
        expect(restored.appliedFixes!.first.details!['value'], equals(0));
      });
    });

    group('FormValidationIssue', () {
      test('creates with required fields', () {
        final issue = FormValidationIssue(
          code: 'ERR',
          message: 'msg',
          path: '/p',
        );
        expect(issue.severity, isNull);
        expect(issue.context, isNull);
      });

      test('serialization round-trip', () {
        final issue = FormValidationIssue(
          code: 'TYPE_MISMATCH',
          message: 'Expected number',
          path: '/data/count',
          severity: 'warning',
          context: {'expected': 'number', 'actual': 'string'},
        );
        final json = issue.toJson();
        final restored = FormValidationIssue.fromJson(json);
        expect(restored.code, equals('TYPE_MISMATCH'));
        expect(restored.message, equals('Expected number'));
        expect(restored.path, equals('/data/count'));
        expect(restored.severity, equals('warning'));
        expect(restored.context!['expected'], equals('number'));
      });
    });

    group('FormAutoFixAction', () {
      test('creates with required fields', () {
        final fix = FormAutoFixAction(
          action: 'trim',
          path: '/data/name',
          description: 'Trimmed whitespace',
        );
        expect(fix.details, isNull);
      });

      test('serialization round-trip', () {
        final fix = FormAutoFixAction(
          action: 'coerce',
          path: '/data/amount',
          description: 'Coerced string to number',
          details: {'from': '42', 'to': 42},
        );
        final json = fix.toJson();
        final restored = FormAutoFixAction.fromJson(json);
        expect(restored.action, equals('coerce'));
        expect(restored.path, equals('/data/amount'));
        expect(restored.description, equals('Coerced string to number'));
        expect(restored.details!['from'], equals('42'));
        expect(restored.details!['to'], equals(42));
      });
    });

    // ------------------------------------------------------------------------
    // FormResult & FormError
    // ------------------------------------------------------------------------
    group('FormResult', () {
      test('FormResult.ok creates successful result', () {
        const result = FormResult<String>.ok('data');
        expect(result.success, isTrue);
        expect(result.data, equals('data'));
        expect(result.error, isNull);
        expect(result.warnings, isNull);
      });

      test('FormResult.fail creates failed result', () {
        final result = FormResult<String>.fail(
          FormError(code: 'ERR', message: 'Failed'),
        );
        expect(result.success, isFalse);
        expect(result.data, isNull);
        expect(result.error, isNotNull);
        expect(result.error!.code, equals('ERR'));
      });

      test('FormResult creates with all fields', () {
        final result = FormResult<String>(
          success: true,
          data: 'value',
          warnings: [
            FormError(code: 'WARN', message: 'Minor issue'),
          ],
        );
        expect(result.success, isTrue);
        expect(result.data, equals('value'));
        expect(result.warnings, isNotNull);
        expect(result.warnings!.length, equals(1));
        expect(result.warnings!.first.code, equals('WARN'));
      });

      test('FormResult.fromJson deserializes with converter', () {
        final json = {
          'success': true,
          'data': {'value': 42},
        };
        final result = FormResult<Map<String, dynamic>>.fromJson(
          json,
          (data) => data,
        );
        expect(result.success, isTrue);
        expect(result.data!['value'], equals(42));
      });

      test('FormResult.fromJson deserializes failure', () {
        final json = {
          'success': false,
          'error': {'code': 'NOT_FOUND', 'message': 'Gone'},
        };
        final result = FormResult<Map<String, dynamic>>.fromJson(
          json,
          (data) => data,
        );
        expect(result.success, isFalse);
        expect(result.error!.code, equals('NOT_FOUND'));
        expect(result.data, isNull);
      });

      test('FormResult.fromJson with warnings', () {
        final json = {
          'success': true,
          'data': {'x': 1},
          'warnings': [
            {'code': 'W1', 'message': 'warn1'},
          ],
        };
        final result = FormResult<Map<String, dynamic>>.fromJson(
          json,
          (data) => data,
        );
        expect(result.warnings, isNotNull);
        expect(result.warnings!.length, equals(1));
        expect(result.warnings!.first.code, equals('W1'));
      });

      test('FormResult.toJson with dataToJson converter', () {
        const result = FormResult<String>.ok('hello');
        final json = result.toJson((data) => {'text': data});
        expect(json['success'], isTrue);
        expect((json['data'] as Map)['text'], equals('hello'));
      });

      test('FormResult.toJson without dataToJson includes data as-is', () {
        const result = FormResult<String>.ok('hello');
        final json = result.toJson();
        expect(json['data'], equals('hello'));
      });

      test('FormResult.toJson omits null fields', () {
        const result = FormResult<String>.ok('x');
        final json = result.toJson();
        expect(json.containsKey('error'), isFalse);
        expect(json.containsKey('warnings'), isFalse);
      });
    });

    group('FormError', () {
      test('creates with required fields', () {
        final error = FormError(code: 'ERR', message: 'Something failed');
        expect(error.code, equals('ERR'));
        expect(error.message, equals('Something failed'));
        expect(error.path, isNull);
        expect(error.context, isNull);
        expect(error.suggestion, isNull);
      });

      test('serialization round-trip with all fields', () {
        final error = FormError(
          code: 'VALIDATION',
          message: 'Invalid input',
          path: '/data/email',
          context: {'format': 'email'},
          suggestion: 'Use a valid email address',
        );
        final json = error.toJson();
        final restored = FormError.fromJson(json);
        expect(restored.code, equals('VALIDATION'));
        expect(restored.message, equals('Invalid input'));
        expect(restored.path, equals('/data/email'));
        expect(restored.context!['format'], equals('email'));
        expect(restored.suggestion, equals('Use a valid email address'));
      });

      test('toJson omits null optional fields', () {
        final error = FormError(code: 'E', message: 'M');
        final json = error.toJson();
        expect(json.containsKey('path'), isFalse);
        expect(json.containsKey('context'), isFalse);
        expect(json.containsKey('suggestion'), isFalse);
      });
    });

    // ------------------------------------------------------------------------
    // StubFormPort
    // ------------------------------------------------------------------------
    group('StubFormPort', () {
      late StubFormPort port;

      setUp(() {
        port = StubFormPort();
      });

      test('createDocument returns ok result', () async {
        final result = await port.createDocument(
          templateId: 'tmpl-1',
          initialData: {'key': 'value'},
          documentId: 'my-doc',
          author: 'tester',
        );
        expect(result.success, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.documentId, equals('my-doc'));
        expect(result.data!.templateId, equals('tmpl-1'));
        expect(result.data!.templateVersion, equals('1.0.0'));
        expect(result.data!.metadata.author, equals('tester'));
        expect(result.data!.status, equals(FormDocumentStatus.draft));
        expect(result.data!.version, equals(1));
        expect(result.data!.data['key'], equals('value'));
      });

      test('createDocument generates id when not provided', () async {
        final result = await port.createDocument(
          templateId: 'tmpl-2',
          initialData: {},
        );
        expect(result.success, isTrue);
        expect(result.data!.documentId, startsWith('doc-'));
        expect(result.data!.metadata.author, equals('stub'));
      });

      test('getDocument retrieves existing document', () async {
        await port.createDocument(
          templateId: 'tmpl-1',
          initialData: {},
          documentId: 'doc-100',
        );
        final result = await port.getDocument(documentId: 'doc-100');
        expect(result.success, isTrue);
        expect(result.data!.documentId, equals('doc-100'));
      });

      test('getDocument returns fail for missing document', () async {
        final result = await port.getDocument(documentId: 'nonexistent');
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.code, equals('NOT_FOUND'));
      });

      test('listDocuments returns all documents', () async {
        await port.createDocument(
          templateId: 'tmpl-a',
          initialData: {},
          documentId: 'doc-a',
        );
        await port.createDocument(
          templateId: 'tmpl-b',
          initialData: {},
          documentId: 'doc-b',
        );
        final result = await port.listDocuments();
        expect(result.success, isTrue);
        expect(result.data!.length, equals(2));
      });

      test('listDocuments filters by templateId', () async {
        await port.createDocument(
          templateId: 'tmpl-x',
          initialData: {},
          documentId: 'doc-x1',
        );
        await port.createDocument(
          templateId: 'tmpl-y',
          initialData: {},
          documentId: 'doc-y1',
        );
        final result = await port.listDocuments(templateId: 'tmpl-x');
        expect(result.data!.length, equals(1));
        expect(result.data!.first.templateId, equals('tmpl-x'));
      });

      test('listDocuments respects limit', () async {
        for (var i = 0; i < 5; i++) {
          await port.createDocument(
            templateId: 'tmpl',
            initialData: {},
            documentId: 'doc-$i',
          );
        }
        final result = await port.listDocuments(limit: 3);
        expect(result.data!.length, equals(3));
      });

      test('validate returns valid result', () async {
        final doc = FormDocument(
          documentId: 'doc-v',
          templateId: 'tmpl-v',
          templateVersion: '1.0.0',
          metadata: FormDocumentMetadata(
            author: 'test',
            createdAt: DateTime.now(),
          ),
        );
        final result = await port.validate(document: doc);
        expect(result.success, isTrue);
        expect(result.data!.isValid, isTrue);
        expect(result.data!.issues, isEmpty);
      });

      test('patch returns fail for nonexistent document', () async {
        final result = await port.patch(
          documentId: 'no-such-doc',
          operations: [
            FormPatchOperation(
              op: 'replace',
              path: '/data/x',
              value: 1,
            ),
          ],
          targetVersion: 1,
        );
        expect(result.success, isFalse);
        expect(result.error!.code, equals('NOT_FOUND'));
      });

      test('patch returns ok for existing document', () async {
        await port.createDocument(
          templateId: 'tmpl',
          initialData: {},
          documentId: 'doc-p',
        );
        final result = await port.patch(
          documentId: 'doc-p',
          operations: [
            FormPatchOperation(op: 'add', path: '/data/x', value: 'new'),
          ],
          targetVersion: 1,
        );
        expect(result.success, isTrue);
        expect(result.data, isNotNull);
      });

      test('getDocumentHistory returns empty list', () async {
        final result = await port.getDocumentHistory(documentId: 'any');
        expect(result.success, isTrue);
        expect(result.data, isEmpty);
      });
    });
  });

  // ==========================================================================
  // FormRendererPort
  // ==========================================================================
  group('FormRendererPort', () {
    // ------------------------------------------------------------------------
    // FormRenderOutput
    // ------------------------------------------------------------------------
    group('FormRenderOutput', () {
      test('creates with required fields', () {
        final now = DateTime.utc(2025, 6, 1);
        final output = FormRenderOutput(
          format: 'pdf',
          content: 'binary-data',
          pageCount: 5,
          generatedAt: now,
        );
        expect(output.format, equals('pdf'));
        expect(output.content, equals('binary-data'));
        expect(output.pageCount, equals(5));
        expect(output.fileSize, isNull);
        expect(output.generatedAt, equals(now));
        expect(output.metrics, isNull);
      });

      test('serialization round-trip', () {
        final now = DateTime.utc(2025, 6, 1, 12, 0, 0);
        final output = FormRenderOutput(
          format: 'html',
          content: '<h1>Title</h1>',
          pageCount: 3,
          fileSize: 2048,
          generatedAt: now,
          metrics: const FormRenderMetrics(
            renderTimeMs: 150.5,
            pageCount: 3,
            overflowCount: 1,
            autofixCount: 2,
            fileSize: 2048,
          ),
        );
        final json = output.toJson();
        final restored = FormRenderOutput.fromJson(json);
        expect(restored.format, equals('html'));
        expect(restored.content, equals('<h1>Title</h1>'));
        expect(restored.pageCount, equals(3));
        expect(restored.fileSize, equals(2048));
        expect(restored.generatedAt, equals(now));
        expect(restored.metrics, isNotNull);
        expect(restored.metrics!.renderTimeMs, equals(150.5));
        expect(restored.metrics!.overflowCount, equals(1));
        expect(restored.metrics!.autofixCount, equals(2));
      });

      test('toJson omits null optional fields', () {
        final output = FormRenderOutput(
          format: 'markdown',
          content: '# H1',
          pageCount: 1,
          generatedAt: DateTime.utc(2025, 1, 1),
        );
        final json = output.toJson();
        expect(json.containsKey('fileSize'), isFalse);
        expect(json.containsKey('metrics'), isFalse);
      });

      test('fromJson handles missing fields gracefully', () {
        final json = <String, dynamic>{};
        final output = FormRenderOutput.fromJson(json);
        expect(output.format, equals(''));
        expect(output.content, isNull);
        expect(output.pageCount, equals(0));
      });
    });

    // ------------------------------------------------------------------------
    // FormRenderMetrics
    // ------------------------------------------------------------------------
    group('FormRenderMetrics', () {
      test('creates with defaults', () {
        const metrics = FormRenderMetrics(
          renderTimeMs: 100.0,
          pageCount: 2,
        );
        expect(metrics.overflowCount, equals(0));
        expect(metrics.autofixCount, equals(0));
        expect(metrics.fileSize, isNull);
      });

      test('serialization round-trip', () {
        const metrics = FormRenderMetrics(
          renderTimeMs: 250.0,
          pageCount: 10,
          overflowCount: 3,
          autofixCount: 1,
          fileSize: 65536,
        );
        final json = metrics.toJson();
        final restored = FormRenderMetrics.fromJson(json);
        expect(restored.renderTimeMs, equals(250.0));
        expect(restored.pageCount, equals(10));
        expect(restored.overflowCount, equals(3));
        expect(restored.autofixCount, equals(1));
        expect(restored.fileSize, equals(65536));
      });

      test('toJson omits null fileSize', () {
        const metrics = FormRenderMetrics(
          renderTimeMs: 50.0,
          pageCount: 1,
        );
        final json = metrics.toJson();
        expect(json.containsKey('fileSize'), isFalse);
      });

      test('fromJson handles missing fields with defaults', () {
        final json = <String, dynamic>{};
        final metrics = FormRenderMetrics.fromJson(json);
        expect(metrics.renderTimeMs, equals(0.0));
        expect(metrics.pageCount, equals(0));
        expect(metrics.overflowCount, equals(0));
        expect(metrics.autofixCount, equals(0));
        expect(metrics.fileSize, isNull);
      });
    });

    // ------------------------------------------------------------------------
    // FormRendererMetadata
    // ------------------------------------------------------------------------
    group('FormRendererMetadata', () {
      test('creates with required fields', () {
        const meta = FormRendererMetadata(
          rendererId: 'pdf-renderer',
          version: '1.2.0',
          supportedFormats: ['pdf', 'html'],
        );
        expect(meta.rendererId, equals('pdf-renderer'));
        expect(meta.version, equals('1.2.0'));
        expect(meta.supportedFormats.length, equals(2));
        expect(meta.supportedTemplateRange, isNull);
      });

      test('serialization round-trip', () {
        const meta = FormRendererMetadata(
          rendererId: 'full-renderer',
          version: '2.0.0',
          supportedFormats: ['pdf', 'html', 'docx', 'markdown'],
          supportedTemplateRange: '>=1.0.0 <3.0.0',
        );
        final json = meta.toJson();
        final restored = FormRendererMetadata.fromJson(json);
        expect(restored.rendererId, equals('full-renderer'));
        expect(restored.version, equals('2.0.0'));
        expect(restored.supportedFormats.length, equals(4));
        expect(restored.supportedFormats, contains('docx'));
        expect(
          restored.supportedTemplateRange,
          equals('>=1.0.0 <3.0.0'),
        );
      });

      test('toJson omits null supportedTemplateRange', () {
        const meta = FormRendererMetadata(
          rendererId: 'r',
          version: '0.1.0',
          supportedFormats: [],
        );
        final json = meta.toJson();
        expect(json.containsKey('supportedTemplateRange'), isFalse);
      });

      test('fromJson handles missing fields with defaults', () {
        final json = <String, dynamic>{};
        final meta = FormRendererMetadata.fromJson(json);
        expect(meta.rendererId, equals(''));
        expect(meta.version, equals(''));
        expect(meta.supportedFormats, isEmpty);
      });
    });

    // ------------------------------------------------------------------------
    // StubFormRendererPort
    // ------------------------------------------------------------------------
    group('StubFormRendererPort', () {
      late StubFormRendererPort port;

      setUp(() {
        port = StubFormRendererPort();
      });

      test('render returns successful result with requested format', () async {
        final doc = FormDocument(
          documentId: 'doc-r',
          templateId: 'tmpl-r',
          templateVersion: '1.0.0',
          metadata: FormDocumentMetadata(
            author: 'test',
            createdAt: DateTime.utc(2025, 1, 1),
          ),
        );
        final result = await port.render(document: doc, format: 'html');
        expect(result.success, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.format, equals('html'));
        expect(result.data!.pageCount, equals(1));
        expect(result.data!.content, equals(''));
      });

      test('render accepts options parameter', () async {
        final doc = FormDocument(
          documentId: 'doc-r2',
          templateId: 'tmpl-r2',
          templateVersion: '1.0.0',
          metadata: FormDocumentMetadata(
            author: 'test',
            createdAt: DateTime.utc(2025, 1, 1),
          ),
        );
        final result = await port.render(
          document: doc,
          format: 'pdf',
          options: {'quality': 'high'},
        );
        expect(result.success, isTrue);
        expect(result.data!.format, equals('pdf'));
      });

      test('supportedFormats returns html and markdown', () {
        final formats = port.supportedFormats();
        expect(formats, contains('html'));
        expect(formats, contains('markdown'));
        expect(formats.length, equals(2));
      });

      test('getMetadata returns stub metadata', () {
        final metadata = port.getMetadata();
        expect(metadata.rendererId, equals('stub'));
        expect(metadata.version, equals('0.0.0'));
        expect(metadata.supportedFormats, contains('html'));
        expect(metadata.supportedFormats, contains('markdown'));
      });
    });
  });

  // ==========================================================================
  // FormTemplatePort
  // ==========================================================================
  group('FormTemplatePort', () {
    // Helper to create a minimal layout policy for templates.
    FormLayoutPolicy makeLayoutPolicy() {
      return const FormLayoutPolicy(
        pageSize: FormPageSize(
          size: 'A4',
          width: 595.0,
          height: 842.0,
        ),
        margins: FormMargins(
          top: 72.0,
          right: 72.0,
          bottom: 72.0,
          left: 72.0,
        ),
        fontPolicy: FormFontPolicy(
          defaultFont: 'sans-serif',
          defaultSize: 12.0,
          headingSize: 18.0,
          bodySize: 11.0,
          minSize: 8.0,
        ),
      );
    }

    // Helper to create a minimal template.
    FormTemplate makeTemplate({
      String templateId = 'tmpl-1',
      String version = '1.0.0',
      String name = 'Test Template',
    }) {
      return FormTemplate(
        templateId: templateId,
        version: version,
        name: name,
        schema: const FormSchema(),
        layoutPolicy: makeLayoutPolicy(),
      );
    }

    // ------------------------------------------------------------------------
    // FormTemplate
    // ------------------------------------------------------------------------
    group('FormTemplate', () {
      test('creates with defaults', () {
        final template = makeTemplate();
        expect(template.templateId, equals('tmpl-1'));
        expect(template.version, equals('1.0.0'));
        expect(template.name, equals('Test Template'));
        expect(template.description, isNull);
        expect(template.defaultSections, isEmpty);
        expect(template.locale, isNull);
        expect(template.components, isNull);
        expect(template.i18nStrings, isNull);
        expect(template.manifest, isNull);
      });

      test('serialization round-trip with all fields', () {
        final template = FormTemplate(
          templateId: 'tmpl-full',
          version: '2.1.0',
          name: 'Full Template',
          description: 'A comprehensive template',
          schema: FormSchema(
            fields: [
              FormSchemaField(name: 'title', type: 'string', required: true),
            ],
            strict: true,
          ),
          layoutPolicy: makeLayoutPolicy(),
          defaultSections: [
            const FormSection(sectionId: 's1', index: 0, title: 'Overview'),
          ],
          locale: 'ko',
          components: ['chart-lib', 'table-lib'],
          i18nStrings: {'greeting': 'Hello', 'farewell': 'Goodbye'},
          manifest: FormTemplateManifest(
            compatRange: '>=1.0.0 <3.0.0',
            dependencies: [
              const FormTemplateDependency(
                componentId: 'chart-lib',
                version: '1.0.0',
                type: 'chart',
              ),
            ],
            metadata: {'author': 'team'},
          ),
        );
        final json = template.toJson();
        final restored = FormTemplate.fromJson(json);
        expect(restored.templateId, equals('tmpl-full'));
        expect(restored.version, equals('2.1.0'));
        expect(restored.name, equals('Full Template'));
        expect(restored.description, equals('A comprehensive template'));
        expect(restored.schema.fields.length, equals(1));
        expect(restored.schema.strict, isTrue);
        expect(restored.defaultSections.length, equals(1));
        expect(restored.defaultSections.first.title, equals('Overview'));
        expect(restored.locale, equals('ko'));
        expect(restored.components!.length, equals(2));
        expect(restored.i18nStrings!['greeting'], equals('Hello'));
        expect(restored.manifest, isNotNull);
        expect(restored.manifest!.compatRange, equals('>=1.0.0 <3.0.0'));
        expect(restored.manifest!.dependencies.length, equals(1));
        expect(
          restored.manifest!.dependencies.first.componentId,
          equals('chart-lib'),
        );
        expect(restored.manifest!.dependencies.first.type, equals('chart'));
        expect(restored.manifest!.metadata!['author'], equals('team'));
      });

      test('toJson omits null and empty optional fields', () {
        final template = makeTemplate();
        final json = template.toJson();
        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('defaultSections'), isFalse);
        expect(json.containsKey('locale'), isFalse);
        expect(json.containsKey('components'), isFalse);
        expect(json.containsKey('i18nStrings'), isFalse);
        expect(json.containsKey('manifest'), isFalse);
      });
    });

    // ------------------------------------------------------------------------
    // FormTemplateManifest
    // ------------------------------------------------------------------------
    group('FormTemplateManifest', () {
      test('creates with defaults', () {
        final manifest = FormTemplateManifest(compatRange: '>=1.0.0');
        expect(manifest.dependencies, isEmpty);
        expect(manifest.compatRange, equals('>=1.0.0'));
        expect(manifest.metadata, isNull);
      });

      test('serialization round-trip', () {
        final manifest = FormTemplateManifest(
          compatRange: '>=1.0.0 <2.0.0',
          dependencies: [
            const FormTemplateDependency(
              componentId: 'font-pack',
              version: '3.0.0',
              type: 'font',
            ),
            const FormTemplateDependency(
              componentId: 'icon-set',
              version: '1.5.0',
            ),
          ],
          metadata: {'created': '2025-01-01'},
        );
        final json = manifest.toJson();
        final restored = FormTemplateManifest.fromJson(json);
        expect(restored.compatRange, equals('>=1.0.0 <2.0.0'));
        expect(restored.dependencies.length, equals(2));
        expect(restored.dependencies.first.componentId, equals('font-pack'));
        expect(restored.dependencies.first.type, equals('font'));
        expect(restored.dependencies.last.type, isNull);
        expect(restored.metadata!['created'], equals('2025-01-01'));
      });

      test('toJson omits empty dependencies and null metadata', () {
        final manifest = FormTemplateManifest(compatRange: '>=1.0.0');
        final json = manifest.toJson();
        expect(json.containsKey('dependencies'), isFalse);
        expect(json.containsKey('metadata'), isFalse);
      });
    });

    // ------------------------------------------------------------------------
    // FormTemplateDependency
    // ------------------------------------------------------------------------
    group('FormTemplateDependency', () {
      test('creates with required fields', () {
        const dep = FormTemplateDependency(
          componentId: 'lib-x',
          version: '1.0.0',
        );
        expect(dep.componentId, equals('lib-x'));
        expect(dep.version, equals('1.0.0'));
        expect(dep.type, isNull);
      });

      test('serialization round-trip', () {
        const dep = FormTemplateDependency(
          componentId: 'chart-engine',
          version: '2.3.1',
          type: 'chart',
        );
        final json = dep.toJson();
        final restored = FormTemplateDependency.fromJson(json);
        expect(restored.componentId, equals('chart-engine'));
        expect(restored.version, equals('2.3.1'));
        expect(restored.type, equals('chart'));
      });

      test('toJson omits null type', () {
        const dep = FormTemplateDependency(
          componentId: 'x',
          version: '0.0.1',
        );
        final json = dep.toJson();
        expect(json.containsKey('type'), isFalse);
      });
    });

    // ------------------------------------------------------------------------
    // FormTemplateVersion
    // ------------------------------------------------------------------------
    group('FormTemplateVersion', () {
      test('creates with required fields', () {
        final ts = DateTime.utc(2025, 8, 1);
        final ver = FormTemplateVersion(
          templateId: 'tmpl-1',
          version: '1.0.0',
          createdAt: ts,
        );
        expect(ver.templateId, equals('tmpl-1'));
        expect(ver.version, equals('1.0.0'));
        expect(ver.createdAt, equals(ts));
        expect(ver.author, isNull);
        expect(ver.changeDescription, isNull);
      });

      test('serialization round-trip', () {
        final ts = DateTime.utc(2025, 8, 15, 10, 30);
        final ver = FormTemplateVersion(
          templateId: 'tmpl-2',
          version: '2.0.0',
          createdAt: ts,
          author: 'editor',
          changeDescription: 'Major update',
        );
        final json = ver.toJson();
        final restored = FormTemplateVersion.fromJson(json);
        expect(restored.templateId, equals('tmpl-2'));
        expect(restored.version, equals('2.0.0'));
        expect(restored.createdAt, equals(ts));
        expect(restored.author, equals('editor'));
        expect(restored.changeDescription, equals('Major update'));
      });

      test('toJson omits null optional fields', () {
        final ver = FormTemplateVersion(
          templateId: 't',
          version: '0.1.0',
          createdAt: DateTime.utc(2025, 1, 1),
        );
        final json = ver.toJson();
        expect(json.containsKey('author'), isFalse);
        expect(json.containsKey('changeDescription'), isFalse);
      });
    });

    // ------------------------------------------------------------------------
    // StubFormTemplatePort
    // ------------------------------------------------------------------------
    group('StubFormTemplatePort', () {
      late StubFormTemplatePort port;

      setUp(() {
        port = StubFormTemplatePort();
      });

      test('saveTemplate stores and returns template', () async {
        final template = makeTemplate(templateId: 'tmpl-save');
        final result = await port.saveTemplate(template: template);
        expect(result.success, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.templateId, equals('tmpl-save'));
      });

      test('getTemplate retrieves existing template', () async {
        final template = makeTemplate(templateId: 'tmpl-get');
        await port.saveTemplate(template: template);
        final result = await port.getTemplate(templateId: 'tmpl-get');
        expect(result.success, isTrue);
        expect(result.data!.name, equals('Test Template'));
      });

      test('getTemplate returns fail for missing template', () async {
        final result = await port.getTemplate(templateId: 'nonexistent');
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.code, equals('not_found'));
      });

      test('listTemplates returns all templates', () async {
        await port.saveTemplate(
          template: makeTemplate(templateId: 't1', name: 'Alpha'),
        );
        await port.saveTemplate(
          template: makeTemplate(templateId: 't2', name: 'Beta'),
        );
        final result = await port.listTemplates();
        expect(result.success, isTrue);
        expect(result.data!.length, equals(2));
      });

      test('listTemplates filters by search', () async {
        await port.saveTemplate(
          template: makeTemplate(templateId: 't1', name: 'Alpha Report'),
        );
        await port.saveTemplate(
          template: makeTemplate(templateId: 't2', name: 'Beta Summary'),
        );
        final result = await port.listTemplates(search: 'Alpha');
        expect(result.data!.length, equals(1));
        expect(result.data!.first.name, equals('Alpha Report'));
      });

      test('getTemplateVersions returns empty list', () async {
        final result = await port.getTemplateVersions(templateId: 'tmpl-1');
        expect(result.success, isTrue);
        expect(result.data, isEmpty);
      });

      test('deleteTemplate removes template', () async {
        final template = makeTemplate(templateId: 'tmpl-del');
        await port.saveTemplate(template: template);

        // Verify template exists.
        final before = await port.getTemplate(templateId: 'tmpl-del');
        expect(before.success, isTrue);

        // Delete it.
        final deleteResult = await port.deleteTemplate(templateId: 'tmpl-del');
        expect(deleteResult.success, isTrue);

        // Verify it no longer exists.
        final after = await port.getTemplate(templateId: 'tmpl-del');
        expect(after.success, isFalse);
      });

      test('clear removes all templates', () async {
        await port.saveTemplate(
          template: makeTemplate(templateId: 't1'),
        );
        await port.saveTemplate(
          template: makeTemplate(templateId: 't2'),
        );
        port.clear();
        final result = await port.listTemplates();
        expect(result.data, isEmpty);
      });

      test('saveTemplate overwrites existing template', () async {
        await port.saveTemplate(
          template: makeTemplate(templateId: 'tmpl-ow', name: 'Original'),
        );
        await port.saveTemplate(
          template: makeTemplate(templateId: 'tmpl-ow', name: 'Updated'),
        );
        final result = await port.getTemplate(templateId: 'tmpl-ow');
        expect(result.data!.name, equals('Updated'));
      });
    });
  });
}
