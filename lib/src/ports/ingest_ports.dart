/// Ingest Ports - OCR, ASR, Vision, and Binary Storage interfaces.
///
/// These ports are used by mcp_ingest and can be implemented by:
/// - Native plugins (local processing, free)
/// - Cloud APIs (mcp_llm providers, paid)
library;

import 'dart:typed_data';

import 'llm_port.dart';

// =============================================================================
// OcrPort
// =============================================================================

/// OCR processing options.
class OcrOptions {
  /// Language code (e.g., 'eng', 'kor', 'jpn').
  final String language;

  /// Page segmentation mode.
  final int? pageSegMode;

  /// Whether to preserve layout.
  final bool preserveLayout;

  const OcrOptions({
    this.language = 'eng',
    this.pageSegMode,
    this.preserveLayout = false,
  });
}

/// OCR recognition result.
class OcrResult {
  /// Recognized text.
  final String text;

  /// Confidence score (0.0 - 1.0).
  final double confidence;

  /// Detected language.
  final String? language;

  /// Text regions with bounding boxes.
  final List<OcrRegion>? regions;

  /// Processing time.
  final Duration processingTime;

  const OcrResult({
    required this.text,
    required this.confidence,
    this.language,
    this.regions,
    required this.processingTime,
  });
}

/// OCR region with position.
class OcrRegion {
  /// Region text.
  final String text;

  /// Confidence score.
  final double confidence;

  /// Bounding box.
  final BoundingBox boundingBox;

  const OcrRegion({
    required this.text,
    required this.confidence,
    required this.boundingBox,
  });
}

/// Bounding box for visual elements.
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

/// Port for OCR operations.
abstract interface class OcrPort {
  /// Recognize text from image bytes.
  Future<OcrResult> recognize(
    Stream<List<int>> imageData,
    OcrOptions options,
  );

  /// Check if the OCR engine is available.
  Future<bool> isAvailable();

  /// Get supported languages.
  Future<List<String>> supportedLanguages();
}

/// Stub OCR port for testing.
class StubOcrPort implements OcrPort {
  @override
  Future<OcrResult> recognize(
      Stream<List<int>> imageData, OcrOptions options) async {
    return const OcrResult(
      text: '',
      confidence: 0.0,
      processingTime: Duration.zero,
    );
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<String>> supportedLanguages() async => ['eng'];
}

// =============================================================================
// AsrPort
// =============================================================================

/// ASR processing options.
class AsrOptions {
  /// Language code (e.g., 'en', 'ko', 'ja').
  final String language;

  /// Whether to include word-level timestamps.
  final bool wordTimestamps;

  /// Whether to translate to English.
  final bool translate;

  /// Whether to enable speaker diarization.
  final bool enableDiarization;

  /// Maximum number of speakers to detect (for diarization).
  final int? maxSpeakers;

  /// Model size hint (tiny, base, small, medium, large).
  final String? modelSize;

  const AsrOptions({
    this.language = 'en',
    this.wordTimestamps = false,
    this.translate = false,
    this.enableDiarization = false,
    this.maxSpeakers,
    this.modelSize,
  });
}

/// ASR transcription result.
class AsrResult {
  /// Full transcribed text.
  final String text;

  /// Confidence score (0.0 - 1.0).
  final double confidence;

  /// Language detected or used.
  final String? language;

  /// Transcript segments with timestamps.
  final List<AsrSegment>? segments;

  /// Audio duration.
  final Duration audioDuration;

  /// Processing time.
  final Duration processingTime;

  const AsrResult({
    required this.text,
    required this.confidence,
    this.language,
    this.segments,
    required this.audioDuration,
    required this.processingTime,
  });
}

/// Single transcription segment.
class AsrSegment {
  /// Segment text.
  final String text;

  /// Start time.
  final Duration startTime;

  /// End time.
  final Duration endTime;

  /// Confidence score.
  final double confidence;

