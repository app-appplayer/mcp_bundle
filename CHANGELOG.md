## [0.4.1] - 2026-05-30 - Behavior section schema (additive)

### Added
- `BehaviorSection` / `BehaviorDefinition` / `BehaviorStepDef` — new model classes under `lib/src/models/behavior_section.dart`. A behavior definition is an ordered list of declarative steps; each step carries `do` (tool/skill invocation map), `when` (guard expression), `then` (outcome routing map), `dependsOn` (step dependency list), and `onFailure` (failure jump target). The host kernel maps these to its execution engine; this section is the serializable carrier only.
- `McpBundle.behavior` — optional `BehaviorSection?` field wired through `fromJson` / `toJson` / `copyWith` / `hasContent` / `presentSections`. Emitted under the `behavior` key; omitted when null so existing bundles round-trip byte-identical.
- `behavior_section.dart` exported from the main `mcp_bundle` barrel.
- 5 new regression tests (`test/models/behavior_section_test.dart`). Total: 5065 PASS.

### Backward compatibility
- Fully additive. No existing field, section, or model changed. Bundles without a `behavior` key continue to load identically. `^0.4.0` caret consumers resolve `0.4.1` automatically.

---

## [0.4.0] - 2026-05-23 - BREAKING — `UiSection.pages` is now a Map (mcp_ui_dsl 1.3 spec alignment) + 0.3.3 staged changes folded in

### Changed (BREAKING) — `UiSection.pages` = `Map<String, PageDefinition>`
- `UiSection.pages` field type changed from **`List<PageDefinition>`** to **`Map<String, PageDefinition>`** (keyed by id). The mcp_ui_dsl 1.3 `app.schema.json` declares `pages` as `"type": "object"` (id-keyed map); the previous list form was a spec violation. Routes referencing `ui://pages/<id>` resolve against this map.
- `UiSection.fromJson` accepts both map and list inputs leniently — legacy bundles emitting the list form continue to load. List inputs synthesize the map by using `PageDefinition.id` as the key.
- `UiSection.toJson` always emits the spec-aligned map form. **JSON wire format is breaking** — a 0.3.x consumer parsing a 0.4.x emitter's output silently drops the `pages` map (the old lenient `List.cast` returns null on a Map input).
- New factory **`UiSection.fromPagesList(List<PageDefinition>)`** — call site compatibility for callers that build pages into a list variable. Synthesizes the map by `PageDefinition.id` and returns a `UiSection`.

### Migration
- Consumers using `pages.first` / `pages.map((p) => ...)` / `for (page in pages)` must update to `pages.values.first` / `pages.values.map(...)` / `for (page in pages.values)`.
- Constructor sites using `pages: <PageDefinition>[...]` (a list variable) should call `UiSection.fromPagesList(<PageDefinition>[...], ...)` instead.
- New code is recommended to use the literal map form: `pages: {'home': PageDefinition(id: 'home', ...)}`.

### Caret resolution
- A `^0.3.x` constraint does **not** resolve `0.4.0` automatically (pre-1.0 semver — caret only spans within the same minor). Consumers must update to `^0.4.0` explicitly.
- Backward read = supported (`fromJson` accepts the old list form). Forward write = incompatible (a 0.3.x consumer cannot parse the new map JSON).

### Release dependency cascade
After publishing 0.4.0, every direct consumer must update its caret and ship a patch:
- mcp_knowledge / mcp_fact_graph / mcp_skill / mcp_profile / mcp_philosophy / mcp_server / mcp_llm / mcp_client (8 packages).
- flowbrain_core.
- brain_kernel.
- flutter_mcp_ui_core / flutter_mcp_ui_runtime / flutter_mcp_ui_generator.
- appplayer_core.
- Standard / Pro / X / Custom AppPlayer derivatives.

