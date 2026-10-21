import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/session/session_controller.dart';
import '../ai/ai_repository.dart';
import 'events_list_screen.dart';
import 'polls_list_screen.dart';
import 'posts_list_screen.dart';

class CommunityHomeScreen extends ConsumerWidget {
  const CommunityHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final societyId = ref.watch(sessionControllerProvider).value?.society?.id;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community'),
          actions: [
            if (societyId != null)
              IconButton(
                icon: const Icon(Icons.auto_awesome),
                tooltip: 'Ask the community',
                onPressed: () => context.push('/home/society/community/ask', extra: societyId),
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Feed'),
              Tab(text: 'Polls'),
              Tab(text: 'Events'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (societyId != null) _CommunitySummaryBanner(societyId: societyId),
            const Expanded(
              child: TabBarView(
                children: [
                  PostsListScreen(),
                  PollsListScreen(),
                  EventsListScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Today's community summary" - an AI digest of the last 7 days, collapsed
/// until tapped so it never pushes the feed down for people who don't care.
class _CommunitySummaryBanner extends ConsumerStatefulWidget {
  final String societyId;

  const _CommunitySummaryBanner({required this.societyId});

  @override
  ConsumerState<_CommunitySummaryBanner> createState() => _CommunitySummaryBannerState();
}

class _CommunitySummaryBannerState extends ConsumerState<_CommunitySummaryBanner> {
  bool _expanded = false;
  String? _summary;
  bool _loading = false;

  Future<void> _toggle() async {
    setState(() => _expanded = !_expanded);
    if (_expanded && _summary == null) {
      setState(() => _loading = true);
      try {
        final summary = await ref.read(aiRepositoryProvider).communitySummary(widget.societyId);
        if (mounted) setState(() => _summary = summary);
      } catch (_) {
        if (mounted) setState(() => _summary = "Couldn't load a summary right now.");
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text("Today's community summary"),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onTap: _toggle,
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Text(_summary ?? ''),
            ),
        ],
      ),
    );
  }
}
