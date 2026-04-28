// Coverage tests for McpBundleValidator - testing all validation paths.
import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:mcp_bundle/src/validator/mcp_bundle_validator.dart';

// Import test_section directly to get StepAction (hidden in barrel)
import 'package:mcp_bundle/src/models/test_section.dart' as test_models;
import 'package:mcp_bundle/src/models/skill_section.dart' as skill_models;

void main() {
  // Helper to create a valid manifest
  BundleManifest validManifest({
    String id = 'test.bundle',
    String name = 'Test Bundle',
    String version = '1.0.0',
  }) {
    return BundleManifest(id: id, name: name, version: version);
  }

  // Helper to create a minimal valid bundle
  McpBundle minimalBundle({BundleManifest? manifest}) {
    return McpBundle(
      manifest: manifest ?? validManifest(),
    );
  }

  group('McpBundleValidator', () {
    // ==================== Manifest Validation ====================
    group('_validateManifest', () {
      test('empty bundle ID produces MISSING_REQUIRED error', () {
        final bundle = minimalBundle(
          manifest: validManifest(id: ''),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        final error = result.errors.firstWhere(
          (e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.location == 'manifest.id',
        );
        expect(error.message, contains('Bundle ID is required'));
      });

      test('invalid ID pattern produces INVALID_PATTERN error', () {
        final bundle = minimalBundle(
          manifest: validManifest(id: 'UPPER_case'),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        final error = result.errors.firstWhere(
          (e) =>
              e.code == McpValidationCodes.invalidPattern &&
              e.location == 'manifest.id',
        );
        expect(error.message, contains('Invalid bundle ID format'));
      });

      test('ID starting with number produces INVALID_PATTERN error', () {
        final bundle = minimalBundle(
          manifest: validManifest(id: '123start'),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidPattern &&
                e.location == 'manifest.id',
          ),
          isTrue,
        );
      });

      test('empty name produces MISSING_REQUIRED error', () {
        final bundle = minimalBundle(
          manifest: validManifest(name: ''),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        final error = result.errors.firstWhere(
          (e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.location == 'manifest.name',
        );
        expect(error.message, contains('Bundle name is required'));
      });

      test('empty version produces MISSING_REQUIRED error', () {
        final bundle = minimalBundle(
          manifest: validManifest(version: ''),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        final error = result.errors.firstWhere(
          (e) =>
              e.code == McpValidationCodes.missingRequired &&
              e.location == 'manifest.version',
        );
        expect(error.message, contains('Bundle version is required'));
      });

      test('invalid version format produces INVALID_PATTERN error', () {
        final bundle = minimalBundle(
          manifest: validManifest(version: 'not-semver'),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        final error = result.errors.firstWhere(
          (e) =>
              e.code == McpValidationCodes.invalidPattern &&
              e.location == 'manifest.version',
        );
        expect(error.message, contains('Invalid version format'));
      });

      test('valid manifest produces no manifest errors', () {
        final bundle = minimalBundle();
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isTrue);
      });
    });

    // ==================== UI Section Validation ====================
    group('_validateUiSection', () {
      test('screen with empty id produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          ui: UiSection(pages: [
            PageDefinition(
              id: '',
              name: 'Home',
              root: const WidgetNode(type: 'Container'),
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'ui.pages[0].id',
          ),
          isTrue,
        );
      });

      test('screen with invalid id pattern produces INVALID_PATTERN', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          ui: UiSection(pages: [
            PageDefinition(
              id: '123-bad',
              name: 'Home',
              root: const WidgetNode(type: 'Container'),
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidPattern &&
                e.location == 'ui.pages[0].id',
          ),
          isTrue,
        );
      });

      test('duplicate screen ids produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          ui: UiSection(pages: [
            PageDefinition(
              id: 'home',
              name: 'Home',
              root: const WidgetNode(type: 'Container'),
            ),
            PageDefinition(
              id: 'home',
              name: 'Home2',
              root: const WidgetNode(type: 'Container'),
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'ui.pages[1].id',
          ),
          isTrue,
        );
      });

      test('widget with empty type produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          ui: UiSection(pages: [
            PageDefinition(
              id: 'home',
              name: 'Home',
              root: const WidgetNode(type: ''),
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'ui.pages[0].root.type',
          ),
          isTrue,
        );
      });

      test('callSkill action with null target produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          ui: UiSection(pages: [
            PageDefinition(
              id: 'home',
              name: 'Home',
              root: WidgetNode(
                type: 'Button',
                actions: {
                  'onTap': const ActionDef(
                    type: ActionType.callSkill,
                    target: null,
                  ),
                },
              ),
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.message.contains('Skill action requires target'),
          ),
          isTrue,
        );
      });

      test('navigate action with null target produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          ui: UiSection(pages: [
            PageDefinition(
              id: 'home',
              name: 'Home',
              root: WidgetNode(
                type: 'Button',
                actions: {
                  'onTap': const ActionDef(
                    type: ActionType.navigate,
                    target: null,
                  ),
                },
              ),
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.message.contains('Navigate action requires target'),
          ),
          isTrue,
        );
      });

      test('validates children widgets recursively', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          ui: UiSection(pages: [
            PageDefinition(
              id: 'home',
              name: 'Home',
              root: WidgetNode(
                type: 'Column',
                children: [
                  const WidgetNode(type: ''),
                ],
              ),
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'ui.pages[0].root.children[0].type',
          ),
          isTrue,
        );
      });
    });

    // ==================== Skill Section Validation ====================
    group('_validateSkillSection', () {
      test('module with empty id produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          skills: const SkillSection(modules: [
            SkillModule(id: '', name: 'Test Skill'),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'skills.modules[0].id',
          ),
          isTrue,
        );
      });

      test('module with empty name produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          skills: const SkillSection(modules: [
            SkillModule(id: 'skill_one', name: ''),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'skills.modules[0].name',
          ),
          isTrue,
        );
      });

      test('duplicate module ids produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          skills: const SkillSection(modules: [
            SkillModule(id: 'skill_one', name: 'Skill One'),
            SkillModule(id: 'skill_one', name: 'Skill One Dup'),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'skills.modules[1].id',
          ),
          isTrue,
        );
      });

      test('procedure with empty id produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          skills: SkillSection(modules: [
            SkillModule(
              id: 'skill_one',
              name: 'Skill One',
              procedures: [
                skill_models.SkillProcedure(
                  id: '',
                  name: 'Proc',
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'skills.modules[0].procedures[0].id',
          ),
          isTrue,
        );
      });

      test('duplicate procedure ids produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          skills: SkillSection(modules: [
            SkillModule(
              id: 'skill_one',
              name: 'Skill One',
              procedures: [
                skill_models.SkillProcedure(id: 'proc_a', name: 'Proc A'),
                skill_models.SkillProcedure(id: 'proc_a', name: 'Proc A Dup'),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'skills.modules[0].procedures[1].id',
          ),
          isTrue,
        );
      });
    });

    // ==================== Asset Section Validation ====================
    group('_validateAssetSection', () {
      test('asset with empty path produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          assets: const AssetSection(assets: [
            Asset(path: '', type: AssetType.file, content: 'data'),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'assets.assets[0].path',
          ),
          isTrue,
        );
      });

      test('duplicate asset paths produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          assets: const AssetSection(assets: [
            Asset(path: 'images/logo.png', type: AssetType.image, content: 'a'),
            Asset(path: 'images/logo.png', type: AssetType.image, content: 'b'),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'assets.assets[1].path',
          ),
          isTrue,
        );
      });

      test('asset with no content and no contentRef produces MISSING_REQUIRED',
          () {
        final bundle = McpBundle(
          manifest: validManifest(),
          assets: const AssetSection(assets: [
            Asset(path: 'images/logo.png', type: AssetType.image),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.message.contains('Asset must have content or contentRef'),
          ),
          isTrue,
        );
      });
    });

    // ==================== Policy Section Validation ====================
    group('_validatePolicySection', () {
      test('policy with empty id produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          policies: PolicySection(policies: [
            Policy(
              id: '',
              name: 'Test Policy',
              rules: [
                PolicyRule(
                  id: 'rule1',
                  condition: const AlwaysCondition(),
                  action: PolicyAction.allow,
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'policies.policies[0].id',
          ),
          isTrue,
        );
      });

      test('duplicate policy ids produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          policies: PolicySection(policies: [
            Policy(
              id: 'pol1',
              name: 'Policy One',
              rules: [
                PolicyRule(
                  id: 'r1',
                  condition: const AlwaysCondition(),
                  action: PolicyAction.allow,
                ),
              ],
            ),
            Policy(
              id: 'pol1',
              name: 'Policy One Dup',
              rules: [
                PolicyRule(
                  id: 'r2',
                  condition: const AlwaysCondition(),
                  action: PolicyAction.allow,
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'policies.policies[1].id',
          ),
          isTrue,
        );
      });

      test('policy with empty name produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          policies: PolicySection(policies: [
            Policy(
              id: 'pol1',
              name: '',
              rules: [
                PolicyRule(
                  id: 'r1',
                  condition: const AlwaysCondition(),
                  action: PolicyAction.allow,
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'policies.policies[0].name',
          ),
          isTrue,
        );
      });

      test('policy with no rules produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          policies: const PolicySection(policies: [
            Policy(id: 'pol1', name: 'Policy One', rules: []),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'policies.policies[0].rules',
          ),
          isTrue,
        );
      });

      test('rule with empty id produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          policies: PolicySection(policies: [
            Policy(
              id: 'pol1',
              name: 'Policy One',
              rules: [
                PolicyRule(
                  id: '',
                  condition: const AlwaysCondition(),
                  action: PolicyAction.allow,
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'policies.policies[0].rules[0].id',
          ),
          isTrue,
        );
      });

      test('duplicate rule ids within policy produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          policies: PolicySection(policies: [
            Policy(
              id: 'pol1',
              name: 'Policy One',
              rules: [
                PolicyRule(
                  id: 'r1',
                  condition: const AlwaysCondition(),
                  action: PolicyAction.allow,
                ),
                PolicyRule(
                  id: 'r1',
                  condition: const AlwaysCondition(),
                  action: PolicyAction.deny,
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'policies.policies[0].rules[1].id',
          ),
          isTrue,
        );
      });

      test('priority out of range (negative) produces INVALID_VALUE', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          policies: PolicySection(policies: [
            Policy(
              id: 'pol1',
              name: 'Policy One',
              priority: -1,
              rules: [
                PolicyRule(
                  id: 'r1',
                  condition: const AlwaysCondition(),
                  action: PolicyAction.allow,
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                e.location == 'policies.policies[0].priority',
          ),
          isTrue,
        );
      });

      test('priority out of range (over 100) produces INVALID_VALUE', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          policies: PolicySection(policies: [
            Policy(
              id: 'pol1',
              name: 'Policy One',
              priority: 101,
              rules: [
                PolicyRule(
                  id: 'r1',
                  condition: const AlwaysCondition(),
                  action: PolicyAction.allow,
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                e.message.contains('priority must be between 0 and 100'),
          ),
          isTrue,
        );
      });

      test('ThresholdCondition with empty metric produces MISSING_REQUIRED',
          () {
        final bundle = McpBundle(
          manifest: validManifest(),
          policies: PolicySection(policies: [
            Policy(
              id: 'pol1',
              name: 'Policy One',
              rules: [
                PolicyRule(
                  id: 'r1',
                  condition: const ThresholdCondition(
                    metric: '',
                    operator: ThresholdOperator.gte,
                    value: 0.5,
                  ),
                  action: PolicyAction.allow,
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.message.contains('Threshold condition requires metric'),
          ),
          isTrue,
        );
      });

      test(
          'ThresholdCondition with between operator and non-list value '
          'produces INVALID_VALUE', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          policies: PolicySection(policies: [
            Policy(
              id: 'pol1',
              name: 'Policy One',
              rules: [
                PolicyRule(
                  id: 'r1',
                  condition: const ThresholdCondition(
                    metric: 'score',
                    operator: ThresholdOperator.between,
                    value: 0.5,
                  ),
                  action: PolicyAction.allow,
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                e.message.contains('Between operator requires [min, max]'),
          ),
          isTrue,
        );
      });

      test('CompositeCondition with empty conditions produces MISSING_REQUIRED',
          () {
        final bundle = McpBundle(
          manifest: validManifest(),
          policies: PolicySection(policies: [
            Policy(
              id: 'pol1',
              name: 'Policy One',
              rules: [
                PolicyRule(
                  id: 'r1',
                  condition: const CompositeCondition(
                    operator: CompositeOperator.and,
                    conditions: [],
                  ),
                  action: PolicyAction.allow,
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.message.contains('Composite condition requires'),
          ),
          isTrue,
        );
      });

      test('ExpressionCondition with empty expression produces MISSING_REQUIRED',
          () {
        final bundle = McpBundle(
          manifest: validManifest(),
          policies: PolicySection(policies: [
            Policy(
              id: 'pol1',
              name: 'Policy One',
              rules: [
                PolicyRule(
                  id: 'r1',
                  condition: const ExpressionCondition(expression: ''),
                  action: PolicyAction.allow,
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.message.contains('Expression condition requires expression'),
          ),
          isTrue,
        );
      });

      test('MetricCondition with empty metric produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          policies: PolicySection(policies: [
            Policy(
              id: 'pol1',
              name: 'Policy One',
              rules: [
                PolicyRule(
                  id: 'r1',
                  condition: const MetricCondition(metric: ''),
                  action: PolicyAction.allow,
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.message.contains('Metric condition requires metric'),
          ),
          isTrue,
        );
      });

      test('AlwaysCondition produces no condition errors', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          policies: PolicySection(policies: [
            Policy(
              id: 'pol1',
              name: 'Policy One',
              rules: [
                PolicyRule(
                  id: 'r1',
                  condition: const AlwaysCondition(),
                  action: PolicyAction.allow,
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isTrue);
      });

      test('CompositeCondition recursively validates child conditions', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          policies: PolicySection(policies: [
            Policy(
              id: 'pol1',
              name: 'Policy One',
              rules: [
                PolicyRule(
                  id: 'r1',
                  condition: const CompositeCondition(
                    operator: CompositeOperator.and,
                    conditions: [
                      ThresholdCondition(
                        metric: '',
                        operator: ThresholdOperator.gte,
                        value: 0.5,
                      ),
                    ],
                  ),
                  action: PolicyAction.allow,
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.message.contains('Threshold condition requires metric'),
          ),
          isTrue,
        );
      });
    });

    // ==================== FactGraphSchema Validation ====================
    group('_validateFactGraphSchemaSection', () {
      test('entity type with empty name produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          factGraphSchema: const FactGraphSchema(entityTypes: [
            EntityTypeDefinition(name: ''),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'factGraphSchema.entityTypes[0].name',
          ),
          isTrue,
        );
      });

      test('duplicate entity type names produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          factGraphSchema: const FactGraphSchema(entityTypes: [
            EntityTypeDefinition(name: 'Person'),
            EntityTypeDefinition(name: 'Person'),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'factGraphSchema.entityTypes[1].name',
          ),
          isTrue,
        );
      });

      test('property with empty name produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          factGraphSchema: const FactGraphSchema(entityTypes: [
            EntityTypeDefinition(
              name: 'Person',
              properties: [
                PropertyDefinition(name: '', type: 'string'),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location ==
                    'factGraphSchema.entityTypes[0].properties[0].name',
          ),
          isTrue,
        );
      });

      test('duplicate property names produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          factGraphSchema: const FactGraphSchema(entityTypes: [
            EntityTypeDefinition(
              name: 'Person',
              properties: [
                PropertyDefinition(name: 'age', type: 'number'),
                PropertyDefinition(name: 'age', type: 'number'),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location ==
                    'factGraphSchema.entityTypes[0].properties[1].name',
          ),
          isTrue,
        );
      });

      test('invalid property type produces INVALID_VALUE', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          factGraphSchema: const FactGraphSchema(entityTypes: [
            EntityTypeDefinition(
              name: 'Person',
              properties: [
                PropertyDefinition(name: 'data', type: 'foobar'),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                e.message.contains('Invalid property type'),
          ),
          isTrue,
        );
      });

      test(
          'required property not found in properties produces '
          'UNKNOWN_REFERENCE', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          factGraphSchema: const FactGraphSchema(entityTypes: [
            EntityTypeDefinition(
              name: 'Person',
              properties: [
                PropertyDefinition(name: 'age', type: 'number'),
              ],
              requiredProperties: ['name'],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.unknownReference &&
                e.message.contains('Required property not found: name'),
          ),
          isTrue,
        );
      });

      test('relation type with empty name produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          factGraphSchema: const FactGraphSchema(
            entityTypes: [EntityTypeDefinition(name: 'Person')],
            relationTypes: [
              RelationTypeDefinition(
                name: '',
                fromEntityType: 'Person',
                toEntityType: 'Person',
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'factGraphSchema.relationTypes[0].name',
          ),
          isTrue,
        );
      });

      test('duplicate relation type names produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          factGraphSchema: const FactGraphSchema(
            entityTypes: [EntityTypeDefinition(name: 'Person')],
            relationTypes: [
              RelationTypeDefinition(
                name: 'worksFor',
                fromEntityType: 'Person',
                toEntityType: 'Person',
              ),
              RelationTypeDefinition(
                name: 'worksFor',
                fromEntityType: 'Person',
                toEntityType: 'Person',
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'factGraphSchema.relationTypes[1].name',
          ),
          isTrue,
        );
      });

      test('relation with unknown fromEntityType produces UNKNOWN_REFERENCE',
          () {
        final bundle = McpBundle(
          manifest: validManifest(),
          factGraphSchema: const FactGraphSchema(
            entityTypes: [EntityTypeDefinition(name: 'Person')],
            relationTypes: [
              RelationTypeDefinition(
                name: 'worksFor',
                fromEntityType: 'Unknown',
                toEntityType: 'Person',
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.unknownReference &&
                e.message.contains('Unknown source entity type'),
          ),
          isTrue,
        );
      });

      test('relation with unknown toEntityType produces UNKNOWN_REFERENCE', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          factGraphSchema: const FactGraphSchema(
            entityTypes: [EntityTypeDefinition(name: 'Person')],
            relationTypes: [
              RelationTypeDefinition(
                name: 'worksFor',
                fromEntityType: 'Person',
                toEntityType: 'Unknown',
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.unknownReference &&
                e.message.contains('Unknown target entity type'),
          ),
          isTrue,
        );
      });

      test('fact type with empty name produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          factGraphSchema: const FactGraphSchema(factTypes: [
            FactTypeDefinition(name: '', valueType: 'string'),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'factGraphSchema.factTypes[0].name',
          ),
          isTrue,
        );
      });

      test('duplicate fact type names produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          factGraphSchema: const FactGraphSchema(factTypes: [
            FactTypeDefinition(name: 'birthDate', valueType: 'date'),
            FactTypeDefinition(name: 'birthDate', valueType: 'date'),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'factGraphSchema.factTypes[1].name',
          ),
          isTrue,
        );
      });

      test('invalid fact value type produces INVALID_VALUE', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          factGraphSchema: const FactGraphSchema(factTypes: [
            FactTypeDefinition(name: 'customFact', valueType: 'foobar'),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                e.message.contains('Invalid fact value type'),
          ),
          isTrue,
        );
      });
    });

    // ==================== Flow Section Validation ====================
    group('_validateFlowSection', () {
      test('flow with empty id produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          flow: const FlowSection(flows: [
            FlowDefinition(id: '', name: 'Test Flow'),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'flow.flows[0].id',
          ),
          isTrue,
        );
      });

      test('duplicate flow ids produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          flow: const FlowSection(flows: [
            FlowDefinition(id: 'flow1', name: 'Flow One'),
            FlowDefinition(id: 'flow1', name: 'Flow One Dup'),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'flow.flows[1].id',
          ),
          isTrue,
        );
      });

      test('step with empty id produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          flow: const FlowSection(flows: [
            FlowDefinition(
              id: 'flow1',
              name: 'Flow One',
              steps: [
                FlowStep(id: '', type: StepType.action),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'flow.flows[0].steps[0].id',
          ),
          isTrue,
        );
      });

      test('duplicate step ids produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          flow: const FlowSection(flows: [
            FlowDefinition(
              id: 'flow1',
              name: 'Flow One',
              steps: [
                FlowStep(id: 'step1', type: StepType.action),
                FlowStep(id: 'step1', type: StepType.action),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'flow.flows[0].steps[1].id',
          ),
          isTrue,
        );
      });

      test('step next reference to unknown step produces UNKNOWN_REFERENCE',
          () {
        final bundle = McpBundle(
          manifest: validManifest(),
          flow: const FlowSection(flows: [
            FlowDefinition(
              id: 'flow1',
              name: 'Flow One',
              steps: [
                FlowStep(
                  id: 'step1',
                  type: StepType.action,
                  next: ['nonexistent'],
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.unknownReference &&
                e.message.contains('Unknown next step reference: nonexistent'),
          ),
          isTrue,
        );
      });

      test('step onError reference to unknown step produces UNKNOWN_REFERENCE',
          () {
        final bundle = McpBundle(
          manifest: validManifest(),
          flow: const FlowSection(flows: [
            FlowDefinition(
              id: 'flow1',
              name: 'Flow One',
              steps: [
                FlowStep(
                  id: 'step1',
                  type: StepType.action,
                  onError: 'nonexistent',
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.unknownReference &&
                e.message
                    .contains('Unknown onError step reference: nonexistent'),
          ),
          isTrue,
        );
      });
    });

    // ==================== Knowledge Section Validation ====================
    group('_validateKnowledgeSection', () {
      test('source with empty id produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          knowledge: const KnowledgeSection(sources: [
            KnowledgeSource(
              id: '',
              name: 'Test Source',
              type: KnowledgeSourceType.documents,
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'knowledge.sources[0].id',
          ),
          isTrue,
        );
      });

      test('duplicate source ids produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          knowledge: const KnowledgeSection(sources: [
            KnowledgeSource(
              id: 'src1',
              name: 'Source One',
              type: KnowledgeSourceType.documents,
            ),
            KnowledgeSource(
              id: 'src1',
              name: 'Source One Dup',
              type: KnowledgeSourceType.documents,
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'knowledge.sources[1].id',
          ),
          isTrue,
        );
      });

      test('source with empty name produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          knowledge: const KnowledgeSection(sources: [
            KnowledgeSource(
              id: 'src1',
              name: '',
              type: KnowledgeSourceType.documents,
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'knowledge.sources[0].name',
          ),
          isTrue,
        );
      });
    });

    // ==================== Bindings Section Validation ====================
    group('_validateBindingsSection', () {
      test('data source with empty id produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          bindings: const BindingSection(
            sources: [
              DataSource(id: '', name: 'DS', type: DataSourceType.state),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'bindings.sources[0].id',
          ),
          isTrue,
        );
      });

      test('duplicate data source ids produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          bindings: const BindingSection(
            sources: [
              DataSource(id: 'ds1', name: 'DS1', type: DataSourceType.state),
              DataSource(id: 'ds1', name: 'DS1 Dup', type: DataSourceType.api),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'bindings.sources[1].id',
          ),
          isTrue,
        );
      });

      test('binding with empty id produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          bindings: const BindingSection(
            bindings: [
              DataBinding(id: '', source: 'src', target: 'tgt'),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'bindings.bindings[0].id',
          ),
          isTrue,
        );
      });

      test('duplicate binding ids produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          bindings: const BindingSection(
            bindings: [
              DataBinding(id: 'b1', source: 'src', target: 'tgt'),
              DataBinding(id: 'b1', source: 'src2', target: 'tgt2'),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'bindings.bindings[1].id',
          ),
          isTrue,
        );
      });

      test('binding with empty source produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          bindings: const BindingSection(
            bindings: [
              DataBinding(id: 'b1', source: '', target: 'tgt'),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.message.contains('Binding source is required'),
          ),
          isTrue,
        );
      });

      test('binding with empty target produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          bindings: const BindingSection(
            bindings: [
              DataBinding(id: 'b1', source: 'src', target: ''),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.message.contains('Binding target is required'),
          ),
          isTrue,
        );
      });
    });

    // ==================== Profiles Section Validation ====================
    group('_validateProfilesSection', () {
      test('profile with empty id produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          profiles: const ProfilesSection(profiles: [
            ProfileDefinition(id: '', name: 'Test Profile'),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'profiles.profiles[0].id',
          ),
          isTrue,
        );
      });

      test('duplicate profile ids produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          profiles: const ProfilesSection(profiles: [
            ProfileDefinition(id: 'prof1', name: 'Profile One'),
            ProfileDefinition(id: 'prof1', name: 'Profile One Dup'),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'profiles.profiles[1].id',
          ),
          isTrue,
        );
      });

      test('profile with empty name produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          profiles: const ProfilesSection(profiles: [
            ProfileDefinition(id: 'prof1', name: ''),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'profiles.profiles[0].name',
          ),
          isTrue,
        );
      });
    });

    // ==================== Test Section Validation ====================
    group('_validateTestSection', () {
      test('suite with empty id produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          tests: test_models.TestSection(suites: [
            test_models.TestSuite(id: '', name: 'Test Suite'),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'tests.suites[0].id',
          ),
          isTrue,
        );
      });

      test('duplicate suite ids produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          tests: test_models.TestSection(suites: [
            test_models.TestSuite(id: 'suite1', name: 'Suite One'),
            test_models.TestSuite(id: 'suite1', name: 'Suite One Dup'),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'tests.suites[1].id',
          ),
          isTrue,
        );
      });

      test('test case with empty id produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          tests: test_models.TestSection(suites: [
            test_models.TestSuite(
              id: 'suite1',
              name: 'Suite One',
              tests: [
                test_models.TestCase(id: '', name: 'Test Case'),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'tests.suites[0].tests[0].id',
          ),
          isTrue,
        );
      });

      test('duplicate test case ids within suite produces DUPLICATE_ID', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          tests: test_models.TestSection(suites: [
            test_models.TestSuite(
              id: 'suite1',
              name: 'Suite One',
              tests: [
                test_models.TestCase(id: 'tc1', name: 'Test One'),
                test_models.TestCase(id: 'tc1', name: 'Test One Dup'),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.duplicateId &&
                e.location == 'tests.suites[0].tests[1].id',
          ),
          isTrue,
        );
      });
    });

    // ==================== Expression Syntax Validation ====================
    group('_validateExpressionSyntax', () {
      test('valid expression in flow trigger condition produces no errors', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          flow: FlowSection(flows: [
            FlowDefinition(
              id: 'flow1',
              name: 'Flow One',
              trigger: const FlowTrigger(
                type: TriggerType.manual,
                condition: '1 + 2',
              ),
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        // Should not have expression syntax errors
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                e.location == 'flow.flows[0].trigger.condition',
          ),
          isFalse,
        );
      });

      test(
          'invalid expression in flow trigger condition produces INVALID_VALUE',
          () {
        final bundle = McpBundle(
          manifest: validManifest(),
          flow: FlowSection(flows: [
            FlowDefinition(
              id: 'flow1',
              name: 'Flow One',
              trigger: const FlowTrigger(
                type: TriggerType.manual,
                condition: '{{bad}}',
              ),
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                e.location == 'flow.flows[0].trigger.condition',
          ),
          isTrue,
        );
      });
    });

    // ==================== Expression Validation Across Sections ====================
    group('_validateExpressions', () {
      test('validates flow output expression', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          flow: FlowSection(flows: [
            FlowDefinition(
              id: 'flow1',
              name: 'Flow One',
              output: const FlowOutput(
                type: 'string',
                expression: '{{bad}}',
              ),
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                e.location == 'flow.flows[0].output.expression',
          ),
          isTrue,
        );
      });

      test('validates flow step condition', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          flow: const FlowSection(flows: [
            FlowDefinition(
              id: 'flow1',
              name: 'Flow One',
              steps: [
                FlowStep(
                  id: 'step1',
                  type: StepType.action,
                  condition: '{{bad}}',
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                e.location == 'flow.flows[0].steps[0].condition',
          ),
          isTrue,
        );
      });

      test('validates binding transform', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          bindings: const BindingSection(
            bindings: [
              DataBinding(
                id: 'b1',
                source: 'src',
                target: 'tgt',
                transform: '{{bad}}',
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                e.location == 'bindings.bindings[0].transform',
          ),
          isTrue,
        );
      });

      test('validates binding condition', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          bindings: const BindingSection(
            bindings: [
              DataBinding(
                id: 'b1',
                source: 'src',
                target: 'tgt',
                condition: '{{bad}}',
              ),
            ],
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                e.location == 'bindings.bindings[0].condition',
          ),
          isTrue,
        );
      });

      test('validates computed binding expression', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          bindings: BindingSection(
            computed: {
              'total': const ComputedValue(expression: '{{bad}}'),
            },
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                e.location == 'bindings.computed[total].expression',
          ),
          isTrue,
        );
      });

      test('validates profile section condition', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          profiles: const ProfilesSection(profiles: [
            ProfileDefinition(
              id: 'prof1',
              name: 'Profile One',
              sections: [
                ProfileContentSection(
                  name: 'intro',
                  content: 'Hello',
                  condition: '{{bad}}',
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                e.location ==
                    'profiles.profiles[0].sections[0].condition',
          ),
          isTrue,
        );
      });

      test('validates skill procedure step condition', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          skills: SkillSection(modules: [
            SkillModule(
              id: 'skill_one',
              name: 'Skill One',
              procedures: [
                skill_models.SkillProcedure(
                  id: 'proc1',
                  name: 'Proc',
                  steps: [
                    skill_models.ProcedureStep(
                      id: 'step1',
                      action: const skill_models.StepAction(
                        type: skill_models.StepActionType.prompt,
                      ),
                      condition: '{{bad}}',
                    ),
                  ],
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                e.location ==
                    'skills.modules[0].procedures[0].steps[0].condition',
          ),
          isTrue,
        );
      });

      test('validates test fixture factory expression', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          tests: test_models.TestSection(
            fixtures: {
              'myFixture':
                  test_models.TestFixture(name: 'fixture', factory: '{{bad}}'),
            },
          ),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                e.location == 'tests.fixtures[myFixture].factory',
          ),
          isTrue,
        );
      });

      test('valid expressions produce no expression errors', () {
        final bundle = McpBundle(
          manifest: validManifest(),
          flow: FlowSection(flows: [
            FlowDefinition(
              id: 'flow1',
              name: 'Flow One',
              trigger: const FlowTrigger(
                type: TriggerType.manual,
                condition: '1 + 2',
              ),
              output: const FlowOutput(
                type: 'string',
                expression: 'true',
              ),
              steps: const [
                FlowStep(
                  id: 'step1',
                  type: StepType.action,
                  condition: '1 > 0',
                ),
              ],
            ),
          ]),
          bindings: BindingSection(
            bindings: const [
              DataBinding(
                id: 'b1',
                source: 'src',
                target: 'tgt',
                transform: '1 + 1',
                condition: 'true',
              ),
            ],
            computed: {
              'total': const ComputedValue(expression: '1 + 2'),
            },
          ),
          profiles: const ProfilesSection(profiles: [
            ProfileDefinition(
              id: 'prof1',
              name: 'Profile One',
              sections: [
                ProfileContentSection(
                  name: 'intro',
                  content: 'Hello',
                  condition: 'true',
                ),
              ],
            ),
          ]),
          skills: SkillSection(modules: [
            SkillModule(
              id: 'skill_one',
              name: 'Skill One',
              procedures: [
                skill_models.SkillProcedure(
                  id: 'proc1',
                  name: 'Proc',
                  steps: [
                    skill_models.ProcedureStep(
                      id: 'step1',
                      action: const skill_models.StepAction(
                        type: skill_models.StepActionType.prompt,
                      ),
                      condition: 'true',
                    ),
                  ],
                ),
              ],
            ),
          ]),
        );
        final result = McpBundleValidator.validate(bundle);
        // Should have no expression-related INVALID_VALUE errors
        expect(
          result.errors.where(
            (e) =>
                e.code == McpValidationCodes.invalidValue &&
                (e.message.contains('Expression syntax error') ||
                    e.message.contains('Expression lexer error')),
          ),
          isEmpty,
        );
      });
    });

    // ==================== validateSchema / validateReferences / validateIntegrity ====================
    group('public API methods', () {
      test('validateSchema returns result for schema only', () {
        final bundle = minimalBundle(manifest: validManifest(id: 'UPPER'));
        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) => e.code == McpValidationCodes.invalidPattern,
          ),
          isTrue,
        );
      });

      test('validateReferences returns result', () {
        final bundle = minimalBundle();
        final result = McpBundleValidator.validateReferences(bundle);
        // Minimal valid bundle should pass reference check
        expect(result, isNotNull);
      });

      test('validateIntegrity with no integrity returns valid', () {
        final bundle = minimalBundle();
        final result = McpBundleValidator.validateIntegrity(bundle);
        expect(result.isValid, isTrue);
      });
    });

    // ==================== schemaVersion validation ====================
    group('schemaVersion validation', () {
      test('empty schemaVersion produces MISSING_REQUIRED', () {
        final bundle = McpBundle(
          schemaVersion: '',
          manifest: validManifest(),
        );
        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.code == McpValidationCodes.missingRequired &&
                e.location == 'schemaVersion',
          ),
          isTrue,
        );
      });
    });
  });
}
