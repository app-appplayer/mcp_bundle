# Bundle Packaging and Install Lifecycle

Defines the two on-disk forms of an MCP bundle, the transitions between
them, and the install / load / uninstall lifecycle that `mcp_bundle`
exposes.

All behaviour is driven by fields already declared in `BundleManifest`,
`IntegrityConfig`, and `CompatibilityConfig`. This document specifies how
those fields are consumed at packaging and install time and what contracts
the hosting process must fulfil.

## Forms

### `.mcpb` — Distribution Package

A single file containing a ZIP archive of a `.mbd/` tree.

- Extension: `.mcpb`
- Magic bytes: `PK\x03\x04`
- Compression: DEFLATE
- Entry order: lexicographic by path; `manifest.json` always first
- Path normalisation: forward slashes; no leading `/`; no `..` segments;
  no symlink entries; no entry whose normalised path escapes the archive
  root
- Entry size caps (see [Safety Limits](#safety-limits))
- Purpose: transport (HTTP, file share, picker, attachment)

### `.mbd/` — Unpacked Directory

A directory containing the expanded bundle tree.

- Extension: `.mbd/` (treated as a directory on every platform)
- Required entry: `manifest.json` at the root; serialised `McpBundle.toJson()` (manifest + optional integrity / compatibility / sections — bundle's source-of-truth identity record). Pre-launch: legacy `bundle.json` is not accepted.
- Six **reserved sub-folders** for discrete content:
  `ui/`, `assets/`, `skills/`, `knowledge/`, `profiles/`, `philosophy/`.
  Consumers read / write files under these folders through the
  `BundleResources` API (`bundle.uiResources` / `assetResources` / …);
  `dart:io` access is forbidden for callers outside `mcp_bundle`. See
  [`bundle_resource_io.md`](bundle_resource_io.md) for the design.
- `contentRef` resolution: relative paths resolve against the `.mbd/` root;
  absolute paths and URIs (`http://`, `https://`, `file://`) are kept as-is
- Purpose: runtime read access, direct use by other packages, development

## Install Root Layout

Produced by `McpBundleInstaller` under a caller-provided `installRoot`:

```
<installRoot>/
  .lock                         OS-level install lock
  .staging/                     in-progress extractions (ignored by list())
  <bundleId>/                   one directory per installed bundle
    manifest.json                 copy of the installed manifest + sections
    <...assets, knowledge, etc. from the .mbd tree>
    .install.json               sidecar metadata (see below)
```

Only one version of a given `bundleId` is resident at a time. Upgrade is an
atomic replace (see [Install Steps](#install--mcpb--installrootid)).

`.install.json` sidecar (per installed bundle):

```json
{
  "schemaVersion": "1.0.0",
  "id": "com.example.app",
  "version": "1.2.0",
  "installedAt": "2026-04-20T10:00:00Z",
  "manifestDigest": "sha256:...",
  "sourceDigest": "sha256:...",
  "signer": "keyId-or-null"
}
```

- `manifestDigest`: SHA-256 of the canonical JSON of `BundleManifest.toJson`
  at install time; used to detect on-disk tampering of `manifest.json`
- `sourceDigest`: SHA-256 of the original `.mcpb` bytes
- `signer`: the `keyId` of the verified signature, or `null` when the
  package was unsigned (and the install was permitted by policy)

`list()` discovers installed bundles by scanning `<installRoot>/*/manifest.json`;
the sidecar augments but never replaces the on-disk truth.

## Pack — `.mbd/` → `.mcpb`

`McpBundlePacker.packDirectory(mbdPath, {computeIntegrity = true,
signer})`.

Steps:
1. Load the directory with `McpBundleLoader.loadDirectory(mbdPath)`.
2. When `computeIntegrity` (default `true`): populate
   `McpBundle.integrity.contentHash` / `files[]` per `ContentHash.scope`:
   - `canonicalJson`: SHA-256 of the canonical JSON of `McpBundle.toJson`
     with the `integrity` field itself excluded
   - `contentSections`: SHA-256 of the canonical JSON of each present
     content section (`ui` / `flow` / `skills` / `assets` / `knowledge` /
     `bindings` / `tests` / `policies` / `profiles`), concatenated in that
     fixed order with a NUL separator
   - `allFiles`: SHA-256 of every regular file in the `.mbd/` tree in
     lexicographic path order, joined as `(pathUtf8, 0x00, bytes, 0x00)`
     tuples; `manifest.json` excluded because its `integrity` field is
     being computed
3. When `signer` is provided: compute the payload bytes according to
   `SignedPayloadRef.type`:
   - `contentHash`: the raw bytes of the populated `contentHash.value`
   - `manifest`: canonical JSON of `BundleManifest.toJson`
   - `allSections`: the same byte sequence used for
     `ContentScope.contentSections` above
   - `external`: caller supplies the bytes; `url` is recorded as-is
   
   Sign with the declared `SignatureAlgorithm` and append to
   `integrity.signatures[]`.
4. Serialise the updated bundle JSON.
5. Emit ZIP bytes:
   - First entry: `manifest.json`
   - Remaining entries: every regular file in the `.mbd/` tree in
     lexicographic path order
   - DEFLATE compression, zero metadata beyond required fields (no
     extra timestamps, no uid/gid) so output is byte-reproducible for a
     given input tree

`computeIntegrity: false` is an escape hatch for local development;
the resulting `.mcpb` fails any installer configured with
`InstallPolicy.requireIntegrity`.

## Install — `.mcpb` → `<installRoot>/<id>/`

`McpBundleInstaller.installBytes(bytes, {installRoot, runtime, policy,
trustStore})` / `installFile(path, ...)` / `installDirectory(mbdPath,
...)` / `installUrl(uri, {headers, client, timeout, ...})`.

`installDirectory` packs an already-unpacked `.mbd/` tree in memory via
`McpBundlePacker` and routes the result through `installBytes`, so the
same verification pipeline (integrity / compatibility / signature /
safety limits) runs regardless of how the source was supplied.

`installUrl` issues an HTTP GET, honours `InstallPolicy.limits` as a
pre-check against the response's `Content-Length`, maps non-2xx
responses to `BundleReadException` (404 → `BundleNotFoundException`),
and delegates the verified bytes to `installBytes`. The host may inject
a `http.Client` to control retries / connection pooling; otherwise a
one-shot client is used and closed.

Steps (each step aborts on failure and rolls back any disk state produced
by earlier steps):

1. **Acquire** `<installRoot>/.lock` with an exclusive OS lock
   (`flock` on POSIX, `LockFileEx` on Windows). Abort with
   `BundleBusyException` if non-blocking acquisition fails.
2. **Validate container**: verify ZIP magic bytes; reject anything else
   with `BundleFormatException`.
3. **Enforce safety limits** before extraction (see [Safety Limits](#safety-limits)).
4. **Parse manifest** from the `manifest.json` entry without touching disk.
5. **Enforce compatibility** (`CompatibilityConfig`):
   - `schemaVersion` inside the loader's supported set
   - `runtime.version` inside `[minRuntimeVersion, maxRuntimeVersion]`
   - every `requiredFeatures` entry present in `runtime.features`
   - no `incompatibleWith` entry matches any currently installed
     `bundleId`
6. **Enforce integrity** (`IntegrityConfig`) when either:
   - `policy.requireIntegrity` is `true`, or
   - the bundle declares an `IntegrityConfig`
   
   Recompute `contentHash` under its declared `scope`, recompute each
   `FileHash`, and call the respective `verify` method. Reject on any
   mismatch.
7. **Verify signatures** when `integrity.signatures[]` is non-empty:
   - For each entry, resolve the public key from `trustStore` by
     `keyId`; reject with `BundleSignatureException` if no matching
     key is trusted.
   - Build the signed payload bytes for the declared
     `SignedPayloadRef.type` (identical rules to [Pack](#pack--mbd--mcpb)
     step 3).
   - Verify with the declared `SignatureAlgorithm`.
   - When `policy.requireSignature` is `true`, missing signatures
     abort the install.
8. **Stage**: create a unique directory under
   `<installRoot>/.staging/<uuid>/` and extract every ZIP entry into it.
   Re-apply the path-traversal checks per entry; refuse symlinks and
   non-regular entries.
9. **Write** the `.install.json` sidecar into the staging directory with
   `manifestDigest`, `sourceDigest`, `signer`, and `installedAt`.
10. **Swap**: resolve `<installRoot>/<bundleId>/` to a target path. When
    the target exists, rename it to
    `<installRoot>/.staging/<uuid>-previous/` (still an atomic rename),
    then rename the newly staged directory into the target path. On any
    failure during the swap, rename the previous version back.
11. **Cleanup**: delete `<...-previous/>` on success.
12. **Release** the lock and return `InstalledBundle`.

### Conflict Policy

`InstallPolicy.onConflict`:

- `failIfExists` — throw `BundleAlreadyInstalledException` when the target
  `<bundleId>/` exists.
- `replace` (default) — atomic swap per steps 10–11.
- `skipIfExists` — abort after step 5 when the target exists; return the
  previously-installed metadata.

`InstallPolicy.requireIntegrity` (default `true`) and
`InstallPolicy.requireSignature` (default `false`) gate integrity and
signature enforcement for all sources uniformly.

## Uninstall

`McpBundleInstaller.uninstall(installRoot, id)`.

Steps:
1. Acquire `<installRoot>/.lock`.
2. Rename `<installRoot>/<id>/` to `<installRoot>/.staging/<uuid>-deleted/`.
3. Recursively delete the renamed directory.
4. Release the lock.

Failure between steps 2 and 3 leaves a staging-tree orphan that the next
installer run cleans up on lock acquisition.

## Load

- `McpBundleLoader.loadDirectory(mbdPath)` — unchanged; reads any `.mbd/`
  tree regardless of whether it lives under `installRoot`.
- `McpBundleLoader.loadInstalled(installRoot, id)` — resolves
  `<installRoot>/<id>/` and delegates to `loadDirectory`.

Both return a fully-parsed `McpBundle` with relative `contentRef` paths
rewritten to absolute paths under the `.mbd/` root.

## Safety Limits

Installer-enforced caps against malformed or hostile `.mcpb` inputs.
Defaults apply unless the caller overrides via `InstallPolicy`:

| Limit | Default | Purpose |
|---|---|---|
| `maxCompressedBytes` | 64 MiB | reject oversized archives |
| `maxUncompressedBytes` | 512 MiB | ZIP-bomb defence |
| `maxCompressionRatio` | 100:1 | ZIP-bomb defence per entry |
| `maxEntryCount` | 10 000 | defence against entry-count bombs |
| `maxEntryPathLength` | 1 024 chars | defence against path-length abuse |
| `maxPathDepth` | 32 | defence against deeply nested trees |

Any entry that violates a cap aborts the install immediately and removes
the staging directory.

## Trust Store

`TrustStore` is a caller-supplied object handed to the installer. It
exposes:

```
TrustedPublicKey? lookup(String keyId);
bool isRevoked(String keyId);
```

`mcp_bundle` never persists or fetches keys. Hosts decide key provenance
(bundled trust roots, OS keychain, TOFU pinning, remote revocation list,
etc.) and inject the populated `TrustStore` per install call.

## Runtime Descriptor

`RuntimeDescriptor` is the caller's declaration of the running
environment:

```
String version;                 // semver string, matched against min/maxRuntimeVersion
Set<String> features;           // matched against CompatibilityConfig.requiredFeatures
```

`mcp_bundle` never inspects the process, the Flutter binding, or any
platform API to discover these values.

## Dependencies

- `package:archive` — pure-Dart ZIP encode / decode
- `package:crypto` — already a transitive dependency; used for SHA-256
  hashing and, with `package:pointycastle` where the host opts in, for
  signature verification

No Flutter dependency is added. `path_provider`, `flock` bindings, or any
other platform-specific concern belong in the host.

## Public API Surface

```
// Packaging
McpBundlePacker
  static Future<Uint8List> packDirectory(
    String mbdPath, {
    bool computeIntegrity = true,
    BundleSigner? signer,
  });

// Lifecycle
McpBundleInstaller
  static Future<InstalledBundle> installBytes(
    Uint8List bytes, {
    required String installRoot,
    required RuntimeDescriptor runtime,
    InstallPolicy policy = const InstallPolicy(),
    TrustStore trustStore = const EmptyTrustStore(),
  });
  static Future<InstalledBundle> installFile(
    String filePath, { ...same ... });
  static Future<InstalledBundle> installDirectory(
    String mbdPath, { ...same ... });
  static Future<InstalledBundle> installUrl(
    Uri url, {
    ...same ...,
    Map<String, String>? headers,
    http.Client? client,
    Duration timeout = const Duration(seconds: 60),
  });
  static Future<void> uninstall(String installRoot, String id);
  static Future<List<InstalledBundle>> list(String installRoot);

// Loading
McpBundleLoader
  static Future<McpBundle> loadInstalled(String installRoot, String id);
  static Future<McpBundle> loadDirectory(String mbdPath);   // unchanged
```

New value types:

```
class InstalledBundle {
  final String id;
  final String version;
  final String installPath;     // absolute .mbd/ path
  final BundleManifest manifest;
  final DateTime installedAt;
  final String? signer;
}

class InstallPolicy {
  final InstallConflictPolicy onConflict;  // default: replace
  final bool requireIntegrity;             // default: true
  final bool requireSignature;             // default: false
  final InstallLimits limits;              // defaults in the table above
}

enum InstallConflictPolicy { failIfExists, replace, skipIfExists }

class RuntimeDescriptor {
  final String version;
  final Set<String> features;
}

abstract class TrustStore {
  TrustedPublicKey? lookup(String keyId);
  bool isRevoked(String keyId);
}

class TrustedPublicKey {
  final String keyId;
  final SignatureAlgorithm algorithm;
  final Uint8List publicKey;       // raw key bytes in the algorithm's canonical form
}

abstract class BundleSigner {
  String get keyId;
  SignatureAlgorithm get algorithm;
  Uint8List sign(Uint8List payload);
}
```

## Install Root Placement

`installRoot` must be a directory inside the host process's private
runtime data area — never a world-readable filesystem location.
Recommended per platform:

| Platform | Path | API |
|---|---|---|
| iOS | App sandbox `Library/Application Support/…` | `NSApplicationSupportDirectory` / `path_provider.getApplicationSupportDirectory()` |
| Android | `/data/data/<package>/files/…` | `Context.getFilesDir()` / `path_provider.getApplicationSupportDirectory()` |
| macOS | `~/Library/Application Support/<bundleId>/…` | `path_provider.getApplicationSupportDirectory()` |
| Linux | `$XDG_DATA_HOME/<app>/…` | `path_provider.getApplicationSupportDirectory()` |
| Windows | `%APPDATA%/<app>/…` | `path_provider.getApplicationSupportDirectory()` |

Rationale: installed bundles contain executable content (UI definitions,
flow steps, skill templates) and must live in a directory that:

- is private to the host process (no cross-app read on Android / iOS)
- is not backed up as user documents (`Documents/` on iOS exposes files
  to iCloud and the Files app — wrong surface for installed code)
- survives routine cache eviction (`Cache/` may be purged under memory
  pressure on iOS / Android — wrong placement)

`mcp_bundle` performs no path discovery. The host resolves the root via
the platform API above and injects it per call.

## Host Contract

- `installRoot` is a host-chosen path; `mcp_bundle` performs no path
  discovery.
- `RuntimeDescriptor` is host-declared; `mcp_bundle` does not know which
  runtime hosts it.
- `TrustStore` is host-provided; `mcp_bundle` holds no default trust
  anchors.
- Installed bundles are addressed by `bundleId` only. Hosts persist that
  id (and the observed `manifest.version` if they display it) — never the
  absolute install path.
- `McpBundleLoader.loadDirectory` remains usable outside the install
  lifecycle for library and server callers that consume `.mbd/` trees
  directly.
