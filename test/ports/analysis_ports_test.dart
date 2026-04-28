import 'package:test/test.dart';
import 'package:mcp_bundle/ports.dart';

void main() {
  // ==========================================================================
  // AnalysisPort
  // ==========================================================================
  group('AnalysisPort', () {
    // ---- Enums -------------------------------------------------------------
    group('AnalysisSourceType', () {
      test('has all expected values', () {
        expect(AnalysisSourceType.values.length, equals(4));
        expect(
          AnalysisSourceType.values,
          containsAll([
            AnalysisSourceType.factgraph,
            AnalysisSourceType.mcpIo,
            AnalysisSourceType.external,
            AnalysisSourceType.upload,
          ]),
        );
      });

      test('fromString returns correct value', () {
        expect(
          AnalysisSourceType.fromString('factgraph'),
          equals(AnalysisSourceType.factgraph),
        );
        expect(
          AnalysisSourceType.fromString('mcpIo'),
          equals(AnalysisSourceType.mcpIo),
        );
        expect(
          AnalysisSourceType.fromString('external'),
          equals(AnalysisSourceType.external),
        );
        expect(
          AnalysisSourceType.fromString('upload'),
          equals(AnalysisSourceType.upload),
        );
      });

      test('fromString returns factgraph as default for unknown value', () {
        expect(
          AnalysisSourceType.fromString('unknown'),
          equals(AnalysisSourceType.factgraph),
        );
        expect(
          AnalysisSourceType.fromString(''),
          equals(AnalysisSourceType.factgraph),
        );
      });
    });

    group('AnalysisExecutionMode', () {
      test('has all expected values', () {
        expect(AnalysisExecutionMode.values.length, equals(3));
        expect(
          AnalysisExecutionMode.values,
          containsAll([
            AnalysisExecutionMode.batch,
            AnalysisExecutionMode.streaming,
            AnalysisExecutionMode.adhoc,
          ]),
        );
      });

      test('fromString returns correct value', () {
        expect(
          AnalysisExecutionMode.fromString('batch'),
          equals(AnalysisExecutionMode.batch),
        );
        expect(
          AnalysisExecutionMode.fromString('streaming'),
          equals(AnalysisExecutionMode.streaming),
        );
        expect(
          AnalysisExecutionMode.fromString('adhoc'),
          equals(AnalysisExecutionMode.adhoc),
        );
      });

      test('fromString returns batch as default for unknown value', () {
        expect(
          AnalysisExecutionMode.fromString('unknown'),
          equals(AnalysisExecutionMode.batch),
        );
      });
    });

    group('AnalysisJobStatus', () {
      test('has all expected values', () {
        expect(AnalysisJobStatus.values.length, equals(5));
        expect(
          AnalysisJobStatus.values,
          containsAll([
            AnalysisJobStatus.queued,
            AnalysisJobStatus.running,
            AnalysisJobStatus.completed,
            AnalysisJobStatus.failed,
            AnalysisJobStatus.canceled,
          ]),
        );
      });

      test('fromString returns correct value', () {
        expect(
          AnalysisJobStatus.fromString('queued'),
          equals(AnalysisJobStatus.queued),
        );
        expect(
          AnalysisJobStatus.fromString('running'),
          equals(AnalysisJobStatus.running),
        );
        expect(
          AnalysisJobStatus.fromString('completed'),
          equals(AnalysisJobStatus.completed),
        );
        expect(
          AnalysisJobStatus.fromString('failed'),
          equals(AnalysisJobStatus.failed),
        );
        expect(
          AnalysisJobStatus.fromString('canceled'),
          equals(AnalysisJobStatus.canceled),
        );
      });

      test('fromString returns queued as default for unknown value', () {
        expect(
          AnalysisJobStatus.fromString('unknown'),
          equals(AnalysisJobStatus.queued),
        );
      });
    });

    group('AnalysisArtifactType', () {
      test('has all expected values', () {
        expect(AnalysisArtifactType.values.length, equals(7));
        expect(
          AnalysisArtifactType.values,
          containsAll([
            AnalysisArtifactType.metric,
            AnalysisArtifactType.series,
            AnalysisArtifactType.table,
            AnalysisArtifactType.chart,
            AnalysisArtifactType.summary,
            AnalysisArtifactType.alert,
            AnalysisArtifactType.model,
          ]),
        );
      });

      test('fromString returns correct value', () {
        expect(
          AnalysisArtifactType.fromString('metric'),
          equals(AnalysisArtifactType.metric),
        );
        expect(
          AnalysisArtifactType.fromString('series'),
          equals(AnalysisArtifactType.series),
        );
        expect(
          AnalysisArtifactType.fromString('table'),
          equals(AnalysisArtifactType.table),
        );
        expect(
          AnalysisArtifactType.fromString('chart'),
          equals(AnalysisArtifactType.chart),
        );
        expect(
          AnalysisArtifactType.fromString('summary'),
          equals(AnalysisArtifactType.summary),
        );
        expect(
          AnalysisArtifactType.fromString('alert'),
          equals(AnalysisArtifactType.alert),
        );
        expect(
          AnalysisArtifactType.fromString('model'),
          equals(AnalysisArtifactType.model),
        );
      });

      test('fromString returns metric as default for unknown value', () {
        expect(
          AnalysisArtifactType.fromString('unknown'),
          equals(AnalysisArtifactType.metric),
        );
      });
    });

    group('AnalysisAlertSeverity', () {
      test('has all expected values', () {
        expect(AnalysisAlertSeverity.values.length, equals(3));
        expect(
          AnalysisAlertSeverity.values,
          containsAll([
            AnalysisAlertSeverity.info,
            AnalysisAlertSeverity.warn,
            AnalysisAlertSeverity.critical,
          ]),
        );
      });

      test('fromString returns correct value', () {
        expect(
          AnalysisAlertSeverity.fromString('info'),
          equals(AnalysisAlertSeverity.info),
        );
        expect(
          AnalysisAlertSeverity.fromString('warn'),
          equals(AnalysisAlertSeverity.warn),
        );
        expect(
          AnalysisAlertSeverity.fromString('critical'),
          equals(AnalysisAlertSeverity.critical),
        );
      });

      test('fromString returns info as default for unknown value', () {
        expect(
          AnalysisAlertSeverity.fromString('unknown'),
          equals(AnalysisAlertSeverity.info),
        );
      });
    });

    // ---- Spec Types --------------------------------------------------------
    group('AnalysisSpecMetadata', () {
      test('creates with defaults', () {
        const meta = AnalysisSpecMetadata();
        expect(meta.author, isNull);
        expect(meta.tags, isEmpty);
        expect(meta.description, isNull);
      });

      test('creates with all fields', () {
        const meta = AnalysisSpecMetadata(
          author: 'test-author',
          tags: ['tag1', 'tag2'],
          description: 'A test description',
        );
        expect(meta.author, equals('test-author'));
        expect(meta.tags, equals(['tag1', 'tag2']));
        expect(meta.description, equals('A test description'));
      });

      test('serialization round-trip', () {
        const original = AnalysisSpecMetadata(
          author: 'author1',
          tags: ['a', 'b'],
          description: 'desc',
        );
        final json = original.toJson();
        final restored = AnalysisSpecMetadata.fromJson(json);
        expect(restored.author, equals(original.author));
        expect(restored.tags, equals(original.tags));
        expect(restored.description, equals(original.description));
      });

      test('toJson omits null and empty fields', () {
        const meta = AnalysisSpecMetadata();
        final json = meta.toJson();
        expect(json.containsKey('author'), isFalse);
        expect(json.containsKey('tags'), isFalse);
        expect(json.containsKey('description'), isFalse);
      });
    });

    group('AnalysisTimeRange', () {
      test('creates with start and end', () {
        final range = AnalysisTimeRange(
          start: DateTime.utc(2025, 1, 1),
          end: DateTime.utc(2025, 12, 31),
        );
        expect(range.start, equals(DateTime.utc(2025, 1, 1)));
        expect(range.end, equals(DateTime.utc(2025, 12, 31)));
      });

      test('serialization round-trip', () {
        final original = AnalysisTimeRange(
          start: DateTime.utc(2025, 6, 1),
          end: DateTime.utc(2025, 6, 30),
        );
        final json = original.toJson();
        final restored = AnalysisTimeRange.fromJson(json);
        expect(restored.start, equals(original.start));
        expect(restored.end, equals(original.end));
      });
    });

    group('AnalysisColumnInfo', () {
      test('creates with required fields', () {
        const col = AnalysisColumnInfo(name: 'temp', type: 'double');
        expect(col.name, equals('temp'));
        expect(col.type, equals('double'));
        expect(col.unit, isNull);
      });

      test('creates with unit', () {
        const col = AnalysisColumnInfo(
          name: 'temp',
          type: 'double',
          unit: 'celsius',
        );
        expect(col.unit, equals('celsius'));
      });

      test('serialization round-trip', () {
        const original = AnalysisColumnInfo(
          name: 'pressure',
          type: 'double',
          unit: 'Pa',
        );
        final json = original.toJson();
        final restored = AnalysisColumnInfo.fromJson(json);
        expect(restored.name, equals(original.name));
        expect(restored.type, equals(original.type));
        expect(restored.unit, equals(original.unit));
      });

      test('toJson omits null unit', () {
        const col = AnalysisColumnInfo(name: 'x', type: 'int');
        final json = col.toJson();
        expect(json.containsKey('unit'), isFalse);
      });
    });

    group('AnalysisSourceSchema', () {
      test('creates with columns', () {
        const schema = AnalysisSourceSchema(
          columns: [
            AnalysisColumnInfo(name: 'a', type: 'int'),
            AnalysisColumnInfo(name: 'b', type: 'string'),
          ],
        );
        expect(schema.columns.length, equals(2));
        expect(schema.timestampField, isNull);
      });

      test('serialization round-trip', () {
        const original = AnalysisSourceSchema(
          columns: [
            AnalysisColumnInfo(name: 'ts', type: 'datetime'),
            AnalysisColumnInfo(name: 'value', type: 'double', unit: 'kg'),
          ],
          timestampField: 'ts',
        );
        final json = original.toJson();
        final restored = AnalysisSourceSchema.fromJson(json);
        expect(restored.columns.length, equals(2));
        expect(restored.columns[0].name, equals('ts'));
        expect(restored.columns[1].unit, equals('kg'));
        expect(restored.timestampField, equals('ts'));
      });
    });

    group('AnalysisInputSource', () {
      test('creates with required fields', () {
        final source = AnalysisInputSource(
          sourceType: AnalysisSourceType.factgraph,
        );
        expect(source.sourceType, equals(AnalysisSourceType.factgraph));
        expect(source.query, isNull);
        expect(source.filter, isNull);
        expect(source.timeRange, isNull);
        expect(source.schema, isNull);
      });

      test('creates with all optional fields', () {
        final source = AnalysisInputSource(
          sourceType: AnalysisSourceType.mcpIo,
          query: 'SELECT * FROM sensor',
          filter: {'status': 'active'},
          timeRange: AnalysisTimeRange(
            start: DateTime.utc(2025, 1, 1),
            end: DateTime.utc(2025, 12, 31),
          ),
          schema: const AnalysisSourceSchema(
            columns: [AnalysisColumnInfo(name: 'val', type: 'double')],
          ),
        );
        expect(source.query, equals('SELECT * FROM sensor'));
        expect(source.filter!['status'], equals('active'));
        expect(source.timeRange, isNotNull);
        expect(source.schema!.columns.length, equals(1));
      });

      test('serialization round-trip', () {
        final original = AnalysisInputSource(
          sourceType: AnalysisSourceType.external,
          query: 'test-query',
          filter: {'key': 'value'},
          timeRange: AnalysisTimeRange(
            start: DateTime.utc(2025, 3, 1),
            end: DateTime.utc(2025, 3, 31),
          ),
          schema: const AnalysisSourceSchema(
            columns: [AnalysisColumnInfo(name: 'x', type: 'int')],
            timestampField: 'x',
          ),
        );
        final json = original.toJson();
        final restored = AnalysisInputSource.fromJson(json);
        expect(restored.sourceType, equals(AnalysisSourceType.external));
        expect(restored.query, equals('test-query'));
        expect(restored.filter!['key'], equals('value'));
        expect(restored.timeRange!.start, equals(DateTime.utc(2025, 3, 1)));
        expect(restored.schema!.timestampField, equals('x'));
      });
    });

    group('AnalysisTransform', () {
      test('creates with required fields', () {
        final transform = AnalysisTransform(
          name: 'filter',
          parameters: {'column': 'status', 'value': 'active'},
        );
        expect(transform.name, equals('filter'));
        expect(transform.parameters['column'], equals('status'));
      });

      test('serialization round-trip', () {
        final original = AnalysisTransform(
          name: 'resample',
          parameters: {'interval': '1h'},
        );
        final json = original.toJson();
        final restored = AnalysisTransform.fromJson(json);
        expect(restored.name, equals('resample'));
        expect(restored.parameters['interval'], equals('1h'));
      });

      test('fromJson defaults parameters to empty map', () {
        final restored = AnalysisTransform.fromJson({
          'name': 'sort',
        });
        expect(restored.parameters, isEmpty);
      });
    });

    group('AnalysisStep', () {
      test('creates with required fields', () {
        final step = AnalysisStep(
          function: 'descriptive_stats',
          parameters: {'columns': ['temp']},
        );
        expect(step.function, equals('descriptive_stats'));
      });

      test('serialization round-trip', () {
        final original = AnalysisStep(
          function: 'anomaly_detect',
          parameters: {'method': 'zscore', 'threshold': 3.0},
        );
        final json = original.toJson();
        final restored = AnalysisStep.fromJson(json);
        expect(restored.function, equals('anomaly_detect'));
        expect(restored.parameters['method'], equals('zscore'));
        expect(restored.parameters['threshold'], equals(3.0));
      });

      test('fromJson defaults parameters to empty map', () {
        final restored = AnalysisStep.fromJson({
          'function': 'test_fn',
        });
        expect(restored.parameters, isEmpty);
      });
    });

    group('AnalysisOutputDef', () {
      test('creates with required fields', () {
        final output = AnalysisOutputDef(
          type: AnalysisArtifactType.metric,
          name: 'avg_temp',
        );
        expect(output.type, equals(AnalysisArtifactType.metric));
        expect(output.name, equals('avg_temp'));
        expect(output.parameters, isNull);
      });

      test('creates with parameters', () {
        final output = AnalysisOutputDef(
          type: AnalysisArtifactType.chart,
          name: 'trend_chart',
          parameters: {'chartType': 'line'},
        );
        expect(output.parameters!['chartType'], equals('line'));
      });

      test('serialization round-trip', () {
        final original = AnalysisOutputDef(
          type: AnalysisArtifactType.table,
          name: 'results_table',
          parameters: {'limit': 100},
        );
        final json = original.toJson();
        final restored = AnalysisOutputDef.fromJson(json);
        expect(restored.type, equals(AnalysisArtifactType.table));
        expect(restored.name, equals('results_table'));
        expect(restored.parameters!['limit'], equals(100));
      });
    });

    // ---- AnalysisSpec ------------------------------------------------------
    group('AnalysisSpec', () {
      AnalysisSpec createSampleSpec() {
        return AnalysisSpec(
          specId: 'spec-001',
          version: '1.0.0',
          inputSources: [
            AnalysisInputSource(
              sourceType: AnalysisSourceType.factgraph,
              query: 'sensor_data',
            ),
          ],
          transforms: [
            AnalysisTransform(
              name: 'filter',
              parameters: {'status': 'active'},
            ),
          ],
          analysisSteps: [
            AnalysisStep(
              function: 'descriptive_stats',
              parameters: {'columns': ['temperature']},
            ),
          ],
          outputs: [
            AnalysisOutputDef(
              type: AnalysisArtifactType.metric,
              name: 'avg_temp',
            ),
          ],
          parameters: {'region': 'north'},
          metadata: const AnalysisSpecMetadata(
            author: 'tester',
            tags: ['sensor', 'temperature'],
            description: 'Temperature analysis spec',
          ),
        );
      }

      test('creates with all fields', () {
        final spec = createSampleSpec();
        expect(spec.specId, equals('spec-001'));
        expect(spec.version, equals('1.0.0'));
        expect(spec.inputSources.length, equals(1));
        expect(spec.transforms.length, equals(1));
        expect(spec.analysisSteps.length, equals(1));
        expect(spec.outputs.length, equals(1));
        expect(spec.parameters['region'], equals('north'));
        expect(spec.metadata.author, equals('tester'));
      });

      test('creates with default transforms and parameters', () {
        final spec = AnalysisSpec(
          specId: 'spec-002',
          version: '1.0.0',
          inputSources: [
            AnalysisInputSource(
              sourceType: AnalysisSourceType.upload,
            ),
          ],
          analysisSteps: [
            AnalysisStep(
              function: 'count',
              parameters: {},
            ),
          ],
          outputs: [
            AnalysisOutputDef(
              type: AnalysisArtifactType.metric,
              name: 'row_count',
            ),
          ],
          metadata: const AnalysisSpecMetadata(),
        );
        expect(spec.transforms, isEmpty);
        expect(spec.parameters, isEmpty);
      });

      test('serialization round-trip', () {
        final original = createSampleSpec();
        final json = original.toJson();
        final restored = AnalysisSpec.fromJson(json);

        expect(restored.specId, equals(original.specId));
        expect(restored.version, equals(original.version));
        expect(
          restored.inputSources.length,
          equals(original.inputSources.length),
        );
        expect(
          restored.inputSources[0].sourceType,
          equals(AnalysisSourceType.factgraph),
        );
        expect(restored.transforms.length, equals(original.transforms.length));
        expect(restored.transforms[0].name, equals('filter'));
        expect(
          restored.analysisSteps.length,
          equals(original.analysisSteps.length),
        );
        expect(restored.analysisSteps[0].function, equals('descriptive_stats'));
        expect(restored.outputs.length, equals(original.outputs.length));
        expect(
          restored.outputs[0].type,
          equals(AnalysisArtifactType.metric),
        );
        expect(restored.parameters['region'], equals('north'));
        expect(restored.metadata.author, equals('tester'));
        expect(restored.metadata.tags, equals(['sensor', 'temperature']));
        expect(
          restored.metadata.description,
          equals('Temperature analysis spec'),
        );
      });

      test('toJson omits empty transforms and parameters', () {
        final spec = AnalysisSpec(
          specId: 'spec-minimal',
          version: '0.1.0',
          inputSources: [
            AnalysisInputSource(sourceType: AnalysisSourceType.upload),
          ],
          analysisSteps: [
            AnalysisStep(function: 'noop', parameters: {}),
          ],
          outputs: [
            AnalysisOutputDef(
              type: AnalysisArtifactType.summary,
              name: 'out',
            ),
          ],
          metadata: const AnalysisSpecMetadata(),
        );
        final json = spec.toJson();
        expect(json.containsKey('transforms'), isFalse);
        expect(json.containsKey('parameters'), isFalse);
      });
    });

    // ---- Job Types ---------------------------------------------------------
    group('AnalysisJobLog', () {
      test('creates with required fields', () {
        final log = AnalysisJobLog(
          step: 'descriptive_stats',
          timestamp: DateTime.utc(2025, 6, 15, 10, 30),
          inputSize: 1000,
          outputSize: 5,
          executionTime: const Duration(milliseconds: 250),
        );
        expect(log.step, equals('descriptive_stats'));
        expect(log.inputSize, equals(1000));
        expect(log.outputSize, equals(5));
        expect(log.executionTime.inMilliseconds, equals(250));
      });

      test('serialization round-trip', () {
        final original = AnalysisJobLog(
          step: 'transform_filter',
          timestamp: DateTime.utc(2025, 6, 15, 10, 30),
          inputSize: 500,
          outputSize: 200,
          executionTime: const Duration(milliseconds: 100),
        );
        final json = original.toJson();
        final restored = AnalysisJobLog.fromJson(json);
        expect(restored.step, equals('transform_filter'));
        expect(restored.timestamp, equals(DateTime.utc(2025, 6, 15, 10, 30)));
        expect(restored.inputSize, equals(500));
        expect(restored.outputSize, equals(200));
        expect(restored.executionTime.inMilliseconds, equals(100));
      });

      test('fromJson defaults inputSize and outputSize to 0', () {
        final restored = AnalysisJobLog.fromJson({
          'step': 'test',
          'timestamp': '2025-06-15T10:00:00.000Z',
        });
        expect(restored.inputSize, equals(0));
        expect(restored.outputSize, equals(0));
        expect(restored.executionTime, equals(Duration.zero));
      });
    });

    group('AnalysisError', () {
      test('creates with required fields', () {
        final error = AnalysisError(
          code: 'source.unavailable',
          message: 'Data source not reachable',
        );
        expect(error.code, equals('source.unavailable'));
        expect(error.message, equals('Data source not reachable'));
        expect(error.details, isNull);
        expect(error.step, isNull);
        expect(error.timestamp, isNull);
      });

      test('creates with all optional fields', () {
        final now = DateTime.utc(2025, 6, 15);
        final error = AnalysisError(
          code: 'transform.failed',
          message: 'Invalid column',
          details: {'column': 'missing_col'},
          step: 'filter_step',
          timestamp: now,
        );
        expect(error.details!['column'], equals('missing_col'));
        expect(error.step, equals('filter_step'));
        expect(error.timestamp, equals(now));
      });

      test('serialization round-trip', () {
        final original = AnalysisError(
          code: 'analysis.timeout',
          message: 'Execution exceeded time limit',
          details: {'limitMs': 30000},
          step: 'anomaly_detect',
          timestamp: DateTime.utc(2025, 7, 1, 12, 0),
        );
        final json = original.toJson();
        final restored = AnalysisError.fromJson(json);
        expect(restored.code, equals('analysis.timeout'));
        expect(restored.message, equals('Execution exceeded time limit'));
        expect(restored.details!['limitMs'], equals(30000));
        expect(restored.step, equals('anomaly_detect'));
        expect(
          restored.timestamp,
          equals(DateTime.utc(2025, 7, 1, 12, 0)),
        );
      });

      test('toJson omits null fields', () {
        final error = AnalysisError(
          code: 'err',
          message: 'msg',
        );
        final json = error.toJson();
        expect(json.containsKey('details'), isFalse);
        expect(json.containsKey('step'), isFalse);
        expect(json.containsKey('timestamp'), isFalse);
      });
    });

    group('AnalysisJob', () {
      test('creates with required fields and defaults', () {
        final now = DateTime.utc(2025, 6, 15);
        final job = AnalysisJob(
          jobId: 'job-001',
          specId: 'spec-001',
          specVersion: '1.0.0',
          mode: AnalysisExecutionMode.batch,
          status: AnalysisJobStatus.queued,
          createdAt: now,
        );
        expect(job.jobId, equals('job-001'));
        expect(job.specId, equals('spec-001'));
        expect(job.specVersion, equals('1.0.0'));
        expect(job.mode, equals(AnalysisExecutionMode.batch));
        expect(job.status, equals(AnalysisJobStatus.queued));
        expect(job.progress, equals(0.0));
        expect(job.createdAt, equals(now));
        expect(job.startTime, isNull);
        expect(job.endTime, isNull);
        expect(job.inputRange, isNull);
        expect(job.parameters, isEmpty);
        expect(job.artifactIds, isEmpty);
        expect(job.logs, isEmpty);
        expect(job.errors, isEmpty);
      });

      test('creates with all optional fields', () {
        final created = DateTime.utc(2025, 6, 15, 10, 0);
        final started = DateTime.utc(2025, 6, 15, 10, 1);
        final ended = DateTime.utc(2025, 6, 15, 10, 5);
        final job = AnalysisJob(
          jobId: 'job-002',
          specId: 'spec-002',
          specVersion: '2.0.0',
          mode: AnalysisExecutionMode.streaming,
          status: AnalysisJobStatus.completed,
          progress: 1.0,
          createdAt: created,
          startTime: started,
          endTime: ended,
          inputRange: AnalysisTimeRange(
            start: DateTime.utc(2025, 1, 1),
            end: DateTime.utc(2025, 6, 30),
          ),
          parameters: {'key': 'val'},
          artifactIds: ['art-1', 'art-2'],
          logs: [
            AnalysisJobLog(
              step: 'step1',
              timestamp: started,
              inputSize: 100,
              outputSize: 10,
              executionTime: const Duration(seconds: 1),
            ),
          ],
          errors: [
            AnalysisError(code: 'warn', message: 'minor issue'),
          ],
        );
        expect(job.progress, equals(1.0));
        expect(job.startTime, equals(started));
        expect(job.endTime, equals(ended));
        expect(job.inputRange, isNotNull);
        expect(job.parameters['key'], equals('val'));
        expect(job.artifactIds.length, equals(2));
        expect(job.logs.length, equals(1));
        expect(job.errors.length, equals(1));
      });

      test('serialization round-trip', () {
        final created = DateTime.utc(2025, 6, 15, 10, 0);
        final started = DateTime.utc(2025, 6, 15, 10, 1);
        final ended = DateTime.utc(2025, 6, 15, 10, 5);
        final original = AnalysisJob(
          jobId: 'job-rt',
          specId: 'spec-rt',
          specVersion: '3.0.0',
          mode: AnalysisExecutionMode.adhoc,
          status: AnalysisJobStatus.failed,
          progress: 0.5,
          createdAt: created,
          startTime: started,
          endTime: ended,
          inputRange: AnalysisTimeRange(
            start: DateTime.utc(2025, 1, 1),
            end: DateTime.utc(2025, 6, 30),
          ),
          parameters: {'retries': 3},
          artifactIds: ['art-x'],
          logs: [
            AnalysisJobLog(
              step: 'load',
              timestamp: started,
              inputSize: 50,
              outputSize: 50,
              executionTime: const Duration(milliseconds: 200),
            ),
          ],
          errors: [
            AnalysisError(
              code: 'runtime.error',
              message: 'Crashed',
              step: 'compute',
              timestamp: ended,
            ),
          ],
        );
        final json = original.toJson();
        final restored = AnalysisJob.fromJson(json);

        expect(restored.jobId, equals('job-rt'));
        expect(restored.specId, equals('spec-rt'));
        expect(restored.specVersion, equals('3.0.0'));
        expect(restored.mode, equals(AnalysisExecutionMode.adhoc));
        expect(restored.status, equals(AnalysisJobStatus.failed));
        expect(restored.progress, equals(0.5));
        expect(restored.createdAt, equals(created));
        expect(restored.startTime, equals(started));
        expect(restored.endTime, equals(ended));
        expect(restored.inputRange!.start, equals(DateTime.utc(2025, 1, 1)));
        expect(restored.parameters['retries'], equals(3));
        expect(restored.artifactIds, equals(['art-x']));
        expect(restored.logs.length, equals(1));
        expect(restored.logs[0].step, equals('load'));
        expect(restored.errors.length, equals(1));
        expect(restored.errors[0].code, equals('runtime.error'));
      });

      test('toJson omits empty optional lists and maps', () {
        final job = AnalysisJob(
          jobId: 'job-min',
          specId: 'spec-min',
          specVersion: '1.0.0',
          mode: AnalysisExecutionMode.batch,
          status: AnalysisJobStatus.queued,
          createdAt: DateTime.utc(2025, 1, 1),
        );
        final json = job.toJson();
        expect(json.containsKey('startTime'), isFalse);
        expect(json.containsKey('endTime'), isFalse);
        expect(json.containsKey('inputRange'), isFalse);
        expect(json.containsKey('parameters'), isFalse);
        expect(json.containsKey('artifactIds'), isFalse);
        expect(json.containsKey('logs'), isFalse);
        expect(json.containsKey('errors'), isFalse);
      });
    });

    // ---- Artifact Types ----------------------------------------------------
    group('AnalysisArtifactProvenance', () {
      test('creates with required fields and defaults', () {
        final prov = AnalysisArtifactProvenance(
          version: '1.0.0',
          createdAt: DateTime.utc(2025, 6, 1),
          specId: 'spec-001',
          specVersion: '1.0.0',
        );
        expect(prov.version, equals('1.0.0'));
        expect(prov.tags, isEmpty);
        expect(prov.sourceUri, isNull);
        expect(prov.sourceQuery, isNull);
        expect(prov.inputRange, isNull);
        expect(prov.specId, equals('spec-001'));
      });

      test('serialization round-trip', () {
        final original = AnalysisArtifactProvenance(
          version: '2.0.0',
          tags: ['prod', 'v2'],
          createdAt: DateTime.utc(2025, 6, 15),
          sourceUri: 'factgraph://sensors/temp',
          sourceQuery: 'SELECT temperature FROM sensors',
          inputRange: AnalysisTimeRange(
            start: DateTime.utc(2025, 1, 1),
            end: DateTime.utc(2025, 6, 30),
          ),
          specId: 'spec-rt',
          specVersion: '2.0.0',
        );
        final json = original.toJson();
        final restored = AnalysisArtifactProvenance.fromJson(json);
        expect(restored.version, equals('2.0.0'));
        expect(restored.tags, equals(['prod', 'v2']));
        expect(restored.sourceUri, equals('factgraph://sensors/temp'));
        expect(
          restored.sourceQuery,
          equals('SELECT temperature FROM sensors'),
        );
        expect(restored.inputRange!.start, equals(DateTime.utc(2025, 1, 1)));
        expect(restored.specId, equals('spec-rt'));
        expect(restored.specVersion, equals('2.0.0'));
      });

      test('toJson omits null and empty fields', () {
        final prov = AnalysisArtifactProvenance(
          version: '1.0.0',
          createdAt: DateTime.utc(2025, 1, 1),
          specId: 'spec-x',
          specVersion: '1.0.0',
        );
        final json = prov.toJson();
        expect(json.containsKey('tags'), isFalse);
        expect(json.containsKey('sourceUri'), isFalse);
        expect(json.containsKey('sourceQuery'), isFalse);
        expect(json.containsKey('inputRange'), isFalse);
      });
    });

    // Helper provenance for artifact tests.
    AnalysisArtifactProvenance testProvenance() {
      return AnalysisArtifactProvenance(
        version: '1.0.0',
        createdAt: DateTime.utc(2025, 6, 15),
        specId: 'spec-test',
        specVersion: '1.0.0',
      );
    }

    group('AnalysisMetricArtifact', () {
      test('creates with correct type', () {
        final artifact = AnalysisMetricArtifact(
          artifactId: 'art-metric-1',
          name: 'avg_temperature',
          provenance: testProvenance(),
          value: 23.5,
          unit: 'celsius',
          timeRange: AnalysisTimeRange(
            start: DateTime.utc(2025, 1, 1),
            end: DateTime.utc(2025, 6, 30),
          ),
        );
        expect(artifact.type, equals(AnalysisArtifactType.metric));
        expect(artifact.value, equals(23.5));
        expect(artifact.unit, equals('celsius'));
      });

      test('serialization round-trip', () {
        final original = AnalysisMetricArtifact(
          artifactId: 'art-m-rt',
          name: 'max_pressure',
          provenance: testProvenance(),
          value: 1013.25,
          unit: 'hPa',
          timeRange: AnalysisTimeRange(
            start: DateTime.utc(2025, 3, 1),
            end: DateTime.utc(2025, 3, 31),
          ),
        );
        final json = original.toJson();
        final restored = AnalysisMetricArtifact.fromJson(json);
        expect(restored.artifactId, equals('art-m-rt'));
        expect(restored.name, equals('max_pressure'));
        expect(restored.type, equals(AnalysisArtifactType.metric));
        expect(restored.value, equals(1013.25));
        expect(restored.unit, equals('hPa'));
        expect(
          restored.timeRange.start,
          equals(DateTime.utc(2025, 3, 1)),
        );
      });
    });

    group('AnalysisSeriesArtifact', () {
      test('creates with correct type', () {
        final artifact = AnalysisSeriesArtifact(
          artifactId: 'art-series-1',
          name: 'temp_series',
          provenance: testProvenance(),
          points: [
            AnalysisTimePoint(
              t: DateTime.utc(2025, 6, 1),
              v: 20.0,
            ),
            AnalysisTimePoint(
              t: DateTime.utc(2025, 6, 2),
              v: 21.5,
            ),
          ],
          unit: 'celsius',
        );
        expect(artifact.type, equals(AnalysisArtifactType.series));
        expect(artifact.points.length, equals(2));
        expect(artifact.unit, equals('celsius'));
      });

      test('serialization round-trip', () {
        final original = AnalysisSeriesArtifact(
          artifactId: 'art-s-rt',
          name: 'humidity_series',
          provenance: testProvenance(),
          points: [
            AnalysisTimePoint(t: DateTime.utc(2025, 6, 1), v: 65.0),
          ],
          unit: '%',
        );
        final json = original.toJson();
        final restored = AnalysisSeriesArtifact.fromJson(json);
        expect(restored.artifactId, equals('art-s-rt'));
        expect(restored.points.length, equals(1));
        expect(restored.points[0].v, equals(65.0));
        expect(restored.unit, equals('%'));
      });
    });

    group('AnalysisTimePoint', () {
      test('serialization round-trip', () {
        final original = AnalysisTimePoint(
          t: DateTime.utc(2025, 6, 15, 12, 0),
          v: 42,
        );
        final json = original.toJson();
        final restored = AnalysisTimePoint.fromJson(json);
        expect(restored.t, equals(DateTime.utc(2025, 6, 15, 12, 0)));
        expect(restored.v, equals(42));
      });
    });

    group('AnalysisTableArtifact', () {
      test('creates with correct type', () {
        final artifact = AnalysisTableArtifact(
          artifactId: 'art-table-1',
          name: 'summary_table',
          provenance: testProvenance(),
          columns: ['metric', 'value', 'unit'],
          rows: [
            {'metric': 'avg', 'value': 23.5, 'unit': 'C'},
            {'metric': 'max', 'value': 35.0, 'unit': 'C'},
          ],
          columnUnits: {'value': 'celsius'},
        );
        expect(artifact.type, equals(AnalysisArtifactType.table));
        expect(artifact.columns.length, equals(3));
        expect(artifact.rows.length, equals(2));
        expect(artifact.columnUnits!['value'], equals('celsius'));
      });

      test('creates without columnUnits', () {
        final artifact = AnalysisTableArtifact(
          artifactId: 'art-table-2',
          name: 'simple_table',
          provenance: testProvenance(),
          columns: ['a', 'b'],
          rows: [
            {'a': 1, 'b': 2},
          ],
        );
        expect(artifact.columnUnits, isNull);
      });

      test('serialization round-trip', () {
        final original = AnalysisTableArtifact(
          artifactId: 'art-t-rt',
          name: 'stats_table',
          provenance: testProvenance(),
          columns: ['name', 'count'],
          rows: [
            {'name': 'sensor1', 'count': 100},
          ],
          columnUnits: {'count': 'events'},
        );
        final json = original.toJson();
        final restored = AnalysisTableArtifact.fromJson(json);
        expect(restored.artifactId, equals('art-t-rt'));
        expect(restored.columns, equals(['name', 'count']));
        expect(restored.rows[0]['name'], equals('sensor1'));
        expect(restored.columnUnits!['count'], equals('events'));
      });
    });

    group('AnalysisAxisMeta', () {
      test('creates with required fields', () {
        final axis = AnalysisAxisMeta(
          label: 'Time',
          type: 'time',
        );
        expect(axis.label, equals('Time'));
        expect(axis.type, equals('time'));
        expect(axis.min, isNull);
        expect(axis.max, isNull);
      });

      test('serialization round-trip', () {
        final original = AnalysisAxisMeta(
          label: 'Value',
          type: 'linear',
          min: 0,
          max: 100,
        );
        final json = original.toJson();
        final restored = AnalysisAxisMeta.fromJson(json);
        expect(restored.label, equals('Value'));
        expect(restored.type, equals('linear'));
        expect(restored.min, equals(0));
        expect(restored.max, equals(100));
      });

      test('toJson omits null min/max', () {
        final axis = AnalysisAxisMeta(label: 'X', type: 'category');
        final json = axis.toJson();
        expect(json.containsKey('min'), isFalse);
        expect(json.containsKey('max'), isFalse);
      });
    });

    group('AnalysisChartArtifact', () {
      test('creates with correct type', () {
        final artifact = AnalysisChartArtifact(
          artifactId: 'art-chart-1',
          name: 'trend_chart',
          provenance: testProvenance(),
          series: [
            AnalysisSeriesArtifact(
              artifactId: 'inner-series-1',
              name: 'temp',
              provenance: testProvenance(),
              points: [
                AnalysisTimePoint(t: DateTime.utc(2025, 6, 1), v: 20.0),
              ],
              unit: 'C',
            ),
          ],
          xAxis: AnalysisAxisMeta(label: 'Time', type: 'time'),
          yAxis: AnalysisAxisMeta(label: 'Temp', type: 'linear'),
          units: {'temp': 'celsius'},
        );
        expect(artifact.type, equals(AnalysisArtifactType.chart));
        expect(artifact.series.length, equals(1));
        expect(artifact.xAxis.label, equals('Time'));
        expect(artifact.yAxis.label, equals('Temp'));
        expect(artifact.units!['temp'], equals('celsius'));
      });

      test('creates without units', () {
        final artifact = AnalysisChartArtifact(
          artifactId: 'art-chart-2',
          name: 'basic_chart',
          provenance: testProvenance(),
          series: [],
          xAxis: AnalysisAxisMeta(label: 'X', type: 'linear'),
          yAxis: AnalysisAxisMeta(label: 'Y', type: 'linear'),
        );
        expect(artifact.units, isNull);
      });

      test('serialization round-trip', () {
        final original = AnalysisChartArtifact(
          artifactId: 'art-c-rt',
          name: 'multi_chart',
          provenance: testProvenance(),
          series: [
            AnalysisSeriesArtifact(
              artifactId: 'ser-1',
              name: 'series_a',
              provenance: testProvenance(),
              points: [
                AnalysisTimePoint(t: DateTime.utc(2025, 6, 1), v: 10),
              ],
              unit: 'units',
            ),
          ],
          xAxis: AnalysisAxisMeta(label: 'X', type: 'time'),
          yAxis: AnalysisAxisMeta(
            label: 'Y',
            type: 'logarithmic',
            min: 1,
            max: 1000,
          ),
          units: {'series_a': 'units'},
        );
        final json = original.toJson();
        final restored = AnalysisChartArtifact.fromJson(json);
        expect(restored.artifactId, equals('art-c-rt'));
        expect(restored.series.length, equals(1));
        expect(restored.xAxis.type, equals('time'));
        expect(restored.yAxis.type, equals('logarithmic'));
        expect(restored.yAxis.min, equals(1));
        expect(restored.yAxis.max, equals(1000));
        expect(restored.units!['series_a'], equals('units'));
      });
    });

    group('AnalysisEvidenceLink', () {
      test('creates with required fields', () {
        const link = AnalysisEvidenceLink(uri: 'factgraph://data/1');
        expect(link.uri, equals('factgraph://data/1'));
        expect(link.query, isNull);
        expect(link.dataRange, isNull);
      });

      test('serialization round-trip', () {
        final original = AnalysisEvidenceLink(
          uri: 'factgraph://sensors/temp',
          query: 'WHERE region = north',
          dataRange: AnalysisTimeRange(
            start: DateTime.utc(2025, 1, 1),
            end: DateTime.utc(2025, 6, 30),
          ),
        );
        final json = original.toJson();
        final restored = AnalysisEvidenceLink.fromJson(json);
        expect(restored.uri, equals('factgraph://sensors/temp'));
        expect(restored.query, equals('WHERE region = north'));
        expect(
          restored.dataRange!.start,
          equals(DateTime.utc(2025, 1, 1)),
        );
      });

      test('toJson omits null fields', () {
        const link = AnalysisEvidenceLink(uri: 'test://uri');
        final json = link.toJson();
        expect(json.containsKey('query'), isFalse);
        expect(json.containsKey('dataRange'), isFalse);
      });
    });

    group('AnalysisSummaryArtifact', () {
      test('creates with correct type', () {
        final artifact = AnalysisSummaryArtifact(
          artifactId: 'art-sum-1',
          name: 'analysis_summary',
          provenance: testProvenance(),
          text: 'Temperature is within normal range.',
        );
        expect(artifact.type, equals(AnalysisArtifactType.summary));
        expect(artifact.text, equals('Temperature is within normal range.'));
        expect(artifact.evidenceLinks, isEmpty);
      });

      test('creates with evidence links', () {
        final artifact = AnalysisSummaryArtifact(
          artifactId: 'art-sum-2',
          name: 'detailed_summary',
          provenance: testProvenance(),
          text: 'Anomalies detected in sensor data.',
          evidenceLinks: [
            const AnalysisEvidenceLink(uri: 'factgraph://anomalies/1'),
            const AnalysisEvidenceLink(
              uri: 'factgraph://anomalies/2',
              query: 'threshold > 3.0',
            ),
          ],
        );
        expect(artifact.evidenceLinks.length, equals(2));
      });

      test('serialization round-trip', () {
        final original = AnalysisSummaryArtifact(
          artifactId: 'art-sum-rt',
          name: 'summary_rt',
          provenance: testProvenance(),
          text: 'Round-trip test summary.',
          evidenceLinks: [
            AnalysisEvidenceLink(
              uri: 'factgraph://test',
              dataRange: AnalysisTimeRange(
                start: DateTime.utc(2025, 1, 1),
                end: DateTime.utc(2025, 12, 31),
              ),
            ),
          ],
        );
        final json = original.toJson();
        final restored = AnalysisSummaryArtifact.fromJson(json);
        expect(restored.artifactId, equals('art-sum-rt'));
        expect(restored.text, equals('Round-trip test summary.'));
        expect(restored.evidenceLinks.length, equals(1));
        expect(
          restored.evidenceLinks[0].uri,
          equals('factgraph://test'),
        );
      });

      test('toJson omits empty evidence links', () {
        final artifact = AnalysisSummaryArtifact(
          artifactId: 'art-sum-empty',
          name: 'empty_links',
          provenance: testProvenance(),
          text: 'No evidence.',
        );
        final json = artifact.toJson();
        expect(json.containsKey('evidenceLinks'), isFalse);
      });
    });

    group('AnalysisAlertRuleArtifact', () {
      test('creates with correct type', () {
        final artifact = AnalysisAlertRuleArtifact(
          artifactId: 'art-alert-1',
          name: 'high_temp_alert',
          provenance: testProvenance(),
          condition: 'temperature > 80',
          severity: AnalysisAlertSeverity.critical,
        );
        expect(artifact.type, equals(AnalysisArtifactType.alert));
        expect(artifact.condition, equals('temperature > 80'));
        expect(artifact.severity, equals(AnalysisAlertSeverity.critical));
        expect(artifact.actionHook, isNull);
      });

      test('creates with actionHook', () {
        final artifact = AnalysisAlertRuleArtifact(
          artifactId: 'art-alert-2',
          name: 'webhook_alert',
          provenance: testProvenance(),
          condition: 'pressure < 900',
          severity: AnalysisAlertSeverity.warn,
          actionHook: 'https://hooks.example.com/alert',
        );
        expect(
          artifact.actionHook,
          equals('https://hooks.example.com/alert'),
        );
      });

      test('serialization round-trip', () {
        final original = AnalysisAlertRuleArtifact(
          artifactId: 'art-ar-rt',
          name: 'alert_rt',
          provenance: testProvenance(),
          condition: 'humidity > 90',
          severity: AnalysisAlertSeverity.warn,
          actionHook: 'https://example.com/hook',
        );
        final json = original.toJson();
        final restored = AnalysisAlertRuleArtifact.fromJson(json);
        expect(restored.artifactId, equals('art-ar-rt'));
        expect(restored.condition, equals('humidity > 90'));
        expect(restored.severity, equals(AnalysisAlertSeverity.warn));
        expect(
          restored.actionHook,
          equals('https://example.com/hook'),
        );
      });

      test('toJson omits null actionHook', () {
        final artifact = AnalysisAlertRuleArtifact(
          artifactId: 'art-ar-no-hook',
          name: 'no_hook',
          provenance: testProvenance(),
          condition: 'x > 0',
          severity: AnalysisAlertSeverity.info,
        );
        final json = artifact.toJson();
        expect(json.containsKey('actionHook'), isFalse);
      });
    });

    group('AnalysisModelArtifact', () {
      test('creates with correct type', () {
        final artifact = AnalysisModelArtifact(
          artifactId: 'art-model-1',
          name: 'regression_model',
          provenance: testProvenance(),
          parameters: {'slope': 1.5, 'intercept': 0.3},
          modelVersion: '1.0.0',
          performanceMetrics: {'rmse': 0.05, 'r2': 0.98},
        );
        expect(artifact.type, equals(AnalysisArtifactType.model));
        expect(artifact.parameters['slope'], equals(1.5));
        expect(artifact.modelVersion, equals('1.0.0'));
        expect(artifact.performanceMetrics['r2'], equals(0.98));
      });

      test('serialization round-trip', () {
        final original = AnalysisModelArtifact(
          artifactId: 'art-mod-rt',
          name: 'model_rt',
          provenance: testProvenance(),
          parameters: {'alpha': 0.01},
          modelVersion: '2.1.0',
          performanceMetrics: {'accuracy': 0.95},
        );
        final json = original.toJson();
        final restored = AnalysisModelArtifact.fromJson(json);
        expect(restored.artifactId, equals('art-mod-rt'));
        expect(restored.parameters['alpha'], equals(0.01));
        expect(restored.modelVersion, equals('2.1.0'));
        expect(restored.performanceMetrics['accuracy'], equals(0.95));
      });

      test('fromJson defaults empty parameters and metrics', () {
        final json = {
          'artifactId': 'art-mod-defaults',
          'type': 'model',
          'name': 'default_model',
          'provenance': {
            'version': '1.0.0',
            'createdAt': '2025-06-15T00:00:00.000Z',
            'specId': 'spec-x',
            'specVersion': '1.0.0',
          },
          'modelVersion': '1.0.0',
        };
        final restored = AnalysisModelArtifact.fromJson(json);
        expect(restored.parameters, isEmpty);
        expect(restored.performanceMetrics, isEmpty);
      });
    });

    // ---- AnalysisArtifact.fromJson dispatching -----------------------------
    group('AnalysisArtifact.fromJson dispatch', () {
      Map<String, dynamic> baseJson(String type) => {
            'artifactId': 'art-dispatch-$type',
            'type': type,
            'name': 'dispatch_$type',
            'provenance': {
              'version': '1.0.0',
              'createdAt': '2025-06-15T00:00:00.000Z',
              'specId': 'spec-dispatch',
              'specVersion': '1.0.0',
            },
          };

      test('dispatches to AnalysisMetricArtifact for type=metric', () {
        final json = {
          ...baseJson('metric'),
          'value': 42.0,
          'unit': 'count',
          'timeRange': {
            'start': '2025-01-01T00:00:00.000Z',
            'end': '2025-12-31T00:00:00.000Z',
          },
        };
        final artifact = AnalysisArtifact.fromJson(json);
        expect(artifact, isA<AnalysisMetricArtifact>());
        expect(artifact.type, equals(AnalysisArtifactType.metric));
        final metric = artifact as AnalysisMetricArtifact;
        expect(metric.value, equals(42.0));
        expect(metric.unit, equals('count'));
      });

      test('dispatches to AnalysisSeriesArtifact for type=series', () {
        final json = {
          ...baseJson('series'),
          'points': [
            {'t': '2025-06-01T00:00:00.000Z', 'v': 10.0},
            {'t': '2025-06-02T00:00:00.000Z', 'v': 20.0},
          ],
          'unit': 'kg',
        };
        final artifact = AnalysisArtifact.fromJson(json);
        expect(artifact, isA<AnalysisSeriesArtifact>());
        expect(artifact.type, equals(AnalysisArtifactType.series));
        final series = artifact as AnalysisSeriesArtifact;
        expect(series.points.length, equals(2));
      });

      test('dispatches to AnalysisTableArtifact for type=table', () {
        final json = {
          ...baseJson('table'),
          'columns': ['a', 'b'],
          'rows': [
            {'a': 1, 'b': 2},
          ],
        };
        final artifact = AnalysisArtifact.fromJson(json);
        expect(artifact, isA<AnalysisTableArtifact>());
        expect(artifact.type, equals(AnalysisArtifactType.table));
        final table = artifact as AnalysisTableArtifact;
        expect(table.columns, equals(['a', 'b']));
        expect(table.rows.length, equals(1));
      });

      test('dispatches to AnalysisChartArtifact for type=chart', () {
        final json = {
          ...baseJson('chart'),
          'series': <Map<String, dynamic>>[],
          'xAxis': {'label': 'X', 'type': 'time'},
          'yAxis': {'label': 'Y', 'type': 'linear'},
        };
        final artifact = AnalysisArtifact.fromJson(json);
        expect(artifact, isA<AnalysisChartArtifact>());
        expect(artifact.type, equals(AnalysisArtifactType.chart));
      });

      test('dispatches to AnalysisSummaryArtifact for type=summary', () {
        final json = {
          ...baseJson('summary'),
          'text': 'Summary text here.',
        };
        final artifact = AnalysisArtifact.fromJson(json);
        expect(artifact, isA<AnalysisSummaryArtifact>());
        expect(artifact.type, equals(AnalysisArtifactType.summary));
        final summary = artifact as AnalysisSummaryArtifact;
        expect(summary.text, equals('Summary text here.'));
      });

      test('dispatches to AnalysisAlertRuleArtifact for type=alert', () {
        final json = {
          ...baseJson('alert'),
          'condition': 'temp > 100',
          'severity': 'critical',
        };
        final artifact = AnalysisArtifact.fromJson(json);
        expect(artifact, isA<AnalysisAlertRuleArtifact>());
        expect(artifact.type, equals(AnalysisArtifactType.alert));
        final alert = artifact as AnalysisAlertRuleArtifact;
        expect(alert.condition, equals('temp > 100'));
        expect(alert.severity, equals(AnalysisAlertSeverity.critical));
      });

      test('dispatches to AnalysisModelArtifact for type=model', () {
        final json = {
          ...baseJson('model'),
          'parameters': {'weight': 0.5},
          'modelVersion': '1.0.0',
          'performanceMetrics': {'accuracy': 0.9},
        };
        final artifact = AnalysisArtifact.fromJson(json);
        expect(artifact, isA<AnalysisModelArtifact>());
        expect(artifact.type, equals(AnalysisArtifactType.model));
        final model = artifact as AnalysisModelArtifact;
        expect(model.modelVersion, equals('1.0.0'));
      });
    });

    // ---- AnalysisAlert -----------------------------------------------------
    group('AnalysisAlert', () {
      test('creates with required fields', () {
        final alert = AnalysisAlert(
          alertRuleId: 'rule-001',
          severity: AnalysisAlertSeverity.warn,
          timestamp: DateTime.utc(2025, 6, 15),
          condition: 'temperature > 50',
          currentValue: 55,
          triggered: true,
        );
        expect(alert.alertRuleId, equals('rule-001'));
        expect(alert.severity, equals(AnalysisAlertSeverity.warn));
        expect(alert.condition, equals('temperature > 50'));
        expect(alert.currentValue, equals(55));
        expect(alert.triggered, isTrue);
        expect(alert.actionHook, isNull);
      });

      test('creates with actionHook', () {
        final alert = AnalysisAlert(
          alertRuleId: 'rule-002',
          severity: AnalysisAlertSeverity.critical,
          timestamp: DateTime.utc(2025, 6, 15),
          condition: 'pressure < 900',
          currentValue: 850,
          triggered: true,
          actionHook: 'https://hooks.example.com/notify',
        );
        expect(
          alert.actionHook,
          equals('https://hooks.example.com/notify'),
        );
      });

      test('serialization round-trip', () {
        final original = AnalysisAlert(
          alertRuleId: 'rule-rt',
          severity: AnalysisAlertSeverity.info,
          timestamp: DateTime.utc(2025, 7, 1, 8, 0),
          condition: 'count > 10',
          currentValue: 5,
          triggered: false,
          actionHook: 'https://example.com/hook',
        );
        final json = original.toJson();
        final restored = AnalysisAlert.fromJson(json);
        expect(restored.alertRuleId, equals('rule-rt'));
        expect(restored.severity, equals(AnalysisAlertSeverity.info));
        expect(
          restored.timestamp,
          equals(DateTime.utc(2025, 7, 1, 8, 0)),
        );
        expect(restored.condition, equals('count > 10'));
        expect(restored.currentValue, equals(5));
        expect(restored.triggered, isFalse);
        expect(restored.actionHook, equals('https://example.com/hook'));
      });

      test('toJson omits null actionHook', () {
        final alert = AnalysisAlert(
          alertRuleId: 'rule-x',
          severity: AnalysisAlertSeverity.info,
          timestamp: DateTime.utc(2025, 1, 1),
          condition: 'x > 0',
          currentValue: 1,
          triggered: true,
        );
        final json = alert.toJson();
        expect(json.containsKey('actionHook'), isFalse);
      });
    });

    // ---- StubAnalysisPort --------------------------------------------------
    group('StubAnalysisPort', () {
      late StubAnalysisPort port;

      setUp(() {
        port = StubAnalysisPort();
      });

      tearDown(() {
        port.clear();
      });

      test('listSpecs returns empty list initially', () async {
        final specs = await port.listSpecs();
        expect(specs, isEmpty);
      });

      test('createSpec adds spec and listSpecs returns it', () async {
        final spec = AnalysisSpec(
          specId: 'spec-001',
          version: '1.0.0',
          inputSources: [
            AnalysisInputSource(
              sourceType: AnalysisSourceType.factgraph,
            ),
          ],
          analysisSteps: [
            AnalysisStep(function: 'count', parameters: {}),
          ],
          outputs: [
            AnalysisOutputDef(
              type: AnalysisArtifactType.metric,
              name: 'count',
            ),
          ],
          metadata: const AnalysisSpecMetadata(
            description: 'Test spec',
          ),
        );
        final created = await port.createSpec(spec);
        expect(created.specId, equals('spec-001'));

        final specs = await port.listSpecs();
        expect(specs.length, equals(1));
        expect(specs[0].specId, equals('spec-001'));
      });

      test('listSpecs supports search filter', () async {
        await port.createSpec(AnalysisSpec(
          specId: 'temperature-analysis',
          version: '1.0.0',
          inputSources: [
            AnalysisInputSource(sourceType: AnalysisSourceType.factgraph),
          ],
          analysisSteps: [
            AnalysisStep(function: 'stats', parameters: {}),
          ],
          outputs: [
            AnalysisOutputDef(
              type: AnalysisArtifactType.metric,
              name: 'avg',
            ),
          ],
          metadata: const AnalysisSpecMetadata(
            description: 'Temperature metrics',
          ),
        ));
        await port.createSpec(AnalysisSpec(
          specId: 'pressure-analysis',
          version: '1.0.0',
          inputSources: [
            AnalysisInputSource(sourceType: AnalysisSourceType.mcpIo),
          ],
          analysisSteps: [
            AnalysisStep(function: 'stats', parameters: {}),
          ],
          outputs: [
            AnalysisOutputDef(
              type: AnalysisArtifactType.metric,
              name: 'max',
            ),
          ],
          metadata: const AnalysisSpecMetadata(
            description: 'Pressure metrics',
          ),
        ));

        final tempResults = await port.listSpecs(search: 'temperature');
        expect(tempResults.length, equals(1));
        expect(tempResults[0].specId, equals('temperature-analysis'));

        final allResults = await port.listSpecs();
        expect(allResults.length, equals(2));
      });

      test('listSpecs supports limit and offset', () async {
        for (int i = 0; i < 5; i++) {
          await port.createSpec(AnalysisSpec(
            specId: 'spec-$i',
            version: '1.0.0',
            inputSources: [
              AnalysisInputSource(
                sourceType: AnalysisSourceType.factgraph,
              ),
            ],
            analysisSteps: [
              AnalysisStep(function: 'noop', parameters: {}),
            ],
            outputs: [
              AnalysisOutputDef(
                type: AnalysisArtifactType.metric,
                name: 'out',
              ),
            ],
            metadata: const AnalysisSpecMetadata(),
          ));
        }

        final limited = await port.listSpecs(limit: 2);
        expect(limited.length, equals(2));

        final offsetResults = await port.listSpecs(offset: 3);
        expect(offsetResults.length, equals(2));

        final limitedOffset = await port.listSpecs(offset: 1, limit: 2);
        expect(limitedOffset.length, equals(2));
        expect(limitedOffset[0].specId, equals('spec-1'));
        expect(limitedOffset[1].specId, equals('spec-2'));
      });

      test('updateSpec replaces existing spec', () async {
        final original = AnalysisSpec(
          specId: 'spec-update',
          version: '1.0.0',
          inputSources: [
            AnalysisInputSource(sourceType: AnalysisSourceType.factgraph),
          ],
          analysisSteps: [
            AnalysisStep(function: 'v1', parameters: {}),
          ],
          outputs: [
            AnalysisOutputDef(
              type: AnalysisArtifactType.metric,
              name: 'out',
            ),
          ],
          metadata: const AnalysisSpecMetadata(),
        );
        await port.createSpec(original);

        final updated = AnalysisSpec(
          specId: 'spec-update',
          version: '2.0.0',
          inputSources: [
            AnalysisInputSource(sourceType: AnalysisSourceType.mcpIo),
          ],
          analysisSteps: [
            AnalysisStep(function: 'v2', parameters: {}),
          ],
          outputs: [
            AnalysisOutputDef(
              type: AnalysisArtifactType.summary,
              name: 'summary',
            ),
          ],
          metadata: const AnalysisSpecMetadata(),
        );
        await port.updateSpec('spec-update', updated);

        final specs = await port.listSpecs();
        expect(specs.length, equals(1));
        expect(specs[0].version, equals('2.0.0'));
        expect(specs[0].analysisSteps[0].function, equals('v2'));
      });

      test('updateSpec adds spec if not found', () async {
        final spec = AnalysisSpec(
          specId: 'spec-new',
          version: '1.0.0',
          inputSources: [
            AnalysisInputSource(sourceType: AnalysisSourceType.upload),
          ],
          analysisSteps: [
            AnalysisStep(function: 'noop', parameters: {}),
          ],
          outputs: [
            AnalysisOutputDef(
              type: AnalysisArtifactType.metric,
              name: 'x',
            ),
          ],
          metadata: const AnalysisSpecMetadata(),
        );
        await port.updateSpec('spec-new', spec);

        final specs = await port.listSpecs();
        expect(specs.length, equals(1));
        expect(specs[0].specId, equals('spec-new'));
      });

      test('runAnalysis creates a completed job', () async {
        final job = await port.runAnalysis(
          specId: 'spec-001',
          parameters: {'param1': 'value1'},
        );
        expect(job.jobId, equals('job_0'));
        expect(job.specId, equals('spec-001'));
        expect(job.specVersion, equals('1.0.0'));
        expect(job.mode, equals(AnalysisExecutionMode.batch));
        expect(job.status, equals(AnalysisJobStatus.completed));
        expect(job.progress, equals(1.0));
        expect(job.parameters['param1'], equals('value1'));
      });

      test('runAnalysis with custom mode and timeRange', () async {
        final timeRange = AnalysisTimeRange(
          start: DateTime.utc(2025, 1, 1),
          end: DateTime.utc(2025, 6, 30),
        );
        final job = await port.runAnalysis(
          specId: 'spec-002',
          parameters: {},
          mode: AnalysisExecutionMode.streaming,
          timeRange: timeRange,
        );
        expect(job.mode, equals(AnalysisExecutionMode.streaming));
        expect(job.inputRange, isNotNull);
        expect(
          job.inputRange!.start,
          equals(DateTime.utc(2025, 1, 1)),
        );
      });

      test('runAnalysis increments job IDs', () async {
        final job0 = await port.runAnalysis(
          specId: 'spec-a',
          parameters: {},
        );
        final job1 = await port.runAnalysis(
          specId: 'spec-b',
          parameters: {},
        );
        expect(job0.jobId, equals('job_0'));
        expect(job1.jobId, equals('job_1'));
      });

      test('getJob returns job by ID', () async {
        final job = await port.runAnalysis(
          specId: 'spec-001',
          parameters: {},
        );
        final retrieved = await port.getJob(job.jobId);
        expect(retrieved, isNotNull);
        expect(retrieved!.jobId, equals(job.jobId));
        expect(retrieved.specId, equals('spec-001'));
      });

      test('getJob returns null for unknown ID', () async {
        final result = await port.getJob('nonexistent');
        expect(result, isNull);
      });

      test('getArtifacts returns empty list', () async {
        final artifacts = await port.getArtifacts();
        expect(artifacts, isEmpty);
      });

      test('getArtifacts returns empty list with filters', () async {
        final artifacts = await port.getArtifacts(
          jobId: 'job-1',
          specId: 'spec-1',
          type: AnalysisArtifactType.metric,
          tags: ['test'],
          limit: 10,
        );
        expect(artifacts, isEmpty);
      });

      test('evaluateAlert returns non-triggered alert', () async {
        final alert = await port.evaluateAlert('rule-123');
        expect(alert.alertRuleId, equals('rule-123'));
        expect(alert.severity, equals(AnalysisAlertSeverity.info));
        expect(alert.condition, equals('stub_condition'));
        expect(alert.currentValue, equals(0));
        expect(alert.triggered, isFalse);
      });

      test('clear resets all stored data', () async {
        await port.createSpec(AnalysisSpec(
          specId: 'spec-clear',
          version: '1.0.0',
          inputSources: [
            AnalysisInputSource(sourceType: AnalysisSourceType.upload),
          ],
          analysisSteps: [
            AnalysisStep(function: 'noop', parameters: {}),
          ],
          outputs: [
            AnalysisOutputDef(
              type: AnalysisArtifactType.metric,
              name: 'x',
            ),
          ],
          metadata: const AnalysisSpecMetadata(),
        ));
        await port.runAnalysis(specId: 'spec-clear', parameters: {});

        port.clear();

        final specs = await port.listSpecs();
        expect(specs, isEmpty);
        final job = await port.getJob('job_0');
        expect(job, isNull);
      });
    });
  });

  // ==========================================================================
  // AnalysisDataSourcePort
  // ==========================================================================
  group('AnalysisDataSourcePort', () {
    group('AnalysisDataSet', () {
      test('creates with required fields', () {
        final dataSet = AnalysisDataSet(
          columns: [
            const AnalysisColumnInfo(name: 'temp', type: 'double'),
          ],
          rows: [
            {'temp': 23.5},
          ],
          rowCount: 1,
        );
        expect(dataSet.columns.length, equals(1));
        expect(dataSet.rows.length, equals(1));
        expect(dataSet.rowCount, equals(1));
        expect(dataSet.timeRange, isNull);
        expect(dataSet.metadata, isNull);
      });

      test('creates with all optional fields', () {
        final dataSet = AnalysisDataSet(
          columns: [
            const AnalysisColumnInfo(name: 'ts', type: 'datetime'),
            const AnalysisColumnInfo(name: 'value', type: 'double'),
          ],
          rows: [
            {'ts': '2025-06-01', 'value': 10.0},
            {'ts': '2025-06-02', 'value': 20.0},
          ],
          rowCount: 2,
          timeRange: AnalysisTimeRange(
            start: DateTime.utc(2025, 6, 1),
            end: DateTime.utc(2025, 6, 2),
          ),
          metadata: {'source': 'sensor_a'},
        );
        expect(dataSet.timeRange, isNotNull);
        expect(dataSet.metadata!['source'], equals('sensor_a'));
      });

      test('serialization round-trip', () {
        final original = AnalysisDataSet(
          columns: [
            const AnalysisColumnInfo(
              name: 'pressure',
              type: 'double',
              unit: 'hPa',
            ),
          ],
          rows: [
            {'pressure': 1013.25},
          ],
          rowCount: 1,
          timeRange: AnalysisTimeRange(
            start: DateTime.utc(2025, 3, 1),
            end: DateTime.utc(2025, 3, 31),
          ),
          metadata: {'region': 'north'},
        );
        final json = original.toJson();
        final restored = AnalysisDataSet.fromJson(json);
        expect(restored.columns.length, equals(1));
        expect(restored.columns[0].name, equals('pressure'));
        expect(restored.columns[0].unit, equals('hPa'));
        expect(restored.rows.length, equals(1));
        expect(restored.rows[0]['pressure'], equals(1013.25));
        expect(restored.rowCount, equals(1));
        expect(
          restored.timeRange!.start,
          equals(DateTime.utc(2025, 3, 1)),
        );
        expect(restored.metadata!['region'], equals('north'));
      });

      test('fromJson handles missing optional fields', () {
        final restored = AnalysisDataSet.fromJson(<String, dynamic>{});
        expect(restored.columns, isEmpty);
        expect(restored.rows, isEmpty);
        expect(restored.rowCount, equals(0));
        expect(restored.timeRange, isNull);
        expect(restored.metadata, isNull);
      });

      test('toJson omits null timeRange and metadata', () {
        final dataSet = AnalysisDataSet(
          columns: [],
          rows: [],
          rowCount: 0,
        );
        final json = dataSet.toJson();
        expect(json.containsKey('timeRange'), isFalse);
        expect(json.containsKey('metadata'), isFalse);
      });
    });

    group('StubAnalysisDataSourcePort', () {
      late StubAnalysisDataSourcePort port;

      setUp(() {
        port = StubAnalysisDataSourcePort();
      });

      test('queryData returns empty data set', () async {
        final result = await port.queryData(
          sourceType: AnalysisSourceType.factgraph,
          query: 'SELECT * FROM data',
        );
        expect(result.columns, isEmpty);
        expect(result.rows, isEmpty);
        expect(result.rowCount, equals(0));
      });

      test('queryData accepts optional filter and timeRange', () async {
        final result = await port.queryData(
          sourceType: AnalysisSourceType.mcpIo,
          query: 'test_query',
          filter: {'status': 'active'},
          timeRange: AnalysisTimeRange(
            start: DateTime.utc(2025, 1, 1),
            end: DateTime.utc(2025, 12, 31),
          ),
        );
        expect(result.columns, isEmpty);
        expect(result.rowCount, equals(0));
      });

      test('getSourceMetadata returns empty schema', () async {
        final schema = await port.getSourceMetadata(
          sourceType: AnalysisSourceType.external,
          query: 'sensor_data',
        );
        expect(schema.columns, isEmpty);
        expect(schema.timestampField, isNull);
      });

      test('isAvailable returns true for all source types', () async {
        for (final sourceType in AnalysisSourceType.values) {
          final result = await port.isAvailable(sourceType);
          expect(result, isTrue);
        }
      });
    });
  });

  // ==========================================================================
  // AnalysisFunctionPort
  // ==========================================================================
  group('AnalysisFunctionPort', () {
    group('AnalysisFunctionInfo', () {
      test('creates with defaults', () {
        final info = AnalysisFunctionInfo(
          functionName: 'descriptive_stats',
          description: 'Compute descriptive statistics',
        );
        expect(info.functionName, equals('descriptive_stats'));
        expect(info.description, equals('Compute descriptive statistics'));
        expect(info.parameters, isEmpty);
        expect(info.supportedDataTypes, isEmpty);
        expect(info.plugin, isNull);
        expect(info.specVersionRange, isNull);
      });

      test('creates with all fields', () {
        final info = AnalysisFunctionInfo(
          functionName: 'anomaly_detect',
          description: 'Detect anomalies',
          parameters: {
            'threshold': AnalysisParameterSchema(
              name: 'threshold',
              type: 'double',
              defaultValue: 3.0,
              description: 'Z-score threshold',
              min: 0,
              max: 10,
            ),
          },
          supportedDataTypes: ['numeric', 'temporal'],
          plugin: 'advanced-analytics',
          specVersionRange: '>=1.0.0 <2.0.0',
        );
        expect(info.parameters.length, equals(1));
        expect(info.parameters['threshold']!.name, equals('threshold'));
        expect(info.supportedDataTypes, equals(['numeric', 'temporal']));
        expect(info.plugin, equals('advanced-analytics'));
        expect(info.specVersionRange, equals('>=1.0.0 <2.0.0'));
      });

      test('serialization round-trip', () {
        final original = AnalysisFunctionInfo(
          functionName: 'correlation',
          description: 'Compute correlation coefficient',
          parameters: {
            'method': AnalysisParameterSchema(
              name: 'method',
              type: 'string',
              defaultValue: 'pearson',
              description: 'Correlation method',
            ),
          },
          supportedDataTypes: ['numeric'],
          plugin: 'stats-plugin',
          specVersionRange: '>=1.0.0',
        );
        final json = original.toJson();
        final restored = AnalysisFunctionInfo.fromJson(json);
        expect(restored.functionName, equals('correlation'));
        expect(restored.description, equals('Compute correlation coefficient'));
        expect(restored.parameters.length, equals(1));
        expect(restored.parameters['method']!.type, equals('string'));
        expect(
          restored.parameters['method']!.defaultValue,
          equals('pearson'),
        );
        expect(restored.supportedDataTypes, equals(['numeric']));
        expect(restored.plugin, equals('stats-plugin'));
        expect(restored.specVersionRange, equals('>=1.0.0'));
      });

      test('toJson omits empty and null fields', () {
        final info = AnalysisFunctionInfo(
          functionName: 'noop',
          description: 'No operation',
        );
        final json = info.toJson();
        expect(json.containsKey('parameters'), isFalse);
        expect(json.containsKey('supportedDataTypes'), isFalse);
        expect(json.containsKey('plugin'), isFalse);
        expect(json.containsKey('specVersionRange'), isFalse);
      });

      test('fromJson handles missing optional fields', () {
        final restored = AnalysisFunctionInfo.fromJson(<String, dynamic>{});
        expect(restored.functionName, isEmpty);
        expect(restored.description, isEmpty);
        expect(restored.parameters, isEmpty);
        expect(restored.supportedDataTypes, isEmpty);
        expect(restored.plugin, isNull);
        expect(restored.specVersionRange, isNull);
      });
    });

    group('AnalysisParameterSchema', () {
      test('creates with required fields', () {
        final schema = AnalysisParameterSchema(
          name: 'threshold',
          type: 'double',
        );
        expect(schema.name, equals('threshold'));
        expect(schema.type, equals('double'));
        expect(schema.defaultValue, isNull);
        expect(schema.description, isNull);
        expect(schema.min, isNull);
        expect(schema.max, isNull);
      });

      test('creates with all optional fields', () {
        final schema = AnalysisParameterSchema(
          name: 'window_size',
          type: 'int',
          defaultValue: 10,
          description: 'Sliding window size',
          min: 1,
          max: 1000,
        );
        expect(schema.defaultValue, equals(10));
        expect(schema.description, equals('Sliding window size'));
        expect(schema.min, equals(1));
        expect(schema.max, equals(1000));
      });

      test('serialization round-trip', () {
        final original = AnalysisParameterSchema(
          name: 'alpha',
          type: 'double',
          defaultValue: 0.05,
          description: 'Significance level',
          min: 0.0,
          max: 1.0,
        );
        final json = original.toJson();
        final restored = AnalysisParameterSchema.fromJson(json);
        expect(restored.name, equals('alpha'));
        expect(restored.type, equals('double'));
        expect(restored.defaultValue, equals(0.05));
        expect(restored.description, equals('Significance level'));
        expect(restored.min, equals(0.0));
        expect(restored.max, equals(1.0));
      });

      test('toJson omits null fields', () {
        final schema = AnalysisParameterSchema(
          name: 'x',
          type: 'string',
        );
        final json = schema.toJson();
        expect(json.containsKey('defaultValue'), isFalse);
        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('min'), isFalse);
        expect(json.containsKey('max'), isFalse);
      });

      test('fromJson defaults name and type', () {
        final restored = AnalysisParameterSchema.fromJson(
          <String, dynamic>{},
        );
        expect(restored.name, isEmpty);
        expect(restored.type, equals('string'));
      });
    });

    group('AnalysisFunctionResult', () {
      test('creates with required fields', () {
        final result = AnalysisFunctionResult(
          functionName: 'descriptive_stats',
          results: {'mean': 23.5, 'std': 2.1},
          executionTime: const Duration(milliseconds: 150),
        );
        expect(result.functionName, equals('descriptive_stats'));
        expect(result.results['mean'], equals(23.5));
        expect(result.executionTime.inMilliseconds, equals(150));
        expect(result.metadata, isNull);
      });

      test('creates with metadata', () {
        final result = AnalysisFunctionResult(
          functionName: 'anomaly_detect',
          results: {'anomalies': 3},
          executionTime: const Duration(seconds: 2),
          metadata: {'method': 'zscore'},
        );
        expect(result.metadata!['method'], equals('zscore'));
      });

      test('serialization round-trip', () {
        final original = AnalysisFunctionResult(
          functionName: 'correlation',
          results: {'r': 0.95, 'p_value': 0.001},
          executionTime: const Duration(milliseconds: 500),
          metadata: {'pairs': 100},
        );
        final json = original.toJson();
        final restored = AnalysisFunctionResult.fromJson(json);
        expect(restored.functionName, equals('correlation'));
        expect(restored.results['r'], equals(0.95));
        expect(restored.results['p_value'], equals(0.001));
        expect(restored.executionTime.inMilliseconds, equals(500));
        expect(restored.metadata!['pairs'], equals(100));
      });

      test('toJson omits null metadata', () {
        final result = AnalysisFunctionResult(
          functionName: 'test',
          results: {},
          executionTime: Duration.zero,
        );
        final json = result.toJson();
        expect(json.containsKey('metadata'), isFalse);
      });

      test('fromJson handles missing optional fields', () {
        final restored = AnalysisFunctionResult.fromJson(
          <String, dynamic>{},
        );
        expect(restored.functionName, isEmpty);
        expect(restored.results, isEmpty);
        expect(restored.executionTime, equals(Duration.zero));
        expect(restored.metadata, isNull);
      });
    });

    group('StubAnalysisFunctionPort', () {
      late StubAnalysisFunctionPort port;

      setUp(() {
        port = StubAnalysisFunctionPort();
      });

      tearDown(() {
        port.clear();
      });

      test('getFunctionCatalog returns empty list initially', () async {
        final catalog = await port.getFunctionCatalog();
        expect(catalog, isEmpty);
      });

      test('registerFunction adds function to catalog', () async {
        final funcInfo = AnalysisFunctionInfo(
          functionName: 'descriptive_stats',
          description: 'Compute descriptive statistics',
          supportedDataTypes: ['numeric'],
        );
        await port.registerFunction(funcInfo);

        final catalog = await port.getFunctionCatalog();
        expect(catalog.length, equals(1));
        expect(catalog[0].functionName, equals('descriptive_stats'));
        expect(catalog[0].description, equals('Compute descriptive statistics'));
      });

      test('registerFunction replaces existing function', () async {
        final v1 = AnalysisFunctionInfo(
          functionName: 'my_func',
          description: 'Version 1',
        );
        final v2 = AnalysisFunctionInfo(
          functionName: 'my_func',
          description: 'Version 2',
        );
        await port.registerFunction(v1);
        await port.registerFunction(v2);

        final catalog = await port.getFunctionCatalog();
        expect(catalog.length, equals(1));
        expect(catalog[0].description, equals('Version 2'));
      });

      test('registerFunction supports multiple functions', () async {
        await port.registerFunction(AnalysisFunctionInfo(
          functionName: 'func_a',
          description: 'Function A',
        ));
        await port.registerFunction(AnalysisFunctionInfo(
          functionName: 'func_b',
          description: 'Function B',
        ));

        final catalog = await port.getFunctionCatalog();
        expect(catalog.length, equals(2));
      });

      test('unregisterFunction removes function from catalog', () async {
        await port.registerFunction(AnalysisFunctionInfo(
          functionName: 'to_remove',
          description: 'Will be removed',
        ));
        await port.registerFunction(AnalysisFunctionInfo(
          functionName: 'to_keep',
          description: 'Will stay',
        ));

        await port.unregisterFunction('to_remove');

        final catalog = await port.getFunctionCatalog();
        expect(catalog.length, equals(1));
        expect(catalog[0].functionName, equals('to_keep'));
      });

      test('unregisterFunction is no-op for unknown function', () async {
        await port.registerFunction(AnalysisFunctionInfo(
          functionName: 'existing',
          description: 'Existing function',
        ));

        await port.unregisterFunction('nonexistent');

        final catalog = await port.getFunctionCatalog();
        expect(catalog.length, equals(1));
      });

      test('executeFunction returns empty result', () async {
        final dataSet = AnalysisDataSet(
          columns: [
            const AnalysisColumnInfo(name: 'value', type: 'double'),
          ],
          rows: [
            {'value': 10.0},
            {'value': 20.0},
          ],
          rowCount: 2,
        );

        final result = await port.executeFunction(
          functionName: 'descriptive_stats',
          parameters: {'columns': ['value']},
          data: dataSet,
        );
        expect(result.functionName, equals('descriptive_stats'));
        expect(result.results, isEmpty);
        expect(result.executionTime, equals(Duration.zero));
      });

      test('clear removes all registered functions', () async {
        await port.registerFunction(AnalysisFunctionInfo(
          functionName: 'func_1',
          description: 'Function 1',
        ));
        await port.registerFunction(AnalysisFunctionInfo(
          functionName: 'func_2',
          description: 'Function 2',
        ));

        port.clear();

        final catalog = await port.getFunctionCatalog();
        expect(catalog, isEmpty);
      });
    });
  });
}
