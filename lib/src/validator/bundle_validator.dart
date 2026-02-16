/// Bundle validator for validating MCP bundles.
library;

import '../schema/bundle_schema.dart';
import '../schema/manifest_schema.dart';
import 'validation_result.dart';

/// Validates MCP bundles against schema and rules.
class BundleValidator {
  final ValidatorOptions options;

  const BundleValidator({this.options = const ValidatorOptions()});

  /// Validate a bundle.
  ValidationResult validate(Bundle bundle) {
    final context = ValidationContext();

    // Validate manifest
    context.withPath('manifest', () {
      _validateManifest(bundle.manifest, context);
    });

    // Validate resources
    context.withPath('resources', () {
      _validateResources(bundle.resources, context);
    });

    // Validate dependencies
    context.withPath('dependencies', () {
      _validateDependencies(bundle.dependencies, context);
    });

    // Cross-validation
    _crossValidate(bundle, context);

    return context.toResult();
  }

  /// Validate a skill manifest.
  ValidationResult validateSkill(SkillManifest skill) {
    final context = ValidationContext();

    context.withPath('skill', () {
      if (skill.id.isEmpty) {
        context.addRequiredError('id');
      }
      if (skill.name.isEmpty) {
        context.addRequiredError('name');
      }

      // Validate inputs
      context.withPath('inputs', () {
        for (var i = 0; i < skill.inputs.length; i++) {
          context.withPath('[$i]', () {
            _validateParameter(skill.inputs[i], context);
          });
        }
      });

      // Validate steps
      context.withPath('steps', () {
        _validateSkillSteps(skill.steps, context);
      });
    });

    return context.toResult();
  }

  /// Validate a profile manifest.
  ValidationResult validateProfile(ProfileManifest profile) {
    final context = ValidationContext();

    context.withPath('profile', () {
      if (profile.id.isEmpty) {
        context.addRequiredError('id');
      }
      if (profile.name.isEmpty) {
        context.addRequiredError('name');
      }

      // Validate sections
      context.withPath('sections', () {
        for (var i = 0; i < profile.sections.length; i++) {
          context.withPath('[$i]', () {
            final section = profile.sections[i];
            if (section.name.isEmpty) {
              context.addRequiredError('name');
            }
            if (section.content.isEmpty) {
              context.addRequiredError('content');
            }
          });
        }
      });
    });

    return context.toResult();
  }

  void _validateManifest(BundleManifest manifest, ValidationContext context) {
    // Required fields
    if (manifest.name.isEmpty) {
      context.addRequiredError('name');
    } else if (!_isValidIdentifier(manifest.name)) {
      context.addInvalidValueError(
        'name',
        manifest.name,
        expected: 'valid identifier (alphanumeric, hyphen, underscore)',
      );
    }

    if (manifest.version.isEmpty) {
      context.addRequiredError('version');
    } else if (!_isValidVersion(manifest.version)) {
      context.addInvalidValueError(
        'version',
        manifest.version,
        expected: 'semantic version (e.g., 1.0.0)',
      );
    }

    // Optional field validations
    if (manifest.license != null && manifest.license!.isNotEmpty) {
      if (options.validateLicense && !_isValidLicense(manifest.license!)) {
        context.addWarning(ValidationWarning.bestPractice(
          'License "${manifest.license}" is not a recognized SPDX identifier',
          location: context.currentPath,
        ));
      }
    }

    if (manifest.homepage != null && manifest.homepage!.isNotEmpty) {
      if (!_isValidUrl(manifest.homepage!)) {
        context.addInvalidValueError('homepage', manifest.homepage, expected: 'valid URL');
      }
    }

    if (manifest.repository != null && manifest.repository!.isNotEmpty) {
      if (!_isValidUrl(manifest.repository!)) {
        context.addInvalidValueError('repository', manifest.repository, expected: 'valid URL');
      }
    }
  }

  void _validateResources(
    List<BundleResource> resources,
    ValidationContext context,
  ) {
    final paths = <String>{};

    for (var i = 0; i < resources.length; i++) {
      context.withPath('[$i]', () {
        final resource = resources[i];

        // Required path
        if (resource.path.isEmpty) {
          context.addRequiredError('path');
        } else {
          // Check for duplicates
          if (paths.contains(resource.path)) {
            context.addError(ValidationError.duplicate(
              'path',
              resource.path,
              location: context.currentPath,
            ));
          }
          paths.add(resource.path);

          // Validate path format
          if (!_isValidResourcePath(resource.path)) {
            context.addInvalidValueError(
              'path',
              resource.path,
              expected: 'valid resource path',
            );
          }
        }

        // Must have content or reference
        if (!resource.hasInlineContent && !resource.hasExternalContent) {
          context.addError(ValidationError(
            code: 'MISSING_CONTENT',
            message: 'Resource must have either content or contentRef',
            location: context.currentPath,
          ));
        }

        // Validate type-specific content
        if (resource.hasInlineContent) {
          _validateResourceContent(resource, context);
        }
      });
    }
  }

  void _validateResourceContent(
    BundleResource resource,
    ValidationContext context,
  ) {
    switch (resource.type) {
      case ResourceType.skill:
        if (resource.content is Map<String, dynamic>) {
          final skillResult = validateSkill(
            SkillManifest.fromJson(resource.content as Map<String, dynamic>),
          );
          for (final error in skillResult.errors) {
            context.addError(error);
          }
          for (final warning in skillResult.warnings) {
            context.addWarning(warning);
          }
        }

      case ResourceType.profile:
        if (resource.content is Map<String, dynamic>) {
          final profileResult = validateProfile(
            ProfileManifest.fromJson(resource.content as Map<String, dynamic>),
          );
          for (final error in profileResult.errors) {
            context.addError(error);
          }
          for (final warning in profileResult.warnings) {
            context.addWarning(warning);
          }
        }

      default:
        // No specific validation for other types
        break;
    }
  }

