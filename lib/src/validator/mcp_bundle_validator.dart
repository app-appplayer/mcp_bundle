/// MCP Bundle Validator - Validates section-based McpBundle data.
///
/// Validates bundle data against schema rules, reference integrity,
/// and content hash verification.
library;

import '../models/bundle.dart';
import '../models/manifest.dart';
import '../models/ui_section.dart';
import '../models/flow_section.dart';
import '../models/skill_section.dart';
import '../models/asset.dart';
import '../models/knowledge.dart';
import '../models/binding.dart';
import '../models/profile_section.dart';
import '../models/test_section.dart';
import '../models/policy.dart';
import '../models/fact_graph_schema.dart';
import '../models/integrity.dart';
import '../expression/lexer.dart';
import '../expression/parser.dart';
import 'validation_result.dart';

/// Error codes for MCP bundle validation.
abstract class McpValidationCodes {
  // Schema errors
  static const missingRequired = 'MISSING_REQUIRED';
  static const invalidType = 'INVALID_TYPE';
  static const invalidPattern = 'INVALID_PATTERN';
  static const invalidValue = 'INVALID_VALUE';

  // Reference errors
  static const unknownReference = 'UNKNOWN_REFERENCE';
  static const circularReference = 'CIRCULAR_REFERENCE';
  static const duplicateId = 'DUPLICATE_ID';

  // Integrity errors
  static const hashMismatch = 'HASH_MISMATCH';
  static const signatureInvalid = 'SIGNATURE_INVALID';
  static const signatureExpired = 'SIGNATURE_EXPIRED';
}

/// Validator for section-based MCP bundles.
class McpBundleValidator {
  /// Validate entire bundle.
  static ValidationResult validate(McpBundle bundle) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    // Schema validation
    errors.addAll(_validateSchema(bundle, warnings));

    // Reference validation
    errors.addAll(_validateReferences(bundle, warnings));

