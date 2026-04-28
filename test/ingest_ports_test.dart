import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:mcp_bundle/ports.dart';

void main() {
  group('OcrPort', () {
    group('OcrOptions', () {
      test('creates with defaults', () {
        const options = OcrOptions();
        expect(options.language, equals('eng'));
        expect(options.pageSegMode, isNull);
        expect(options.preserveLayout, isFalse);
      });

      test('creates with custom values', () {
        const options = OcrOptions(
          language: 'kor',
          pageSegMode: 6,
          preserveLayout: true,
        );
        expect(options.language, equals('kor'));
        expect(options.pageSegMode, equals(6));
        expect(options.preserveLayout, isTrue);
      });
    });

    group('OcrResult', () {
      test('creates with required fields', () {
        const result = OcrResult(
          text: 'Hello World',
          confidence: 0.95,
          processingTime: Duration(milliseconds: 100),
        );
        expect(result.text, equals('Hello World'));
        expect(result.confidence, equals(0.95));
        expect(result.processingTime, equals(const Duration(milliseconds: 100)));
        expect(result.language, isNull);
        expect(result.regions, isNull);
      });

      test('creates with all fields', () {
        const result = OcrResult(
          text: 'Hello',
          confidence: 0.9,
          language: 'eng',
          regions: [
            OcrRegion(
              text: 'Hello',
              confidence: 0.9,
              boundingBox: BoundingBox(x: 0, y: 0, width: 100, height: 20),
            ),
          ],
          processingTime: Duration(seconds: 1),
        );
        expect(result.language, equals('eng'));
        expect(result.regions?.length, equals(1));
      });
    });

    group('OcrRegion', () {
      test('creates with required fields', () {
        const region = OcrRegion(
          text: 'Word',
          confidence: 0.85,
          boundingBox: BoundingBox(x: 10, y: 20, width: 50, height: 15),
        );
        expect(region.text, equals('Word'));
        expect(region.confidence, equals(0.85));
        expect(region.boundingBox.x, equals(10));
        expect(region.boundingBox.y, equals(20));
        expect(region.boundingBox.width, equals(50));
        expect(region.boundingBox.height, equals(15));
      });
    });

    group('BoundingBox', () {
      test('creates with required fields', () {
        const bbox = BoundingBox(x: 0, y: 0, width: 100, height: 100);
        expect(bbox.x, equals(0));
        expect(bbox.y, equals(0));
        expect(bbox.width, equals(100));
        expect(bbox.height, equals(100));
      });
    });

    group('StubOcrPort', () {
      test('isAvailable returns true', () async {
        final port = StubOcrPort();
        expect(await port.isAvailable(), isTrue);
      });

      test('supportedLanguages returns eng', () async {
        final port = StubOcrPort();
        final langs = await port.supportedLanguages();
        expect(langs, contains('eng'));
      });

      test('recognize returns empty result', () async {
        final port = StubOcrPort();
        final result = await port.recognize(
          Stream.value([1, 2, 3]),
          const OcrOptions(),
        );
        expect(result.text, isEmpty);
        expect(result.confidence, equals(0.0));
        expect(result.processingTime, equals(Duration.zero));
      });
    });
  });

  group('AsrPort', () {
    group('AsrOptions', () {
      test('creates with defaults', () {
        const options = AsrOptions();
        expect(options.language, equals('en'));
        expect(options.wordTimestamps, isFalse);
        expect(options.translate, isFalse);
        expect(options.enableDiarization, isFalse);
        expect(options.maxSpeakers, isNull);
        expect(options.modelSize, isNull);
      });

      test('creates with diarization enabled', () {
        const options = AsrOptions(
          language: 'ko',
          enableDiarization: true,
          maxSpeakers: 3,
          modelSize: 'large',
        );
        expect(options.language, equals('ko'));
        expect(options.enableDiarization, isTrue);
        expect(options.maxSpeakers, equals(3));
        expect(options.modelSize, equals('large'));
      });
    });

    group('AsrResult', () {
      test('creates with required fields', () {
        const result = AsrResult(
          text: 'Hello World',
          confidence: 0.95,
          audioDuration: Duration(seconds: 5),
          processingTime: Duration(seconds: 2),
        );
        expect(result.text, equals('Hello World'));
        expect(result.confidence, equals(0.95));
        expect(result.audioDuration, equals(const Duration(seconds: 5)));
        expect(result.processingTime, equals(const Duration(seconds: 2)));
        expect(result.language, isNull);
        expect(result.segments, isNull);
      });

      test('creates with segments', () {
        const result = AsrResult(
          text: 'Hello World',
          confidence: 0.9,
          language: 'en',
          segments: [
            AsrSegment(
              text: 'Hello',
              startTime: Duration.zero,
              endTime: Duration(milliseconds: 500),
              confidence: 0.95,
            ),
            AsrSegment(
              text: 'World',
              startTime: Duration(milliseconds: 600),
              endTime: Duration(milliseconds: 1000),
              confidence: 0.92,
              speakerId: 'SPEAKER_00',
            ),
          ],
          audioDuration: Duration(seconds: 1),
          processingTime: Duration(milliseconds: 500),
        );
        expect(result.language, equals('en'));
        expect(result.segments?.length, equals(2));
        expect(result.segments?.last.speakerId, equals('SPEAKER_00'));
      });
    });

    group('AsrSegment', () {
      test('creates with Duration timestamps', () {
        const segment = AsrSegment(
          text: 'Test',
          startTime: Duration(milliseconds: 1500),
          endTime: Duration(milliseconds: 2500),
          confidence: 0.88,
        );
        expect(segment.text, equals('Test'));
        expect(segment.startTime, equals(const Duration(milliseconds: 1500)));
        expect(segment.endTime, equals(const Duration(milliseconds: 2500)));
        expect(segment.confidence, equals(0.88));
        expect(segment.speakerId, isNull);
      });

      test('creates with speaker ID for diarization', () {
        const segment = AsrSegment(
          text: 'Hello',
          startTime: Duration.zero,
          endTime: Duration(seconds: 1),
          confidence: 0.9,
          speakerId: 'SPEAKER_01',
        );
        expect(segment.speakerId, equals('SPEAKER_01'));
      });
    });

    group('StubAsrPort', () {
      test('isAvailable returns true', () async {
        final port = StubAsrPort();
        expect(await port.isAvailable(), isTrue);
      });

      test('supportedLanguages returns en', () async {
        final port = StubAsrPort();
        final langs = await port.supportedLanguages();
        expect(langs, contains('en'));
      });

      test('transcribe returns empty result', () async {
        final port = StubAsrPort();
        final result = await port.transcribe(
          Stream.value([1, 2, 3]),
          const AsrOptions(),
        );
        expect(result.text, isEmpty);
        expect(result.confidence, equals(0.0));
        expect(result.audioDuration, equals(Duration.zero));
        expect(result.processingTime, equals(Duration.zero));
      });
    });
  });

  group('VisionPort', () {
    group('VisionOptions', () {
      test('creates with defaults', () {
        const options = VisionOptions();
        expect(options.detailed, isTrue);
        expect(options.detectObjects, isFalse);
        expect(options.detectFaces, isFalse);
        expect(options.extractText, isFalse);
        expect(options.prompt, isNull);
      });

      test('creates with all features enabled', () {
        const options = VisionOptions(
          detailed: true,
          detectObjects: true,
          detectFaces: true,
          extractText: true,
          prompt: 'Describe this image',
        );
        expect(options.detectObjects, isTrue);
        expect(options.detectFaces, isTrue);
        expect(options.extractText, isTrue);
        expect(options.prompt, equals('Describe this image'));
      });
    });

    group('VisionResult', () {
      test('creates with required fields', () {
        const result = VisionResult(
          description: 'A photo of a cat',
          confidence: 0.95,
          processingTime: Duration(milliseconds: 200),
        );
        expect(result.description, equals('A photo of a cat'));
        expect(result.confidence, equals(0.95));
        expect(result.processingTime, equals(const Duration(milliseconds: 200)));
        expect(result.labels, isNull);
        expect(result.text, isNull);
        expect(result.faces, isNull);
      });

      test('creates with labels and faces', () {
        const result = VisionResult(
          description: 'A person smiling',
          labels: [
            VisionLabel(name: 'person', confidence: 0.98),
            VisionLabel(
              name: 'smile',
              confidence: 0.85,
              boundingBox: BoundingBox(x: 50, y: 50, width: 100, height: 50),
            ),
          ],
          faces: [
            VisionFace(
              boundingBox: BoundingBox(x: 40, y: 30, width: 120, height: 150),
              confidence: 0.99,
              emotions: {'happy': 0.9, 'neutral': 0.1},
            ),
          ],
          confidence: 0.95,
          processingTime: Duration(seconds: 1),
        );
        expect(result.labels?.length, equals(2));
        expect(result.faces?.length, equals(1));
        expect(result.faces?.first.emotions?['happy'], equals(0.9));
      });
    });

    group('VisionLabel', () {
      test('creates without bounding box', () {
        const label = VisionLabel(name: 'cat', confidence: 0.95);
        expect(label.name, equals('cat'));
        expect(label.confidence, equals(0.95));
        expect(label.boundingBox, isNull);
      });

      test('creates with bounding box', () {
        const label = VisionLabel(
          name: 'dog',
          confidence: 0.88,
          boundingBox: BoundingBox(x: 10, y: 20, width: 200, height: 150),
        );
        expect(label.boundingBox?.width, equals(200));
      });
    });

    group('VisionFace', () {
      test('creates with required fields', () {
        const face = VisionFace(
          boundingBox: BoundingBox(x: 0, y: 0, width: 100, height: 100),
          confidence: 0.99,
        );
        expect(face.confidence, equals(0.99));
        expect(face.emotions, isNull);
      });

      test('creates with emotions', () {
        const face = VisionFace(
          boundingBox: BoundingBox(x: 0, y: 0, width: 100, height: 100),
          confidence: 0.95,
          emotions: {'happy': 0.8, 'sad': 0.1, 'neutral': 0.1},
        );
        expect(face.emotions?.length, equals(3));
        expect(face.emotions?['happy'], equals(0.8));
      });
    });

    group('StubVisionPort', () {
      test('isAvailable returns true', () async {
        final port = StubVisionPort();
        expect(await port.isAvailable(), isTrue);
      });

      test('describe returns empty result', () async {
        final port = StubVisionPort();
        final result = await port.describe(
          Stream.value([1, 2, 3]),
          const VisionOptions(),
        );
        expect(result.description, isEmpty);
        expect(result.confidence, equals(0.0));
        expect(result.processingTime, equals(Duration.zero));
      });
    });
  });

  group('BinaryStoragePort', () {
    group('StorageOptions', () {
      test('creates with defaults', () {
        const options = StorageOptions();
        expect(options.contentAddressable, isTrue);
        expect(options.prefix, isNull);
        expect(options.ttlSeconds, equals(0));
      });

      test('creates with custom values', () {
        const options = StorageOptions(
          contentAddressable: false,
          prefix: 'images/',
          ttlSeconds: 3600,
        );
        expect(options.contentAddressable, isFalse);
        expect(options.prefix, equals('images/'));
        expect(options.ttlSeconds, equals(3600));
      });
    });

    group('StorageMetadata', () {
      test('creates with required fields', () {
        final now = DateTime.now();
        final metadata = StorageMetadata(
          key: 'test-key',
          mimeType: 'image/png',
          size: 1024,
          sha256: 'abc123',
          createdAt: now,
        );
        expect(metadata.key, equals('test-key'));
        expect(metadata.mimeType, equals('image/png'));
        expect(metadata.size, equals(1024));
        expect(metadata.sha256, equals('abc123'));
        expect(metadata.createdAt, equals(now));
        expect(metadata.expiresAt, isNull);
      });

      test('creates with expiry', () {
        final now = DateTime.now();
        final expiry = now.add(const Duration(hours: 1));
        final metadata = StorageMetadata(
          key: 'temp-key',
          mimeType: 'application/octet-stream',
          size: 512,
          sha256: 'def456',
          createdAt: now,
          expiresAt: expiry,
        );
        expect(metadata.expiresAt, equals(expiry));
      });
    });

    group('InMemoryBinaryStoragePort', () {
      test('store and retrieve data', () async {
        final storage = InMemoryBinaryStoragePort();
        final data = [1, 2, 3, 4, 5];

        final ref = await storage.store(
          Stream.value(data),
          'application/octet-stream',
        );
        expect(ref, startsWith('mem://'));

        final retrieved = await storage.retrieve(ref);
        expect(retrieved, equals(Uint8List.fromList(data)));
      });

      test('exists returns correct value', () async {
        final storage = InMemoryBinaryStoragePort();
        final ref = await storage.store(
          Stream.value([1, 2, 3]),
          'text/plain',
        );

        expect(await storage.exists(ref), isTrue);
        expect(await storage.exists('nonexistent'), isFalse);
      });

      test('metadata returns stored info', () async {
        final storage = InMemoryBinaryStoragePort();
        final data = [1, 2, 3, 4, 5];

        final ref = await storage.store(
          Stream.value(data),
          'image/png',
        );

        final meta = await storage.metadata(ref);
        expect(meta, isNotNull);
        expect(meta?.key, equals(ref));
        expect(meta?.mimeType, equals('image/png'));
        expect(meta?.size, equals(5));
      });

      test('delete removes data', () async {
        final storage = InMemoryBinaryStoragePort();
        final ref = await storage.store(
          Stream.value([1, 2, 3]),
          'text/plain',
        );

        expect(await storage.exists(ref), isTrue);
        final deleted = await storage.delete(ref);
        expect(deleted, isTrue);
        expect(await storage.exists(ref), isFalse);
      });

      test('list returns all keys', () async {
        final storage = InMemoryBinaryStoragePort();
        final ref1 = await storage.store(Stream.value([1]), 'text/plain');
        await Future<void>.delayed(const Duration(milliseconds: 2));
        final ref2 = await storage.store(Stream.value([2]), 'text/plain');

        final keys = await storage.list();
        expect(keys.length, equals(2));
        expect(keys, contains(ref1));
        expect(keys, contains(ref2));
      });

      test('list with prefix filters keys', () async {
        final storage = InMemoryBinaryStoragePort();
        await storage.store(Stream.value([1]), 'text/plain');
        await Future<void>.delayed(const Duration(milliseconds: 2));
        await storage.store(Stream.value([2]), 'text/plain');

        final keys = await storage.list('mem://');
        expect(keys.length, equals(2));

        final noKeys = await storage.list('other://');
        expect(noKeys, isEmpty);
      });

      test('retrieve throws for nonexistent key', () async {
        final storage = InMemoryBinaryStoragePort();
        expect(
          () => storage.retrieve('nonexistent'),
          throwsException,
        );
      });
    });
  });

  group('IngestPorts', () {
    test('empty ports has no capabilities', () {
      const ports = IngestPorts.empty;
      expect(ports.ocr, isNull);
      expect(ports.asr, isNull);
      expect(ports.vision, isNull);
      expect(ports.storage, isNull);
      expect(ports.llm, isNull);
      expect(ports.hasStorage, isFalse);
      expect(ports.hasLlm, isFalse);
    });

    test('stubs factory creates all ports', () {
      final ports = IngestPorts.stubs();
      expect(ports.ocr, isNotNull);
      expect(ports.asr, isNotNull);
      expect(ports.vision, isNotNull);
      expect(ports.storage, isNotNull);
      expect(ports.hasStorage, isTrue);
    });

    test('hasOcr async check works', () async {
      final ports = IngestPorts.stubs();
      expect(await ports.hasOcr, isTrue);

      const emptyPorts = IngestPorts.empty;
      expect(await emptyPorts.hasOcr, isFalse);
    });

    test('hasAsr async check works', () async {
      final ports = IngestPorts.stubs();
      expect(await ports.hasAsr, isTrue);

      const emptyPorts = IngestPorts.empty;
      expect(await emptyPorts.hasAsr, isFalse);
    });

    test('hasVision async check works', () async {
      final ports = IngestPorts.stubs();
      expect(await ports.hasVision, isTrue);

      const emptyPorts = IngestPorts.empty;
      expect(await emptyPorts.hasVision, isFalse);
    });

    test('creates with individual ports', () {
      final ports = IngestPorts(
        ocr: StubOcrPort(),
        asr: StubAsrPort(),
      );
      expect(ports.ocr, isNotNull);
      expect(ports.asr, isNotNull);
      expect(ports.vision, isNull);
      expect(ports.storage, isNull);
    });
  });
}
