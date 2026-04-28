/// Port Contracts - Barrel export for all port interfaces.
///
/// This file exports all port contracts defined in mcp_bundle.
/// Import this file to access all ports at once.
///
/// Catalogue layout (REDESIGN-PLAN.md Phase 9 complete):
/// - Capability-named standard ports live in dedicated files.
/// - `knowledge_ports.dart` retains only `CollectionStoragePort`.
library;

// Shared types used by ports
export '../types/claim.dart';
export '../types/period.dart';
export '../types/confidence.dart';
export '../types/context_bundle.dart';
export '../types/knowledge_types.dart';
export '../types/appraisal_result.dart';
export '../types/decision_guidance.dart';
export '../types/expression_style.dart';
export '../types/source_info.dart';

// --- Core capability ports (stable) ---
export 'llm_port.dart';
export 'storage_port.dart';
export 'metric_port.dart';
export 'event_port.dart';
export 'channel_port.dart';
export 'approval_port.dart';
export 'notification_port.dart';
export 'ingest_ports.dart';

// --- Collection storage ---
export 'knowledge_ports.dart';

// --- Phase 1a extracted/new standard ports ---
export 'mcp_port.dart';
export 'evidence_port.dart';
export 'expression_port.dart';
export 'appraisal_port.dart';
export 'decision_port.dart';

// --- Phase 1b data/knowledge ports ---
export 'facts_port.dart';
export 'claims_port.dart';
export 'entities_port.dart';
export 'candidates_port.dart';
export 'patterns_port.dart';
export 'summaries_port.dart';
export 'runs_port.dart';

// --- Phase 1b context/retrieval ports ---
export 'context_bundle_port.dart';
export 'retrieval_port.dart';
export 'asset_port.dart';
export 'index_port.dart';

// --- Phase 1b execution ports ---
export 'skill_runtime_port.dart';
export 'skill_registry_port.dart';

// --- Phase 1b evaluation ports ---
export 'metrics_port.dart';
export 'profile_summaries_port.dart';

// --- Phase 1b philosophy ports ---
export 'ethos_store_port.dart';

// --- Phase 1b ops ports ---
export 'workflow_port.dart';
export 'pipeline_port.dart';
export 'schedule_trigger_port.dart';
export 'audit_port.dart';
export 'runbook_port.dart';

// IO Ports
export 'io_device_port.dart';
export 'io_policy_port.dart';
export 'io_registry_port.dart';
export 'io_audit_port.dart';
export 'io_stream_port.dart';

// Form Ports
export 'form_port.dart';
export 'form_renderer_port.dart';
export 'form_template_port.dart';

// Analysis Ports
export 'analysis_port.dart';
export 'analysis_datasource_port.dart';
export 'analysis_function_port.dart';

// Philosophy Port
export 'philosophy_port.dart';

// UI Port
export 'ui_port.dart';
