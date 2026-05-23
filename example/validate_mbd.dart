import 'dart:convert';
import 'dart:io';
import 'package:mcp_bundle/mcp_bundle.dart';

void main() async {
  final dir = '/Users/jsha/Desktop/Works/workspace/makemind/tools/builder/workspace/app_builder/app_builder.mbd';
  final raw = await File('$dir/manifest.json').readAsString();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final bundle = McpBundle.fromJson(json);
  final result = McpBundleValidator.validate(bundle);
  print('valid: ${result.isValid}');
  print('errors (${result.errors.length}):');
  for (final e in result.errors) print('  $e');
  print('warnings (${result.warnings.length}):');
  for (final w in result.warnings) print('  $w');
}
