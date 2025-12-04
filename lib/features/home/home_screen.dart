import 'package:flutter/material.dart';

import 'data/sample_family.dart';
import 'data/supabase_genealogy_repository.dart';
import 'models/family_member.dart';
import 'widgets/branch_tree_explorer.dart';
import 'widgets/family_tree_view.dart';

class HomeTabsScreen extends StatefulWidget {
  const HomeTabsScreen({super.key});

  @override
  State<HomeTabsScreen> createState() => _HomeTabsScreenState();
}

class _HomeTabsScreenState extends State<HomeTabsScreen> {
  int _currentIndex = 0;
  late final SupabaseGenealogyRepository _repository;
  late Future<List<FamilyMember>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _repository = SupabaseGenealogyRepository();
    _membersFuture = _repository.fetchFamilyMembers();
  }

  void _reloadMembers() {
    setState(() {
      _membersFuture = _repository.fetchFamilyMembers();
    });
  }

  void _openStory(FamilyMember member) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _MemberStorySheet(member: member);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<FamilyMember>>(
          future: _membersFuture,
          builder: (context, snapshot) {
            final members = snapshot.data;
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final error = snapshot.hasError ? snapshot.error : null;
            return IndexedStack(
              index: _currentIndex,
              children: [
                FamilyTreeTab(
                  onMemberSelected: _openStory,
                  members: members,
                  isLoading: isLoading,
                  error: error,
                  onRetry: _reloadMembers,
                ),
                StoriesTab(
                  onMemberSelected: _openStory,
                  members: members,
                  isLoading: isLoading,
                  error: error,
                  onRetry: _reloadMembers,
                ),
                const ResearchTab(),
                const MemoriesTab(),
                const ProfileTab(),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            label: 'Tree',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Stories',
          ),
          NavigationDestination(
            icon: Icon(Icons.troubleshoot_outlined),
            label: 'Research',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_mosaic),
            label: 'Memories',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class FamilyTreeTab extends StatelessWidget {
  const FamilyTreeTab({
    super.key,
    required this.onMemberSelected,
    required this.members,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final ValueChanged<FamilyMember> onMemberSelected;
  final List<FamilyMember>? members;
  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TabHeader(
            title: 'Family tree',
            subtitle:
                'Pinch to zoom the tree, либо изучай ветви через список ниже.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TabBar(
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              tabs: const [
                Tab(text: 'Интерактивный вид'),
                Tab(text: 'Список ветвей'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: _TreeContainer(
                        members: members,
                        onMemberSelected: onMemberSelected,
                        isLoading: isLoading,
                        error: error,
                        onRetry: onRetry,
                      ),
                    ),
                  ),
                ),
                BranchTreeExplorer(
                  onPersonSelected: onMemberSelected,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StoriesTab extends StatelessWidget {
  const StoriesTab({
    super.key,
    required this.onMemberSelected,
    required this.members,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final ValueChanged<FamilyMember> onMemberSelected;
  final List<FamilyMember>? members;
  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final resolvedMembers = (members != null && members!.isNotEmpty)
        ? members!
        : sampleFamily;
    final usingDemo = (members == null || members!.isEmpty) && !isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TabHeader(
          title: 'Stories',
          subtitle: 'Finish drafts and mark which clips should sync to Supabase.',
        ),
        if (isLoading)
          const LinearProgressIndicator(minHeight: 2)
        else if (error != null)
          _InlineErrorBanner(
            message: 'Не удалось загрузить истории: $error',
            onRetry: onRetry,
          )
        else if (usingDemo)
          const _InlineInfoBanner(
            message:
                'В Supabase пока нет историй, поэтому показаны демонстрационные данные.',
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            itemBuilder: (context, index) {
              final member = resolvedMembers[index];
              return _StoryCard(
                member: member,
                onTap: () => onMemberSelected(member),
              );
            },
            separatorBuilder: (_, index) => const SizedBox(height: 16),
            itemCount: resolvedMembers.length,
          ),
        ),
      ],
    );
  }
}

class _TreeContainer extends StatelessWidget {
  const _TreeContainer({
    required this.members,
    required this.onMemberSelected,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final List<FamilyMember>? members;
  final ValueChanged<FamilyMember> onMemberSelected;
  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return _CenteredError(
        message: 'Не удалось загрузить дерево: $error',
        onRetry: onRetry,
      );
    }

    final hasRemoteMembers = members != null && members!.isNotEmpty;
    final resolvedMembers = hasRemoteMembers ? members! : sampleFamily;

    if (resolvedMembers.isEmpty) {
      return _CenteredError(
        message: 'В Supabase пока нет родственников. Добавь записи и обнови.',
        onRetry: onRetry,
        isInfo: true,
      );
    }

    return Stack(
      children: [
        FamilyTreeView(
          members: resolvedMembers,
          onMemberSelected: onMemberSelected,
        ),
        if (!hasRemoteMembers)
          Positioned(
            top: 16,
            right: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Демо-дерево',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CenteredError extends StatelessWidget {
  const _CenteredError({
    required this.message,
    required this.onRetry,
    this.isInfo = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool isInfo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isInfo ? Icons.info_outline : Icons.warning_amber_rounded,
            color: isInfo ? colorScheme.primary : colorScheme.error,
            size: 40,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
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

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.errorContainer,
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          TextButton(
            onPressed: onRetry,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

class _InlineInfoBanner extends StatelessWidget {
  const _InlineInfoBanner({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.secondaryContainer,
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class ResearchTab extends StatelessWidget {
  const ResearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderTab(
      title: 'Research missions',
      description:
          'Track which archives, phone interviews, or Supabase tables are still pending. '
          'You can promote a mission to the tree once you verify a story.',
      highlights: [
        'Archive requests',
        'DNA matches',
        'Interview schedule',
      ],
      icon: Icons.explore_outlined,
    );
  }
}

class MemoriesTab extends StatelessWidget {
  const MemoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderTab(
      title: 'Memories board',
      description:
          'Drop photos, audio snippets, and drone clips here. Later they will sync with Supabase storage.',
      highlights: [
        'Upload session plan',
        'Tag relatives',
        'Share highlights',
      ],
      icon: Icons.auto_awesome,
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderTab(
      title: 'Curator profile',
      description:
          'Switch between your curator profile and the public timeline that other relatives will see.',
      highlights: [
        'Personal goals',
        'Notifications',
        'Supabase connection status',
      ],
      icon: Icons.person_outline,
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.title,
    required this.description,
    required this.highlights,
    required this.icon,
  });

  final String title;
  final String description;
  final List<String> highlights;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        color: colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 48,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: highlights
                    .map(
                      (item) => Chip(
                        label: Text(item),
                        backgroundColor: colorScheme.secondaryContainer,
                      ),
                    )
                    .toList(),
              ),
              const Spacer(),
              Text(
                'Coming soon',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.member,
    required this.onTap,
  });

  final FamilyMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trimmedName = member.fullName.trim();
    final avatarInitial =
        trimmedName.isEmpty ? '?' : trimmedName[0].toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(avatarInitial),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        member.role,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow_outlined),
                  tooltip: 'Listen to story draft',
                  onPressed: onTap,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              member.story,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.chrome_reader_mode_outlined),
                label: const Text('Read full story'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberStorySheet extends StatelessWidget {
  const _MemberStorySheet({
    required this.member,
  });

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  member.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${member.lifeSpan} • ${member.role}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  member.story,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                if (member.highlights.isNotEmpty) ...[
                  Text(
                    'Highlights',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: member.highlights
                        .map(
                          (highlight) => Chip(
                            label: Text(highlight),
                            backgroundColor: colorScheme.secondaryContainer,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TabHeader extends StatelessWidget {
  const _TabHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