    // Integrity validation
    errors.addAll(_validateIntegrity(bundle, warnings));

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate schema only.
  static ValidationResult validateSchema(McpBundle bundle) {
    final warnings = <ValidationWarning>[];
    final errors = _validateSchema(bundle, warnings);
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate references only.
  static ValidationResult validateReferences(McpBundle bundle) {
    final warnings = <ValidationWarning>[];
    final errors = _validateReferences(bundle, warnings);
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate integrity only.
  static ValidationResult validateIntegrity(McpBundle bundle) {
    final warnings = <ValidationWarning>[];
    if (bundle.integrity == null) {
      return ValidationResult.valid();
    }
    final errors = _validateIntegrity(bundle, warnings);
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // ==================== Schema Validation ====================

  static List<ValidationError> _validateSchema(
    McpBundle bundle,
    List<ValidationWarning> warnings,
  ) {
    final errors = <ValidationError>[];

    // Validate schemaVersion
    if (bundle.schemaVersion.isEmpty) {
      errors.add(const ValidationError(
        code: McpValidationCodes.missingRequired,
        message: 'schemaVersion is required',
        location: 'schemaVersion',
      ));
    }

    // Validate manifest
    errors.addAll(_validateManifest(bundle.manifest, warnings));

    // Validate sections
    if (bundle.ui != null) {
      errors.addAll(_validateUiSection(bundle.ui!));
    }
    if (bundle.skills != null) {
      errors.addAll(_validateSkillSection(bundle.skills!));
    }
    if (bundle.assets != null) {
      errors.addAll(_validateAssetSection(bundle.assets!));
    }
    if (bundle.policies != null) {
      errors.addAll(_validatePolicySection(bundle.policies!));
    }
    if (bundle.factGraphSchema != null) {
      errors.addAll(_validateFactGraphSchemaSection(bundle.factGraphSchema!));
    }
    if (bundle.flow != null) {
      errors.addAll(_validateFlowSection(bundle.flow!));
    }
    if (bundle.knowledge != null) {
      errors.addAll(_validateKnowledgeSection(bundle.knowledge!));
    }
    if (bundle.bindings != null) {
      errors.addAll(_validateBindingsSection(bundle.bindings!));
    }
    if (bundle.profiles != null) {
      errors.addAll(_validateProfilesSection(bundle.profiles!));
    }
    if (bundle.tests != null) {
      errors.addAll(_validateTestSection(bundle.tests!));
    }

    // Validate expression syntax in all sections
    errors.addAll(_validateExpressions(bundle));

    return errors;
  }

  static List<ValidationError> _validateManifest(
    BundleManifest manifest,
    List<ValidationWarning> warnings,
  ) {
    final errors = <ValidationError>[];

    // ID pattern: lowercase, dots, underscores
    if (manifest.id.isEmpty) {
      errors.add(const ValidationError(
        code: McpValidationCodes.missingRequired,
        message: 'Bundle ID is required',
        location: 'manifest.id',
      ));
    } else {
      final idPattern = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$');
      if (!idPattern.hasMatch(manifest.id)) {
        errors.add(const ValidationError(
          code: McpValidationCodes.invalidPattern,
          message: 'Invalid bundle ID format: must be lowercase with dots/underscores',
          location: 'manifest.id',
        ));
      }
    }

    // Name required
    if (manifest.name.isEmpty) {
      errors.add(const ValidationError(
        code: McpValidationCodes.missingRequired,
        message: 'Bundle name is required',
        location: 'manifest.name',
      ));
    }

    // Version pattern: semver
    if (manifest.version.isEmpty) {
      errors.add(const ValidationError(
        code: McpValidationCodes.missingRequired,
        message: 'Bundle version is required',
        location: 'manifest.version',
      ));
    } else {
      final versionPattern = RegExp(
        r'^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?(\+[a-zA-Z0-9.]+)?$',
      );
      if (!versionPattern.hasMatch(manifest.version)) {
        errors.add(const ValidationError(
          code: McpValidationCodes.invalidPattern,
          message: 'Invalid version format (expected semver)',
          location: 'manifest.version',
        ));
      }
    }

    return errors;
  }

  static List<ValidationError> _validateUiSection(UiSection ui) {
    final errors = <ValidationError>[];
    final pageIds = <String>{};

    for (var i = 0; i < ui.pages.length; i++) {
      final page = ui.pages[i];
      final path = 'ui.pages[$i]';

      // Required: id
      if (page.id.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Page id is required',
          location: '$path.id',
        ));
      }

      // Pattern: id format
      final idPattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$');
      if (page.id.isNotEmpty && !idPattern.hasMatch(page.id)) {
        errors.add(ValidationError(
          code: McpValidationCodes.invalidPattern,
          message: 'Invalid page id format',
          location: '$path.id',
        ));
      }

      // Duplicate check
      if (pageIds.contains(page.id)) {
        errors.add(ValidationError(
          code: McpValidationCodes.duplicateId,
          message: 'Duplicate page id: ${page.id}',
          location: '$path.id',
        ));
      }
      pageIds.add(page.id);

      // Validate root widget
      errors.addAll(_validateWidgetNode(page.root, '$path.root'));
    }

    return errors;
  }

  static List<ValidationError> _validateWidgetNode(WidgetNode widget, String path) {
    final errors = <ValidationError>[];

    // Required: type
    if (widget.type.isEmpty) {
      errors.add(ValidationError(
        code: McpValidationCodes.missingRequired,
        message: 'Widget type is required',
        location: '$path.type',
      ));
    }

    // Validate actions
    for (final entry in widget.actions.entries) {
      errors.addAll(_validateAction(entry.value, '$path.actions[${entry.key}]'));
    }

    // Recursive validation for children
    for (var i = 0; i < widget.children.length; i++) {
      errors.addAll(_validateWidgetNode(widget.children[i], '$path.children[$i]'));
    }

    return errors;
  }

  static List<ValidationError> _validateAction(ActionDef action, String path) {
    final errors = <ValidationError>[];

    // Validate action type
    if (action.type == ActionType.callSkill && action.target == null) {
      errors.add(ValidationError(
        code: McpValidationCodes.missingRequired,
        message: 'Skill action requires target',
        location: '$path.target',
      ));
    }

    if (action.type == ActionType.navigate && action.target == null) {
      errors.add(ValidationError(
        code: McpValidationCodes.missingRequired,
        message: 'Navigate action requires target',
        location: '$path.target',
      ));
    }

    return errors;
  }

  static List<ValidationError> _validateSkillSection(SkillSection skills) {
    final errors = <ValidationError>[];
    final moduleIds = <String>{};

    for (var i = 0; i < skills.modules.length; i++) {
      final module = skills.modules[i];
      final path = 'skills.modules[$i]';

      // Required: id
      if (module.id.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Skill module id is required',
          location: '$path.id',
        ));
      }

      // Required: name
      if (module.name.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Skill module name is required',
          location: '$path.name',
        ));
      }

      // Duplicate check
      if (moduleIds.contains(module.id)) {
        errors.add(ValidationError(
          code: McpValidationCodes.duplicateId,
          message: 'Duplicate skill module id: ${module.id}',
          location: '$path.id',
        ));
      }
      moduleIds.add(module.id);

      // Validate procedures
      final procedureIds = <String>{};
      for (var j = 0; j < module.procedures.length; j++) {
        final proc = module.procedures[j];
        final procPath = '$path.procedures[$j]';

        if (proc.id.isEmpty) {
          errors.add(ValidationError(
            code: McpValidationCodes.missingRequired,
            message: 'Procedure id is required',
            location: '$procPath.id',
          ));
        }

        if (procedureIds.contains(proc.id)) {
          errors.add(ValidationError(
            code: McpValidationCodes.duplicateId,
            message: 'Duplicate procedure id within skill: ${proc.id}',
            location: '$procPath.id',
          ));
        }
        procedureIds.add(proc.id);
      }
    }

    return errors;
  }

  static List<ValidationError> _validateAssetSection(AssetSection assets) {
    final errors = <ValidationError>[];
    final assetPaths = <String>{};

    for (var i = 0; i < assets.assets.length; i++) {
      final asset = assets.assets[i];
      final path = 'assets.assets[$i]';

      // Required: path
      if (asset.path.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Asset path is required',
          location: '$path.path',
        ));
      }

      // Duplicate check
      if (assetPaths.contains(asset.path)) {
        errors.add(ValidationError(
          code: McpValidationCodes.duplicateId,
          message: 'Duplicate asset path: ${asset.path}',
          location: '$path.path',
        ));
      }
      assetPaths.add(asset.path);

      // Must have content or reference
      if (!asset.hasInlineContent && !asset.hasExternalContent) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Asset must have content or contentRef',
          location: path,
        ));
      }
    }

    return errors;
  }

  static List<ValidationError> _validatePolicySection(PolicySection policies) {
    final errors = <ValidationError>[];
    final policyIds = <String>{};

    for (var i = 0; i < policies.policies.length; i++) {
      final policy = policies.policies[i];
      final path = 'policies.policies[$i]';

      // Required: id
      if (policy.id.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Policy id is required',
          location: '$path.id',
        ));
      }

      // Duplicate check
      if (policyIds.contains(policy.id)) {
        errors.add(ValidationError(
          code: McpValidationCodes.duplicateId,
          message: 'Duplicate policy id: ${policy.id}',
          location: '$path.id',
        ));
      }
      policyIds.add(policy.id);

      // Required: name
      if (policy.name.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Policy name is required',
          location: '$path.name',
        ));
      }

      // Validate rules
      if (policy.rules.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Policy must have at least one rule',
          location: '$path.rules',
        ));
      }

      final ruleIds = <String>{};
      for (var j = 0; j < policy.rules.length; j++) {
        final rule = policy.rules[j];
        final rulePath = '$path.rules[$j]';

        // Required: id
        if (rule.id.isEmpty) {
          errors.add(ValidationError(
            code: McpValidationCodes.missingRequired,
            message: 'Rule id is required',
            location: '$rulePath.id',
          ));
        }

        // Duplicate rule check
        if (ruleIds.contains(rule.id)) {
          errors.add(ValidationError(
            code: McpValidationCodes.duplicateId,
            message: 'Duplicate rule id within policy: ${rule.id}',
            location: '$rulePath.id',
          ));
        }
        ruleIds.add(rule.id);

        // Validate condition
        errors.addAll(_validatePolicyCondition(rule.condition, '$rulePath.condition'));
      }

      // Validate priority range (0-100)
      if (policy.priority < 0 || policy.priority > 100) {
        errors.add(ValidationError(
          code: McpValidationCodes.invalidValue,
          message: 'Policy priority must be between 0 and 100',
          location: '$path.priority',
        ));
      }
    }

    return errors;
  }

  static List<ValidationError> _validatePolicyCondition(
    PolicyCondition condition,
    String path,
  ) {
    final errors = <ValidationError>[];

    switch (condition) {
      case ThresholdCondition():
        if (condition.metric.isEmpty) {
          errors.add(ValidationError(
            code: McpValidationCodes.missingRequired,
            message: 'Threshold condition requires metric',
            location: '$path.metric',
          ));
        }
        // Validate "between" operator has a [min, max] list value
        if (condition.operator == ThresholdOperator.between) {
          if (condition.value is! List || (condition.value as List).length != 2) {
            errors.add(ValidationError(
              code: McpValidationCodes.invalidValue,
              message: 'Between operator requires [min, max] value',
              location: '$path.value',
            ));
          }
        }

      case CompositeCondition():
        if (condition.conditions.isEmpty) {
          errors.add(ValidationError(
            code: McpValidationCodes.missingRequired,
            message: 'Composite condition requires at least one child condition',
            location: '$path.conditions',
          ));
        }
        // Recursive validation
        for (var i = 0; i < condition.conditions.length; i++) {
          errors.addAll(_validatePolicyCondition(
            condition.conditions[i],
            '$path.conditions[$i]',
          ));
        }

      case ExpressionCondition():
        if (condition.expression.isEmpty) {
          errors.add(ValidationError(
            code: McpValidationCodes.missingRequired,
            message: 'Expression condition requires expression',
            location: '$path.expression',
          ));
        }

      case MetricCondition():
        if (condition.metric.isEmpty) {
          errors.add(ValidationError(
            code: McpValidationCodes.missingRequired,
            message: 'Metric condition requires metric',
            location: '$path.metric',
          ));
        }

      case AlwaysCondition():
        // No additional validation needed
        break;
    }

    return errors;
  }

  static List<ValidationError> _validateFactGraphSchemaSection(
    FactGraphSchema schema,
  ) {
    final errors = <ValidationError>[];
    final entityTypeNames = <String>{};
    final relationTypeNames = <String>{};
    final factTypeNames = <String>{};

    // Validate entity types
    for (var i = 0; i < schema.entityTypes.length; i++) {
      final entityType = schema.entityTypes[i];
      final path = 'factGraphSchema.entityTypes[$i]';

      // Required: name
      if (entityType.name.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Entity type name is required',
          location: '$path.name',
        ));
      }

      // Duplicate check
      if (entityTypeNames.contains(entityType.name)) {
        errors.add(ValidationError(
          code: McpValidationCodes.duplicateId,
          message: 'Duplicate entity type name: ${entityType.name}',
          location: '$path.name',
        ));
      }
      entityTypeNames.add(entityType.name);

      // Validate properties
      final propertyNames = <String>{};
      for (var j = 0; j < entityType.properties.length; j++) {
        final property = entityType.properties[j];
        final propPath = '$path.properties[$j]';

        if (property.name.isEmpty) {
          errors.add(ValidationError(
            code: McpValidationCodes.missingRequired,
            message: 'Property name is required',
            location: '$propPath.name',
          ));
        }

        if (propertyNames.contains(property.name)) {
          errors.add(ValidationError(
            code: McpValidationCodes.duplicateId,
            message: 'Duplicate property name: ${property.name}',
            location: '$propPath.name',
          ));
        }
        propertyNames.add(property.name);

        // Validate property type
        final validTypes = ['string', 'number', 'integer', 'double', 'boolean', 'date', 'datetime', 'list', 'map', 'object'];
        if (!validTypes.contains(property.type.toLowerCase())) {
          errors.add(ValidationError(
            code: McpValidationCodes.invalidValue,
            message: 'Invalid property type: ${property.type}',
            location: '$propPath.type',
          ));
        }
      }

      // Validate required properties exist
      for (final requiredProp in entityType.requiredProperties) {
        if (!propertyNames.contains(requiredProp)) {
          errors.add(ValidationError(
            code: McpValidationCodes.unknownReference,
            message: 'Required property not found: $requiredProp',
            location: '$path.requiredProperties',
          ));
        }
      }
    }

    // Validate relation types
    for (var i = 0; i < schema.relationTypes.length; i++) {
      final relationType = schema.relationTypes[i];
      final path = 'factGraphSchema.relationTypes[$i]';

      // Required: name
      if (relationType.name.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Relation type name is required',
          location: '$path.name',
        ));
      }

      // Duplicate check
      if (relationTypeNames.contains(relationType.name)) {
        errors.add(ValidationError(
          code: McpValidationCodes.duplicateId,
          message: 'Duplicate relation type name: ${relationType.name}',
          location: '$path.name',
        ));
      }
      relationTypeNames.add(relationType.name);

      // Validate from/to entity types exist
      if (relationType.fromEntityType.isNotEmpty &&
          !entityTypeNames.contains(relationType.fromEntityType)) {
        errors.add(ValidationError(
          code: McpValidationCodes.unknownReference,
          message: 'Unknown source entity type: ${relationType.fromEntityType}',
          location: '$path.fromEntityType',
        ));
      }

      if (relationType.toEntityType.isNotEmpty &&
          !entityTypeNames.contains(relationType.toEntityType)) {
        errors.add(ValidationError(
          code: McpValidationCodes.unknownReference,
          message: 'Unknown target entity type: ${relationType.toEntityType}',
          location: '$path.toEntityType',
        ));
      }
    }

    // Validate fact types
    for (var i = 0; i < schema.factTypes.length; i++) {
      final factType = schema.factTypes[i];
      final path = 'factGraphSchema.factTypes[$i]';

      // Required: name
      if (factType.name.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Fact type name is required',
          location: '$path.name',
        ));
      }

      // Duplicate check
      if (factTypeNames.contains(factType.name)) {
        errors.add(ValidationError(
          code: McpValidationCodes.duplicateId,
          message: 'Duplicate fact type name: ${factType.name}',
          location: '$path.name',
        ));
      }
      factTypeNames.add(factType.name);

      // Validate value type
      final validValueTypes = ['string', 'number', 'boolean', 'date', 'datetime', 'json'];
      if (!validValueTypes.contains(factType.valueType.toLowerCase())) {
        errors.add(ValidationError(
          code: McpValidationCodes.invalidValue,
          message: 'Invalid fact value type: ${factType.valueType}',
          location: '$path.valueType',
        ));
      }
    }

    return errors;
  }

  // ==================== Flow Section Validation ====================

  static List<ValidationError> _validateFlowSection(FlowSection flow) {
    final errors = <ValidationError>[];
    final flowIds = <String>{};

    for (var i = 0; i < flow.flows.length; i++) {
      final flowDef = flow.flows[i];
      final path = 'flow.flows[$i]';

      // Required: id
      if (flowDef.id.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Flow id is required',
          location: '$path.id',
        ));
      }

      // Duplicate check
      if (flowIds.contains(flowDef.id)) {
        errors.add(ValidationError(
          code: McpValidationCodes.duplicateId,
          message: 'Duplicate flow id: ${flowDef.id}',
          location: '$path.id',
        ));
      }
      flowIds.add(flowDef.id);

      // Validate steps
      final stepIds = <String>{};
      for (var j = 0; j < flowDef.steps.length; j++) {
        final step = flowDef.steps[j];
        final stepPath = '$path.steps[$j]';

        // Required: id
        if (step.id.isEmpty) {
          errors.add(ValidationError(
            code: McpValidationCodes.missingRequired,
            message: 'Flow step id is required',
            location: '$stepPath.id',
          ));
        }

        // Duplicate step check
        if (stepIds.contains(step.id)) {
          errors.add(ValidationError(
            code: McpValidationCodes.duplicateId,
            message: 'Duplicate flow step id: ${step.id}',
            location: '$stepPath.id',
          ));
        }
        stepIds.add(step.id);
      }

      // Validate step references (next, onError) point to existing step IDs
      for (var j = 0; j < flowDef.steps.length; j++) {
        final step = flowDef.steps[j];
        final stepPath = '$path.steps[$j]';

        for (final nextId in step.next) {
          if (!stepIds.contains(nextId)) {
            errors.add(ValidationError(
              code: McpValidationCodes.unknownReference,
              message: 'Unknown next step reference: $nextId',
              location: '$stepPath.next',
            ));
          }
        }

        if (step.onError != null && !stepIds.contains(step.onError)) {
          errors.add(ValidationError(
            code: McpValidationCodes.unknownReference,
            message: 'Unknown onError step reference: ${step.onError}',
            location: '$stepPath.onError',
          ));
        }
      }
    }

    return errors;
  }

  // ==================== Knowledge Section Validation ====================

  static List<ValidationError> _validateKnowledgeSection(
    KnowledgeSection knowledge,
  ) {
    final errors = <ValidationError>[];
    final sourceIds = <String>{};

    for (var i = 0; i < knowledge.sources.length; i++) {
      final source = knowledge.sources[i];
      final path = 'knowledge.sources[$i]';

      // Required: id
      if (source.id.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Knowledge source id is required',
          location: '$path.id',
        ));
      }

      // Duplicate check
      if (sourceIds.contains(source.id)) {
        errors.add(ValidationError(
          code: McpValidationCodes.duplicateId,
          message: 'Duplicate knowledge source id: ${source.id}',
          location: '$path.id',
        ));
      }
      sourceIds.add(source.id);

      // Required: name
      if (source.name.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Knowledge source name is required',
          location: '$path.name',
        ));
      }
    }

    return errors;
  }

  // ==================== Bindings Section Validation ====================

  static List<ValidationError> _validateBindingsSection(
    BindingSection bindings,
  ) {
    final errors = <ValidationError>[];
    final bindingIds = <String>{};
    final sourceIds = <String>{};

    // Validate data sources
    for (var i = 0; i < bindings.sources.length; i++) {
      final source = bindings.sources[i];
      final path = 'bindings.sources[$i]';

      if (source.id.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Data source id is required',
          location: '$path.id',
        ));
      }

      if (sourceIds.contains(source.id)) {
        errors.add(ValidationError(
          code: McpValidationCodes.duplicateId,
          message: 'Duplicate data source id: ${source.id}',
          location: '$path.id',
        ));
      }
      sourceIds.add(source.id);
    }

    // Validate bindings
    for (var i = 0; i < bindings.bindings.length; i++) {
      final binding = bindings.bindings[i];
      final path = 'bindings.bindings[$i]';

      // Required: id
      if (binding.id.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Binding id is required',
          location: '$path.id',
        ));
      }

      // Duplicate check
      if (bindingIds.contains(binding.id)) {
        errors.add(ValidationError(
          code: McpValidationCodes.duplicateId,
          message: 'Duplicate binding id: ${binding.id}',
          location: '$path.id',
        ));
      }
      bindingIds.add(binding.id);

      // Required: source
      if (binding.source.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Binding source is required',
          location: '$path.source',
        ));
      }

      // Required: target
      if (binding.target.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Binding target is required',
          location: '$path.target',
        ));
      }
    }

    return errors;
  }

  // ==================== Profiles Section Validation ====================

  static List<ValidationError> _validateProfilesSection(
    ProfilesSection profiles,
  ) {
    final errors = <ValidationError>[];
    final profileIds = <String>{};

    for (var i = 0; i < profiles.profiles.length; i++) {
      final profile = profiles.profiles[i];
      final path = 'profiles.profiles[$i]';

      // Required: id
      if (profile.id.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Profile id is required',
          location: '$path.id',
        ));
      }

      // Duplicate check
      if (profileIds.contains(profile.id)) {
        errors.add(ValidationError(
          code: McpValidationCodes.duplicateId,
          message: 'Duplicate profile id: ${profile.id}',
          location: '$path.id',
        ));
      }
      profileIds.add(profile.id);

      // Required: name
      if (profile.name.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Profile name is required',
          location: '$path.name',
        ));
      }
    }

    return errors;
  }

  // ==================== Test Section Validation ====================

  static List<ValidationError> _validateTestSection(TestSection tests) {
    final errors = <ValidationError>[];
    final suiteIds = <String>{};

    for (var i = 0; i < tests.suites.length; i++) {
      final suite = tests.suites[i];
      final path = 'tests.suites[$i]';

      // Required: id
      if (suite.id.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Test suite id is required',
          location: '$path.id',
        ));
      }

      // Duplicate check
      if (suiteIds.contains(suite.id)) {
        errors.add(ValidationError(
          code: McpValidationCodes.duplicateId,
          message: 'Duplicate test suite id: ${suite.id}',
          location: '$path.id',
        ));
      }
      suiteIds.add(suite.id);

      // Validate test cases
      final caseIds = <String>{};
      for (var j = 0; j < suite.tests.length; j++) {
        final testCase = suite.tests[j];
        final casePath = '$path.tests[$j]';

        // Required: id
        if (testCase.id.isEmpty) {
          errors.add(ValidationError(
            code: McpValidationCodes.missingRequired,
            message: 'Test case id is required',
            location: '$casePath.id',
          ));
        }

        // Duplicate case check within suite
        if (caseIds.contains(testCase.id)) {
          errors.add(ValidationError(
            code: McpValidationCodes.duplicateId,
            message: 'Duplicate test case id within suite: ${testCase.id}',
            location: '$casePath.id',
          ));
        }
        caseIds.add(testCase.id);
      }
    }

    return errors;
  }

  // ==================== Expression Syntax Validation ====================

  static List<ValidationError> _validateExpressionSyntax(
    String expression,
    String path,
  ) {
    try {
      final tokens = Lexer(expression).tokenize();
      Parser(tokens).parse();
      return [];
    } on ParserException catch (e) {
      return [
        ValidationError(
          code: McpValidationCodes.invalidValue,
          message: 'Expression syntax error: ${e.message}',
          location: path,
        ),
      ];
    } on LexerException catch (e) {
      return [
        ValidationError(
          code: McpValidationCodes.invalidValue,
          message: 'Expression lexer error: ${e.message}',
          location: path,
        ),
      ];
    }
  }

  static List<ValidationError> _validateExpressions(McpBundle bundle) {
    final errors = <ValidationError>[];

    // Flow trigger conditions and step conditions
    if (bundle.flow != null) {
      for (var i = 0; i < bundle.flow!.flows.length; i++) {
        final flowDef = bundle.flow!.flows[i];

        if (flowDef.trigger?.condition != null) {
          errors.addAll(_validateExpressionSyntax(
            flowDef.trigger!.condition!,
            'flow.flows[$i].trigger.condition',
          ));
        }

        if (flowDef.output?.expression != null) {
          errors.addAll(_validateExpressionSyntax(
            flowDef.output!.expression!,
            'flow.flows[$i].output.expression',
          ));
        }

        for (var j = 0; j < flowDef.steps.length; j++) {
          final step = flowDef.steps[j];
          if (step.condition != null) {
            errors.addAll(_validateExpressionSyntax(
              step.condition!,
              'flow.flows[$i].steps[$j].condition',
            ));
          }
        }
      }
    }

    // Binding transforms and conditions
    if (bundle.bindings != null) {
      for (var i = 0; i < bundle.bindings!.bindings.length; i++) {
        final binding = bundle.bindings!.bindings[i];

        if (binding.transform != null) {
          errors.addAll(_validateExpressionSyntax(
            binding.transform!,
            'bindings.bindings[$i].transform',
          ));
        }

        if (binding.condition != null) {
          errors.addAll(_validateExpressionSyntax(
            binding.condition!,
            'bindings.bindings[$i].condition',
          ));
        }
      }

      // Computed value expressions
      for (final entry in bundle.bindings!.computed.entries) {
        if (entry.value.expression.isNotEmpty) {
          errors.addAll(_validateExpressionSyntax(
            entry.value.expression,
            'bindings.computed[${entry.key}].expression',
          ));
        }
      }
    }

    // Profile section conditions
    if (bundle.profiles != null) {
      for (var i = 0; i < bundle.profiles!.profiles.length; i++) {
        final profile = bundle.profiles!.profiles[i];
        for (var j = 0; j < profile.sections.length; j++) {
          final section = profile.sections[j];
          if (section.condition != null) {
            errors.addAll(_validateExpressionSyntax(
              section.condition!,
              'profiles.profiles[$i].sections[$j].condition',
            ));
          }
        }
      }
    }

    // Skill procedure step conditions
    if (bundle.skills != null) {
      for (var i = 0; i < bundle.skills!.modules.length; i++) {
        final module = bundle.skills!.modules[i];
        for (var j = 0; j < module.procedures.length; j++) {
          final proc = module.procedures[j];
          for (var k = 0; k < proc.steps.length; k++) {
            final step = proc.steps[k];
            if (step.condition != null) {
              errors.addAll(_validateExpressionSyntax(
                step.condition!,
                'skills.modules[$i].procedures[$j].steps[$k].condition',
              ));
            }
          }
        }
      }
    }

    // Test fixture factory expressions
    if (bundle.tests != null) {
      for (final entry in bundle.tests!.fixtures.entries) {
        if (entry.value.factory != null) {
          errors.addAll(_validateExpressionSyntax(
            entry.value.factory!,
            'tests.fixtures[${entry.key}].factory',
          ));
        }
      }
    }

    return errors;
  }

  // ==================== Integrity Validation ====================

  static List<ValidationError> _validateIntegrity(
    McpBundle bundle,
    List<ValidationWarning> warnings,
  ) {
    final errors = <ValidationError>[];
    final integrity = bundle.integrity;

    if (integrity == null) return errors;

    // Validate content hash
    if (integrity.contentHash != null) {
      final contentHash = integrity.contentHash!;

      if (contentHash.value.isEmpty) {
        errors.add(const ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Content hash value is required',
          location: 'integrity.contentHash.value',
        ));
      }

      if (contentHash.algorithm == HashAlgorithm.unknown) {
        errors.add(const ValidationError(
          code: McpValidationCodes.invalidValue,
          message: 'Unknown hash algorithm',
          location: 'integrity.contentHash.algorithm',
        ));
      }
    }

    // Validate file hashes
    for (var i = 0; i < integrity.files.length; i++) {
      final fileHash = integrity.files[i];
      final path = 'integrity.files[$i]';

      if (fileHash.path.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'File hash path is required',
          location: '$path.path',
        ));
      }

      if (fileHash.value.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'File hash value is required',
          location: '$path.value',
        ));
      }

      if (fileHash.algorithm == HashAlgorithm.unknown) {
        errors.add(ValidationError(
          code: McpValidationCodes.invalidValue,
          message: 'Unknown hash algorithm for file: ${fileHash.path}',
          location: '$path.algorithm',
        ));
      }
    }

    // Validate signatures
    for (var i = 0; i < integrity.signatures.length; i++) {
      final signature = integrity.signatures[i];
      final path = 'integrity.signatures[$i]';

      if (signature.keyId.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Signature key ID is required',
          location: '$path.keyId',
        ));
      }

      if (signature.value.isEmpty) {
        errors.add(ValidationError(
          code: McpValidationCodes.missingRequired,
          message: 'Signature value is required',
          location: '$path.value',
        ));
      }

      if (signature.algorithm == SignatureAlgorithm.unknown) {
        errors.add(ValidationError(
          code: McpValidationCodes.invalidValue,
          message: 'Unknown signature algorithm',
          location: '$path.algorithm',
        ));
      }

      // Check signature expiration if timestamp exists
      if (signature.timestamp != null) {
        // Signatures older than 1 year generate a warning
        final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
        if (signature.timestamp!.isBefore(oneYearAgo)) {
          warnings.add(ValidationWarning(
            code: McpValidationCodes.signatureExpired,
            message: 'Signature is older than 1 year',
            location: '$path.timestamp',
          ));
        }
      }
    }

    return errors;
  }

  // ==================== Reference Validation ====================

  static List<ValidationError> _validateReferences(
    McpBundle bundle,
    List<ValidationWarning> warnings,
  ) {
    final errors = <ValidationError>[];

    // Collect all defined IDs across sections
    final skillIds =
        bundle.skills?.modules.map((m) => m.id).toSet() ?? {};
    final pageIds =
        bundle.ui?.pages.map((s) => s.id).toSet() ?? {};
    final knowledgeSourceIds =
        bundle.knowledge?.sources.map((s) => s.id).toSet() ?? {};

    // Validate UI → skill references and UI → page navigation
    if (bundle.ui != null) {
      for (final page in bundle.ui!.pages) {
        _validateWidgetReferences(
          page.root,
          skillIds,
          pageIds,
          errors,
          warnings,
        );
      }
    }

    // Validate skill → knowledge source references
    if (bundle.skills != null) {
      for (var i = 0; i < bundle.skills!.modules.length; i++) {
        final module = bundle.skills!.modules[i];
        for (var j = 0; j < module.knowledgeSources.length; j++) {
          final ref = module.knowledgeSources[j];
          if (ref.sourceId.isNotEmpty &&
              !knowledgeSourceIds.contains(ref.sourceId)) {
            errors.add(ValidationError(
              code: McpValidationCodes.unknownReference,
              message: 'Unknown knowledge source reference: ${ref.sourceId}',
              location:
                  'skills.modules[$i].knowledgeSources[$j].sourceId',
            ));
          }
        }

        // Validate procedure entryPoint and step next/onError references
        for (var j = 0; j < module.procedures.length; j++) {
          final proc = module.procedures[j];
          final stepIds =
              proc.steps.map((s) => s.id).toSet();

          // entryPoint must reference a valid step
          if (proc.entryPoint != null &&
              proc.entryPoint!.isNotEmpty &&
              !stepIds.contains(proc.entryPoint)) {
            errors.add(ValidationError(
              code: McpValidationCodes.unknownReference,
              message: 'Unknown entryPoint step: ${proc.entryPoint}',
              location:
                  'skills.modules[$i].procedures[$j].entryPoint',
            ));
          }

          // Step next/onError references
          for (var k = 0; k < proc.steps.length; k++) {
            final step = proc.steps[k];
            final stepPath =
                'skills.modules[$i].procedures[$j].steps[$k]';

            for (final nextId in step.next) {
              if (!stepIds.contains(nextId)) {
                errors.add(ValidationError(
                  code: McpValidationCodes.unknownReference,
                  message: 'Unknown next step reference: $nextId',
                  location: '$stepPath.next',
                ));
              }
            }

            if (step.onError != null &&
                !stepIds.contains(step.onError)) {
              errors.add(ValidationError(
                code: McpValidationCodes.unknownReference,
                message:
                    'Unknown onError step reference: ${step.onError}',
                location: '$stepPath.onError',
              ));
            }
          }
        }
      }
    }

    // Check for circular dependencies
    errors.addAll(_checkCircularDependencies(bundle));

    return errors;
  }

  static void _validateWidgetReferences(
    WidgetNode widget,
    Set<String> skillIds,
    Set<String> pageIds,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
  ) {
    // Check action references
    for (final action in widget.actions.values) {
      if (action.type == ActionType.callSkill && action.target != null) {
        if (!skillIds.contains(action.target)) {
          errors.add(ValidationError(
            code: McpValidationCodes.unknownReference,
            message: 'Unknown skill reference: ${action.target}',
            location: 'ui.action.target',
          ));
        }
      }

      if (action.type == ActionType.navigate && action.target != null) {
        // Navigation targets could be page IDs or routes
        if (!pageIds.contains(action.target) &&
            !action.target!.startsWith('/')) {
          warnings.add(ValidationWarning(
            code: 'UNVERIFIED_NAVIGATION',
            message: 'Navigation target may not exist: ${action.target}',
            location: 'ui.action.target',
          ));
        }
      }
    }

    // Recursive check for children
    for (final child in widget.children) {
      _validateWidgetReferences(child, skillIds, pageIds, errors, warnings);
    }
  }

  static List<ValidationError> _checkCircularDependencies(McpBundle bundle) {
    final errors = <ValidationError>[];

    // Build dependency graph
    final graph = <String, List<String>>{};

    // Skill → knowledge source edges via knowledgeSources refs
    for (final module in bundle.skills?.modules ?? <SkillModule>[]) {
      final moduleId = 'skill:${module.id}';
      graph.putIfAbsent(moduleId, () => []);

      for (final ref in module.knowledgeSources) {
        if (ref.sourceId.isNotEmpty) {
          final targetId = 'knowledge:${ref.sourceId}';
          graph[moduleId]!.add(targetId);
          graph.putIfAbsent(targetId, () => []);
        }
      }
    }

    // Flow step chains: step → next step edges
    for (final flowDef in bundle.flow?.flows ?? <FlowDefinition>[]) {
      for (final step in flowDef.steps) {
        final stepNodeId = 'flow:${flowDef.id}:${step.id}';
        graph.putIfAbsent(stepNodeId, () => []);

        for (final nextId in step.next) {
          final nextNodeId = 'flow:${flowDef.id}:$nextId';
          graph[stepNodeId]!.add(nextNodeId);
          graph.putIfAbsent(nextNodeId, () => []);
        }
      }
    }

    // Procedure step chains: step → next step edges
    for (final module in bundle.skills?.modules ?? <SkillModule>[]) {
      for (final proc in module.procedures) {
        for (final step in proc.steps) {
          final stepNodeId =
              'proc:${module.id}:${proc.id}:${step.id}';
          graph.putIfAbsent(stepNodeId, () => []);

          for (final nextId in step.next) {
            final nextNodeId =
                'proc:${module.id}:${proc.id}:$nextId';
            graph[stepNodeId]!.add(nextNodeId);
            graph.putIfAbsent(nextNodeId, () => []);
          }
        }
      }
    }

    // Page → skill edges via UI actions
    for (final page in bundle.ui?.pages ?? <PageDefinition>[]) {
      final pageId = 'page:${page.id}';
      graph.putIfAbsent(pageId, () => []);
      _collectWidgetDeps(page.root, pageId, graph);
    }

    // Detect cycles using DFS with color marking
    final color = <String, int>{};
    const white = 0, gray = 1, black = 2;

    for (final node in graph.keys) {
      color[node] = white;
    }

    List<String> cyclePath = [];

    bool dfs(String node) {
      color[node] = gray;
      cyclePath.add(node);

      for (final neighbor in graph[node] ?? <String>[]) {
        if (color[neighbor] == gray) {
          final cycleStart = cyclePath.indexOf(neighbor);
          final cycle = [...cyclePath.sublist(cycleStart), neighbor];
          errors.add(ValidationError(
            code: McpValidationCodes.circularReference,
            message: 'Circular dependency detected: ${cycle.join(' → ')}',
            location: 'dependencies',
          ));
          return true;
        }
        if (color[neighbor] == white) {
          if (dfs(neighbor)) return true;
        }
      }

      cyclePath.removeLast();
      color[node] = black;
      return false;
    }

    for (final node in graph.keys) {
      if (color[node] == white) {
        cyclePath = [];
        dfs(node);
      }
    }

    return errors;
  }

  /// Recursively collect widget dependency edges for circular dependency graph.
  static void _collectWidgetDeps(
    WidgetNode widget,
    String parentId,
    Map<String, List<String>> graph,
  ) {
    for (final action in widget.actions.values) {
      if (action.type == ActionType.callSkill && action.target != null) {
        final targetId = 'skill:${action.target}';
        graph[parentId]!.add(targetId);
        graph.putIfAbsent(targetId, () => []);
      }
    }
    for (final child in widget.children) {
      _collectWidgetDeps(child, parentId, graph);
    }
  }
}