### Internal cascade (workspace path overrides applied; all tests passing)
- `lib/src/io/mcp_bundle_loader.dart` — `for (var page in ui.pages)` → `pages.values`.
- `lib/src/validator/mcp_bundle_validator.dart` — `_validateUiSection` iterates `entries` with error locations rendered as `ui.pages[<key>]`. `_validateReferences` and `_validateIntegrity` cross-section checks use `pages.values`.
- All 5062 tests pass.

### Note on the 0.3.3 staged changes
The 0.3.3 changes listed below were staged but never published. They are folded into this 0.4.0 release: the additive 5 sections, BundleFolder additions, loader Section forward fix, schemaVersion additions, authoring layer, round-trip gaps, and chrome user-zone fields all ship together with the BREAKING `UiSection.pages` change in this single release.

---

## [0.3.3] - 2026-05-13 - Knowledge Section data extension + Authoring layer boost + Round-trip gap fix + Chrome user-zone fields



### Added — WiringSection chrome user-zone (2026-05-20, additive)
- `WiringSection.titlebar` + `WiringSection.statusbar` — two optional single-string payloads rendered in the host chrome's titlebar / statusbar user-zones. `{{key}}` tokens resolve against the active tab's runtime state by host policy; single-payload semantics keeps the host out of the bundle's intra-zone layout. fromJson / toJson / copyWith all wired; omitted when null so existing bundles round-trip byte-identical. Spec §06.4a defines the host behavior. Closes the wiring round-trip drop that forced `vibe_studio_base/_readRawWiring` to bypass the typed model. Regression: 2 cases in `test/models/round_trip_gaps_test.dart` (round-trip preserve + omit-when-null). Tracks `cherry/tracks/mcp-bundle-authoring-d1-d2-d3-2026-05-19.md` (continued, 2026-05-20).

### Added — Round-trip gaps (2026-05-19, additive · G1/G2/G3/G5)
- **G1**: 3 new top-level sections modeled — `chat` (`ChatSection` · `slashCommands[]` + `agent` · accepts both inline `tool`+`args` and nested `directDispatch.{tool,args}`), `wiring` (`WiringSection` · `domainActions[]` button|selectGroup discriminator + `lifecycle[]` + `settings[]` + `lifecycleStateBindings`), `settings` (`SettingsSection` · `sections[]` × `fields[]` × free-form `extra` pass-through). Top-level canonical position per spec §06 update; loader accepts legacy `manifest.<key>` nested position as alias (top-level wins on collision). `McpBundle.{chat, wiring, settingsSection}` final fields + fromJson/toJson/copyWith all wired; `_resolveSection` helper handles dual location. Closes round-trip silent loss of 3 sections digest observed by Diora during D1/D2/D3 adoption.
- **G2**: `McpBundle.fromJson` + `McpBundleLoader.fromJson` now absorb every top-level key the model does not recognise into `extensions._unmodeledTopLevel` and re-spread them via `McpBundle.toJson`. Forward-compat — bundles authored against a future spec extension round-trip through today's loader without silent loss. Author-supplied `extensions` channel preserved unchanged.
- **G3**: `RequiresSection` preserves the empty-array `builtinAtoms` / `builtinTools` shape when the author declared the field explicitly. Distinguishes "author wrote `[]` — bundle is fully portable" from "field absent". `_hadExplicitAtoms` / `_hadExplicitTools` flags drive emit; existing `isEmpty` / `copyWith` semantics unchanged.
- **G5**: `McpBundleMutator.mutate` accepts `McpLoaderOptions? options` and forwards to `loadDirectory` — callers can mutate legacy bundles (missing top-level `schemaVersion`, etc.) by passing `const McpLoaderOptions.lenient()`. Default remains strict.
- G4 (mid-section schemaVersion noise) reverted — spec §3.2 mandates `schemaVersion` always emit; the noise was a spec-driven choice, not a defect. Decision recorded in cherry track.
- Regression: 10 new cases in `test/models/round_trip_gaps_test.dart` covering all 4 gaps × forward / legacy / collision paths. Tracks `cherry/tracks/mcp-bundle-authoring-d1-d2-d3-2026-05-19.md` (continued).

