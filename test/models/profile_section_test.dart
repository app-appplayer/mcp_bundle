import 'package:mcp_bundle/mcp_bundle.dart';
import 'package:test/test.dart';

void main() {
  group('ProfilesSection', () {
    test('creates with defaults', () {
      const section = ProfilesSection();
      expect(section.profiles, isEmpty);
      expect(section.isEmpty, isTrue);
      expect(section.isNotEmpty, isFalse);
    });

    test('fromJson with profiles', () {
      final section = ProfilesSection.fromJson({
        'profiles': [
          {'id': 'p1', 'name': 'Profile 1'},
          {'id': 'p2', 'name': 'Profile 2'},
        ],
      });
      expect(section.profiles, hasLength(2));
      expect(section.isEmpty, isFalse);
      expect(section.isNotEmpty, isTrue);
    });

    test('fromJson with empty map', () {
      final section = ProfilesSection.fromJson({});
      expect(section.profiles, isEmpty);
    });

    test('fromJson with null profiles', () {
      final section = ProfilesSection.fromJson({'profiles': null});
      expect(section.profiles, isEmpty);
    });

    test('toJson', () {
      const section = ProfilesSection(
        profiles: [
          ProfileDefinition(id: 'p1', name: 'Profile 1'),
        ],
      );
      final json = section.toJson();
      expect(json['profiles'], hasLength(1));
      expect(
        (json['profiles'] as List<Map<String, dynamic>>).first['id'],
        'p1',
      );
    });

    test('getProfile found', () {
      const section = ProfilesSection(
        profiles: [
          ProfileDefinition(id: 'p1', name: 'Profile 1'),
          ProfileDefinition(id: 'p2', name: 'Profile 2'),
        ],
      );
      final profile = section.getProfile('p2');
      expect(profile, isNotNull);
      expect(profile!.id, 'p2');
      expect(profile.name, 'Profile 2');
    });

    test('getProfile not found', () {
      const section = ProfilesSection(
        profiles: [
          ProfileDefinition(id: 'p1', name: 'Profile 1'),
        ],
      );
      expect(section.getProfile('nonexistent'), isNull);
    });

    test('getProfile empty profiles', () {
      const section = ProfilesSection();
      expect(section.getProfile('any'), isNull);
    });

    test('copyWith profiles', () {
      const section = ProfilesSection(
        profiles: [ProfileDefinition(id: 'p1', name: 'Old')],
      );
      final updated = section.copyWith(
        profiles: [const ProfileDefinition(id: 'p2', name: 'New')],
      );
      expect(updated.profiles, hasLength(1));
      expect(updated.profiles.first.id, 'p2');
    });

    test('copyWith null preserves original', () {
      const section = ProfilesSection(
        profiles: [ProfileDefinition(id: 'p1', name: 'Original')],
      );
      final copy = section.copyWith();
      expect(copy.profiles, hasLength(1));
      expect(copy.profiles.first.id, 'p1');
    });
  });

  group('ProfileDefinition', () {
    test('creates with required fields', () {
      const profile = ProfileDefinition(id: 'p1', name: 'Test');
      expect(profile.id, 'p1');
      expect(profile.name, 'Test');
      expect(profile.description, isNull);
      expect(profile.version, '1.0.0');
      expect(profile.sections, isEmpty);
      expect(profile.capabilities, isEmpty);
      expect(profile.variables, isEmpty);
      expect(profile.metadata, isEmpty);
    });

    test('fromJson with all fields', () {
      final profile = ProfileDefinition.fromJson({
        'id': 'p1',
        'name': 'Profile 1',
        'description': 'Test profile',
        'version': '2.0.0',
        'sections': [
          {'name': 'intro', 'content': 'Hello'},
        ],
        'capabilities': ['llm', 'rag'],
        'variables': {'model': 'gpt-4'},
        'metadata': {'author': 'test'},
      });
      expect(profile.id, 'p1');
      expect(profile.name, 'Profile 1');
      expect(profile.description, 'Test profile');
      expect(profile.version, '2.0.0');
      expect(profile.sections, hasLength(1));
      expect(profile.capabilities, ['llm', 'rag']);
      expect(profile.variables, {'model': 'gpt-4'});
      expect(profile.metadata, {'author': 'test'});
    });

    test('fromJson defaults', () {
      final profile = ProfileDefinition.fromJson({});
      expect(profile.id, '');
      expect(profile.name, '');
      expect(profile.version, '1.0.0');
      expect(profile.sections, isEmpty);
      expect(profile.capabilities, isEmpty);
    });

    test('toJson omits empty/null fields', () {
      const profile = ProfileDefinition(id: 'p1', name: 'Test');
      final json = profile.toJson();
      expect(json['id'], 'p1');
      expect(json['name'], 'Test');
      expect(json['version'], '1.0.0');
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('sections'), isFalse);
      expect(json.containsKey('capabilities'), isFalse);
      expect(json.containsKey('variables'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('toJson includes non-empty fields', () {
      const profile = ProfileDefinition(
        id: 'p1',
        name: 'Test',
        description: 'Desc',
        sections: [ProfileContentSection(name: 's1', content: 'text')],
        capabilities: ['llm'],
        variables: {'k': 'v'},
        metadata: {'a': 'b'},
      );
      final json = profile.toJson();
      expect(json['description'], 'Desc');
      expect(json.containsKey('sections'), isTrue);
      expect(json['capabilities'], ['llm']);
      expect(json['variables'], {'k': 'v'});
      expect(json['metadata'], {'a': 'b'});
    });

    test('fromJson/toJson roundtrip', () {
      final original = {
        'id': 'p1',
        'name': 'Profile',
        'description': 'Test',
        'version': '1.0.0',
        'capabilities': ['llm'],
      };
      final profile = ProfileDefinition.fromJson(original);
      final json = profile.toJson();
      expect(json['id'], 'p1');
      expect(json['name'], 'Profile');
      expect(json['description'], 'Test');
      expect(json['capabilities'], ['llm']);
    });

    test('copyWith all fields', () {
      const profile = ProfileDefinition(id: 'p1', name: 'Old');
      final updated = profile.copyWith(
        id: 'p2',
        name: 'New',
        description: 'Updated',
        version: '2.0.0',
        sections: [const ProfileContentSection(name: 's1', content: 'c')],
        capabilities: ['rag'],
        variables: {'x': 1},
        metadata: {'y': 2},
      );
      expect(updated.id, 'p2');
      expect(updated.name, 'New');
      expect(updated.description, 'Updated');
      expect(updated.version, '2.0.0');
      expect(updated.sections, hasLength(1));
      expect(updated.capabilities, ['rag']);
      expect(updated.variables, {'x': 1});
      expect(updated.metadata, {'y': 2});
    });

    test('copyWith preserves unchanged', () {
      const profile = ProfileDefinition(
        id: 'p1',
        name: 'Test',
        description: 'Desc',
      );
      final copy = profile.copyWith(name: 'Updated');
      expect(copy.id, 'p1');
      expect(copy.name, 'Updated');
      expect(copy.description, 'Desc');
    });
  });

  group('ProfileContentSection', () {
    test('creates with required fields', () {
      const section = ProfileContentSection(name: 'intro', content: 'Hello');
      expect(section.name, 'intro');
      expect(section.content, 'Hello');
      expect(section.priority, 0);
      expect(section.condition, isNull);
    });

    test('fromJson with all fields', () {
      final section = ProfileContentSection.fromJson({
        'name': 'system',
        'content': 'You are helpful',
        'priority': 10,
        'condition': 'context.mode == "advanced"',
      });
      expect(section.name, 'system');
      expect(section.content, 'You are helpful');
      expect(section.priority, 10);
      expect(section.condition, 'context.mode == "advanced"');
    });

    test('fromJson defaults', () {
      final section = ProfileContentSection.fromJson({});
      expect(section.name, '');
      expect(section.content, '');
      expect(section.priority, 0);
      expect(section.condition, isNull);
    });

    test('toJson omits default/null fields', () {
      const section = ProfileContentSection(name: 'intro', content: 'Hello');
      final json = section.toJson();
      expect(json['name'], 'intro');
      expect(json['content'], 'Hello');
      expect(json.containsKey('priority'), isFalse);
      expect(json.containsKey('condition'), isFalse);
    });

    test('toJson includes non-default fields', () {
      const section = ProfileContentSection(
        name: 'intro',
        content: 'Hello',
        priority: 5,
        condition: 'true',
      );
      final json = section.toJson();
      expect(json['priority'], 5);
      expect(json['condition'], 'true');
    });

    test('fromJson/toJson roundtrip', () {
      final original = {
        'name': 'section1',
        'content': 'Content here',
        'priority': 3,
        'condition': 'state.active',
      };
      final section = ProfileContentSection.fromJson(original);
      final json = section.toJson();
      expect(json['name'], 'section1');
      expect(json['content'], 'Content here');
      expect(json['priority'], 3);
      expect(json['condition'], 'state.active');
    });

    test('copyWith all fields', () {
      const section = ProfileContentSection(
        name: 'old',
        content: 'old content',
      );
      final updated = section.copyWith(
        name: 'new',
        content: 'new content',
        priority: 10,
        condition: 'always',
      );
      expect(updated.name, 'new');
      expect(updated.content, 'new content');
      expect(updated.priority, 10);
      expect(updated.condition, 'always');
    });

    test('copyWith preserves unchanged', () {
      const section = ProfileContentSection(
        name: 'intro',
        content: 'Hello',
        priority: 5,
        condition: 'true',
      );
      final copy = section.copyWith(content: 'Updated');
      expect(copy.name, 'intro');
      expect(copy.content, 'Updated');
      expect(copy.priority, 5);
      expect(copy.condition, 'true');
    });
  });
}
