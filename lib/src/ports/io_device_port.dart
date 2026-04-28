/// IoDevicePort - Unified interface for IoT/hardware device operations.
///
/// Provides abstract contracts for device communication including
/// reading sensor data, executing commands, subscribing to topics,
/// and emergency stop across the MCP ecosystem.
library;

import 'dart:async';

// ============================================================================
// Enums
// ============================================================================

/// Kind of payload carried in an envelope.
enum PayloadKind {
  read,
  stream,
  event,
  commandResult,
  describe;

  static PayloadKind fromString(String value) {
    return PayloadKind.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PayloadKind.read,
    );
  }
}

/// Data type of a typed payload value.
enum PayloadType {
  scalar,
  vector,
  waveform,
  event,
  struct_,
  blob,
  null_;

  static PayloadType fromString(String value) {
    return PayloadType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PayloadType.scalar,
    );
  }
}

/// Quality indicator for a payload value.
enum Quality {
  ok,
  stale,
  clipped,
  saturated,
  timeout,
  error,
  simulated,
  unknown;

  static Quality fromString(String value) {
    return Quality.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Quality.unknown,
    );
  }
}

/// Connection state of an IO device.
enum IoConnectionState {
  connected,
  disconnected,
  error,
  connecting;

  static IoConnectionState fromString(String value) {
    return IoConnectionState.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IoConnectionState.disconnected,
    );
  }
}

/// Safety classification for a device capability.
enum SafetyClass {
  safe,
  guarded,
  dangerous;

  static SafetyClass fromString(String value) {
    return SafetyClass.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SafetyClass.safe,
    );
  }
}

/// Status of a command execution.
enum CommandStatus {
  pending,
  executing,
  completed,
  failed,
  rejected,
  needsApproval,
  planned;

  static CommandStatus fromString(String value) {
    return CommandStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CommandStatus.pending,
    );
  }
}

/// Subscription topic delivery mode.
enum TopicMode {
  continuous,
  onChange,
  poll,
  event;

  static TopicMode fromString(String value) {
    return TopicMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TopicMode.continuous,
    );
  }
}

/// Backpressure handling policy for subscriptions.
enum BackpressurePolicy {
  dropOldest,
  dropNewest,
  block;

  static BackpressurePolicy fromString(String value) {
    return BackpressurePolicy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BackpressurePolicy.dropOldest,
    );
  }
}

/// Transport protocol type for device communication.
enum TransportType {
  tcp,
  serial,
  usb,
  ble,
  can,
  mqtt,
  ros2,
  custom;

  static TransportType fromString(String value) {
    return TransportType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransportType.custom,
    );
  }
}

/// Condition operator for interlock rules.
enum InterlockCondition {
  equals,
  isTrue,
  isFalse,
  greaterThan,
  lessThan;

  static InterlockCondition fromString(String value) {
    return InterlockCondition.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InterlockCondition.equals,
    );
  }
}

/// Action to take when an interlock condition is met.
enum InterlockAction {
  deny,
  warn;

  static InterlockAction fromString(String value) {
    return InterlockAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InterlockAction.deny,
    );
  }
}

/// Policy decision outcome.
enum Decision {
  allow,
  deny,
  needsApproval,
  needsPlan;

  static Decision fromString(String value) {
    return Decision.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Decision.deny,
    );
  }
}

// ============================================================================
// Payload Types
// ============================================================================

/// Source information for a typed payload.
class PayloadSource {
  /// Adapter identifier that produced this payload.
  final String adapterId;

  /// Firmware version of the source device.
  final String? firmware;

  /// Sample rate in Hz of the source.
  final double? sampleRate;

  const PayloadSource({
    required this.adapterId,
    this.firmware,
    this.sampleRate,
  });

