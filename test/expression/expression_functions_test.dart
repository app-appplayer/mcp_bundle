import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

// Helper to evaluate expression strings through the full evaluator pipeline.
dynamic eval(String source, [Map<String, dynamic>? vars]) {
  final lexer = Lexer(source);
  final tokens = lexer.tokenize();
  final parser = Parser(tokens);
  final expr = parser.parse();
  final ctx = EvaluationContext(variables: vars ?? {});
  final evaluator = ExpressionEvaluator(ctx);
  return evaluator.evaluateOrThrow(expr);
}

void main() {
  late ExpressionFunctions fns;

  setUp(() {
    fns = ExpressionFunctions();
  });

  // ---------------------------------------------------------------------------
  // 1. Registration: register(), has(), call(), unknown function error
  // ---------------------------------------------------------------------------
  group('Registration', () {
    test('has() returns true for a built-in function', () {
      expect(fns.has('upper'), isTrue);
    });

    test('has() returns false for an unknown function', () {
      expect(fns.has('nonExistent'), isFalse);
    });

    test('call() throws ArgumentError for an unknown function', () {
      expect(
        () => fns.call('unknownFunc', <dynamic>[]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('register() adds a custom function callable by name', () {
      fns.register('triple', (args) => (args[0] as int) * 3);
      expect(fns.has('triple'), isTrue);
      expect(fns.call('triple', <dynamic>[4]), 12);
    });

    test('register() can override a built-in function', () {
      fns.register('upper', (args) => 'custom');
      expect(fns.call('upper', <dynamic>['hello']), 'custom');
    });

    test('unknown function via evaluator throws', () {
      expect(
        () => eval("unknownFunc('x')"),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 2. String functions (17)
  // ---------------------------------------------------------------------------
  group('String functions', () {
    test('length returns length of a string', () {
      expect(eval("length('hello')"), 5);
    });

    test('length returns length of a list', () {
      expect(eval('length([1, 2, 3])'), 3);
    });

    test('length returns length of a map', () {
      expect(eval("length({'a': 1, 'b': 2})"), 2);
    });

    test('length returns 0 for non-collection value', () {
      expect(eval('length(42)'), 0);
    });

    test('upper converts string to uppercase', () {
      expect(eval("upper('hello')"), 'HELLO');
    });

    test('lower converts string to lowercase', () {
      expect(eval("lower('HELLO')"), 'hello');
    });

    test('trim removes whitespace from both ends', () {
      expect(eval("trim('  hello  ')"), 'hello');
    });

    test('trimStart removes leading whitespace', () {
      expect(eval("trimStart('  hello  ')"), 'hello  ');
    });

    test('trimEnd removes trailing whitespace', () {
      expect(eval("trimEnd('  hello  ')"), '  hello');
    });

    test('substring extracts with start and end indices', () {
      // Numbers parsed by the expression engine are doubles, but substring
      // internally casts to int. Pass integers via context variables instead.
      final result = eval("substring(s, start, end)", {
        's': 'hello world',
        'start': 0,
        'end': 5,
      });
      expect(result, 'hello');
    });

    test('substring extracts from start index to end of string', () {
      // Same double-to-int cast issue; use context variable for the index.
      final result = eval("substring(s, start)", {
        's': 'hello world',
        'start': 6,
      });
      expect(result, 'world');
    });

    test('replace replaces first occurrence only', () {
      expect(eval("replace('hello hello', 'hello', 'hi')"), 'hi hello');
    });

    test('replaceAll replaces all occurrences', () {
      expect(eval("replaceAll('hello hello', 'hello', 'hi')"), 'hi hi');
    });

    test('split splits string by separator', () {
      expect(eval("split('a,b,c', ',')"), ['a', 'b', 'c']);
    });

    test('join joins list elements with separator', () {
      expect(eval("join(['a', 'b', 'c'], '-')"), 'a-b-c');
    });

    test('join returns empty string for non-list argument', () {
      expect(eval("join(42, ',')"), '');
    });

    test('startsWith returns true when string starts with prefix', () {
      expect(eval("startsWith('hello', 'hel')"), isTrue);
    });

    test('startsWith returns false when string does not start with prefix', () {
      expect(eval("startsWith('hello', 'xyz')"), isFalse);
    });

    test('endsWith returns true when string ends with suffix', () {
      expect(eval("endsWith('hello', 'llo')"), isTrue);
    });

    test('endsWith returns false when string does not end with suffix', () {
      expect(eval("endsWith('hello', 'xyz')"), isFalse);
    });

    test('contains returns true when string contains substring', () {
      expect(eval("contains('hello world', 'world')"), isTrue);
    });

    test('contains returns false when string does not contain substring', () {
      expect(eval("contains('hello', 'xyz')"), isFalse);
    });

    test('contains checks list membership', () {
      expect(eval('contains([1, 2, 3], 2)'), isTrue);
    });

    test('contains checks map key membership', () {
      expect(eval("contains({'a': 1}, 'a')"), isTrue);
    });

    test('indexOf returns index of substring in string', () {
      expect(eval("indexOf('hello', 'lo')"), 3);
    });

    test('indexOf returns -1 when substring is not found', () {
      expect(eval("indexOf('hello', 'xyz')"), -1);
    });

    test('indexOf returns index of element in list', () {
      expect(eval('indexOf([10, 20, 30], 20)'), 1);
    });

    test('padStart pads string from the left with specified character', () {
      expect(eval("padStart('42', 5, '0')"), '00042');
    });

    test('padStart uses space as default pad character', () {
      expect(eval("padStart('hi', 5)"), '   hi');
    });

    test('padEnd pads string from the right with specified character', () {
      expect(eval("padEnd('42', 5, '0')"), '42000');
    });

    test('padEnd uses space as default pad character', () {
      expect(eval("padEnd('hi', 5)"), 'hi   ');
    });
  });

  // ---------------------------------------------------------------------------
  // 3. Math functions (16)
  // ---------------------------------------------------------------------------
  group('Math functions', () {
    test('abs returns absolute value of negative number', () {
      expect(eval('abs(-5)'), 5);
    });

    test('abs returns same value for positive number', () {
      expect(eval('abs(5)'), 5);
    });

    test('ceil rounds up to nearest integer', () {
      expect(eval('ceil(2.3)'), 3);
    });

    test('ceil with negative number', () {
      expect(eval('ceil(-2.3)'), -2);
    });

    test('floor rounds down to nearest integer', () {
      expect(eval('floor(2.7)'), 2);
    });

    test('floor with negative number', () {
      expect(eval('floor(-2.3)'), -3);
    });

    test('round rounds to nearest integer - up', () {
      expect(eval('round(2.5)'), 3);
    });

    test('round rounds to nearest integer - down', () {
      expect(eval('round(2.4)'), 2);
    });

    test('min returns the smallest of given numbers', () {
      expect(eval('min(3, 1, 2)'), 1);
    });

    test('min returns null for empty arguments', () {
      expect(eval('min()'), isNull);
    });

    test('max returns the largest of given numbers', () {
      expect(eval('max(3, 1, 2)'), 3);
    });

    test('max returns null for empty arguments', () {
      expect(eval('max()'), isNull);
    });

    test('sum returns the sum of a list of numbers', () {
      expect(eval('sum([1, 2, 3, 4])'), 10);
    });

    test('sum returns 0 for non-list argument', () {
      expect(eval('sum(42)'), 0);
    });

    test('avg returns the average of a list of numbers', () {
      expect(eval('avg([2, 4, 6])'), 4.0);
    });

    test('avg returns 0 for empty list', () {
      expect(eval('avg([])'), 0);
    });

    test('pow raises base to exponent', () {
      expect(eval('pow(2, 3)'), 8);
    });

    test('pow with exponent 0 returns 1', () {
      expect(eval('pow(5, 0)'), 1);
    });

    test('sqrt returns the square root', () {
      expect(eval('sqrt(9)'), 3.0);
    });

    test('sqrt of 0 returns 0', () {
      expect(eval('sqrt(0)'), 0.0);
    });

    test('log returns the natural logarithm', () {
      final result = eval('log(1)') as double;
      expect(result, closeTo(0.0, 1e-10));
    });

    test('sin returns the sine of 0', () {
      expect(eval('sin(0)'), 0.0);
    });

    test('cos returns the cosine of 0', () {
      expect(eval('cos(0)'), 1.0);
    });

    test('tan returns the tangent of 0', () {
      expect(eval('tan(0)'), 0.0);
    });

    test('random returns a double between 0 and 1', () {
      final result = eval('random()') as double;
      expect(result, greaterThanOrEqualTo(0.0));
      expect(result, lessThan(1.0));
    });

    test('clamp constrains value above maximum to max', () {
      expect(eval('clamp(15, 0, 10)'), 10);
    });

    test('clamp returns value when within range', () {
      expect(eval('clamp(5, 0, 10)'), 5);
    });

    test('clamp constrains value below minimum to min', () {
      expect(eval('clamp(-5, 0, 10)'), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Array functions (21)
  // ---------------------------------------------------------------------------
  group('Array functions', () {
    test('first returns the first element of a list', () {
      expect(eval('first([10, 20, 30])'), 10);
    });

    test('first returns null for empty list', () {
      expect(eval('first([])'), isNull);
    });

    test('first returns null for non-list argument', () {
      expect(eval('first(42)'), isNull);
    });

    test('last returns the last element of a list', () {
      expect(eval('last([10, 20, 30])'), 30);
    });

    test('last returns null for empty list', () {
      expect(eval('last([])'), isNull);
    });

    test('at returns element at given index', () {
      expect(eval('at([10, 20, 30], 1)'), 20);
    });

    test('at returns null for out-of-bounds index', () {
      expect(eval('at([10, 20], 5)'), isNull);
    });

    test('at returns null for negative index', () {
      expect(eval('at([10, 20], -1)'), isNull);
    });

    test('slice returns sub-list with start and end', () {
      expect(eval('slice([1, 2, 3, 4, 5], 1, 3)'), [2, 3]);
    });

    test('slice returns sub-list from start to end of list', () {
      expect(eval('slice([1, 2, 3, 4, 5], 3)'), [4, 5]);
    });

    test('slice returns empty list for non-list argument', () {
      expect(eval('slice(42, 0, 1)'), <dynamic>[]);
    });

    test('reverse returns reversed list', () {
      expect(eval('reverse([1, 2, 3])'), [3, 2, 1]);
    });

    test('reverse returns empty list for non-list argument', () {
      expect(eval('reverse(42)'), <dynamic>[]);
    });

    test('sort returns sorted list of numbers', () {
      expect(eval('sort([3, 1, 2])'), [1, 2, 3]);
    });

    test('sort does not mutate the original list', () {
      final original = <int>[3, 1, 2];
      fns.call('sort', <dynamic>[original]);
      expect(original, <int>[3, 1, 2]);
    });

    test('sort returns sorted list of strings', () {
      expect(eval("sort(['c', 'a', 'b'])"), ['a', 'b', 'c']);
    });

    test('unique removes duplicate elements', () {
      final result = eval('unique([1, 2, 2, 3, 3, 3])') as List;
      expect(result.length, 3);
      expect(result, containsAll([1, 2, 3]));
    });

    test('unique returns empty list for non-list argument', () {
      expect(eval('unique(42)'), <dynamic>[]);
    });

    test('flatten flattens nested lists', () {
      final result = fns.call('flatten', <dynamic>[
        <dynamic>[
          1,
          <dynamic>[
            2,
            <dynamic>[3, 4],
          ],
          5,
        ],
      ]);
      expect(result, [1, 2, 3, 4, 5]);
    });

    test('flatten returns empty list for non-list argument', () {
      expect(fns.call('flatten', <dynamic>[42]), <dynamic>[]);
    });

    test('map transforms each element with a function', () {
      final result = fns.call('map', <dynamic>[
        <int>[1, 2, 3],
        (dynamic x) => (x as int) * 2,
      ]);
      expect(result, [2, 4, 6]);
    });

    test('map returns original list when second arg is not a Function', () {
      final input = <int>[1, 2, 3];
      expect(fns.call('map', <dynamic>[input, 'notAFunction']), input);
    });

    test('filter selects elements matching a predicate', () {
      final result = fns.call('filter', <dynamic>[
        <int>[1, 2, 3, 4, 5],
        (dynamic x) => (x as int) > 3,
      ]);
      expect(result, [4, 5]);
    });

    test('filter returns empty list for non-list argument', () {
      expect(fns.call('filter', <dynamic>[42, (dynamic x) => true]), <dynamic>[]);
    });

    test('reduce accumulates values with an initial value', () {
      final result = fns.call('reduce', <dynamic>[
        <int>[1, 2, 3, 4],
        (dynamic acc, dynamic x) => (acc as int) + (x as int),
        0,
      ]);
      expect(result, 10);
    });

    test('reduce returns initial value when list is not a List', () {
      expect(
        fns.call('reduce', <dynamic>[42, (dynamic a, dynamic b) => a, 0]),
        0,
      );
    });

    test('find returns the first matching element', () {
      final result = fns.call('find', <dynamic>[
        <int>[1, 2, 3, 4],
        (dynamic x) => (x as int) > 2,
      ]);
      expect(result, 3);
    });

    test('find returns null when no element matches', () {
      final result = fns.call('find', <dynamic>[
        <int>[1, 2, 3],
        (dynamic x) => (x as int) > 10,
      ]);
      expect(result, isNull);
    });

    test('findIndex returns the index of the first matching element', () {
      final result = fns.call('findIndex', <dynamic>[
        <int>[10, 20, 30],
        (dynamic x) => (x as int) == 20,
      ]);
      expect(result, 1);
    });

    test('findIndex returns -1 when no element matches', () {
      final result = fns.call('findIndex', <dynamic>[
        <int>[10, 20, 30],
        (dynamic x) => (x as int) == 99,
      ]);
      expect(result, -1);
    });

    test('every returns true when all elements satisfy predicate', () {
      final result = fns.call('every', <dynamic>[
        <int>[2, 4, 6],
        (dynamic x) => (x as int) % 2 == 0,
      ]);
      expect(result, isTrue);
    });

    test('every returns false when some element does not satisfy', () {
      final result = fns.call('every', <dynamic>[
        <int>[2, 3, 6],
        (dynamic x) => (x as int) % 2 == 0,
      ]);
      expect(result, isFalse);
    });

    test('some returns true when at least one element matches', () {
      final result = fns.call('some', <dynamic>[
        <int>[1, 2, 3],
        (dynamic x) => (x as int) == 2,
      ]);
      expect(result, isTrue);
    });

    test('some returns false when no element matches', () {
      final result = fns.call('some', <dynamic>[
        <int>[1, 2, 3],
        (dynamic x) => (x as int) > 10,
      ]);
      expect(result, isFalse);
    });

    test('count returns list length without predicate', () {
      expect(eval('count([1, 2, 3])'), 3);
    });

    test('count returns count of matching elements with predicate', () {
      final result = fns.call('count', <dynamic>[
        <int>[1, 2, 3, 4, 5],
        (dynamic x) => (x as int) > 3,
      ]);
      expect(result, 2);
    });

    test('count returns 0 for non-list argument', () {
      expect(eval('count(42)'), 0);
    });

    test('groupBy groups elements using a function', () {
      final result = fns.call('groupBy', <dynamic>[
        <int>[1, 2, 3, 4, 5, 6],
        (dynamic x) => (x as int) % 2 == 0 ? 'even' : 'odd',
      ]) as Map;
      expect(result['even'], [2, 4, 6]);
      expect(result['odd'], [1, 3, 5]);
    });

    test('groupBy groups maps by string key', () {
      final result = fns.call('groupBy', <dynamic>[
        <Map<String, dynamic>>[
          {'type': 'a', 'v': 1},
          {'type': 'b', 'v': 2},
          {'type': 'a', 'v': 3},
        ],
        'type',
      ]) as Map;
      expect((result['a'] as List).length, 2);
      expect((result['b'] as List).length, 1);
    });

    test('groupBy returns empty map for non-list argument', () {
      expect(fns.call('groupBy', <dynamic>[42, 'key']), <dynamic, dynamic>{});
    });

    test('sortBy sorts elements using a function', () {
      final result = fns.call('sortBy', <dynamic>[
        <int>[3, 1, 2],
        (dynamic x) => x,
      ]);
      expect(result, [1, 2, 3]);
    });

    test('sortBy sorts maps by string key', () {
      final result = fns.call('sortBy', <dynamic>[
        <Map<String, dynamic>>[
          {'name': 'Charlie'},
          {'name': 'Alice'},
          {'name': 'Bob'},
        ],
        'name',
      ]) as List;
      expect((result[0] as Map)['name'], 'Alice');
      expect((result[1] as Map)['name'], 'Bob');
      expect((result[2] as Map)['name'], 'Charlie');
    });

    test('sortBy returns empty list for non-list argument', () {
      expect(fns.call('sortBy', <dynamic>[42, 'key']), <dynamic>[]);
    });

    test('pluck extracts a key from a list of maps', () {
      final result = fns.call('pluck', <dynamic>[
        <Map<String, dynamic>>[
          {'name': 'Alice'},
          {'name': 'Bob'},
        ],
        'name',
      ]);
      expect(result, ['Alice', 'Bob']);
    });

    test('pluck returns null entries for non-map elements', () {
      final result = fns.call('pluck', <dynamic>[
        <dynamic>[42, 'hello'],
        'key',
      ]);
      expect(result, [null, null]);
    });

    test('pluck returns empty list when key is null', () {
      expect(fns.call('pluck', <dynamic>[<dynamic>[1, 2]]), <dynamic>[]);
    });

    test('zip combines multiple lists into tuples', () {
      final result = fns.call('zip', <dynamic>[
        <int>[1, 2, 3],
        <String>['a', 'b', 'c'],
      ]);
      expect(result, [
        [1, 'a'],
        [2, 'b'],
        [3, 'c'],
      ]);
    });

    test('zip truncates to shortest list', () {
      final result = fns.call('zip', <dynamic>[
        <int>[1, 2],
        <String>['a', 'b', 'c'],
      ]) as List;
      expect(result.length, 2);
    });

    test('zip returns empty list when no arguments', () {
      expect(fns.call('zip', <dynamic>[]), <dynamic>[]);
    });

    test('range generates a range with single argument (0 to n)', () {
      expect(eval('range(5)'), [0, 1, 2, 3, 4]);
    });

    test('range generates a range with start and end', () {
      expect(eval('range(2, 5)'), [2, 3, 4]);
    });

    test('range generates a range with custom step', () {
      expect(eval('range(0, 10, 3)'), [0, 3, 6, 9]);
    });

    test('range returns empty list for step of zero', () {
      expect(eval('range(0, 5, 0)'), <int>[]);
    });

    test('range supports negative step', () {
      expect(eval('range(5, 0, -1)'), [5, 4, 3, 2, 1]);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. Object functions (9)
  // ---------------------------------------------------------------------------
  group('Object functions', () {
    test('keys returns list of map keys', () {
      final result = eval("keys({'a': 1, 'b': 2})") as List;
      expect(result, containsAll(['a', 'b']));
    });

    test('keys returns empty list for non-map argument', () {
      expect(eval('keys(42)'), <dynamic>[]);
    });

    test('values returns list of map values', () {
      final result = eval("values({'a': 1, 'b': 2})") as List;
      expect(result, containsAll([1, 2]));
    });

    test('values returns empty list for non-map argument', () {
      expect(eval('values(42)'), <dynamic>[]);
    });

    test('entries returns list of key-value pairs', () {
      final result = eval("entries({'a': 1})") as List;
      expect(result.length, 1);
      expect(result[0], ['a', 1]);
    });

    test('entries returns empty list for non-map argument', () {
      expect(eval('entries(42)'), <dynamic>[]);
    });

    test('fromEntries creates map from key-value pairs', () {
      final result = fns.call('fromEntries', <dynamic>[
        <List<dynamic>>[
          ['a', 1],
          ['b', 2],
        ],
      ]);
      expect(result, {'a': 1, 'b': 2});
    });

    test('fromEntries returns empty map for non-list argument', () {
      expect(fns.call('fromEntries', <dynamic>[42]), <dynamic, dynamic>{});
    });

    test('merge combines multiple maps', () {
      final result = eval("merge({'a': 1}, {'b': 2}, {'c': 3})");
      expect(result, {'a': 1, 'b': 2, 'c': 3});
    });

    test('merge later maps override earlier keys', () {
      final result = eval("merge({'a': 1}, {'a': 99})");
      expect(result, {'a': 99});
    });

    test('pick selects specified keys from map', () {
      final result = eval("pick({'a': 1, 'b': 2, 'c': 3}, 'a', 'c')");
      expect(result, {'a': 1, 'c': 3});
    });

    test('pick ignores keys that do not exist', () {
      final result = eval("pick({'a': 1}, 'a', 'z')");
      expect(result, {'a': 1});
    });

    test('pick returns empty map for non-map argument', () {
      expect(eval("pick(42, 'a')"), <dynamic, dynamic>{});
    });

    test('omit excludes specified keys from map', () {
      final result = eval("omit({'a': 1, 'b': 2, 'c': 3}, 'b')");
      expect(result, {'a': 1, 'c': 3});
    });

    test('omit returns copy of map when no keys to exclude', () {
      final result = eval("omit({'a': 1, 'b': 2})");
      expect(result, {'a': 1, 'b': 2});
    });

    test('get retrieves a top-level value from map', () {
      expect(eval("get({'name': 42}, 'name')"), 42);
    });

    test('get retrieves a nested value via dot notation', () {
      final result = eval("get(data, 'a.b.c')", {
        'data': {
          'a': {
            'b': {'c': 99},
          },
        },
      });
      expect(result, 99);
    });

    test('get returns default value when path not found', () {
      expect(eval("get({'a': 1}, 'x.y.z', 'fallback')"), 'fallback');
    });

    test('get returns null when path not found and no default', () {
      expect(eval("get({'a': 1}, 'missing')"), isNull);
    });

    test('get supports list indexing via dot notation', () {
      final result = eval("get(data, 'items.1')", {
        'data': {
          'items': [10, 20, 30],
        },
      });
      expect(result, 20);
    });

    test('has returns true when map contains key', () {
      expect(eval("has({'a': 1}, 'a')"), isTrue);
    });

    test('has returns false when map does not contain key', () {
      expect(eval("has({'a': 1}, 'b')"), isFalse);
    });

    test('has checks list bounds with integer key', () {
      // The expression engine parses 1 as a double, but _has checks
      // key is int. Pass the index via a context variable to get an actual int.
      expect(eval('has(list, idx)', {'list': [10, 20, 30], 'idx': 1}), isTrue);
    });

    test('has returns false for out-of-bounds list index', () {
      expect(eval('has([10, 20], 5)'), isFalse);
    });

    test('has returns false for non-collection argument', () {
      expect(eval("has(42, 'key')"), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // 6. Type functions (11)
  // ---------------------------------------------------------------------------
  group('Type functions', () {
    test('type returns "null" for null', () {
      // The expression engine stores null as the string 'null', so passing
      // the literal null through the evaluator yields a string. Use a context
      // variable to pass an actual Dart null.
      expect(eval('type(v)', {'v': null}), 'null');
    });

    test('type returns "boolean" for true', () {
      expect(eval('type(true)'), 'boolean');
    });

    test('type returns "boolean" for false', () {
      expect(eval('type(false)'), 'boolean');
    });

    test('type returns "number" for integer', () {
      expect(eval('type(42)'), 'number');
    });

    test('type returns "number" for double', () {
      expect(eval('type(3.14)'), 'number');
    });

    test('type returns "string" for string', () {
      expect(eval("type('hello')"), 'string');
    });

    test('type returns "array" for list', () {
      expect(eval('type([1, 2])'), 'array');
    });

    test('type returns "object" for map', () {
      expect(eval("type({'a': 1})"), 'object');
    });

    test('isNull returns true for null', () {
      // The expression engine stores null as the string 'null'. Use a context
      // variable to pass an actual Dart null.
      expect(eval('isNull(v)', {'v': null}), isTrue);
    });

    test('isNull returns false for non-null value', () {
      expect(eval('isNull(42)'), isFalse);
    });

    test('isNumber returns true for integer', () {
      expect(eval('isNumber(42)'), isTrue);
    });

    test('isNumber returns true for double', () {
      expect(eval('isNumber(3.14)'), isTrue);
    });

    test('isNumber returns false for string', () {
      expect(eval("isNumber('42')"), isFalse);
    });

    test('isString returns true for string', () {
      expect(eval("isString('hello')"), isTrue);
    });

    test('isString returns false for number', () {
      expect(eval('isString(42)'), isFalse);
    });

    test('isBool returns true for boolean true', () {
      expect(eval('isBool(true)'), isTrue);
    });

    test('isBool returns true for boolean false', () {
      expect(eval('isBool(false)'), isTrue);
    });

    test('isBool returns false for non-boolean', () {
      expect(eval('isBool(1)'), isFalse);
    });

    test('isArray returns true for list', () {
      expect(eval('isArray([1])'), isTrue);
    });

    test('isArray returns false for non-list', () {
      expect(eval('isArray(42)'), isFalse);
    });

    test('isObject returns true for map', () {
      expect(eval("isObject({'a': 1})"), isTrue);
    });

    test('isObject returns false for non-map', () {
      expect(eval('isObject(42)'), isFalse);
    });

    test('toNumber returns num as-is', () {
      expect(eval('toNumber(42)'), 42);
    });

    test('toNumber parses string to number', () {
      expect(eval("toNumber('3.14')"), 3.14);
    });

    test('toNumber converts true to 1', () {
      expect(eval('toNumber(true)'), 1);
    });

    test('toNumber converts false to 0', () {
      expect(eval('toNumber(false)'), 0);
    });

    test('toNumber returns null for unparseable string', () {
      expect(eval("toNumber('abc')"), isNull);
    });

    test('toString converts integer to string', () {
      // Note: toString is a keyword in Dart, registered as "toString" function
      expect(fns.call('toString', <dynamic>[42]), '42');
    });

    test('toString converts null to null', () {
      expect(fns.call('toString', <dynamic>[null]), isNull);
    });

    test('toString converts boolean to string', () {
      expect(fns.call('toString', <dynamic>[true]), 'true');
    });

    test('toBool returns true for non-zero number', () {
      expect(eval('toBool(1)'), isTrue);
    });

    test('toBool returns false for zero', () {
      expect(eval('toBool(0)'), isFalse);
    });

    test('toBool returns true for non-empty string', () {
      expect(eval("toBool('hello')"), isTrue);
    });

    test('toBool returns false for empty string', () {
      expect(eval("toBool('')"), isFalse);
    });

    test('toBool returns false for string "false"', () {
      expect(eval("toBool('false')"), isFalse);
    });

    test('toBool returns true for non-empty list', () {
      expect(eval('toBool([1])'), isTrue);
    });

    test('toBool returns false for empty list', () {
      expect(eval('toBool([])'), isFalse);
    });

    test('toBool returns true for non-empty map', () {
      expect(eval("toBool({'a': 1})"), isTrue);
    });

    test('toBool returns false for null', () {
      // The expression engine stores null as the string 'null'. Use a context
      // variable to pass an actual Dart null.
      expect(eval('toBool(v)', {'v': null}), isFalse);
    });

    test('toArray returns list as-is', () {
      expect(eval('toArray([1, 2, 3])'), [1, 2, 3]);
    });

    test('toArray converts map values to list', () {
      final result = eval("toArray({'a': 1, 'b': 2})") as List;
      expect(result, containsAll([1, 2]));
    });

    test('toArray splits string into characters', () {
      expect(eval("toArray('abc')"), ['a', 'b', 'c']);
    });

    test('toArray wraps scalar in a list', () {
      expect(eval('toArray(42)'), [42]);
    });

    test('toArray returns empty list for null', () {
      // The expression engine stores null as the string 'null'. Use a context
      // variable to pass an actual Dart null.
      expect(eval('toArray(v)', {'v': null}), <dynamic>[]);
    });
  });

  // ---------------------------------------------------------------------------
  // 7. Date functions (19)
  // ---------------------------------------------------------------------------
  group('Date functions', () {
    test('now returns a valid ISO 8601 date string', () {
      final result = eval('now()') as String;
      expect(result, isNotNull);
      expect(DateTime.tryParse(result), isNotNull);
    });

    test('today returns a valid ISO 8601 date string', () {
      final result = eval('today()') as String;
      expect(result, isNotNull);
      expect(DateTime.tryParse(result), isNotNull);
    });

    test('today returns a date with midnight time', () {
      final result = eval('today()') as String;
      final dt = DateTime.parse(result);
      expect(dt.hour, 0);
      expect(dt.minute, 0);
      expect(dt.second, 0);
    });

    test('parseDate parses a valid ISO 8601 date string', () {
      final result = eval("parseDate('2024-03-15')");
      expect(result, isNotNull);
      expect(DateTime.tryParse(result as String), isNotNull);
    });

    test('parseDate returns null for invalid date string', () {
      expect(eval("parseDate('not-a-date')"), isNull);
    });

    test('parseDate returns null for null input', () {
      expect(eval('parseDate(null)'), isNull);
    });

    test('formatDate formats a date with default pattern yyyy-MM-dd', () {
      expect(eval("formatDate('2024-03-15T10:30:00')"), '2024-03-15');
    });

    test('formatDate formats a date with custom pattern', () {
      final result = eval(
        "formatDate('2024-03-15T10:30:45', 'yyyy/MM/dd HH:mm:ss')",
      );
      expect(result, '2024/03/15 10:30:45');
    });

    test('formatDate returns null for invalid date', () {
      expect(eval("formatDate('not-a-date')"), isNull);
    });

    test('addDays adds positive days to a date', () {
      final result = eval("addDays('2024-01-01T00:00:00.000', 10)") as String;
      final dt = DateTime.parse(result);
      expect(dt.day, 11);
      expect(dt.month, 1);
    });

    test('addDays subtracts days with negative value', () {
      final result = eval("addDays('2024-01-15T00:00:00.000', -5)") as String;
      final dt = DateTime.parse(result);
      expect(dt.day, 10);
    });

    test('addDays returns null for null date input', () {
      expect(eval('addDays(null, 5)'), isNull);
    });

    test('addHours adds hours to a date', () {
      final result = eval("addHours('2024-01-01T00:00:00.000', 5)") as String;
      final dt = DateTime.parse(result);
      expect(dt.hour, 5);
    });

    test('addMonths adds months to a date', () {
      final result =
          eval("addMonths('2024-01-15T00:00:00.000', 3)") as String;
      final dt = DateTime.parse(result);
      expect(dt.month, 4);
      expect(dt.year, 2024);
    });

    test('addMonths wraps across year boundary', () {
      final result =
          eval("addMonths('2024-11-15T00:00:00.000', 3)") as String;
      final dt = DateTime.parse(result);
      expect(dt.month, 2);
      expect(dt.year, 2025);
    });

    test('addYears adds years to a date', () {
      final result =
          eval("addYears('2024-06-15T00:00:00.000', 2)") as String;
      final dt = DateTime.parse(result);
      expect(dt.year, 2026);
    });

    test('diffDays returns positive difference when first date is later', () {
      final result = eval(
        "diffDays('2024-01-10T00:00:00.000', '2024-01-01T00:00:00.000')",
      );
      expect(result, 9);
    });

    test('diffDays returns negative difference when first date is earlier', () {
      final result = eval(
        "diffDays('2024-01-01T00:00:00.000', '2024-01-10T00:00:00.000')",
      );
      expect(result, -9);
    });

    test('diffDays returns null when a date argument is null', () {
      expect(eval("diffDays(null, '2024-01-01')"), isNull);
    });

    test('diffHours returns difference in hours', () {
      final result = eval(
        "diffHours('2024-01-01T10:00:00.000', '2024-01-01T00:00:00.000')",
      );
      expect(result, 10);
    });

    test('year extracts year from date string', () {
      expect(eval("year('2024-06-15')"), 2024);
    });

    test('year returns null for null input', () {
      expect(eval('year(null)'), isNull);
    });

    test('month extracts month from date string', () {
      expect(eval("month('2024-06-15')"), 6);
    });

    test('day extracts day from date string', () {
      expect(eval("day('2024-06-15')"), 15);
    });

    test('hour extracts hour from date-time string', () {
      expect(eval("hour('2024-06-15T14:30:00')"), 14);
    });

    test('minute extracts minute from date-time string', () {
      expect(eval("minute('2024-06-15T14:30:00')"), 30);
    });

    test('second extracts second from date-time string', () {
      expect(eval("second('2024-06-15T14:30:45')"), 45);
    });

    test('dayOfWeek returns 1 for Monday', () {
      // 2024-01-01 is a Monday
      expect(eval("dayOfWeek('2024-01-01')"), 1);
    });

    test('dayOfWeek returns 7 for Sunday', () {
      // 2024-01-07 is a Sunday
      expect(eval("dayOfWeek('2024-01-07')"), 7);
    });

    test('dayOfWeek returns null for null input', () {
      expect(eval('dayOfWeek(null)'), isNull);
    });

    test('age returns age in years for a past birthdate', () {
      final result = eval("age('2000-01-01')");
      expect(result, isA<int>());
      expect(result as int, greaterThanOrEqualTo(25));
    });

    test('age returns null for invalid date', () {
      expect(eval("age('invalid')"), isNull);
    });

    test('age returns null for null input', () {
      expect(eval('age(null)'), isNull);
    });

    test('duration returns difference in days by default', () {
      final result = eval(
        "duration('2024-01-10T00:00:00.000', '2024-01-01T00:00:00.000')",
      );
      expect(result, 9);
    });

    test('duration returns difference in hours', () {
      final result = eval(
        "duration('2024-01-02T00:00:00.000', '2024-01-01T00:00:00.000', 'hours')",
      );
      expect(result, 24);
    });

    test('duration returns difference in minutes', () {
      final result = eval(
        "duration('2024-01-01T01:00:00.000', '2024-01-01T00:00:00.000', 'minutes')",
      );
      expect(result, 60);
    });

    test('duration returns difference in seconds', () {
      final result = eval(
        "duration('2024-01-01T00:01:00.000', '2024-01-01T00:00:00.000', 'seconds')",
      );
      expect(result, 60);
    });

    test('duration returns difference in milliseconds', () {
      final result = eval(
        "duration('2024-01-01T00:00:01.000', '2024-01-01T00:00:00.000', 'milliseconds')",
      );
      expect(result, 1000);
    });

    test('duration returns difference in weeks', () {
      final result = eval(
        "duration('2024-01-15T00:00:00.000', '2024-01-01T00:00:00.000', 'weeks')",
      );
      expect(result, 2);
    });

    test('duration returns difference in months', () {
      final result = eval(
        "duration('2024-06-01T00:00:00.000', '2024-01-01T00:00:00.000', 'months')",
      );
      expect(result, 5);
    });

    test('duration returns difference in years', () {
      final result = eval(
        "duration('2026-01-01T00:00:00.000', '2024-01-01T00:00:00.000', 'years')",
      );
      expect(result, 2);
    });

    test('duration returns null when first date is null', () {
      expect(eval("duration(null, '2024-01-01')"), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 8. Context stubs (5)
  // ---------------------------------------------------------------------------
  group('Context stubs', () {
    test('fact returns null as a runtime stub', () {
      expect(eval("fact('someFactId')"), isNull);
    });

    test('facts returns empty list as a runtime stub', () {
      expect(eval("facts('query')"), <dynamic>[]);
    });

    test('entity returns null as a runtime stub', () {
      expect(eval("entity('entityId')"), isNull);
    });

    test('summary returns null as a runtime stub', () {
      expect(eval("summary('type')"), isNull);
    });

    test('stepResult returns null as a runtime stub', () {
      expect(eval("stepResult('stepId')"), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 9. Utility functions (7)
  // ---------------------------------------------------------------------------
  group('Utility functions', () {
    test('coalesce returns first non-null value', () {
      // The expression engine stores null as the string 'null', so passing
      // literal null yields a non-null string. Use context variables for
      // actual Dart null values.
      expect(
        eval("coalesce(a, b, 'hello', 42)", {'a': null, 'b': null}),
        'hello',
      );
    });

    test('coalesce returns null when all values are null', () {
      // Same issue: literal null becomes the string 'null'. Use context vars.
      expect(eval('coalesce(a, b, c)', {'a': null, 'b': null, 'c': null}), isNull);
    });

    test('coalesce returns first argument when non-null', () {
      expect(eval('coalesce(42, null)'), 42);
    });

    test('default returns value when non-null', () {
      // "default" is a reserved word; call via ExpressionFunctions directly
      expect(fns.call('default', <dynamic>[42, 0]), 42);
    });

    test('default returns fallback when value is null', () {
      expect(fns.call('default', <dynamic>[null, 'fallback']), 'fallback');
    });

    test('default returns null when both value and fallback are null', () {
      expect(fns.call('default', <dynamic>[null, null]), isNull);
    });

    test('if returns thenVal when condition is true', () {
      // "if" is a reserved word; call via ExpressionFunctions directly
      expect(fns.call('if', <dynamic>[true, 'yes', 'no']), 'yes');
    });

    test('if returns elseVal when condition is false', () {
      expect(fns.call('if', <dynamic>[false, 'yes', 'no']), 'no');
    });

    test('if returns null when condition is false and elseVal not provided', () {
      expect(fns.call('if', <dynamic>[false, 'yes']), isNull);
    });

    test('switch returns matching case value', () {
      // "switch" is a reserved word; call via ExpressionFunctions directly
      expect(
        fns.call('switch', <dynamic>['b', 'a', 1, 'b', 2, 'c', 3]),
        2,
      );
    });

    test('switch returns default value when no match and odd remaining args', () {
      expect(
        fns.call('switch', <dynamic>['z', 'a', 1, 'b', 2, 'default']),
        'default',
      );
    });

    test('switch returns null when no match and no default', () {
      expect(
        fns.call('switch', <dynamic>['z', 'a', 1, 'b', 2]),
        isNull,
      );
    });

    test('switch returns null with fewer than 2 args', () {
      expect(fns.call('switch', <dynamic>['x']), isNull);
    });

    test('switch returns first case when value matches first pair', () {
      expect(
        fns.call('switch', <dynamic>['a', 'a', 100, 'b', 200]),
        100,
      );
    });

    test('format substitutes indexed placeholders with values', () {
      // The expression engine parses 30 as 30.0 (double), so the formatted
      // result includes the decimal. Use a context variable for the integer.
      expect(
        eval("format('Hello {0}, you are {1}!', 'Alice', age)", {'age': 30}),
        'Hello Alice, you are 30!',
      );
    });

    test('format handles template with no placeholders', () {
      expect(eval("format('No placeholders here')"), 'No placeholders here');
    });

    test('format replaces multiple occurrences of same placeholder', () {
      expect(eval("format('{0} and {0}', 'X')"), 'X and X');
    });

    test('format handles null replacement values', () {
      // The expression engine stores null as the string 'null'. Use a context
      // variable to pass an actual Dart null, which format replaces with ''.
      expect(eval("format('Value: {0}', v)", {'v': null}), 'Value: ');
    });

    test('json serializes a map to JSON string', () {
      final result = eval("json({'name': 'Alice', 'age': 30})") as String;
      expect(result, contains('"name"'));
      expect(result, contains('"Alice"'));
      expect(result, contains('"age"'));
      expect(result, contains('30'));
    });

    test('json serializes a list to JSON string', () {
      // The expression engine parses numbers as doubles, so the output
      // includes decimal places. Use context variable with actual int list.
      expect(eval('json(list)', {'list': [1, 2, 3]}), '[1,2,3]');
    });

    test('json returns toString for non-collection', () {
      // The expression engine parses 42 as 42.0 (double). Use a context
      // variable to pass an actual int.
      expect(eval('json(v)', {'v': 42}), '42');
    });

    test('json serializes nested structures', () {
      // Numbers parsed by the expression engine are doubles, so use a context
      // variable with actual int values.
      final result = eval('json(data)', {
        'data': {'items': [1, 2], 'active': true},
      }) as String;
      expect(result, contains('"items"'));
      expect(result, contains('[1,2]'));
      expect(result, contains('true'));
    });

    test('parseJson parses a JSON object string', () {
      final result = fns.call('parseJson', <dynamic>['{"a":1,"b":"hello"}']);
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['a'], 1);
      expect(result['b'], 'hello');
    });

    test('parseJson parses a JSON array string', () {
      final result = fns.call('parseJson', <dynamic>['[1,2,3]']);
      expect(result, [1, 2, 3]);
    });

    test('parseJson parses JSON boolean true', () {
      expect(fns.call('parseJson', <dynamic>['true']), isTrue);
    });

    test('parseJson parses JSON boolean false', () {
      expect(fns.call('parseJson', <dynamic>['false']), isFalse);
    });

    test('parseJson parses JSON null', () {
      expect(fns.call('parseJson', <dynamic>['null']), isNull);
    });

    test('parseJson parses a JSON number', () {
      expect(fns.call('parseJson', <dynamic>['42']), 42);
    });

    test('parseJson parses a JSON decimal number', () {
      expect(fns.call('parseJson', <dynamic>['3.14']), 3.14);
    });

    test('parseJson returns null for null input', () {
      expect(fns.call('parseJson', <dynamic>[null]), isNull);
    });

    test('parseJson parses nested JSON object', () {
      final result = fns.call(
        'parseJson',
        <dynamic>['{"user":{"name":"Alice","age":30}}'],
      );
      expect(result, isA<Map<String, dynamic>>());
      final user = (result as Map)['user'] as Map;
      expect(user['name'], 'Alice');
      expect(user['age'], 30);
    });

    test('parseJson handles whitespace in JSON', () {
      final result = fns.call(
        'parseJson',
        <dynamic>['  { "key" : "value" }  '],
      );
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['key'], 'value');
    });
  });

  // ---------------------------------------------------------------------------
  // 10. Aliases (3)
  // ---------------------------------------------------------------------------
  group('Aliases', () {
    test('distinct is an alias for unique', () {
      final result = fns.call('distinct', <dynamic>[
        <int>[1, 2, 2, 3, 3],
      ]) as List;
      expect(result.length, 3);
      expect(result, containsAll([1, 2, 3]));
    });

    test('date is an alias for parseDate', () {
      final result = fns.call('date', <dynamic>['2024-06-15']);
      expect(result, isNotNull);
      final dt = DateTime.parse(result as String);
      expect(dt.year, 2024);
      expect(dt.month, 6);
      expect(dt.day, 15);
    });

    test('daysBetween is an alias for diffDays', () {
      final result = fns.call(
        'daysBetween',
        <dynamic>['2024-01-10T00:00:00.000', '2024-01-01T00:00:00.000'],
      );
      expect(result, 9);
    });
  });

  // ---------------------------------------------------------------------------
  // Additional evaluator integration tests
  // ---------------------------------------------------------------------------
  group('Evaluator integration', () {
    test('function call with variable arguments', () {
      expect(eval('length(name)', {'name': 'hello'}), 5);
    });

    test('chained function calls', () {
      expect(eval("upper(trim('  hello  '))"), 'HELLO');
    });

    test('function result used in arithmetic', () {
      expect(eval("length('hello') + 10"), 15);
    });

    test('function result used in comparison', () {
      expect(eval("length('hello') > 3"), isTrue);
    });

    test('function result used in logical expression', () {
      expect(eval("startsWith('hello', 'he') and endsWith('hello', 'lo')"), isTrue);
    });

    test('nested function calls with multiple arguments', () {
      expect(eval("contains(split('a,b,c', ','), 'b')"), isTrue);
    });

    test('function with array literal argument', () {
      expect(eval('sum([10, 20, 30])'), 60);
    });

    test('function with object literal argument', () {
      final result = eval("keys({'x': 1, 'y': 2})") as List;
      expect(result, containsAll(['x', 'y']));
    });

    test('math function in complex expression', () {
      expect(eval('abs(-10) + floor(3.7)'), 13);
    });

    test('clamp used to bound a computed value', () {
      expect(eval('clamp(100 + 50, 0, 120)'), 120);
    });
  });
}
