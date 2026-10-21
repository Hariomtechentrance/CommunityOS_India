import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'ai_repository.dart';

class _QA {
  final String question;
  String? answer;
  bool loading = true;

  _QA(this.question);
}

/// "Ask the community" - answers grounded only in this society's last 7
/// days of notices/events/posts (see AiService.recentContext on the
/// backend), not general knowledge - so it never makes something up about
/// this specific community.
class CommunityAssistantScreen extends ConsumerStatefulWidget {
  final String societyId;

  const CommunityAssistantScreen({super.key, required this.societyId});

  @override
  ConsumerState<CommunityAssistantScreen> createState() => _CommunityAssistantScreenState();
}

class _CommunityAssistantScreenState extends ConsumerState<CommunityAssistantScreen> {
  final _controller = TextEditingController();
  final List<_QA> _history = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    _controller.clear();
    final qa = _QA(question);
    setState(() => _history.add(qa));

    try {
      final answer = await ref.read(aiRepositoryProvider).askCommunity(widget.societyId, question);
      setState(() => qa.answer = answer);
    } catch (e) {
      setState(() => qa.answer = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => qa.loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask the community')),
      body: Column(
        children: [
          Expanded(
            child: _history.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Ask anything about this community\'s recent notices, '
                        'events, and posts - e.g. "Any meetups this week?"',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final qa = _history[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: Card(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(qa.question),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: qa.loading
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(qa.answer ?? ''),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Ask a question...'),
                      onSubmitted: (_) => _ask(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send), onPressed: _ask),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
