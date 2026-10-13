// Access rights (bundle spec 02 §2.3.1, 04 §4.2).
//
// A bundle declares the access rights its tools are gated by and each tool
// names the one it needs; the host decides at call time. A bundle that
// declares nothing keeps working as before — every tool needs only the
// implicit `use` right.

import 'dart:convert';
import 'dart:io';

import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

Map<String, dynamic> _bundle({
  List<Map<String, dynamic>>? accessRights,
  List<Map<String, dynamic>> tools = const [],
}) =>
    {
      'manifest': {
        'id': 'com.example.attendance',
        'name': 'Attendance',
        'version': '1.0.0',
        if (accessRights != null) 'accessRights': accessRights,
      },
      if (tools.isNotEmpty)
        'tools': {
          'tools': [
            for (final t in tools) {'kind': 'host', ...t}
          ]
        },
    };

const _read = {
  'id': 'attendance.read',
  'label': {'en': 'View attendance', 'ko': '출결 보기'},
  'risk': 'read',
  'default': 'member',
};

const _write = {
  'id': 'attendance.write',
  'label': {'en': 'Record attendance'},
  'description': {'en': 'Create and change attendance records.'},
  'risk': 'write',
};

List<ValidationError> _errors(Map<String, dynamic> json) =>
    McpBundleValidator.validate(McpBundle.fromJson(json)).errors;

