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
    final allRows = <dynamic>[];
    bool hasMore = true;
    int from = 0;
    const int pageSize = 1000;

    print('Supabase: Loading all persons in batches...');

    while (hasMore) {
      final List<dynamic> rows = await _client
          .from('people')
          .select('''
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
            ''')
          .order('depth', ascending: true)
          .order('orderby', ascending: true)
          .order('id', ascending: true)
          .range(from, from + pageSize - 1);

      allRows.addAll(rows);
      print('Supabase: Fetched batch ${from ~/ pageSize + 1} (${rows.length} rows). Total: ${allRows.length}');
      
      if (rows.length < pageSize) {
        hasMore = false;
      } else {
        from += pageSize;
      }
      
      // Safety break to prevent infinite loops in case of unexpected API behavior
      if (allRows.length > 20000) {
        print('Supabase Caution: Reached 20k limit, stopping fetch.');
        break;
      }
    }
    
    return allRows.map((row) => Person.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<List<Person>> getAllPersons() => _fetchPersons();

  Future<void> addPerson(Person person) async {
    int depth = 0;
    String path = person.name;

    if (person.parentId != null) {
      try {
        final parentData = await _client
            .from('people')
            .select('depth, path')
            .eq('id', person.parentId!)
            .single();
        
        depth = (parentData['depth'] as int? ?? 0) + 1;
        final parentPath = parentData['path'] as String? ?? '';
        path = parentPath.isNotEmpty ? '$parentPath.${person.name}' : person.name;
      } catch (e) {
        print('Warning: Could not fetch parent data for depth calculation: $e');
        // Fallback to defaults or rethrow if necessary
      }
    }

    final data = person.toJson();
    data.remove('id'); // Supabase generates UUID
    data.remove('created_at');
    data.remove('updated_at');
    
    // Explicitly set calculated fields
    data['depth'] = depth;
    data['path'] = path;
    
    await _client.from('people').insert(data);
  }

  Future<void> updatePerson(Person person) async {
    final data = person.toJson();
    data.remove('created_at');
    data.remove('updated_at');
    await _client.from('people').update(data).eq('id', person.id);
  }

  Future<void> deletePerson(String id) async {
    await _client.from('people').delete().eq('id', id);
  }


  Future<List<FamilyMember>> fetchFamilyMembers() async {
    final persons = await _fetchPersons();
    print('Supabase Repository: Fetched ${persons.length} persons from "people" table.');
    if (persons.isEmpty) return [];

    // Build parent-child relationships
    final personById = {
      for (final person in persons) person.id: person,
    };
    
    print('Supabase: Verifying links for ${persons.length} persons...');
    int linksFound = 0;
    final childrenByParentId = <String, List<String>>{};
    for (final person in persons) {
      if (person.parentId != null) {
        if (personById.containsKey(person.parentId)) {
          linksFound++;
          childrenByParentId
              .putIfAbsent(person.parentId!, () => [])
              .add(person.id);
        } else {
          print('Supabase WARNING: parent_id "${person.parentId}" for "${person.name}" NOT FOUND in people list!');
        }
      }
    }
    print('Supabase: Total valid parent-child links found: $linksFound');

    // Convert to FamilyMember
    final members = <String, FamilyMember>{};
    for (final person in persons) {
      final member = _mapPersonToFamilyMember(person);
      members[member.id] = member;
    }

    // Assign children to each member
    final result = members.values
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

    // Debug: Find roots
    final allChildIds = result.expand((m) => m.childrenIds).toSet();
    final roots = result.where((m) => !allChildIds.contains(m.id)).toList();
    print('Supabase: Identified ${roots.length} roots: ${roots.map((r) => r.fullName).join(', ')}');
    if (roots.isEmpty && result.isNotEmpty) {
      print('Supabase Warning: No roots found! Circular dependency or missing parents?');
    }

    return result;
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
