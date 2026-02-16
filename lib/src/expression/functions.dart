/// Built-in functions for Expression Language.
///
/// Provides 40+ functions for string, math, array, object, and date operations.
library;

import 'dart:math' as math;

/// Type alias for expression functions.
typedef ExprFunction = dynamic Function(List<dynamic> args);

/// Registry of built-in expression functions.
class ExpressionFunctions {
  final Map<String, ExprFunction> _functions = {};

  ExpressionFunctions() {
    _registerBuiltins();
  }

  /// Register a custom function.
  void register(String name, ExprFunction fn) {
    _functions[name] = fn;
  }

  /// Check if a function exists.
  bool has(String name) => _functions.containsKey(name);

  /// Call a function by name.
  dynamic call(String name, List<dynamic> args) {
    final fn = _functions[name];
    if (fn == null) {
      throw ArgumentError('Unknown function: $name');
    }
    return fn(args);
  }

  void _registerBuiltins() {
    // String functions
    _functions['length'] = _length;
    _functions['upper'] = _upper;
    _functions['lower'] = _lower;
    _functions['trim'] = _trim;
    _functions['trimStart'] = _trimStart;
    _functions['trimEnd'] = _trimEnd;
    _functions['substring'] = _substring;
    _functions['replace'] = _replace;
    _functions['replaceAll'] = _replaceAll;
    _functions['split'] = _split;
    _functions['join'] = _join;
    _functions['startsWith'] = _startsWith;
    _functions['endsWith'] = _endsWith;
    _functions['contains'] = _contains;
    _functions['indexOf'] = _indexOf;
    _functions['padStart'] = _padStart;
    _functions['padEnd'] = _padEnd;

    // Math functions
    _functions['abs'] = _abs;
    _functions['ceil'] = _ceil;
    _functions['floor'] = _floor;
    _functions['round'] = _round;
    _functions['min'] = _min;
    _functions['max'] = _max;
    _functions['sum'] = _sum;
    _functions['avg'] = _avg;
    _functions['pow'] = _pow;
    _functions['sqrt'] = _sqrt;
    _functions['log'] = _log;
    _functions['sin'] = _sin;
    _functions['cos'] = _cos;
    _functions['tan'] = _tan;
    _functions['random'] = _random;
    _functions['clamp'] = _clamp;

    // Array functions
    _functions['first'] = _first;
    _functions['last'] = _last;
    _functions['at'] = _at;
    _functions['slice'] = _slice;
    _functions['reverse'] = _reverse;
    _functions['sort'] = _sort;
    _functions['unique'] = _unique;
    _functions['flatten'] = _flatten;
    _functions['map'] = _map;
    _functions['filter'] = _filter;
    _functions['reduce'] = _reduce;
    _functions['find'] = _find;
    _functions['findIndex'] = _findIndex;
    _functions['every'] = _every;
    _functions['some'] = _some;
    _functions['count'] = _count;
    _functions['groupBy'] = _groupBy;
    _functions['sortBy'] = _sortBy;
    _functions['pluck'] = _pluck;
    _functions['zip'] = _zip;
    _functions['range'] = _range;

    // Object functions
    _functions['keys'] = _keys;
    _functions['values'] = _values;
    _functions['entries'] = _entries;
    _functions['fromEntries'] = _fromEntries;
    _functions['merge'] = _merge;
    _functions['pick'] = _pick;
    _functions['omit'] = _omit;
    _functions['get'] = _get;
    _functions['has'] = _has;

    // Type functions
    _functions['type'] = _type;
    _functions['isNull'] = _isNull;
    _functions['isNumber'] = _isNumber;
    _functions['isString'] = _isString;
    _functions['isBool'] = _isBool;
    _functions['isArray'] = _isArray;
    _functions['isObject'] = _isObject;
    _functions['toNumber'] = _toNumber;
    _functions['toString'] = _toStringFn;
    _functions['toBool'] = _toBool;
    _functions['toArray'] = _toArray;

    // Date functions
    _functions['now'] = _now;
    _functions['today'] = _today;
    _functions['parseDate'] = _parseDate;
    _functions['formatDate'] = _formatDate;
    _functions['addDays'] = _addDays;
    _functions['addMonths'] = _addMonths;
    _functions['addYears'] = _addYears;
    _functions['diffDays'] = _diffDays;
    _functions['year'] = _year;
    _functions['month'] = _month;
    _functions['day'] = _day;
    _functions['hour'] = _hour;
    _functions['minute'] = _minute;
    _functions['second'] = _second;
    _functions['dayOfWeek'] = _dayOfWeek;

    // Utility functions
    _functions['coalesce'] = _coalesce;
    _functions['default'] = _defaultFn;
    _functions['if'] = _ifFn;
    _functions['switch'] = _switchFn;
    _functions['format'] = _format;
    _functions['json'] = _json;
    _functions['parseJson'] = _parseJson;
  }

