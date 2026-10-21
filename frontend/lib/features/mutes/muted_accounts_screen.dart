import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/user.dart';
import 'mutes_repository.dart';

class MutedAccountsScreen extends ConsumerStatefulWidget {
  const MutedAccountsScreen({super.key});

  @override
  ConsumerState<MutedAccountsScreen> createState() => _MutedAccountsScreenState();
}

class _MutedAccountsScreenState extends ConsumerState<MutedAccountsScreen> {
  bool _loading = true;
  String? _error;
  List<AppUser> _users = [];
  int _page = 1;
  bool _hasMore = false;
  final _unmuting = <String>{};

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
      final result = await ref.read(mutesRepositoryProvider).listMuted(page: page);
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

  Future<void> _unmute(AppUser user) async {
    setState(() => _unmuting.add(user.id));
    try {
      await ref.read(mutesRepositoryProvider).unmute(user.id);
      setState(() => _users.removeWhere((u) => u.id == user.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _unmuting.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Muted accounts')),
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
                              child: Text("You haven't muted anyone."),
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
                            final isUnmuting = _unmuting.contains(user.id);
                            return ListTile(
                              leading: UserAvatar(avatarUrl: user.avatarUrl),
                              title: Text(user.name ?? 'Someone'),
                              subtitle: user.area != null ? Text(user.area!) : null,
                              trailing: OutlinedButton(
                                onPressed: isUnmuting ? null : () => _unmute(user),
                                child: isUnmuting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Unmute'),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
