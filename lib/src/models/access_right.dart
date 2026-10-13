/// Access rights a bundle declares for its own tools — who may use which
/// part of the app. Distinct from the UI DSL's device and client
/// permissions (`permissions`, the `permission` action).
///
/// The bundle only declares them. Whether a caller holds a right is
/// decided by the host at call time; a bundle carries no checking code.
library;

/// The right every installed app has. A tool that names no access right
/// requires this one only, so it is reserved and cannot be declared.
const String implicitUseAccessRight = 'use';

/// How much an access right lets its holder do.
enum AccessRisk {
  /// Reads records.
  read,

  /// Creates or changes records.
  write,

  /// Deletes records or acts outside the app (payments, messages, devices).
  danger,

  /// Unrecognized value — kept for forward compatibility, rejected by the
  /// validator.
  unknown;

  /// Parse from the wire value. Unrecognized or missing values map to
  /// [unknown].
  static AccessRisk fromString(String? value) {
    for (final risk in values) {
      if (risk != unknown && risk.name == value) return risk;
    }
    return unknown;
  }
}

/// Who holds an access right once the app is installed, before anyone
/// changes it.
enum AccessDefault {
  /// Nobody until it is granted.
  none,

  /// Everyone who may use the app.
  member,

  /// Only the installation's administrators.
  admin,

  /// Unrecognized value — kept for forward compatibility, rejected by the
  /// validator.
  unknown;

  /// Parse from the wire value. A missing value is [none]; an unrecognized
  /// one is [unknown].
  static AccessDefault fromString(String? value) {
    if (value == null) return none;
    for (final level in values) {
      if (level != unknown && level.name == value) return level;
    }
    return unknown;
  }
}

/// One entry in the manifest's `accessRights` list.
class AccessRight {
  /// Identifier unique within the bundle, lowercase and dotted
  /// (`attendance.read`). Tools refer to it by this value.
  final String id;

  /// Display name by language tag (`en`, `ko`, ...). At least one entry.
  final Map<String, String> label;

  /// Optional explanation by language tag.
  final Map<String, String>? description;

  /// How much the right lets its holder do.
  final AccessRisk risk;

  /// Who holds it right after install. Wire key `default`.
  final AccessDefault defaultGrant;

  const AccessRight({
    required this.id,
    required this.label,
    this.description,
    required this.risk,
    this.defaultGrant = AccessDefault.none,
  });

  /// Create from JSON.
  factory AccessRight.fromJson(Map<String, dynamic> json) {
    return AccessRight(
      id: json['id'] as String? ?? '',
      label: _parseText(json['label']) ?? const {},
      description: _parseText(json['description']),
      risk: AccessRisk.fromString(json['risk'] as String?),
      defaultGrant: AccessDefault.fromString(json['default'] as String?),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (description != null) 'description': description,
        'risk': risk.name,
        'default': defaultGrant.name,
      };

  static Map<String, String>? _parseText(Object? value) {
    if (value is! Map) return null;
    return {
      for (final entry in value.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }
}
