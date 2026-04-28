/// Expression Port - Template formatting and style rendering.
///
/// Capability-named port for template interpolation and style-driven
/// rendering. Extracted from `knowledge_ports.dart` per REDESIGN-PLAN.md
/// Phase 1a (0.1.0-a2). Resolves mcp_bundle/mcp_profile duplication —
/// this is the canonical single source of truth.
///
/// Provider: `mcp_profile` (expression layer).
library;

import '../types/expression_style.dart';

/// Port for expression/template formatting operations.
///
/// Used by the profile system to render templates with variables and
/// apply expression styles.
abstract class ExpressionPort {
  /// Format a template with variables.
  String format(String template, Map<String, dynamic> variables);

  /// Validate a template.
  bool validate(String template);

  /// Extract variable names from template.
  List<String> extractVariables(String template);

  /// Render a style onto data (optional capability — default throws).
  ///
  /// Providers that apply `ExpressionStyle` to structured data can
  /// override this. The default implementation throws [UnsupportedError]
  /// so that simple consumers can ignore it.
  String render(ExpressionStyle style, Map<String, dynamic> data) {
    throw UnsupportedError(
      'ExpressionPort.render is not supported by this provider',
    );
  }
}

/// Stub expression port for testing.
class StubExpressionPort implements ExpressionPort {
  const StubExpressionPort();

  @override
  String format(String template, Map<String, dynamic> variables) {
    var result = template;
    for (final entry in variables.entries) {
      result = result.replaceAll('{{${entry.key}}}', '${entry.value}');
    }
    return result;
  }

  @override
  bool validate(String template) {
    return true;
  }

  @override
  List<String> extractVariables(String template) {
    final regex = RegExp(r'\{\{(\w+)\}\}');
    return regex.allMatches(template).map((m) => m.group(1)!).toList();
  }

  @override
  String render(ExpressionStyle style, Map<String, dynamic> data) {
    return data.toString();
  }
}
