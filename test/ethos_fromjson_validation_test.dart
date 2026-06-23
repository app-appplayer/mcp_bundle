/// Ethos object-graph `fromJson` field-named validation (0.4.4).
///
/// A missing required field must throw a clear `<owner>.fromJson: ... '<field>'`
/// FormatException instead of an opaque `Null is not a subtype of String`,
/// while a fully valid ethos still round-trips unchanged.
library;

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

Map<String, dynamic> _validEthosJson() => <String, dynamic>{
      'id': 'e1',
      'name': 'Test Ethos',
      'valuePriorities': <Map<String, dynamic>>[
        {
          'id': 'vp1',
          'rank': 1,
          'higherValue': 'safety',
          'lowerValue': 'speed',
          'rationale': 'safety first',
        },
      ],
      'prohibitions': <Map<String, dynamic>>[
        {
          'id': 'p1',
          'statement': 'never leak secrets',
          'severity': 'hard',
          'rationale': 'confidentiality',
        },
      ],
      'metadata': <String, dynamic>{
        'version': '1.0.0',
        'createdAt': '2026-06-23T00:00:00.000Z',
        'updatedAt': '2026-06-23T00:00:00.000Z',
      },
    };

void main() {
  group('Ethos.fromJson validation (0.4.4)', () {
    test('a fully valid ethos round-trips unchanged', () {
      final ethos = Ethos.fromJson(_validEthosJson());
      expect(ethos.id, 'e1');
      expect(ethos.prohibitions.single.rationale, 'confidentiality');
      expect(ethos.metadata.version, '1.0.0');
      // toJson → fromJson is stable.
      final round = Ethos.fromJson(ethos.toJson());
      expect(round.id, ethos.id);
      expect(round.valuePriorities.single.higherValue, 'safety');
    });

    test('Prohibition.forbiddenPatterns round-trips (default empty)', () {
      // Absent → empty.
      final base = Ethos.fromJson(_validEthosJson());
      expect(base.prohibitions.single.forbiddenPatterns, isEmpty);

      // Present → preserved through toJson/fromJson.
      final j = _validEthosJson();
      ((j['prohibitions'] as List).first as Map)['forbiddenPatterns'] =
          <String>['xyzzy', 'plugh'];
      final ethos = Ethos.fromJson(j);
      expect(ethos.prohibitions.single.forbiddenPatterns, ['xyzzy', 'plugh']);
      final round = Ethos.fromJson(ethos.toJson());
      expect(round.prohibitions.single.forbiddenPatterns, ['xyzzy', 'plugh']);
    });

    test('missing top-level field names the field (Ethos)', () {
      final j = _validEthosJson()..remove('name');
      expect(
        () => Ethos.fromJson(j),
        throwsA(isA<FormatException>().having(
            (e) => e.message, 'message', allOf(contains('Ethos'), contains("'name'")))),
      );
    });

    test('missing prohibition.rationale names the field (Prohibition)', () {
      final j = _validEthosJson();
      ((j['prohibitions'] as List).first as Map).remove('rationale');
      expect(
        () => Ethos.fromJson(j),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            allOf(contains('Prohibition'), contains("'rationale'")))),
      );
    });

    test('missing metadata.version names the field (EthosMetadata)', () {
      final j = _validEthosJson();
      (j['metadata'] as Map).remove('version');
      expect(
        () => Ethos.fromJson(j),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            allOf(contains('EthosMetadata'), contains("'version'")))),
      );
    });

    test('invalid metadata.createdAt date names the field', () {
      final j = _validEthosJson();
      (j['metadata'] as Map)['createdAt'] = 'not-a-date';
      expect(
        () => Ethos.fromJson(j),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            allOf(contains('EthosMetadata'), contains("'createdAt'")))),
      );
    });

    test('valuePriorities not a list names the field (Ethos)', () {
      final j = _validEthosJson()..['valuePriorities'] = 'oops';
      expect(
        () => Ethos.fromJson(j),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            allOf(contains('Ethos'), contains("'valuePriorities'")))),
      );
    });
  });
}
