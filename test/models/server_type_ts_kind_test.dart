import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

/// `BundleType.server` + `ToolKind.ts` round-trip (marketplace server
/// authoring). The canonical packer parses the manifest into models and
/// re-serializes — before these enum values existed, `type: "server"` and
/// `kind: "ts"` were normalized to `"unknown"`, losing the values that drive
/// server-listing derivation and the ts build.
void main() {
  test('BundleType.server round-trips through fromString/name', () {
    expect(BundleType.fromString('server'), BundleType.server);
    expect(BundleType.server.name, 'server');
    // Unknown values still normalize.
    expect(BundleType.fromString('nonsense'), BundleType.unknown);
  });

  test('ToolKind.ts round-trips through fromString/wireValue', () {
    expect(ToolKind.fromString('ts'), ToolKind.ts);
    expect(ToolKind.fromString('TS'), ToolKind.ts); // case-insensitive
    expect(ToolKind.ts.wireValue, 'ts');
    expect(ToolKind.fromString('nonsense'), ToolKind.unknown);
  });

  test('manifest with type server + kind ts survives model round-trip',
      () {
    final manifest = BundleManifest.fromJson(const {
      'id': 'com.example.tsserver',
      'name': 'TS Tool Server',
      'version': '1.0.0',
      'type': 'server',
    });
    expect(manifest.type, BundleType.server);
    expect(manifest.toJson()['type'], 'server');

    final tools = ToolsSection.fromJson(const {
      'tools': [
        {
          'name': 'verify.now',
          'kind': 'ts',
          'target': {'entry': 'tools/verify.ts', 'fn': 'now'},
        }
      ],
    });
    expect(tools.tools.single.kind, ToolKind.ts);
    expect(tools.toJson()['tools'][0]['kind'], 'ts');
  });
}
