import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/goal_community.dart';
import 'create_goal_community_screen.dart';
import 'goal_communities_repository.dart';

class GoalCommunitiesListScreen extends ConsumerStatefulWidget {
  const GoalCommunitiesListScreen({super.key});

  @override
  ConsumerState<GoalCommunitiesListScreen> createState() => _GoalCommunitiesListScreenState();
}

class _GoalCommunitiesListScreenState extends ConsumerState<GoalCommunitiesListScreen> {
  bool _loading = true;
  String? _error;
  List<GoalCommunity> _communities = [];

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
      final communities = await ref.read(goalCommunitiesRepositoryProvider).list();
      setState(() => _communities = communities);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goal communities')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateGoalCommunityScreen()),
          );
          if (created == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Start a goal'),
      ),
      body: MaxWidthBox(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _communities.isEmpty
                      ? ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No goal communities yet. Start one - a 100-day coding '
                                'challenge, a 30-day fitness streak, anything with a daily '
                                'check-in.',
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _communities.length,
                          itemBuilder: (context, index) {
                            final c = _communities[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(c.title),
                                subtitle: Text(
                                  '${c.durationDays} days · ${c.memberCount} members'
                                  '${c.joinCostCoins > 0 ? ' · 🪙 ${c.joinCostCoins} to join' : ''}'
                                  '${c.joined ? ' · your streak: ${c.myStreak ?? 0} 🔥' : ''}',
                                ),
                                trailing: c.joined
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : null,
                                onTap: () async {
                                  await context.push('/home/goals/${c.id}');
                                  _load();
                                },
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
