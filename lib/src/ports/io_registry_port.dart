/// IO Registry Port - Device and adapter registry interface.
///
/// This port provides a unified interface for discovering, registering,
/// and managing IO device adapters across the MCP ecosystem:
/// - Adapter registration with manifest-based contracts
/// - Device discovery across multiple transports
/// - Device lifecycle event streaming
/// - Adapter resolution by device URI
library;

import 'dart:async';

import 'io_device_port.dart';

// ============================================================================
// Registry Event Type
// ============================================================================

/// Type of registry lifecycle event.
enum RegistryEventType {
  /// A device was registered in the registry.
  deviceRegistered,

  /// A device was unregistered from the registry.
  deviceUnregistered,

  /// A device established a connection.
  deviceConnected,

  /// A device lost its connection.
  deviceDisconnected,

  /// A device encountered an error.
  deviceError,

  /// An adapter was registered in the registry.
  adapterRegistered,

  /// An adapter was unregistered from the registry.
  adapterUnregistered;

  /// Parse a [RegistryEventType] from its string name.
  static RegistryEventType fromString(String value) {
    return RegistryEventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RegistryEventType.deviceError,
    );
  }
}

// ============================================================================
// Adapter Manifest
// ============================================================================

/// Manifest describing an IO adapter's identity, capabilities, and constraints.
class AdapterManifest {
  /// Unique adapter identifier.
  final String adapterId;

  /// Semantic version of the adapter implementation.
  final String adapterVersion;

  /// Semver range of the contract this adapter supports (e.g., ">=0.1.0 <1.0.0").
  final String contractVersionRange;

  /// Human-readable display name.
  final String displayName;

  /// Optional description of the adapter.
  final String? description;

  /// Transport types this adapter can use.
  final List<TransportDescriptor> transports;

  /// Device matching rules for auto-discovery.
  final List<DeviceMatcher> matchers;

  /// Capabilities exposed by this adapter.
  final List<CapabilityDescriptor> capabilities;

  /// Optional concurrency constraints.
  final ConcurrencyDescriptor? concurrency;

  AdapterManifest({
    required this.adapterId,
    required this.adapterVersion,
    required this.contractVersionRange,
    required this.displayName,
    this.description,
    this.transports = const [],
    this.matchers = const [],
    this.capabilities = const [],
    this.concurrency,
  });

