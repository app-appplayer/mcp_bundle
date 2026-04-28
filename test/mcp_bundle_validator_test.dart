import 'package:test/test.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() {
  group('McpValidationCodes', () {
    test('has all expected schema error codes', () {
      expect(McpValidationCodes.missingRequired, equals('MISSING_REQUIRED'));
      expect(McpValidationCodes.invalidType, equals('INVALID_TYPE'));
      expect(McpValidationCodes.invalidPattern, equals('INVALID_PATTERN'));
      expect(McpValidationCodes.invalidValue, equals('INVALID_VALUE'));
    });

    test('has all expected reference error codes', () {
      expect(McpValidationCodes.unknownReference, equals('UNKNOWN_REFERENCE'));
      expect(McpValidationCodes.circularReference, equals('CIRCULAR_REFERENCE'));
      expect(McpValidationCodes.duplicateId, equals('DUPLICATE_ID'));
    });

    test('has all expected integrity error codes', () {
      expect(McpValidationCodes.hashMismatch, equals('HASH_MISMATCH'));
      expect(McpValidationCodes.signatureInvalid, equals('SIGNATURE_INVALID'));
      expect(McpValidationCodes.signatureExpired, equals('SIGNATURE_EXPIRED'));
    });
  });

  group('McpBundleValidator', () {
    group('validate', () {
      test('validates valid bundle successfully', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
        );

        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('returns error for empty bundle ID', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: '',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
        );

        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.code == McpValidationCodes.missingRequired), isTrue);
      });

      test('returns error for empty bundle name', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'test.bundle',
            name: '',
            version: '1.0.0',
          ),
        );

        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.location == 'manifest.name'), isTrue);
      });

      test('returns error for empty version', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '',
          ),
        );

        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.location == 'manifest.version'), isTrue);
      });

      test('returns error for invalid version format', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: 'invalid',
          ),
        );

        final result = McpBundleValidator.validate(bundle);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.code == McpValidationCodes.invalidPattern), isTrue);
      });

      test('accepts valid semver formats', () {
        final versions = ['1.0.0', '1.0.0-alpha', '1.0.0-alpha.1', '1.0.0+build'];
        for (final version in versions) {
          final bundle = McpBundle(
            manifest: BundleManifest(
              id: 'test.bundle',
              name: 'Test Bundle',
              version: version,
            ),
          );

          final result = McpBundleValidator.validate(bundle);
          expect(result.errors.where((e) => e.location == 'manifest.version'), isEmpty,
              reason: 'Version $version should be valid');
        }
      });

      test('warns for non-standard bundle ID pattern', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'TestBundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
        );

        final result = McpBundleValidator.validate(bundle);
        // Non-standard ID pattern is an error, not a warning
        expect(result.errors.any((e) => e.code == McpValidationCodes.invalidPattern), isTrue);
      });
    });

    group('validateSchema', () {
      test('validates UI section', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          ui: UiSection(
            pages: [
              PageDefinition(
                id: 'home',
                name: 'Home',
                root: WidgetNode(type: 'container'),
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isTrue);
      });

      test('returns error for empty page ID', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          ui: UiSection(
            pages: [
              PageDefinition(
                id: '',
                name: 'Home',
                root: WidgetNode(type: 'container'),
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) => e.location?.contains('ui.pages') == true),
          isTrue,
        );
      });

      test('returns error for invalid screen ID format', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          ui: UiSection(
            pages: [
              PageDefinition(
                id: '123invalid',
                name: 'Home',
                root: WidgetNode(type: 'container'),
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.code == McpValidationCodes.invalidPattern), isTrue);
      });

      test('returns error for duplicate screen IDs', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          ui: UiSection(
            pages: [
              PageDefinition(
                id: 'home',
                name: 'Home 1',
                root: WidgetNode(type: 'container'),
              ),
              PageDefinition(
                id: 'home',
                name: 'Home 2',
                root: WidgetNode(type: 'container'),
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.code == McpValidationCodes.duplicateId), isTrue);
      });

      test('returns error for empty widget type', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          ui: UiSection(
            pages: [
              PageDefinition(
                id: 'home',
                name: 'Home',
                root: WidgetNode(type: ''),
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.location?.contains('root.type') == true), isTrue);
      });

      test('validates nested widget children', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          ui: UiSection(
            pages: [
              PageDefinition(
                id: 'home',
                name: 'Home',
                root: WidgetNode(
                  type: 'container',
                  children: [
                    WidgetNode(type: ''),
                  ],
                ),
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
      });

      test('validates action requires target for callSkill', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          ui: UiSection(
            pages: [
              PageDefinition(
                id: 'home',
                name: 'Home',
                root: WidgetNode(
                  type: 'button',
                  actions: {
                    'onPressed': const ActionDef(type: ActionType.callSkill),
                  },
                ),
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.location?.contains('target') == true), isTrue);
      });

      test('validates action requires target for navigate', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          ui: UiSection(
            pages: [
              PageDefinition(
                id: 'home',
                name: 'Home',
                root: WidgetNode(
                  type: 'button',
                  actions: {
                    'onPressed': const ActionDef(type: ActionType.navigate),
                  },
                ),
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
      });

      test('validates skills section', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          skills: SkillSection(
            modules: [
              SkillModule(
                id: 'greeting',
                name: 'Greeting Skill',
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isTrue);
      });

      test('returns error for empty skill module ID', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          skills: SkillSection(
            modules: [
              SkillModule(
                id: '',
                name: 'Greeting Skill',
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
      });

      test('returns error for empty skill module name', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          skills: SkillSection(
            modules: [
              SkillModule(
                id: 'greeting',
                name: '',
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
      });

      test('returns error for duplicate skill module IDs', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          skills: SkillSection(
            modules: [
              SkillModule(id: 'greeting', name: 'Greeting 1'),
              SkillModule(id: 'greeting', name: 'Greeting 2'),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.code == McpValidationCodes.duplicateId), isTrue);
      });

      test('validates procedures within skills', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          skills: SkillSection(
            modules: [
              SkillModule(
                id: 'greeting',
                name: 'Greeting Skill',
                procedures: [
                  SkillProcedure(id: '', name: 'Greet', steps: const []),
                ],
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.location?.contains('procedures') == true), isTrue);
      });

      test('returns error for duplicate procedure IDs within skill', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          skills: SkillSection(
            modules: [
              SkillModule(
                id: 'greeting',
                name: 'Greeting Skill',
                procedures: [
                  SkillProcedure(id: 'greet', name: 'Greet 1', steps: const []),
                  SkillProcedure(id: 'greet', name: 'Greet 2', steps: const []),
                ],
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.code == McpValidationCodes.duplicateId), isTrue);
      });

      test('validates assets section', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          assets: AssetSection(
            assets: [
              Asset(
                path: 'images/logo.png',
                type: AssetType.image,
                content: 'base64data',
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isTrue);
      });

      test('returns error for empty asset path', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          assets: AssetSection(
            assets: [
              Asset(
                path: '',
                type: AssetType.image,
                content: 'base64data',
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
      });

      test('returns error for duplicate asset paths', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          assets: AssetSection(
            assets: [
              Asset(path: 'images/logo.png', type: AssetType.image, content: 'data1'),
              Asset(path: 'images/logo.png', type: AssetType.image, content: 'data2'),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.code == McpValidationCodes.duplicateId), isTrue);
      });

      test('returns error for asset without content or contentRef', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          assets: AssetSection(
            assets: [
              Asset(
                path: 'images/logo.png',
                type: AssetType.image,
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateSchema(bundle);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.message.contains('content')), isTrue);
      });
    });

    group('validateReferences', () {
      test('validates valid skill reference from UI', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          skills: SkillSection(
            modules: [
              SkillModule(id: 'greeting', name: 'Greeting'),
            ],
          ),
          ui: UiSection(
            pages: [
              PageDefinition(
                id: 'home',
                name: 'Home',
                root: WidgetNode(
                  type: 'button',
                  actions: {
                    'onPressed': const ActionDef(
                      type: ActionType.callSkill,
                      target: 'greeting',
                    ),
                  },
                ),
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateReferences(bundle);
        expect(result.isValid, isTrue);
      });

      test('returns error for unknown skill reference', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          skills: SkillSection(
            modules: [
              SkillModule(id: 'greeting', name: 'Greeting'),
            ],
          ),
          ui: UiSection(
            pages: [
              PageDefinition(
                id: 'home',
                name: 'Home',
                root: WidgetNode(
                  type: 'button',
                  actions: {
                    'onPressed': const ActionDef(
                      type: ActionType.callSkill,
                      target: 'nonexistent',
                    ),
                  },
                ),
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateReferences(bundle);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.code == McpValidationCodes.unknownReference), isTrue);
      });

      test('validates navigation to known screen', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          ui: UiSection(
            pages: [
              PageDefinition(
                id: 'home',
                name: 'Home',
                root: WidgetNode(
                  type: 'button',
                  actions: {
                    'onPressed': ActionDef(
                      type: ActionType.navigate,
                      target: 'settings',
                    ),
                  },
                ),
              ),
              PageDefinition(
                id: 'settings',
                name: 'Settings',
                root: WidgetNode(type: 'container'),
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateReferences(bundle);
        expect(result.isValid, isTrue);
      });

      test('warns for unknown navigation target that is not a route', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          ui: UiSection(
            pages: [
              PageDefinition(
                id: 'home',
                name: 'Home',
                root: WidgetNode(
                  type: 'button',
                  actions: {
                    'onPressed': ActionDef(
                      type: ActionType.navigate,
                      target: 'unknownScreen',
                    ),
                  },
                ),
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateReferences(bundle);
        expect(result.warnings.any((w) => w.message.contains('unknownScreen')), isTrue);
      });

      test('accepts route-style navigation targets', () {
        const bundle = McpBundle(
          manifest: BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          ui: UiSection(
            pages: [
              PageDefinition(
                id: 'home',
                name: 'Home',
                root: WidgetNode(
                  type: 'button',
                  actions: {
                    'onPressed': ActionDef(
                      type: ActionType.navigate,
                      target: '/settings/profile',
                    ),
                  },
                ),
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateReferences(bundle);
        expect(result.warnings.where((w) => w.message.contains('/settings')), isEmpty);
      });

      test('validates nested widget references', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          skills: SkillSection(
            modules: [
              SkillModule(id: 'greeting', name: 'Greeting'),
            ],
          ),
          ui: UiSection(
            pages: [
              PageDefinition(
                id: 'home',
                name: 'Home',
                root: WidgetNode(
                  type: 'column',
                  children: [
                    WidgetNode(
                      type: 'button',
                      actions: {
                        'onPressed': const ActionDef(
                          type: ActionType.callSkill,
                          target: 'nonexistent',
                        ),
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateReferences(bundle);
        expect(result.isValid, isFalse);
      });

      test('detects no circular dependencies in valid bundle', () {
        final bundle = McpBundle(
          manifest: const BundleManifest(
            id: 'test.bundle',
            name: 'Test Bundle',
            version: '1.0.0',
          ),
          skills: SkillSection(
            modules: [
              SkillModule(id: 'skill1', name: 'Skill 1'),
              SkillModule(id: 'skill2', name: 'Skill 2'),
            ],
          ),
          ui: const UiSection(
            pages: [
              PageDefinition(
                id: 'screen1',
                name: 'Screen 1',
                root: WidgetNode(type: 'container'),
              ),
              PageDefinition(
                id: 'screen2',
                name: 'Screen 2',
                root: WidgetNode(type: 'container'),
              ),
            ],
          ),
        );

        final result = McpBundleValidator.validateReferences(bundle);
        expect(result.errors.where((e) => e.code == McpValidationCodes.circularReference), isEmpty);
      });
    });
  });
}