  // String functions
  dynamic _length(List<dynamic> args) {
    final val = args.firstOrNull;
    if (val is String) return val.length;
    if (val is List) return val.length;
    if (val is Map) return val.length;
    return 0;
  }

  dynamic _upper(List<dynamic> args) => args.firstOrNull?.toString().toUpperCase();
  dynamic _lower(List<dynamic> args) => args.firstOrNull?.toString().toLowerCase();
  dynamic _trim(List<dynamic> args) => args.firstOrNull?.toString().trim();
  dynamic _trimStart(List<dynamic> args) => args.firstOrNull?.toString().trimLeft();
  dynamic _trimEnd(List<dynamic> args) => args.firstOrNull?.toString().trimRight();

  dynamic _substring(List<dynamic> args) {
    final str = args.firstOrNull?.toString() ?? '';
    final start = (args.length > 1 ? args[1] as int? : 0) ?? 0;
    final end = args.length > 2 ? args[2] as int? : null;
    return str.substring(start, end);
  }

  dynamic _replace(List<dynamic> args) {
    final str = args.firstOrNull?.toString() ?? '';
    final from = args.length > 1 ? args[1].toString() : '';
    final to = args.length > 2 ? args[2].toString() : '';
    return str.replaceFirst(from, to);
  }

  dynamic _replaceAll(List<dynamic> args) {
    final str = args.firstOrNull?.toString() ?? '';
    final from = args.length > 1 ? args[1].toString() : '';
    final to = args.length > 2 ? args[2].toString() : '';
    return str.replaceAll(from, to);
  }

  dynamic _split(List<dynamic> args) {
    final str = args.firstOrNull?.toString() ?? '';
    final sep = args.length > 1 ? args[1].toString() : '';
    return str.split(sep);
  }

  dynamic _join(List<dynamic> args) {
    final list = args.firstOrNull;
    if (list is! List) return '';
    final sep = args.length > 1 ? args[1].toString() : '';
    return list.map((e) => e?.toString() ?? '').join(sep);
  }

  dynamic _startsWith(List<dynamic> args) {
    final str = args.firstOrNull?.toString() ?? '';
    final prefix = args.length > 1 ? args[1].toString() : '';
    return str.startsWith(prefix);
  }

  dynamic _endsWith(List<dynamic> args) {
    final str = args.firstOrNull?.toString() ?? '';
    final suffix = args.length > 1 ? args[1].toString() : '';
    return str.endsWith(suffix);
  }

  dynamic _contains(List<dynamic> args) {
    final val = args.firstOrNull;
    final search = args.length > 1 ? args[1] : null;
    if (val is String) return val.contains(search.toString());
    if (val is List) return val.contains(search);
    if (val is Map) return val.containsKey(search);
    return false;
  }

  dynamic _indexOf(List<dynamic> args) {
    final val = args.firstOrNull;
    final search = args.length > 1 ? args[1] : null;
    if (val is String) return val.indexOf(search.toString());
    if (val is List) return val.indexOf(search);
    return -1;
  }

