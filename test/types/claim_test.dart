import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  // ── ClaimType ──────────────────────────────────────────────────────────

  group('ClaimType', () {
    group('fromString', () {
      test('parses exact lowercase value', () {
        expect(ClaimType.fromString('fact'), equals(ClaimType.fact));
        expect(ClaimType.fromString('date'), equals(ClaimType.date));
        expect(ClaimType.fromString('amount'), equals(ClaimType.amount));
        expect(ClaimType.fromString('entity'), equals(ClaimType.entity));
      });

      test('parses case-insensitively', () {
        expect(ClaimType.fromString('FACT'), equals(ClaimType.fact));
        expect(ClaimType.fromString('Date'), equals(ClaimType.date));
        expect(ClaimType.fromString('AMOUNT'), equals(ClaimType.amount));
        expect(ClaimType.fromString('Entity'), equals(ClaimType.entity));
        expect(ClaimType.fromString('RELATION'), equals(ClaimType.relation));
      });

      test('defaults to fact for unknown values', () {
        expect(ClaimType.fromString('nonexistent'), equals(ClaimType.fact));
        expect(ClaimType.fromString(''), equals(ClaimType.fact));
        expect(ClaimType.fromString('unknown_type'), equals(ClaimType.fact));
      });

      test('parses all factual types', () {
        expect(ClaimType.fromString('fact'), equals(ClaimType.fact));
        expect(ClaimType.fromString('date'), equals(ClaimType.date));
        expect(ClaimType.fromString('amount'), equals(ClaimType.amount));
        expect(ClaimType.fromString('quantity'), equals(ClaimType.quantity));
        expect(ClaimType.fromString('category'), equals(ClaimType.category));
        expect(ClaimType.fromString('entity'), equals(ClaimType.entity));
        expect(ClaimType.fromString('relation'), equals(ClaimType.relation));
        expect(ClaimType.fromString('temporal'), equals(ClaimType.temporal));
        expect(ClaimType.fromString('causal'), equals(ClaimType.causal));
        expect(
            ClaimType.fromString('comparative'), equals(ClaimType.comparative));
        expect(ClaimType.fromString('quantitative'),
            equals(ClaimType.quantitative));
      });

      test('parses all derived types', () {
        expect(
            ClaimType.fromString('conclusion'), equals(ClaimType.conclusion));
        expect(ClaimType.fromString('recommendation'),
            equals(ClaimType.recommendation));
        expect(
            ClaimType.fromString('speculation'), equals(ClaimType.speculation));
        expect(
            ClaimType.fromString('observation'), equals(ClaimType.observation));
        expect(
            ClaimType.fromString('prediction'), equals(ClaimType.prediction));
        expect(ClaimType.fromString('opinion'), equals(ClaimType.opinion));
        expect(ClaimType.fromString('hypothetical'),
            equals(ClaimType.hypothetical));
      });
    });
  });

  // ── ClaimStatus ────────────────────────────────────────────────────────

  group('ClaimStatus', () {
    group('fromString', () {
      test('parses exact lowercase value', () {
        expect(ClaimStatus.fromString('pending'), equals(ClaimStatus.pending));
        expect(
            ClaimStatus.fromString('verifying'), equals(ClaimStatus.verifying));
        expect(
            ClaimStatus.fromString('supported'), equals(ClaimStatus.supported));
      });

      test('parses case-insensitively', () {
        expect(ClaimStatus.fromString('PENDING'), equals(ClaimStatus.pending));
        expect(
            ClaimStatus.fromString('Supported'), equals(ClaimStatus.supported));
        expect(ClaimStatus.fromString('CONFLICTING'),
            equals(ClaimStatus.conflicting));
      });

      test('handles underscore removal for camelCase enum names', () {
        // 'partially_supported' -> 'partiallysupported' matches 'partiallysupported'
        expect(ClaimStatus.fromString('partially_supported'),
            equals(ClaimStatus.partiallySupported));
        expect(ClaimStatus.fromString('PARTIALLY_SUPPORTED'),
            equals(ClaimStatus.partiallySupported));
      });

      test('parses partiallySupported without underscores', () {
        expect(ClaimStatus.fromString('partiallysupported'),
            equals(ClaimStatus.partiallySupported));
        expect(ClaimStatus.fromString('partiallySupported'),
            equals(ClaimStatus.partiallySupported));
      });

      test('defaults to pending for unknown values', () {
        expect(
            ClaimStatus.fromString('nonexistent'), equals(ClaimStatus.pending));
        expect(ClaimStatus.fromString(''), equals(ClaimStatus.pending));
        expect(ClaimStatus.fromString('invalid'), equals(ClaimStatus.pending));
      });

      test('parses all status values', () {
        expect(ClaimStatus.fromString('pending'), equals(ClaimStatus.pending));
        expect(
            ClaimStatus.fromString('verifying'), equals(ClaimStatus.verifying));
        expect(
            ClaimStatus.fromString('supported'), equals(ClaimStatus.supported));
        expect(ClaimStatus.fromString('unsupported'),
            equals(ClaimStatus.unsupported));
        expect(ClaimStatus.fromString('conflicting'),
            equals(ClaimStatus.conflicting));
        expect(ClaimStatus.fromString('partiallysupported'),
            equals(ClaimStatus.partiallySupported));
        expect(ClaimStatus.fromString('unverifiable'),
            equals(ClaimStatus.unverifiable));
        expect(ClaimStatus.fromString('speculation'),
            equals(ClaimStatus.speculation));
      });
    });
  });

  // ── Claim ──────────────────────────────────────────────────────────────

  group('Claim', () {
    // Shared fixture for a fully-populated claim
    final now = DateTime(2024, 6, 15, 12, 0, 0);
    final verifiedTime = DateTime(2024, 6, 16, 8, 0, 0);

    Claim fullClaim() => Claim(
          id: 'claim-001',
          workspaceId: 'ws-1',
          text: 'The revenue was 5 million',
          type: ClaimType.amount,
          value: 5000000,
          subject: 'Revenue',
          predicate: 'equals',
          object: '5 million',
          sourceId: 'src-1',
          evidenceRefs: ['ev-1', 'ev-2'],
          contradictingRefs: ['ev-3'],
          confidence: 0.85,
          status: ClaimStatus.supported,
          conflictReason: null,
          verifiedAt: verifiedTime,
          createdAt: now,
          metadata: {'source': 'annual_report'},
        );

    // ── fromJson ───────────────────────────────────────────────────────

    group('fromJson', () {
      test('parses a fully populated JSON map', () {
        final json = {
          'id': 'c1',
          'workspaceId': 'ws-1',
          'text': 'Some claim',
          'type': 'fact',
          'value': 42,
          'subject': 'X',
          'predicate': 'is',
          'object': 'Y',
          'sourceId': 'src-1',
          'evidenceRefs': ['e1'],
          'contradictingRefs': ['e2'],
          'confidence': 0.9,
          'status': 'supported',
          'conflictReason': 'reason',
          'verifiedAt': '2024-06-15T12:00:00.000',
          'createdAt': '2024-06-14T10:00:00.000',
          'metadata': {'key': 'value'},
        };

        final claim = Claim.fromJson(json);

        expect(claim.id, equals('c1'));
        expect(claim.workspaceId, equals('ws-1'));
        expect(claim.text, equals('Some claim'));
        expect(claim.type, equals(ClaimType.fact));
        expect(claim.value, equals(42));
        expect(claim.subject, equals('X'));
        expect(claim.predicate, equals('is'));
        expect(claim.object, equals('Y'));
        expect(claim.sourceId, equals('src-1'));
        expect(claim.evidenceRefs, equals(['e1']));
        expect(claim.contradictingRefs, equals(['e2']));
        expect(claim.confidence, equals(0.9));
        expect(claim.status, equals(ClaimStatus.supported));
        expect(claim.conflictReason, equals('reason'));
        expect(claim.verifiedAt, equals(DateTime(2024, 6, 15, 12)));
        expect(claim.createdAt, equals(DateTime(2024, 6, 14, 10)));
        expect(claim.metadata, equals({'key': 'value'}));
      });

      test('applies defaults for missing fields', () {
        final claim = Claim.fromJson({});

        expect(claim.id, equals(''));
        expect(claim.workspaceId, equals('default'));
        expect(claim.text, equals(''));
        expect(claim.type, equals(ClaimType.fact));
        expect(claim.value, isNull);
        expect(claim.subject, isNull);
        expect(claim.predicate, isNull);
        expect(claim.object, isNull);
        expect(claim.sourceId, isNull);
        expect(claim.evidenceRefs, isEmpty);
        expect(claim.contradictingRefs, isEmpty);
        expect(claim.confidence, equals(0.0));
        expect(claim.status, equals(ClaimStatus.pending));
        expect(claim.conflictReason, isNull);
        expect(claim.verifiedAt, isNull);
        expect(claim.createdAt, isNull);
        expect(claim.metadata, isNull);
      });

      test('reads "statement" as alias for "text"', () {
        final claim = Claim.fromJson({
          'id': 'c1',
          'statement': 'Alias text',
        });
        expect(claim.text, equals('Alias text'));
      });

      test('prefers "text" over "statement" when both present', () {
        final claim = Claim.fromJson({
          'id': 'c1',
          'text': 'Primary',
          'statement': 'Fallback',
        });
        expect(claim.text, equals('Primary'));
      });

      test('reads "responseId" as alias for "sourceId"', () {
        final claim = Claim.fromJson({
          'id': 'c1',
          'responseId': 'resp-1',
        });
        expect(claim.sourceId, equals('resp-1'));
      });

      test('prefers "sourceId" over "responseId"', () {
        final claim = Claim.fromJson({
          'id': 'c1',
          'sourceId': 'src-1',
          'responseId': 'resp-1',
        });
        expect(claim.sourceId, equals('src-1'));
      });

      test('reads "supportingEvidenceIds" as alias for "evidenceRefs"', () {
        final claim = Claim.fromJson({
          'id': 'c1',
          'supportingEvidenceIds': ['se1', 'se2'],
        });
        expect(claim.evidenceRefs, equals(['se1', 'se2']));
      });

      test(
          'reads "contradictingEvidenceIds" as alias for "contradictingRefs"',
          () {
        final claim = Claim.fromJson({
          'id': 'c1',
          'contradictingEvidenceIds': ['ce1'],
        });
        expect(claim.contradictingRefs, equals(['ce1']));
      });

      test('reads "verificationStatus" as alias for "status"', () {
        final claim = Claim.fromJson({
          'id': 'c1',
          'verificationStatus': 'supported',
        });
        expect(claim.status, equals(ClaimStatus.supported));
      });

      test('parses confidence from integer', () {
        final claim = Claim.fromJson({
          'id': 'c1',
          'confidence': 1,
        });
        expect(claim.confidence, equals(1.0));
      });
    });

    // ── toJson ─────────────────────────────────────────────────────────

    group('toJson', () {
      test('serialises all populated fields', () {
        final json = fullClaim().toJson();

        expect(json['id'], equals('claim-001'));
        expect(json['workspaceId'], equals('ws-1'));
        expect(json['text'], equals('The revenue was 5 million'));
        expect(json['type'], equals('amount'));
        expect(json['value'], equals(5000000));
        expect(json['subject'], equals('Revenue'));
        expect(json['predicate'], equals('equals'));
        expect(json['object'], equals('5 million'));
        expect(json['sourceId'], equals('src-1'));
        expect(json['evidenceRefs'], equals(['ev-1', 'ev-2']));
        expect(json['contradictingRefs'], equals(['ev-3']));
        expect(json['confidence'], equals(0.85));
        expect(json['status'], equals('supported'));
        expect(json['verifiedAt'], isNotNull);
        expect(json['createdAt'], isNotNull);
        expect(json['metadata'], equals({'source': 'annual_report'}));
      });

      test('omits null optional fields', () {
        final claim = Claim(
          id: 'c1',
          workspaceId: 'ws',
          text: 'test',
          type: ClaimType.fact,
          evidenceRefs: [],
          confidence: 0.5,
        );
        final json = claim.toJson();

        expect(json.containsKey('value'), isFalse);
        expect(json.containsKey('subject'), isFalse);
        expect(json.containsKey('predicate'), isFalse);
        expect(json.containsKey('object'), isFalse);
        expect(json.containsKey('sourceId'), isFalse);
        expect(json.containsKey('conflictReason'), isFalse);
        expect(json.containsKey('verifiedAt'), isFalse);
        expect(json.containsKey('createdAt'), isFalse);
        expect(json.containsKey('metadata'), isFalse);
      });

      test('omits contradictingRefs when empty', () {
        final claim = Claim(
          id: 'c1',
          workspaceId: 'ws',
          text: 'test',
          type: ClaimType.fact,
          evidenceRefs: [],
          confidence: 0.5,
        );
        expect(claim.toJson().containsKey('contradictingRefs'), isFalse);
      });
    });

    // ── JSON roundtrip ─────────────────────────────────────────────────

    group('JSON roundtrip', () {
      test('fully populated claim survives roundtrip', () {
        final original = fullClaim();
        final restored = Claim.fromJson(original.toJson());

        expect(restored.id, equals(original.id));
        expect(restored.workspaceId, equals(original.workspaceId));
        expect(restored.text, equals(original.text));
        expect(restored.type, equals(original.type));
        expect(restored.value, equals(original.value));
        expect(restored.subject, equals(original.subject));
        expect(restored.predicate, equals(original.predicate));
        expect(restored.object, equals(original.object));
        expect(restored.sourceId, equals(original.sourceId));
        expect(restored.evidenceRefs, equals(original.evidenceRefs));
        expect(
            restored.contradictingRefs, equals(original.contradictingRefs));
        expect(restored.confidence, equals(original.confidence));
        expect(restored.status, equals(original.status));
        expect(restored.verifiedAt, equals(original.verifiedAt));
        expect(restored.createdAt, equals(original.createdAt));
        expect(restored.metadata, equals(original.metadata));
      });

      test('minimal claim survives roundtrip', () {
        final original = Claim(
          id: 'min',
          workspaceId: 'ws',
          text: 'minimal',
          type: ClaimType.fact,
          evidenceRefs: [],
          confidence: 0.0,
        );
        final restored = Claim.fromJson(original.toJson());

        expect(restored.id, equals(original.id));
        expect(restored.text, equals(original.text));
        expect(restored.type, equals(original.type));
      });
    });

    // ── copyWith ───────────────────────────────────────────────────────

    group('copyWith', () {
      test('returns equal claim when no overrides given', () {
        final original = fullClaim();
        final copied = original.copyWith();

        expect(copied.id, equals(original.id));
        expect(copied.text, equals(original.text));
        expect(copied.confidence, equals(original.confidence));
        expect(copied.status, equals(original.status));
      });

      test('overrides specified fields only', () {
        final original = fullClaim();
        final copied = original.copyWith(
          text: 'Updated text',
          confidence: 0.99,
          status: ClaimStatus.conflicting,
        );

        expect(copied.text, equals('Updated text'));
        expect(copied.confidence, equals(0.99));
        expect(copied.status, equals(ClaimStatus.conflicting));
        // Unchanged fields
        expect(copied.id, equals(original.id));
        expect(copied.workspaceId, equals(original.workspaceId));
        expect(copied.type, equals(original.type));
      });

      test('can override id and workspaceId', () {
        final original = fullClaim();
        final copied = original.copyWith(
          id: 'new-id',
          workspaceId: 'new-ws',
        );
        expect(copied.id, equals('new-id'));
        expect(copied.workspaceId, equals('new-ws'));
      });
    });

    // ── isVerified ─────────────────────────────────────────────────────

    group('isVerified', () {
      test('returns true for supported status', () {
        final claim = fullClaim().copyWith(status: ClaimStatus.supported);
        expect(claim.isVerified, isTrue);
      });

      test('returns true for unsupported status', () {
        final claim = fullClaim().copyWith(status: ClaimStatus.unsupported);
        expect(claim.isVerified, isTrue);
      });

      test('returns true for conflicting status', () {
        final claim = fullClaim().copyWith(status: ClaimStatus.conflicting);
        expect(claim.isVerified, isTrue);
      });

      test('returns true for partiallySupported status', () {
        final claim =
            fullClaim().copyWith(status: ClaimStatus.partiallySupported);
        expect(claim.isVerified, isTrue);
      });

      test('returns false for pending status', () {
        final claim = fullClaim().copyWith(status: ClaimStatus.pending);
        expect(claim.isVerified, isFalse);
      });

      test('returns false for verifying status', () {
        final claim = fullClaim().copyWith(status: ClaimStatus.verifying);
        expect(claim.isVerified, isFalse);
      });

      test('returns false for unverifiable status', () {
        final claim = fullClaim().copyWith(status: ClaimStatus.unverifiable);
        expect(claim.isVerified, isFalse);
      });

      test('returns false for speculation status', () {
        final claim = fullClaim().copyWith(status: ClaimStatus.speculation);
        expect(claim.isVerified, isFalse);
      });
    });

    // ── isSupported ────────────────────────────────────────────────────

    group('isSupported', () {
      test('returns true only for supported status', () {
        expect(
          fullClaim().copyWith(status: ClaimStatus.supported).isSupported,
          isTrue,
        );
      });

      test('returns false for non-supported statuses', () {
        for (final status in ClaimStatus.values
            .where((s) => s != ClaimStatus.supported)) {
          expect(
            fullClaim().copyWith(status: status).isSupported,
            isFalse,
            reason: '${status.name} should not be isSupported',
          );
        }
      });
    });

    // ── hasRdfStructure ────────────────────────────────────────────────

    group('hasRdfStructure', () {
      test('returns true when subject is set', () {
        final claim = Claim(
          id: 'c1',
          workspaceId: 'ws',
          text: 't',
          type: ClaimType.fact,
          subject: 'S',
          evidenceRefs: [],
          confidence: 0.5,
        );
        expect(claim.hasRdfStructure, isTrue);
      });

      test('returns true when predicate is set', () {
        final claim = Claim(
          id: 'c1',
          workspaceId: 'ws',
          text: 't',
          type: ClaimType.fact,
          predicate: 'P',
          evidenceRefs: [],
          confidence: 0.5,
        );
        expect(claim.hasRdfStructure, isTrue);
      });

      test('returns true when object is set', () {
        final claim = Claim(
          id: 'c1',
          workspaceId: 'ws',
          text: 't',
          type: ClaimType.fact,
          object: 'O',
          evidenceRefs: [],
          confidence: 0.5,
        );
        expect(claim.hasRdfStructure, isTrue);
      });

      test('returns false when no RDF fields are set', () {
        final claim = Claim(
          id: 'c1',
          workspaceId: 'ws',
          text: 't',
          type: ClaimType.fact,
          evidenceRefs: [],
          confidence: 0.5,
        );
        expect(claim.hasRdfStructure, isFalse);
      });
    });

    // ── equality / hashCode ────────────────────────────────────────────

    group('equality and hashCode', () {
      test('claims with same id are equal', () {
        final a = Claim(
          id: 'same',
          workspaceId: 'ws-a',
          text: 'text-a',
          type: ClaimType.fact,
          evidenceRefs: [],
          confidence: 0.5,
        );
        final b = Claim(
          id: 'same',
          workspaceId: 'ws-b',
          text: 'text-b',
          type: ClaimType.opinion,
          evidenceRefs: ['e1'],
          confidence: 0.9,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('claims with different ids are not equal', () {
        final a = Claim(
          id: 'id-a',
          workspaceId: 'ws',
          text: 'same text',
          type: ClaimType.fact,
          evidenceRefs: [],
          confidence: 0.5,
        );
        final b = Claim(
          id: 'id-b',
          workspaceId: 'ws',
          text: 'same text',
          type: ClaimType.fact,
          evidenceRefs: [],
          confidence: 0.5,
        );
        expect(a, isNot(equals(b)));
      });

      test('identical claim equals itself', () {
        final claim = fullClaim();
        expect(claim, equals(claim));
      });
    });

    // ── toString ───────────────────────────────────────────────────────

    group('toString', () {
      test('includes id, text, and status', () {
        final claim = fullClaim();
        final str = claim.toString();
        expect(str, contains('claim-001'));
        expect(str, contains('The revenue was 5 million'));
        expect(str, contains('supported'));
      });
    });
  });
}
