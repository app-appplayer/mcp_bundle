import 'package:test/test.dart';
import 'package:mcp_bundle/src/models/integrity.dart';

void main() {
  // ---------------------------------------------------------------------------
  // CompatibilityConfig
  // ---------------------------------------------------------------------------
  group('CompatibilityConfig', () {
    group('fromJson / toJson', () {
      test('round-trips full JSON', () {
        final json = {
          'schemaVersion': '2.0',
          'requirements': {'dart_sdk': '>=3.0.0', 'flutter': '^3.10.0'},
          'minRuntimeVersion': '1.0.0',
          'maxRuntimeVersion': '2.0.0',
          'requiredFeatures': ['streaming', 'offline'],
          'incompatibleWith': ['legacy-bundle-v1'],
        };

        final config = CompatibilityConfig.fromJson(json);
        final output = config.toJson();

        expect(output['schemaVersion'], equals('2.0'));
        expect(output['requirements'], equals(json['requirements']));
        expect(output['minRuntimeVersion'], equals('1.0.0'));
        expect(output['maxRuntimeVersion'], equals('2.0.0'));
        expect(output['requiredFeatures'], equals(['streaming', 'offline']));
        expect(output['incompatibleWith'], equals(['legacy-bundle-v1']));
      });

      test('handles empty JSON gracefully', () {
        final config = CompatibilityConfig.fromJson({});

        expect(config.schemaVersion, isNull);
        expect(config.requirements, isEmpty);
        expect(config.minRuntimeVersion, isNull);
        expect(config.maxRuntimeVersion, isNull);
        expect(config.requiredFeatures, isEmpty);
        expect(config.incompatibleWith, isEmpty);
      });

      test('omits null and empty fields in toJson', () {
        const config = CompatibilityConfig();
        final json = config.toJson();

        expect(json.containsKey('schemaVersion'), isFalse);
        expect(json.containsKey('requirements'), isFalse);
        expect(json.containsKey('minRuntimeVersion'), isFalse);
        expect(json.containsKey('maxRuntimeVersion'), isFalse);
        expect(json.containsKey('requiredFeatures'), isFalse);
        expect(json.containsKey('incompatibleWith'), isFalse);
      });
    });

    group('copyWith', () {
      test('copies all fields', () {
        const original = CompatibilityConfig(
          schemaVersion: '1.0',
          requirements: {'a': '1.0'},
          minRuntimeVersion: '0.5',
          maxRuntimeVersion: '3.0',
          requiredFeatures: ['feat1'],
          incompatibleWith: ['bad-pkg'],
        );

        final copy = original.copyWith(
          schemaVersion: '2.0',
          requirements: {'b': '2.0'},
          minRuntimeVersion: '1.0',
          maxRuntimeVersion: '4.0',
          requiredFeatures: ['feat2'],
          incompatibleWith: ['other-pkg'],
        );

        expect(copy.schemaVersion, equals('2.0'));
        expect(copy.requirements, equals({'b': '2.0'}));
        expect(copy.minRuntimeVersion, equals('1.0'));
        expect(copy.maxRuntimeVersion, equals('4.0'));
        expect(copy.requiredFeatures, equals(['feat2']));
        expect(copy.incompatibleWith, equals(['other-pkg']));
      });

      test('preserves original values when no overrides given', () {
        const original = CompatibilityConfig(
          schemaVersion: '1.0',
          requirements: {'a': '1.0'},
        );

        final copy = original.copyWith();

        expect(copy.schemaVersion, equals('1.0'));
        expect(copy.requirements, equals({'a': '1.0'}));
      });
    });

    group('empty defaults', () {
      test('default constructor produces empty collections', () {
        const config = CompatibilityConfig();

        expect(config.schemaVersion, isNull);
        expect(config.requirements, isEmpty);
        expect(config.minRuntimeVersion, isNull);
        expect(config.maxRuntimeVersion, isNull);
        expect(config.requiredFeatures, isEmpty);
        expect(config.incompatibleWith, isEmpty);
      });
    });

    group('checkCompatibility', () {
      // ">=" operator
      test('>= requirement satisfied when version equals', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '>=1.2.0'},
        );
        expect(config.checkCompatibility({'pkg': '1.2.0'}), isTrue);
      });

      test('>= requirement satisfied when version is greater', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '>=1.2.0'},
        );
        expect(config.checkCompatibility({'pkg': '1.3.0'}), isTrue);
      });

      test('>= requirement not satisfied when version is less', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '>=1.2.0'},
        );
        expect(config.checkCompatibility({'pkg': '1.1.9'}), isFalse);
      });

      // ">" operator
      test('> requirement satisfied when version is strictly greater', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '>1.0.0'},
        );
        expect(config.checkCompatibility({'pkg': '1.0.1'}), isTrue);
      });

      test('> requirement not satisfied when version equals', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '>1.0.0'},
        );
        expect(config.checkCompatibility({'pkg': '1.0.0'}), isFalse);
      });

      test('> requirement not satisfied when version is less', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '>2.0.0'},
        );
        expect(config.checkCompatibility({'pkg': '1.9.9'}), isFalse);
      });

      // "<=" operator
      test('<= requirement satisfied when version equals', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '<=3.0.0'},
        );
        expect(config.checkCompatibility({'pkg': '3.0.0'}), isTrue);
      });

      test('<= requirement satisfied when version is less', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '<=3.0.0'},
        );
        expect(config.checkCompatibility({'pkg': '2.9.9'}), isTrue);
      });

      test('<= requirement not satisfied when version is greater', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '<=3.0.0'},
        );
        expect(config.checkCompatibility({'pkg': '3.0.1'}), isFalse);
      });

      // "<" operator
      test('< requirement satisfied when version is strictly less', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '<2.0.0'},
        );
        expect(config.checkCompatibility({'pkg': '1.9.9'}), isTrue);
      });

      test('< requirement not satisfied when version equals', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '<2.0.0'},
        );
        expect(config.checkCompatibility({'pkg': '2.0.0'}), isFalse);
      });

      test('< requirement not satisfied when version is greater', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '<2.0.0'},
        );
        expect(config.checkCompatibility({'pkg': '2.0.1'}), isFalse);
      });

      // "^" caret range (compatible major version)
      test('^ caret range matches same major version', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '^1.2.0'},
        );
        expect(config.checkCompatibility({'pkg': '1.5.0'}), isTrue);
      });

      test('^ caret range matches exact version', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '^1.2.0'},
        );
        expect(config.checkCompatibility({'pkg': '1.2.0'}), isTrue);
      });

      test('^ caret range does not match different major version', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '^1.2.0'},
        );
        expect(config.checkCompatibility({'pkg': '2.0.0'}), isFalse);
      });

      // Exact version match
      test('exact version match succeeds', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '1.0.0'},
        );
        expect(config.checkCompatibility({'pkg': '1.0.0'}), isTrue);
      });

      test('exact version mismatch fails', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '1.0.0'},
        );
        expect(config.checkCompatibility({'pkg': '1.0.1'}), isFalse);
      });

      // Wildcard "*"
      test('wildcard * always matches any version', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '*'},
        );
        expect(config.checkCompatibility({'pkg': '99.99.99'}), isTrue);
      });

      test('wildcard * matches zero-like version', () {
        const config = CompatibilityConfig(
          requirements: {'pkg': '*'},
        );
        expect(config.checkCompatibility({'pkg': '0.0.1'}), isTrue);
      });

      // Missing version in available
      test('returns false when required package is missing from available', () {
        const config = CompatibilityConfig(
          requirements: {'missing_pkg': '>=1.0.0'},
        );
        expect(config.checkCompatibility({}), isFalse);
      });

      test('returns false when one of many packages is missing', () {
        const config = CompatibilityConfig(
          requirements: {'a': '>=1.0.0', 'b': '>=1.0.0'},
        );
        expect(config.checkCompatibility({'a': '1.0.0'}), isFalse);
      });

      // Multiple requirements
      test('all requirements satisfied returns true', () {
        const config = CompatibilityConfig(
          requirements: {
            'dart': '>=3.0.0',
            'flutter': '^3.10.0',
            'any_lib': '*',
          },
        );
        final available = {
          'dart': '3.2.0',
          'flutter': '3.16.0',
          'any_lib': '0.0.1',
        };
        expect(config.checkCompatibility(available), isTrue);
      });

      test('one requirement fails causes overall failure', () {
        const config = CompatibilityConfig(
          requirements: {
            'dart': '>=3.0.0',
            'flutter': '>=4.0.0',
          },
        );
        final available = {
          'dart': '3.2.0',
          'flutter': '3.16.0',
        };
        expect(config.checkCompatibility(available), isFalse);
      });

      test('empty requirements always returns true', () {
        const config = CompatibilityConfig();
        expect(config.checkCompatibility({'anything': '1.0.0'}), isTrue);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // IntegrityConfig
  // ---------------------------------------------------------------------------
  group('IntegrityConfig', () {
    group('fromJson / toJson', () {
      test('round-trips full JSON with contentHash, files, and signatures', () {
        final timestamp = DateTime.utc(2025, 6, 1, 12, 0, 0);
        final json = {
          'contentHash': {
            'algorithm': 'sha256',
            'value': 'abc123',
            'scope': 'canonical_json',
          },
          'files': [
            {
              'path': 'data/config.json',
              'algorithm': 'sha256',
              'value': 'def456',
            },
          ],
          'signatures': [
            {
              'keyId': 'key-1',
              'algorithm': 'rsa-sha256',
              'value': 'sig-value',
              'signedPayload': {
                'type': 'content_hash',
              },
            },
          ],
          'computedAt': timestamp.toIso8601String(),
        };

        final config = IntegrityConfig.fromJson(json);
        final output = config.toJson();

        expect(output['contentHash'], isNotNull);
        expect(output['files'], hasLength(1));
        expect(output['signatures'], hasLength(1));
        expect(output['computedAt'], equals(timestamp.toIso8601String()));
      });

      test('handles empty JSON gracefully', () {
        final config = IntegrityConfig.fromJson({});

        expect(config.contentHash, isNull);
        expect(config.files, isEmpty);
        expect(config.signatures, isEmpty);
        expect(config.computedAt, isNull);
      });

      test('omits null and empty fields in toJson', () {
        const config = IntegrityConfig();
        final json = config.toJson();

        expect(json.containsKey('contentHash'), isFalse);
        expect(json.containsKey('files'), isFalse);
        expect(json.containsKey('signatures'), isFalse);
        expect(json.containsKey('computedAt'), isFalse);
      });
    });

    group('copyWith', () {
      test('overrides specified fields', () {
        const original = IntegrityConfig(
          contentHash: ContentHash(
            algorithm: HashAlgorithm.sha256,
            value: 'original',
          ),
        );

        final copy = original.copyWith(
          contentHash: const ContentHash(
            algorithm: HashAlgorithm.sha512,
            value: 'updated',
          ),
        );

        expect(copy.contentHash!.algorithm, equals(HashAlgorithm.sha512));
        expect(copy.contentHash!.value, equals('updated'));
      });

      test('preserves original when no overrides given', () {
        final original = IntegrityConfig(
          computedAt: DateTime.utc(2025, 1, 1),
        );

        final copy = original.copyWith();

        expect(copy.computedAt, equals(original.computedAt));
      });
    });

    group('isValid getter', () {
      test('returns true when contentHash is present', () {
        const config = IntegrityConfig(
          contentHash: ContentHash(
            algorithm: HashAlgorithm.sha256,
            value: 'abc',
          ),
        );
        expect(config.isValid, isTrue);
      });

      test('returns true when files list is non-empty', () {
        const config = IntegrityConfig(
          files: [
            FileHash(
              path: 'a.txt',
              algorithm: HashAlgorithm.sha256,
              value: 'hash',
            ),
          ],
        );
        expect(config.isValid, isTrue);
      });

      test('returns true when signatures list is non-empty', () {
        const config = IntegrityConfig(
          signatures: [
            Signature(
              keyId: 'k1',
              algorithm: SignatureAlgorithm.rsaSha256,
              value: 'sig',
              signedPayload: SignedPayloadRef(type: PayloadRefType.manifest),
            ),
          ],
        );
        expect(config.isValid, isTrue);
      });

      test('returns false when all fields are empty/null', () {
        const config = IntegrityConfig();
        expect(config.isValid, isFalse);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // ContentHash
  // ---------------------------------------------------------------------------
  group('ContentHash', () {
    group('fromJson / toJson', () {
      test('round-trips full JSON', () {
        final json = {
          'algorithm': 'sha256',
          'value': 'abcdef1234567890',
          'scope': 'all_files',
          'excludedPaths': ['tmp/', '.cache/'],
        };

        final hash = ContentHash.fromJson(json);
        final output = hash.toJson();

        expect(output['algorithm'], equals('sha256'));
        expect(output['value'], equals('abcdef1234567890'));
        expect(output['scope'], equals('allFiles'));
        expect(output['excludedPaths'], equals(['tmp/', '.cache/']));
      });

      test('handles minimal JSON with defaults', () {
        final hash = ContentHash.fromJson({});

        expect(hash.algorithm, equals(HashAlgorithm.unknown));
        expect(hash.value, equals(''));
        expect(hash.scope, equals(ContentScope.canonicalJson));
        expect(hash.excludedPaths, isEmpty);
      });

      test('omits excludedPaths when empty in toJson', () {
        const hash = ContentHash(
          algorithm: HashAlgorithm.sha256,
          value: 'abc',
        );
        final json = hash.toJson();

        expect(json.containsKey('excludedPaths'), isFalse);
      });
    });

    group('copyWith', () {
      test('overrides specified fields', () {
        const original = ContentHash(
          algorithm: HashAlgorithm.sha256,
          value: 'old',
          scope: ContentScope.canonicalJson,
        );

        final copy = original.copyWith(
          algorithm: HashAlgorithm.sha512,
          value: 'new',
          scope: ContentScope.allFiles,
          excludedPaths: ['test/'],
        );

        expect(copy.algorithm, equals(HashAlgorithm.sha512));
        expect(copy.value, equals('new'));
        expect(copy.scope, equals(ContentScope.allFiles));
        expect(copy.excludedPaths, equals(['test/']));
      });
    });

    group('verify', () {
      test('returns true for identical hash (same case)', () {
        const hash = ContentHash(
          algorithm: HashAlgorithm.sha256,
          value: 'abcdef1234567890',
        );
        expect(hash.verify('abcdef1234567890'), isTrue);
      });

      test('returns true for case-insensitive match (mixed case)', () {
        const hash = ContentHash(
          algorithm: HashAlgorithm.sha256,
          value: 'ABCDEF1234567890',
        );
        expect(hash.verify('abcdef1234567890'), isTrue);
      });

      test('returns true when stored is lower and computed is upper', () {
        const hash = ContentHash(
          algorithm: HashAlgorithm.sha256,
          value: 'aabbcc',
        );
        expect(hash.verify('AABBCC'), isTrue);
      });

      test('returns false for hash mismatch', () {
        const hash = ContentHash(
          algorithm: HashAlgorithm.sha256,
          value: 'abcdef',
        );
        expect(hash.verify('123456'), isFalse);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // HashAlgorithm
  // ---------------------------------------------------------------------------
  group('HashAlgorithm', () {
    group('fromString', () {
      test('parses "sha256"', () {
        expect(HashAlgorithm.fromString('sha256'), equals(HashAlgorithm.sha256));
      });

      test('parses "sha-256"', () {
        expect(
          HashAlgorithm.fromString('sha-256'),
          equals(HashAlgorithm.sha256),
        );
      });

      test('parses "sha384"', () {
        expect(HashAlgorithm.fromString('sha384'), equals(HashAlgorithm.sha384));
      });

      test('parses "sha-384"', () {
        expect(
          HashAlgorithm.fromString('sha-384'),
          equals(HashAlgorithm.sha384),
        );
      });

      test('parses "sha512"', () {
        expect(HashAlgorithm.fromString('sha512'), equals(HashAlgorithm.sha512));
      });

      test('parses "sha-512"', () {
        expect(
          HashAlgorithm.fromString('sha-512'),
          equals(HashAlgorithm.sha512),
        );
      });

      test('parses "md5"', () {
        expect(HashAlgorithm.fromString('md5'), equals(HashAlgorithm.md5));
      });

      test('returns unknown for unrecognised string', () {
        expect(
          HashAlgorithm.fromString('blake2'),
          equals(HashAlgorithm.unknown),
        );
      });

      test('returns unknown for null', () {
        expect(HashAlgorithm.fromString(null), equals(HashAlgorithm.unknown));
      });

      test('is case-insensitive', () {
        expect(HashAlgorithm.fromString('SHA256'), equals(HashAlgorithm.sha256));
        expect(HashAlgorithm.fromString('MD5'), equals(HashAlgorithm.md5));
      });
    });
  });

  // ---------------------------------------------------------------------------
  // ContentScope
  // ---------------------------------------------------------------------------
  group('ContentScope', () {
    group('fromString', () {
      test('parses "canonical_json"', () {
        expect(
          ContentScope.fromString('canonical_json'),
          equals(ContentScope.canonicalJson),
        );
      });

      test('parses "canonicaljson"', () {
        expect(
          ContentScope.fromString('canonicaljson'),
          equals(ContentScope.canonicalJson),
        );
      });

      test('parses "content_sections"', () {
        expect(
          ContentScope.fromString('content_sections'),
          equals(ContentScope.contentSections),
        );
      });

      test('parses "contentsections"', () {
        expect(
          ContentScope.fromString('contentsections'),
          equals(ContentScope.contentSections),
        );
      });

      test('parses "all_files"', () {
        expect(
          ContentScope.fromString('all_files'),
          equals(ContentScope.allFiles),
        );
      });

      test('parses "allfiles"', () {
        expect(
          ContentScope.fromString('allfiles'),
          equals(ContentScope.allFiles),
        );
      });

      test('parses "custom"', () {
        expect(ContentScope.fromString('custom'), equals(ContentScope.custom));
      });

      test('returns canonicalJson for unknown string', () {
        expect(
          ContentScope.fromString('something_else'),
          equals(ContentScope.canonicalJson),
        );
      });

      test('returns canonicalJson for null', () {
        expect(
          ContentScope.fromString(null),
          equals(ContentScope.canonicalJson),
        );
      });
    });
  });

  // ---------------------------------------------------------------------------
  // FileHash
  // ---------------------------------------------------------------------------
  group('FileHash', () {
    group('fromJson / toJson', () {
      test('round-trips full JSON including optional fields', () {
        final modified = DateTime.utc(2025, 3, 15, 10, 30, 0);
        final json = {
          'path': 'src/main.dart',
          'algorithm': 'sha512',
          'value': 'fedcba9876543210',
          'size': 4096,
          'modifiedAt': modified.toIso8601String(),
        };

        final fileHash = FileHash.fromJson(json);
        final output = fileHash.toJson();

        expect(output['path'], equals('src/main.dart'));
        expect(output['algorithm'], equals('sha512'));
        expect(output['value'], equals('fedcba9876543210'));
        expect(output['size'], equals(4096));
        expect(output['modifiedAt'], equals(modified.toIso8601String()));
      });

      test('handles minimal JSON with defaults', () {
        final fileHash = FileHash.fromJson({});

        expect(fileHash.path, equals(''));
        expect(fileHash.algorithm, equals(HashAlgorithm.unknown));
        expect(fileHash.value, equals(''));
        expect(fileHash.size, isNull);
        expect(fileHash.modifiedAt, isNull);
      });

      test('omits null fields in toJson', () {
        const fileHash = FileHash(
          path: 'a.txt',
          algorithm: HashAlgorithm.sha256,
          value: 'hash',
        );
        final json = fileHash.toJson();

        expect(json.containsKey('size'), isFalse);
        expect(json.containsKey('modifiedAt'), isFalse);
      });
    });

    group('copyWith', () {
      test('overrides specified fields', () {
        const original = FileHash(
          path: 'a.txt',
          algorithm: HashAlgorithm.sha256,
          value: 'aaa',
          size: 100,
        );

        final copy = original.copyWith(
          path: 'b.txt',
          algorithm: HashAlgorithm.md5,
          value: 'bbb',
          size: 200,
        );

        expect(copy.path, equals('b.txt'));
        expect(copy.algorithm, equals(HashAlgorithm.md5));
        expect(copy.value, equals('bbb'));
        expect(copy.size, equals(200));
      });

      test('preserves originals when no overrides given', () {
        const original = FileHash(
          path: 'x.txt',
          algorithm: HashAlgorithm.sha384,
          value: 'xxx',
        );

        final copy = original.copyWith();

        expect(copy.path, equals('x.txt'));
        expect(copy.algorithm, equals(HashAlgorithm.sha384));
        expect(copy.value, equals('xxx'));
      });
    });

    group('verify', () {
      test('returns true for identical hash (same case)', () {
        const fileHash = FileHash(
          path: 'f.txt',
          algorithm: HashAlgorithm.sha256,
          value: 'abcdef',
        );
        expect(fileHash.verify('abcdef'), isTrue);
      });

      test('returns true for case-insensitive match', () {
        const fileHash = FileHash(
          path: 'f.txt',
          algorithm: HashAlgorithm.sha256,
          value: 'ABCDEF',
        );
        expect(fileHash.verify('abcdef'), isTrue);
      });

      test('returns false for mismatch', () {
        const fileHash = FileHash(
          path: 'f.txt',
          algorithm: HashAlgorithm.sha256,
          value: 'abcdef',
        );
        expect(fileHash.verify('999999'), isFalse);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Signature
  // ---------------------------------------------------------------------------
  group('Signature', () {
    group('fromJson / toJson', () {
      test('round-trips full JSON with all fields', () {
        final ts = DateTime.utc(2025, 7, 4, 18, 0, 0);
        final json = {
          'keyId': 'key-abc-123',
          'algorithm': 'ecdsa-p256',
          'value': 'c2lnbmF0dXJl',
          'timestamp': ts.toIso8601String(),
          'signedPayload': {
            'type': 'manifest',
            'hash': 'abc',
            'hashAlgorithm': 'sha256',
            'url': 'https://example.com/payload',
          },
          'certificate': '-----BEGIN CERTIFICATE-----\nMIIB...\n-----END CERTIFICATE-----',
          'signer': 'dev@example.com',
        };

        final sig = Signature.fromJson(json);
        final output = sig.toJson();

        expect(output['keyId'], equals('key-abc-123'));
        expect(output['algorithm'], equals('ecdsaP256'));
        expect(output['value'], equals('c2lnbmF0dXJl'));
        expect(output['timestamp'], equals(ts.toIso8601String()));
        expect(output['signedPayload'], isA<Map<String, dynamic>>());
        expect(output['certificate'], contains('BEGIN CERTIFICATE'));
        expect(output['signer'], equals('dev@example.com'));
      });

      test('handles minimal JSON with defaults', () {
        final sig = Signature.fromJson({});

        expect(sig.keyId, equals(''));
        expect(sig.algorithm, equals(SignatureAlgorithm.unknown));
        expect(sig.value, equals(''));
        expect(sig.timestamp, isNull);
        expect(sig.certificate, isNull);
        expect(sig.signer, isNull);
      });

      test('omits null optional fields in toJson', () {
        const sig = Signature(
          keyId: 'k1',
          algorithm: SignatureAlgorithm.ed25519,
          value: 'val',
          signedPayload: SignedPayloadRef(type: PayloadRefType.manifest),
        );
        final json = sig.toJson();

        expect(json.containsKey('timestamp'), isFalse);
        expect(json.containsKey('certificate'), isFalse);
        expect(json.containsKey('signer'), isFalse);
      });
    });

    group('copyWith', () {
      test('overrides all fields', () {
        const original = Signature(
          keyId: 'old-key',
          algorithm: SignatureAlgorithm.rsaSha256,
          value: 'old-val',
          signedPayload: SignedPayloadRef(type: PayloadRefType.manifest),
          signer: 'old@example.com',
        );

        final copy = original.copyWith(
          keyId: 'new-key',
          algorithm: SignatureAlgorithm.ed25519,
          value: 'new-val',
          signedPayload:
              const SignedPayloadRef(type: PayloadRefType.contentHash),
          signer: 'new@example.com',
          certificate: 'cert-data',
        );

        expect(copy.keyId, equals('new-key'));
        expect(copy.algorithm, equals(SignatureAlgorithm.ed25519));
        expect(copy.value, equals('new-val'));
        expect(copy.signedPayload.type, equals(PayloadRefType.contentHash));
        expect(copy.signer, equals('new@example.com'));
        expect(copy.certificate, equals('cert-data'));
      });

      test('preserves original values when no overrides given', () {
        const original = Signature(
          keyId: 'keep',
          algorithm: SignatureAlgorithm.ecdsaP384,
          value: 'keep-val',
          signedPayload: SignedPayloadRef(type: PayloadRefType.allSections),
        );

        final copy = original.copyWith();

        expect(copy.keyId, equals('keep'));
        expect(copy.algorithm, equals(SignatureAlgorithm.ecdsaP384));
        expect(copy.value, equals('keep-val'));
        expect(copy.signedPayload.type, equals(PayloadRefType.allSections));
      });
    });
  });

  // ---------------------------------------------------------------------------
  // SignatureAlgorithm
  // ---------------------------------------------------------------------------
  group('SignatureAlgorithm', () {
    group('fromString', () {
      // RSA-SHA256 variants
      test('parses "rsa-sha256"', () {
        expect(
          SignatureAlgorithm.fromString('rsa-sha256'),
          equals(SignatureAlgorithm.rsaSha256),
        );
      });

      test('parses "rsasha256"', () {
        expect(
          SignatureAlgorithm.fromString('rsasha256'),
          equals(SignatureAlgorithm.rsaSha256),
        );
      });

      test('parses "rs256"', () {
        expect(
          SignatureAlgorithm.fromString('rs256'),
          equals(SignatureAlgorithm.rsaSha256),
        );
      });

      // RSA-SHA384 variants
      test('parses "rsa-sha384"', () {
        expect(
          SignatureAlgorithm.fromString('rsa-sha384'),
          equals(SignatureAlgorithm.rsaSha384),
        );
      });

      test('parses "rsasha384"', () {
        expect(
          SignatureAlgorithm.fromString('rsasha384'),
          equals(SignatureAlgorithm.rsaSha384),
        );
      });

      test('parses "rs384"', () {
        expect(
          SignatureAlgorithm.fromString('rs384'),
          equals(SignatureAlgorithm.rsaSha384),
        );
      });

      // RSA-SHA512 variants
      test('parses "rsa-sha512"', () {
        expect(
          SignatureAlgorithm.fromString('rsa-sha512'),
          equals(SignatureAlgorithm.rsaSha512),
        );
      });

      test('parses "rsasha512"', () {
        expect(
          SignatureAlgorithm.fromString('rsasha512'),
          equals(SignatureAlgorithm.rsaSha512),
        );
      });

      test('parses "rs512"', () {
        expect(
          SignatureAlgorithm.fromString('rs512'),
          equals(SignatureAlgorithm.rsaSha512),
        );
      });

      // ECDSA-P256 variants
      test('parses "ecdsa-p256"', () {
        expect(
          SignatureAlgorithm.fromString('ecdsa-p256'),
          equals(SignatureAlgorithm.ecdsaP256),
        );
      });

      test('parses "ecdsap256"', () {
        expect(
          SignatureAlgorithm.fromString('ecdsap256'),
          equals(SignatureAlgorithm.ecdsaP256),
        );
      });

      test('parses "es256"', () {
        expect(
          SignatureAlgorithm.fromString('es256'),
          equals(SignatureAlgorithm.ecdsaP256),
        );
      });

      // ECDSA-P384 variants
      test('parses "ecdsa-p384"', () {
        expect(
          SignatureAlgorithm.fromString('ecdsa-p384'),
          equals(SignatureAlgorithm.ecdsaP384),
        );
      });

      test('parses "ecdsap384"', () {
        expect(
          SignatureAlgorithm.fromString('ecdsap384'),
          equals(SignatureAlgorithm.ecdsaP384),
        );
      });

      test('parses "es384"', () {
        expect(
          SignatureAlgorithm.fromString('es384'),
          equals(SignatureAlgorithm.ecdsaP384),
        );
      });

      // Ed25519
      test('parses "ed25519"', () {
        expect(
          SignatureAlgorithm.fromString('ed25519'),
          equals(SignatureAlgorithm.ed25519),
        );
      });

      // Unknown / null
      test('returns unknown for unrecognised string', () {
        expect(
          SignatureAlgorithm.fromString('hmac-sha256'),
          equals(SignatureAlgorithm.unknown),
        );
      });

      test('returns unknown for null', () {
        expect(
          SignatureAlgorithm.fromString(null),
          equals(SignatureAlgorithm.unknown),
        );
      });

      test('is case-insensitive', () {
        expect(
          SignatureAlgorithm.fromString('RSA-SHA256'),
          equals(SignatureAlgorithm.rsaSha256),
        );
        expect(
          SignatureAlgorithm.fromString('ED25519'),
          equals(SignatureAlgorithm.ed25519),
        );
      });
    });
  });

  // ---------------------------------------------------------------------------
  // SignedPayloadRef
  // ---------------------------------------------------------------------------
  group('SignedPayloadRef', () {
    group('fromJson / toJson', () {
      test('round-trips full JSON', () {
        final json = {
          'type': 'content_hash',
          'hash': 'abc123',
          'hashAlgorithm': 'sha256',
          'url': 'https://example.com/payload',
        };

        final ref = SignedPayloadRef.fromJson(json);
        final output = ref.toJson();

        expect(output['type'], equals('contentHash'));
        expect(output['hash'], equals('abc123'));
        expect(output['hashAlgorithm'], equals('sha256'));
        expect(output['url'], equals('https://example.com/payload'));
      });

      test('handles minimal JSON with defaults', () {
        final ref = SignedPayloadRef.fromJson({});

        expect(ref.type, equals(PayloadRefType.unknown));
        expect(ref.hash, isNull);
        expect(ref.hashAlgorithm, isNull);
        expect(ref.url, isNull);
      });

      test('omits null fields in toJson', () {
        const ref = SignedPayloadRef(type: PayloadRefType.manifest);
        final json = ref.toJson();

        expect(json.containsKey('hash'), isFalse);
        expect(json.containsKey('hashAlgorithm'), isFalse);
        expect(json.containsKey('url'), isFalse);
      });
    });

    group('copyWith', () {
      test('overrides specified fields', () {
        const original = SignedPayloadRef(
          type: PayloadRefType.manifest,
          hash: 'old',
        );

        final copy = original.copyWith(
          type: PayloadRefType.external,
          hash: 'new',
          hashAlgorithm: HashAlgorithm.sha512,
          url: 'https://example.com',
        );

        expect(copy.type, equals(PayloadRefType.external));
        expect(copy.hash, equals('new'));
        expect(copy.hashAlgorithm, equals(HashAlgorithm.sha512));
        expect(copy.url, equals('https://example.com'));
      });

      test('preserves original values when no overrides given', () {
        const original = SignedPayloadRef(
          type: PayloadRefType.allSections,
          hash: 'keep',
          hashAlgorithm: HashAlgorithm.sha384,
        );

        final copy = original.copyWith();

        expect(copy.type, equals(PayloadRefType.allSections));
        expect(copy.hash, equals('keep'));
        expect(copy.hashAlgorithm, equals(HashAlgorithm.sha384));
      });
    });
  });

  // ---------------------------------------------------------------------------
  // PayloadRefType
  // ---------------------------------------------------------------------------
  group('PayloadRefType', () {
    group('fromString', () {
      test('parses "content_hash"', () {
        expect(
          PayloadRefType.fromString('content_hash'),
          equals(PayloadRefType.contentHash),
        );
      });

      test('parses "contenthash"', () {
        expect(
          PayloadRefType.fromString('contenthash'),
          equals(PayloadRefType.contentHash),
        );
      });

      test('parses "manifest"', () {
        expect(
          PayloadRefType.fromString('manifest'),
          equals(PayloadRefType.manifest),
        );
      });

      test('parses "all_sections"', () {
        expect(
          PayloadRefType.fromString('all_sections'),
          equals(PayloadRefType.allSections),
        );
      });

      test('parses "allsections"', () {
        expect(
          PayloadRefType.fromString('allsections'),
          equals(PayloadRefType.allSections),
        );
      });

      test('parses "external"', () {
        expect(
          PayloadRefType.fromString('external'),
          equals(PayloadRefType.external),
        );
      });

      test('returns unknown for unrecognised string', () {
        expect(
          PayloadRefType.fromString('something'),
          equals(PayloadRefType.unknown),
        );
      });

      test('returns unknown for null', () {
        expect(
          PayloadRefType.fromString(null),
          equals(PayloadRefType.unknown),
        );
      });
    });
  });
}