  /// Create from JSON.
  factory AdapterManifest.fromJson(Map<String, dynamic> json) {
    return AdapterManifest(
      adapterId: json['adapterId'] as String,
      adapterVersion: json['adapterVersion'] as String,
      contractVersionRange: json['contractVersionRange'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String?,
      transports: (json['transports'] as List<dynamic>?)
              ?.map(
                  (e) => TransportDescriptor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      matchers: (json['matchers'] as List<dynamic>?)
              ?.map((e) => DeviceMatcher.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((e) =>
                  CapabilityDescriptor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      concurrency: json['concurrency'] != null
          ? ConcurrencyDescriptor.fromJson(
              json['concurrency'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'adapterId': adapterId,
        'adapterVersion': adapterVersion,
        'contractVersionRange': contractVersionRange,
        'displayName': displayName,
        if (description != null) 'description': description,
        if (transports.isNotEmpty)
          'transports': transports.map((t) => t.toJson()).toList(),
        if (matchers.isNotEmpty)
          'matchers': matchers.map((m) => m.toJson()).toList(),
        if (capabilities.isNotEmpty)
          'capabilities': capabilities.map((c) => c.toJson()).toList(),
        if (concurrency != null) 'concurrency': concurrency!.toJson(),
      };
}

// ============================================================================
// Transport Descriptor
// ============================================================================

/// Describes a transport type and its default configuration.
class TransportDescriptor {
  /// The transport type.
  final TransportType type;

  /// Default configuration values for this transport.
  final Map<String, dynamic>? defaults;

  TransportDescriptor({
    required this.type,
    this.defaults,
  });

  /// Create from JSON.
  factory TransportDescriptor.fromJson(Map<String, dynamic> json) {
    return TransportDescriptor(
      type: TransportType.fromString(json['type'] as String),
      defaults: json['defaults'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (defaults != null) 'defaults': defaults,
      };
}

// ============================================================================
// Device Matcher
// ============================================================================

/// Rule for matching a device during auto-discovery.
class DeviceMatcher {
  /// Matcher type (e.g., idn_query, serial_pattern, mac_address, ros_topic).
  final String type;

  /// Pattern to match against.
  final String pattern;

  /// Optional context for the match operation.
  final Map<String, dynamic>? context;

  DeviceMatcher({
    required this.type,
    required this.pattern,
    this.context,
  });

  /// Create from JSON.
  factory DeviceMatcher.fromJson(Map<String, dynamic> json) {
    return DeviceMatcher(
      type: json['type'] as String,
      pattern: json['pattern'] as String,
      context: json['context'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'type': type,
        'pattern': pattern,
        if (context != null) 'context': context,
      };
}

// ============================================================================
// Concurrency Descriptor
// ============================================================================

/// Describes concurrency constraints for an adapter.
class ConcurrencyDescriptor {
  /// Maximum number of commands that can execute concurrently.
  final int maxConcurrentCommands;

  /// Whether parallel read operations are supported.
  final bool supportsParallelReads;

  const ConcurrencyDescriptor({
    required this.maxConcurrentCommands,
    this.supportsParallelReads = false,
  });

  /// Create from JSON.
  factory ConcurrencyDescriptor.fromJson(Map<String, dynamic> json) {
    return ConcurrencyDescriptor(
      maxConcurrentCommands: json['maxConcurrentCommands'] as int,
      supportsParallelReads: json['supportsParallelReads'] as bool? ?? false,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'maxConcurrentCommands': maxConcurrentCommands,
        'supportsParallelReads': supportsParallelReads,
      };
}

// ============================================================================
// Registry Event
// ============================================================================

/// Event emitted by the registry when device or adapter state changes.
class RegistryEvent {
  /// Type of the registry event.
  final RegistryEventType type;

  /// Identifier of the device involved.
  final String deviceId;

  /// Identifier of the adapter involved (if applicable).
  final String? adapterId;

  /// When the event occurred.
  final DateTime timestamp;

  const RegistryEvent({
    required this.type,
    required this.deviceId,
    this.adapterId,
    required this.timestamp,
  });

  /// Create from JSON.
  factory RegistryEvent.fromJson(Map<String, dynamic> json) {
    return RegistryEvent(
      type: RegistryEventType.fromString(json['type'] as String),
      deviceId: json['deviceId'] as String,
      adapterId: json['adapterId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'deviceId': deviceId,
        if (adapterId != null) 'adapterId': adapterId,
        'timestamp': timestamp.toIso8601String(),
      };
}

// ============================================================================
// IO Registry Port Interface
// ============================================================================

/// Abstract port for device and adapter registry operations.
///
/// Provides a central registry for discovering IO devices, registering
/// adapters by manifest, and streaming lifecycle events.
abstract class IoRegistryPort {
  /// Register an adapter with its manifest.
  Future<void> registerAdapter(AdapterManifest manifest, IoDevicePort adapter);

  /// Unregister an adapter by its identifier.
  Future<void> unregisterAdapter(String adapterId);

  /// Discover available devices, optionally filtered by transport.
  Future<List<DeviceDescriptor>> discover({
    String? transportFilter,
    Duration? timeout,
  });

  /// List known devices, optionally filtered by connection state.
  Future<List<DeviceDescriptor>> list({IoConnectionState? stateFilter});

  /// Get a specific device descriptor by its identifier.
  Future<DeviceDescriptor?> get(String deviceId);

  /// Resolve the adapter responsible for the given device URI.
  Future<IoDevicePort?> resolveAdapter(String uri);

  /// Stream of registry lifecycle events.
  Stream<RegistryEvent> get events;
}

// ============================================================================
// Stub Implementation
// ============================================================================

/// Stub implementation of [IoRegistryPort] for testing.
class StubIoRegistryPort implements IoRegistryPort {
  final _controller = StreamController<RegistryEvent>.broadcast();
  final Map<String, DeviceDescriptor> _devices = {};
  final Map<String, IoDevicePort> _adapters = {};

  @override
  Future<void> registerAdapter(
    AdapterManifest manifest,
    IoDevicePort adapter,
  ) async {
    _adapters[manifest.adapterId] = adapter;
  }

  @override
  Future<void> unregisterAdapter(String adapterId) async {
    _adapters.remove(adapterId);
  }

  @override
  Future<List<DeviceDescriptor>> discover({
    String? transportFilter,
    Duration? timeout,
  }) async {
    return _devices.values.toList();
  }

  @override
  Future<List<DeviceDescriptor>> list({IoConnectionState? stateFilter}) async {
    if (stateFilter == null) {
      return _devices.values.toList();
    }
    return _devices.values
        .where((d) => d.connectionState == stateFilter)
        .toList();
  }

  @override
  Future<DeviceDescriptor?> get(String deviceId) async {
    return _devices[deviceId];
  }

  @override
  Future<IoDevicePort?> resolveAdapter(String uri) async {
    return null;
  }

  @override
  Stream<RegistryEvent> get events => _controller.stream;

  /// Dispose the event stream controller.
  void dispose() {
    _controller.close();
  }
}