void main() {
  group('AccessRight model', () {
    test('reads every field and writes the same document back', () {
      final p = AccessRight.fromJson(Map<String, dynamic>.from(_write));
      expect(p.id, 'attendance.write');
      expect(p.label, {'en': 'Record attendance'});
      expect(p.description, {'en': 'Create and change attendance records.'});
      expect(p.risk, AccessRisk.write);
      expect(p.toJson()['default'], 'none',
          reason: 'a missing default grants nobody');
      expect(AccessRight.fromJson(p.toJson()).toJson(), p.toJson());
    });

    test('default reads member and admin', () {
      expect(AccessRight.fromJson(Map.from(_read)).defaultGrant,
          AccessDefault.member);
      expect(AccessRight.fromJson({..._read, 'default': 'admin'}).defaultGrant,
          AccessDefault.admin);
    });

    test('unrecognized risk and default are kept as unknown', () {
      final p = AccessRight.fromJson(
          {..._read, 'risk': 'nuclear', 'default': 'everyone'});
      expect(p.risk, AccessRisk.unknown);
      expect(p.defaultGrant, AccessDefault.unknown);
    });

    test('manifest carries the list through JSON', () {
      final bundle = McpBundle.fromJson(_bundle(accessRights: [_read, _write]));
      expect(bundle.manifest.accessRights.map((p) => p.id),
          ['attendance.read', 'attendance.write']);
      final again = McpBundle.fromJson(bundle.toJson());
      expect(again.manifest.accessRights.map((p) => p.toJson()),
          bundle.manifest.accessRights.map((p) => p.toJson()));
    });

    test('a tool carries accessRight and scoped through JSON', () {
      final tool = ToolEntry.fromJson({
        'name': 'recordAttendance',
        'accessRight': 'attendance.write',
        'scoped': true,
      });
      expect(tool.accessRight, 'attendance.write');
      expect(tool.scoped, isTrue);
      expect(tool.toJson()['accessRight'], 'attendance.write');
      expect(tool.toJson()['scoped'], isTrue);
    });

    test('a tool that names nothing writes neither field', () {
      final tool = ToolEntry.fromJson({'name': 'ping'});
      expect(tool.accessRight, isNull);
      expect(tool.scoped, isFalse);
      expect(tool.toJson().containsKey('accessRight'), isFalse);
      expect(tool.toJson().containsKey('scoped'), isFalse);
    });
  });

  group('validation', () {
    test('a bundle without access rights is valid as before', () {
      expect(
          _errors(_bundle(tools: [
            {'name': 'ping'},
            {'name': 'list', 'scoped': true},
          ])),
          isEmpty);
    });

    test('declared access rights and tools that name them are valid', () {
      expect(
          _errors(_bundle(accessRights: [
            _read,
            _write
          ], tools: [
            {'name': 'listAttendance', 'accessRight': 'attendance.read'},
            {
              'name': 'recordAttendance',
              'accessRight': 'attendance.write',
              'scoped': true,
            },
            {'name': 'ping'},
          ])),
          isEmpty);
    });

    test('a tool naming an undeclared access right is refused', () {
      final errors = _errors(_bundle(accessRights: [
        _read
      ], tools: [
        {'name': 'recordAttendance', 'accessRight': 'attendance.write'},
      ]));
      expect(errors.map((e) => e.code), [McpValidationCodes.unknownReference]);
      expect(errors.single.location, 'tools.tools[0].accessRight');
    });

    test('naming an access right with none declared is refused', () {
      final errors = _errors(_bundle(tools: [
        {'name': 'recordAttendance', 'accessRight': 'attendance.write'},
      ]));
      expect(errors.map((e) => e.code), [McpValidationCodes.unknownReference]);
    });

    final cases = <String, (Map<String, dynamic>, String, String)>{
      'empty id': (
        {..._read, 'id': ''},
        McpValidationCodes.missingRequired,
        'manifest.accessRights[0].id'
      ),
      'reserved id use': (
        {..._read, 'id': 'use'},
        McpValidationCodes.invalidValue,
        'manifest.accessRights[0].id'
      ),
      'id not lowercase dotted': (
        {..._read, 'id': 'Attendance-Read'},
        McpValidationCodes.invalidPattern,
        'manifest.accessRights[0].id'
      ),
      'no label': (
        {..._read}..remove('label'),
        McpValidationCodes.missingRequired,
        'manifest.accessRights[0].label'
      ),
      'empty label text': (
        {
          ..._read,
          'label': {'en': ''}
        },
        McpValidationCodes.missingRequired,
        'manifest.accessRights[0].label'
      ),
      'unknown risk': (
        {..._read, 'risk': 'nuclear'},
        McpValidationCodes.invalidValue,
        'manifest.accessRights[0].risk'
      ),
      'missing risk': (
        {..._read}..remove('risk'),
        McpValidationCodes.invalidValue,
        'manifest.accessRights[0].risk'
      ),
      'unknown default': (
        {..._read, 'default': 'everyone'},
        McpValidationCodes.invalidValue,
        'manifest.accessRights[0].default'
      ),
    };
    for (final entry in cases.entries) {
      test('refuses ${entry.key}', () {
        final (accessRight, code, location) = entry.value;
        final errors = _errors(_bundle(accessRights: [accessRight]));
        expect(errors.map((e) => (e.code, e.location)), [(code, location)]);
      });
    }

    test('refuses a duplicate id', () {
      final errors = _errors(_bundle(accessRights: [_read, _read]));
      expect(errors.map((e) => (e.code, e.location)),
          [(McpValidationCodes.duplicateId, 'manifest.accessRights[1].id')]);
    });
  });

  // The document consumers test against: what `bundle://manifest.json`
  // carries for a bundle that declares access rights. `tools` is the section
  // object, not a bare list.
  test('fixture access_rights/manifest.json is valid and round-trips', () {
    final text =
        File('test/fixtures/access_rights/manifest.json').readAsStringSync();
    final bundle = McpBundle.fromJson(jsonDecode(text) as Map<String, dynamic>);
    expect(McpBundleValidator.validate(bundle).errors, isEmpty);
    expect(bundle.manifest.accessRights, hasLength(3));
    expect(bundle.tools!.tools.where((t) => t.scoped), hasLength(2));
    final again =
        jsonDecode(jsonEncode(bundle.toJson())) as Map<String, dynamic>;
    expect(again['tools'], isA<Map<String, dynamic>>());
    expect((again['tools'] as Map<String, dynamic>)['tools'], hasLength(4));
  });
}
