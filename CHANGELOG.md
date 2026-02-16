## [0.1.0] - Initial Release

### Added

#### Core Features
- **Bundle Schema**
  - `McpBundle` model as the main container
  - `BundleSkill` for skill definitions
  - `BundleProfile` for profile definitions
  - `BundleKnowledge` for knowledge items
  - Metadata and versioning support

- **Bundle Loader**
  - `BundleLoader` for loading and saving bundles
  - File-based loading with `.mcpb` format
  - URL-based loading for remote bundles
  - JSON data loading for in-memory bundles
  - Bundle serialization and deserialization

- **Bundle Validator**
  - `BundleValidator` for comprehensive validation
  - Schema validation for all bundle components
  - Reference integrity checking
  - Warning and error reporting
  - Customizable validation rules

- **Expression Language**
  - `ExpressionEvaluator` for template processing
  - Mustache-style variable syntax `{{variable}}`
  - Conditional sections `{{#condition}}...{{/condition}}`
  - Inverted sections `{{^condition}}...{{/condition}}`
  - Array iteration `{{#array}}...{{/array}}`
  - Nested property access `{{user.address.city}}`
  - Built-in functions for data manipulation

- **Validation Results**
  - `BundleValidation` with errors and warnings
  - Detailed error messages with locations
  - Validation context for debugging

### Data Models
- `McpBundle` - Main bundle container
- `BundleSkill` - Skill definition in bundle
- `BundleProfile` - Profile definition in bundle
- `BundleKnowledge` - Knowledge item in bundle
- `BundleValidation` - Validation result

### Expression Features
- Variable interpolation
- Conditional rendering
- Array iteration
- Nested property access
- Function calls

---

## Support and Contributing

- [Report Issues](https://github.com/app-appplayer/mcp_bundle/issues)
- [Join Discussions](https://github.com/app-appplayer/mcp_bundle/discussions)
- [Read Documentation](https://github.com/app-appplayer/mcp_bundle/wiki)
- [Support Development](https://www.patreon.com/mcpdevstudio)
