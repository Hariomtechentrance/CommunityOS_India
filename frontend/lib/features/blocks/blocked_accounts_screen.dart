import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/user.dart';
import 'blocks_repository.dart';

class BlockedAccountsScreen extends ConsumerStatefulWidget {
  const BlockedAccountsScreen({super.key});

  @override
  ConsumerState<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends ConsumerState<BlockedAccountsScreen> {
  bool _loading = true;
  String? _error;
  List<AppUser> _users = [];
  int _page = 1;
  bool _hasMore = false;
  final _unblocking = <String>{};

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
      final result = await ref.read(blocksRepositoryProvider).listBlocked(page: page);
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

  Future<void> _unblock(AppUser user) async {
    setState(() => _unblocking.add(user.id));
    try {
      await ref.read(blocksRepositoryProvider).unblock(user.id);
      setState(() => _users.removeWhere((u) => u.id == user.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _unblocking.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked accounts')),
      body: MaxWidthBox(
        child: RefreshIndicator(
          onRefresh: () => _load(),
          child: _loading && _users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _users.isEmpty
                      ? ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(24),
                              child: Text("You haven't blocked anyone."),
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
                            final isUnblocking = _unblocking.contains(user.id);
                            return ListTile(
                              leading: UserAvatar(avatarUrl: user.avatarUrl),
                              title: Text(user.name ?? 'Someone'),
                              subtitle: user.area != null ? Text(user.area!) : null,
                              trailing: OutlinedButton(
                                onPressed: isUnblocking ? null : () => _unblock(user),
                                child: isUnblocking
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Unblock'),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
