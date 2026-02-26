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
      if (allRows.length > 200000) {
        print('Supabase Caution: Reached 200k limit, stopping fetch.');
        break;
      }
    }
    
    return allRows.map((row) => Person.fromJson(row as Map<String, dynamic>)).toList();
  }

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

      final persons = rows.map((row) => Person.fromJson(row as Map<String, dynamic>)).toList();
      return persons.map((p) => _mapPersonToFamilyMember(p, hasChildren: (p.childrenCount ?? 0) > 0)).toList();
    } catch (e) {
      print('Supabase Error in getRoots: $e');
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

      final persons = rows.map((row) => Person.fromJson(row as Map<String, dynamic>)).toList();
      return persons.map((p) => _mapPersonToFamilyMember(p, hasChildren: (p.childrenCount ?? 0) > 0)).toList();
    } catch (e) {
      print('Supabase Error in getChildren ($parentId): $e');
      return [];
    }
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


  // Этот метод мы оставляем для совместимости, но пользоваться им не рекомендуется
  // для большого дерева (> 200k) в обычном режиме. Для демо может вернуть только корни
  Future<List<FamilyMember>> fetchFamilyMembers() async {
    return getRoots();
  }

  FamilyMember _mapPersonToFamilyMember(Person person, {bool hasChildren = false}) {
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
