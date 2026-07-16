import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/user.dart';
import '../follows/follows_repository.dart';

enum FollowListMode { followers, following }

class FollowListScreen extends ConsumerStatefulWidget {
  final String userId;
  final FollowListMode mode;

  const FollowListScreen({super.key, required this.userId, required this.mode});

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen> {
  bool _loading = true;
  String? _error;
  List<AppUser> _users = [];
  int _page = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool append = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = append ? _page + 1 : 1;
      final repo = ref.read(followsRepositoryProvider);
      final result = widget.mode == FollowListMode.followers
          ? await repo.listFollowers(widget.userId, page: page)
          : await repo.listFollowing(widget.userId, page: page);
      setState(() {
        _users = append ? [..._users, ...result.items] : result.items;
        _page = result.page;
        _hasMore = result.hasMore;
      });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == FollowListMode.followers ? 'Followers' : 'Following';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: MaxWidthBox(
        child: RefreshIndicator(
          onRefresh: () => _load(),
          child: _loading && _users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _users.isEmpty
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                widget.mode == FollowListMode.followers
                                    ? 'No followers yet.'
                                    : 'Not following anyone yet.',
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _users.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _users.length) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: _loading
                                      ? const CircularProgressIndicator()
                                      : OutlinedButton(
                                          onPressed: () => _load(append: true),
                                          child: const Text('Load more'),
                                        ),
                                ),
                              );
                            }
                            final user = _users[index];
                            return ListTile(
                              leading: UserAvatar(avatarUrl: user.avatarUrl),
                              title: Text(user.name ?? 'Someone'),
                              subtitle: user.area != null ? Text(user.area!) : null,
                              onTap: () => context.push('/home/users/${user.id}'),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