### Added — Authoring layer (2026-05-19, additive)
- `McpBundleWriter.writeManifest(bundle, mbdPath, {indent})` — writes `manifest.json` **only**, leaving every reserved-folder file (`knowledge/`, `agents/`, …) untouched. Use for partial mutations that don't change disk-side resource files. Fraction of the I/O cost of a full `writeDirectory`, races less with concurrent readers. Caller carries the consistency contract (manifest ↔ reserved-folder coherence) — `writeDirectory` is still canonical when both sides change. The existing `writeDirectory` now delegates its manifest write through the same internal helper for DRY.
- `McpBundleMutator.mutate<R>(mbdPath, {fn, timeout, useFileLock, indent})` — transactional load → mutate → write. Three layered guards: (1) per-`mbdPath` in-process FIFO mutex; (2) opt-in OS-level advisory file lock on a `.mbd-lock` sentinel for cross-process safety; (3) optimistic sha256 checksum of `manifest.json` captured at load and verified just before write. Mutation closure returns `MutationOutcome(updated, result)` — null `updated` skips the write entirely; thrown errors abort with no disk side-effect. New `BundleMutationException` reports `BundleMutationReason.timeout` / `lockFailed` / `conflict` so callers can distinguish race vs application errors. Solves the last-write-wins window when multiple authoring surfaces (UI editor + chat agent + headless mcp-server LLM) mutate the same bundle.
- `PartialValidators` facade — pre-insertion validation for 10 entry types: `validateKnowledgeSource` / `validateKnowledgeDocument` / `validateAgent` / `validateFact` / `validateSkill` / `validateProfile` / `validatePhilosophy` / `validateWorkflow` / `validatePipeline` / `validateRunbook`. Each returns `null` for valid entries or a `List<String>` of issues. Combines explicit required-field check (closes the silent fallback gap where `fromJson` coerces missing `id` to empty string) with a smoke `XxxEntry.fromJson(entry)` parse to catch hard shape errors. Lets host authoring tools reject invalid entries before they reach disk — replaces ad-hoc per-mutator `id != null` checks that previously had to track the model's `required` ctor fields by hand. Whole-bundle `McpBundleValidator` still runs at load time for cross-reference integrity (not replaced). Regression: 9 new cases in `test/validator/partial_validators_test.dart`, 9 transaction + 2 writeManifest cases in `test/io/bundle_mutator_test.dart`. Tracks `cherry/tracks/mcp-bundle-authoring-d1-d2-d3-2026-05-19.md`.