  dynamic _padStart(List<dynamic> args) {
    final str = args.firstOrNull?.toString() ?? '';
    final len = args.length > 1 ? (args[1] as num).toInt() : 0;
    final pad = args.length > 2 ? args[2].toString() : ' ';
    return str.padLeft(len, pad);
  }

  dynamic _padEnd(List<dynamic> args) {
    final str = args.firstOrNull?.toString() ?? '';
    final len = args.length > 1 ? (args[1] as num).toInt() : 0;
    final pad = args.length > 2 ? args[2].toString() : ' ';
    return str.padRight(len, pad);
  }

  // Math functions
  dynamic _abs(List<dynamic> args) => (args.firstOrNull as num?)?.abs();
  dynamic _ceil(List<dynamic> args) => (args.firstOrNull as num?)?.ceil();
  dynamic _floor(List<dynamic> args) => (args.firstOrNull as num?)?.floor();
  dynamic _round(List<dynamic> args) => (args.firstOrNull as num?)?.round();

  dynamic _min(List<dynamic> args) {
    final nums = args.whereType<num>().toList();
    if (nums.isEmpty) return null;
    return nums.reduce((a, b) => a < b ? a : b);
  }

  dynamic _max(List<dynamic> args) {
    final nums = args.whereType<num>().toList();
    if (nums.isEmpty) return null;
    return nums.reduce((a, b) => a > b ? a : b);
  }

  dynamic _sum(List<dynamic> args) {
    final list = args.firstOrNull;
    if (list is! List) return 0;
    return list.whereType<num>().fold<num>(0, (a, b) => a + b);
  }

  dynamic _avg(List<dynamic> args) {
    final list = args.firstOrNull;
    if (list is! List || list.isEmpty) return 0;
    final nums = list.whereType<num>().toList();
    if (nums.isEmpty) return 0;
    return nums.fold<num>(0, (a, b) => a + b) / nums.length;
  }

  dynamic _pow(List<dynamic> args) {
    final base = args.firstOrNull as num? ?? 0;
    final exp = args.length > 1 ? args[1] as num : 1;
    return math.pow(base, exp);
  }

  dynamic _sqrt(List<dynamic> args) => math.sqrt((args.firstOrNull as num?) ?? 0);
  dynamic _log(List<dynamic> args) => math.log((args.firstOrNull as num?) ?? 1);
  dynamic _sin(List<dynamic> args) => math.sin((args.firstOrNull as num?) ?? 0);
  dynamic _cos(List<dynamic> args) => math.cos((args.firstOrNull as num?) ?? 0);
  dynamic _tan(List<dynamic> args) => math.tan((args.firstOrNull as num?) ?? 0);
  dynamic _random(List<dynamic> args) => math.Random().nextDouble();

  dynamic _clamp(List<dynamic> args) {
    final val = args.firstOrNull as num? ?? 0;
    final minVal = args.length > 1 ? args[1] as num : 0;
    final maxVal = args.length > 2 ? args[2] as num : 1;
    return val.clamp(minVal, maxVal);
  }

  // Array functions
  dynamic _first(List<dynamic> args) {
    final list = args.firstOrNull;
    if (list is! List || list.isEmpty) return null;
    return list.first;
  }

  dynamic _last(List<dynamic> args) {
    final list = args.firstOrNull;
    if (list is! List || list.isEmpty) return null;
    return list.last;
  }

  dynamic _at(List<dynamic> args) {
    final list = args.firstOrNull;
    final index = args.length > 1 ? (args[1] as num).toInt() : 0;
    if (list is! List) return null;
    if (index < 0 || index >= list.length) return null;
    return list[index];
  }

  dynamic _slice(List<dynamic> args) {
    final list = args.firstOrNull;
    if (list is! List) return [];
    final start = args.length > 1 ? (args[1] as num).toInt() : 0;
    final end = args.length > 2 ? (args[2] as num).toInt() : list.length;
    return list.sublist(start.clamp(0, list.length), end.clamp(0, list.length));
  }