  /// Speaker identifier for diarization (null if not supported/enabled).
  final String? speakerId;

  const AsrSegment({
    required this.text,
    required this.startTime,
    required this.endTime,
    required this.confidence,
    this.speakerId,
  });
}

/// Port for ASR operations.
abstract interface class AsrPort {
  /// Transcribe audio stream.
  Future<AsrResult> transcribe(
    Stream<List<int>> audioData,
    AsrOptions options,
  );

  /// Check if the ASR engine is available.
  Future<bool> isAvailable();

  /// Get supported languages.
  Future<List<String>> supportedLanguages();
}

/// Stub ASR port for testing.
class StubAsrPort implements AsrPort {
  @override
  Future<AsrResult> transcribe(
      Stream<List<int>> audioData, AsrOptions options) async {
    return const AsrResult(
      text: '',
      confidence: 0.0,
      audioDuration: Duration.zero,
      processingTime: Duration.zero,
    );
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<String>> supportedLanguages() async => ['en'];
}

// =============================================================================
// VisionPort
// =============================================================================

/// Vision processing options.
class VisionOptions {
  /// Whether to generate detailed description.
  final bool detailed;

  /// Whether to detect objects.
  final bool detectObjects;

  /// Whether to detect faces.
  final bool detectFaces;

  /// Whether to extract text (separate from OCR).
  final bool extractText;

  /// Custom prompt for analysis.
  final String? prompt;

  const VisionOptions({
    this.detailed = true,
    this.detectObjects = false,
    this.detectFaces = false,
    this.extractText = false,
    this.prompt,
  });
}

/// Vision analysis result.
class VisionResult {
  /// Text description of the image.
  final String description;

  /// Detected objects/labels.
  final List<VisionLabel>? labels;

  /// Detected text (OCR).
  final String? text;

  /// Detected faces.
  final List<VisionFace>? faces;

  /// Confidence score (0.0 - 1.0).
  final double confidence;

  /// Processing time.
  final Duration processingTime;

  const VisionResult({
    required this.description,
    this.labels,
    this.text,
    this.faces,
    required this.confidence,
    required this.processingTime,
  });
}

/// Vision label/object.
class VisionLabel {
  final String name;
  final double confidence;
  final BoundingBox? boundingBox;

  const VisionLabel({
    required this.name,
    required this.confidence,
    this.boundingBox,
  });
}

/// Vision face detection.
class VisionFace {
  final BoundingBox boundingBox;
  final double confidence;
  final Map<String, double>? emotions;

  const VisionFace({
    required this.boundingBox,
    required this.confidence,
    this.emotions,
  });
}

/// Port for vision analysis operations.
abstract interface class VisionPort {
  /// Analyze and describe an image.
  Future<VisionResult> describe(
    Stream<List<int>> imageData,
    VisionOptions options,
  );

  /// Check if the vision engine is available.
  Future<bool> isAvailable();
}

/// Stub Vision port for testing.
class StubVisionPort implements VisionPort {
  @override
  Future<VisionResult> describe(
      Stream<List<int>> imageData, VisionOptions options) async {
    return const VisionResult(
      description: '',
      confidence: 0.0,
      processingTime: Duration.zero,
    );
  }

  @override
  Future<bool> isAvailable() async => true;
}

// =============================================================================
// BinaryStoragePort
// =============================================================================

/// Storage options.
class StorageOptions {
  /// Content-addressable storage (use hash as key).
  final bool contentAddressable;

  /// Custom prefix for keys.
  final String? prefix;

  /// TTL in seconds (0 = no expiry).
  final int ttlSeconds;

  const StorageOptions({
    this.contentAddressable = true,
    this.prefix,
    this.ttlSeconds = 0,
  });
}

/// Storage metadata.
class StorageMetadata {
  /// Storage key/reference.
  final String key;

  /// MIME type.
  final String mimeType;

  /// Size in bytes.
  final int size;

