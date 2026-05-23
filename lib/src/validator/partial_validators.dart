/// Pre-insertion partial-entry validation for the 9-category knowledge
/// surface authoring tools mutate. Used by hosts (`studio.builder.*`,
/// `BundleKnowledgeView`, headless mcp authoring clients) BEFORE
/// inserting a new entry into the parent section's list — surfaces
/// shape errors to the LLM / UI as a diagnostic instead of letting
/// invalid JSON land on disk and surface at the next
/// [McpBundleLoader.loadDirectory].
///
/// Each `validate*` method:
/// 1. Runs explicit field checks (presence + non-empty for required
///    identifiers). The `fromJson` factories on these models fall
///    back silently (e.g. `id: json['id'] as String? ?? ''`) so a
///    smoke parse alone would accept entries with empty ids — the
///    explicit pass closes that gap.
/// 2. Runs the matching `XxxEntry.fromJson(entry)` as a smoke parse
///    to catch hard shape errors (wrong type, missing required
///    nested object). Caught exceptions land as a single
///    `'shape: <message>'` issue.
///
/// Returns `null` when the entry is valid; a `List<String>` of issues
/// when invalid (same shape as [McpBundleValidator]'s
/// [ValidationResult.errors] — string-per-error, suitable for direct
/// surface to the caller).
///
/// **Not a replacement** for whole-bundle [McpBundleValidator] — that
/// pass still runs at load time and covers cross-reference integrity
/// (orphan agent → role, dangling skill chain, …) which is impossible
/// to check on a single entry in isolation.
///
/// **Long-term**: when `specs/mcp_bundle/spec/1.0` ships entry-level
/// JSON Schemas, these methods become generated stubs delegating to a
/// shared schema validator. The hand-rolled field lists here will
/// drop. Until then, the rules track the model's `required` ctor
/// fields directly — anything the model class declares `required`
/// MUST be in the field list below.
library;

import '../models/agent_section.dart';
import '../models/facts_section.dart';
import '../models/knowledge.dart';
import '../models/philosophy_section.dart';
import '../models/pipelines_section.dart';
import '../models/profile_section.dart';
import '../models/runbooks_section.dart';
import '../models/skill_section.dart';
import '../models/workflows_section.dart';

/// Facade exposing per-entry partial validation for every
/// knowledge-category section. See library doc for semantics.
class PartialValidators {
  PartialValidators._();

  /// `knowledge.sources[i]`.
  static List<String>? validateKnowledgeSource(Map<String, dynamic> entry) =>
      _runChecks(
        entry,
        requiredFields: const ['id', 'name'],
        smokeParse: () => KnowledgeSource.fromJson(entry),
      );

  /// `knowledge.sources[i].documents[j]` (also `knowledge.documents[i]`).
  ///
  /// A document MUST identify itself either by an explicit `id` or by
  /// the `path` it lives under in the reserved `knowledge/` folder —
  /// the loader keys cross-references off whichever is present.
  static List<String>? validateKnowledgeDocument(
          Map<String, dynamic> entry) =>
      _runChecks(
        entry,
        requiredEitherOr: const [
          ['id', 'path']
        ],
        smokeParse: () => KnowledgeDocument.fromJson(entry),
      );

  /// `agents.agents[i]`.
  static List<String>? validateAgent(Map<String, dynamic> entry) =>
      _runChecks(
        entry,
        requiredFields: const ['id', 'name', 'role'],
        smokeParse: () => AgentDefinition.fromJson(entry),
      );

  /// `facts.facts[i]`.
  static List<String>? validateFact(Map<String, dynamic> entry) => _runChecks(
        entry,
        requiredFields: const ['id'],
        smokeParse: () => Fact.fromJson(entry),
      );

  /// `skills.skills[i]` (canonical) or `.modules[i]` (legacy alias).
  static List<String>? validateSkill(Map<String, dynamic> entry) =>
      _runChecks(
        entry,
        requiredFields: const ['id', 'name'],
        smokeParse: () => SkillModule.fromJson(entry),
      );

  /// `profiles.profiles[i]`.
  static List<String>? validateProfile(Map<String, dynamic> entry) =>
      _runChecks(
        entry,
        requiredFields: const ['id', 'name'],
        smokeParse: () => ProfileDefinition.fromJson(entry),
      );

  /// `philosophy.philosophies[i]`.
  static List<String>? validatePhilosophy(Map<String, dynamic> entry) =>
      _runChecks(
        entry,
        requiredFields: const ['id', 'name'],
        smokeParse: () => Philosophy.fromJson(entry),
      );

  /// `workflows.workflows[i]`.
  static List<String>? validateWorkflow(Map<String, dynamic> entry) =>
      _runChecks(
        entry,
        requiredFields: const ['id', 'name'],
        smokeParse: () => WorkflowEntry.fromJson(entry),
      );

  /// `pipelines.pipelines[i]`.
  static List<String>? validatePipeline(Map<String, dynamic> entry) =>
      _runChecks(
        entry,
        requiredFields: const ['id', 'name'],
        smokeParse: () => PipelineEntry.fromJson(entry),
      );

  /// `runbooks.runbooks[i]`.
  static List<String>? validateRunbook(Map<String, dynamic> entry) =>
      _runChecks(
        entry,
        requiredFields: const ['id', 'name'],
        smokeParse: () => RunbookEntry.fromJson(entry),
      );

  // --- internals ------------------------------------------------------

  static List<String>? _runChecks(
    Map<String, dynamic> entry, {
    List<String> requiredFields = const [],
    List<List<String>> requiredEitherOr = const [],
    required void Function() smokeParse,
  }) {
    final issues = <String>[];

    for (final field in requiredFields) {
      final v = entry[field];
      if (v == null || (v is String && v.isEmpty)) {
        issues.add('required field "$field" is missing or empty');
      }
    }

    for (final group in requiredEitherOr) {
      final any = group.any((f) {
        final v = entry[f];
        return v != null && !(v is String && v.isEmpty);
      });
      if (!any) {
        issues.add(
            'at least one of [${group.join(", ")}] is required and non-empty');
      }
    }

    try {
      smokeParse();
    } catch (e) {
      issues.add('shape: $e');
    }

    return issues.isEmpty ? null : issues;
  }
}
