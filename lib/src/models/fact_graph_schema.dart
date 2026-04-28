/// FactGraph schema model.
///
/// Schema definitions for FactGraph entities and relations.
/// Used for validation in 04-validator.md Section 6.
/// Design: 02-models-design.md Section 4.7
library;

/// Schema definitions for FactGraph entities and relations.
class FactGraphSchema {
  /// Entity type definitions.
  final List<EntityTypeDefinition> entityTypes;

  /// Relation type definitions.
  final List<RelationTypeDefinition> relationTypes;

  /// Fact type definitions.
  final List<FactTypeDefinition> factTypes;

  const FactGraphSchema({
    this.entityTypes = const [],
    this.relationTypes = const [],
    this.factTypes = const [],
  });

  /// Create from JSON.
  factory FactGraphSchema.fromJson(Map<String, dynamic> json) {
    return FactGraphSchema(
      entityTypes: (json['entityTypes'] as List<dynamic>?)
              ?.map((e) => EntityTypeDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      relationTypes: (json['relationTypes'] as List<dynamic>?)
              ?.map((e) => RelationTypeDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      factTypes: (json['factTypes'] as List<dynamic>?)
              ?.map((e) => FactTypeDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      if (entityTypes.isNotEmpty)
        'entityTypes': entityTypes.map((e) => e.toJson()).toList(),
      if (relationTypes.isNotEmpty)
        'relationTypes': relationTypes.map((r) => r.toJson()).toList(),
      if (factTypes.isNotEmpty)
        'factTypes': factTypes.map((f) => f.toJson()).toList(),
    };
  }

  /// Create a copy with modifications.
  FactGraphSchema copyWith({
    List<EntityTypeDefinition>? entityTypes,
    List<RelationTypeDefinition>? relationTypes,
    List<FactTypeDefinition>? factTypes,
  }) {
    return FactGraphSchema(
      entityTypes: entityTypes ?? this.entityTypes,
      relationTypes: relationTypes ?? this.relationTypes,
      factTypes: factTypes ?? this.factTypes,
    );
  }

  /// Find entity type by name.
  EntityTypeDefinition? findEntityType(String name) {
    return entityTypes.where((e) => e.name == name).firstOrNull;
  }

  /// Find relation type by name.
  RelationTypeDefinition? findRelationType(String name) {
    return relationTypes.where((r) => r.name == name).firstOrNull;
  }

  /// Find fact type by name.
  FactTypeDefinition? findFactType(String name) {
    return factTypes.where((f) => f.name == name).firstOrNull;
  }

  /// Check if schema is empty.
  bool get isEmpty =>
      entityTypes.isEmpty && relationTypes.isEmpty && factTypes.isEmpty;

  /// Check if schema is not empty.
  bool get isNotEmpty => !isEmpty;
}

/// Entity type definition for FactGraph schema.
class EntityTypeDefinition {
  /// Type name (e.g., "Person", "Organization").
  final String name;

  /// Human-readable description.
  final String? description;

  /// Property definitions.
  final List<PropertyDefinition> properties;

  /// Names of required properties.
  final List<String> requiredProperties;

  /// Parent type for inheritance.
  final String? extendsType;

  /// Whether this type is abstract (cannot be instantiated directly).
  final bool isAbstract;

  const EntityTypeDefinition({
    required this.name,
    this.description,
    this.properties = const [],
    this.requiredProperties = const [],
    this.extendsType,
    this.isAbstract = false,
  });

  /// Create from JSON.
  factory EntityTypeDefinition.fromJson(Map<String, dynamic> json) {
    return EntityTypeDefinition(
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      properties: (json['properties'] as List<dynamic>?)
              ?.map((e) => PropertyDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      requiredProperties: (json['requiredProperties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      extendsType: json['extends'] as String?,
      isAbstract: json['abstract'] as bool? ?? false,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (properties.isNotEmpty)
        'properties': properties.map((p) => p.toJson()).toList(),
      if (requiredProperties.isNotEmpty)
        'requiredProperties': requiredProperties,
      if (extendsType != null) 'extends': extendsType,
      if (isAbstract) 'abstract': isAbstract,
    };
  }

  /// Create a copy with modifications.
  EntityTypeDefinition copyWith({
    String? name,
    String? description,
    List<PropertyDefinition>? properties,
    List<String>? requiredProperties,
    String? extendsType,
    bool? isAbstract,
  }) {
    return EntityTypeDefinition(
      name: name ?? this.name,
      description: description ?? this.description,
      properties: properties ?? this.properties,
      requiredProperties: requiredProperties ?? this.requiredProperties,
      extendsType: extendsType ?? this.extendsType,
      isAbstract: isAbstract ?? this.isAbstract,
    );
  }

  /// Find property by name.
  PropertyDefinition? findProperty(String propertyName) {
    return properties.where((p) => p.name == propertyName).firstOrNull;
  }

  /// Check if a property is required.
  bool isPropertyRequired(String propertyName) {
    return requiredProperties.contains(propertyName);
  }
}

/// Relation type definition for FactGraph schema.
class RelationTypeDefinition {
  /// Relation type name (e.g., "worksFor", "locatedIn").
  final String name;

  /// Human-readable description.
  final String? description;

  /// Source entity type.
  final String fromEntityType;

  /// Target entity type.
  final String toEntityType;

  /// Additional property definitions.
  final List<PropertyDefinition> properties;

  /// Cardinality constraint for source side.
  final Cardinality fromCardinality;

  /// Cardinality constraint for target side.
  final Cardinality toCardinality;

  /// Whether this relation is bidirectional.
  final bool bidirectional;

  /// Inverse relation name (for bidirectional relations).
  final String? inverseName;

  const RelationTypeDefinition({
    required this.name,
    this.description,
    required this.fromEntityType,
    required this.toEntityType,
    this.properties = const [],
    this.fromCardinality = Cardinality.many,
    this.toCardinality = Cardinality.many,
    this.bidirectional = false,
    this.inverseName,
  });

  /// Create from JSON.
  factory RelationTypeDefinition.fromJson(Map<String, dynamic> json) {
    return RelationTypeDefinition(
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      fromEntityType: json['fromEntityType'] as String? ?? json['from'] as String? ?? '',
      toEntityType: json['toEntityType'] as String? ?? json['to'] as String? ?? '',
      properties: (json['properties'] as List<dynamic>?)
              ?.map((e) => PropertyDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      fromCardinality: Cardinality.fromString(json['fromCardinality'] as String?),
      toCardinality: Cardinality.fromString(json['toCardinality'] as String?),
      bidirectional: json['bidirectional'] as bool? ?? false,
      inverseName: json['inverseName'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'fromEntityType': fromEntityType,
      'toEntityType': toEntityType,
      if (properties.isNotEmpty)
        'properties': properties.map((p) => p.toJson()).toList(),
      'fromCardinality': fromCardinality.name,
      'toCardinality': toCardinality.name,
      if (bidirectional) 'bidirectional': bidirectional,
      if (inverseName != null) 'inverseName': inverseName,
    };
  }

  /// Create a copy with modifications.
  RelationTypeDefinition copyWith({
    String? name,
    String? description,
    String? fromEntityType,
    String? toEntityType,
    List<PropertyDefinition>? properties,
    Cardinality? fromCardinality,
    Cardinality? toCardinality,
    bool? bidirectional,
    String? inverseName,
  }) {
    return RelationTypeDefinition(
      name: name ?? this.name,
      description: description ?? this.description,
      fromEntityType: fromEntityType ?? this.fromEntityType,
      toEntityType: toEntityType ?? this.toEntityType,
      properties: properties ?? this.properties,
      fromCardinality: fromCardinality ?? this.fromCardinality,
      toCardinality: toCardinality ?? this.toCardinality,
      bidirectional: bidirectional ?? this.bidirectional,
      inverseName: inverseName ?? this.inverseName,
    );
  }
}

/// Cardinality constraints for relations.
enum Cardinality {
  /// Exactly one.
  one,

  /// Zero or one.
  zeroOrOne,

  /// Zero or more.
  many,

  /// One or more.
  oneOrMore;

  static Cardinality fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'one':
      case '1':
        return Cardinality.one;
      case 'zeroorone':
      case '0..1':
        return Cardinality.zeroOrOne;
      case 'oneormore':
      case '1..*':
        return Cardinality.oneOrMore;
      case 'many':
      case '*':
      case '0..*':
      default:
        return Cardinality.many;
    }
  }
}

/// Fact type definition for FactGraph schema.
class FactTypeDefinition {
  /// Fact type name (e.g., "birthDate", "revenue").
  final String name;

  /// Human-readable description.
  final String? description;

  /// Value type: "string", "number", "boolean", "date", "datetime", "json".
  final String valueType;

  /// Valid sources for this fact type.
  final List<String> validSources;

  /// Whether this fact requires temporal tracking.
  final bool temporal;

  /// Unit of measurement (for numeric facts).
  final String? unit;

  /// Validation pattern (regex for string types).
  final String? pattern;

  /// Minimum value (for numeric types).
  final double? minValue;

  /// Maximum value (for numeric types).
  final double? maxValue;

  /// Allowed values (for enum-like facts).
  final List<String>? allowedValues;

  const FactTypeDefinition({
    required this.name,
    this.description,
    required this.valueType,
    this.validSources = const [],
    this.temporal = false,
    this.unit,
    this.pattern,
    this.minValue,
    this.maxValue,
    this.allowedValues,
  });

  /// Create from JSON.
  factory FactTypeDefinition.fromJson(Map<String, dynamic> json) {
    return FactTypeDefinition(
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      valueType: json['valueType'] as String? ?? 'string',
      validSources: (json['validSources'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      temporal: json['temporal'] as bool? ?? false,
      unit: json['unit'] as String?,
      pattern: json['pattern'] as String?,
      minValue: (json['minValue'] as num?)?.toDouble(),
      maxValue: (json['maxValue'] as num?)?.toDouble(),
      allowedValues: (json['allowedValues'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'valueType': valueType,
      if (validSources.isNotEmpty) 'validSources': validSources,
      if (temporal) 'temporal': temporal,
      if (unit != null) 'unit': unit,
      if (pattern != null) 'pattern': pattern,
      if (minValue != null) 'minValue': minValue,
      if (maxValue != null) 'maxValue': maxValue,
      if (allowedValues != null) 'allowedValues': allowedValues,
    };
  }

  /// Create a copy with modifications.
  FactTypeDefinition copyWith({
    String? name,
    String? description,
    String? valueType,
    List<String>? validSources,
    bool? temporal,
    String? unit,
    String? pattern,
    double? minValue,
    double? maxValue,
    List<String>? allowedValues,
  }) {
    return FactTypeDefinition(
      name: name ?? this.name,
      description: description ?? this.description,
      valueType: valueType ?? this.valueType,
      validSources: validSources ?? this.validSources,
      temporal: temporal ?? this.temporal,
      unit: unit ?? this.unit,
      pattern: pattern ?? this.pattern,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      allowedValues: allowedValues ?? this.allowedValues,
    );
  }

  /// Validate a value against this fact type definition.
  bool validateValue(dynamic value) {
    if (value == null) return true; // Null is always valid (optionality is handled elsewhere)

    switch (valueType) {
      case 'string':
        if (value is! String) return false;
        if (pattern != null) {
          final regex = RegExp(pattern!);
          if (!regex.hasMatch(value)) return false;
        }
        if (allowedValues != null && !allowedValues!.contains(value)) {
          return false;
        }
        return true;

      case 'number':
      case 'integer':
      case 'double':
        if (value is! num) return false;
        if (minValue != null && value < minValue!) return false;
        if (maxValue != null && value > maxValue!) return false;
        return true;

      case 'boolean':
        return value is bool;

      case 'date':
      case 'datetime':
        if (value is DateTime) return true;
        if (value is String) {
          try {
            DateTime.parse(value);
            return true;
          } catch (_) {
            return false;
          }
        }
        return false;

      case 'json':
      case 'object':
      case 'map':
        return value is Map;

      case 'array':
      case 'list':
        return value is List;

      default:
        return true;
    }
  }
}

/// Property definition for entities and relations.
class PropertyDefinition {
  /// Property name.
  final String name;

  /// Property type: "string", "number", "boolean", "date", "list", "map".
  final String type;

  /// Whether this property is required.
  final bool required;

  /// Default value if not provided.
  final dynamic defaultValue;

  /// Human-readable description.
  final String? description;

  /// Whether the property value should be unique.
  final bool unique;

  /// Whether the property should be indexed for queries.
  final bool indexed;

  /// Validation pattern (for string types).
  final String? pattern;

  /// Minimum value (for numeric types).
  final double? minValue;

  /// Maximum value (for numeric types).
  final double? maxValue;

  /// Minimum length (for string/list types).
  final int? minLength;

  /// Maximum length (for string/list types).
  final int? maxLength;

  /// Element type for list properties.
  final String? elementType;

  /// Allowed values for enum-like properties.
  final List<String>? allowedValues;

  const PropertyDefinition({
    required this.name,
    required this.type,
    this.required = false,
    this.defaultValue,
    this.description,
    this.unique = false,
    this.indexed = false,
    this.pattern,
    this.minValue,
    this.maxValue,
    this.minLength,
    this.maxLength,
    this.elementType,
    this.allowedValues,
  });

  /// Create from JSON.
  factory PropertyDefinition.fromJson(Map<String, dynamic> json) {
    return PropertyDefinition(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'string',
      required: json['required'] as bool? ?? false,
      defaultValue: json['default'] ?? json['defaultValue'],
      description: json['description'] as String?,
      unique: json['unique'] as bool? ?? false,
      indexed: json['indexed'] as bool? ?? false,
      pattern: json['pattern'] as String?,
      minValue: (json['minValue'] as num?)?.toDouble(),
      maxValue: (json['maxValue'] as num?)?.toDouble(),
      minLength: json['minLength'] as int?,
      maxLength: json['maxLength'] as int?,
      elementType: json['elementType'] as String?,
      allowedValues: (json['allowedValues'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      if (required) 'required': required,
      if (defaultValue != null) 'default': defaultValue,
      if (description != null) 'description': description,
      if (unique) 'unique': unique,
      if (indexed) 'indexed': indexed,
      if (pattern != null) 'pattern': pattern,
      if (minValue != null) 'minValue': minValue,
      if (maxValue != null) 'maxValue': maxValue,
      if (minLength != null) 'minLength': minLength,
      if (maxLength != null) 'maxLength': maxLength,
      if (elementType != null) 'elementType': elementType,
      if (allowedValues != null) 'allowedValues': allowedValues,
    };
  }

  /// Create a copy with modifications.
  PropertyDefinition copyWith({
    String? name,
    String? type,
    bool? required,
    dynamic defaultValue,
    String? description,
    bool? unique,
    bool? indexed,
    String? pattern,
    double? minValue,
    double? maxValue,
    int? minLength,
    int? maxLength,
    String? elementType,
    List<String>? allowedValues,
  }) {
    return PropertyDefinition(
      name: name ?? this.name,
      type: type ?? this.type,
      required: required ?? this.required,
      defaultValue: defaultValue ?? this.defaultValue,
      description: description ?? this.description,
      unique: unique ?? this.unique,
      indexed: indexed ?? this.indexed,
      pattern: pattern ?? this.pattern,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      elementType: elementType ?? this.elementType,
      allowedValues: allowedValues ?? this.allowedValues,
    );
  }

  /// Validate a value against this property definition.
  bool validateValue(dynamic value) {
    // Handle null/missing values
    if (value == null) {
      return !required || defaultValue != null;
    }

    // Type validation
    switch (type) {
      case 'string':
        if (value is! String) return false;
        if (minLength != null && value.length < minLength!) return false;
        if (maxLength != null && value.length > maxLength!) return false;
        if (pattern != null) {
          final regex = RegExp(pattern!);
          if (!regex.hasMatch(value)) return false;
        }
        if (allowedValues != null && !allowedValues!.contains(value)) {
          return false;
        }
        return true;

      case 'number':
      case 'integer':
      case 'double':
        if (value is! num) return false;
        if (minValue != null && value < minValue!) return false;
        if (maxValue != null && value > maxValue!) return false;
        return true;

      case 'boolean':
        return value is bool;

      case 'date':
      case 'datetime':
        if (value is DateTime) return true;
        if (value is String) {
          try {
            DateTime.parse(value);
            return true;
          } catch (_) {
            return false;
          }
        }
        return false;

      case 'list':
      case 'array':
        if (value is! List) return false;
        if (minLength != null && value.length < minLength!) return false;
        if (maxLength != null && value.length > maxLength!) return false;
        return true;

      case 'map':
      case 'object':
        return value is Map;

      default:
        return true;
    }
  }
}
