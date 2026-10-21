import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/user_avatar.dart';
import '../../models/user.dart';
import 'reels_repository.dart';

/// Public "liked by" list for a reel, Instagram-style - anyone can open it,
/// unlike StoryViewersSheet (author-only) or AreaPost's interestedUsers
/// (owner-only, since that gates real-world contact info).
class ReelLikesSheet extends ConsumerStatefulWidget {
  final String reelId;

  const ReelLikesSheet({super.key, required this.reelId});

  @override
  ConsumerState<ReelLikesSheet> createState() => _ReelLikesSheetState();
}

class _ReelLikesSheetState extends ConsumerState<ReelLikesSheet> {
  bool _loading = true;
  String? _error;
  List<AppUser> _likers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final likers = await ref.read(reelsRepositoryProvider).listLikers(widget.reelId);
      if (mounted) setState(() => _likers = likers);
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
                'Liked by (${_likers.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _likers.isEmpty
                          ? const Center(child: Text('No likes yet.'))
                          : ListView.builder(
                              itemCount: _likers.length,
                              itemBuilder: (context, index) {
                                final liker = _likers[index];
                                return ListTile(
                                  leading: UserAvatar(avatarUrl: liker.avatarUrl),
                                  title: Text(liker.name ?? 'Someone'),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    context.push('/home/users/${liker.id}');
                                  },
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
