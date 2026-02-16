/// Canonicalization utilities for MCP Bundle.
///
/// Provides consistent JSON normalization for hashing and comparison.
library;

import 'dart:convert';

/// Canonicalizes JSON data for consistent representation.
class Canonicalizer {
  const Canonicalizer();

  /// Canonicalize a JSON value to a normalized string.
  ///
  /// Rules:
  /// - Objects: keys sorted alphabetically
  /// - Arrays: preserved order
  /// - Numbers: normalized representation
  /// - Strings: escaped properly
  /// - Null values: preserved
  String canonicalize(dynamic value) {
    final buffer = StringBuffer();
    _writeCanonical(value, buffer);
    return buffer.toString();
  }

  /// Canonicalize to bytes (UTF-8 encoded).
  List<int> canonicalizeToBytes(dynamic value) {
    return utf8.encode(canonicalize(value));
  }

  void _writeCanonical(dynamic value, StringBuffer buffer) {
    if (value == null) {
      buffer.write('null');
    } else if (value is bool) {
      buffer.write(value ? 'true' : 'false');
    } else if (value is num) {
      _writeNumber(value, buffer);
    } else if (value is String) {
      _writeString(value, buffer);
    } else if (value is List) {
      _writeArray(value, buffer);
    } else if (value is Map<String, dynamic>) {
      _writeObject(value, buffer);
    } else if (value is Map) {
      _writeObject(
        value.map((k, v) => MapEntry(k.toString(), v)),
        buffer,
      );
    } else {
      _writeString(value.toString(), buffer);
    }
  }

  void _writeNumber(num value, StringBuffer buffer) {
    if (value.isNaN || value.isInfinite) {
      buffer.write('null');
      return;
    }

    if (value is int) {
      buffer.write(value.toString());
    } else {
      // Normalize double representation
      final d = value.toDouble();
      if (d == d.truncateToDouble()) {
        buffer.write(d.toInt().toString());
      } else {
        buffer.write(d.toString());
      }
    }
  }

  void _writeString(String value, StringBuffer buffer) {
    buffer.write('"');
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      final code = char.codeUnitAt(0);

      if (code == 0x22) {
        // "
        buffer.write(r'\"');
      } else if (code == 0x5C) {
        // \
        buffer.write(r'\\');
      } else if (code == 0x08) {
        // backspace
        buffer.write(r'\b');
      } else if (code == 0x0C) {
        // form feed
        buffer.write(r'\f');
      } else if (code == 0x0A) {
        // newline
        buffer.write(r'\n');
      } else if (code == 0x0D) {
        // carriage return
        buffer.write(r'\r');
      } else if (code == 0x09) {
        // tab
        buffer.write(r'\t');
      } else if (code < 0x20) {
        // Control characters
        buffer.write(r'\u');
        buffer.write(code.toRadixString(16).padLeft(4, '0'));
      } else {
        buffer.write(char);
      }
    }
    buffer.write('"');
  }

  void _writeArray(List<dynamic> value, StringBuffer buffer) {
    buffer.write('[');
    for (var i = 0; i < value.length; i++) {
      if (i > 0) buffer.write(',');
      _writeCanonical(value[i], buffer);
    }
    buffer.write(']');
  }

  void _writeObject(Map<String, dynamic> value, StringBuffer buffer) {
    buffer.write('{');

    // Sort keys alphabetically
    final sortedKeys = value.keys.toList()..sort();

    for (var i = 0; i < sortedKeys.length; i++) {
      if (i > 0) buffer.write(',');
      final key = sortedKeys[i];
      _writeString(key, buffer);
      buffer.write(':');
      _writeCanonical(value[key], buffer);
    }

    buffer.write('}');
  }
}

/// JSON deep equality comparison.
class JsonComparator {
  const JsonComparator();

  /// Compare two JSON values for deep equality.
  bool equals(dynamic a, dynamic b) {
    if (identical(a, b)) return true;

    if (a == null) return b == null;
    if (b == null) return false;

    if (a is Map<dynamic, dynamic> && b is Map<dynamic, dynamic>) {
      return _mapsEqual(a, b);
    }

    if (a is List<dynamic> && b is List<dynamic>) {
      return _listsEqual(a, b);
    }

    if (a is num && b is num) {
      if (a.isNaN && b.isNaN) return true;
      return a == b;
    }

    return a == b;
  }

  bool _mapsEqual(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!equals(a[key], b[key])) return false;
    }

    return true;
  }

  bool _listsEqual(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (!equals(a[i], b[i])) return false;
    }

    return true;
  }
}

/// Default canonicalizer instance.
const canonicalizer = Canonicalizer();

/// Default JSON comparator instance.
const jsonComparator = JsonComparator();

/// Canonicalize JSON value.
String canonicalizeJson(dynamic value) => canonicalizer.canonicalize(value);

/// Compare JSON values for equality.
bool jsonEquals(dynamic a, dynamic b) => jsonComparator.equals(a, b);
