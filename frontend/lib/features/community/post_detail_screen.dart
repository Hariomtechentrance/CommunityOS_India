import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/post.dart';
import 'post_repository.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Post? _post;

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
      final post = await ref.read(postRepositoryProvider).getById(societyId, widget.postId);
      setState(() => _post = post);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addComment() async {
    final societyId = ref.read(sessionControllerProvider).value?.society?.id;
    if (societyId == null || _commentController.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(postRepositoryProvider)
          .addComment(societyId, widget.postId, _commentController.text.trim());
      _commentController.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: MaxWidthBox(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _post == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Chip(label: Text(postTypeLabel(_post!.type))),
                                      const SizedBox(height: 8),
                                      if (_post!.title != null)
                                        Text(
                                          _post!.title!,
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                      const SizedBox(height: 4),
                                      Text(_post!.body),
                                      const SizedBox(height: 4),
                                      Text(
                                        _post!.author?.phone ?? '',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text('Comments', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              ...?_post!.comments?.map(
                                (comment) => Card(
                                  child: ListTile(
                                    title: Text(comment.body),
                                    subtitle: Text(comment.author?.phone ?? ''),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    decoration: const InputDecoration(
                                      hintText: 'Add a comment...',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: _submitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.send),
                                  onPressed: _submitting ? null : _addComment,
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