  void _validateDependencies(
    List<BundleDependency> dependencies,
    ValidationContext context,
  ) {
    final names = <String>{};

    for (var i = 0; i < dependencies.length; i++) {
      context.withPath('[$i]', () {
        final dep = dependencies[i];

        if (dep.name.isEmpty) {
          context.addRequiredError('name');
        } else {
          // Check for duplicate dependencies
          if (names.contains(dep.name)) {
            context.addError(ValidationError.duplicate(
              'dependency',
              dep.name,
              location: context.currentPath,
            ));
          }
          names.add(dep.name);
        }

        // Validate version constraint
        if (dep.version.isNotEmpty && dep.version != '*') {
          if (!_isValidVersionConstraint(dep.version)) {
            context.addInvalidValueError(
              'version',
              dep.version,
              expected: 'valid version constraint',
            );
          }
        }
      });
    }
  }

  void _validateParameter(ParameterSchema param, ValidationContext context) {
    if (param.name.isEmpty) {
      context.addRequiredError('name');
    }

    if (param.type.isEmpty) {
      context.addRequiredError('type');
    } else if (!_isValidType(param.type)) {
      context.addInvalidValueError(
        'type',
        param.type,
        expected: 'valid type (string, number, boolean, array, object, any)',
      );
    }
  }

  void _validateSkillSteps(List<SkillStep> steps, ValidationContext context) {
    final ids = <String>{};
    final referencedIds = <String>{};

    // Collect all step IDs
    for (final step in steps) {
      if (step.id.isNotEmpty) {
        ids.add(step.id);
      }
      for (final nextId in step.next) {
        referencedIds.add(nextId);
      }
    }

    // Validate each step
    for (var i = 0; i < steps.length; i++) {
      context.withPath('[$i]', () {
        final step = steps[i];

        if (step.id.isEmpty) {
          context.addRequiredError('id');
        } else if (ids.where((id) => id == step.id).length > 1) {
          context.addError(ValidationError.duplicate(
            'step id',
            step.id,
            location: context.currentPath,
          ));
        }

        // Validate next references
        for (final nextId in step.next) {
          if (!ids.contains(nextId)) {
            context.addError(ValidationError.unresolvedRef(
              'step "$nextId"',
              location: context.currentPath,
            ));
          }
        }
      });
    }
  }

  void _crossValidate(Bundle bundle, ValidationContext context) {
    // Validate entry point exists
    if (bundle.manifest.entryPoint != null) {
      final entryPoint = bundle.manifest.entryPoint!;
      final exists = bundle.resources.any((r) => r.path == entryPoint);
      if (!exists) {
        context.addError(ValidationError.unresolvedRef(
          'entryPoint "$entryPoint"',
          location: 'manifest.entryPoint',
        ));
      }
    }

    // Validate exports exist
    for (final export in bundle.manifest.exports) {
      final exists = bundle.resources.any((r) => r.path == export);
      if (!exists) {
        context.addError(ValidationError.unresolvedRef(
          'export "$export"',
          location: 'manifest.exports',
        ));
      }
    }
  }

  // Validation helpers

  bool _isValidIdentifier(String value) {
    return RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$').hasMatch(value);
  }

  bool _isValidVersion(String value) {
    return RegExp(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$')
        .hasMatch(value);
  }

  bool _isValidVersionConstraint(String value) {
    // Supports: exact version, ^version, ~version, >=version, etc.
    return RegExp(r'^[\^~>=<]*\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?$').hasMatch(value) ||
        RegExp(r'^\d+\.\d+\.x$').hasMatch(value) ||
        value == '*';
  }

  bool _isValidUrl(String value) {
    return RegExp(r'^https?://').hasMatch(value);
  }

  bool _isValidResourcePath(String value) {
    // No empty segments, no absolute paths, no parent references
    if (value.startsWith('/')) return false;
    if (value.contains('//')) return false;
    if (value.contains('..')) return false;
    return true;
  }

  bool _isValidType(String value) {
    const validTypes = {
      'string', 'number', 'integer', 'boolean', 'array', 'object', 'any', 'null',
    };
    return validTypes.contains(value.toLowerCase());
  }

  bool _isValidLicense(String value) {
    // Common SPDX identifiers
    const commonLicenses = {
      'MIT', 'Apache-2.0', 'GPL-3.0', 'GPL-2.0', 'BSD-3-Clause', 'BSD-2-Clause',
      'ISC', 'MPL-2.0', 'LGPL-3.0', 'LGPL-2.1', 'AGPL-3.0', 'Unlicense', 'CC0-1.0',
    };
    return commonLicenses.contains(value);
  }
}

/// Options for bundle validation.
class ValidatorOptions {
  /// Whether to validate license identifiers.
  final bool validateLicense;

  /// Whether to validate URL accessibility.
  final bool validateUrls;

  /// Whether to perform deep content validation.
  final bool deepValidation;

  /// Custom validation rules.
  final List<ValidationRule> customRules;

  const ValidatorOptions({
    this.validateLicense = false,
    this.validateUrls = false,
    this.deepValidation = true,
    this.customRules = const [],
  });
}

/// A custom validation rule.
abstract class ValidationRule {
  /// Rule identifier.
  String get id;

  /// Rule description.
  String get description;

  /// Apply the rule to a bundle.
  List<ValidationIssue> apply(Bundle bundle);
}
