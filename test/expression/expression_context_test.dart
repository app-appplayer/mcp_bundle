import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('EvaluationContext', () {
    test('creates with empty variables', () {
      final ctx = EvaluationContext();
      expect(ctx.allVariables, isEmpty);
    });

    test('get returns value for set variable', () {
      final ctx = EvaluationContext(variables: {'x': 42});
      expect(ctx.get('x'), 42);
    });

    test('get returns null for undefined variable', () {
      final ctx = EvaluationContext();
      expect(ctx.get('x'), isNull);
    });

    test('has returns true for existing variable', () {
      final ctx = EvaluationContext(variables: {'x': 42});
      expect(ctx.has('x'), isTrue);
    });

    test('has returns false for missing variable', () {
      final ctx = EvaluationContext();
      expect(ctx.has('x'), isFalse);
    });

    test('set adds new variable', () {
      final ctx = EvaluationContext();
      ctx.set('x', 42);
      expect(ctx.get('x'), 42);
      expect(ctx.has('x'), isTrue);
    });

    test('set overwrites existing variable', () {
      final ctx = EvaluationContext(variables: {'x': 1});
      ctx.set('x', 2);
      expect(ctx.get('x'), 2);
    });

    test('allVariables returns all variables', () {
      final ctx = EvaluationContext(variables: {'a': 1, 'b': 2});
      expect(ctx.allVariables, {'a': 1, 'b': 2});
    });

    test('child creates context with parent chain', () {
      final parent = EvaluationContext(variables: {'x': 1});
      final child = parent.child({'y': 2});
      expect(child.has('x'), isTrue);
      expect(child.has('y'), isTrue);
      expect(child.get('x'), 1);
      expect(child.get('y'), 2);
    });

    test('child context inherits parent variables', () {
      final parent = EvaluationContext(variables: {'a': 10});
      final child = parent.child();
      expect(child.get('a'), 10);
    });

    test('child context overrides parent variables', () {
      final parent = EvaluationContext(variables: {'a': 10});
      final child = parent.child({'a': 20});
      expect(child.get('a'), 20);
    });

    test('deep parent chain resolution', () {
      final root = EvaluationContext(variables: {'x': 1});
      final mid = root.child({'y': 2});
      final leaf = mid.child({'z': 3});
      expect(leaf.get('x'), 1);
      expect(leaf.get('y'), 2);
      expect(leaf.get('z'), 3);
    });

    test('allVariables includes parent variables', () {
      final parent = EvaluationContext(variables: {'a': 1});
      final child = parent.child({'b': 2});
      expect(child.allVariables, {'a': 1, 'b': 2});
    });

    test('allVariables child overrides parent', () {
      final parent = EvaluationContext(variables: {'a': 1});
      final child = parent.child({'a': 99});
      expect(child.allVariables, {'a': 99});
    });

    test('child shares same functions instance', () {
      final parent = EvaluationContext();
      final child = parent.child();
      expect(identical(parent.functions, child.functions), isTrue);
    });

    test('has returns true for variable with null value', () {
      final ctx = EvaluationContext(variables: {'x': null});
      expect(ctx.has('x'), isTrue);
      expect(ctx.get('x'), isNull);
    });

    group('factory EvaluationContext.from()', () {
      test('populates inputs namespace', () {
        final ctx = EvaluationContext.from(inputs: {'name': 'Alice'});
        expect(ctx.get('inputs'), {'name': 'Alice'});
      });

      test('populates steps namespace', () {
        final ctx = EvaluationContext.from(steps: {'step1': 'done'});
        expect(ctx.get('steps'), {'step1': 'done'});
      });

      test('populates context namespace', () {
        final ctx = EvaluationContext.from(context: {'env': 'prod'});
        expect(ctx.get('context'), {'env': 'prod'});
      });

      test('populates state namespace', () {
        final ctx = EvaluationContext.from(state: {'count': 0});
        expect(ctx.get('state'), {'count': 0});
      });

      test('populates extra variables at top level', () {
        final ctx = EvaluationContext.from(extra: {'x': 42, 'y': 'hello'});
        expect(ctx.get('x'), 42);
        expect(ctx.get('y'), 'hello');
      });

      test('handles all null maps gracefully', () {
        final ctx = EvaluationContext.from();
        expect(ctx.allVariables, isEmpty);
      });

      test('combines multiple namespaces', () {
        final ctx = EvaluationContext.from(
          inputs: {'a': 1},
          state: {'b': 2},
          extra: {'c': 3},
        );
        expect(ctx.get('inputs'), {'a': 1});
        expect(ctx.get('state'), {'b': 2});
        expect(ctx.get('c'), 3);
      });
    });
  });

  group('EvaluationResult', () {
    test('success creates with value', () {
      const result = EvaluationResult.success(42);
      expect(result.value, 42);
      expect(result.success, isTrue);
      expect(result.error, isNull);
    });

    test('success with null value', () {
      const result = EvaluationResult.success(null);
      expect(result.value, isNull);
      expect(result.success, isTrue);
    });

    test('failure creates with error message', () {
      const result = EvaluationResult.failure('something went wrong');
      expect(result.value, isNull);
      expect(result.success, isFalse);
      expect(result.error, 'something went wrong');
    });

    test('success toString format', () {
      const result = EvaluationResult.success(42);
      expect(result.toString(), 'Success(42)');
    });

    test('failure toString format', () {
      const result = EvaluationResult.failure('error');
      expect(result.toString(), 'Failure(error)');
    });
  });
}