### Added
- `schemaVersion` field added to `AgentsSection` / `FactGraphSection` / `PhilosophySection` / `PolicySection` / `ProfilesSection` / `RequiresSection` (default `'1.0.0'`, additive — backward compatible). Aligns the 6 sections that previously lacked the slot with the common section pattern (spec 1.0 §3.2: every typed section MUST expose `schemaVersion` defaulting to `'1.0.0'`). `fromJson` falls back to `'1.0.0'` when the key is absent, so bundles authored before this release continue to load identically. `toJson` always emits `schemaVersion`. `FactGraphSection`'s legacy `version` field is preserved alongside the new `schemaVersion` — both round-trip independently. New regression cases per section in `test/models/{agent,philosophy,policy,profile,fact_graph,requires}_section_test.dart` cover default + parse + round-trip + copyWith.
- `FactsSection` + `Fact` class (subject/predicate/object/confidence?/source?/metadata) — inline path under `manifest.facts[]`.
- `WorkflowsSection` + `WorkflowEntry` (id/name/version/description?/steps/metadata) — `manifest.workflows[]`.
- `PipelinesSection` + `PipelineEntry` (stages) — `manifest.pipelines[]`.
- `RunbooksSection` + `RunbookEntry` (procedure) — `manifest.runbooks[]`.
- `ToolsSection` + `ToolEntry` + `ToolKind` enum (host/mcp/cloud/js) — inline path under `manifest.tools[]`. Standard surface where Studio and AppPlayer receive a bundle's tool declarations. The `target` map is kind-discriminated (host=`{}` · mcp=`{transport,url?,command?,args?}` · cloud=`{url}` · js=`{entry,fn}`). Validator is lenient — only checks that `name` is present, `kind` is not `unknown`, and `name` values are unique.
- `ToolEntry.outputSchema` field (additive · `Map<String, dynamic>?` · no enforced JSON Schema dialect) — mirrors `inputSchema`. Defaults to `null`; `fromJson` / `toJson` / `copyWith` all preserve it. When the host advertises a response shape, callers can use it to validate the `mergeState` auto-merge contract (mcp_ui_dsl 1.3 §3.10). Closes the gap where on-disk `.mbd/manifest.json` `tools.tools[]` entries were already emitting `outputSchema` but only the raw map was accessible — there was no typed getter. Validator policy stays lenient (`outputSchema` shape is not enforced). Test cases live in `test/models/tools_test.dart` (map round-trip · null default · copyWith · independence from `inputSchema`).
- `McpBundle` gains 5 new top-level fields — same pattern as the existing `skills` / `profiles` / `philosophy` / `agents`.
- **5 new BundleFolder entries: `facts` · `workflows` · `pipelines` · `runbooks` · `tools` (additive · existing 7 unchanged).** `BundleFolder.values` grows 7 → 12 (declaration order: ui · assets · skills · knowledge · facts · workflows · pipelines · runbooks · tools · profiles · philosophy · agents). Companion surface for callers that want to carry large facts / workflow / pipeline / runbook / tool definitions in a dedicated reserved subfolder instead of inline inside the manifest.
- `McpBundle` gains 5 new typed accessors — `factsResources` · `workflowsResources` · `pipelinesResources` · `runbooksResources` · `toolsResources` (each wrapping `bundle.resources(BundleFolder.X)`). Same pattern as the existing `uiResources` / `assetResources` / `skillResources` / `knowledgeResources` / `profileResources` / `philosophyResources` / `agentResources`.

### Fixed
- **Loader `fromJson` missing Section forward** — `McpBundleLoader.fromJson` (the canonical entry point used by `loadFile` / `loadDirectory` / `fromJsonString`) only forwarded 4 sections (`ui` · `skills` · `assets` + `extensions`) when assembling the returned `McpBundle`. Every other typed top-level Section the model declares — `knowledge` · `flow` · `profiles` · `philosophy` · `agents` · `facts` · `workflows` · `pipelines` · `runbooks` · `tools` · `requires` · `factGraphSchema` · `factGraphSection` · `bindings` · `tests` · `policies` · `integrity` · `compatibility` — was silently dropped at the loader boundary even when present in the source JSON. Hosts using `McpBundle.fromJson` directly observed the right shape; hosts going through the loader did not. The internal `_ParsedSections` container and `_parseSections` phase had no awareness of the missing 18 sections at all. This release expands `_ParsedSections` to hold every typed top-level field the model carries, parses each section in `_parseSections` via a generic `_parseSection<T>` helper that mirrors the canonical `models/bundle.dart` `McpBundle.fromJson` per-section pattern (presence check → typed `fromJson` → on-failure record error + skip warning + null), and forwards every parsed section into the assembled `McpBundle(...)` constructor call. `_resolveAssetPaths` (the post-`loadDirectory` step that rewrites relative `contentRef` paths to absolute) similarly hand-rolled a constructor call that dropped most sections; it now uses `bundle.copyWith(assets: …)` so every other section the loader assembled survives path resolution. Strictly additive — no existing field shape changed, no existing forward removed, schemaVersion stays `'1.0.0'`, pubspec stays `0.3.3`. Bundles using only the historical 4 sections continue to load identically (verified by backward-compat regression tests).

