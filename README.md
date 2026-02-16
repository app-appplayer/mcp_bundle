# MCP Bundle

## Support This Project

If you find this package useful, consider supporting ongoing development on PayPal.

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/ncp/payment/F7G56QD9LSJ92)
Support makemind via [PayPal](https://www.paypal.com/ncp/payment/F7G56QD9LSJ92)

---

### MCP Knowledge Package Family

- [`mcp_bundle`](https://pub.dev/packages/mcp_bundle): Bundle schema, loader, validator, and expression language for MCP ecosystem.
- [`mcp_fact_graph`](https://pub.dev/packages/mcp_fact_graph): Temporal knowledge graph with evidence-based fact management and summarization.
- [`mcp_skill`](https://pub.dev/packages/mcp_skill): Skill definitions and runtime execution for AI capabilities.
- [`mcp_profile`](https://pub.dev/packages/mcp_profile): Profile definitions for AI personas with template rendering and appraisal.
- [`mcp_knowledge_ops`](https://pub.dev/packages/mcp_knowledge_ops): Knowledge operations including pipelines, workflows, and scheduling.
- [`mcp_knowledge`](https://pub.dev/packages/mcp_knowledge): Unified integration package for the complete knowledge system.

---

A foundational Dart package providing bundle schema definitions, loading, validation, and expression language for the MCP ecosystem. This is the core package that other MCP knowledge packages depend on.

## Features

### Core Features
- **Bundle Schema**: Define and structure MCP bundles with skills, profiles, and knowledge
- **Bundle Loader**: Load bundles from files, URLs, or raw data
- **Bundle Validator**: Validate bundle structure and content
- **Expression Language**: Powerful expression evaluation for dynamic content

### Bundle Model
- **Skills**: Skill definitions within bundles
- **Profiles**: Profile definitions within bundles
- **Knowledge**: Knowledge items within bundles
- **Metadata**: Bundle versioning and metadata

### Expression Language
- **Variable Access**: `{{variable}}` syntax
- **Conditionals**: `{{#condition}}...{{/condition}}`
- **Loops**: `{{#array}}...{{/array}}`
- **Functions**: Built-in functions for data manipulation

## Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  mcp_bundle: ^0.1.0
```

### Basic Usage

```dart
import 'package:mcp_bundle/mcp_bundle.dart';

void main() async {
  // Create a bundle
  final bundle = McpBundle(
    id: 'my_bundle',
    name: 'My AI Bundle',
    version: '1.0.0',
    skills: [
      BundleSkill(
        id: 'summarizer',
        name: 'Text Summarizer',
        description: 'Summarizes text content',
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

  // Validate bundle
  final validator = BundleValidator();
  final validation = await validator.validate(bundle);

  if (validation.isValid) {
    print('Bundle is valid!');
  } else {
    print('Errors: ${validation.errors}');
  }

  // Save bundle
  final loader = BundleLoader();
  await loader.save(bundle, 'my_bundle.mcpb');
}
```

## Core Concepts

### McpBundle

The main bundle container:

```dart
final bundle = McpBundle(
  id: 'customer_service',
  name: 'Customer Service AI',
  version: '2.0.0',
  description: 'AI capabilities for customer service',
  skills: [...],
  profiles: [...],
  knowledge: [...],
  metadata: {
    'author': 'MakeMind',
    'category': 'customer-service',
  },
);
```

### Bundle Loader

Load and save bundles:

```dart
final loader = BundleLoader();

// Load from file
final bundle = await loader.load('path/to/bundle.mcpb');

// Load from URL
final remoteBundle = await loader.loadFromUrl('https://example.com/bundle.mcpb');

// Load from raw data
final dataBundle = await loader.loadFromJson(jsonData);

// Save bundle
await loader.save(bundle, 'output.mcpb');
```

### Bundle Validator

Validate bundle structure and content:

```dart
final validator = BundleValidator();

final validation = await validator.validate(bundle);

print('Valid: ${validation.isValid}');
print('Errors: ${validation.errors}');
print('Warnings: ${validation.warnings}');

// Validate specific parts
final skillValidation = await validator.validateSkills(bundle.skills);
final profileValidation = await validator.validateProfiles(bundle.profiles);
```

### Expression Language

Evaluate expressions with context:

```dart
final expression = ExpressionEvaluator();

// Simple variable access
final result = expression.evaluate(
  '{{user.name}}',
  {'user': {'name': 'John'}},
);
// Result: 'John'

// Conditional sections
final conditional = expression.evaluate(
  '{{#isPremium}}Premium features enabled{{/isPremium}}',
  {'isPremium': true},
);
// Result: 'Premium features enabled'

// Array iteration
final loop = expression.evaluate(
  '{{#items}}Item: {{name}}\n{{/items}}',
  {'items': [{'name': 'A'}, {'name': 'B'}]},
);
// Result: 'Item: A\nItem: B\n'
```

## Bundle Schema

### Skills in Bundle

```dart
BundleSkill(
  id: 'analyzer',
  name: 'Text Analyzer',
  description: 'Analyzes text content',
  inputSchema: {
    'type': 'object',
    'properties': {
      'text': {'type': 'string'},
    },
  },
  outputSchema: {
    'type': 'object',
    'properties': {
      'sentiment': {'type': 'string'},
      'topics': {'type': 'array'},
    },
  },
  executor: 'llm',
  prompt: 'Analyze: {{input.text}}',
  tags: ['nlp', 'analysis'],
)
```

### Profiles in Bundle

```dart
BundleProfile(
  id: 'expert',
  name: 'Domain Expert',
  description: 'Expert in specific domain',
  systemPrompt: '''
You are an expert in {{domain}}.
Help the user with {{task}}.
''',
  variables: ['domain', 'task'],
  tags: ['expert'],
)
```

### Knowledge in Bundle

```dart
BundleKnowledge(
  id: 'faq',
  name: 'FAQ Knowledge',
  type: 'document',
  content: 'Frequently asked questions...',
  metadata: {
    'source': 'internal',
    'lastUpdated': '2025-01-01',
  },
)
```

## API Reference

### BundleLoader

| Method | Description |
|--------|-------------|
| `load(path)` | Load bundle from file |
| `loadFromUrl(url)` | Load bundle from URL |
| `loadFromJson(json)` | Load from JSON data |
| `save(bundle, path)` | Save bundle to file |

### BundleValidator

| Method | Description |
|--------|-------------|
| `validate(bundle)` | Validate entire bundle |
| `validateSkills(skills)` | Validate skills |
| `validateProfiles(profiles)` | Validate profiles |
| `validateKnowledge(knowledge)` | Validate knowledge |

### ExpressionEvaluator

| Method | Description |
|--------|-------------|
| `evaluate(template, context)` | Evaluate expression |
| `validate(template)` | Validate expression syntax |
| `extractVariables(template)` | Extract variable names |

## Examples

### Complete Examples Available
- `example/basic_bundle.dart` - Basic bundle creation
- `example/bundle_loading.dart` - Loading and saving bundles
- `example/expression_language.dart` - Expression evaluation
- `example/validation.dart` - Bundle validation

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## Support

- [Documentation](https://github.com/app-appplayer/mcp_bundle/wiki)
- [Issue Tracker](https://github.com/app-appplayer/mcp_bundle/issues)
- [Discussions](https://github.com/app-appplayer/mcp_bundle/discussions)
- [Support on Patreon](https://www.patreon.com/mcpdevstudio)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