  dynamic _reverse(List<dynamic> args) {
    final list = args.firstOrNull;
    if (list is! List) return [];
    return list.reversed.toList();
  }

  dynamic _sort(List<dynamic> args) {
    final list = args.firstOrNull;
    if (list is! List) return [];
    final sorted = List.from(list);
    sorted.sort((a, b) => Comparable.compare(a as Comparable, b as Comparable));
    return sorted;
  }

  dynamic _unique(List<dynamic> args) {
    final list = args.firstOrNull;
    if (list is! List) return [];
    return list.toSet().toList();
  }

  dynamic _flatten(List<dynamic> args) {
    final list = args.firstOrNull;
    if (list is! List) return [];
    return _flattenDeep(list);
  }

  List<dynamic> _flattenDeep(List<dynamic> list) {
    final result = <dynamic>[];
    for (final item in list) {
      if (item is List) {
        result.addAll(_flattenDeep(item));
      } else {
        result.add(item);
      }
    }
    return result;
  }

  dynamic _map(List<dynamic> args) {
    final list = args.firstOrNull;
    final fn = args.length > 1 ? args[1] : null;
    if (list is! List) return [];
    if (fn is! Function) return list;
    return list.map((e) => Function.apply(fn, [e])).toList();
  }

  dynamic _filter(List<dynamic> args) {
    final list = args.firstOrNull;
    final fn = args.length > 1 ? args[1] : null;
    if (list is! List) return [];
    if (fn is! Function) return list;
    return list.where((e) => Function.apply(fn, [e]) == true).toList();
  }

  dynamic _reduce(List<dynamic> args) {
    final list = args.firstOrNull;
    final fn = args.length > 1 ? args[1] : null;
    final initial = args.length > 2 ? args[2] : null;
    if (list is! List) return initial;
    if (fn is! Function) return initial;
    return list.fold(initial, (acc, e) => Function.apply(fn, [acc, e]));
  }

  dynamic _find(List<dynamic> args) {
    final list = args.firstOrNull;
    final fn = args.length > 1 ? args[1] : null;
    if (list is! List) return null;
    if (fn is! Function) return null;
    for (final e in list) {
      if (Function.apply(fn, [e]) == true) return e;
    }
    return null;
  }

  dynamic _findIndex(List<dynamic> args) {
    final list = args.firstOrNull;
    final fn = args.length > 1 ? args[1] : null;
    if (list is! List) return -1;
    if (fn is! Function) return -1;
    for (var i = 0; i < list.length; i++) {
      if (Function.apply(fn, [list[i]]) == true) return i;
    }
    return -1;
  }

  dynamic _every(List<dynamic> args) {
    final list = args.firstOrNull;
    final fn = args.length > 1 ? args[1] : null;
    if (list is! List) return true;
    if (fn is! Function) return true;
    return list.every((e) => Function.apply(fn, [e]) == true);
  }

  dynamic _some(List<dynamic> args) {
    final list = args.firstOrNull;
    final fn = args.length > 1 ? args[1] : null;
    if (list is! List) return false;
    if (fn is! Function) return false;
    return list.any((e) => Function.apply(fn, [e]) == true);
  }

  dynamic _count(List<dynamic> args) {
    final list = args.firstOrNull;
    final fn = args.length > 1 ? args[1] : null;
    if (list is! List) return 0;
    if (fn == null) return list.length;
    if (fn is! Function) return list.length;
    return list.where((e) => Function.apply(fn, [e]) == true).length;
  }

  dynamic _groupBy(List<dynamic> args) {
    final list = args.firstOrNull;
    final key = args.length > 1 ? args[1] : null;
    if (list is! List) return {};
    final result = <dynamic, List<dynamic>>{};
    for (final item in list) {
      dynamic k;
      if (key is Function) {
        k = Function.apply(key, [item]);
      } else if (key is String && item is Map) {
        k = item[key];
      } else {
        k = item;
      }
      result.putIfAbsent(k, () => []).add(item);
    }
    return result;
  }

