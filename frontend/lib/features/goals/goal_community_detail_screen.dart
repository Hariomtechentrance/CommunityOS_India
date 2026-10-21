import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/goal_community.dart';
import 'goal_communities_repository.dart';

class GoalCommunityDetailScreen extends ConsumerStatefulWidget {
  final String goalCommunityId;

  const GoalCommunityDetailScreen({super.key, required this.goalCommunityId});

  @override
  ConsumerState<GoalCommunityDetailScreen> createState() => _GoalCommunityDetailScreenState();
}

class _GoalCommunityDetailScreenState extends ConsumerState<GoalCommunityDetailScreen> {
  bool _loading = true;
  bool _acting = false;
  String? _error;
  GoalCommunity? _community;
  List<GoalLeaderboardEntry> _leaderboard = [];

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
      final repo = ref.read(goalCommunitiesRepositoryProvider);
      final results = await Future.wait([
        repo.getById(widget.goalCommunityId),
        repo.leaderboard(widget.goalCommunityId),
      ]);
      setState(() {
        _community = results[0] as GoalCommunity;
        _leaderboard = results[1] as List<GoalLeaderboardEntry>;
      });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleJoin() async {
    if (!_community!.joined && _community!.joinCostCoins > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Join this community?'),
          content: Text(
            'This costs 🪙 ${_community!.joinCostCoins} coins, paid once to the creator.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Pay & join'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _acting = true);
    try {
      final repo = ref.read(goalCommunitiesRepositoryProvider);
      if (_community!.joined) {
        await repo.leave(widget.goalCommunityId);
      } else {
        await repo.join(widget.goalCommunityId);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _checkIn() async {
    setState(() => _acting = true);
    try {
      await ref.read(goalCommunitiesRepositoryProvider).checkIn(widget.goalCommunityId);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checked in! Streak: ${_community!.myStreak} 🔥')),
      );
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
      appBar: AppBar(title: Text(_community?.title ?? 'Goal community')),
      body: MaxWidthBox(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(_community!.description),
                        const SizedBox(height: 8),
                        Text(
                          '${_community!.durationDays} days · ${_community!.memberCount} members'
                          '${_community!.joinCostCoins > 0 ? ' · 🪙 ${_community!.joinCostCoins} to join' : ''}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _community!.joined
                                  ? OutlinedButton(
                                      onPressed: _acting ? null : _toggleJoin,
                                      child: const Text('Leave'),
                                    )
                                  : FilledButton(
                                      onPressed: _acting ? null : _toggleJoin,
                                      child: const Text('Join'),
                                    ),
                            ),
                          ],
                        ),
                        if (_community!.joined) ...[
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    '🔥 ${_community!.myStreak ?? 0} day streak',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  Text('Best: ${_community!.myLongestStreak ?? 0} days'),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: (_acting || _community!.checkedInToday)
                                        ? null
                                        : _checkIn,
                                    icon: const Icon(Icons.check),
                                    label: Text(
                                      _community!.checkedInToday
                                          ? 'Checked in today'
                                          : 'Check in today',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text('Leaderboard', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (_leaderboard.isEmpty)
                          const Text('No check-ins yet.')
                        else
                          ..._leaderboard.asMap().entries.map(
                                (entry) => ListTile(
                                  leading: Text('#${entry.key + 1}'),
                                  title: Row(
                                    children: [
                                      UserAvatar(avatarUrl: entry.value.user.avatarUrl, radius: 16),
                                      const SizedBox(width: 8),
                                      Text(entry.value.user.name ?? 'Someone'),
                                    ],
                                  ),
                                  trailing: Text('🔥 ${entry.value.currentStreak}'),
                                ),
                              ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
