# Bundle Resource I/O

`mcp_bundle` is the **single owner of bundle file I/O**. Every consumer of
a bundle — runtime renderer, MCP server, designer, installer, CLI tool —
reads and writes bundle files **through `mcp_bundle`'s API only**, never
through `dart:io` directly. Adapter packages translate the bytes into
their own domain models (`flutter_mcp_ui_runtime` renders, an MCP server
serves, etc.).

## Why centralise

- **Predictability** — one parse path, one set of safety checks (path
  traversal, UTF-8, JSON validation), one notion of "what the bundle
  contains".
- **Migrability** — swap the on-disk layout (snapshot ↔ archive ↔ remote)
  without touching every consumer.
- **Demo clarity** — sample code shows the canonical flow:
  `bundle.<folder>Resources.read(rel)` → adapter → consumer. No `File`
  imports anywhere outside `mcp_bundle`.

## Reserved Folders

Six folder names are **reserved** by the bundle format. Each maps 1:1 to
a sub-tree under the `.mbd/` root:

| Folder | Purpose |
| --- | --- |
| `ui/` | UI definition files (mcp_ui_dsl JSON) |
| `assets/` | Binary or text assets (icons, splash, fonts, …) |
| `skills/` | Skill / capability module definitions |
| `knowledge/` | Knowledge sources, retriever configs |
| `profiles/` | Profile definitions |
| `philosophy/` | Philosophy / ethos definitions |

Layout:

```
my-app.mbd/
├── manifest.json   # BundleManifest + integrity + compatibility (the bundle's source-of-truth root)
├── ui/             # reserved
├── assets/         # reserved
├── skills/         # reserved
├── knowledge/      # reserved
├── profiles/       # reserved
└── philosophy/     # reserved
```

`manifest.json` is the bundle's identity record — a serialised
`BundleManifest` plus optional `IntegrityConfig` and
`CompatibilityConfig`. The name is the source-of-truth signal: the
file is the manifest, not a generic "bundle container".

An on-disk file under a reserved folder is the canonical
representation of that resource. The `ui/` folder in particular is a
filesystem snapshot of the URI space an MCP server would serve —
`ui/<rel>.json` ↔ `ui://<rel>`. Bundle authoring tools must write
content into reserved folders rather than embedding sections inline
in `manifest.json`.

## API Shape

```dart
class McpBundle {
  // Generic — folder name as a string. Throws StateError when the
  // bundle has no [directory] (loaded from inline JSON / remote fetch).
  BundleResources resources(String folder);

  // Typed shortcuts for the six reserved folders.
  BundleResources get uiResources;
  BundleResources get assetResources;
  BundleResources get skillResources;
  BundleResources get knowledgeResources;
  BundleResources get profileResources;
  BundleResources get philosophyResources;
}

class BundleResources {
  /// Read file contents as UTF-8 text. Throws [BundleResourceNotFound]
  /// on missing file, [FileSystemException] on I/O failure.
  Future<String> read(String relativePath);

  /// Read file contents as raw bytes.
  Future<Uint8List> readBytes(String relativePath);

  /// Read JSON-decoded content. Throws [BundleResourceParseException]
  /// on malformed JSON.
  Future<dynamic> readJson(String relativePath);

  /// Write UTF-8 text. Creates parent directories as needed.
  Future<void> write(String relativePath, String content);

  /// Write raw bytes. Creates parent directories as needed.
  Future<void> writeBytes(String relativePath, Uint8List bytes);

  /// JSON-encode [value] (default 2-space indent) and write. Creates
  /// parent directories as needed. Symmetric with [readJson] so callers
  /// do not repeat `jsonEncode` + `write`.
  Future<void> writeJson(String relativePath, Object? value, {int indent = 2});

  /// Check whether the file exists.
  Future<bool> exists(String relativePath);

  /// Delete the file. No-op on missing.
  Future<void> delete(String relativePath);

  /// Enumerate files under this folder. [extension] filters by suffix
  /// (e.g. `.json`); pass `null` for all files. Returns paths relative
  /// to the folder root, with forward-slash separators, sorted
  /// lexicographically.
  Future<List<String>> list({String? extension});
}
```

### Path Safety

All methods reject:

- Absolute paths (`/foo`, `C:\foo`)
- Path traversal (`..` segments)
- Symlink resolution that escapes the folder root

These checks live in `BundleResources` and apply to every consumer
uniformly.

## Demo Flow

A bundle-backed MCP server (sample / reference):

```dart
final bundle = await McpBundleLoader.loadDirectory(mbdPath);
for (final rel in await bundle.uiResources.list(extension: '.json')) {
  final content = await bundle.uiResources.read(rel);
  final uri = 'ui://${rel.substring(0, rel.length - '.json'.length)}';
  server.addResource(
    uri: uri,
    name: rel.split('/').last,
    handler: (_, __) async => /* serve content */,
  );
}
```

A renderer adapter (`BundleUiReadAdapter` in `flutter_mcp_ui_runtime`):

```dart
final appJson = jsonDecode(await bundle.uiResources.read('app.json'));
// build ApplicationDefinition from appJson; lazy-load pages on demand
// via bundle.uiResources.read('pages/X.json').
```

Production-grade consumers may add fallbacks (cache, CDN, embedded
inline sections). The demo path stays one liner per file: read through
mcp_bundle, hand to adapter.

## Authoring: Folders Only

Bundle authoring tools must write UI content as files under `ui/`,
never as inline `manifest.json:ui` blocks. The typed `UiSection` fields
(`pages`, `widgets`, `theme`, `navigation`, `state`) are deprecated and
exist only as a forward-compat round-trip channel: when a legacy
bundle's `manifest.json` carries inline `ui` section data,
`UiSection.fromJson` preserves the raw map and `toJson` re-emits it
unchanged. New code never reads from those typed fields — it goes
through `BundleResources`.

Same rule applies to other section folders. The `manifest.json` carries
identity (manifest), integrity, and compatibility — not content.

## What `mcp_bundle` Does Not Do

- Render UI (that's `flutter_mcp_ui_runtime`'s adapter)
- Serve resources via MCP (that's the consumer's MCP server impl)
- Resolve `bundle://` URIs into Flutter `ImageProvider`s (asset adapter)
- Validate UI semantics (mcp_ui_dsl validator)

`mcp_bundle` reads bytes, writes bytes, and validates the bundle
*format* (manifest, integrity, schema). Domain interpretation lives in
the consumer adapters.
