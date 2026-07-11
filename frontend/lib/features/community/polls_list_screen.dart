import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/poll.dart';
import 'create_poll_screen.dart';
import 'poll_repository.dart';

class PollsListScreen extends ConsumerStatefulWidget {
  const PollsListScreen({super.key});

  @override
  ConsumerState<PollsListScreen> createState() => _PollsListScreenState();
}

class _PollsListScreenState extends ConsumerState<PollsListScreen> {
  bool _loading = true;
  String? _error;
  List<Poll> _polls = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final societyId = ref.read(sessionControllerProvider).value?.society?.id;
    if (societyId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final polls = await ref.read(pollRepositoryProvider).list(societyId);
      setState(() => _polls = polls);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _vote(Poll poll, String optionId) async {
    final societyId = ref.read(sessionControllerProvider).value?.society?.id;
    if (societyId == null) return;
    try {
      await ref.read(pollRepositoryProvider).vote(societyId, poll.id, optionId);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreatePollScreen()),
          );
          if (created == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('New poll'),
      ),
      body: MaxWidthBox(
        child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _polls.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No polls yet.'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _polls.length,
                        itemBuilder: (context, index) {
                          final poll = _polls[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(poll.question,
                                      style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  ...poll.options.map((option) {
                                    final voted = poll.myVoteOptionId == option.id;
                                    final total = poll.totalVotes;
                                    final pct = total == 0
                                        ? 0.0
                                        : option.voteCount / total;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: InkWell(
                                        onTap: () => _vote(poll, option.id),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  voted
                                                      ? Icons.radio_button_checked
                                                      : Icons.radio_button_unchecked,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(child: Text(option.label)),
                                                Text('${option.voteCount}'),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(value: pct),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
        ),
      ),
    );
  }
}
