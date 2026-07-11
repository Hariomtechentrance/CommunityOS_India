import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/post.dart';
import 'create_post_screen.dart';
import 'post_repository.dart';

class PostsListScreen extends ConsumerStatefulWidget {
  const PostsListScreen({super.key});

  @override
  ConsumerState<PostsListScreen> createState() => _PostsListScreenState();
}

class _PostsListScreenState extends ConsumerState<PostsListScreen> {
  bool _loading = true;
  String? _error;
  List<Post> _posts = [];
  PostType? _filter;

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
      final posts = await ref.read(postRepositoryProvider).list(societyId, type: _filter);
      setState(() => _posts = posts);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final posted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (posted == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('New post'),
      ),
      body: MaxWidthBox(
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == null,
                  onSelected: (_) {
                    setState(() => _filter = null);
                    _load();
                  },
                ),
                ...PostType.values.map(
                  (type) => ChoiceChip(
                    label: Text(postTypeLabel(type)),
                    selected: _filter == type,
                    onSelected: (_) {
                      setState(() => _filter = type);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _posts.isEmpty
                          ? ListView(
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('No posts yet. Be the first to share something.'),
                                ),
                              ],
                            )
                          : ListView.builder(
                              itemCount: _posts.length,
                              itemBuilder: (context, index) {
                                final post = _posts[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    onTap: () =>
                                        context.push('/home/society/community/posts/${post.id}'),
                                    title: Text(post.title ?? postTypeLabel(post.type)),
                                    subtitle: Text(
                                      post.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Chip(
                                          label: Text(
                                            postTypeLabel(post.type),
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.comment, size: 14),
                                            const SizedBox(width: 4),
                                            Text('${post.commentCount}'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
