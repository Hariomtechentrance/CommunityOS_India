import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/admin.dart';
import 'admin_repository.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  bool _loading = true;
  bool _acting = false;
  String? _error;
  AdminUserDetail? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await ref.read(adminRepositoryProvider).getUserDetail(widget.userId);
      setState(() => _detail = detail);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleSuspend() async {
    final detail = _detail;
    if (detail == null) return;
    setState(() => _acting = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .setSuspended(widget.userId, !detail.user.isSuspended);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _confirmDelete() async {
    final detail = _detail;
    if (detail == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this user?'),
        content: Text(
          'This permanently deletes ${detail.user.name ?? detail.user.phone} and everything '
          'they created (posts, complaints, comments, listings, etc). This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _acting = true);
    try {
      await ref.read(adminRepositoryProvider).deleteUser(widget.userId);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User details')),
      body: MaxWidthBox(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _buildDetail(context, _detail!),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, AdminUserDetail detail) {
    final user = detail.user;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                UserAvatar(avatarUrl: user.avatarUrl, radius: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name ?? 'Unnamed', style: Theme.of(context).textTheme.titleLarge),
                      Text(user.phone),
                      if (user.area != null) Text(user.area!),
                      if (user.lastLoginAt != null)
                        Text('Last login: ${user.lastLoginAt}')
                      else
                        const Text('Never logged in'),
                      if (user.isSuspended)
                        const Chip(label: Text('Suspended'), backgroundColor: Colors.redAccent),
                      if (user.isSuperAdmin)
                        const Chip(label: Text('Super admin')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _Count(label: 'Posts', value: detail.postCount),
                _Count(label: 'Complaints', value: detail.complaintCount),
                _Count(label: 'Area posts', value: detail.areaPostCount),
                _Count(label: 'Listings', value: detail.listingCount),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Society memberships', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (detail.memberships.isEmpty)
          const Text('Not a member of any society.')
        else
          ...detail.memberships.map(
            (m) => Card(
              child: ListTile(
                title: Text(m.societyName),
                subtitle: Text('${m.role} · ${m.status}'),
              ),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _acting || user.isSuperAdmin ? null : _toggleSuspend,
          icon: Icon(user.isSuspended ? Icons.check_circle : Icons.block),
          label: Text(user.isSuspended ? 'Unsuspend account' : 'Suspend account'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _acting || user.isSuperAdmin ? null : _confirmDelete,
          style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          icon: const Icon(Icons.delete_forever),
          label: const Text('Delete account'),
        ),
        if (user.isSuperAdmin)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Super admin accounts can\'t be suspended or deleted from this screen.'),
          ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  final String label;
  final int value;

  const _Count({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value', style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
