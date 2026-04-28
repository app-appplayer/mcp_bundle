import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:mcp_bundle/src/utils/integrity.dart' as integrity_util;

void main() {
  // ==================== HashAlgorithm ====================

  group('HashAlgorithm', () {
    test('has all expected values', () {
      expect(
        integrity_util.HashAlgorithm.values,
        containsAll([
          integrity_util.HashAlgorithm.sha256,
          integrity_util.HashAlgorithm.sha384,
          integrity_util.HashAlgorithm.sha512,
          integrity_util.HashAlgorithm.md5,
        ]),
      );
    });

    test('has exactly four values', () {
      expect(integrity_util.HashAlgorithm.values.length, equals(4));
    });
  });

  // ==================== ContentHash ====================

  group('ContentHash', () {
    group('fromBytes', () {
      test('creates hash from byte list', () {
        final bytes = List<int>.generate(32, (i) => i);
        final hash = ContentHash.fromBytes(
          integrity_util.HashAlgorithm.sha256,
          bytes,
        );
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.sha256));
        expect(hash.bytes.length, equals(32));
      });

      test('stores a copy of bytes (not reference)', () {
        final bytes = <int>[1, 2, 3, 4];
        final hash = ContentHash.fromBytes(
          integrity_util.HashAlgorithm.sha256,
          bytes,
        );
        bytes[0] = 99;
        expect(hash.bytes[0], equals(1));
      });
    });

    group('parse', () {
      test('parses sha256 hash string', () {
        final hex = 'a' * 64;
        final hash = ContentHash.parse('sha256:$hex');
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.sha256));
        expect(hash.hex, equals(hex));
      });

      test('parses sha-256 (with hyphen) hash string', () {
        final hex = 'b' * 64;
        final hash = ContentHash.parse('sha-256:$hex');
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.sha256));
      });

      test('parses sha384 hash string', () {
        final hex = 'c' * 96;
        final hash = ContentHash.parse('sha384:$hex');
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.sha384));
      });

      test('parses sha-384 (with hyphen) hash string', () {
        final hex = 'c' * 96;
        final hash = ContentHash.parse('sha-384:$hex');
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.sha384));
      });

      test('parses sha512 hash string', () {
        final hex = 'd' * 128;
        final hash = ContentHash.parse('sha512:$hex');
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.sha512));
      });

      test('parses sha-512 (with hyphen) hash string', () {
        final hex = 'd' * 128;
        final hash = ContentHash.parse('sha-512:$hex');
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.sha512));
      });

      test('parses md5 hash string', () {
        final hex = 'e' * 32;
        final hash = ContentHash.parse('md5:$hex');
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.md5));
      });

      test('throws FormatException for missing colon separator', () {
        expect(
          () => ContentHash.parse('sha256abcdef'),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException for unknown algorithm', () {
        expect(
          () => ContentHash.parse('sha999:${'a' * 64}'),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException for odd-length hex string', () {
        expect(
          () => ContentHash.parse('sha256:abc'),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException for too many colons', () {
        expect(
          () => ContentHash.parse('sha256:ab:cd'),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('hex', () {
      test('returns hex-encoded bytes', () {
        final bytes = Uint8List.fromList([0x0a, 0xff, 0x00, 0x10]);
        final hash = ContentHash.fromBytes(
          integrity_util.HashAlgorithm.sha256,
          bytes,
        );
        expect(hash.hex, equals('0aff0010'));
      });

      test('pads single-digit hex values with leading zero', () {
        final bytes = Uint8List.fromList([0x01]);
        final hash = ContentHash.fromBytes(
          integrity_util.HashAlgorithm.sha256,
          bytes,
        );
        expect(hash.hex, equals('01'));
      });
    });

    group('toString', () {
      test('returns algorithm:hex format', () {
        final hex = 'ab' * 32;
        final hash = ContentHash.parse('sha256:$hex');
        expect(hash.toString(), equals('sha256:$hex'));
      });
    });

    group('equality', () {
      test('equal hashes are equal', () {
        final hex = 'ab' * 32;
        final a = ContentHash.parse('sha256:$hex');
        final b = ContentHash.parse('sha256:$hex');
        expect(a, equals(b));
      });

      test('different algorithms are not equal', () {
        // Same bytes but different algorithms
        final a = ContentHash.fromBytes(
          integrity_util.HashAlgorithm.sha256,
          List<int>.filled(16, 0xab),
        );
        final b = ContentHash.fromBytes(
          integrity_util.HashAlgorithm.md5,
          List<int>.filled(16, 0xab),
        );
        expect(a, isNot(equals(b)));
      });

      test('different bytes are not equal', () {
        final a = ContentHash.fromBytes(
          integrity_util.HashAlgorithm.sha256,
          [1, 2, 3],
        );
        final b = ContentHash.fromBytes(
          integrity_util.HashAlgorithm.sha256,
          [1, 2, 4],
        );
        expect(a, isNot(equals(b)));
      });

      test('different byte lengths are not equal', () {
        final a = ContentHash.fromBytes(
          integrity_util.HashAlgorithm.sha256,
          [1, 2],
        );
        final b = ContentHash.fromBytes(
          integrity_util.HashAlgorithm.sha256,
          [1, 2, 3],
        );
        expect(a, isNot(equals(b)));
      });

      test('identical instances are equal', () {
        final a = ContentHash.fromBytes(
          integrity_util.HashAlgorithm.sha256,
          [1, 2, 3],
        );
        expect(a, equals(a));
      });

      test('is not equal to non-ContentHash object', () {
        final a = ContentHash.fromBytes(
          integrity_util.HashAlgorithm.sha256,
          [1, 2, 3],
        );
        // ignore: unrelated_type_equality_checks
        expect(a == Object(), isFalse);
      });
    });

    group('hashCode', () {
      test('equal hashes have same hashCode', () {
        final hex = 'ab' * 32;
        final a = ContentHash.parse('sha256:$hex');
        final b = ContentHash.parse('sha256:$hex');
        expect(a.hashCode, equals(b.hashCode));
      });
    });
  });

  // ==================== IntegrityChecker ====================

  group('IntegrityChecker', () {
    const checker = IntegrityChecker();

    group('hashBytes', () {
      test('produces SHA-256 hash by default', () {
        final hash = checker.hashBytes(utf8.encode('hello'));
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.sha256));
        // SHA-256 produces 32 bytes
        expect(hash.bytes.length, equals(32));
      });

      test('produces deterministic hash for same input', () {
        final bytes = utf8.encode('test data');
        final hash1 = checker.hashBytes(bytes);
        final hash2 = checker.hashBytes(bytes);
        expect(hash1, equals(hash2));
      });

      test('produces different hashes for different input', () {
        final hash1 = checker.hashBytes(utf8.encode('hello'));
        final hash2 = checker.hashBytes(utf8.encode('world'));
        expect(hash1, isNot(equals(hash2)));
      });

      test('hashes empty bytes', () {
        final hash = checker.hashBytes(<int>[]);
        expect(hash.bytes.length, equals(32));
      });
    });

    group('hashString', () {
      test('hashes string content', () {
        final hash = checker.hashString('hello');
        // Should be equivalent to hashing UTF-8 encoded bytes
        final expected = checker.hashBytes(utf8.encode('hello'));
        expect(hash, equals(expected));
      });

      test('hashes empty string', () {
        final hash = checker.hashString('');
        final expected = checker.hashBytes(utf8.encode(''));
        expect(hash, equals(expected));
      });

      test('hashes unicode string', () {
        final hash = checker.hashString('unicode text');
        expect(hash.bytes.length, equals(32));
      });
    });

    group('hashJson', () {
      test('hashes canonicalized JSON', () {
        final hash = checker.hashJson({'b': 2, 'a': 1});
        // Same data in different key order should produce same hash
        final hash2 = checker.hashJson({'a': 1, 'b': 2});
        expect(hash, equals(hash2));
      });

      test('produces different hash for different JSON', () {
        final hash1 = checker.hashJson({'a': 1});
        final hash2 = checker.hashJson({'a': 2});
        expect(hash1, isNot(equals(hash2)));
      });

      test('hashes null JSON value', () {
        final hash = checker.hashJson(null);
        expect(hash.bytes.length, equals(32));
      });

      test('hashes array JSON value', () {
        final hash = checker.hashJson([1, 2, 3]);
        expect(hash.bytes.length, equals(32));
      });
    });

    group('with different algorithms', () {
      test('SHA-384 produces 48-byte hash', () {
        const sha384Checker = IntegrityChecker(
          algorithm: integrity_util.HashAlgorithm.sha384,
        );
        final hash = sha384Checker.hashBytes(utf8.encode('test'));
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.sha384));
        expect(hash.bytes.length, equals(48));
      });

      test('SHA-512 produces 64-byte hash', () {
        const sha512Checker = IntegrityChecker(
          algorithm: integrity_util.HashAlgorithm.sha512,
        );
        final hash = sha512Checker.hashBytes(utf8.encode('test'));
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.sha512));
        expect(hash.bytes.length, equals(64));
      });

      test('MD5 produces 16-byte hash', () {
        const md5Checker = IntegrityChecker(
          algorithm: integrity_util.HashAlgorithm.md5,
        );
        final hash = md5Checker.hashBytes(utf8.encode('test'));
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.md5));
        expect(hash.bytes.length, equals(16));
      });
    });

    group('verifyBytes', () {
      test('returns true for matching content', () {
        final bytes = utf8.encode('hello world');
        final hash = checker.hashBytes(bytes);
        expect(checker.verifyBytes(bytes, hash), isTrue);
      });

      test('returns false for non-matching content', () {
        final bytes = utf8.encode('hello world');
        final hash = checker.hashBytes(bytes);
        final tamperedBytes = utf8.encode('hello worlx');
        expect(checker.verifyBytes(tamperedBytes, hash), isFalse);
      });

      test('verifies using the algorithm from expected hash', () {
        // Create hash with MD5
        const md5Checker = IntegrityChecker(
          algorithm: integrity_util.HashAlgorithm.md5,
        );
        final bytes = utf8.encode('test');
        final md5Hash = md5Checker.hashBytes(bytes);

        // Default checker (SHA-256) should still verify correctly
        // because it uses the algorithm from the expected hash
        expect(checker.verifyBytes(bytes, md5Hash), isTrue);
      });
    });

    group('verifyString', () {
      test('returns true for matching string', () {
        const content = 'verify me';
        final hash = checker.hashString(content);
        expect(checker.verifyString(content, hash), isTrue);
      });

      test('returns false for non-matching string', () {
        final hash = checker.hashString('original');
        expect(checker.verifyString('modified', hash), isFalse);
      });
    });

    group('verifyJson', () {
      test('returns true for matching JSON (same key order)', () {
        final data = <String, dynamic>{'a': 1, 'b': 2};
        final hash = checker.hashJson(data);
        expect(checker.verifyJson(data, hash), isTrue);
      });

      test('returns true for matching JSON (different key order)', () {
        final hash = checker.hashJson({'a': 1, 'b': 2});
        expect(checker.verifyJson({'b': 2, 'a': 1}, hash), isTrue);
      });

      test('returns false for non-matching JSON', () {
        final hash = checker.hashJson({'a': 1});
        expect(checker.verifyJson({'a': 2}, hash), isFalse);
      });
    });

    group('verifyHashString', () {
      test('returns true for valid hash string match', () {
        final bytes = utf8.encode('content');
        final hash = checker.hashBytes(bytes);
        expect(
          checker.verifyHashString(bytes, hash.toString()),
          isTrue,
        );
      });

      test('returns false for non-matching hash string', () {
        final bytes = utf8.encode('content');
        final fakeHash = 'sha256:${'00' * 32}';
        expect(checker.verifyHashString(bytes, fakeHash), isFalse);
      });

      test('returns false for invalid hash string format', () {
        final bytes = utf8.encode('content');
        expect(checker.verifyHashString(bytes, 'not-a-hash'), isFalse);
      });

      test('returns false for unknown algorithm in hash string', () {
        final bytes = utf8.encode('content');
        expect(
          checker.verifyHashString(bytes, 'sha999:${'aa' * 32}'),
          isFalse,
        );
      });
    });
  });

  // ==================== IntegrityResult ====================

  group('IntegrityResult', () {
    group('constructor', () {
      test('creates result with all fields', () {
        final hash = ContentHash.fromBytes(
          integrity_util.HashAlgorithm.sha256,
          List<int>.filled(32, 0),
        );
        final result = IntegrityResult(
          isValid: true,
          errors: const [],
          hashes: {'bundle': hash},
        );
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
        expect(result.hashes, hasLength(1));
      });
    });

    group('valid factory', () {
      test('creates valid result with no errors', () {
        const result = IntegrityResult.valid();
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
        expect(result.hashes, isEmpty);
      });

      test('creates valid result with hashes', () {
        final hash = ContentHash.fromBytes(
          integrity_util.HashAlgorithm.sha256,
          List<int>.filled(32, 0xab),
        );
        final result = IntegrityResult.valid(hashes: {'main': hash});
        expect(result.isValid, isTrue);
        expect(result.hashes['main'], equals(hash));
      });
    });

    group('invalid factory', () {
      test('creates invalid result with errors', () {
        const error = IntegrityError(
          type: IntegrityErrorType.hashMismatch,
          message: 'Hash does not match',
        );
        const result = IntegrityResult.invalid(errors: [error]);
        expect(result.isValid, isFalse);
        expect(result.errors, hasLength(1));
      });

      test('creates invalid result with errors and hashes', () {
        const error = IntegrityError(
          type: IntegrityErrorType.missingHash,
          message: 'No hash found',
        );
        final hash = ContentHash.fromBytes(
          integrity_util.HashAlgorithm.sha256,
          List<int>.filled(32, 0),
        );
        final result = IntegrityResult.invalid(
          errors: [error],
          hashes: {'partial': hash},
        );
        expect(result.isValid, isFalse);
        expect(result.errors, hasLength(1));
        expect(result.hashes, hasLength(1));
      });
    });
  });

  // ==================== IntegrityError ====================

  group('IntegrityError', () {
    test('creates error with required fields', () {
      const error = IntegrityError(
        type: IntegrityErrorType.hashMismatch,
        message: 'Hash mismatch detected',
      );
      expect(error.type, equals(IntegrityErrorType.hashMismatch));
      expect(error.message, equals('Hash mismatch detected'));
      expect(error.path, isNull);
      expect(error.expectedHash, isNull);
      expect(error.actualHash, isNull);
    });

    test('creates error with all fields', () {
      const error = IntegrityError(
        type: IntegrityErrorType.hashMismatch,
        path: '/assets/image.png',
        message: 'Content has been modified',
        expectedHash: 'sha256:aabbccdd',
        actualHash: 'sha256:11223344',
      );
      expect(error.path, equals('/assets/image.png'));
      expect(error.expectedHash, equals('sha256:aabbccdd'));
      expect(error.actualHash, equals('sha256:11223344'));
    });

    test('toString includes message', () {
      const error = IntegrityError(
        type: IntegrityErrorType.missingContent,
        message: 'File is missing',
      );
      expect(error.toString(), contains('File is missing'));
    });

    test('toString includes path when present', () {
      const error = IntegrityError(
        type: IntegrityErrorType.missingContent,
        path: '/data/file.json',
        message: 'File is missing',
      );
      final str = error.toString();
      expect(str, contains('/data/file.json'));
      expect(str, contains('File is missing'));
    });

    test('toString omits path when null', () {
      const error = IntegrityError(
        type: IntegrityErrorType.invalidContent,
        message: 'Invalid content',
      );
      expect(error.toString(), isNot(contains('path')));
    });
  });

  // ==================== IntegrityErrorType ====================

  group('IntegrityErrorType', () {
    test('has all expected values', () {
      expect(
        IntegrityErrorType.values,
        containsAll([
          IntegrityErrorType.hashMismatch,
          IntegrityErrorType.missingHash,
          IntegrityErrorType.invalidHashFormat,
          IntegrityErrorType.missingContent,
          IntegrityErrorType.invalidContent,
        ]),
      );
    });

    test('has exactly five values', () {
      expect(IntegrityErrorType.values.length, equals(5));
    });
  });

  // ==================== Convenience Functions ====================

  group('Convenience functions', () {
    group('sha256Hash', () {
      test('hashes bytes with SHA-256', () {
        final hash = sha256Hash(utf8.encode('test'));
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.sha256));
        expect(hash.bytes.length, equals(32));
      });

      test('produces same result as IntegrityChecker', () {
        final bytes = utf8.encode('consistency check');
        final hash = sha256Hash(bytes);
        final expected = const IntegrityChecker().hashBytes(bytes);
        expect(hash, equals(expected));
      });
    });

    group('sha256HashString', () {
      test('hashes string with SHA-256', () {
        final hash = sha256HashString('hello');
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.sha256));
      });

      test('equivalent to hashing UTF-8 encoded string', () {
        final hash = sha256HashString('test');
        final expected = sha256Hash(utf8.encode('test'));
        expect(hash, equals(expected));
      });
    });

    group('sha256HashJson', () {
      test('hashes JSON with SHA-256', () {
        final hash = sha256HashJson({'key': 'value'});
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.sha256));
      });

      test('key order does not affect hash', () {
        final hash1 = sha256HashJson({'a': 1, 'b': 2});
        final hash2 = sha256HashJson({'b': 2, 'a': 1});
        expect(hash1, equals(hash2));
      });
    });

    group('verifyIntegrity', () {
      test('returns true when bytes match hash string', () {
        final bytes = utf8.encode('verify me');
        final hash = sha256Hash(bytes);
        expect(verifyIntegrity(bytes, hash.toString()), isTrue);
      });

      test('returns false when bytes do not match hash string', () {
        final bytes = utf8.encode('original');
        final hash = sha256Hash(utf8.encode('different'));
        expect(verifyIntegrity(bytes, hash.toString()), isFalse);
      });

      test('returns false for invalid hash string', () {
        expect(verifyIntegrity(utf8.encode('data'), 'invalid'), isFalse);
      });
    });

    group('default integrityChecker', () {
      test('is a const IntegrityChecker', () {
        expect(integrityChecker, isA<IntegrityChecker>());
      });

      test('uses SHA-256 by default', () {
        final hash = integrityChecker.hashBytes([1, 2, 3]);
        expect(hash.algorithm, equals(integrity_util.HashAlgorithm.sha256));
      });
    });
  });
}
