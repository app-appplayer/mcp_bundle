/// Canonical Period type for time span representation.
///
/// Supports both relative (e.g., "last 30 days") and absolute
/// (e.g., "2025-01-01 to 2025-03-31") time spans.
library;

/// Period unit for relative periods.
enum PeriodUnit {
  minutes,
  hours,
  days,
  weeks,
  months,
  years;

  /// Parse from string.
  static PeriodUnit fromString(String value) {
    return PeriodUnit.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => throw ArgumentError('Unknown period unit: $value'),
    );
  }
}

/// Direction of relative period from reference time.
enum PeriodDirection {
  /// Period extends into the past (default).
  past,

  /// Period extends into the future.
  future,

  /// Period extends both directions (centered on reference).
  around;

  /// Parse from string.
  static PeriodDirection fromString(String value) {
    return PeriodDirection.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => PeriodDirection.past,
    );
  }
}

/// Base class for Period types.
sealed class Period {
  const Period();

  /// Create a relative period.
  const factory Period.relative({
    required PeriodUnit unit,
    required int value,
    PeriodDirection direction,
  }) = RelativePeriod;

  /// Create an absolute period.
  const factory Period.absolute({
    required DateTime start,
    required DateTime end,
  }) = AbsolutePeriod;

  /// Parse from JSON.
  factory Period.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'relative':
        return RelativePeriod.fromJson(json);
      case 'absolute':
        return AbsolutePeriod.fromJson(json);
      default:
        throw ArgumentError('Unknown period type: $type');
    }
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson();

  /// Resolve to DateRange at the given reference time.
  DateRange resolve([DateTime? referenceTime]);
}

/// Relative period - a duration from reference time.
///
/// By default, extends into the past. Use [direction] to change this:
/// - [PeriodDirection.past]: "last N units" (default)
/// - [PeriodDirection.future]: "next N units"
/// - [PeriodDirection.around]: "N units before and after"
class RelativePeriod extends Period {
  final PeriodUnit unit;
  final int value;
  final PeriodDirection direction;

  const RelativePeriod({
    required this.unit,
    required this.value,
    this.direction = PeriodDirection.past,
  });

  factory RelativePeriod.fromJson(Map<String, dynamic> json) {
    return RelativePeriod(
      unit: PeriodUnit.fromString(json['unit'] as String),
      value: json['value'] as int,
      direction: json['direction'] != null
          ? PeriodDirection.fromString(json['direction'] as String)
          : PeriodDirection.past,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'relative',
        'unit': unit.name,
        'value': value,
        'direction': direction.name,
      };

  @override
  DateRange resolve([DateTime? referenceTime]) {
    final ref = referenceTime ?? DateTime.now();

    switch (direction) {
      case PeriodDirection.past:
        return DateRange(start: _subtractDuration(ref), end: ref);
      case PeriodDirection.future:
        return DateRange(start: ref, end: _addDuration(ref));
      case PeriodDirection.around:
        final halfValue = value ~/ 2;
        final halfPeriod = RelativePeriod(unit: unit, value: halfValue);
        return DateRange(
          start: halfPeriod._subtractDuration(ref),
          end: halfPeriod._addDuration(ref),
        );
    }
  }

  DateTime _addDuration(DateTime from) {
    switch (unit) {
      case PeriodUnit.minutes:
        return from.add(Duration(minutes: value));
      case PeriodUnit.hours:
        return from.add(Duration(hours: value));
      case PeriodUnit.days:
        return from.add(Duration(days: value));
      case PeriodUnit.weeks:
        return from.add(Duration(days: value * 7));
      case PeriodUnit.months:
        return DateTime(from.year, from.month + value, from.day);
      case PeriodUnit.years:
        return DateTime(from.year + value, from.month, from.day);
    }
  }

  DateTime _subtractDuration(DateTime from) {
    switch (unit) {
      case PeriodUnit.minutes:
        return from.subtract(Duration(minutes: value));
      case PeriodUnit.hours:
        return from.subtract(Duration(hours: value));
      case PeriodUnit.days:
        return from.subtract(Duration(days: value));
      case PeriodUnit.weeks:
        return from.subtract(Duration(days: value * 7));
      case PeriodUnit.months:
        return DateTime(from.year, from.month - value, from.day);
      case PeriodUnit.years:
        return DateTime(from.year - value, from.month, from.day);
    }
  }

  @override
  String toString() =>
      'RelativePeriod($value ${unit.name}, direction: ${direction.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelativePeriod &&
          unit == other.unit &&
          value == other.value &&
          direction == other.direction;

  @override
  int get hashCode => Object.hash(unit, value, direction);
}

/// Absolute period - a fixed date range.
class AbsolutePeriod extends Period {
  final DateTime start;
  final DateTime end;

  const AbsolutePeriod({required this.start, required this.end});

  factory AbsolutePeriod.fromJson(Map<String, dynamic> json) {
    return AbsolutePeriod(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'absolute',
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      };

  @override
  DateRange resolve([DateTime? referenceTime]) {
    return DateRange(start: start, end: end);
  }

  @override
  String toString() => 'AbsolutePeriod($start to $end)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AbsolutePeriod && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Helper class for resolved date ranges.
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  /// Duration of the range.
  Duration get duration => end.difference(start);

  /// Check if a date is within this range (inclusive).
  bool contains(DateTime date) =>
      (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
      (date.isBefore(end) || date.isAtSameMomentAs(end));

  @override
  String toString() => 'DateRange($start to $end)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}
