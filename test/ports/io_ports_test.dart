import 'package:test/test.dart';
import 'package:mcp_bundle/ports.dart';

void main() {
  // ==========================================================================
  // IoDevicePort
  // ==========================================================================
  group('IoDevicePort', () {
    // ---- Enums ----
    group('PayloadKind', () {
      test('fromString parses valid values', () {
        expect(PayloadKind.fromString('read'), equals(PayloadKind.read));
        expect(PayloadKind.fromString('stream'), equals(PayloadKind.stream));
        expect(PayloadKind.fromString('event'), equals(PayloadKind.event));
        expect(PayloadKind.fromString('commandResult'),
            equals(PayloadKind.commandResult));
        expect(
            PayloadKind.fromString('describe'), equals(PayloadKind.describe));
      });

      test('fromString returns default for unknown value', () {
        expect(PayloadKind.fromString('unknown'), equals(PayloadKind.read));
        expect(PayloadKind.fromString(''), equals(PayloadKind.read));
      });
    });

    group('PayloadType', () {
      test('fromString parses valid values', () {
        expect(PayloadType.fromString('scalar'), equals(PayloadType.scalar));
        expect(PayloadType.fromString('vector'), equals(PayloadType.vector));
        expect(
            PayloadType.fromString('waveform'), equals(PayloadType.waveform));
        expect(PayloadType.fromString('event'), equals(PayloadType.event));
        expect(PayloadType.fromString('struct_'), equals(PayloadType.struct_));
        expect(PayloadType.fromString('blob'), equals(PayloadType.blob));
        expect(PayloadType.fromString('null_'), equals(PayloadType.null_));
      });

      test('fromString returns default for unknown value', () {
        expect(PayloadType.fromString('invalid'), equals(PayloadType.scalar));
      });
    });

    group('Quality', () {
      test('fromString parses all values', () {
        expect(Quality.fromString('ok'), equals(Quality.ok));
        expect(Quality.fromString('stale'), equals(Quality.stale));
        expect(Quality.fromString('clipped'), equals(Quality.clipped));
        expect(Quality.fromString('saturated'), equals(Quality.saturated));
        expect(Quality.fromString('timeout'), equals(Quality.timeout));
        expect(Quality.fromString('error'), equals(Quality.error));
        expect(Quality.fromString('simulated'), equals(Quality.simulated));
        expect(Quality.fromString('unknown'), equals(Quality.unknown));
      });

      test('fromString returns default for unknown value', () {
        expect(Quality.fromString('bad'), equals(Quality.unknown));
      });
    });

    group('IoConnectionState', () {
      test('fromString parses all values', () {
        expect(IoConnectionState.fromString('connected'),
            equals(IoConnectionState.connected));
        expect(IoConnectionState.fromString('disconnected'),
            equals(IoConnectionState.disconnected));
        expect(IoConnectionState.fromString('error'),
            equals(IoConnectionState.error));
        expect(IoConnectionState.fromString('connecting'),
            equals(IoConnectionState.connecting));
      });

      test('fromString returns disconnected for unknown value', () {
        expect(IoConnectionState.fromString('invalid'),
            equals(IoConnectionState.disconnected));
      });
    });

    group('SafetyClass', () {
      test('fromString parses all values', () {
        expect(SafetyClass.fromString('safe'), equals(SafetyClass.safe));
        expect(
            SafetyClass.fromString('guarded'), equals(SafetyClass.guarded));
        expect(SafetyClass.fromString('dangerous'),
            equals(SafetyClass.dangerous));
      });

      test('fromString returns safe for unknown value', () {
        expect(SafetyClass.fromString('other'), equals(SafetyClass.safe));
      });
    });

    group('CommandStatus', () {
      test('fromString parses all values', () {
        expect(CommandStatus.fromString('pending'),
            equals(CommandStatus.pending));
        expect(CommandStatus.fromString('executing'),
            equals(CommandStatus.executing));
        expect(CommandStatus.fromString('completed'),
            equals(CommandStatus.completed));
        expect(
            CommandStatus.fromString('failed'), equals(CommandStatus.failed));
        expect(CommandStatus.fromString('rejected'),
            equals(CommandStatus.rejected));
        expect(CommandStatus.fromString('needsApproval'),
            equals(CommandStatus.needsApproval));
        expect(CommandStatus.fromString('planned'),
            equals(CommandStatus.planned));
      });

      test('fromString returns pending for unknown value', () {
        expect(
            CommandStatus.fromString('xyz'), equals(CommandStatus.pending));
      });
    });

    group('TopicMode', () {
      test('fromString parses all values', () {
        expect(TopicMode.fromString('continuous'),
            equals(TopicMode.continuous));
        expect(
            TopicMode.fromString('onChange'), equals(TopicMode.onChange));
        expect(TopicMode.fromString('poll'), equals(TopicMode.poll));
        expect(TopicMode.fromString('event'), equals(TopicMode.event));
      });

      test('fromString returns continuous for unknown value', () {
        expect(
            TopicMode.fromString('invalid'), equals(TopicMode.continuous));
      });
    });

    group('BackpressurePolicy', () {
      test('fromString parses all values', () {
        expect(BackpressurePolicy.fromString('dropOldest'),
            equals(BackpressurePolicy.dropOldest));
        expect(BackpressurePolicy.fromString('dropNewest'),
            equals(BackpressurePolicy.dropNewest));
        expect(BackpressurePolicy.fromString('block'),
            equals(BackpressurePolicy.block));
      });

      test('fromString returns dropOldest for unknown value', () {
        expect(BackpressurePolicy.fromString('other'),
            equals(BackpressurePolicy.dropOldest));
      });
    });

    group('TransportType', () {
      test('fromString parses all values', () {
        expect(TransportType.fromString('tcp'), equals(TransportType.tcp));
        expect(
            TransportType.fromString('serial'), equals(TransportType.serial));
        expect(TransportType.fromString('usb'), equals(TransportType.usb));
        expect(TransportType.fromString('ble'), equals(TransportType.ble));
        expect(TransportType.fromString('can'), equals(TransportType.can));
        expect(TransportType.fromString('mqtt'), equals(TransportType.mqtt));
        expect(TransportType.fromString('ros2'), equals(TransportType.ros2));
        expect(
            TransportType.fromString('custom'), equals(TransportType.custom));
      });

      test('fromString returns custom for unknown value', () {
        expect(
            TransportType.fromString('unknown'), equals(TransportType.custom));
      });
    });

    group('InterlockCondition', () {
      test('fromString parses all values', () {
        expect(InterlockCondition.fromString('equals'),
            equals(InterlockCondition.equals));
        expect(InterlockCondition.fromString('isTrue'),
            equals(InterlockCondition.isTrue));
        expect(InterlockCondition.fromString('isFalse'),
            equals(InterlockCondition.isFalse));
        expect(InterlockCondition.fromString('greaterThan'),
            equals(InterlockCondition.greaterThan));
        expect(InterlockCondition.fromString('lessThan'),
            equals(InterlockCondition.lessThan));
      });

      test('fromString returns equals for unknown value', () {
        expect(InterlockCondition.fromString('nope'),
            equals(InterlockCondition.equals));
      });
    });

    group('InterlockAction', () {
      test('fromString parses all values', () {
        expect(InterlockAction.fromString('deny'),
            equals(InterlockAction.deny));
        expect(InterlockAction.fromString('warn'),
            equals(InterlockAction.warn));
      });

      test('fromString returns deny for unknown value', () {
        expect(InterlockAction.fromString('other'),
            equals(InterlockAction.deny));
      });
    });

    group('Decision', () {
      test('fromString parses all values', () {
        expect(Decision.fromString('allow'), equals(Decision.allow));
        expect(Decision.fromString('deny'), equals(Decision.deny));
        expect(Decision.fromString('needsApproval'),
            equals(Decision.needsApproval));
        expect(
            Decision.fromString('needsPlan'), equals(Decision.needsPlan));
      });

      test('fromString returns deny for unknown value', () {
        expect(Decision.fromString('invalid'), equals(Decision.deny));
      });
    });

    // ---- Data classes serialization ----
    group('PayloadSource', () {
      test('creates with required and optional fields', () {
        const source = PayloadSource(adapterId: 'adapter-1');
        expect(source.adapterId, equals('adapter-1'));
        expect(source.firmware, isNull);
        expect(source.sampleRate, isNull);
      });

      test('serializes and deserializes round-trip', () {
        const source = PayloadSource(
          adapterId: 'adapter-1',
          firmware: 'v2.1',
          sampleRate: 44100.0,
        );
        final json = source.toJson();
        final restored = PayloadSource.fromJson(json);
        expect(restored.adapterId, equals('adapter-1'));
        expect(restored.firmware, equals('v2.1'));
        expect(restored.sampleRate, equals(44100.0));
      });

      test('toJson omits null optional fields', () {
        const source = PayloadSource(adapterId: 'a');
        final json = source.toJson();
        expect(json.containsKey('firmware'), isFalse);
        expect(json.containsKey('sampleRate'), isFalse);
      });
    });

    group('TypedPayload', () {
      test('creates with defaults', () {
        final ts = DateTime.utc(2025, 6, 1);
        final payload = TypedPayload(
          type: PayloadType.scalar,
          value: 42.0,
          timestamp: ts,
        );
        expect(payload.quality, equals(Quality.ok));
        expect(payload.unit, isNull);
        expect(payload.source, isNull);
      });

      test('serializes and deserializes round-trip', () {
        final ts = DateTime.utc(2025, 6, 1, 12, 0, 0);
        final payload = TypedPayload(
          type: PayloadType.vector,
          value: [1.0, 2.0, 3.0],
          unit: 'rpm',
          timestamp: ts,
          quality: Quality.stale,
          source: const PayloadSource(adapterId: 'src-1'),
        );
        final json = payload.toJson();
        final restored = TypedPayload.fromJson(json);
        expect(restored.type, equals(PayloadType.vector));
        expect(restored.unit, equals('rpm'));
        expect(restored.quality, equals(Quality.stale));
        expect(restored.source?.adapterId, equals('src-1'));
        expect(restored.timestamp, equals(ts));
      });
    });

    group('ChunkMeta', () {
      test('serializes and deserializes round-trip', () {
        const chunk = ChunkMeta(index: 0, total: 5, groupId: 'grp-1');
        final json = chunk.toJson();
        final restored = ChunkMeta.fromJson(json);
        expect(restored.index, equals(0));
        expect(restored.total, equals(5));
        expect(restored.groupId, equals('grp-1'));
      });
    });

    group('EnvelopeMeta', () {
      test('serializes and deserializes without optional fields', () {
        final meta = EnvelopeMeta(
          capturedAt: DateTime.utc(2025, 6, 1),
          sourceAddress: '192.168.1.1',
        );
        final json = meta.toJson();
        final restored = EnvelopeMeta.fromJson(json);
        expect(restored.sourceAddress, equals('192.168.1.1'));
        expect(restored.sequenceNumber, isNull);
        expect(restored.chunk, isNull);
      });

      test('serializes and deserializes with chunk', () {
        final meta = EnvelopeMeta(
          capturedAt: DateTime.utc(2025, 6, 1),
          sourceAddress: 'addr-1',
          sequenceNumber: 42,
          chunk: const ChunkMeta(index: 1, total: 3, groupId: 'g-1'),
        );
        final json = meta.toJson();
        final restored = EnvelopeMeta.fromJson(json);
        expect(restored.sequenceNumber, equals(42));
        expect(restored.chunk?.index, equals(1));
        expect(restored.chunk?.total, equals(3));
        expect(restored.chunk?.groupId, equals('g-1'));
      });
    });

    group('PayloadEnvelope', () {
      test('serializes and deserializes round-trip', () {
        final ts = DateTime.utc(2025, 6, 1, 10, 0, 0);
        final envelope = PayloadEnvelope(
          uri: 'io://device-1/ch/1/waveform',
          kind: PayloadKind.stream,
          payload: TypedPayload(
            type: PayloadType.waveform,
            value: [0.1, 0.2, 0.3],
            unit: 'V',
            timestamp: ts,
          ),
          meta: EnvelopeMeta(
            capturedAt: ts,
            sourceAddress: 'device-1',
          ),
        );
        final json = envelope.toJson();
        final restored = PayloadEnvelope.fromJson(json);
        expect(restored.uri, equals('io://device-1/ch/1/waveform'));
        expect(restored.kind, equals(PayloadKind.stream));
        expect(restored.payload.type, equals(PayloadType.waveform));
        expect(restored.payload.unit, equals('V'));
        expect(restored.meta.sourceAddress, equals('device-1'));
      });
    });

    group('ResourceDescriptor', () {
      test('creates with default values', () {
        const rd = ResourceDescriptor(
          id: 'r1',
          name: 'Temperature',
          uri: 'io://dev/ch/1/temp',
          payloadType: PayloadType.scalar,
        );
        expect(rd.readable, isTrue);
        expect(rd.writable, isFalse);
        expect(rd.subscribable, isFalse);
        expect(rd.unit, isNull);
      });

      test('serializes and deserializes round-trip', () {
        const rd = ResourceDescriptor(
          id: 'r1',
          name: 'Pressure',
          uri: 'io://dev/ch/1/pressure',
          payloadType: PayloadType.scalar,
          unit: 'Pa',
          readable: true,
          writable: true,
          subscribable: true,
        );
        final json = rd.toJson();
        final restored = ResourceDescriptor.fromJson(json);
        expect(restored.id, equals('r1'));
        expect(restored.name, equals('Pressure'));
        expect(restored.uri, equals('io://dev/ch/1/pressure'));
        expect(restored.payloadType, equals(PayloadType.scalar));
        expect(restored.unit, equals('Pa'));
        expect(restored.readable, isTrue);
        expect(restored.writable, isTrue);
        expect(restored.subscribable, isTrue);
      });
    });

    group('ChannelDescriptor', () {
      test('creates with default empty resources', () {
        const ch = ChannelDescriptor(id: 'ch1', name: 'Axis 1', type: 'axis');
        expect(ch.resources, isEmpty);
        expect(ch.children, isNull);
      });

      test('serializes and deserializes with resources and children', () {
        const ch = ChannelDescriptor(
          id: 'ch1',
          name: 'Main',
          type: 'ch',
          resources: [
            ResourceDescriptor(
              id: 'r1',
              name: 'Temp',
              uri: 'io://dev/ch/1/temp',
              payloadType: PayloadType.scalar,
            ),
          ],
          children: [
            ChannelDescriptor(id: 'sub1', name: 'Sub', type: 'gpio'),
          ],
        );
        final json = ch.toJson();
        final restored = ChannelDescriptor.fromJson(json);
        expect(restored.id, equals('ch1'));
        expect(restored.resources.length, equals(1));
        expect(restored.resources.first.id, equals('r1'));
        expect(restored.children?.length, equals(1));
        expect(restored.children!.first.id, equals('sub1'));
      });
    });

    group('CapabilityDescriptor', () {
      test('creates with default safety class', () {
        const cap = CapabilityDescriptor(action: 'moveTo');
        expect(cap.safetyClass, equals(SafetyClass.safe));
        expect(cap.argsSchema, isNull);
        expect(cap.description, isNull);
      });

      test('serializes and deserializes round-trip', () {
        const cap = CapabilityDescriptor(
          action: 'setSpeed',
          safetyClass: SafetyClass.guarded,
          argsSchema: {'type': 'object'},
          description: 'Set motor speed',
        );
        final json = cap.toJson();
        final restored = CapabilityDescriptor.fromJson(json);
        expect(restored.action, equals('setSpeed'));
        expect(restored.safetyClass, equals(SafetyClass.guarded));
        expect(restored.argsSchema?['type'], equals('object'));
        expect(restored.description, equals('Set motor speed'));
      });
    });

    group('DeviceDescriptor', () {
      test('creates with default values', () {
        const dd = DeviceDescriptor(
          deviceId: 'dev-1',
          manufacturer: 'TestCorp',
          model: 'T100',
          transport: 'tcp',
        );
        expect(dd.connectionState, equals(IoConnectionState.disconnected));
        expect(dd.capabilities, isEmpty);
        expect(dd.resourceTree, isEmpty);
        expect(dd.serial, isNull);
        expect(dd.version, isNull);
      });

      test('serializes and deserializes round-trip', () {
        const dd = DeviceDescriptor(
          deviceId: 'dev-1',
          manufacturer: 'Acme',
          model: 'Sensor-X',
          serial: 'SN12345',
          version: 'fw-1.0',
          transport: 'mqtt',
          connectionState: IoConnectionState.connected,
          capabilities: [
            CapabilityDescriptor(
                action: 'read', safetyClass: SafetyClass.safe),
          ],
          resourceTree: [
            ChannelDescriptor(id: 'ch1', name: 'Main', type: 'ch'),
          ],
        );
        final json = dd.toJson();
        final restored = DeviceDescriptor.fromJson(json);
        expect(restored.deviceId, equals('dev-1'));
        expect(restored.manufacturer, equals('Acme'));
        expect(restored.model, equals('Sensor-X'));
        expect(restored.serial, equals('SN12345'));
        expect(restored.version, equals('fw-1.0'));
        expect(restored.transport, equals('mqtt'));
        expect(
            restored.connectionState, equals(IoConnectionState.connected));
        expect(restored.capabilities.length, equals(1));
        expect(restored.resourceTree.length, equals(1));
      });

      test('toJson omits empty lists and null fields', () {
        const dd = DeviceDescriptor(
          deviceId: 'x',
          manufacturer: 'm',
          model: 'mo',
          transport: 't',
        );
        final json = dd.toJson();
        expect(json.containsKey('serial'), isFalse);
        expect(json.containsKey('version'), isFalse);
        expect(json.containsKey('capabilities'), isFalse);
        expect(json.containsKey('resourceTree'), isFalse);
      });
    });

    group('IoError', () {
      test('serializes and deserializes round-trip', () {
        final ts = DateTime.utc(2025, 6, 1);
        final err = IoError(
          code: 'TIMEOUT',
          message: 'Connection timed out',
          timestamp: ts,
          details: {'attempt': 3},
        );
        final json = err.toJson();
        final restored = IoError.fromJson(json);
        expect(restored.code, equals('TIMEOUT'));
        expect(restored.message, equals('Connection timed out'));
        expect(restored.timestamp, equals(ts));
        expect(restored.details?['attempt'], equals(3));
      });

      test('toJson omits null details', () {
        final err = IoError(
          code: 'ERR',
          message: 'msg',
          timestamp: DateTime.utc(2025),
        );
        final json = err.toJson();
        expect(json.containsKey('details'), isFalse);
      });
    });

    group('ConditionEvaluation', () {
      test('serializes and deserializes round-trip', () {
        const ce = ConditionEvaluation(
          ruleId: 'rule-1',
          matched: true,
          decision: Decision.allow,
        );
        final json = ce.toJson();
        final restored = ConditionEvaluation.fromJson(json);
        expect(restored.ruleId, equals('rule-1'));
        expect(restored.matched, isTrue);
        expect(restored.decision, equals(Decision.allow));
      });

      test('handles null decision', () {
        const ce = ConditionEvaluation(ruleId: 'r1', matched: false);
        final json = ce.toJson();
        expect(json.containsKey('decision'), isFalse);
        final restored = ConditionEvaluation.fromJson(json);
        expect(restored.decision, isNull);
      });
    });

    group('PolicyTrace', () {
      test('serializes and deserializes round-trip', () {
        final ts = DateTime.utc(2025, 6, 1);
        final trace = PolicyTrace(
          commandId: 'cmd-1',
          ruleId: 'rule-1',
          evaluatedAt: ts,
          conditions: [
            const ConditionEvaluation(
              ruleId: 'rule-1',
              matched: true,
              decision: Decision.allow,
            ),
          ],
          finalDecision: Decision.allow,
          finalNotes: 'Allowed by default',
        );
        final json = trace.toJson();
        final restored = PolicyTrace.fromJson(json);
        expect(restored.commandId, equals('cmd-1'));
        expect(restored.ruleId, equals('rule-1'));
        expect(restored.evaluatedAt, equals(ts));
        expect(restored.conditions.length, equals(1));
        expect(restored.finalDecision, equals(Decision.allow));
        expect(restored.finalNotes, equals('Allowed by default'));
      });

      test('handles minimal fields', () {
        final trace = PolicyTrace(
          commandId: 'cmd-2',
          evaluatedAt: DateTime.utc(2025),
          finalDecision: Decision.deny,
        );
        final json = trace.toJson();
        expect(json.containsKey('ruleId'), isFalse);
        expect(json.containsKey('conditions'), isFalse);
        expect(json.containsKey('finalNotes'), isFalse);
      });
    });

    group('Command', () {
      test('creates with defaults', () {
        const cmd = Command(action: 'moveTo', target: 'io://dev/axis/1');
        expect(cmd.args, isEmpty);
        expect(cmd.priority, isNull);
        expect(cmd.metadata, isNull);
      });

      test('serializes and deserializes round-trip', () {
        const cmd = Command(
          action: 'setSpeed',
          target: 'io://dev/motor/1',
          args: {'speed': 100},
          priority: 1,
          metadata: {'source': 'test'},
        );
        final json = cmd.toJson();
        final restored = Command.fromJson(json);
        expect(restored.action, equals('setSpeed'));
        expect(restored.target, equals('io://dev/motor/1'));
        expect(restored.args['speed'], equals(100));
        expect(restored.priority, equals(1));
        expect(restored.metadata?['source'], equals('test'));
      });

      test('toJson omits empty args and null fields', () {
        const cmd = Command(action: 'stop', target: 't');
        final json = cmd.toJson();
        expect(json.containsKey('args'), isFalse);
        expect(json.containsKey('priority'), isFalse);
        expect(json.containsKey('metadata'), isFalse);
      });
    });

    group('CommandResult', () {
      test('serializes and deserializes round-trip', () {
        final ts = DateTime.utc(2025, 6, 1);
        final result = CommandResult(
          status: CommandStatus.failed,
          error: IoError(
            code: 'FAIL',
            message: 'Command failed',
            timestamp: ts,
          ),
          policyTrace: PolicyTrace(
            commandId: 'cmd-1',
            evaluatedAt: ts,
            finalDecision: Decision.deny,
          ),
        );
        final json = result.toJson();
        final restored = CommandResult.fromJson(json);
        expect(restored.status, equals(CommandStatus.failed));
        expect(restored.error?.code, equals('FAIL'));
        expect(restored.policyTrace?.finalDecision, equals(Decision.deny));
      });

      test('handles completed with result value', () {
        final result = CommandResult(
          status: CommandStatus.completed,
          result: {'position': 42},
        );
        final json = result.toJson();
        final restored = CommandResult.fromJson(json);
        expect(restored.status, equals(CommandStatus.completed));
        expect((restored.result as Map)['position'], equals(42));
        expect(restored.error, isNull);
      });
    });

    group('ReadOptions', () {
      test('creates with all null', () {
        const opts = ReadOptions();
        expect(opts.timeoutMs, isNull);
        expect(opts.retries, isNull);
        expect(opts.downsampleHz, isNull);
      });

      test('serializes and deserializes round-trip', () {
        const opts = ReadOptions(
          timeoutMs: 5000,
          retries: 3,
          downsampleHz: 100.0,
        );
        final json = opts.toJson();
        final restored = ReadOptions.fromJson(json);
        expect(restored.timeoutMs, equals(5000));
        expect(restored.retries, equals(3));
        expect(restored.downsampleHz, equals(100.0));
      });
    });

    group('ReadSpec', () {
      test('serializes and deserializes round-trip', () {
        const spec = ReadSpec(
          targets: ['io://dev/ch/1/temp', 'io://dev/ch/2/pressure'],
          options: ReadOptions(timeoutMs: 1000),
        );
        final json = spec.toJson();
        final restored = ReadSpec.fromJson(json);
        expect(restored.targets.length, equals(2));
        expect(restored.targets.first, equals('io://dev/ch/1/temp'));
        expect(restored.options?.timeoutMs, equals(1000));
      });

      test('handles no options', () {
        const spec = ReadSpec(targets: ['io://dev/ch/1']);
        final json = spec.toJson();
        expect(json.containsKey('options'), isFalse);
        final restored = ReadSpec.fromJson(json);
        expect(restored.options, isNull);
      });
    });

    group('ReadResultItem', () {
      test('serializes and deserializes with envelope', () {
        final ts = DateTime.utc(2025, 6, 1);
        final item = ReadResultItem(
          uri: 'io://dev/ch/1/temp',
          envelope: PayloadEnvelope(
            uri: 'io://dev/ch/1/temp',
            kind: PayloadKind.read,
            payload: TypedPayload(
              type: PayloadType.scalar,
              value: 25.5,
              timestamp: ts,
            ),
            meta: EnvelopeMeta(
              capturedAt: ts,
              sourceAddress: 'dev-1',
            ),
          ),
        );
        final json = item.toJson();
        final restored = ReadResultItem.fromJson(json);
        expect(restored.uri, equals('io://dev/ch/1/temp'));
        expect(restored.envelope?.payload.value, equals(25.5));
        expect(restored.error, isNull);
      });

      test('serializes and deserializes with error', () {
        final item = ReadResultItem(
          uri: 'io://dev/ch/2',
          error: IoError(
            code: 'READ_FAIL',
            message: 'Unable to read',
            timestamp: DateTime.utc(2025),
          ),
        );
        final json = item.toJson();
        final restored = ReadResultItem.fromJson(json);
        expect(restored.uri, equals('io://dev/ch/2'));
        expect(restored.envelope, isNull);
        expect(restored.error?.code, equals('READ_FAIL'));
      });
    });

    group('ReadTiming', () {
      test('serializes and deserializes round-trip', () {
        final timing = ReadTiming(
          total: const Duration(milliseconds: 150),
          fastest: const Duration(milliseconds: 10),
          slowest: const Duration(milliseconds: 80),
        );
        final json = timing.toJson();
        final restored = ReadTiming.fromJson(json);
        expect(restored.total.inMilliseconds, equals(150));
        expect(restored.fastest?.inMilliseconds, equals(10));
        expect(restored.slowest?.inMilliseconds, equals(80));
      });

      test('handles null fastest and slowest', () {
        final timing = ReadTiming(total: const Duration(milliseconds: 50));
        final json = timing.toJson();
        expect(json.containsKey('fastestMs'), isFalse);
        expect(json.containsKey('slowestMs'), isFalse);
      });
    });

    group('ReadResult', () {
      test('creates with default empty items', () {
        const result = ReadResult();
        expect(result.items, isEmpty);
        expect(result.timing, isNull);
      });

      test('serializes and deserializes round-trip', () {
        final ts = DateTime.utc(2025, 6, 1);
        final result = ReadResult(
          items: [
            ReadResultItem(
              uri: 'io://dev/ch/1',
              envelope: PayloadEnvelope(
                uri: 'io://dev/ch/1',
                kind: PayloadKind.read,
                payload: TypedPayload(
                  type: PayloadType.scalar,
                  value: 10,
                  timestamp: ts,
                ),
                meta: EnvelopeMeta(
                  capturedAt: ts,
                  sourceAddress: 'dev',
                ),
              ),
            ),
          ],
          timing: ReadTiming(total: const Duration(milliseconds: 100)),
        );
        final json = result.toJson();
        final restored = ReadResult.fromJson(json);
        expect(restored.items.length, equals(1));
        expect(restored.timing?.total.inMilliseconds, equals(100));
      });
    });

    group('TopicOptions', () {
      test('creates with all null', () {
        const opts = TopicOptions();
        expect(opts.intervalMs, isNull);
        expect(opts.bufferSize, isNull);
        expect(opts.backpressure, isNull);
        expect(opts.ttlSeconds, isNull);
      });

      test('serializes and deserializes round-trip', () {
        const opts = TopicOptions(
          intervalMs: 100,
          bufferSize: 1024,
          backpressure: BackpressurePolicy.dropNewest,
          ttlSeconds: 60,
        );
        final json = opts.toJson();
        final restored = TopicOptions.fromJson(json);
        expect(restored.intervalMs, equals(100));
        expect(restored.bufferSize, equals(1024));
        expect(
            restored.backpressure, equals(BackpressurePolicy.dropNewest));
        expect(restored.ttlSeconds, equals(60));
      });
    });

    group('TopicSpec', () {
      test('serializes and deserializes round-trip', () {
        const spec = TopicSpec(
          uri: 'io://dev/ch/1/stream',
          mode: TopicMode.onChange,
          options: TopicOptions(intervalMs: 50),
        );
        final json = spec.toJson();
        final restored = TopicSpec.fromJson(json);
        expect(restored.uri, equals('io://dev/ch/1/stream'));
        expect(restored.mode, equals(TopicMode.onChange));
        expect(restored.options?.intervalMs, equals(50));
      });
    });

    group('EmergencyStopRequest', () {
      test('creates with optional deviceId', () {
        const req = EmergencyStopRequest(
          reason: 'Safety hazard',
          actorId: 'operator-1',
        );
        expect(req.deviceId, isNull);
        expect(req.reason, equals('Safety hazard'));
        expect(req.actorId, equals('operator-1'));
      });

      test('serializes and deserializes round-trip', () {
        const req = EmergencyStopRequest(
          deviceId: 'dev-1',
          reason: 'Overheating',
          actorId: 'sys',
        );
        final json = req.toJson();
        final restored = EmergencyStopRequest.fromJson(json);
        expect(restored.deviceId, equals('dev-1'));
        expect(restored.reason, equals('Overheating'));
        expect(restored.actorId, equals('sys'));
      });
    });

    group('EmergencyStopResult', () {
      test('creates with default empty stopped devices', () {
        const result = EmergencyStopResult(success: true);
        expect(result.success, isTrue);
        expect(result.stoppedDevices, isEmpty);
        expect(result.error, isNull);
      });

      test('serializes and deserializes round-trip', () {
        const result = EmergencyStopResult(
          success: true,
          stoppedDevices: ['dev-1', 'dev-2'],
        );
        final json = result.toJson();
        final restored = EmergencyStopResult.fromJson(json);
        expect(restored.success, isTrue);
        expect(restored.stoppedDevices.length, equals(2));
        expect(restored.stoppedDevices.first, equals('dev-1'));
      });

      test('serializes and deserializes with error', () {
        final result = EmergencyStopResult(
          success: false,
          error: IoError(
            code: 'STOP_FAIL',
            message: 'Could not stop',
            timestamp: DateTime.utc(2025),
          ),
        );
        final json = result.toJson();
        final restored = EmergencyStopResult.fromJson(json);
        expect(restored.success, isFalse);
        expect(restored.error?.code, equals('STOP_FAIL'));
      });
    });

    // ---- StubIoDevicePort ----
    group('StubIoDevicePort', () {
      late StubIoDevicePort port;

      setUp(() {
        port = StubIoDevicePort();
      });

      test('connect completes without error', () async {
        await port.connect();
      });

      test('disconnect completes without error', () async {
        await port.disconnect();
      });

      test('describe returns stub device descriptor', () async {
        final descriptor = await port.describe();
        expect(descriptor.deviceId, equals('stub-device'));
        expect(descriptor.manufacturer, equals('Stub'));
        expect(descriptor.model, equals('StubModel'));
        expect(descriptor.transport, equals('custom'));
        expect(descriptor.connectionState,
            equals(IoConnectionState.connected));
      });

      test('read returns empty ReadResult', () async {
        final result = await port.read(
          const ReadSpec(targets: ['io://dev/ch/1']),
        );
        expect(result.items, isEmpty);
      });

      test('execute returns completed CommandResult', () async {
        final result = await port.execute(
          const Command(action: 'test', target: 'io://dev'),
        );
        expect(result.status, equals(CommandStatus.completed));
      });

      test('subscribe returns empty stream', () async {
        final stream = port.subscribe(
          const TopicSpec(uri: 'io://dev/ch/1', mode: TopicMode.continuous),
        );
        final events = await stream.toList();
        expect(events, isEmpty);
      });

      test('emergencyStop returns success', () async {
        final result = await port.emergencyStop(
          const EmergencyStopRequest(
            reason: 'test',
            actorId: 'test-actor',
          ),
        );
        expect(result.success, isTrue);
      });
    });
  });

  // ==========================================================================
  // IoPolicyPort
  // ==========================================================================
  group('IoPolicyPort', () {
    group('PolicyCondition', () {
      test('creates with all null optional fields', () {
        const condition = PolicyCondition();
        expect(condition.action, isNull);
        expect(condition.targetPrefix, isNull);
        expect(condition.actorRoleIn, isNull);
        expect(condition.safetyClass, isNull);
        expect(condition.transport, isNull);
      });

      test('serializes and deserializes round-trip', () {
        const condition = PolicyCondition(
          action: 'moveTo*',
          targetPrefix: 'io://robot/',
          actorRoleIn: ['operator', 'admin'],
          safetyClass: SafetyClass.guarded,
          transport: 'mqtt',
        );
        final json = condition.toJson();
        final restored = PolicyCondition.fromJson(json);
        expect(restored.action, equals('moveTo*'));
        expect(restored.targetPrefix, equals('io://robot/'));
        expect(restored.actorRoleIn, equals(['operator', 'admin']));
        expect(restored.safetyClass, equals(SafetyClass.guarded));
        expect(restored.transport, equals('mqtt'));
      });

      test('toJson omits null fields', () {
        const condition = PolicyCondition(action: 'test');
        final json = condition.toJson();
        expect(json.containsKey('action'), isTrue);
        expect(json.containsKey('targetPrefix'), isFalse);
        expect(json.containsKey('actorRoleIn'), isFalse);
        expect(json.containsKey('safetyClass'), isFalse);
        expect(json.containsKey('transport'), isFalse);
      });
    });

    group('Bound', () {
      test('serializes and deserializes round-trip', () {
        const bound = Bound(min: 0.0, max: 100.0);
        final json = bound.toJson();
        final restored = Bound.fromJson(json);
        expect(restored.min, equals(0.0));
        expect(restored.max, equals(100.0));
      });

      test('handles partial bounds', () {
        const bound = Bound(max: 50.0);
        final json = bound.toJson();
        expect(json.containsKey('min'), isFalse);
        final restored = Bound.fromJson(json);
        expect(restored.min, isNull);
        expect(restored.max, equals(50.0));
      });
    });

    group('RateLimit', () {
      test('serializes and deserializes round-trip', () {
        final rl = RateLimit(
          maxCalls: 10,
          window: const Duration(seconds: 60),
        );
        final json = rl.toJson();
        final restored = RateLimit.fromJson(json);
        expect(restored.maxCalls, equals(10));
        expect(restored.window.inMilliseconds, equals(60000));
      });
    });

    group('Interlock', () {
      test('serializes and deserializes round-trip', () {
        const interlock = Interlock(
          uri: 'io://dev/safety/guard',
          condition: InterlockCondition.isTrue,
          action: InterlockAction.deny,
        );
        final json = interlock.toJson();
        final restored = Interlock.fromJson(json);
        expect(restored.uri, equals('io://dev/safety/guard'));
        expect(restored.condition, equals(InterlockCondition.isTrue));
        expect(restored.action, equals(InterlockAction.deny));
      });
    });

    group('PolicyConstraints', () {
      test('creates with all null fields', () {
        const pc = PolicyConstraints();
        expect(pc.bounds, isNull);
        expect(pc.rateLimit, isNull);
        expect(pc.interlocks, isNull);
        expect(pc.requireApproval, isNull);
      });

      test('serializes and deserializes round-trip', () {
        final pc = PolicyConstraints(
          bounds: {'speed': const Bound(min: 0, max: 1000)},
          rateLimit: RateLimit(
            maxCalls: 5,
            window: const Duration(seconds: 30),
          ),
          interlocks: [
            const Interlock(
              uri: 'io://dev/guard',
              condition: InterlockCondition.isTrue,
              action: InterlockAction.deny,
            ),
          ],
          requireApproval: true,
        );
        final json = pc.toJson();
        final restored = PolicyConstraints.fromJson(json);
        expect(restored.bounds?['speed']?.max, equals(1000));
        expect(restored.rateLimit?.maxCalls, equals(5));
        expect(restored.interlocks?.length, equals(1));
        expect(restored.requireApproval, isTrue);
      });
    });

    group('PolicyRule', () {
      test('creates with default enabled=true', () {
        const rule = PolicyRule(
          id: 'rule-1',
          name: 'Test Rule',
          when: PolicyCondition(action: 'test'),
          allow: true,
        );
        expect(rule.enabled, isTrue);
        expect(rule.description, isNull);
        expect(rule.constraints, isNull);
        expect(rule.priority, isNull);
      });

      test('serializes and deserializes round-trip', () {
        const rule = PolicyRule(
          id: 'rule-1',
          name: 'Allow moveTo',
          description: 'Allows moveTo for operators',
          when: PolicyCondition(
            action: 'moveTo',
            actorRoleIn: ['operator'],
          ),
          allow: true,
          priority: 10,
          enabled: false,
        );
        final json = rule.toJson();
        final restored = PolicyRule.fromJson(json);
        expect(restored.id, equals('rule-1'));
        expect(restored.name, equals('Allow moveTo'));
        expect(restored.description, equals('Allows moveTo for operators'));
        expect(restored.when.action, equals('moveTo'));
        expect(restored.allow, isTrue);
        expect(restored.priority, equals(10));
        expect(restored.enabled, isFalse);
      });
    });

    group('PolicyDecision', () {
      test('serializes and deserializes round-trip', () {
        const pd = PolicyDecision(
          decision: Decision.allow,
          ruleId: 'rule-1',
          notes: 'Matched operator rule',
        );
        final json = pd.toJson();
        final restored = PolicyDecision.fromJson(json);
        expect(restored.decision, equals(Decision.allow));
        expect(restored.ruleId, equals('rule-1'));
        expect(restored.notes, equals('Matched operator rule'));
      });

      test('handles minimal fields', () {
        const pd = PolicyDecision(decision: Decision.deny);
        final json = pd.toJson();
        expect(json.containsKey('ruleId'), isFalse);
        expect(json.containsKey('notes'), isFalse);
      });
    });

    // ---- StubIoPolicyPort ----
    group('StubIoPolicyPort', () {
      late StubIoPolicyPort port;

      setUp(() {
        port = StubIoPolicyPort();
      });

      test('addRule and listRules', () async {
        const rule = PolicyRule(
          id: 'r1',
          name: 'Rule 1',
          when: PolicyCondition(action: 'moveTo'),
          allow: true,
        );
        await port.addRule(rule);
        final rules = await port.listRules();
        expect(rules.length, equals(1));
        expect(rules.first.id, equals('r1'));
      });

      test('listRules returns empty initially', () async {
        final rules = await port.listRules();
        expect(rules, isEmpty);
      });

      test('updateRule modifies existing rule', () async {
        const rule = PolicyRule(
          id: 'r1',
          name: 'Original',
          when: PolicyCondition(action: 'test'),
          allow: true,
        );
        await port.addRule(rule);

        const updated = PolicyRule(
          id: 'r1',
          name: 'Updated',
          when: PolicyCondition(action: 'test'),
          allow: false,
        );
        await port.updateRule(updated);

        final rules = await port.listRules();
        expect(rules.length, equals(1));
        expect(rules.first.name, equals('Updated'));
        expect(rules.first.allow, isFalse);
      });

      test('updateRule throws StateError for non-existent rule', () async {
        const rule = PolicyRule(
          id: 'nonexistent',
          name: 'Ghost',
          when: PolicyCondition(),
          allow: true,
        );
        expect(
          () => port.updateRule(rule),
          throwsA(isA<StateError>()),
        );
      });

      test('removeRule removes existing rule', () async {
        const rule = PolicyRule(
          id: 'r1',
          name: 'Rule 1',
          when: PolicyCondition(),
          allow: true,
        );
        await port.addRule(rule);
        await port.removeRule('r1');
        final rules = await port.listRules();
        expect(rules, isEmpty);
      });

      test('listRules filters by action', () async {
        const rule1 = PolicyRule(
          id: 'r1',
          name: 'MoveTo rule',
          when: PolicyCondition(action: 'moveTo'),
          allow: true,
        );
        const rule2 = PolicyRule(
          id: 'r2',
          name: 'Stop rule',
          when: PolicyCondition(action: 'stop'),
          allow: false,
        );
        await port.addRule(rule1);
        await port.addRule(rule2);

        final moveRules = await port.listRules(actionFilter: 'moveTo');
        expect(moveRules.length, equals(1));
        expect(moveRules.first.id, equals('r1'));

        final stopRules = await port.listRules(actionFilter: 'stop');
        expect(stopRules.length, equals(1));
        expect(stopRules.first.id, equals('r2'));
      });

      test('listRules filters by device ID prefix', () async {
        const rule1 = PolicyRule(
          id: 'r1',
          name: 'Robot rule',
          when: PolicyCondition(targetPrefix: 'io://robot/arm'),
          allow: true,
        );
        const rule2 = PolicyRule(
          id: 'r2',
          name: 'Sensor rule',
          when: PolicyCondition(targetPrefix: 'io://sensor/temp'),
          allow: true,
        );
        await port.addRule(rule1);
        await port.addRule(rule2);

        final robotRules =
            await port.listRules(deviceIdFilter: 'io://robot');
        expect(robotRules.length, equals(1));
        expect(robotRules.first.id, equals('r1'));
      });
    });
  });

  // ==========================================================================
  // IoRegistryPort
  // ==========================================================================
  group('IoRegistryPort', () {
    group('RegistryEventType', () {
      test('fromString parses all values', () {
        expect(RegistryEventType.fromString('deviceRegistered'),
            equals(RegistryEventType.deviceRegistered));
        expect(RegistryEventType.fromString('deviceUnregistered'),
            equals(RegistryEventType.deviceUnregistered));
        expect(RegistryEventType.fromString('deviceConnected'),
            equals(RegistryEventType.deviceConnected));
        expect(RegistryEventType.fromString('deviceDisconnected'),
            equals(RegistryEventType.deviceDisconnected));
        expect(RegistryEventType.fromString('deviceError'),
            equals(RegistryEventType.deviceError));
        expect(RegistryEventType.fromString('adapterRegistered'),
            equals(RegistryEventType.adapterRegistered));
        expect(RegistryEventType.fromString('adapterUnregistered'),
            equals(RegistryEventType.adapterUnregistered));
      });

      test('fromString returns deviceError for unknown value', () {
        expect(RegistryEventType.fromString('invalid'),
            equals(RegistryEventType.deviceError));
      });
    });

    group('TransportDescriptor', () {
      test('serializes and deserializes round-trip', () {
        final td = TransportDescriptor(
          type: TransportType.mqtt,
          defaults: {'broker': 'localhost', 'port': 1883},
        );
        final json = td.toJson();
        final restored = TransportDescriptor.fromJson(json);
        expect(restored.type, equals(TransportType.mqtt));
        expect(restored.defaults?['broker'], equals('localhost'));
        expect(restored.defaults?['port'], equals(1883));
      });

      test('toJson omits null defaults', () {
        final td = TransportDescriptor(type: TransportType.tcp);
        final json = td.toJson();
        expect(json.containsKey('defaults'), isFalse);
      });
    });

    group('DeviceMatcher', () {
      test('serializes and deserializes round-trip', () {
        final matcher = DeviceMatcher(
          type: 'idn_query',
          pattern: 'KEYSIGHT*',
          context: {'timeout': 5000},
        );
        final json = matcher.toJson();
        final restored = DeviceMatcher.fromJson(json);
        expect(restored.type, equals('idn_query'));
        expect(restored.pattern, equals('KEYSIGHT*'));
        expect(restored.context?['timeout'], equals(5000));
      });

      test('toJson omits null context', () {
        final matcher = DeviceMatcher(type: 'serial', pattern: 'USB*');
        final json = matcher.toJson();
        expect(json.containsKey('context'), isFalse);
      });
    });

    group('ConcurrencyDescriptor', () {
      test('creates with default supportsParallelReads=false', () {
        const cd = ConcurrencyDescriptor(maxConcurrentCommands: 4);
        expect(cd.maxConcurrentCommands, equals(4));
        expect(cd.supportsParallelReads, isFalse);
      });

      test('serializes and deserializes round-trip', () {
        const cd = ConcurrencyDescriptor(
          maxConcurrentCommands: 8,
          supportsParallelReads: true,
        );
        final json = cd.toJson();
        final restored = ConcurrencyDescriptor.fromJson(json);
        expect(restored.maxConcurrentCommands, equals(8));
        expect(restored.supportsParallelReads, isTrue);
      });
    });

    group('AdapterManifest', () {
      test('creates with default empty lists', () {
        final manifest = AdapterManifest(
          adapterId: 'adapter-1',
          adapterVersion: '1.0.0',
          contractVersionRange: '>=0.1.0 <1.0.0',
          displayName: 'Test Adapter',
        );
        expect(manifest.transports, isEmpty);
        expect(manifest.matchers, isEmpty);
        expect(manifest.capabilities, isEmpty);
        expect(manifest.concurrency, isNull);
        expect(manifest.description, isNull);
      });

      test('serializes and deserializes round-trip', () {
        final manifest = AdapterManifest(
          adapterId: 'keysight-dmm',
          adapterVersion: '2.0.0',
          contractVersionRange: '>=1.0.0 <2.0.0',
          displayName: 'Keysight DMM Adapter',
          description: 'Digital multimeter adapter',
          transports: [
            TransportDescriptor(type: TransportType.tcp),
          ],
          matchers: [
            DeviceMatcher(type: 'idn_query', pattern: 'KEYSIGHT*'),
          ],
          capabilities: [
            const CapabilityDescriptor(action: 'measure'),
          ],
          concurrency: const ConcurrencyDescriptor(
            maxConcurrentCommands: 2,
            supportsParallelReads: true,
          ),
        );
        final json = manifest.toJson();
        final restored = AdapterManifest.fromJson(json);
        expect(restored.adapterId, equals('keysight-dmm'));
        expect(restored.adapterVersion, equals('2.0.0'));
        expect(restored.contractVersionRange, equals('>=1.0.0 <2.0.0'));
        expect(restored.displayName, equals('Keysight DMM Adapter'));
        expect(restored.description, equals('Digital multimeter adapter'));
        expect(restored.transports.length, equals(1));
        expect(restored.transports.first.type, equals(TransportType.tcp));
        expect(restored.matchers.length, equals(1));
        expect(restored.matchers.first.pattern, equals('KEYSIGHT*'));
        expect(restored.capabilities.length, equals(1));
        expect(restored.concurrency?.maxConcurrentCommands, equals(2));
        expect(restored.concurrency?.supportsParallelReads, isTrue);
      });

      test('toJson omits empty lists and null fields', () {
        final manifest = AdapterManifest(
          adapterId: 'a',
          adapterVersion: '1.0.0',
          contractVersionRange: '>=0.1.0',
          displayName: 'A',
        );
        final json = manifest.toJson();
        expect(json.containsKey('description'), isFalse);
        expect(json.containsKey('transports'), isFalse);
        expect(json.containsKey('matchers'), isFalse);
        expect(json.containsKey('capabilities'), isFalse);
        expect(json.containsKey('concurrency'), isFalse);
      });
    });

    group('RegistryEvent', () {
      test('serializes and deserializes round-trip', () {
        final ts = DateTime.utc(2025, 6, 1);
        final event = RegistryEvent(
          type: RegistryEventType.deviceConnected,
          deviceId: 'dev-2',
          adapterId: 'adapter-2',
          timestamp: ts,
        );
        final json = event.toJson();
        final restored = RegistryEvent.fromJson(json);
        expect(
            restored.type, equals(RegistryEventType.deviceConnected));
        expect(restored.deviceId, equals('dev-2'));
        expect(restored.adapterId, equals('adapter-2'));
        expect(restored.timestamp, equals(ts));
      });

      test('handles null adapterId', () {
        final event = RegistryEvent(
          type: RegistryEventType.deviceError,
          deviceId: 'dev-1',
          timestamp: DateTime.utc(2025),
        );
        final json = event.toJson();
        expect(json.containsKey('adapterId'), isFalse);
        final restored = RegistryEvent.fromJson(json);
        expect(restored.adapterId, isNull);
      });
    });

    // ---- StubIoRegistryPort ----
    group('StubIoRegistryPort', () {
      late StubIoRegistryPort port;

      setUp(() {
        port = StubIoRegistryPort();
      });

      tearDown(() {
        port.dispose();
      });

      test('registerAdapter and unregisterAdapter', () async {
        final manifest = AdapterManifest(
          adapterId: 'adapter-1',
          adapterVersion: '1.0.0',
          contractVersionRange: '>=0.1.0',
          displayName: 'Test',
        );
        final adapter = StubIoDevicePort();

        await port.registerAdapter(manifest, adapter);
        // Verify the adapter is registered (no exception thrown)

        await port.unregisterAdapter('adapter-1');
        // Verify unregister succeeds without error
      });

      test('discover returns empty list initially', () async {
        final devices = await port.discover();
        expect(devices, isEmpty);
      });

      test('list returns empty list initially', () async {
        final devices = await port.list();
        expect(devices, isEmpty);
      });

      test('get returns null for unknown device', () async {
        final device = await port.get('nonexistent');
        expect(device, isNull);
      });

      test('resolveAdapter returns null', () async {
        final adapter = await port.resolveAdapter('io://dev/ch/1');
        expect(adapter, isNull);
      });

      test('events stream is a broadcast stream', () {
        final stream = port.events;
        // Should be able to listen multiple times without error
        final sub1 = stream.listen((_) {});
        final sub2 = stream.listen((_) {});
        sub1.cancel();
        sub2.cancel();
      });
    });
  });

  // ==========================================================================
  // IoAuditPort
  // ==========================================================================
  group('IoAuditPort', () {
    group('IoAuditType', () {
      test('fromString parses all values', () {
        expect(IoAuditType.fromString('execute'),
            equals(IoAuditType.execute));
        expect(IoAuditType.fromString('emergencyStop'),
            equals(IoAuditType.emergencyStop));
        expect(IoAuditType.fromString('readAccess'),
            equals(IoAuditType.readAccess));
        expect(IoAuditType.fromString('subscribeAccess'),
            equals(IoAuditType.subscribeAccess));
        expect(IoAuditType.fromString('policyChange'),
            equals(IoAuditType.policyChange));
      });

      test('fromString returns execute for unknown value', () {
        expect(
            IoAuditType.fromString('invalid'), equals(IoAuditType.execute));
      });
    });

    group('IoAuditRecord', () {
      test('creates with required fields only', () {
        final ts = DateTime.utc(2025, 6, 1);
        final record = IoAuditRecord(
          id: 'audit-1',
          type: IoAuditType.execute,
          actorId: 'user-1',
          actorRole: 'operator',
          deviceId: 'dev-1',
          requestedAt: ts,
        );
        expect(record.id, equals('audit-1'));
        expect(record.type, equals(IoAuditType.execute));
        expect(record.command, isNull);
        expect(record.policyDecision, isNull);
        expect(record.policyTrace, isNull);
        expect(record.resultStatus, isNull);
        expect(record.executedAt, isNull);
        expect(record.completedAt, isNull);
        expect(record.stateBefore, isNull);
        expect(record.stateAfter, isNull);
        expect(record.metadata, isNull);
      });

      test('serializes and deserializes round-trip with all fields', () {
        final ts = DateTime.utc(2025, 6, 1);
        final record = IoAuditRecord(
          id: 'audit-2',
          type: IoAuditType.execute,
          actorId: 'skill-1',
          actorRole: 'skill',
          command: const Command(
            action: 'setSpeed',
            target: 'io://robot/motor/1',
            args: {'speed': 500},
          ),
          deviceId: 'robot-1',
          policyDecision: const PolicyDecision(
            decision: Decision.allow,
            ruleId: 'rule-1',
          ),
          policyTrace: PolicyTrace(
            commandId: 'cmd-1',
            evaluatedAt: ts,
            finalDecision: Decision.allow,
          ),
          resultStatus: CommandStatus.completed,
          requestedAt: ts,
          executedAt: ts.add(const Duration(milliseconds: 10)),
          completedAt: ts.add(const Duration(milliseconds: 50)),
          stateBefore: {'speed': 0},
          stateAfter: {'speed': 500},
          metadata: {'session': 'abc'},
        );
        final json = record.toJson();
        final restored = IoAuditRecord.fromJson(json);
        expect(restored.id, equals('audit-2'));
        expect(restored.type, equals(IoAuditType.execute));
        expect(restored.actorId, equals('skill-1'));
        expect(restored.actorRole, equals('skill'));
        expect(restored.command?.action, equals('setSpeed'));
        expect(restored.command?.args['speed'], equals(500));
        expect(restored.deviceId, equals('robot-1'));
        expect(restored.policyDecision?.decision, equals(Decision.allow));
        expect(restored.policyDecision?.ruleId, equals('rule-1'));
        expect(restored.policyTrace?.commandId, equals('cmd-1'));
        expect(restored.resultStatus, equals(CommandStatus.completed));
        expect(restored.requestedAt, equals(ts));
        expect(restored.executedAt,
            equals(ts.add(const Duration(milliseconds: 10))));
        expect(restored.completedAt,
            equals(ts.add(const Duration(milliseconds: 50))));
        expect(restored.stateBefore?['speed'], equals(0));
        expect(restored.stateAfter?['speed'], equals(500));
        expect(restored.metadata?['session'], equals('abc'));
      });

      test('toJson omits null optional fields', () {
        final record = IoAuditRecord(
          id: 'a1',
          type: IoAuditType.readAccess,
          actorId: 'u1',
          actorRole: 'operator',
          deviceId: 'd1',
          requestedAt: DateTime.utc(2025),
        );
        final json = record.toJson();
        expect(json.containsKey('command'), isFalse);
        expect(json.containsKey('policyDecision'), isFalse);
        expect(json.containsKey('policyTrace'), isFalse);
        expect(json.containsKey('resultStatus'), isFalse);
        expect(json.containsKey('executedAt'), isFalse);
        expect(json.containsKey('completedAt'), isFalse);
        expect(json.containsKey('stateBefore'), isFalse);
        expect(json.containsKey('stateAfter'), isFalse);
        expect(json.containsKey('metadata'), isFalse);
      });
    });

    group('IoAuditQuery', () {
      test('creates with all null', () {
        const query = IoAuditQuery();
        expect(query.deviceId, isNull);
        expect(query.actorId, isNull);
        expect(query.type, isNull);
        expect(query.from, isNull);
        expect(query.to, isNull);
        expect(query.limit, isNull);
        expect(query.offset, isNull);
      });

      test('serializes and deserializes round-trip', () {
        final from = DateTime.utc(2025, 1, 1);
        final to = DateTime.utc(2025, 12, 31);
        final query = IoAuditQuery(
          deviceId: 'dev-1',
          actorId: 'user-1',
          type: IoAuditType.emergencyStop,
          from: from,
          to: to,
          limit: 50,
          offset: 10,
        );
        final json = query.toJson();
        final restored = IoAuditQuery.fromJson(json);
        expect(restored.deviceId, equals('dev-1'));
        expect(restored.actorId, equals('user-1'));
        expect(restored.type, equals(IoAuditType.emergencyStop));
        expect(restored.from, equals(from));
        expect(restored.to, equals(to));
        expect(restored.limit, equals(50));
        expect(restored.offset, equals(10));
      });

      test('toJson omits null fields', () {
        const query = IoAuditQuery(deviceId: 'dev-1');
        final json = query.toJson();
        expect(json.containsKey('deviceId'), isTrue);
        expect(json.containsKey('actorId'), isFalse);
        expect(json.containsKey('type'), isFalse);
        expect(json.containsKey('from'), isFalse);
        expect(json.containsKey('to'), isFalse);
        expect(json.containsKey('limit'), isFalse);
        expect(json.containsKey('offset'), isFalse);
      });
    });

    group('IoAuditExportConfig', () {
      test('serializes and deserializes round-trip', () {
        const config = IoAuditExportConfig(
          query: IoAuditQuery(deviceId: 'dev-1'),
          targetSystem: 'elasticsearch',
          options: {'index': 'io-audit'},
        );
        final json = config.toJson();
        final restored = IoAuditExportConfig.fromJson(json);
        expect(restored.query.deviceId, equals('dev-1'));
        expect(restored.targetSystem, equals('elasticsearch'));
        expect(restored.options?['index'], equals('io-audit'));
      });

      test('toJson omits null options', () {
        const config = IoAuditExportConfig(
          query: IoAuditQuery(),
          targetSystem: 'mcp_fact_graph',
        );
        final json = config.toJson();
        expect(json.containsKey('options'), isFalse);
      });
    });

    // ---- StubIoAuditPort ----
    group('StubIoAuditPort', () {
      late StubIoAuditPort port;

      setUp(() {
        port = StubIoAuditPort();
      });

      test('records is empty initially', () {
        expect(port.records, isEmpty);
      });

      test('record adds audit entry', () async {
        final record = IoAuditRecord(
          id: 'a1',
          type: IoAuditType.execute,
          actorId: 'user-1',
          actorRole: 'operator',
          deviceId: 'dev-1',
          requestedAt: DateTime.utc(2025, 6, 1),
        );
        await port.record(record);
        expect(port.records.length, equals(1));
        expect(port.records.first.id, equals('a1'));
      });

      test('query filters by deviceId', () async {
        await port.record(IoAuditRecord(
          id: 'a1',
          type: IoAuditType.execute,
          actorId: 'u1',
          actorRole: 'op',
          deviceId: 'dev-1',
          requestedAt: DateTime.utc(2025),
        ));
        await port.record(IoAuditRecord(
          id: 'a2',
          type: IoAuditType.execute,
          actorId: 'u1',
          actorRole: 'op',
          deviceId: 'dev-2',
          requestedAt: DateTime.utc(2025),
        ));

        final results =
            await port.query(const IoAuditQuery(deviceId: 'dev-1'));
        expect(results.length, equals(1));
        expect(results.first.id, equals('a1'));
      });

      test('query filters by actorId', () async {
        await port.record(IoAuditRecord(
          id: 'a1',
          type: IoAuditType.execute,
          actorId: 'user-1',
          actorRole: 'op',
          deviceId: 'dev-1',
          requestedAt: DateTime.utc(2025),
        ));
        await port.record(IoAuditRecord(
          id: 'a2',
          type: IoAuditType.execute,
          actorId: 'user-2',
          actorRole: 'op',
          deviceId: 'dev-1',
          requestedAt: DateTime.utc(2025),
        ));

        final results =
            await port.query(const IoAuditQuery(actorId: 'user-1'));
        expect(results.length, equals(1));
        expect(results.first.id, equals('a1'));
      });

      test('query filters by type', () async {
        await port.record(IoAuditRecord(
          id: 'a1',
          type: IoAuditType.execute,
          actorId: 'u1',
          actorRole: 'op',
          deviceId: 'dev-1',
          requestedAt: DateTime.utc(2025),
        ));
        await port.record(IoAuditRecord(
          id: 'a2',
          type: IoAuditType.emergencyStop,
          actorId: 'u1',
          actorRole: 'op',
          deviceId: 'dev-1',
          requestedAt: DateTime.utc(2025),
        ));

        final results = await port
            .query(const IoAuditQuery(type: IoAuditType.emergencyStop));
        expect(results.length, equals(1));
        expect(results.first.id, equals('a2'));
      });

      test('query returns all when no filter', () async {
        await port.record(IoAuditRecord(
          id: 'a1',
          type: IoAuditType.execute,
          actorId: 'u1',
          actorRole: 'op',
          deviceId: 'dev-1',
          requestedAt: DateTime.utc(2025),
        ));
        await port.record(IoAuditRecord(
          id: 'a2',
          type: IoAuditType.readAccess,
          actorId: 'u2',
          actorRole: 'skill',
          deviceId: 'dev-2',
          requestedAt: DateTime.utc(2025),
        ));

        final results = await port.query(const IoAuditQuery());
        expect(results.length, equals(2));
      });

      test('export completes without error', () async {
        await port.export(const IoAuditExportConfig(
          query: IoAuditQuery(),
          targetSystem: 'test',
        ));
        // No-op stub, just confirm it does not throw
      });

      test('clear removes all records', () async {
        await port.record(IoAuditRecord(
          id: 'a1',
          type: IoAuditType.execute,
          actorId: 'u1',
          actorRole: 'op',
          deviceId: 'dev-1',
          requestedAt: DateTime.utc(2025),
        ));
        expect(port.records.length, equals(1));
        port.clear();
        expect(port.records, isEmpty);
      });
    });
  });

  // ==========================================================================
  // IoStreamPort
  // ==========================================================================
  group('IoStreamPort', () {
    group('SubscriptionHandle', () {
      test('serializes and deserializes round-trip', () {
        const handle = SubscriptionHandle(
          subscriptionId: 'sub-1',
          topic: 'io://dev/ch/1/waveform',
          mode: TopicMode.continuous,
          createdAt: 1717200000000,
          expiresAt: 1717203600000,
        );
        final json = handle.toJson();
        final restored = SubscriptionHandle.fromJson(json);
        expect(restored.subscriptionId, equals('sub-1'));
        expect(restored.topic, equals('io://dev/ch/1/waveform'));
        expect(restored.mode, equals(TopicMode.continuous));
        expect(restored.createdAt, equals(1717200000000));
        expect(restored.expiresAt, equals(1717203600000));
      });

      test('toJson omits null expiresAt', () {
        const handle = SubscriptionHandle(
          subscriptionId: 'sub-1',
          topic: 'io://dev/ch/1',
          mode: TopicMode.onChange,
          createdAt: 1000,
        );
        final json = handle.toJson();
        expect(json.containsKey('expiresAt'), isFalse);
      });

      test('handles all TopicMode values', () {
        for (final mode in TopicMode.values) {
          final handle = SubscriptionHandle(
            subscriptionId: 'sub-${mode.name}',
            topic: 'io://dev/test',
            mode: mode,
            createdAt: 0,
          );
          final json = handle.toJson();
          final restored = SubscriptionHandle.fromJson(json);
          expect(restored.mode, equals(mode));
        }
      });
    });

    group('SubscriptionStatus', () {
      test('creates with default values', () {
        const status = SubscriptionStatus(
          subscriptionId: 'sub-1',
          active: true,
        );
        expect(status.messagesDelivered, equals(0));
        expect(status.messagesDropped, equals(0));
        expect(status.bufferUsed, equals(0));
        expect(status.bufferCapacity, equals(0));
        expect(status.lastMessageAt, isNull);
      });

      test('serializes and deserializes round-trip', () {
        final lastMsg = DateTime.utc(2025, 6, 1, 12, 0, 0);
        final status = SubscriptionStatus(
          subscriptionId: 'sub-1',
          active: true,
          messagesDelivered: 1000,
          messagesDropped: 5,
          bufferUsed: 128,
          bufferCapacity: 1024,
          lastMessageAt: lastMsg,
        );
        final json = status.toJson();
        final restored = SubscriptionStatus.fromJson(json);
        expect(restored.subscriptionId, equals('sub-1'));
        expect(restored.active, isTrue);
        expect(restored.messagesDelivered, equals(1000));
        expect(restored.messagesDropped, equals(5));
        expect(restored.bufferUsed, equals(128));
        expect(restored.bufferCapacity, equals(1024));
        expect(restored.lastMessageAt, equals(lastMsg));
      });

      test('toJson omits null lastMessageAt', () {
        const status = SubscriptionStatus(
          subscriptionId: 'sub-1',
          active: false,
        );
        final json = status.toJson();
        expect(json.containsKey('lastMessageAt'), isFalse);
      });
    });

    group('IoStreamSubscription', () {
      test('creates with handle and stream', () {
        const handle = SubscriptionHandle(
          subscriptionId: 'sub-1',
          topic: 'io://dev/ch/1',
          mode: TopicMode.continuous,
          createdAt: 0,
        );
        final subscription = IoStreamSubscription(
          handle: handle,
          stream: const Stream.empty(),
        );
        expect(subscription.handle.subscriptionId, equals('sub-1'));
      });
    });

    // ---- StubIoStreamPort ----
    group('StubIoStreamPort', () {
      late StubIoStreamPort port;

      setUp(() {
        port = StubIoStreamPort();
      });

      test('subscribe creates a subscription', () async {
        const spec = TopicSpec(
          uri: 'io://dev/ch/1/waveform',
          mode: TopicMode.continuous,
        );
        final sub = await port.subscribe(spec, consumerId: 'consumer-1');
        expect(sub.handle.subscriptionId, equals('sub_0'));
        expect(sub.handle.topic, equals('io://dev/ch/1/waveform'));
        expect(sub.handle.mode, equals(TopicMode.continuous));
      });

      test('subscribe generates sequential IDs', () async {
        const spec = TopicSpec(
          uri: 'io://dev/ch/1',
          mode: TopicMode.onChange,
        );
        final sub1 = await port.subscribe(spec, consumerId: 'c1');
        final sub2 = await port.subscribe(spec, consumerId: 'c2');
        expect(sub1.handle.subscriptionId, equals('sub_0'));
        expect(sub2.handle.subscriptionId, equals('sub_1'));
      });

      test('subscribe returns empty stream', () async {
        const spec = TopicSpec(
          uri: 'io://dev/ch/1',
          mode: TopicMode.continuous,
        );
        final sub = await port.subscribe(spec, consumerId: 'c1');
        final events = await sub.stream.toList();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(events, isEmpty);
      });

      test('unsubscribe removes subscription', () async {
        const spec = TopicSpec(
          uri: 'io://dev/ch/1',
          mode: TopicMode.continuous,
        );
        final sub = await port.subscribe(spec, consumerId: 'c1');
        final subId = sub.handle.subscriptionId;

        await port.unsubscribe(subId);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final status = await port.getStatus(subId);
        expect(status, isNull);
      });

      test('listSubscriptions returns active subscriptions', () async {
        const spec1 = TopicSpec(
          uri: 'io://dev/ch/1',
          mode: TopicMode.continuous,
        );
        const spec2 = TopicSpec(
          uri: 'io://dev/ch/2',
          mode: TopicMode.poll,
        );
        await port.subscribe(spec1, consumerId: 'c1');
        await port.subscribe(spec2, consumerId: 'c2');

        final subs = await port.listSubscriptions();
        expect(subs.length, equals(2));
      });

      test('listSubscriptions returns empty when none active', () async {
        final subs = await port.listSubscriptions();
        expect(subs, isEmpty);
      });

      test('getStatus returns status for active subscription', () async {
        const spec = TopicSpec(
          uri: 'io://dev/ch/1',
          mode: TopicMode.continuous,
        );
        final sub = await port.subscribe(spec, consumerId: 'c1');
        final status = await port.getStatus(sub.handle.subscriptionId);
        expect(status, isNotNull);
        expect(status!.subscriptionId, equals(sub.handle.subscriptionId));
        expect(status.active, isTrue);
      });

      test('getStatus returns null for unknown subscription', () async {
        final status = await port.getStatus('nonexistent');
        expect(status, isNull);
      });

      test('clear removes all subscriptions', () async {
        const spec = TopicSpec(
          uri: 'io://dev/ch/1',
          mode: TopicMode.continuous,
        );
        await port.subscribe(spec, consumerId: 'c1');
        await port.subscribe(spec, consumerId: 'c2');

        port.clear();

        final subs = await port.listSubscriptions();
        expect(subs, isEmpty);
      });

      test('unsubscribe then listSubscriptions reflects removal', () async {
        const spec = TopicSpec(
          uri: 'io://dev/ch/1',
          mode: TopicMode.continuous,
        );
        final sub1 = await port.subscribe(spec, consumerId: 'c1');
        await port.subscribe(spec, consumerId: 'c2');

        await port.unsubscribe(sub1.handle.subscriptionId);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final subs = await port.listSubscriptions();
        expect(subs.length, equals(1));
        expect(subs.first.subscriptionId, equals('sub_1'));
      });
    });
  });
}