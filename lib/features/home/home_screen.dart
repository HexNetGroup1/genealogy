import 'package:flutter/material.dart';

import 'data/sample_family.dart';
import 'models/family_member.dart';
import 'widgets/book_library.dart';
import 'widgets/family_tree_view.dart';
import 'widgets/shezhire_info_tab.dart';
import 'data/supabase_genealogy_repository.dart';

import 'widgets/unified_header.dart';
import '../../widgets/liquid_glass.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _repository = SupabaseGenealogyRepository();
  
  List<FamilyMember>? _members;
  bool _isLoading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      debugPrint('Supabase: Fetching family roots...');
      final members = await _repository.getRoots();
      debugPrint('Supabase: Found ${members.length} roots.');
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Supabase Error: $e');
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Басты';
      case 1:
        return 'Шежіре';
      case 2:
        return 'PDF кітапхана';
      default:
        return 'Genealogy';
    }
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 54,
            ),
            child: IndexedStack(
              index: _currentIndex,
              children: [
                const ShezhireInfoTab(),
                _TreeContainer(
                  members: _members,
                  onMemberSelected: _openStory,
                  isLoading: _isLoading,
                  error: _error,
                  onRetry: _fetchData,
                  onLoadChildren: (parentId) => _repository.getChildren(parentId),
                ),
                const BookLibrary(),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: UnifiedHeader(
              title: _getTitle(),
              isGlass: false,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFFF57F17),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Басты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_tree_outlined),
            activeIcon: Icon(Icons.account_tree),
            label: 'Шежіре',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf_outlined),
            activeIcon: Icon(Icons.picture_as_pdf),
            label: 'PDF',
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const Color _activeColor = Color(0xFFF57F17);
  static const Color _inactiveColor = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    _activeColor.withValues(alpha: 0.12),
                    _activeColor.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: _activeColor.withValues(alpha: 0.25),
                  width: 1,
                )
              : Border.all(
                  color: Colors.transparent,
                  width: 1,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _activeColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.0, end: isSelected ? 1.15 : 1.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? _activeColor : _inactiveColor,
                size: 24,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isSelected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: _activeColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
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
    required this.onLoadChildren,
  });

  final List<FamilyMember>? members;
  final ValueChanged<FamilyMember> onMemberSelected;
  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;
  final Future<List<FamilyMember>> Function(String parentId) onLoadChildren;

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
          onLoadChildren: onLoadChildren,
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


// Helpers

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
