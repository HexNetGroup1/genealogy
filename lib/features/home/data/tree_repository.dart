import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_initializer.dart';
import '../models/branch.dart';
import '../models/person.dart';

class TreeRepository {
  TreeRepository({SupabaseClient? client})
      : _client = client ?? SupabaseInitializer.client;

  final SupabaseClient _client;

  // Get root person (depth 0, like "Алаш")
  Future<Branch> getRootBranch() async {
    final List<dynamic> data = await _client
        .from('people')
        .select()
        .eq('depth', 0)
        .limit(1);
    
    if (data.isEmpty) {
      throw Exception('Root person not found');
    }
    
    final person = Person.fromJson(data.first as Map<String, dynamic>);
    
    // Convert person to Branch for backwards compatibility
    return Branch(
      id: int.tryParse(person.id) ?? 0,
      name: person.name,
      type: 'root',
      parentId: person.parentId != null ? int.tryParse(person.parentId!) : null,
    );
  }

  // Get children of a person (by parent_id)
  Future<List<Branch>> getChildrenBranches(int parentId) async {
    final List<dynamic> data = await _client
        .from('people')
        .select()
        .eq('parent_id', parentId.toString())
        .order('orderby', ascending: true)
        .order('id', ascending: true) as List<dynamic>;

    return data
        .map((row) {
          final person = Person.fromJson(row as Map<String, dynamic>);
          return Branch(
            id: int.tryParse(person.id) ?? 0,
            name: person.name,
            type: 'person',
            parentId: parentId,
          );
        })
        .toList();
  }

  // Get persons by "branch" (actually by parent_id in hierarchical structure)
  Future<List<Person>> getPersonsByBranch(int branchId) async {
    final List<dynamic> data = await _client
        .from('people')
        .select()
        .eq('parent_id', branchId.toString()) as List<dynamic>;

    return data
        .map((row) => Person.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
