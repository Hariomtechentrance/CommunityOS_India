import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/reel.dart';
import 'reels_repository.dart';

class ReelCommentsSheet extends ConsumerStatefulWidget {
  final String reelId;

  const ReelCommentsSheet({super.key, required this.reelId});

  @override
  ConsumerState<ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends ConsumerState<ReelCommentsSheet> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _posting = false;
  String? _error;
  List<ReelComment> _comments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final comments = await ref.read(reelsRepositoryProvider).listComments(widget.reelId);
      if (!mounted) return;
      setState(() => _comments = comments);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _post() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    setState(() => _posting = true);
    try {
      final comment = await ref.read(reelsRepositoryProvider).addComment(widget.reelId, body);
      if (!mounted) return;
      setState(() => _comments = [..._comments, comment]);
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Comments', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _comments.isEmpty
                          ? const Center(child: Text('No comments yet.'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                final c = _comments[index];
                                return ListTile(
                                  leading: UserAvatar(avatarUrl: c.author?.avatarUrl),
                                  title: Text(c.author?.name ?? 'Someone'),
                                  subtitle: Text(c.body),
                                );
                              },
                            ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _posting ? null : _post,
                      icon: _posting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
