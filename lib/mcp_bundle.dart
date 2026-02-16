/// MCP Bundle - Schema, models, loader, validator, expression language, and port contracts.
///
/// This package provides tools for working with MCP Bundle data:
/// - Data models for all bundle sections (UI, Flow, Skills, etc.)
/// - Bundle loading and parsing
/// - Schema validation
/// - Expression language for dynamic content
/// - Integrity verification
/// - Port contracts for inter-package communication
library mcp_bundle;

// Models
export 'src/models/bundle.dart';
export 'src/models/manifest.dart';
export 'src/models/ui_section.dart';
export 'src/models/flow_section.dart';
export 'src/models/skill_section.dart';
export 'src/models/asset.dart';
export 'src/models/knowledge.dart';
export 'src/models/binding.dart';
export 'src/models/test_section.dart' hide StepAction;

// Types
export 'src/types/period.dart';
export 'src/types/claim.dart';
export 'src/types/confidence.dart';

// Schema (legacy, for backward compatibility)
export 'src/schema/bundle_schema.dart' hide BundleManifest, BundleDependency;
export 'src/schema/manifest_schema.dart' hide StepType, TriggerType, SkillTrigger;

// Expression Language
export 'src/expression/token.dart';
export 'src/expression/lexer.dart';
export 'src/expression/ast.dart';
export 'src/expression/parser.dart';
export 'src/expression/evaluator.dart';
export 'src/expression/context.dart';
export 'src/expression/functions.dart';

// Loader
export 'src/loader/bundle_loader.dart';
export 'src/loader/loader_options.dart';

// Validator
export 'src/validator/bundle_validator.dart';
export 'src/validator/validation_result.dart';

// Utils
export 'src/utils/canonicalization.dart';
export 'src/utils/integrity.dart';

// Ports (Contract Layer)
export 'src/ports/llm_port.dart';
export 'src/ports/storage_port.dart';
export 'src/ports/metric_port.dart';
export 'src/ports/event_port.dart';
