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
        .from('persons')
        .select(
          '''
          id,
          branch_id,
          last_name,
          first_name,
          middle_name,
          birth_date,
          death_date,
          photo,
          description,
          created_at,
          updated_at
          ''',
        )
        .order('id');
    return rows.map((row) => Person.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<List<Branch>> _fetchBranches() async {
    final List<dynamic> rows = await _client
        .from('branches')
        .select(
          '''
          id,
          parent_id,
          name,
          type,
          description,
          icon_url,
          order_index,
          created_at,
          updated_at
          ''',
        )
        .order('order_index');
    return rows.map((row) => Branch.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<List<FamilyMember>> fetchFamilyMembers() async {
    final persons = await _fetchPersons();
    final branches = await _fetchBranches();
    if (persons.isEmpty) return [];

    final branchById = {
      for (final branch in branches) branch.id: branch,
    };
    final branchChildren = <int, List<int>>{};
    for (final branch in branches) {
      final parentId = branch.parentId;
      if (parentId == null) continue;
      branchChildren.putIfAbsent(parentId, () => []).add(branch.id);
    }

    final branchPersonIds = <int, List<String>>{};
    final members = <String, FamilyMember>{};

    for (final person in persons) {
      final branch = branchById[person.branchId];
      final member = _mapPersonToFamilyMember(person, branch);
      members[member.id] = member;
      branchPersonIds.putIfAbsent(person.branchId, () => []).add(member.id);
    }

    final childrenByMember = <String, List<String>>{
      for (final member in members.values) member.id: [],
    };

    for (final person in persons) {
      final childBranchIds = branchChildren[person.branchId] ?? const [];
      final childMemberIds = <String>[];
      for (final childBranchId in childBranchIds) {
        childMemberIds.addAll(branchPersonIds[childBranchId] ?? const []);
      }
      if (childMemberIds.isNotEmpty) {
        childrenByMember['person-${person.id}'] = childMemberIds;
      }
    }

    return members.values
        .map(
          (member) => member.copyWith(
            childrenIds: childrenByMember[member.id] ?? const [],
          ),
        )
        .toList();
  }

  FamilyMember _mapPersonToFamilyMember(Person person, Branch? branch) {
    final fullName = person.displayName;
    final role = branch?.name ?? 'Relative';
    final highlights = <String>[
      if (branch != null) branch.type,
      if (branch?.description?.isNotEmpty == true) branch!.description!,
    ];
    final lifeSpan = _formatLifeSpan(person.birthDate, person.deathDate);
    final story = (person.description?.trim().isNotEmpty ?? false)
        ? person.description!.trim()
        : 'Пока нет истории. Добавь её из Supabase.';

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
