import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import '../models/family_member.dart';

class FamilyTreeView extends StatefulWidget {
  const FamilyTreeView({
    super.key,
    required this.members,
    required this.onMemberSelected,
  });

  final List<FamilyMember> members;
  final ValueChanged<FamilyMember> onMemberSelected;

  @override
  State<FamilyTreeView> createState() => _FamilyTreeViewState();
}

class _FamilyTreeViewState extends State<FamilyTreeView> {
  late final Graph _graph;
  late final BuchheimWalkerConfiguration _configuration;
  late final Map<String, FamilyMember> _membersById;
  final Map<String, Node> _nodeCache = {};

  @override
  void initState() {
    super.initState();
    _membersById = {
      for (final member in widget.members) member.id: member,
    };
    _graph = Graph()..isTree = true;
    for (final member in widget.members) {
      _ensureNode(member.id);
      for (final childId in member.childrenIds) {
        _graph.addEdge(_ensureNode(member.id), _ensureNode(childId));
      }
    }
    _configuration = BuchheimWalkerConfiguration()
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM
      ..siblingSeparation = 24
      ..levelSeparation = 56
      ..subtreeSeparation = 32;
  }

  Node _ensureNode(String id) {
    return _nodeCache.putIfAbsent(id, () => Node.Id(id));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(32),
      minScale: 0.6,
      maxScale: 2.6,
      child: GraphView(
        graph: _graph,
        algorithm: BuchheimWalkerAlgorithm(
          _configuration,
          TreeEdgeRenderer(_configuration),
        ),
        paint: Paint()
          ..color = colorScheme.outlineVariant
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
        builder: (Node node) {
          final memberId = node.key!.value as String;
          final member = _membersById[memberId];
          if (member == null) {
            return const SizedBox.shrink();
          }
          return _FamilyNodeCard(
            member: member,
            onTap: widget.onMemberSelected,
          );
        },
      ),
    );
  }
}

class _FamilyNodeCard extends StatelessWidget {
  const _FamilyNodeCard({
    required this.member,
    required this.onTap,
  });

  final FamilyMember member;
  final ValueChanged<FamilyMember> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onTap(member),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(24),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              member.fullName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              member.lifeSpan,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              member.role,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            if (member.highlights.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: member.highlights
                    .take(2)
                    .map(
                      (highlight) => Chip(
                        label: Text(highlight),
                        visualDensity: VisualDensity.compact,
                        labelStyle: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: colorScheme.onSecondaryContainer),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: colorScheme.secondaryContainer,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
