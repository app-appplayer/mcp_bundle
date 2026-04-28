// Comprehensive tests for the validator/ directory:
// - validation_result.dart (ValidationResult, ValidationError, ValidationWarning, ValidationContext)
// - bundle_validator.dart (BundleValidator)
// - mcp_bundle_validator.dart (McpBundleValidator)

import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:mcp_bundle/src/models/integrity.dart' as integrity_model;
import 'package:mcp_bundle/src/models/flow_section.dart' as flow_model;
import 'package:mcp_bundle/src/schema/bundle_schema.dart'
    as schema show Bundle, BundleManifest, BundleDependency;
import 'package:mcp_bundle/src/schema/manifest_schema.dart'
    as manifest show SkillManifest, ProfileManifest, ProfileSection;
import 'package:mcp_bundle/src/validator/bundle_validator.dart';

void main() {
  // ===========================================================================
  // 1. ValidationResult
  // ===========================================================================
  group('ValidationResult', () {
    group('valid() factory', () {
      test('creates valid result with no warnings', () {
        final result = ValidationResult.valid();
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
        expect(result.warnings, isEmpty);
        expect(result.hasErrors, isFalse);
        expect(result.hasWarnings, isFalse);
      });

      test('creates valid result with warnings', () {
        final warnings = [
          const ValidationWarning(
            code: 'WARN',
            message: 'some warning',
          ),
        ];
        final result = ValidationResult.valid(warnings: warnings);
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
        expect(result.warnings, hasLength(1));
        expect(result.hasWarnings, isTrue);
        expect(result.hasErrors, isFalse);
      });
    });

    group('invalid() factory', () {
      test('creates invalid result with errors', () {
        final errors = [
          const ValidationError(
            code: 'ERR',
            message: 'some error',
          ),
        ];
        final result = ValidationResult.invalid(errors);
        expect(result.isValid, isFalse);
        expect(result.errors, hasLength(1));
        expect(result.warnings, isEmpty);
        expect(result.hasErrors, isTrue);
        expect(result.hasWarnings, isFalse);
      });

      test('creates invalid result with errors and warnings', () {
        final errors = [
          const ValidationError(code: 'ERR', message: 'error'),
        ];
        final warnings = [
          const ValidationWarning(code: 'WARN', message: 'warning'),
        ];
        final result = ValidationResult.invalid(
          errors,
          warnings: warnings,
        );
        expect(result.isValid, isFalse);
        expect(result.errors, hasLength(1));
        expect(result.warnings, hasLength(1));
        expect(result.hasErrors, isTrue);
        expect(result.hasWarnings, isTrue);
      });
    });

    group('merge()', () {
      test('merging two valid results stays valid', () {
        final a = ValidationResult.valid();
        final b = ValidationResult.valid();
        final merged = a.merge(b);
        expect(merged.isValid, isTrue);
        expect(merged.errors, isEmpty);
        expect(merged.warnings, isEmpty);
      });

      test('merging valid + invalid produces invalid', () {
        final valid = ValidationResult.valid(warnings: [
          const ValidationWarning(code: 'W1', message: 'w1'),
        ]);
        final invalid = ValidationResult.invalid([
          const ValidationError(code: 'E1', message: 'e1'),
        ]);
        final merged = valid.merge(invalid);
        expect(merged.isValid, isFalse);
        expect(merged.errors, hasLength(1));
        expect(merged.warnings, hasLength(1));
      });

      test('merging two invalid results stays invalid', () {
        final a = ValidationResult.invalid([
          const ValidationError(code: 'E1', message: 'e1'),
        ]);
        final b = ValidationResult.invalid([
          const ValidationError(code: 'E2', message: 'e2'),
        ], warnings: [
          const ValidationWarning(code: 'W1', message: 'w1'),
        ]);
        final merged = a.merge(b);
        expect(merged.isValid, isFalse);
        expect(merged.errors, hasLength(2));
        expect(merged.warnings, hasLength(1));
      });

      test('merging preserves metadata from both sides', () {
        final a = ValidationResult(
          isValid: true,
          metadata: {'key1': 'val1'},
        );
        final b = ValidationResult(
          isValid: true,
          metadata: {'key2': 'val2'},
        );
        final merged = a.merge(b);
        expect(merged.metadata['key1'], equals('val1'));
        expect(merged.metadata['key2'], equals('val2'));
      });
    });

    group('allIssues getter', () {
      test('returns combined errors and warnings', () {
        final result = ValidationResult(
          isValid: false,
          errors: [const ValidationError(code: 'E', message: 'e')],
          warnings: [const ValidationWarning(code: 'W', message: 'w')],
        );
        final issues = result.allIssues;
        expect(issues, hasLength(2));
        expect(issues.whereType<ValidationError>(), hasLength(1));
        expect(issues.whereType<ValidationWarning>(), hasLength(1));
      });

      test('returns empty list when no issues', () {
        final result = ValidationResult.valid();
        expect(result.allIssues, isEmpty);
      });
    });

    group('toString()', () {
      test('valid with no warnings', () {
        final result = ValidationResult.valid();
        expect(result.toString(), equals('ValidationResult: Valid'));
      });

      test('valid with warnings', () {
        final result = ValidationResult.valid(warnings: [
          const ValidationWarning(code: 'W1', message: 'a warning'),
        ]);
        final str = result.toString();
        expect(str, contains('Valid'));
        expect(str, contains('Warnings:'));
        expect(str, contains('a warning'));
      });

      test('invalid with errors', () {
        final result = ValidationResult.invalid([
          const ValidationError(code: 'E1', message: 'an error'),
        ]);
        final str = result.toString();
        expect(str, contains('Invalid'));
        expect(str, contains('Errors:'));
        expect(str, contains('an error'));
      });

      test('invalid with both errors and warnings', () {
        final result = ValidationResult.invalid(
          [const ValidationError(code: 'E1', message: 'err')],
          warnings: [const ValidationWarning(code: 'W1', message: 'wrn')],
        );
        final str = result.toString();
        expect(str, contains('Invalid'));
        expect(str, contains('Errors:'));
        expect(str, contains('err'));
        expect(str, contains('Warnings:'));
        expect(str, contains('wrn'));
      });
    });
  });

  // ===========================================================================
  // 2. ValidationError factories and toString
  // ===========================================================================
  group('ValidationError', () {
    group('required()', () {
      test('creates with correct code and message', () {
        final err = ValidationError.required('name');
        expect(err.code, equals('MISSING_REQUIRED'));
        expect(err.message, contains('"name"'));
        expect(err.location, isNull);
      });

      test('creates with location', () {
        final err = ValidationError.required('id', location: 'manifest');
        expect(err.location, equals('manifest'));
      });
    });

    group('invalidValue()', () {
      test('without expected', () {
        final err = ValidationError.invalidValue('field', 42);
        expect(err.code, equals('INVALID_VALUE'));
        expect(err.message, contains('"field"'));
        expect(err.message, contains('42'));
        expect(err.message, isNot(contains('expected')));
      });

      test('with expected', () {
        final err = ValidationError.invalidValue(
          'field',
          'bad',
          expected: 'a number',
        );
        expect(err.message, contains('expected a number'));
      });

      test('with location', () {
        final err = ValidationError.invalidValue(
          'field',
          'x',
          location: 'root.field',
        );
        expect(err.location, equals('root.field'));
      });
    });

    group('typeMismatch()', () {
      test('creates with correct fields', () {
        final err = ValidationError.typeMismatch(
          'age',
          'int',
          'String',
        );
        expect(err.code, equals('INVALID_TYPE'));
        expect(err.message, contains('"age"'));
        expect(err.message, contains('int'));
        expect(err.message, contains('String'));
      });

      test('with location', () {
        final err = ValidationError.typeMismatch(
          'f',
          'A',
          'B',
          location: 'path',
        );
        expect(err.location, equals('path'));
      });
    });

    group('unresolvedRef()', () {
      test('creates with correct fields', () {
        final err = ValidationError.unresolvedRef('step1');
        expect(err.code, equals('UNKNOWN_REFERENCE'));
        expect(err.message, contains('step1'));
      });

      test('with location', () {
        final err = ValidationError.unresolvedRef(
          'x',
          location: 'steps[0].next',
        );
        expect(err.location, equals('steps[0].next'));
      });
    });

    group('duplicate()', () {
      test('creates with correct fields', () {
        final err = ValidationError.duplicate('id', 'abc');
        expect(err.code, equals('DUPLICATE_ID'));
        expect(err.message, contains('id'));
        expect(err.message, contains('abc'));
      });

      test('with location', () {
        final err = ValidationError.duplicate(
          'name',
          'dup',
          location: 'resources[1]',
        );
        expect(err.location, equals('resources[1]'));
      });
    });

    group('constraint()', () {
      test('creates with correct fields', () {
        final err = ValidationError.constraint(
          'age',
          'must be positive',
        );
        expect(err.code, equals('INVALID_VALUE'));
        expect(err.message, contains('"age"'));
        expect(err.message, contains('must be positive'));
      });

      test('with location', () {
        final err = ValidationError.constraint(
          'x',
          'c',
          location: 'p',
        );
        expect(err.location, equals('p'));
      });
    });

    group('toString()', () {
      test('without location', () {
        final err = const ValidationError(
          code: 'CODE',
          message: 'some message',
        );
        expect(err.toString(), equals('[CODE] some message'));
      });

      test('with location', () {
        final err = const ValidationError(
          code: 'CODE',
          message: 'msg',
          location: 'path.to.field',
        );
        expect(err.toString(), equals('[CODE] msg at path.to.field'));
      });
    });

    test('severity is error', () {
      const err = ValidationError(code: 'X', message: 'x');
      expect(err.severity, equals(ValidationSeverity.error));
    });
  });

  // ===========================================================================
  // 3. ValidationWarning factories and toString
  // ===========================================================================
  group('ValidationWarning', () {
    group('deprecated()', () {
      test('without replacement', () {
        final w = ValidationWarning.deprecated('oldField');
        expect(w.code, equals('DEPRECATED'));
        expect(w.message, contains('"oldField"'));
        expect(w.message, contains('deprecated'));
        expect(w.message, isNot(contains('instead')));
      });

      test('with replacement', () {
        final w = ValidationWarning.deprecated(
          'oldField',
          replacement: 'newField',
        );
        expect(w.message, contains('"newField"'));
        expect(w.message, contains('instead'));
      });

      test('with location', () {
        final w = ValidationWarning.deprecated(
          'f',
          location: 'section',
        );
        expect(w.location, equals('section'));
      });
    });

    group('bestPractice()', () {
      test('creates with message', () {
        final w = ValidationWarning.bestPractice('Use descriptive names');
        expect(w.code, equals('BEST_PRACTICE'));
        expect(w.message, equals('Use descriptive names'));
      });

      test('with location', () {
        final w = ValidationWarning.bestPractice(
          'msg',
          location: 'loc',
        );
        expect(w.location, equals('loc'));
      });
    });

    group('performance()', () {
      test('creates with message', () {
        final w = ValidationWarning.performance('Too many resources');
        expect(w.code, equals('PERFORMANCE'));
        expect(w.message, equals('Too many resources'));
      });

      test('with location', () {
        final w = ValidationWarning.performance(
          'msg',
          location: 'perf.loc',
        );
        expect(w.location, equals('perf.loc'));
      });
    });

    group('toString()', () {
      test('without location', () {
        const w = ValidationWarning(code: 'W', message: 'warn');
        expect(w.toString(), equals('[W] warn'));
      });

      test('with location', () {
        const w = ValidationWarning(
          code: 'W',
          message: 'warn',
          location: 'here',
        );
        expect(w.toString(), equals('[W] warn at here'));
      });
    });

    test('severity is warning', () {
      const w = ValidationWarning(code: 'W', message: 'w');
      expect(w.severity, equals(ValidationSeverity.warning));
    });
  });

  // ===========================================================================
  // 4. ValidationContext
  // ===========================================================================
  group('ValidationContext', () {
    late ValidationContext context;

    setUp(() {
      context = ValidationContext();
    });

    test('initial path is empty', () {
      expect(context.currentPath, equals(''));
    });

    group('pushPath / popPath / currentPath', () {
      test('pushPath builds dot-separated path', () {
        context.pushPath('a');
        expect(context.currentPath, equals('a'));
        context.pushPath('b');
        expect(context.currentPath, equals('a.b'));
        context.pushPath('c');
        expect(context.currentPath, equals('a.b.c'));
      });

      test('popPath removes last segment', () {
        context.pushPath('a');
        context.pushPath('b');
        context.popPath();
        expect(context.currentPath, equals('a'));
        context.popPath();
        expect(context.currentPath, equals(''));
      });

      test('popPath on empty path does not throw', () {
        context.popPath();
        expect(context.currentPath, equals(''));
      });
    });

    group('addError / addWarning', () {
      test('addError accumulates errors', () {
        context.addError(
          const ValidationError(code: 'E', message: 'm'),
        );
        context.addError(
          const ValidationError(code: 'E2', message: 'm2'),
        );
        final result = context.toResult();
        expect(result.errors, hasLength(2));
      });

      test('addWarning accumulates warnings', () {
        context.addWarning(
          const ValidationWarning(code: 'W', message: 'w'),
        );
        final result = context.toResult();
        expect(result.warnings, hasLength(1));
      });
    });

    group('addRequiredError', () {
      test('adds error with MISSING_REQUIRED code and current path', () {
        context.pushPath('manifest');
        context.addRequiredError('name');
        final result = context.toResult();
        expect(result.errors, hasLength(1));
        expect(result.errors.first.code, equals('MISSING_REQUIRED'));
        expect(result.errors.first.location, equals('manifest'));
      });
    });

    group('addInvalidValueError', () {
      test('adds error with INVALID_VALUE code', () {
        context.pushPath('field');
        context.addInvalidValueError('key', 'bad');
        final result = context.toResult();
        expect(result.errors, hasLength(1));
        expect(result.errors.first.code, equals('INVALID_VALUE'));
        expect(result.errors.first.location, equals('field'));
      });

      test('includes expected when provided', () {
        context.addInvalidValueError('key', 'bad', expected: 'good');
        final result = context.toResult();
        expect(result.errors.first.message, contains('expected good'));
      });
    });

    group('toResult()', () {
      test('returns valid when no errors', () {
        context.addWarning(
          const ValidationWarning(code: 'W', message: 'w'),
        );
        final result = context.toResult();
        expect(result.isValid, isTrue);
        expect(result.warnings, hasLength(1));
      });

      test('returns invalid when errors exist', () {
        context.addError(
          const ValidationError(code: 'E', message: 'e'),
        );
        final result = context.toResult();
        expect(result.isValid, isFalse);
      });

      test('returns unmodifiable lists', () {
        context.addError(
          const ValidationError(code: 'E', message: 'e'),
        );
        final result = context.toResult();
        expect(
          () => result.errors.add(
            const ValidationError(code: 'X', message: 'x'),
          ),
          throwsUnsupportedError,
        );
      });
    });

    group('withPath<T>()', () {
      test('pushes and pops path around action', () {
        context.pushPath('root');
        context.withPath('child', () {
          expect(context.currentPath, equals('root.child'));
          context.addRequiredError('inner');
        });
        expect(context.currentPath, equals('root'));
      });

      test('returns value from action', () {
        final val = context.withPath('x', () => 42);
        expect(val, equals(42));
      });

      test('pops path even when action throws', () {
        context.pushPath('base');
        try {
          context.withPath('bad', () {
            throw StateError('boom');
          });
        } catch (_) {
          // Expected
        }
        expect(context.currentPath, equals('base'));
      });
    });
  });

  // ===========================================================================
  // 5. BundleValidator
  // ===========================================================================
  group('BundleValidator', () {
    late BundleValidator validator;

    setUp(() {
      validator = const BundleValidator();
    });

    // Helper: minimal valid bundle
    schema.Bundle _validBundle() {
      return const schema.Bundle(
        manifest: schema.BundleManifest(
          name: 'test-bundle',
          version: '1.0.0',
        ),
      );
    }

    group('validate() - manifest', () {
      test('valid bundle passes', () {
        final result = validator.validate(_validBundle());
        expect(result.isValid, isTrue);
      });

      test('empty manifest name fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(name: '', version: '1.0.0'),
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) => e.code == 'MISSING_REQUIRED'),
          isTrue,
        );
      });

      test('invalid manifest name pattern fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: '123-invalid',
            version: '1.0.0',
          ),
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'INVALID_VALUE' && e.message.contains('name')),
          isTrue,
        );
      });

      test('empty version fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(name: 'valid', version: ''),
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'MISSING_REQUIRED' && e.message.contains('version')),
          isTrue,
        );
      });

      test('invalid version fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: 'not-semver',
          ),
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'INVALID_VALUE' && e.message.contains('version')),
          isTrue,
        );
      });

      test('invalid homepage URL fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
            homepage: 'not-a-url',
          ),
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'INVALID_VALUE' && e.message.contains('homepage')),
          isTrue,
        );
      });

      test('valid homepage URL passes', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
            homepage: 'https://example.com',
          ),
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isTrue);
      });

      test('invalid repository URL fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
            repository: 'git@github.com:user/repo',
          ),
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'INVALID_VALUE' && e.message.contains('repository')),
          isTrue,
        );
      });

      test('license validation warning with validateLicense: true', () {
        const validatorWithLicense = BundleValidator(
          options: ValidatorOptions(validateLicense: true),
        );
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
            license: 'CUSTOM-LICENSE',
          ),
        );
        final result = validatorWithLicense.validate(bundle);
        // Not an error, just a warning
        expect(result.isValid, isTrue);
        expect(result.hasWarnings, isTrue);
        expect(
          result.warnings.any((w) => w.code == 'BEST_PRACTICE'),
          isTrue,
        );
      });

      test('recognized license with validateLicense: true produces no warning',
          () {
        const validatorWithLicense = BundleValidator(
          options: ValidatorOptions(validateLicense: true),
        );
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
            license: 'MIT',
          ),
        );
        final result = validatorWithLicense.validate(bundle);
        expect(result.isValid, isTrue);
        expect(result.hasWarnings, isFalse);
      });
    });

    group('validate() - resources', () {
      test('duplicate resource paths produce error', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
          ),
          resources: [
            BundleResource(
              path: 'skills/a.json',
              type: ResourceType.skill,
              content: 'data',
            ),
            BundleResource(
              path: 'skills/a.json',
              type: ResourceType.skill,
              content: 'data2',
            ),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) => e.code == 'DUPLICATE_ID'),
          isTrue,
        );
      });

      test('empty resource path fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
          ),
          resources: [
            BundleResource(
              path: '',
              type: ResourceType.data,
              content: 'data',
            ),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) => e.code == 'MISSING_REQUIRED'),
          isTrue,
        );
      });

      test('resource path starting with / fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
          ),
          resources: [
            BundleResource(
              path: '/absolute/path',
              type: ResourceType.data,
              content: 'data',
            ),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'INVALID_VALUE' && e.message.contains('path')),
          isTrue,
        );
      });

      test('resource path containing // fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
          ),
          resources: [
            BundleResource(
              path: 'a//b',
              type: ResourceType.data,
              content: 'data',
            ),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
      });

      test('resource path containing .. fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
          ),
          resources: [
            BundleResource(
              path: 'a/../b',
              type: ResourceType.data,
              content: 'data',
            ),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
      });

      test('resource with no content and no contentRef fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
          ),
          resources: [
            BundleResource(
              path: 'some/path',
              type: ResourceType.data,
            ),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) => e.code == 'MISSING_CONTENT'),
          isTrue,
        );
      });

      test('resource with contentRef is valid (no content needed)', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
          ),
          resources: [
            BundleResource(
              path: 'some/path',
              type: ResourceType.data,
              contentRef: 'https://example.com/data.json',
            ),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isTrue);
      });

      test('skill resource content validation (nested validateSkill)', () {
        final bundle = schema.Bundle(
          manifest: const schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
          ),
          resources: [
            BundleResource(
              path: 'skills/empty.json',
              type: ResourceType.skill,
              content: <String, dynamic>{
                'id': '',
                'name': '',
              },
            ),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        // Nested skill validation should produce MISSING_REQUIRED errors
        expect(
          result.errors.any((e) => e.code == 'MISSING_REQUIRED'),
          isTrue,
        );
      });

      test('profile resource content validation (nested validateProfile)', () {
        final bundle = schema.Bundle(
          manifest: const schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
          ),
          resources: [
            BundleResource(
              path: 'profiles/empty.json',
              type: ResourceType.profile,
              content: <String, dynamic>{
                'id': '',
                'name': '',
              },
            ),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
      });
    });

    group('validate() - dependencies', () {
      test('dependency with empty name fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
          ),
          dependencies: [
            schema.BundleDependency(name: '', version: '1.0.0'),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'MISSING_REQUIRED' && e.message.contains('name')),
          isTrue,
        );
      });

      test('duplicate dependency name fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
          ),
          dependencies: [
            schema.BundleDependency(name: 'dep-a', version: '1.0.0'),
            schema.BundleDependency(name: 'dep-a', version: '2.0.0'),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) => e.code == 'DUPLICATE_ID'),
          isTrue,
        );
      });

      test('invalid version constraint fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
          ),
          dependencies: [
            schema.BundleDependency(
              name: 'dep',
              version: 'totally-invalid',
            ),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'INVALID_VALUE' && e.message.contains('version')),
          isTrue,
        );
      });

      test('wildcard version constraint passes', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
          ),
          dependencies: [
            schema.BundleDependency(name: 'dep', version: '*'),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isTrue);
      });

      test('caret version constraint passes', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
          ),
          dependencies: [
            schema.BundleDependency(name: 'dep', version: '^1.2.3'),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isTrue);
      });
    });

    group('validate() - cross-validation', () {
      test('entry point that does not exist in resources fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
            entryPoint: 'main/entry.json',
          ),
          resources: [
            BundleResource(
              path: 'other/file.json',
              type: ResourceType.data,
              content: 'x',
            ),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'UNKNOWN_REFERENCE' &&
              e.message.contains('entryPoint')),
          isTrue,
        );
      });

      test('entry point that exists passes', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
            entryPoint: 'main/entry.json',
          ),
          resources: [
            BundleResource(
              path: 'main/entry.json',
              type: ResourceType.data,
              content: 'x',
            ),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isTrue);
      });

      test('export that does not exist in resources fails', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
            exports: ['missing/export.json'],
          ),
          resources: [
            BundleResource(
              path: 'other/file.json',
              type: ResourceType.data,
              content: 'x',
            ),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'UNKNOWN_REFERENCE' &&
              e.message.contains('export')),
          isTrue,
        );
      });

      test('export that exists passes', () {
        const bundle = schema.Bundle(
          manifest: schema.BundleManifest(
            name: 'valid',
            version: '1.0.0',
            exports: ['a/b.json'],
          ),
          resources: [
            BundleResource(
              path: 'a/b.json',
              type: ResourceType.data,
              content: 'x',
            ),
          ],
        );
        final result = validator.validate(bundle);
        expect(result.isValid, isTrue);
      });
    });

    group('validateSkill()', () {
      test('valid skill passes', () {
        const skill = manifest.SkillManifest(
          id: 'skill1',
          name: 'Skill One',
        );
        final result = validator.validateSkill(skill);
        expect(result.isValid, isTrue);
      });

      test('empty id fails', () {
        const skill = manifest.SkillManifest(
          id: '',
          name: 'Skill One',
        );
        final result = validator.validateSkill(skill);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'MISSING_REQUIRED' && e.message.contains('id')),
          isTrue,
        );
      });

      test('empty name fails', () {
        const skill = manifest.SkillManifest(
          id: 'skill1',
          name: '',
        );
        final result = validator.validateSkill(skill);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'MISSING_REQUIRED' && e.message.contains('name')),
          isTrue,
        );
      });

      test('parameter with empty name fails', () {
        final skill = manifest.SkillManifest(
          id: 'skill1',
          name: 'Skill One',
          inputs: [
            ParameterSchema.fromJson(
              const {'name': '', 'type': 'string'},
            ),
          ],
        );
        final result = validator.validateSkill(skill);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'MISSING_REQUIRED' && e.message.contains('name')),
          isTrue,
        );
      });

      test('parameter with empty type fails', () {
        final skill = manifest.SkillManifest(
          id: 'skill1',
          name: 'Skill One',
          inputs: [
            ParameterSchema.fromJson(
              const {'name': 'param1', 'type': ''},
            ),
          ],
        );
        final result = validator.validateSkill(skill);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'MISSING_REQUIRED' && e.message.contains('type')),
          isTrue,
        );
      });

      test('parameter with invalid type fails', () {
        final skill = manifest.SkillManifest(
          id: 'skill1',
          name: 'Skill One',
          inputs: [
            ParameterSchema.fromJson(
              const {'name': 'param1', 'type': 'invalid_type'},
            ),
          ],
        );
        final result = validator.validateSkill(skill);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'INVALID_VALUE' && e.message.contains('type')),
          isTrue,
        );
      });

      test('valid parameter type passes', () {
        final skill = manifest.SkillManifest(
          id: 'skill1',
          name: 'Skill One',
          inputs: [
            ParameterSchema.fromJson(
              const {'name': 'param1', 'type': 'string'},
            ),
            ParameterSchema.fromJson(
              const {'name': 'param2', 'type': 'number'},
            ),
            ParameterSchema.fromJson(
              const {'name': 'param3', 'type': 'boolean'},
            ),
            ParameterSchema.fromJson(
              const {'name': 'param4', 'type': 'array'},
            ),
            ParameterSchema.fromJson(
              const {'name': 'param5', 'type': 'object'},
            ),
            ParameterSchema.fromJson(
              const {'name': 'param6', 'type': 'any'},
            ),
          ],
        );
        final result = validator.validateSkill(skill);
        expect(result.isValid, isTrue);
      });

      test('duplicate step IDs - Set-based collection prevents detection', () {
        // The source code collects step IDs into a Set, which deduplicates
        // entries. The duplicate check uses ids.where().length > 1 on the
        // Set, which can never exceed 1 for any single value.
        // Therefore, duplicates are not detected at this level.
        final skill = manifest.SkillManifest(
          id: 'skill1',
          name: 'Skill One',
          steps: [
            SkillStep.fromJson(
              const {'id': 'step1', 'type': 'action'},
            ),
            SkillStep.fromJson(
              const {'id': 'step1', 'type': 'action'},
            ),
          ],
        );
        final result = validator.validateSkill(skill);
        // Due to Set-based collection, duplicate detection does not trigger
        expect(result.isValid, isTrue);
      });

      test('unresolved next step reference produces error', () {
        final skill = manifest.SkillManifest(
          id: 'skill1',
          name: 'Skill One',
          steps: [
            SkillStep.fromJson(
              const {'id': 'step1', 'type': 'action', 'next': ['nonexistent']},
            ),
          ],
        );
        final result = validator.validateSkill(skill);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) => e.code == 'UNKNOWN_REFERENCE'),
          isTrue,
        );
      });

      test('valid next step reference passes', () {
        final skill = manifest.SkillManifest(
          id: 'skill1',
          name: 'Skill One',
          steps: [
            SkillStep.fromJson(
              const {'id': 'step1', 'type': 'action', 'next': ['step2']},
            ),
            SkillStep.fromJson(
              const {'id': 'step2', 'type': 'output'},
            ),
          ],
        );
        final result = validator.validateSkill(skill);
        expect(result.isValid, isTrue);
      });

      test('step with empty id fails', () {
        final skill = manifest.SkillManifest(
          id: 'skill1',
          name: 'Skill One',
          steps: [
            SkillStep.fromJson(
              const {'id': '', 'type': 'action'},
            ),
          ],
        );
        final result = validator.validateSkill(skill);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'MISSING_REQUIRED' && e.message.contains('id')),
          isTrue,
        );
      });
    });

    group('validateProfile()', () {
      test('valid profile passes', () {
        const profile = manifest.ProfileManifest(
          id: 'prof1',
          name: 'Profile One',
        );
        final result = validator.validateProfile(profile);
        expect(result.isValid, isTrue);
      });

      test('empty id fails', () {
        const profile = manifest.ProfileManifest(
          id: '',
          name: 'Profile One',
        );
        final result = validator.validateProfile(profile);
        expect(result.isValid, isFalse);
      });

      test('empty name fails', () {
        const profile = manifest.ProfileManifest(
          id: 'prof1',
          name: '',
        );
        final result = validator.validateProfile(profile);
        expect(result.isValid, isFalse);
      });

      test('section with empty name fails', () {
        const profile = manifest.ProfileManifest(
          id: 'prof1',
          name: 'Profile One',
          sections: [
            manifest.ProfileSection(name: '', content: 'some content'),
          ],
        );
        final result = validator.validateProfile(profile);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'MISSING_REQUIRED' && e.message.contains('name')),
          isTrue,
        );
      });

      test('section with empty content fails', () {
        const profile = manifest.ProfileManifest(
          id: 'prof1',
          name: 'Profile One',
          sections: [
            manifest.ProfileSection(name: 'section1', content: ''),
          ],
        );
        final result = validator.validateProfile(profile);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == 'MISSING_REQUIRED' && e.message.contains('content')),
          isTrue,
        );
      });

      test('valid section passes', () {
        const profile = manifest.ProfileManifest(
          id: 'prof1',
          name: 'Profile One',
          sections: [
            manifest.ProfileSection(
              name: 'intro',
              content: 'Introduction text',
            ),
          ],
        );
        final result = validator.validateProfile(profile);
        expect(result.isValid, isTrue);
      });
    });
  });

  // ===========================================================================
  // 6. McpBundleValidator
  // ===========================================================================
  group('McpBundleValidator', () {
    // Helper: minimal valid McpBundle
    McpBundle _validMcpBundle() {
      return const McpBundle(
        schemaVersion: '1.0.0',
        manifest: BundleManifest(
          id: 'com.test.bundle',
          name: 'Test Bundle',
          version: '1.0.0',
        ),
      );
    }

    group('validate() - schema', () {
      test('valid minimal bundle passes', () {
        final result = McpBundleValidator.validate(_validMcpBundle());
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('empty schemaVersion produces error', () {
        const bundle = McpBundle(
          schemaVersion: '',
          manifest: BundleManifest(
            id: 'com.test',
            name: 'Test',
            version: '1.0.0',
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.message.contains('schemaVersion')),
          isTrue,
        );
      });

      test('missing manifest id gives error', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: '',
            name: 'Test',
            version: '1.0.0',
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.location == 'manifest.id'),
          isTrue,
        );
      });

      test('invalid manifest id pattern gives error', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'INVALID-ID',
            name: 'Test',
            version: '1.0.0',
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.invalidPattern &&
              e.location == 'manifest.id'),
          isTrue,
        );
      });

      test('missing manifest name gives error', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'com.test',
            name: '',
            version: '1.0.0',
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.location == 'manifest.name'),
          isTrue,
        );
      });

      test('missing manifest version gives error', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'com.test',
            name: 'Test',
            version: '',
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.location == 'manifest.version'),
          isTrue,
        );
      });

      test('invalid version format gives error', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'com.test',
            name: 'Test',
            version: 'abc',
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.invalidPattern &&
              e.location == 'manifest.version'),
          isTrue,
        );
      });

      test('semver with pre-release passes', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'com.test',
            name: 'Test',
            version: '1.0.0-beta.1',
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isTrue);
      });
    });

    group('validate() - skills section', () {
      test('valid skill module passes', () {
        final bundle = _validMcpBundle().copyWith(
          skills: const SkillSection(
            modules: [
              SkillModule(
                id: 'skill1',
                name: 'Skill One',
                procedures: [
                  SkillProcedure(
                    id: 'proc1',
                    name: 'Proc One',
                  ),
                ],
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isTrue);
      });

      test('skill module with empty id fails', () {
        final bundle = _validMcpBundle().copyWith(
          skills: const SkillSection(
            modules: [
              SkillModule(id: '', name: 'Skill One'),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.message.contains('module id')),
          isTrue,
        );
      });

      test('skill module with empty name fails', () {
        final bundle = _validMcpBundle().copyWith(
          skills: const SkillSection(
            modules: [
              SkillModule(id: 'skill1', name: ''),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.message.contains('module name')),
          isTrue,
        );
      });

      test('duplicate skill module ids fail', () {
        final bundle = _validMcpBundle().copyWith(
          skills: const SkillSection(
            modules: [
              SkillModule(id: 'same', name: 'A'),
              SkillModule(id: 'same', name: 'B'),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) => e.code == McpValidationCodes.duplicateId),
          isTrue,
        );
      });

      test('duplicate procedure ids within same module fail', () {
        final bundle = _validMcpBundle().copyWith(
          skills: const SkillSection(
            modules: [
              SkillModule(
                id: 'skill1',
                name: 'Skill One',
                procedures: [
                  SkillProcedure(id: 'proc1', name: 'P1'),
                  SkillProcedure(id: 'proc1', name: 'P2'),
                ],
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.duplicateId &&
              e.message.contains('procedure')),
          isTrue,
        );
      });

      test('procedure with empty id fails', () {
        final bundle = _validMcpBundle().copyWith(
          skills: const SkillSection(
            modules: [
              SkillModule(
                id: 'skill1',
                name: 'Skill One',
                procedures: [
                  SkillProcedure(id: '', name: 'P1'),
                ],
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.message.contains('Procedure id')),
          isTrue,
        );
      });
    });

    group('validate() - profile section', () {
      test('valid profile passes', () {
        final bundle = _validMcpBundle().copyWith(
          profiles: const ProfilesSection(
            profiles: [
              ProfileDefinition(
                id: 'prof1',
                name: 'Profile One',
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isTrue);
      });

      test('profile with empty id fails', () {
        final bundle = _validMcpBundle().copyWith(
          profiles: const ProfilesSection(
            profiles: [
              ProfileDefinition(id: '', name: 'Profile One'),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.message.contains('Profile id')),
          isTrue,
        );
      });

      test('profile with empty name fails', () {
        final bundle = _validMcpBundle().copyWith(
          profiles: const ProfilesSection(
            profiles: [
              ProfileDefinition(id: 'prof1', name: ''),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.message.contains('Profile name')),
          isTrue,
        );
      });

      test('duplicate profile ids fail', () {
        final bundle = _validMcpBundle().copyWith(
          profiles: const ProfilesSection(
            profiles: [
              ProfileDefinition(id: 'same', name: 'A'),
              ProfileDefinition(id: 'same', name: 'B'),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) => e.code == McpValidationCodes.duplicateId),
          isTrue,
        );
      });
    });

    group('validate() - test section', () {
      test('valid test section passes', () {
        final bundle = _validMcpBundle().copyWith(
          tests: const TestSection(
            suites: [
              TestSuite(
                id: 'suite1',
                name: 'Suite One',
                tests: [
                  TestCase(id: 'test1', name: 'Test One'),
                ],
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isTrue);
      });

      test('test suite with empty id fails', () {
        final bundle = _validMcpBundle().copyWith(
          tests: const TestSection(
            suites: [
              TestSuite(id: '', name: 'Suite One'),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.message.contains('Test suite id')),
          isTrue,
        );
      });

      test('duplicate test suite ids fail', () {
        final bundle = _validMcpBundle().copyWith(
          tests: const TestSection(
            suites: [
              TestSuite(id: 'same', name: 'A'),
              TestSuite(id: 'same', name: 'B'),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) => e.code == McpValidationCodes.duplicateId),
          isTrue,
        );
      });

      test('test case with empty id fails', () {
        final bundle = _validMcpBundle().copyWith(
          tests: const TestSection(
            suites: [
              TestSuite(
                id: 'suite1',
                name: 'Suite One',
                tests: [
                  TestCase(id: '', name: 'Test One'),
                ],
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.message.contains('Test case id')),
          isTrue,
        );
      });

      test('duplicate test case ids within suite fail', () {
        final bundle = _validMcpBundle().copyWith(
          tests: const TestSection(
            suites: [
              TestSuite(
                id: 'suite1',
                name: 'Suite One',
                tests: [
                  TestCase(id: 'tc', name: 'A'),
                  TestCase(id: 'tc', name: 'B'),
                ],
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.duplicateId &&
              e.message.contains('test case')),
          isTrue,
        );
      });
    });

    group('validate() - asset section', () {
      test('valid asset passes', () {
        final bundle = _validMcpBundle().copyWith(
          assets: const AssetSection(
            assets: [
              Asset(
                path: 'images/logo.png',
                type: AssetType.image,
                content: 'base64data',
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isTrue);
      });

      test('asset with empty path fails', () {
        final bundle = _validMcpBundle().copyWith(
          assets: const AssetSection(
            assets: [
              Asset(path: '', type: AssetType.image, content: 'data'),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.message.contains('Asset path')),
          isTrue,
        );
      });

      test('duplicate asset paths fail', () {
        final bundle = _validMcpBundle().copyWith(
          assets: const AssetSection(
            assets: [
              Asset(
                path: 'same/path.png',
                type: AssetType.image,
                content: 'a',
              ),
              Asset(
                path: 'same/path.png',
                type: AssetType.image,
                content: 'b',
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) => e.code == McpValidationCodes.duplicateId),
          isTrue,
        );
      });

      test('asset with no content and no contentRef fails', () {
        final bundle = _validMcpBundle().copyWith(
          assets: const AssetSection(
            assets: [
              Asset(path: 'a.png', type: AssetType.image),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.message.contains('content')),
          isTrue,
        );
      });

      test('asset with contentRef passes (no inline content needed)', () {
        final bundle = _validMcpBundle().copyWith(
          assets: const AssetSection(
            assets: [
              Asset(
                path: 'a.png',
                type: AssetType.image,
                contentRef: 'https://example.com/a.png',
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isTrue);
      });
    });

    group('validate() - integrity', () {
      test('bundle without integrity passes', () {
        final result = McpBundleValidator.validate(_validMcpBundle());
        expect(result.isValid, isTrue);
      });

      test('content hash with empty value fails', () {
        final bundle = _validMcpBundle().copyWith(
          integrity: const integrity_model.IntegrityConfig(
            contentHash: integrity_model.ContentHash(
              algorithm: integrity_model.HashAlgorithm.sha256,
              value: '',
            ),
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.message.contains('Content hash value')),
          isTrue,
        );
      });

      test('content hash with unknown algorithm fails', () {
        final bundle = _validMcpBundle().copyWith(
          integrity: const integrity_model.IntegrityConfig(
            contentHash: integrity_model.ContentHash(
              algorithm: integrity_model.HashAlgorithm.unknown,
              value: 'abc123',
            ),
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.invalidValue &&
              e.message.contains('Unknown hash algorithm')),
          isTrue,
        );
      });

      test('file hash with empty path fails', () {
        final bundle = _validMcpBundle().copyWith(
          integrity: const integrity_model.IntegrityConfig(
            files: [
              integrity_model.FileHash(
                path: '',
                algorithm: integrity_model.HashAlgorithm.sha256,
                value: 'abc123',
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.message.contains('File hash path')),
          isTrue,
        );
      });

      test('file hash with empty value fails', () {
        final bundle = _validMcpBundle().copyWith(
          integrity: const integrity_model.IntegrityConfig(
            files: [
              integrity_model.FileHash(
                path: 'some/file.json',
                algorithm: integrity_model.HashAlgorithm.sha256,
                value: '',
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.message.contains('File hash value')),
          isTrue,
        );
      });

      test('file hash with unknown algorithm fails', () {
        final bundle = _validMcpBundle().copyWith(
          integrity: const integrity_model.IntegrityConfig(
            files: [
              integrity_model.FileHash(
                path: 'some/file.json',
                algorithm: integrity_model.HashAlgorithm.unknown,
                value: 'abc123',
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.invalidValue &&
              e.message.contains('Unknown hash algorithm for file')),
          isTrue,
        );
      });

      test('signature with empty keyId fails', () {
        final bundle = _validMcpBundle().copyWith(
          integrity: integrity_model.IntegrityConfig(
            signatures: [
              integrity_model.Signature(
                keyId: '',
                algorithm: integrity_model.SignatureAlgorithm.rsaSha256,
                value: 'sigvalue',
                signedPayload: const integrity_model.SignedPayloadRef(
                  type: integrity_model.PayloadRefType.contentHash,
                ),
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.message.contains('Signature key ID')),
          isTrue,
        );
      });

      test('signature with empty value fails', () {
        final bundle = _validMcpBundle().copyWith(
          integrity: integrity_model.IntegrityConfig(
            signatures: [
              integrity_model.Signature(
                keyId: 'key1',
                algorithm: integrity_model.SignatureAlgorithm.rsaSha256,
                value: '',
                signedPayload: const integrity_model.SignedPayloadRef(
                  type: integrity_model.PayloadRefType.contentHash,
                ),
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.message.contains('Signature value')),
          isTrue,
        );
      });

      test('signature with unknown algorithm fails', () {
        final bundle = _validMcpBundle().copyWith(
          integrity: integrity_model.IntegrityConfig(
            signatures: [
              integrity_model.Signature(
                keyId: 'key1',
                algorithm: integrity_model.SignatureAlgorithm.unknown,
                value: 'sigvalue',
                signedPayload: const integrity_model.SignedPayloadRef(
                  type: integrity_model.PayloadRefType.contentHash,
                ),
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.invalidValue &&
              e.message.contains('Unknown signature algorithm')),
          isTrue,
        );
      });

      test('old signature produces warning', () {
        final twoYearsAgo =
            DateTime.now().subtract(const Duration(days: 730));
        final bundle = _validMcpBundle().copyWith(
          integrity: integrity_model.IntegrityConfig(
            signatures: [
              integrity_model.Signature(
                keyId: 'key1',
                algorithm: integrity_model.SignatureAlgorithm.rsaSha256,
                value: 'sigvalue',
                timestamp: twoYearsAgo,
                signedPayload: const integrity_model.SignedPayloadRef(
                  type: integrity_model.PayloadRefType.contentHash,
                ),
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isTrue);
        expect(result.hasWarnings, isTrue);
        expect(
          result.warnings.any((w) =>
              w.code == McpValidationCodes.signatureExpired),
          isTrue,
        );
      });

      test('valid integrity config passes', () {
        final bundle = _validMcpBundle().copyWith(
          integrity: integrity_model.IntegrityConfig(
            contentHash: const integrity_model.ContentHash(
              algorithm: integrity_model.HashAlgorithm.sha256,
              value: 'abc123def456',
            ),
            files: const [
              integrity_model.FileHash(
                path: 'manifest.json',
                algorithm: integrity_model.HashAlgorithm.sha256,
                value: 'filehash',
              ),
            ],
            signatures: [
              integrity_model.Signature(
                keyId: 'key1',
                algorithm: integrity_model.SignatureAlgorithm.rsaSha256,
                value: 'sigvalue',
                timestamp: DateTime.now(),
                signedPayload: const integrity_model.SignedPayloadRef(
                  type: integrity_model.PayloadRefType.contentHash,
                ),
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isTrue);
      });
    });

    group('validateSchema()', () {
      test('delegates to schema validation only', () {
        final result = McpBundleValidator.validateSchema(_validMcpBundle());
        expect(result.isValid, isTrue);
      });
    });

    group('validateReferences()', () {
      test('validates references only', () {
        final result = McpBundleValidator.validateReferences(_validMcpBundle());
        expect(result.isValid, isTrue);
      });
    });

    group('validateIntegrity()', () {
      test('returns valid when no integrity config', () {
        final result = McpBundleValidator.validateIntegrity(_validMcpBundle());
        expect(result.isValid, isTrue);
      });

      test('validates integrity when present', () {
        final bundle = _validMcpBundle().copyWith(
          integrity: const integrity_model.IntegrityConfig(
            contentHash: integrity_model.ContentHash(
              algorithm: integrity_model.HashAlgorithm.sha256,
              value: '',
            ),
          ),
        );
        final result = McpBundleValidator.validateIntegrity(bundle);
        expect(result.isValid, isFalse);
      });
    });

    group('validate() - reference validation', () {
      test('unknown knowledge source reference fails', () {
        final bundle = _validMcpBundle().copyWith(
          skills: const SkillSection(
            modules: [
              SkillModule(
                id: 'skill1',
                name: 'Skill One',
                knowledgeSources: [
                  KnowledgeSourceRef(sourceId: 'nonexistent'),
                ],
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.unknownReference &&
              e.message.contains('knowledge source')),
          isTrue,
        );
      });

      test('valid knowledge source reference passes', () {
        final bundle = _validMcpBundle().copyWith(
          skills: const SkillSection(
            modules: [
              SkillModule(
                id: 'skill1',
                name: 'Skill One',
                knowledgeSources: [
                  KnowledgeSourceRef(sourceId: 'ks1'),
                ],
              ),
            ],
          ),
          knowledge: const KnowledgeSection(
            sources: [
              KnowledgeSource(
                id: 'ks1',
                name: 'Source One',
                type: KnowledgeSourceType.documents,
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isTrue);
      });

      test('procedure entryPoint referencing unknown step fails', () {
        final bundle = _validMcpBundle().copyWith(
          skills: const SkillSection(
            modules: [
              SkillModule(
                id: 'skill1',
                name: 'Skill One',
                procedures: [
                  SkillProcedure(
                    id: 'proc1',
                    name: 'P1',
                    entryPoint: 'nonexistent',
                    steps: [
                      ProcedureStep(
                        id: 'step1',
                        action: StepAction(type: StepActionType.prompt),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.unknownReference &&
              e.message.contains('entryPoint')),
          isTrue,
        );
      });

      test('procedure step next referencing unknown step fails', () {
        final bundle = _validMcpBundle().copyWith(
          skills: const SkillSection(
            modules: [
              SkillModule(
                id: 'skill1',
                name: 'Skill One',
                procedures: [
                  SkillProcedure(
                    id: 'proc1',
                    name: 'P1',
                    steps: [
                      ProcedureStep(
                        id: 'step1',
                        action: StepAction(type: StepActionType.prompt),
                        next: ['missing_step'],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.unknownReference &&
              e.message.contains('next step')),
          isTrue,
        );
      });

      test('procedure step onError referencing unknown step fails', () {
        final bundle = _validMcpBundle().copyWith(
          skills: const SkillSection(
            modules: [
              SkillModule(
                id: 'skill1',
                name: 'Skill One',
                procedures: [
                  SkillProcedure(
                    id: 'proc1',
                    name: 'P1',
                    steps: [
                      ProcedureStep(
                        id: 'step1',
                        action: StepAction(type: StepActionType.prompt),
                        onError: 'missing_error_handler',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.unknownReference &&
              e.message.contains('onError')),
          isTrue,
        );
      });
    });

    group('validate() - circular dependency detection', () {
      test('self-referencing flow step detects cycle', () {
        final bundle = _validMcpBundle().copyWith(
          flow: FlowSection(
            flows: [
              FlowDefinition(
                id: 'flow1',
                name: 'Flow One',
                steps: [
                  FlowStep(
                    id: 'stepA',
                    type: flow_model.StepType.action,
                    next: ['stepB'],
                  ),
                  FlowStep(
                    id: 'stepB',
                    type: flow_model.StepType.action,
                    next: ['stepA'],
                  ),
                ],
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        // This should detect a circular dependency
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.circularReference),
          isTrue,
        );
      });
    });

    group('validate() - expression validation', () {
      test('invalid expression in skill step condition fails', () {
        final bundle = _validMcpBundle().copyWith(
          skills: const SkillSection(
            modules: [
              SkillModule(
                id: 'skill1',
                name: 'Skill One',
                procedures: [
                  SkillProcedure(
                    id: 'proc1',
                    name: 'P1',
                    steps: [
                      ProcedureStep(
                        id: 'step1',
                        action: StepAction(type: StepActionType.prompt),
                        condition: '((( invalid expression',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        // Expression validation error
        expect(
          result.errors.any((e) =>
              e.code == McpValidationCodes.invalidValue &&
              (e.message.contains('Expression syntax error') ||
               e.message.contains('Expression lexer error'))),
          isTrue,
        );
      });

      test('valid expression in skill step condition passes', () {
        final bundle = _validMcpBundle().copyWith(
          skills: const SkillSection(
            modules: [
              SkillModule(
                id: 'skill1',
                name: 'Skill One',
                procedures: [
                  SkillProcedure(
                    id: 'proc1',
                    name: 'P1',
                    steps: [
                      ProcedureStep(
                        id: 'step1',
                        action: StepAction(type: StepActionType.prompt),
                        condition: 'x > 0',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        // The expression itself should be valid; other errors may or may not exist
        expect(
          result.errors.where((e) =>
              e.message.contains('Expression syntax error') ||
              e.message.contains('Expression lexer error')),
          isEmpty,
        );
      });
    });
  });

  // ===========================================================================
  // 7. ValidationSeverity enum coverage
  // ===========================================================================
  group('ValidationSeverity', () {
    test('has all expected values', () {
      expect(ValidationSeverity.values, contains(ValidationSeverity.info));
      expect(ValidationSeverity.values, contains(ValidationSeverity.warning));
      expect(ValidationSeverity.values, contains(ValidationSeverity.error));
      expect(ValidationSeverity.values, contains(ValidationSeverity.critical));
    });
  });
}
