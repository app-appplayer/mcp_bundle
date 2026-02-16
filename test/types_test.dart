import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  group('Period', () {
    group('RelativePeriod', () {
      test('creates relative period', () {
        const period = RelativePeriod(unit: PeriodUnit.days, value: 30);

        expect(period.unit, equals(PeriodUnit.days));
        expect(period.value, equals(30));
      });

      test('resolves to date range', () {
        const period = RelativePeriod(unit: PeriodUnit.days, value: 7);
        final ref = DateTime(2024, 6, 15);
        final range = period.resolve(ref);

        expect(range.end, equals(ref));
        expect(range.start, equals(DateTime(2024, 6, 8)));
      });

      test('serializes and deserializes correctly', () {
        const original = RelativePeriod(unit: PeriodUnit.months, value: 3);

        final json = original.toJson();
        final restored = Period.fromJson(json);

        expect(restored, isA<RelativePeriod>());
        final relative = restored as RelativePeriod;
        expect(relative.unit, equals(original.unit));
        expect(relative.value, equals(original.value));
      });
    });

    group('AbsolutePeriod', () {
      test('creates absolute period', () {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 12, 31);
        final period = AbsolutePeriod(start: start, end: end);

        expect(period.start, equals(start));
        expect(period.end, equals(end));
      });

      test('resolves to same date range', () {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 12, 31);
        final period = AbsolutePeriod(start: start, end: end);
        final range = period.resolve();

        expect(range.start, equals(start));
        expect(range.end, equals(end));
      });

      test('serializes and deserializes correctly', () {
        final original = AbsolutePeriod(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 6, 30),
        );

        final json = original.toJson();
        final restored = Period.fromJson(json);

        expect(restored, isA<AbsolutePeriod>());
        final absolute = restored as AbsolutePeriod;
        expect(absolute.start, equals(original.start));
        expect(absolute.end, equals(original.end));
      });
    });

    group('DateRange', () {
      test('calculates duration', () {
        final range = DateRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 8),
        );

        expect(range.duration.inDays, equals(7));
      });

      test('contains checks date inclusion', () {
        final range = DateRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 12, 31),
        );

        expect(range.contains(DateTime(2024, 6, 15)), isTrue);
        expect(range.contains(DateTime(2023, 6, 15)), isFalse);
        expect(range.contains(DateTime(2025, 1, 1)), isFalse);
      });
    });
  });

  group('Confidence', () {
    test('clamp keeps value in range', () {
      expect(Confidence.clamp(0.5), equals(0.5));
      expect(Confidence.clamp(-0.5), equals(0.0));
      expect(Confidence.clamp(1.5), equals(1.0));
    });

    test('average calculates correctly', () {
      expect(Confidence.average([0.6, 0.8, 1.0]), closeTo(0.8, 0.0001));
      expect(Confidence.average([]), equals(0.0));
    });

    test('minimum finds lowest value', () {
      expect(Confidence.minimum([0.6, 0.3, 0.9]), equals(0.3));
      expect(Confidence.minimum([]), equals(0.0));
    });

    test('weighted average calculates correctly', () {
      final scores = [0.5, 1.0];
      final weights = [1.0, 1.0];
      expect(Confidence.weightedAverage(scores, weights), equals(0.75));
    });
  });

  group('ConfidenceLevel', () {
    test('fromScore returns correct level', () {
      expect(ConfidenceLevel.fromScore(0.1), equals(ConfidenceLevel.veryLow));
      expect(ConfidenceLevel.fromScore(0.4), equals(ConfidenceLevel.low));
      expect(ConfidenceLevel.fromScore(0.6), equals(ConfidenceLevel.medium));
      expect(ConfidenceLevel.fromScore(0.8), equals(ConfidenceLevel.high));
      expect(ConfidenceLevel.fromScore(1.0), equals(ConfidenceLevel.veryHigh));
    });

    test('throws on invalid score', () {
      expect(() => ConfidenceLevel.fromScore(-0.1), throwsArgumentError);
      expect(() => ConfidenceLevel.fromScore(1.1), throwsArgumentError);
    });
  });

  group('PeriodUnit', () {
    test('fromString parses correctly', () {
      expect(PeriodUnit.fromString('days'), equals(PeriodUnit.days));
      expect(PeriodUnit.fromString('weeks'), equals(PeriodUnit.weeks));
      expect(PeriodUnit.fromString('months'), equals(PeriodUnit.months));
      expect(PeriodUnit.fromString('years'), equals(PeriodUnit.years));
    });

    test('fromString throws on unknown unit', () {
      expect(() => PeriodUnit.fromString('unknown'), throwsArgumentError);
    });
  });
}
