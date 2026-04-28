/// One-shot CLI: pack a `.mbd/` directory into a `.mcpb` ZIP.
///
/// Usage: `dart run mcp_bundle:pack_mbd <mbdPath> <outputMcpb>`
library;

import 'dart:io';

import 'package:mcp_bundle/mcp_bundle.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln('Usage: dart run mcp_bundle:pack_mbd <mbdPath> <outputMcpb>');
    exitCode = 64; // EX_USAGE
    return;
  }
  final mbdPath = args[0];
  final outputPath = args[1];
  if (!Directory(mbdPath).existsSync()) {
    stderr.writeln('Not a directory: $mbdPath');
    exitCode = 66; // EX_NOINPUT
    return;
  }
  final bytes = await McpBundlePacker.packDirectory(mbdPath);
  await File(outputPath).writeAsBytes(bytes, flush: true);
  stdout.writeln('Wrote ${bytes.length} bytes to $outputPath');
}