  dynamic _sortBy(List<dynamic> args) {
    final list = args.firstOrNull;
    final key = args.length > 1 ? args[1] : null;
    if (list is! List) return [];
    final sorted = List.from(list);
    sorted.sort((a, b) {
      dynamic ka, kb;
      if (key is Function) {
        ka = Function.apply(key, [a]);
        kb = Function.apply(key, [b]);
      } else if (key is String) {
        ka = (a is Map) ? a[key] : a;
        kb = (b is Map) ? b[key] : b;
      } else {
        ka = a;
        kb = b;
      }
      return Comparable.compare(ka as Comparable, kb as Comparable);
    });
    return sorted;
  }

  dynamic _pluck(List<dynamic> args) {
    final list = args.firstOrNull;
    final key = args.length > 1 ? args[1] : null;
    if (list is! List || key == null) return [];
    return list.map((e) => (e is Map) ? e[key] : null).toList();
  }

  dynamic _zip(List<dynamic> args) {
    if (args.isEmpty) return [];
    final lists = args.whereType<List>().toList();
    if (lists.isEmpty) return [];
    final minLen = lists.map((l) => l.length).reduce(math.min);
    final result = <List<dynamic>>[];
    for (var i = 0; i < minLen; i++) {
      result.add(lists.map((l) => l[i]).toList());
    }
    return result;
  }

  dynamic _range(List<dynamic> args) {
    final start = args.isNotEmpty ? (args[0] as num).toInt() : 0;
    final end = args.length > 1 ? (args[1] as num).toInt() : start;
    final step = args.length > 2 ? (args[2] as num).toInt() : 1;
    final actualStart = args.length > 1 ? start : 0;
    final actualEnd = args.length > 1 ? end : start;
    if (step == 0) return [];
    final result = <int>[];
    if (step > 0) {
      for (var i = actualStart; i < actualEnd; i += step) {
        result.add(i);
      }
    } else {
      for (var i = actualStart; i > actualEnd; i += step) {
        result.add(i);
      }
    }
    return result;
  }

  // Object functions
  dynamic _keys(List<dynamic> args) {
    final obj = args.firstOrNull;
    if (obj is! Map) return [];
    return obj.keys.toList();
  }

  dynamic _values(List<dynamic> args) {
    final obj = args.firstOrNull;
    if (obj is! Map) return [];
    return obj.values.toList();
  }

  dynamic _entries(List<dynamic> args) {
    final obj = args.firstOrNull;
    if (obj is! Map) return [];
    return obj.entries.map((e) => [e.key, e.value]).toList();
  }

  dynamic _fromEntries(List<dynamic> args) {
    final entries = args.firstOrNull;
    if (entries is! List) return {};
    final result = <dynamic, dynamic>{};
    for (final entry in entries) {
      if (entry is List && entry.length >= 2) {
        result[entry[0]] = entry[1];
      }
    }
    return result;
  }

  dynamic _merge(List<dynamic> args) {
    final result = <dynamic, dynamic>{};
    for (final arg in args) {
      if (arg is Map) {
        result.addAll(arg);
      }
    }
    return result;
  }

  dynamic _pick(List<dynamic> args) {
    final obj = args.firstOrNull;
    final keys = args.length > 1 ? args.sublist(1) : [];
    if (obj is! Map) return {};
    final result = <dynamic, dynamic>{};
    for (final key in keys) {
      if (obj.containsKey(key)) {
        result[key] = obj[key];
      }
    }
    return result;
  }

