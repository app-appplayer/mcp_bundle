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