  /// Create from JSON.
  factory PayloadSource.fromJson(Map<String, dynamic> json) {
    return PayloadSource(
      adapterId: json['adapterId'] as String,
      firmware: json['firmware'] as String?,
      sampleRate: (json['sampleRate'] as num?)?.toDouble(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'adapterId': adapterId,
        if (firmware != null) 'firmware': firmware,
        if (sampleRate != null) 'sampleRate': sampleRate,
      };
}

/// Typed payload with value, unit, timestamp, and quality.
class TypedPayload {
  /// Data type of the value.
  final PayloadType type;

  /// The actual payload value.
  final dynamic value;

  /// Unit of measurement (e.g., 'celsius', 'rpm').
  final String? unit;

  /// Timestamp when the value was captured.
  final DateTime timestamp;

  /// Quality indicator for this value.
  final Quality quality;

  /// Source information for this payload.
  final PayloadSource? source;

  TypedPayload({
    required this.type,
    required this.value,
    this.unit,
    required this.timestamp,
    this.quality = Quality.ok,
    this.source,
  });

  /// Create from JSON.
  factory TypedPayload.fromJson(Map<String, dynamic> json) {
    return TypedPayload(
      type: PayloadType.fromString(json['type'] as String? ?? 'scalar'),
      value: json['value'],
      unit: json['unit'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      quality: Quality.fromString(json['quality'] as String? ?? 'ok'),
      source: json['source'] != null
          ? PayloadSource.fromJson(json['source'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'value': value,
        if (unit != null) 'unit': unit,
        'timestamp': timestamp.toIso8601String(),
        'quality': quality.name,
        if (source != null) 'source': source!.toJson(),
      };
}

/// Chunk metadata for multi-part payloads.
class ChunkMeta {
  /// Index of this chunk within the group.
  final int index;

  /// Total number of chunks in the group.
  final int total;

  /// Group identifier linking related chunks.
  final String groupId;

  const ChunkMeta({
    required this.index,
    required this.total,
    required this.groupId,
  });

  /// Create from JSON.
  factory ChunkMeta.fromJson(Map<String, dynamic> json) {
    return ChunkMeta(
      index: json['index'] as int,
      total: json['total'] as int,
      groupId: json['groupId'] as String,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'index': index,
        'total': total,
        'groupId': groupId,
      };
}

/// Envelope metadata including capture time and source address.
class EnvelopeMeta {
  /// When the data was captured.
  final DateTime capturedAt;

  /// Source address or identifier.
  final String sourceAddress;

  /// Sequence number for ordering.
  final int? sequenceNumber;

  /// Chunk metadata for multi-part payloads.
  final ChunkMeta? chunk;

  const EnvelopeMeta({
    required this.capturedAt,
    required this.sourceAddress,
    this.sequenceNumber,
    this.chunk,
  });

  /// Create from JSON.
  factory EnvelopeMeta.fromJson(Map<String, dynamic> json) {
    return EnvelopeMeta(
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      sourceAddress: json['sourceAddress'] as String,
      sequenceNumber: json['sequenceNumber'] as int?,
      chunk: json['chunk'] != null
          ? ChunkMeta.fromJson(json['chunk'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'capturedAt': capturedAt.toIso8601String(),
        'sourceAddress': sourceAddress,
        if (sequenceNumber != null) 'sequenceNumber': sequenceNumber,
        if (chunk != null) 'chunk': chunk!.toJson(),
      };
}

/// Envelope wrapping a typed payload with URI and metadata.
class PayloadEnvelope {
  /// Resource URI (e.g., io://deviceId/ch/1/waveform).
  final String uri;

  /// Kind of payload.
  final PayloadKind kind;

  /// The typed payload data.
  final TypedPayload payload;

  /// Envelope metadata.
  final EnvelopeMeta meta;

  PayloadEnvelope({
    required this.uri,
    required this.kind,
    required this.payload,
    required this.meta,
  });

  /// Create from JSON.
  factory PayloadEnvelope.fromJson(Map<String, dynamic> json) {
    return PayloadEnvelope(
      uri: json['uri'] as String,
      kind: PayloadKind.fromString(json['kind'] as String? ?? 'read'),
      payload:
          TypedPayload.fromJson(json['payload'] as Map<String, dynamic>),
      meta: EnvelopeMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'uri': uri,
        'kind': kind.name,
        'payload': payload.toJson(),
        'meta': meta.toJson(),
      };
}

// ============================================================================
// Device Descriptor Types
// ============================================================================

/// Descriptor for a resource exposed by a channel.
class ResourceDescriptor {
  /// Resource identifier.
  final String id;

  /// Human-readable name.
  final String name;

  /// Resource URI (e.g., io://deviceId/ch/1/waveform).
  final String uri;

  /// Payload data type.
  final PayloadType payloadType;

  /// Unit of measurement.
  final String? unit;

  /// Whether this resource can be read.
  final bool readable;

  /// Whether this resource can be written to.
  final bool writable;

  /// Whether this resource supports subscriptions.
  final bool subscribable;

  const ResourceDescriptor({
    required this.id,
    required this.name,
    required this.uri,
    required this.payloadType,
    this.unit,
    this.readable = true,
    this.writable = false,
    this.subscribable = false,
  });

  /// Create from JSON.
  factory ResourceDescriptor.fromJson(Map<String, dynamic> json) {
    return ResourceDescriptor(
      id: json['id'] as String,
      name: json['name'] as String,
      uri: json['uri'] as String,
      payloadType:
          PayloadType.fromString(json['payloadType'] as String? ?? 'scalar'),
      unit: json['unit'] as String?,
      readable: json['readable'] as bool? ?? true,
      writable: json['writable'] as bool? ?? false,
      subscribable: json['subscribable'] as bool? ?? false,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'uri': uri,
        'payloadType': payloadType.name,
        if (unit != null) 'unit': unit,
        'readable': readable,
        'writable': writable,
        'subscribable': subscribable,
      };
}

/// Descriptor for a channel within a device (e.g., axis, joint, sensor).
class ChannelDescriptor {
  /// Channel identifier.
  final String id;

  /// Human-readable name.
  final String name;

  /// Channel type (ch, axis, joint, tag, reg, gpio, pwm, adc, dac).
  final String type;

  /// Resources available on this channel.
  final List<ResourceDescriptor> resources;

  /// Optional nested child channels.
  final List<ChannelDescriptor>? children;

  const ChannelDescriptor({
    required this.id,
    required this.name,
    required this.type,
    this.resources = const [],
    this.children,
  });

  /// Create from JSON.
  factory ChannelDescriptor.fromJson(Map<String, dynamic> json) {
    return ChannelDescriptor(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      resources: (json['resources'] as List<dynamic>?)
              ?.map(
                  (e) => ResourceDescriptor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => ChannelDescriptor.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        if (resources.isNotEmpty)
          'resources': resources.map((r) => r.toJson()).toList(),
        if (children != null)
          'children': children!.map((c) => c.toJson()).toList(),
      };
}

/// Descriptor for a device capability (action it can perform).
class CapabilityDescriptor {
  /// Action name (e.g., 'moveTo', 'setSpeed').
  final String action;

  /// Safety classification for this action.
  final SafetyClass safetyClass;

  /// JSON schema describing the arguments.
  final Map<String, dynamic>? argsSchema;

  /// Human-readable description of this capability.
  final String? description;

  const CapabilityDescriptor({
    required this.action,
    this.safetyClass = SafetyClass.safe,
    this.argsSchema,
    this.description,
  });

  /// Create from JSON.
  factory CapabilityDescriptor.fromJson(Map<String, dynamic> json) {
    return CapabilityDescriptor(
      action: json['action'] as String,
      safetyClass:
          SafetyClass.fromString(json['safetyClass'] as String? ?? 'safe'),
      argsSchema: json['argsSchema'] as Map<String, dynamic>?,
      description: json['description'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'action': action,
        'safetyClass': safetyClass.name,
        if (argsSchema != null) 'argsSchema': argsSchema,
        if (description != null) 'description': description,
      };
}

/// Full descriptor for an IO device.
class DeviceDescriptor {
  /// Unique device identifier.
  final String deviceId;

  /// Device manufacturer.
  final String manufacturer;

  /// Device model.
  final String model;

  /// Serial number.
  final String? serial;

  /// Firmware or software version.
  final String? version;

  /// Transport protocol identifier.
  final String transport;

  /// Current connection state.
  final IoConnectionState connectionState;

  /// List of capabilities this device supports.
  final List<CapabilityDescriptor> capabilities;

  /// Resource tree of channels and their resources.
  final List<ChannelDescriptor> resourceTree;

  const DeviceDescriptor({
    required this.deviceId,
    required this.manufacturer,
    required this.model,
    this.serial,
    this.version,
    required this.transport,
    this.connectionState = IoConnectionState.disconnected,
    this.capabilities = const [],
    this.resourceTree = const [],
  });

  /// Create from JSON.
  factory DeviceDescriptor.fromJson(Map<String, dynamic> json) {
    return DeviceDescriptor(
      deviceId: json['deviceId'] as String,
      manufacturer: json['manufacturer'] as String,
      model: json['model'] as String,
      serial: json['serial'] as String?,
      version: json['version'] as String?,
      transport: json['transport'] as String,
      connectionState: IoConnectionState.fromString(
          json['connectionState'] as String? ?? 'disconnected'),
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((e) =>
                  CapabilityDescriptor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      resourceTree: (json['resourceTree'] as List<dynamic>?)
              ?.map((e) =>
                  ChannelDescriptor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'manufacturer': manufacturer,
        'model': model,
        if (serial != null) 'serial': serial,
        if (version != null) 'version': version,
        'transport': transport,
        'connectionState': connectionState.name,
        if (capabilities.isNotEmpty)
          'capabilities': capabilities.map((c) => c.toJson()).toList(),
        if (resourceTree.isNotEmpty)
          'resourceTree': resourceTree.map((r) => r.toJson()).toList(),
      };
}

// ============================================================================
// Command / Read Types
// ============================================================================

/// Error information from an IO operation.
class IoError {
  /// Error code.
  final String code;

  /// Human-readable error message.
  final String message;

  /// When the error occurred.
  final DateTime timestamp;

  /// Additional error details.
  final Map<String, dynamic>? details;

  const IoError({
    required this.code,
    required this.message,
    required this.timestamp,
    this.details,
  });

  /// Create from JSON.
  factory IoError.fromJson(Map<String, dynamic> json) {
    return IoError(
      code: json['code'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        if (details != null) 'details': details,
      };
}

/// Evaluation result for a single policy condition.
class ConditionEvaluation {
  /// Rule identifier that was evaluated.
  final String ruleId;

  /// Whether the condition matched.
  final bool matched;

  /// Decision produced by this condition (if matched).
  final Decision? decision;

  const ConditionEvaluation({
    required this.ruleId,
    required this.matched,
    this.decision,
  });

  /// Create from JSON.
  factory ConditionEvaluation.fromJson(Map<String, dynamic> json) {
    return ConditionEvaluation(
      ruleId: json['ruleId'] as String,
      matched: json['matched'] as bool,
      decision: json['decision'] != null
          ? Decision.fromString(json['decision'] as String)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'ruleId': ruleId,
        'matched': matched,
        if (decision != null) 'decision': decision!.name,
      };
}

/// Trace of policy evaluation for a command.
class PolicyTrace {
  /// Command identifier that was evaluated.
  final String commandId;

  /// Rule identifier that produced the final decision.
  final String? ruleId;

  /// When the policy was evaluated.
  final DateTime evaluatedAt;

  /// Individual condition evaluations.
  final List<ConditionEvaluation> conditions;

  /// Final decision after all conditions.
  final Decision finalDecision;

  /// Notes about the final decision.
  final String? finalNotes;

  const PolicyTrace({
    required this.commandId,
    this.ruleId,
    required this.evaluatedAt,
    this.conditions = const [],
    required this.finalDecision,
    this.finalNotes,
  });

  /// Create from JSON.
  factory PolicyTrace.fromJson(Map<String, dynamic> json) {
    return PolicyTrace(
      commandId: json['commandId'] as String,
      ruleId: json['ruleId'] as String?,
      evaluatedAt: DateTime.parse(json['evaluatedAt'] as String),
      conditions: (json['conditions'] as List<dynamic>?)
              ?.map((e) =>
                  ConditionEvaluation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      finalDecision:
          Decision.fromString(json['finalDecision'] as String? ?? 'deny'),
      finalNotes: json['finalNotes'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'commandId': commandId,
        if (ruleId != null) 'ruleId': ruleId,
        'evaluatedAt': evaluatedAt.toIso8601String(),
        if (conditions.isNotEmpty)
          'conditions': conditions.map((c) => c.toJson()).toList(),
        'finalDecision': finalDecision.name,
        if (finalNotes != null) 'finalNotes': finalNotes,
      };
}

/// Command to execute on a device.
class Command {
  /// Action to perform.
  final String action;

  /// Target resource or channel URI.
  final String target;

  /// Arguments for the action.
  final Map<String, dynamic> args;

  /// Execution priority (lower = higher priority).
  final int? priority;

  /// Additional metadata.
  final Map<String, dynamic>? metadata;

  const Command({
    required this.action,
    required this.target,
    this.args = const {},
    this.priority,
    this.metadata,
  });

  /// Create from JSON.
  factory Command.fromJson(Map<String, dynamic> json) {
    return Command(
      action: json['action'] as String,
      target: json['target'] as String,
      args: json['args'] as Map<String, dynamic>? ?? {},
      priority: json['priority'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'action': action,
        'target': target,
        if (args.isNotEmpty) 'args': args,
        if (priority != null) 'priority': priority,
        if (metadata != null) 'metadata': metadata,
      };
}

/// Result of a command execution.
class CommandResult {
  /// Status of the command.
  final CommandStatus status;

  /// Result value (if completed successfully).
  final dynamic result;

  /// Error information (if failed).
  final IoError? error;

  /// Policy evaluation trace.
  final PolicyTrace? policyTrace;

  CommandResult({
    required this.status,
    this.result,
    this.error,
    this.policyTrace,
  });

  /// Create from JSON.
  factory CommandResult.fromJson(Map<String, dynamic> json) {
    return CommandResult(
      status:
          CommandStatus.fromString(json['status'] as String? ?? 'pending'),
      result: json['result'],
      error: json['error'] != null
          ? IoError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      policyTrace: json['policyTrace'] != null
          ? PolicyTrace.fromJson(
              json['policyTrace'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'status': status.name,
        if (result != null) 'result': result,
        if (error != null) 'error': error!.toJson(),
        if (policyTrace != null) 'policyTrace': policyTrace!.toJson(),
      };
}

/// Options for a read operation.
class ReadOptions {
  /// Timeout in milliseconds.
  final int? timeoutMs;

  /// Number of retry attempts.
  final int? retries;

  /// Downsample frequency in Hz.
  final double? downsampleHz;

  const ReadOptions({
    this.timeoutMs,
    this.retries,
    this.downsampleHz,
  });

  /// Create from JSON.
  factory ReadOptions.fromJson(Map<String, dynamic> json) {
    return ReadOptions(
      timeoutMs: json['timeoutMs'] as int?,
      retries: json['retries'] as int?,
      downsampleHz: (json['downsampleHz'] as num?)?.toDouble(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        if (timeoutMs != null) 'timeoutMs': timeoutMs,
        if (retries != null) 'retries': retries,
        if (downsampleHz != null) 'downsampleHz': downsampleHz,
      };
}

/// Specification for a read operation.
class ReadSpec {
  /// Target resource URIs to read.
  final List<String> targets;

  /// Read options.
  final ReadOptions? options;

  const ReadSpec({
    required this.targets,
    this.options,
  });

  /// Create from JSON.
  factory ReadSpec.fromJson(Map<String, dynamic> json) {
    return ReadSpec(
      targets: (json['targets'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      options: json['options'] != null
          ? ReadOptions.fromJson(json['options'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'targets': targets,
        if (options != null) 'options': options!.toJson(),
      };
}

/// Single item in a read result.
class ReadResultItem {
  /// Resource URI that was read.
  final String uri;

  /// Payload envelope (if read succeeded).
  final PayloadEnvelope? envelope;

  /// Error information (if read failed).
  final IoError? error;

  const ReadResultItem({
    required this.uri,
    this.envelope,
    this.error,
  });

  /// Create from JSON.
  factory ReadResultItem.fromJson(Map<String, dynamic> json) {
    return ReadResultItem(
      uri: json['uri'] as String,
      envelope: json['envelope'] != null
          ? PayloadEnvelope.fromJson(
              json['envelope'] as Map<String, dynamic>)
          : null,
      error: json['error'] != null
          ? IoError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'uri': uri,
        if (envelope != null) 'envelope': envelope!.toJson(),
        if (error != null) 'error': error!.toJson(),
      };
}

/// Timing information for a read operation.
class ReadTiming {
  /// Total time for the read operation.
  final Duration total;

  /// Fastest individual read.
  final Duration? fastest;

  /// Slowest individual read.
  final Duration? slowest;

  ReadTiming({
    required this.total,
    this.fastest,
    this.slowest,
  });

  /// Create from JSON.
  factory ReadTiming.fromJson(Map<String, dynamic> json) {
    return ReadTiming(
      total: Duration(milliseconds: json['totalMs'] as int? ?? 0),
      fastest: json['fastestMs'] != null
          ? Duration(milliseconds: json['fastestMs'] as int)
          : null,
      slowest: json['slowestMs'] != null
          ? Duration(milliseconds: json['slowestMs'] as int)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'totalMs': total.inMilliseconds,
        if (fastest != null) 'fastestMs': fastest!.inMilliseconds,
        if (slowest != null) 'slowestMs': slowest!.inMilliseconds,
      };
}

/// Result of a read operation.
class ReadResult {
  /// Individual read result items.
  final List<ReadResultItem> items;

  /// Timing information.
  final ReadTiming? timing;

  const ReadResult({
    this.items = const [],
    this.timing,
  });

  /// Create from JSON.
  factory ReadResult.fromJson(Map<String, dynamic> json) {
    return ReadResult(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  ReadResultItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timing: json['timing'] != null
          ? ReadTiming.fromJson(json['timing'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        if (items.isNotEmpty)
          'items': items.map((i) => i.toJson()).toList(),
        if (timing != null) 'timing': timing!.toJson(),
      };
}

// ============================================================================
// Topic / Subscription Types
// ============================================================================

/// Options for a topic subscription.
class TopicOptions {
  /// Polling interval in milliseconds (for poll mode).
  final int? intervalMs;

  /// Maximum buffer size.
  final int? bufferSize;

  /// Backpressure handling policy.
  final BackpressurePolicy? backpressure;

  /// Time-to-live in seconds for buffered messages.
  final int? ttlSeconds;

  const TopicOptions({
    this.intervalMs,
    this.bufferSize,
    this.backpressure,
    this.ttlSeconds,
  });

  /// Create from JSON.
  factory TopicOptions.fromJson(Map<String, dynamic> json) {
    return TopicOptions(
      intervalMs: json['intervalMs'] as int?,
      bufferSize: json['bufferSize'] as int?,
      backpressure: json['backpressure'] != null
          ? BackpressurePolicy.fromString(json['backpressure'] as String)
          : null,
      ttlSeconds: json['ttlSeconds'] as int?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        if (intervalMs != null) 'intervalMs': intervalMs,
        if (bufferSize != null) 'bufferSize': bufferSize,
        if (backpressure != null) 'backpressure': backpressure!.name,
        if (ttlSeconds != null) 'ttlSeconds': ttlSeconds,
      };
}

/// Specification for a topic subscription.
class TopicSpec {
  /// Resource URI to subscribe to.
  final String uri;

  /// Delivery mode for the subscription.
  final TopicMode mode;

  /// Subscription options.
  final TopicOptions? options;

  const TopicSpec({
    required this.uri,
    required this.mode,
    this.options,
  });

  /// Create from JSON.
  factory TopicSpec.fromJson(Map<String, dynamic> json) {
    return TopicSpec(
      uri: json['uri'] as String,
      mode: TopicMode.fromString(json['mode'] as String? ?? 'continuous'),
      options: json['options'] != null
          ? TopicOptions.fromJson(json['options'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'uri': uri,
        'mode': mode.name,
        if (options != null) 'options': options!.toJson(),
      };
}

// ============================================================================
// Safety / Policy Types
// ============================================================================

/// Request to perform an emergency stop.
class EmergencyStopRequest {
  /// Specific device to stop (null = all devices).
  final String? deviceId;

  /// Reason for the emergency stop.
  final String reason;

  /// Actor who initiated the stop.
  final String actorId;

  const EmergencyStopRequest({
    this.deviceId,
    required this.reason,
    required this.actorId,
  });

  /// Create from JSON.
  factory EmergencyStopRequest.fromJson(Map<String, dynamic> json) {
    return EmergencyStopRequest(
      deviceId: json['deviceId'] as String?,
      reason: json['reason'] as String,
      actorId: json['actorId'] as String,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        if (deviceId != null) 'deviceId': deviceId,
        'reason': reason,
        'actorId': actorId,
      };
}

/// Result of an emergency stop operation.
class EmergencyStopResult {
  /// Whether the emergency stop was successful.
  final bool success;

  /// List of device IDs that were stopped.
  final List<String> stoppedDevices;

  /// Error information (if the stop failed).
  final IoError? error;

  const EmergencyStopResult({
    required this.success,
    this.stoppedDevices = const [],
    this.error,
  });

  /// Create from JSON.
  factory EmergencyStopResult.fromJson(Map<String, dynamic> json) {
    return EmergencyStopResult(
      success: json['success'] as bool,
      stoppedDevices: (json['stoppedDevices'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      error: json['error'] != null
          ? IoError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'success': success,
        if (stoppedDevices.isNotEmpty) 'stoppedDevices': stoppedDevices,
        if (error != null) 'error': error!.toJson(),
      };
}

// ============================================================================
// IoDevicePort Interface
// ============================================================================

/// Abstract port for IO device communication.
///
/// Provides a unified interface for interacting with hardware devices
/// including reading sensor data, executing commands, subscribing to
/// real-time data streams, and performing emergency stops.
abstract class IoDevicePort {
  // --- Lifecycle ---

  /// Establish connection to the device. Idempotent.
  Future<void> connect();

  /// Disconnect from the device and release resources.
  Future<void> disconnect();

  // --- 4-Primitive Contract ---

  /// Describe the device and its resource tree.
  Future<DeviceDescriptor> describe();

  /// Read one or more resources from the device.
  Future<ReadResult> read(ReadSpec spec);

  /// Execute a command on the device.
  Future<CommandResult> execute(Command command);

  /// Subscribe to a topic for real-time data delivery.
  Stream<PayloadEnvelope> subscribe(TopicSpec spec);

  /// Perform an emergency stop on the device.
  Future<EmergencyStopResult> emergencyStop(EmergencyStopRequest request);
}

// ============================================================================
// Stub Implementation
// ============================================================================

/// Stub implementation of IoDevicePort for testing.
class StubIoDevicePort implements IoDevicePort {
  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<DeviceDescriptor> describe() async {
    return const DeviceDescriptor(
      deviceId: 'stub-device',
      manufacturer: 'Stub',
      model: 'StubModel',
      transport: 'custom',
      connectionState: IoConnectionState.connected,
    );
  }

  @override
  Future<ReadResult> read(ReadSpec spec) async {
    return const ReadResult();
  }

  @override
  Future<CommandResult> execute(Command command) async {
    return CommandResult(
      status: CommandStatus.completed,
    );
  }

  @override
  Stream<PayloadEnvelope> subscribe(TopicSpec spec) {
    return const Stream.empty();
  }

  @override
  Future<EmergencyStopResult> emergencyStop(
      EmergencyStopRequest request) async {
    return const EmergencyStopResult(
      success: true,
    );
  }
}