### Backward compatibility
- Fully additive. Existing fields, sections, and the 7 original BundleFolder entries are unchanged (no renames, no aliases). `KnowledgeSection` / `BundleFolder.knowledge` / `bundle.knowledgeResources` are untouched. schemaVersion stays `'1.0.0'`.
- Existing `.mbd` bundles authored against 0.3.2 keep working — a `^0.3.0` caret still resolves. The 5 new folders only appear on disk when the host writes them explicitly.
- The inline data path for the 5 new sections is unchanged (the `facts` / `workflows` / `pipelines` / `runbooks` / `tools` keys inside `manifest.json`). The new folder surface is the companion location.
- Loader Section forward fix: bundles that depend only on `ui` / `skills` / `assets` / `manifest` / `extensions` continue to load unchanged. Sections previously dropped by the loader become visible automatically — host code that already null-checks every section field is unaffected; host code that asserts a previously-dropped section is null will need to update.

---

## [0.3.2] - 2026-05-07 - `factGraphSection` wired into `McpBundle`

### Added
- `McpBundle.factGraphSection` — `FactGraphSection?` field exposing FactGraph instance data (entities / facts / relations / summaries / policies, embedded inline or referenced externally per `FactGraphSection.mode`). The `FactGraphSection` model existed since 0.3.0 but was not wired through `McpBundle`'s constructor / `fromJson` / `toJson` / `copyWith` / `hasContent` / `presentSections`, so adapters that wanted to round-trip fact instances inside a bundle had no canonical slot. This release adds the wire so consumers can persist fact instance data alongside the existing `factGraphSchema` (type definitions). Strictly additive — no existing field shape changed; bundles produced by 0.3.x clients continue to load unchanged.

---

## [0.3.1] - 2026-05-04 - EthosRecord JSON round-trip + `agents` reserved folder

### Added
- `EthosRecord.fromJson` / `EthosRecord.toJson` — adapters that persist ethos records via `dart:convert` (KV stores, file-backed adapters, network bridges) can now serialize without ad-hoc per-host glue. `payload` is preserved as-is, `createdAt` round-trips through ISO-8601, `active` defaults to false when absent.
- `BundleFolder.agents` — seventh reserved bundle folder for agent definitions (4-axis bindings + runtime config). Companion `Bundle.agentResources` getter exposes the same `BundleResources` surface as the other six folders. Hosts that bundle agents alongside ui / skills / knowledge / profiles / philosophy now have a canonical on-disk slot.
- `AgentsSection` / `AgentDefinition` — typed model for agent definitions inside a bundle (the static description that a host runtime instantiates into a live agent: role, four-axis bindings — profiles / skills / facts / philosophies — and runtime config such as model / tools / behavior).
- `PhilosophySection` — typed model for philosophy / ethos definitions (guiding principles paired with applied examples and counter-examples). Distinct from `PolicySection` — philosophy captures *why* and *what to learn from*, policy captures *what to enforce*.
- `EthosStorePort` extensions — additional accessor methods so consumers (e.g. `mcp_knowledge.PhilosophyFacade.getEthosById`) can resolve ethos records by id without scanning, completing the symmetry with the other knowledge stores.

---

## [0.3.0] - 2026-04-28 - Standard Port Catalog & Install Pipeline

### Added
- **Standard Port Catalog (40+ ports)** — capability-named contracts spanning UI/Form, IO devices, Knowledge (facts, entities, claims, evidence, candidates, summaries, patterns, index, retrieval), Profile (appraisal, decision, expression, summaries), Skill (registry, runtime), Ops (workflow, pipeline, runbook, runs, schedule trigger), Philosophy (ethos store, philosophy), Analysis (function, datasource), and shared services (mcp, metrics, notification, audit, approval, asset, flow, ingest).
- **Bundle install / sign / pack subsystem** (`lib/src/install/`) — BundleSigner, BundlePacker, BundleInstaller, InstallPolicy, TrustStore, RuntimeDescriptor.
- **Bundle storage subsystem** (`lib/src/io/`) — BundleStoragePort with File / HTTP / Memory adapters, BundleRepository, BundleResources, type coercion utilities.
- Profile and Skill model packages, fact-graph schema/section, integrity, and policy models.

