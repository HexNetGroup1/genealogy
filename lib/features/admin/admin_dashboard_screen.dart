import 'dart:async';

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
  Map<String, String> _parentNames = {};
  bool _isLoading = false;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  int _currentPage = 0;
  int _totalCount = 0;
  int _requestId = 0;

  static const int _pageSize = 50;

  static const Color _primaryGreen = Color(0xFFFBC02D);

  @override
  void initState() {
    super.initState();
    _fetchPersons();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _currentPage = 0;
      _fetchPersons();
    });
  }

  Future<void> _fetchPersons() async {
    final requestId = ++_requestId;
    setState(() => _isLoading = true);
    try {
      final result = await _repository.getPersonsPage(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchController.text,
      );
      final parentNames = await _repository.getPersonNamesByIds(
        result.items.map((person) => person.parentId).whereType<String>(),
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _persons = result.items;
        _parentNames = parentNames;
        _totalCount = result.totalCount;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (!mounted || requestId != _requestId) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Адамдарды жүктеу мүмкін болмады')),
      );
    }
  }

  void _changePage(int page) {
    if (page == _currentPage || page < 0 || page >= _totalPages) return;
    setState(() => _currentPage = page);
    _fetchPersons();
  }

  int get _totalPages =>
      _totalCount == 0 ? 1 : (_totalCount + _pageSize - 1) ~/ _pageSize;

  void _editPerson(Person? person) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PersonEditForm(person: person)));
    if (result == true) await _fetchPersons();
  }

  void _addChild(Person parent) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonEditForm(initialParentId: parent.id),
      ),
    );
    if (result == true) await _fetchPersons();
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
        if (_persons.length == 1 && _currentPage > 0) {
          _currentPage--;
        }
        await _fetchPersons();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
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
                      prefixIcon: const Icon(
                        Icons.search,
                        color: _primaryGreen,
                      ),
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
                    ? const Center(
                        child: CircularProgressIndicator(color: _primaryGreen),
                      )
                    : _persons.isEmpty
                    ? const Center(child: Text('Адамдар табылмады'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                        itemCount: _persons.length,
                        itemBuilder: (context, index) {
                          final person = _persons[index];
                          return _AdminPersonCard(
                            person: person,
                            parentName: person.parentId == null
                                ? null
                                : _parentNames[person.parentId],
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
                    if (!mounted) return;
                    Navigator.of(this.context).pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !_isLoading && _totalCount > 0
          ? _PaginationBar(
              currentPage: _currentPage,
              totalPages: _totalPages,
              totalCount: _totalCount,
              pageSize: _pageSize,
              currentItemCount: _persons.length,
              onPrevious: _currentPage == 0
                  ? null
                  : () => _changePage(_currentPage - 1),
              onNext: _currentPage >= _totalPages - 1
                  ? null
                  : () => _changePage(_currentPage + 1),
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editPerson(null),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add),
        label: const Text(
          'Адам қосу',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.currentItemCount,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final int currentItemCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final firstItem = currentPage * pageSize + 1;
    final lastItem = currentPage * pageSize + currentItemCount;

    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              tooltip: 'Алдыңғы бет',
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Бет ${currentPage + 1} / $totalPages',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$firstItem–$lastItem / $totalCount',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onNext,
              tooltip: 'Келесі бет',
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminPersonCard extends StatelessWidget {
  final Person person;
  final String? parentName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddChild;

  const _AdminPersonCard({
    required this.person,
    required this.parentName,
    required this.onEdit,
    required this.onDelete,
    required this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String label;

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
