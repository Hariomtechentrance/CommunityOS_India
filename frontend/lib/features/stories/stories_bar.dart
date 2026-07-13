import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_controller.dart';
import '../../models/story.dart';
import 'create_story_screen.dart';
import 'story_repository.dart';
import 'story_viewer_screen.dart';

/// Horizontal circle-avatar row at the top of the feed - "Your story" first,
/// then everyone else's, with a colored ring for unseen vs grey once
/// you've viewed all of that person's stories.
class StoriesBar extends ConsumerStatefulWidget {
  const StoriesBar({super.key});

  @override
  ConsumerState<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends ConsumerState<StoriesBar> {
  bool _loading = true;
  List<StoryGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stories = await ref.read(storyRepositoryProvider).listActive();
      if (!mounted) return;
      setState(() {
        _groups = groupStoriesByAuthor(stories);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openViewer(StoryGroup group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          authorName: group.author.name ?? 'Someone',
          stories: group.stories,
        ),
      ),
    );
    _load();
  }

  Future<void> _openCreate() async {
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
    );
    if (posted == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 108);

    final myId = ref.watch(sessionControllerProvider).value?.user?.id;
    StoryGroup? myGroup;
    for (final g in _groups) {
      if (g.author.id == myId) {
        myGroup = g;
        break;
      }
    }
    final otherGroups = _groups.where((g) => g.author.id != myId).toList();

    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _StoryCircle(
            label: 'Your story',
            hasUnseen: false,
            showAddBadge: myGroup == null,
            onTap: myGroup != null ? () => _openViewer(myGroup!) : _openCreate,
          ),
          ...otherGroups.map(
            (group) => _StoryCircle(
              label: group.author.name ?? 'Someone',
              hasUnseen: group.hasUnseen,
              onTap: () => _openViewer(group),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  final String label;
  final bool hasUnseen;
  final bool showAddBadge;
  final VoidCallback onTap;

  const _StoryCircle({
    required this.label,
    required this.hasUnseen,
    required this.onTap,
    this.showAddBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasUnseen ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                  width: hasUnseen ? 2.5 : 1.5,
                ),
              ),
              child: Stack(
                children: [
                  const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 28)),
                  if (showAddBadge)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.add, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
