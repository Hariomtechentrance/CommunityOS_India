import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/user.dart';
import 'user_repository.dart';

/// Find people by their shareable @username or display name - the
/// counterpart to sharing your own @username (see AreaProfileScreen).
class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<AppUser> _results = [];

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref.read(userRepositoryProvider).search(query);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'Search by @username or name',
            border: InputBorder.none,
          ),
        ),
      ),
      body: MaxWidthBox(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _controller.text.trim().isEmpty
                                ? 'Search for people by their @username or name.'
                                : 'No one found.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final user = _results[index];
                          return ListTile(
                            leading: UserAvatar(avatarUrl: user.avatarUrl),
                            title: Text(user.name ?? 'Someone'),
                            subtitle: user.username != null ? Text('@${user.username}') : null,
                            onTap: () => context.push('/home/users/${user.id}'),
                          );
                        },
                      ),
      ),
    );
  }
}
