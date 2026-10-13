// `kind` is required on every tool (bundle spec 04 §4.2, §4.11): an omitted
// kind is rejected, never read as `host` — a tool cannot reach a host builtin
// by leaving it out.

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

List<ValidationError> _kindErrors(Map<String, dynamic> tool) {
  final bundle = McpBundle.fromJson({
    'manifest': {
      'id': 'com.example.kinds',
      'name': 'Kinds',
      'version': '1.0.0'
    },
    'tools': {
      'tools': [tool]
    },
  });
  return McpBundleValidator.validate(bundle)
      .errors
      .where((e) => e.location?.endsWith('.kind') ?? false)
      .toList();
}

void main() {
  test('an omitted kind is rejected, not read as host', () {
    final errors = _kindErrors({'name': 'save'});
    expect(errors, hasLength(1));
    expect(errors.single.message, contains('required'));
  });

  test('an unrecognized kind is rejected', () {
    expect(_kindErrors({'name': 'save', 'kind': 'shell'}), hasLength(1));
  });

  for (final kind in ['host', 'mcp', 'cloud', 'js', 'ts', 'HOST']) {
    test('$kind is accepted', () {
      expect(_kindErrors({'name': 'save', 'kind': kind}), isEmpty);
    });
  }
}