  dynamic _omit(List<dynamic> args) {
    final obj = args.firstOrNull;
    final keys = args.length > 1 ? args.sublist(1).toSet() : <dynamic>{};
    if (obj is! Map) return {};
    final result = <dynamic, dynamic>{};
    for (final entry in obj.entries) {
      if (!keys.contains(entry.key)) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  dynamic _get(List<dynamic> args) {
    final obj = args.firstOrNull;
    final path = args.length > 1 ? args[1] : null;
    final defaultValue = args.length > 2 ? args[2] : null;
    if (obj == null || path == null) return defaultValue;

    final parts = path.toString().split('.');
    dynamic current = obj;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else if (current is List) {
        final index = int.tryParse(part);
        if (index != null && index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return defaultValue;
        }
      } else {
        return defaultValue;
      }
    }
    return current;
  }

  dynamic _has(List<dynamic> args) {
    final obj = args.firstOrNull;
    final key = args.length > 1 ? args[1] : null;
    if (obj is Map) return obj.containsKey(key);
    if (obj is List && key is int) return key >= 0 && key < obj.length;
    return false;
  }

  // Type functions
  dynamic _type(List<dynamic> args) {
    final val = args.firstOrNull;
    if (val == null) return 'null';
    if (val is bool) return 'boolean';
    if (val is num) return 'number';
    if (val is String) return 'string';
    if (val is List) return 'array';
    if (val is Map) return 'object';
    return 'unknown';
  }

  dynamic _isNull(List<dynamic> args) => args.firstOrNull == null;
  dynamic _isNumber(List<dynamic> args) => args.firstOrNull is num;
  dynamic _isString(List<dynamic> args) => args.firstOrNull is String;
  dynamic _isBool(List<dynamic> args) => args.firstOrNull is bool;
  dynamic _isArray(List<dynamic> args) => args.firstOrNull is List;
  dynamic _isObject(List<dynamic> args) => args.firstOrNull is Map;

  dynamic _toNumber(List<dynamic> args) {
    final val = args.firstOrNull;
    if (val is num) return val;
    if (val is String) return num.tryParse(val);
    if (val is bool) return val ? 1 : 0;
    return null;
  }

  dynamic _toStringFn(List<dynamic> args) => args.firstOrNull?.toString();

  dynamic _toBool(List<dynamic> args) {
    final val = args.firstOrNull;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) return val.isNotEmpty && val != 'false';
    if (val is List) return val.isNotEmpty;
    if (val is Map) return val.isNotEmpty;
    return val != null;
  }

  dynamic _toArray(List<dynamic> args) {
    final val = args.firstOrNull;
    if (val is List) return val;
    if (val is Map) return val.values.toList();
    if (val is String) return val.split('');
    if (val == null) return [];
    return [val];
  }