  /// SHA-256 hash.
  final String sha256;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Expiry timestamp (if applicable).
  final DateTime? expiresAt;

  const StorageMetadata({
    required this.key,
    required this.mimeType,
    required this.size,
    required this.sha256,
    required this.createdAt,
    this.expiresAt,
  });
}

/// Port for binary asset storage.
abstract interface class BinaryStoragePort {
  /// Store binary data and return a reference.
  Future<String> store(
    Stream<List<int>> data,
    String mimeType, [
    StorageOptions options = const StorageOptions(),
  ]);

  /// Retrieve binary data by reference.
  Future<Uint8List> retrieve(String reference);

  /// Check if a reference exists.
  Future<bool> exists(String reference);

  /// Get metadata for a reference.
  Future<StorageMetadata?> metadata(String reference);

  /// Delete a stored asset.
  Future<bool> delete(String reference);

  /// List all stored references with optional prefix.
  Future<List<String>> list([String? prefix]);
}

/// In-memory binary storage for testing.
class InMemoryBinaryStoragePort implements BinaryStoragePort {
  final Map<String, List<int>> _data = {};
  final Map<String, StorageMetadata> _metadata = {};

  @override
  Future<String> store(
    Stream<List<int>> data,
    String mimeType, [
    StorageOptions options = const StorageOptions(),
  ]) async {
    final bytes = <int>[];
    await for (final chunk in data) {
      bytes.addAll(chunk);
    }
    final id = 'mem://${DateTime.now().millisecondsSinceEpoch}';
    _data[id] = bytes;
    _metadata[id] = StorageMetadata(
      key: id,
      mimeType: mimeType,
      size: bytes.length,
      sha256: '',
      createdAt: DateTime.now(),
    );
    return id;
  }

  @override
  Future<Uint8List> retrieve(String reference) async {
    final data = _data[reference];
    if (data == null) throw Exception('Not found: $reference');
    return Uint8List.fromList(data);
  }

  @override
  Future<bool> exists(String reference) async => _data.containsKey(reference);

  @override
  Future<StorageMetadata?> metadata(String reference) async =>
      _metadata[reference];

  @override
  Future<bool> delete(String reference) async {
    _data.remove(reference);
    _metadata.remove(reference);
    return true;
  }

  @override
  Future<List<String>> list([String? prefix]) async {
    if (prefix == null) return _data.keys.toList();
    return _data.keys.where((k) => k.startsWith(prefix)).toList();
  }
}

// =============================================================================
// IngestPorts Bundle
// =============================================================================

/// Bundle of all ingest-related ports.
class IngestPorts {
  /// OCR port for text extraction from images.
  final OcrPort? ocr;

  /// ASR port for audio transcription.
  final AsrPort? asr;

  /// Vision port for image analysis.
  final VisionPort? vision;

  /// Storage port for binary assets.
  final BinaryStoragePort? storage;

  /// LLM port for semantic processing.
  final LlmPort? llm;

  const IngestPorts({
    this.ocr,
    this.asr,
    this.vision,
    this.storage,
    this.llm,
  });

  /// Check if OCR is available.
  Future<bool> get hasOcr async => ocr != null && await ocr!.isAvailable();

  /// Check if ASR is available.
  Future<bool> get hasAsr async => asr != null && await asr!.isAvailable();

  /// Check if Vision is available.
  Future<bool> get hasVision async =>
      vision != null && await vision!.isAvailable();

  /// Check if storage is available.
  bool get hasStorage => storage != null;

  /// Check if LLM is available.
  bool get hasLlm => llm != null;

  /// Empty ports (no capabilities).
  static const IngestPorts empty = IngestPorts();

  /// Create with stubs for testing.
  factory IngestPorts.stubs() {
    return IngestPorts(
      ocr: StubOcrPort(),
      asr: StubAsrPort(),
      vision: StubVisionPort(),
      storage: InMemoryBinaryStoragePort(),
    );
  }
}