### Changed
- Expression engine split into lexer / parser / AST / evaluator / functions modules.
- Manifest and UI section: `ui/` reserved folder is now canonical; UiSection typed fields deprecated (round-trip only, removal targeted for 0.6.0).
- LLM port refined.

### Removed
- `lib/src/loader/` legacy loader — replaced by `lib/src/io/` storage subsystem.

---

## [0.2.1] - Channel Port & Port Contracts

### Added

#### Channel Port (`package:mcp_bundle/ports.dart`)

Universal bidirectional communication interface for the MCP ecosystem.

- **ChannelIdentity**
  - Platform identifier (slack, telegram, discord, http, websocket, etc.)
  - Channel-specific ID (workspace ID, server ID)
  - Optional display name
  - JSON serialization support

- **ConversationKey**
  - Unique conversation identifier
  - Combines channel identity with conversation ID
  - Optional user identifier
  - Equality and hashing support

- **ChannelAttachment**
  - File/media attachment model
  - Type, URL, filename, MIME type, size
  - JSON serialization support

- **ChannelEvent**
  - Incoming event from channels
  - Unique event ID for idempotency
  - Conversation key, type, text content
  - User ID/name, timestamp
  - Attachments and platform metadata
  - Factory: `ChannelEvent.message()` for message events

- **ChannelResponse**
  - Outgoing response to channels
  - Text and rich block content
  - Attachments and reply-to support
  - Platform-specific options
  - Factories: `ChannelResponse.text()`, `ChannelResponse.rich()`

- **ChannelCapabilities**
  - Feature flags for channel implementations
  - text, richMessages, attachments, reactions
  - threads, editing, deleting, typingIndicator
  - Maximum message length constraint
  - Presets: `ChannelCapabilities.full()`, `ChannelCapabilities.textOnly()`

- **ChannelPort (Abstract)**
  - Universal interface for channel communication
  - `identity`, `capabilities`, `events` stream
  - `start()`, `stop()`, `send()` methods
  - Optional: `sendTyping()`, `edit()`, `delete()`, `react()`

- **Stub Implementations**
  - `StubChannelPort` for testing with event simulation
  - `EchoChannelPort` for echo-back testing

---

## [0.1.0] - Initial Release

### Added

#### Core Features
- **Bundle Schema**
  - `McpBundle` model as the main container
  - `BundleSkill` for skill definitions
  - `BundleProfile` for profile definitions
  - `BundleKnowledge` for knowledge items
  - Metadata and versioning support

- **Bundle Loader**
  - `BundleLoader` for loading and saving bundles
  - File-based loading with `.mcpb` format
  - URL-based loading for remote bundles
  - JSON data loading for in-memory bundles
  - Bundle serialization and deserialization

- **Bundle Validator**
  - `BundleValidator` for comprehensive validation
  - Schema validation for all bundle components
  - Reference integrity checking
  - Warning and error reporting
  - Customizable validation rules

- **Expression Language**
  - `ExpressionEvaluator` for template processing
  - Mustache-style variable syntax `{{variable}}`
  - Conditional sections `{{#condition}}...{{/condition}}`
  - Inverted sections `{{^condition}}...{{/condition}}`
  - Array iteration `{{#array}}...{{/array}}`
  - Nested property access `{{user.address.city}}`
  - Built-in functions for data manipulation

- **Validation Results**
  - `BundleValidation` with errors and warnings
  - Detailed error messages with locations
  - Validation context for debugging

### Data Models
- `McpBundle` - Main bundle container
- `BundleSkill` - Skill definition in bundle
- `BundleProfile` - Profile definition in bundle
- `BundleKnowledge` - Knowledge item in bundle
- `BundleValidation` - Validation result

### Expression Features
- Variable interpolation
- Conditional rendering
- Array iteration
- Nested property access
- Function calls