  // Date functions
  dynamic _now(List<dynamic> args) => DateTime.now().toIso8601String();
  dynamic _today(List<dynamic> args) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).toIso8601String();
  }

  dynamic _parseDate(List<dynamic> args) {
    final str = args.firstOrNull?.toString();
    if (str == null) return null;
    return DateTime.tryParse(str)?.toIso8601String();
  }

  dynamic _formatDate(List<dynamic> args) {
    final dateStr = args.firstOrNull?.toString();
    final format = args.length > 1 ? args[1].toString() : 'yyyy-MM-dd';
    if (dateStr == null) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;
    return _formatDateTime(date, format);
  }

  String _formatDateTime(DateTime date, String format) {
    var result = format;
    result = result.replaceAll('yyyy', date.year.toString().padLeft(4, '0'));
    result = result.replaceAll('MM', date.month.toString().padLeft(2, '0'));
    result = result.replaceAll('dd', date.day.toString().padLeft(2, '0'));
    result = result.replaceAll('HH', date.hour.toString().padLeft(2, '0'));
    result = result.replaceAll('mm', date.minute.toString().padLeft(2, '0'));
    result = result.replaceAll('ss', date.second.toString().padLeft(2, '0'));
    return result;
  }

  dynamic _addDays(List<dynamic> args) {
    final dateStr = args.firstOrNull?.toString();
    final days = args.length > 1 ? (args[1] as num).toInt() : 0;
    if (dateStr == null) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;
    return date.add(Duration(days: days)).toIso8601String();
  }

  dynamic _addMonths(List<dynamic> args) {
    final dateStr = args.firstOrNull?.toString();
    final months = args.length > 1 ? (args[1] as num).toInt() : 0;
    if (dateStr == null) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;
    return DateTime(date.year, date.month + months, date.day).toIso8601String();
  }

  dynamic _addYears(List<dynamic> args) {
    final dateStr = args.firstOrNull?.toString();
    final years = args.length > 1 ? (args[1] as num).toInt() : 0;
    if (dateStr == null) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;
    return DateTime(date.year + years, date.month, date.day).toIso8601String();
  }

  dynamic _diffDays(List<dynamic> args) {
    final date1Str = args.firstOrNull?.toString();
    final date2Str = args.length > 1 ? args[1].toString() : null;
    if (date1Str == null || date2Str == null) return null;
    final date1 = DateTime.tryParse(date1Str);
    final date2 = DateTime.tryParse(date2Str);
    if (date1 == null || date2 == null) return null;
    return date1.difference(date2).inDays;
  }

  dynamic _year(List<dynamic> args) {
    final dateStr = args.firstOrNull?.toString();
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr)?.year;
  }

  dynamic _month(List<dynamic> args) {
    final dateStr = args.firstOrNull?.toString();
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr)?.month;
  }

  dynamic _day(List<dynamic> args) {
    final dateStr = args.firstOrNull?.toString();
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr)?.day;
  }

  dynamic _hour(List<dynamic> args) {
    final dateStr = args.firstOrNull?.toString();
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr)?.hour;
  }

  dynamic _minute(List<dynamic> args) {
    final dateStr = args.firstOrNull?.toString();
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr)?.minute;
  }

  dynamic _second(List<dynamic> args) {
    final dateStr = args.firstOrNull?.toString();
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr)?.second;
  }

  dynamic _dayOfWeek(List<dynamic> args) {
    final dateStr = args.firstOrNull?.toString();
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr)?.weekday;
  }

  // Utility functions
  dynamic _coalesce(List<dynamic> args) {
    for (final arg in args) {
      if (arg != null) return arg;
    }
    return null;
  }

  dynamic _defaultFn(List<dynamic> args) {
    final val = args.firstOrNull;
    final defaultVal = args.length > 1 ? args[1] : null;
    return val ?? defaultVal;
  }

  dynamic _ifFn(List<dynamic> args) {
    final condition = args.firstOrNull;
    final thenVal = args.length > 1 ? args[1] : null;
    final elseVal = args.length > 2 ? args[2] : null;
    return (condition == true) ? thenVal : elseVal;
  }

  dynamic _switchFn(List<dynamic> args) {
    if (args.length < 2) return null;
    final value = args[0];
    for (var i = 1; i < args.length - 1; i += 2) {
      if (args[i] == value) {
        return args[i + 1];
      }
    }
    // Last argument is default if odd number of remaining args
    if ((args.length - 1) % 2 == 1) {
      return args.last;
    }
    return null;
  }

  dynamic _format(List<dynamic> args) {
    final template = args.firstOrNull?.toString() ?? '';
    final values = args.length > 1 ? args.sublist(1) : [];
    var result = template;
    for (var i = 0; i < values.length; i++) {
      result = result.replaceAll('{$i}', values[i]?.toString() ?? '');
    }
    return result;
  }

  dynamic _json(List<dynamic> args) {
    final val = args.firstOrNull;
    if (val is Map || val is List) {
      return _jsonEncode(val);
    }
    return val?.toString();
  }

  String _jsonEncode(dynamic val) {
    if (val == null) return 'null';
    if (val is bool) return val.toString();
    if (val is num) return val.toString();
    if (val is String) return '"${val.replaceAll('"', '\\"')}"';
    if (val is List) {
      return '[${val.map(_jsonEncode).join(',')}]';
    }
    if (val is Map) {
      final entries = val.entries.map((e) => '"${e.key}":${_jsonEncode(e.value)}');
      return '{${entries.join(',')}}';
    }
    return '"$val"';
  }

  dynamic _parseJson(List<dynamic> args) {
    final str = args.firstOrNull?.toString();
    if (str == null) return null;
    // Simple JSON parsing (for production, use dart:convert)
    return _parseJsonValue(str.trim(), 0).$1;
  }

  (dynamic, int) _parseJsonValue(String str, int pos) {
    if (pos >= str.length) return (null, pos);

    final char = str[pos];

    if (char == '"') {
      return _parseJsonString(str, pos);
    }
    if (char == '[') {
      return _parseJsonArray(str, pos);
    }
    if (char == '{') {
      return _parseJsonObject(str, pos);
    }
    if (char == 't' && str.substring(pos).startsWith('true')) {
      return (true, pos + 4);
    }
    if (char == 'f' && str.substring(pos).startsWith('false')) {
      return (false, pos + 5);
    }
    if (char == 'n' && str.substring(pos).startsWith('null')) {
      return (null, pos + 4);
    }
    if (char == '-' || (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57)) {
      return _parseJsonNumber(str, pos);
    }

    return (null, pos);
  }

  (String, int) _parseJsonString(String str, int pos) {
    final buffer = StringBuffer();
    pos++; // Skip opening quote
    while (pos < str.length && str[pos] != '"') {
      if (str[pos] == '\\' && pos + 1 < str.length) {
        pos++;
        buffer.write(str[pos]);
      } else {
        buffer.write(str[pos]);
      }
      pos++;
    }
    return (buffer.toString(), pos + 1); // Skip closing quote
  }

  (num, int) _parseJsonNumber(String str, int pos) {
    final start = pos;
    if (str[pos] == '-') pos++;
    while (pos < str.length && (str[pos].codeUnitAt(0) >= 48 && str[pos].codeUnitAt(0) <= 57 || str[pos] == '.')) {
      pos++;
    }
    return (num.parse(str.substring(start, pos)), pos);
  }

  (List<dynamic>, int) _parseJsonArray(String str, int pos) {
    final result = <dynamic>[];
    pos++; // Skip '['
    pos = _skipWhitespace(str, pos);

    if (pos < str.length && str[pos] == ']') {
      return (result, pos + 1);
    }

    while (pos < str.length) {
      pos = _skipWhitespace(str, pos);
      final (value, newPos) = _parseJsonValue(str, pos);
      result.add(value);
      pos = _skipWhitespace(str, newPos);

      if (pos >= str.length || str[pos] == ']') break;
      if (str[pos] == ',') pos++;
    }

    return (result, pos + 1); // Skip ']'
  }

  (Map<String, dynamic>, int) _parseJsonObject(String str, int pos) {
    final result = <String, dynamic>{};
    pos++; // Skip '{'
    pos = _skipWhitespace(str, pos);

    if (pos < str.length && str[pos] == '}') {
      return (result, pos + 1);
    }

    while (pos < str.length) {
      pos = _skipWhitespace(str, pos);
      final (key, keyEnd) = _parseJsonString(str, pos);
      pos = _skipWhitespace(str, keyEnd);
      if (pos < str.length && str[pos] == ':') pos++;
      pos = _skipWhitespace(str, pos);
      final (value, valueEnd) = _parseJsonValue(str, pos);
      result[key] = value;
      pos = _skipWhitespace(str, valueEnd);

      if (pos >= str.length || str[pos] == '}') break;
      if (str[pos] == ',') pos++;
    }

    return (result, pos + 1); // Skip '}'
  }

  int _skipWhitespace(String str, int pos) {
    while (pos < str.length && ' \t\n\r'.contains(str[pos])) {
      pos++;
    }
    return pos;
  }
}
