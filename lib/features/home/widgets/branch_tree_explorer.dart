import 'package:flutter/material.dart';

import '../../home/data/tree_repository.dart';
import '../../home/models/branch.dart';
import '../../home/models/family_member.dart';
import '../../home/models/person.dart';

class BranchTreeExplorer extends StatefulWidget {
  const BranchTreeExplorer({
    super.key,
    required this.onPersonSelected,
  });

  final ValueChanged<FamilyMember> onPersonSelected;

  @override
  State<BranchTreeExplorer> createState() => _BranchTreeExplorerState();
}

class _BranchTreeExplorerState extends State<BranchTreeExplorer> {
  late final TreeRepository _repository;
  late Future<Branch> _rootFuture;

  @override
  void initState() {
    super.initState();
    _repository = TreeRepository();
    _rootFuture = _repository.getRootBranch();
  }

  Future<void> _reload() async {
    setState(() {
      _rootFuture = _repository.getRootBranch();
    });
    await _rootFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<Branch>(
        future: _rootFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _BranchError(
              message: 'Ошибка: ${snapshot.error}',
              onRetry: _reload,
            );
          }
          if (!snapshot.hasData) {
            return _BranchError(
              message: 'Не найден корневой род "Алаш".',
              onRetry: _reload,
              isInfo: true,
            );
          }
          final root = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              BranchNode(
                branch: root,
                repository: _repository,
                onPersonSelected: widget.onPersonSelected,
              ),
            ],
          );
        },
      ),
    );
  }
}

class BranchNode extends StatefulWidget {
  const BranchNode({
    super.key,
    required this.branch,
    required this.repository,
    required this.onPersonSelected,
  });

  final Branch branch;
  final TreeRepository repository;
  final ValueChanged<FamilyMember> onPersonSelected;

  @override
  State<BranchNode> createState() => _BranchNodeState();
}

class _BranchNodeState extends State<BranchNode> {
  late Future<List<Branch>> _childrenFuture;
  late Future<List<Person>> _personsFuture;

  @override
  void initState() {
    super.initState();
    _childrenFuture = widget.repository.getChildrenBranches(widget.branch.id);
    _personsFuture = widget.repository.getPersonsByBranch(widget.branch.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Branch>>(
      future: _childrenFuture,
      builder: (context, snapshot) {
        final hasChildren =
            snapshot.hasData && (snapshot.data?.isNotEmpty ?? false);

        return ExpansionTile(
          title: Text(widget.branch.name),
          subtitle: Text(widget.branch.type),
          childrenPadding: const EdgeInsets.only(left: 16),
          children: [
            FutureBuilder<List<Person>>(
              future: _personsFuture,
              builder: (context, personsSnapshot) {
                final persons = personsSnapshot.data;
                if (persons == null || persons.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Тұлғалар:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...persons.map(
                      (person) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_2_outlined),
                        title: Text(
                          person.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () =>
                            widget.onPersonSelected(_mapPerson(person)),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (hasChildren)
              ...snapshot.data!.map(
                (child) => BranchNode(
                  key: ValueKey(child.id),
                  branch: child,
                  repository: widget.repository,
                  onPersonSelected: widget.onPersonSelected,
                ),
              ),
          ],
        );
      },
    );
  }

  FamilyMember _mapPerson(Person person) {
    final fullName = person.displayName;
    final birthYear = person.birthYear?.toString() ?? '????';
    final deathYear = person.deathYear?.toString() ?? '...';
    final lifeSpan = '$birthYear – $deathYear';
    
    return FamilyMember(
      id: 'person-${person.id}',
      fullName: fullName,
      lifeSpan: lifeSpan,
      role: 'Участник рода',
      story: person.path?.isNotEmpty == true
          ? person.path!
          : 'История появится позже.',
      highlights: const [],
    );
  }
}

class _BranchError extends StatelessWidget {
  const _BranchError({
    required this.message,
    required this.onRetry,
    this.isInfo = false,
  });

  final String message;
  final Future<void> Function() onRetry;
  final bool isInfo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = isInfo ? Icons.info_outline : Icons.error_outline;
    final color = isInfo ? colorScheme.primary : colorScheme.error;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Обновить'),
          ),
        ],
      ),
    );
  }
}
