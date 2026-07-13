import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/relative_time.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/story.dart';
import 'story_repository.dart';

/// Author-only bottom sheet listing who's viewed a story, newest first, with
/// each viewer's reaction emoji (if any) shown as a trailing badge.
class StoryViewersSheet extends ConsumerStatefulWidget {
  final String storyId;

  const StoryViewersSheet({super.key, required this.storyId});

  @override
  ConsumerState<StoryViewersSheet> createState() => _StoryViewersSheetState();
}

class _StoryViewersSheetState extends ConsumerState<StoryViewersSheet> {
  bool _loading = true;
  String? _error;
  List<StoryViewer> _viewers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final viewers = await ref.read(storyRepositoryProvider).getViewers(widget.storyId);
      if (mounted) setState(() => _viewers = viewers);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Viewers (${_viewers.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _viewers.isEmpty
                          ? const Center(child: Text('No views yet.'))
                          : ListView.builder(
                              itemCount: _viewers.length,
                              itemBuilder: (context, index) {
                                final viewer = _viewers[index];
                                return ListTile(
                                  leading: UserAvatar(avatarUrl: viewer.avatarUrl),
                                  title: Text(viewer.name ?? 'Someone'),
                                  subtitle: Text(relativeTime(viewer.viewedAt)),
                                  trailing: viewer.reaction != null
                                      ? Text(viewer.reaction!, style: const TextStyle(fontSize: 22))
                                      : null,
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
