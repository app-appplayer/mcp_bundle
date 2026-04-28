# MCP Bundle

A foundational Dart package providing bundle schema, expression language, **standard port contracts**, and a **bundle install / sign / pack pipeline** for the MCP ecosystem. This is the core package other MCP packages depend on.

## Overview

`mcp_bundle` defines:

- **Bundle data models** — `McpBundle` with skills, profiles, knowledge, manifest, UI, flow, fact-graph, and test sections, plus integrity / policy / signing types.
- **Standard Port Catalog** — capability-named contracts (`package:mcp_bundle/ports.dart`) that other MCP packages implement.
- **Bundle storage** — `BundleStoragePort` with file / HTTP / memory adapters, plus repository and resource accessors.
- **Bundle install pipeline** — packing, signing, trust verification, and installation policy.
- **Expression language** — Mustache-style templates with a separated lexer / parser / AST / evaluator.
- **Validator** — schema, reference integrity, and signing integrity checks.

## Standard Port Catalog

The Contract Layer in `package:mcp_bundle/ports.dart`. Each port is a capability-named abstract interface other packages implement.

| Domain | Ports |
|---|---|
| **UI / Form** | `UiPort`, `FormPort`, `FormRendererPort`, `FormTemplatePort` |
| **IO devices** | `IoDevicePort`, `IoStreamPort`, `IoRegistryPort`, `IoPolicyPort`, `IoAuditPort` |
| **Knowledge** | `FactsPort`, `EntitiesPort`, `ClaimsPort`, `EvidencePort`, `CandidatesPort`, `SummariesPort`, `PatternsPort`, `IndexPort`, `RetrievalPort`, `ContextBundlePort`, `KnowledgePorts` (aggregate) |
| **Profile** | `AppraisalPort`, `DecisionPort`, `ExpressionPort`, `ProfileSummariesPort` |
| **Skill** | `SkillRegistryPort`, `SkillRuntimePort` |
| **Ops** | `WorkflowPort`, `PipelinePort`, `RunbookPort`, `RunsPort`, `ScheduleTriggerPort` |
| **Philosophy** | `PhilosophyPort`, `EthosStorePort` |
| **Analysis** | `AnalysisPort`, `AnalysisFunctionPort`, `AnalysisDataSourcePort` |
| **Flow** | `FlowPort` |
| **Shared services** | `LlmPort`, `StoragePort`, `ChannelPort`, `MetricPort`, `MetricsPort`, `EventPort`, `NotificationPort`, `AuditPort`, `ApprovalPort`, `AssetPort`, `McpPort`, `IngestPorts` |

```dart
import 'package:mcp_bundle/ports.dart';

class MyLlmAdapter extends LlmPort {
  @override
  LlmCapabilities get capabilities => const LlmCapabilities.full();

  @override
  Future<LlmResponse> complete(LlmRequest request) async {
    // ...
  }
}
```

## Quick Start

```dart
import 'package:mcp_bundle/mcp_bundle.dart';

final bundle = McpBundle(
  id: 'my_bundle',
  name: 'My AI Bundle',
  version: '1.0.0',
  skills: [
    BundleSkill(
      id: 'summarizer',
      name: 'Text Summarizer',
      executor: 'llm',
      prompt: 'Summarize: {{input.text}}',
    ),
  ],
  profiles: [
    BundleProfile(
      id: 'assistant',
      name: 'Helpful Assistant',
      systemPrompt: 'You are a helpful assistant for {{user.name}}.',
    ),
  ],
);

final validator = BundleValidator();
final result = await validator.validate(bundle);
if (!result.isValid) {
  print(result.errors);
}
```

## Bundle Storage

`BundleStoragePort` abstracts where bundles live. Three built-in adapters:

```dart
final fileStore = FileStorageAdapter(rootDir: '/path/to/bundles');
final httpStore = HttpStorageAdapter(baseUri: Uri.parse('https://example.com/bundles'));
final memStore  = MemoryStorageAdapter();

final repo = BundleRepository(storage: fileStore);
final bundle = await repo.load('my_bundle');
final resources = bundle.resources;          // ui/, assets/, etc.
final uiJson = await resources.readJson('ui/home.json');
```

## Bundle Install / Sign / Pack

A signed `.mcpb` distribution pipeline:

```dart
final packer    = McpBundlePacker();
final signer    = BundleSigner(privateKeyPem: ...);
final installer = McpBundleInstaller(trustStore: TrustStore(...));

final packed   = await packer.pack(bundle);
final signed   = await signer.sign(packed);
final installed = await installer.install(
  signed,
  policy: const InstallPolicy.strict(),
);
```

## Expression Language

Mustache-style templates evaluated against a context map:

```dart
final expr = ExpressionEvaluator();
expr.evaluate('{{user.name}}', {'user': {'name': 'John'}});
// → 'John'

expr.evaluate('{{#isPremium}}Premium{{/isPremium}}', {'isPremium': true});
// → 'Premium'

expr.evaluate('{{#items}}Item: {{name}}\n{{/items}}', {
  'items': [{'name': 'A'}, {'name': 'B'}],
});
// → 'Item: A\nItem: B\n'
```

## UI Resources

The canonical representation of UI in a bundle is the on-disk `ui/` reserved folder, accessed through `BundleResources` (`bundle.uiResources.list / readJson / ...`). Each `ui/<rel>.json` maps to a `ui://<rel>` MCP resource URI.

The legacy typed UI fields on `UiSection` are deprecated and exist only as a forward-compat round-trip channel for older bundles. New tooling should write under `ui/`.

## Support

- [Issue Tracker](https://github.com/app-appplayer/mcp_bundle/issues)
- [Discussions](https://github.com/app-appplayer/mcp_bundle/discussions)

## License

MIT — see [LICENSE](LICENSE).
