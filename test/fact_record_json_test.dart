import 'dart:convert';
import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  test('FactRecord round-trips through JSON (persistent KV path)', () {
    final f = FactRecord(
      id: 'fact/q4', workspaceId: 'w1', type: 'fact',
      content: const {'value': 'Q4 revenue was 5.1 million USD.'},
      confidence: 0.9, evidenceRefs: const ['e1'],
      createdAt: DateTime.utc(2026, 6, 14),
    );
    final round = FactRecord.fromJson(
        jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>);
    expect(round.id, f.id);
    expect(round.type, 'fact');
    expect(round.content['value'], 'Q4 revenue was 5.1 million USD.');
    expect(round.evidenceRefs, ['e1']);
    expect(round.createdAt, f.createdAt);
  });

  test('encode-fallback (fork-KV) path serializes a fact list to maps', () {
    final f = FactRecord(id: 'x', workspaceId: 'w', type: 'fact',
      content: const {'value': 'launch code ZEBRA-9921'}, createdAt: DateTime.utc(2026));
    final encoded = jsonEncode(<FactRecord>[f], toEncodable: (o) => (o as dynamic).toJson());
    final decoded = jsonDecode(encoded) as List;
    expect((decoded.first as Map)['content']['value'], 'launch code ZEBRA-9921');
  });
}
