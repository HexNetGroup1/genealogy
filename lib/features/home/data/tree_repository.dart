import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_initializer.dart';
import '../models/branch.dart';
import '../models/person.dart';

class TreeRepository {
  TreeRepository({SupabaseClient? client})
      : _client = client ?? SupabaseInitializer.client;

  final SupabaseClient _client;

  Future<Branch> getRootBranch() async {
    final Map<String, dynamic> data = await _client
        .from('branches')
        .select()
        .eq('name', 'Алаш')
        .eq('type', 'ata')
        .single();

    return Branch.fromJson(data);
  }

  Future<List<Branch>> getChildrenBranches(int parentId) async {
    final List<dynamic> data = await _client
        .from('branches')
        .select()
        .eq('parent_id', parentId)
        .order('order_index', ascending: true)
        .order('id', ascending: true) as List<dynamic>;

    return data
        .map((row) => Branch.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<Person>> getPersonsByBranch(int branchId) async {
    final List<dynamic> data = await _client
        .from('persons')
        .select()
        .eq('branch_id', branchId) as List<dynamic>;

    return data
        .map((row) => Person.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
