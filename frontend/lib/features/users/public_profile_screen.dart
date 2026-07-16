import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets/max_width_box.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/follow.dart';
import '../../models/user.dart';
import '../calls/call_service.dart';
import '../follows/follows_repository.dart';
import '../users/user_repository.dart';

/// Another user's profile - reachable from anywhere their name/avatar is
/// tappable (post authors, neighbours, followers/following lists). Shows
/// follow state + counts; editing your own profile still lives at
/// AreaProfileScreen (/home/profile), this screen is read-only + social
/// actions only, even when userId happens to be yourself.
class PublicProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  bool _loading = true;
  bool _acting = false;
  String? _error;
  AppUser? _user;
  FollowStats? _stats;

  bool get _isSelf =>
      widget.userId == ref.read(sessionControllerProvider).value?.user?.id;

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
      final results = await Future.wait([
        ref.read(userRepositoryProvider).getById(widget.userId),
        ref.read(followsRepositoryProvider).getStats(widget.userId),
      ]);
      setState(() {
        _user = results[0] as AppUser;
        _stats = results[1] as FollowStats;
      });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _acting = true);
    try {
      final stats = _stats!.isFollowing == true
          ? await ref.read(followsRepositoryProvider).unfollow(widget.userId)
          : await ref.read(followsRepositoryProvider).follow(widget.userId);
      setState(() => _stats = stats);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_user?.name ?? 'Profile')),
      body: MaxWidthBox(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final user = _user!;
    final stats = _stats!;
    final callService = ref.watch(callServiceProvider);
    final myName = ref.watch(sessionControllerProvider).value?.user?.name ?? 'Someone';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              UserAvatar(avatarUrl: user.avatarUrl, radius: 44),
              const SizedBox(height: 12),
              Text(user.name ?? 'Someone', style: Theme.of(context).textTheme.headlineSmall),
              if (user.username != null) ...[
                const SizedBox(height: 2),
                Text('@${user.username}', style: const TextStyle(color: Colors.black54)),
              ],
              if (user.area != null) ...[
                const SizedBox(height: 4),
                Text(user.area!, style: const TextStyle(color: Colors.black54)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatColumn(
              value: stats.followerCount,
              label: 'Followers',
              onTap: () => context.push('/home/users/${widget.userId}/followers'),
            ),
            const SizedBox(width: 40),
            _StatColumn(
              value: stats.followingCount,
              label: 'Following',
              onTap: () => context.push('/home/users/${widget.userId}/following'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (!_isSelf)
          Row(
            children: [
              Expanded(
                child: stats.isFollowing == true
                    ? OutlinedButton(
                        onPressed: _acting ? null : _toggleFollow,
                        child: const Text('Following'),
                      )
                    : FilledButton(
                        onPressed: _acting ? null : _toggleFollow,
                        child: const Text('Follow'),
                      ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Message',
                onPressed: () => context.push(
                  '/home/messages/${user.id}',
                  extra: user.name,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.call),
                tooltip: 'Call (no number shared)',
                style: IconButton.styleFrom(backgroundColor: nikatOrange),
                onPressed:
                    callService == null ? null : () => callService.call(user.id, myName),
              ),
            ],
          ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final int value;
  final String label;
  final VoidCallback onTap;

  const _StatColumn({required this.value, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Text(
              '$value',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700, color: nikatNavy),
            ),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
