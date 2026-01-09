import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_initializer.dart';
import '../models/branch.dart';
import '../models/family_member.dart';
import '../models/person.dart';

class SupabaseGenealogyRepository {
  SupabaseGenealogyRepository({SupabaseClient? client})
      : _client = client ?? SupabaseInitializer.client;

  final SupabaseClient _client;

  Future<List<Person>> _fetchPersons() async {
    final List<dynamic> rows = await _client
        .from('people')
        .select(
          '''
          id,
          name,
          parent_id,
          birth_year,
          death_year,
          image,
          author,
          depth,
          path,
          meta_status,
          locked,
          orderby,
          children_count,
          created_at,
          updated_at
          ''',
        )
        .order('orderby', ascending: true)
        .order('id', ascending: true);
    return rows.map((row) => Person.fromJson(row as Map<String, dynamic>)).toList();
  }


  Future<List<FamilyMember>> fetchFamilyMembers() async {
    final persons = await _fetchPersons();
    print('Supabase Repository: Fetched ${persons.length} persons from "people" table.');
    if (persons.isEmpty) return [];

    // Build parent-child relationships
    final personById = {
      for (final person in persons) person.id: person,
    };
    
    final childrenByParentId = <String, List<String>>{};
    for (final person in persons) {
      if (person.parentId != null) {
        childrenByParentId
            .putIfAbsent(person.parentId!, () => [])
            .add(person.id);
      }
    }

    // Convert to FamilyMember
    final members = <String, FamilyMember>{};
    for (final person in persons) {
      final member = _mapPersonToFamilyMember(person);
      members[member.id] = member;
    }

    // Assign children to each member
    return members.values
        .map(
          (member) {
            final rawId = member.id.replaceFirst('person-', '');
            final childIds = (childrenByParentId[rawId] ?? [])
                .map((id) => 'person-$id')
                .toList();
            return member.copyWith(childrenIds: childIds);
          },
        )
        .toList();
  }

  FamilyMember _mapPersonToFamilyMember(Person person) {
    // Используем 'path' для красивого отображения иерархии в описании
    final breadcrumbs = person.path ?? person.name;
    final story = 'Шежіре жолы: $breadcrumbs\n\n'
        '${person.author != null ? "Автор: ${person.author}\n" : ""}'
        'Уровень в дереве: ${person.depth ?? 0}';

    final highlights = <String>[
      if (person.author != null) '🏷️ ${person.author}',
      if (person.depth != null) '📊 Уровень ${person.depth}',
    ];

    // Формируем роль на основе глубины (примерная логика)
    String role = 'Ұрпақ'; // Потомок
    if (person.depth == 0) role = 'Түп ата'; // Основатель
    else if (person.depth == 1) role = 'Ата'; // Дед

    return FamilyMember(
      id: 'person-${person.id}',
      fullName: person.name,
      lifeSpan: _formatLifeSpan(person.birthDate, person.deathDate),
      story: story,
      role: role,
      highlights: highlights,
    );
  }

  String _formatLifeSpan(DateTime? birth, DateTime? death) {
    final birthStr = birth != null ? '${birth.year}' : '????';
    final deathStr = death != null ? '${death.year}' : '...';
    return '$birthStr – $deathStr';
  }
}
