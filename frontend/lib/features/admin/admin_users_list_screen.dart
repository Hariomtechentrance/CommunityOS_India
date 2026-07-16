import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/user.dart';
import 'admin_repository.dart';

class AdminUsersListScreen extends ConsumerStatefulWidget {
  const AdminUsersListScreen({super.key});

  @override
  ConsumerState<AdminUsersListScreen> createState() => _AdminUsersListScreenState();
}

class _AdminUsersListScreenState extends ConsumerState<AdminUsersListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

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

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({bool append = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = append ? _page + 1 : 1;
      final result = await ref.read(adminRepositoryProvider).listUsers(
            search: _searchController.text.trim(),
            page: page,
          );
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

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage users')),
      body: MaxWidthBox(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  labelText: 'Search by name or phone',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(),
                child: _loading && _users.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _users.isEmpty
                        ? ListView(
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('No users found.'),
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
                                title: Text(user.name ?? user.phone),
                                subtitle: Text(
                                  [
                                    user.phone,
                                    if (user.isSuspended) 'Suspended',
                                    if (user.isSuperAdmin) 'Super admin',
                                  ].join(' · '),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.push('/admin/users/${user.id}'),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
