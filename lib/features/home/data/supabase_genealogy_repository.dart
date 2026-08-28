import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_initializer.dart';
import '../models/family_member.dart';
import '../models/person.dart';

class PersonPage {
  const PersonPage({required this.items, required this.totalCount});

  final List<Person> items;
  final int totalCount;
}

class SupabaseGenealogyRepository {
  SupabaseGenealogyRepository({SupabaseClient? client})
    : _client = client ?? SupabaseInitializer.client;

  final SupabaseClient _client;

  // Загружаем корневых предков (где parent_id IS NULL)
  Future<List<FamilyMember>> getRoots() async {
    try {
      final List<dynamic> rows = await _client
          .from('people')
          .select()
          .isFilter('parent_id', null)
          .order('orderby', ascending: true)
          .order('id', ascending: true)
          .limit(100); // Берем первые 100 корней для надежности

      final persons = rows
          .map((row) => Person.fromJson(row as Map<String, dynamic>))
          .toList();
      return persons
          .map(
            (p) => _mapPersonToFamilyMember(
              p,
              hasChildren: (p.childrenCount ?? 0) > 0,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Supabase Error in getRoots: $e');
      return [];
    }
  }

  // Загружаем детей конкретного предка
  Future<List<FamilyMember>> getChildren(String parentId) async {
    try {
      // parentId в FamilyMember имеет формат "person-UUID", убираем префикс
      final rawParentId = parentId.replaceFirst('person-', '');

      final List<dynamic> rows = await _client
          .from('people')
          .select()
          .eq('parent_id', rawParentId)
          .order('orderby', ascending: true)
          .order('id', ascending: true);

      final persons = rows
          .map((row) => Person.fromJson(row as Map<String, dynamic>))
          .toList();
      return persons
          .map(
            (p) => _mapPersonToFamilyMember(
              p,
              hasChildren: (p.childrenCount ?? 0) > 0,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Supabase Error in getChildren ($parentId): $e');
      return [];
    }
  }

  Future<PersonPage> getPersonsPage({
    required int page,
    int pageSize = 50,
    String search = '',
  }) async {
    final from = page * pageSize;
    final trimmedSearch = search.trim();

    var query = _client.from('people').select('''
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
    ''');

    if (trimmedSearch.isNotEmpty) {
      query = query.ilike('name', '%$trimmedSearch%');
    }

    final response = await query
        .order('depth', ascending: true)
        .order('orderby', ascending: true)
        .order('id', ascending: true)
        .range(from, from + pageSize - 1)
        .count(CountOption.exact);

    final items = response.data.map(Person.fromJson).toList();
    return PersonPage(items: items, totalCount: response.count);
  }

  Future<Map<String, String>> getPersonNamesByIds(Iterable<String> ids) async {
    final uniqueIds = ids.where((id) => id.isNotEmpty).toSet().toList();
    if (uniqueIds.isEmpty) return const {};

    final List<dynamic> rows = await _client
        .from('people')
        .select('id, name')
        .inFilter('id', uniqueIds);

    return {
      for (final row in rows)
        row['id'].toString().toLowerCase(): row['name'] as String,
    };
  }

  Future<Person?> getPersonById(String id) async {
    final Map<String, dynamic>? row = await _client
        .from('people')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Person.fromJson(row);
  }

  Future<List<Person>> searchPersons(String search, {int limit = 50}) async {
    var query = _client.from('people').select();
    final trimmedSearch = search.trim();
    if (trimmedSearch.isNotEmpty) {
      query = query.ilike('path', '%$trimmedSearch%');
    }

    final List<dynamic> rows = await query
        .order('depth', ascending: true)
        .order('orderby', ascending: true)
        .order('id', ascending: true)
        .limit(limit);
    return rows
        .map((row) => Person.fromJson(row as Map<String, dynamic>))
        .toList();
  }

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
        path = parentPath.isNotEmpty
            ? '$parentPath.${person.name}'
            : person.name;
      } catch (e) {
        debugPrint(
          'Warning: Could not fetch parent data for depth calculation: $e',
        );
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

  // Этот метод мы оставляем для совместимости, но пользоваться им не рекомендуется
  // для большого дерева (> 200k) в обычном режиме. Для демо может вернуть только корни
  Future<List<FamilyMember>> fetchFamilyMembers() async {
    return getRoots();
  }

  FamilyMember _mapPersonToFamilyMember(
    Person person, {
    bool hasChildren = false,
  }) {
    // Используем 'path' для красивого отображения иерархии в описании
    final breadcrumbs = person.path ?? person.name;
    final story =
        'Шежіре жолы: $breadcrumbs\n\n'
        '${person.author != null ? "Автор: ${person.author}\n" : ""}'
        'Уровень в дереве: ${person.depth ?? 0}';

    final highlights = <String>[
      if (person.author != null) '🏷️ ${person.author}',
      if (person.depth != null) '📊 Уровень ${person.depth}',
    ];

    // Формируем роль на основе глубины (примерная логика)
    String role = 'Ұрпақ'; // Потомок
    if (person.depth == 0) {
      role = 'Түп ата'; // Основатель
    } else if (person.depth == 1) {
      role = 'Ата'; // Дед
    }

    return FamilyMember(
      id: 'person-${person.id}',
      fullName: person.name,
      lifeSpan: _formatLifeSpan(person.birthDate, person.deathDate),
      story: story,
      role: role,
      highlights: highlights,
      // Мы добавляем фиктивный childId, если у person в БД есть дети, чтобы UI показал кнопку "+"
      // В FamilyTreeView мы проверяем наличие элементов, поэтому просто добавим маркер
      childrenIds: hasChildren ? const ['has_children_marker'] : const [],
    );
  }

  String _formatLifeSpan(DateTime? birth, DateTime? death) {
    final birthStr = birth != null ? '${birth.year}' : '????';
    final deathStr = death != null ? '${death.year}' : '...';
    return '$birthStr – $deathStr';
  }
}
