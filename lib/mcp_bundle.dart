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
export 'src/models/test_section.dart';
export 'src/models/profile_section.dart';
export 'src/models/fact_graph_section.dart' hide ValidationRule;
export 'src/models/fact_graph_schema.dart';
export 'src/models/policy.dart';
export 'src/models/integrity.dart' hide HashAlgorithm, ContentHash;

// Types
export 'src/types/period.dart';
export 'src/types/claim.dart';
export 'src/types/confidence.dart';
export 'src/types/context_bundle.dart';
export 'src/types/skill_result.dart';
export 'src/types/appraisal_result.dart';
export 'src/types/decision_guidance.dart';
export 'src/types/expression_style.dart';
export 'src/types/profile_result.dart';
export 'src/types/source_info.dart';

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

// I/O Layer
export 'src/io/bundle_loader.dart';
export 'src/io/loader_options.dart';
export 'src/io/mcp_bundle_loader.dart';
export 'src/io/mcp_bundle_writer.dart';
export 'src/io/exceptions.dart';
export 'src/io/type_coercion.dart';
export 'src/io/bundle_storage_port.dart';
export 'src/io/file_storage_adapter.dart';
export 'src/io/memory_storage_adapter.dart';
export 'src/io/http_storage_adapter.dart';
export 'src/io/bundle_repository.dart';
export 'src/io/bundle_resources.dart';

// Install Lifecycle — see docs/bundle_packaging_and_install.md
export 'src/install/install_policy.dart';
export 'src/install/installed_bundle.dart';
export 'src/install/runtime_descriptor.dart';
export 'src/install/trust_store.dart';
export 'src/install/bundle_signer.dart';
export 'src/install/mcp_bundle_packer.dart';
export 'src/install/mcp_bundle_installer.dart';

// Validator
export 'src/validator/bundle_validator.dart';
export 'src/validator/validation_result.dart';
export 'src/validator/mcp_bundle_validator.dart';

// Utils
export 'src/utils/canonicalization.dart';
export 'src/utils/integrity.dart';

// Ports (Contract Layer) — see REDESIGN-PLAN.md §3 for the catalogue.
// Core capability ports (stable)
export 'src/ports/llm_port.dart';
export 'src/ports/storage_port.dart';
export 'src/ports/metric_port.dart';
export 'src/ports/event_port.dart';
export 'src/ports/channel_port.dart';
export 'src/ports/approval_port.dart';
export 'src/ports/notification_port.dart';
export 'src/ports/ingest_ports.dart';
export 'src/types/knowledge_types.dart' hide AssetNotFoundException;
export 'src/ports/knowledge_ports.dart';

// Phase 1a extracted/unified standard ports
export 'src/ports/mcp_port.dart';
export 'src/ports/evidence_port.dart';
export 'src/ports/expression_port.dart';
export 'src/ports/appraisal_port.dart';
export 'src/ports/decision_port.dart';

// Phase 1b data/knowledge ports
export 'src/ports/facts_port.dart';
export 'src/ports/claims_port.dart';
export 'src/ports/entities_port.dart';
export 'src/ports/candidates_port.dart';
export 'src/ports/patterns_port.dart';
export 'src/ports/summaries_port.dart';
export 'src/ports/runs_port.dart';

// Phase 1b context/retrieval ports
export 'src/ports/context_bundle_port.dart';
export 'src/ports/retrieval_port.dart';
export 'src/ports/asset_port.dart';
export 'src/ports/index_port.dart';

// Phase 1b execution ports
export 'src/ports/skill_runtime_port.dart';
export 'src/ports/skill_registry_port.dart';

// Phase 1b evaluation ports
export 'src/ports/metrics_port.dart';
export 'src/ports/profile_summaries_port.dart';

// Phase 1b philosophy ports
export 'src/ports/ethos_store_port.dart';

// Phase 1b ops ports
export 'src/ports/workflow_port.dart';
export 'src/ports/pipeline_port.dart';
export 'src/ports/schedule_trigger_port.dart';
export 'src/ports/audit_port.dart';
export 'src/ports/runbook_port.dart';

// IO Ports
export 'src/ports/io_device_port.dart';
export 'src/ports/io_policy_port.dart' hide PolicyRule, PolicyCondition;
export 'src/ports/io_registry_port.dart';
export 'src/ports/io_audit_port.dart';
export 'src/ports/io_stream_port.dart';

// Form Ports
export 'src/ports/form_port.dart';
export 'src/ports/form_renderer_port.dart';
export 'src/ports/form_template_port.dart';

// Analysis Ports
export 'src/ports/analysis_port.dart';
export 'src/ports/analysis_datasource_port.dart';
export 'src/ports/analysis_function_port.dart';

// Philosophy Port
export 'src/ports/philosophy_port.dart';

// UI Port
export 'src/ports/ui_port.dart';

// Flow Port
export 'src/ports/flow_port.dart';
