import 'dart:async';

import 'package:flutter/material.dart';
import '../../home/data/supabase_genealogy_repository.dart';
import '../../home/models/person.dart';
import '../../home/widgets/unified_header.dart';

class PersonEditForm extends StatefulWidget {
  final Person? person;
  final String? initialParentId;

  const PersonEditForm({super.key, this.person, this.initialParentId});

  @override
  State<PersonEditForm> createState() => _PersonEditFormState();
}

class _PersonEditFormState extends State<PersonEditForm> {
  final _formKey = GlobalKey<FormState>();
  final _repository = SupabaseGenealogyRepository();

  late TextEditingController _nameController;
  late TextEditingController _birthYearController;
  late TextEditingController _deathYearController;
  late TextEditingController _authorController;

  String? _selectedParentId;
  String? _selectedParentName;

  bool _isLoading = false;

  static const Color _primaryGreen = Color(0xFFFBC02D);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person?.name);
    _birthYearController = TextEditingController(
      text: widget.person?.birthYear?.toString() ?? '',
    );
    _deathYearController = TextEditingController(
      text: widget.person?.deathYear?.toString() ?? '',
    );
    _authorController = TextEditingController(text: widget.person?.author);
    _selectedParentId = widget.person?.parentId ?? widget.initialParentId;
    _fetchSelectedParent();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthYearController.dispose();
    _deathYearController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _fetchSelectedParent() async {
    final parentId = _selectedParentId;
    if (parentId == null) return;

    try {
      final parent = await _repository.getPersonById(parentId);
      if (mounted && parent != null) {
        setState(() => _selectedParentName = parent.displayName);
      }
    } catch (e) {
      debugPrint('Error fetching parent: $e');
    }
  }

  void _showParentPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ParentPicker(
        repository: _repository,
        excludedPersonId: widget.person?.id,
        onSelected: (person) {
          setState(() {
            _selectedParentId = person.id;
            _selectedParentName = person.displayName;
          });
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.person == null &&
        (_selectedParentId == null || _selectedParentId!.isEmpty)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Нельзя добавить человека без выбора рода (родителя).',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final person = Person(
        id: widget.person?.id ?? '',
        name: _nameController.text.trim(),
        parentId: _selectedParentId,
        birthYear: int.tryParse(_birthYearController.text),
        deathYear: int.tryParse(_deathYearController.text),
        author: _authorController.text.trim(),
        depth: widget.person?.depth,
        path: widget.person?.path,
        image: widget.person?.image,
        metaStatus: widget.person?.metaStatus,
        locked: widget.person?.locked,
        orderBy: widget.person?.orderBy,
        childrenCount: widget.person?.childrenCount,
      );

      if (widget.person == null) {
        await _repository.addPerson(person);
      } else {
        await _repository.updatePerson(person);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 80,
                24,
                40,
              ),
              children: [
                _buildSectionHeader('Негізгі ақпарат'),
                _buildTextField(
                  controller: _nameController,
                  label: 'Аты (Міндетті түрде)',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Атын енгізіңіз' : null,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Таңдаулы Род (Әкесі)'),
                InkWell(
                  onTap: _showParentPicker,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_tree_outlined,
                          color: _primaryGreen,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedParentName ?? 'Родты таңдаңыз',
                                style: TextStyle(
                                  color: _selectedParentName == null
                                      ? Colors.grey
                                      : Colors.black87,
                                  fontWeight: _selectedParentName == null
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              if (_selectedParentId != null)
                                Text(
                                  'ID: $_selectedParentId',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[400],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Өмір сүрген жылдары'),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _birthYearController,
                        label: 'Туған жылы',
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _deathYearController,
                        label: 'Қайтыс болған жылы',
                        icon: Icons.event_busy_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Қосымша'),
                _buildTextField(
                  controller: _authorController,
                  label: 'Автор/Дереккөз',
                  icon: Icons.history_edu_outlined,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.person == null ? 'Қосу' : 'Сақтау',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: UnifiedHeader(
              title: widget.person == null ? 'Адам қосу' : 'Өңдеу',
              showBackButton: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: enabled ? _primaryGreen : Colors.grey,
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _ParentPicker extends StatefulWidget {
  final SupabaseGenealogyRepository repository;
  final String? excludedPersonId;
  final Function(Person) onSelected;

  const _ParentPicker({
    required this.repository,
    required this.onSelected,
    this.excludedPersonId,
  });

  @override
  State<_ParentPicker> createState() => _ParentPickerState();
}

class _ParentPickerState extends State<_ParentPicker> {
  List<Person> _persons = [];
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
    _loadPersons();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadPersons);
  }

  Future<void> _loadPersons() async {
    final requestId = ++_requestId;
    setState(() => _isLoading = true);
    try {
      final persons = await widget.repository.searchPersons(_controller.text);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _persons = persons
            .where((person) => person.id != widget.excludedPersonId)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error searching parents: $e');
      if (!mounted || requestId != _requestId) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Родты таңдаңыз (Әкесі)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Аты бойынша іздеу...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _persons.isEmpty
                ? const Center(child: Text('Адамдар табылмады'))
                : ListView.builder(
                    itemCount: _persons.length,
                    itemBuilder: (context, index) {
                      final person = _persons[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 4,
                        ),
                        title: Text(
                          person.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          person.path ?? 'Деңгей: ${person.depth ?? 0}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        onTap: () {
                          widget.onSelected(person);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
