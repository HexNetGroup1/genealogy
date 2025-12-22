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
        .order('id');
    return rows.map((row) => Person.fromJson(row as Map<String, dynamic>)).toList();
  }


  Future<List<FamilyMember>> fetchFamilyMembers() async {
    final persons = await _fetchPersons();
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
            final personId = member.id.replaceFirst('person-', '');
            final childIds = (childrenByParentId[personId] ?? [])
                .map((id) => 'person-$id')
                .toList();
            return member.copyWith(childrenIds: childIds);
          },
        )
        .toList();
  }


  FamilyMember _mapPersonToFamilyMember(Person person) {
    final fullName = person.displayName;
    final role = 'Потомок';  // Relative/Descendant
    final highlights = <String>[
      if (person.author != null) 'Автор: ${person.author}',
      if (person.depth != null) 'Уровень: ${person.depth}',
    ];
    final lifeSpan = _formatLifeSpan(person.birthDate, person.deathDate);
    final story = person.path ?? 'Информация в разработке';

    return FamilyMember(
      id: 'person-${person.id}',
      fullName: fullName,
      lifeSpan: lifeSpan,
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
