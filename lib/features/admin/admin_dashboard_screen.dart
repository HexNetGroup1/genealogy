import 'package:flutter/material.dart';
import '../home/data/supabase_genealogy_repository.dart';
import '../home/models/person.dart';
import 'widgets/person_edit_form.dart';
import '../../../services/auth_service.dart';
import '../home/widgets/unified_header.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _repository = SupabaseGenealogyRepository();
  final _authService = AuthService();
  List<Person> _persons = [];
  List<Person> _filteredPersons = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();

  static const Color _primaryGreen = Color(0xFFFBC02D);

  @override
  void initState() {
    super.initState();
    _fetchPersons();
    _searchController.addListener(_filterPersons);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPersons() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPersons = _persons.where((p) {
        return p.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _fetchPersons() async {
    setState(() => _isLoading = true);
    try {
      final persons = await _repository.getAllPersons();
      if (mounted) {
        setState(() {
          _persons = persons;
          _filterPersons();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await _authService.signOut();
    if (mounted) Navigator.of(context).pop();
  }

  void _editPerson(Person? person) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PersonEditForm(person: person)),
    );
    if (result == true) _fetchPersons();
  }

  void _addChild(Person parent) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonEditForm(initialParentId: parent.id),
      ),
    );
    if (result == true) _fetchPersons();
  }

  Future<void> _deletePerson(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Удалить?'),
        content: const Text('Вы уверены, что хотите удалить эту запись?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deletePerson(id);
        _fetchPersons();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 80),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Аты бойынша іздеу...',
                      prefixIcon: const Icon(Icons.search, color: _primaryGreen),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: _primaryGreen))
                    : _filteredPersons.isEmpty
                        ? const Center(child: Text('Адамдар табылмады'))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                            itemCount: _filteredPersons.length,
                            itemBuilder: (context, index) {
                              final person = _filteredPersons[index];
                              return _AdminPersonCard(
                                person: person,
                                allPersons: _persons,
                                onEdit: () => _editPerson(person),
                                onDelete: () => _deletePerson(person.id),
                                onAddChild: () => _addChild(person),
                              );
                            },
                          ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: UnifiedHeader(
              title: 'Басқару панелі',
              showBackButton: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black54),
                  tooltip: 'Шығу',
                  onPressed: () async {
                    await _authService.signOut();
                    if (mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editPerson(null),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add),
        label: const Text('Адам қосу', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _AdminPersonCard extends StatelessWidget {
  final Person person;
  final List<Person> allPersons;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddChild;

  const _AdminPersonCard({
    required this.person,
    required this.allPersons,
    required this.onEdit,
    required this.onDelete,
    required this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
    String? parentName;
    if (person.parentId != null) {
      try {
        parentName = allPersons.firstWhere((p) => p.id == person.parentId).name;
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFBC02D).withAlpha(30),
                  child: const Icon(Icons.person, color: Color(0xFFFBC02D)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${parentName != null ? "Род: $parentName | " : ""}Деңгей: ${person.depth ?? 0}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                  icon: Icons.person_add_alt_1,
                  label: 'Ұрпақ қосу',
                  color: const Color(0xFFFBC02D),
                  onTap: onAddChild,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.edit,
                  label: 'Өңдеу',
                  color: Colors.blue,
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'Жою',
                  color: Colors.redAccent,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.label,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
