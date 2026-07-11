import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/area_post.dart';
import 'area_post_kind_ui.dart';
import 'area_repository.dart';

/// Reachable from the Profile tab - everything the user has bookmarked via
/// the Save button on a post/business card.
class SavedPostsScreen extends ConsumerStatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  ConsumerState<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends ConsumerState<SavedPostsScreen> {
  bool _loading = true;
  String? _error;
  List<AreaPost> _posts = [];

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
      final posts = await ref.read(areaRepositoryProvider).listSaved();
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
      appBar: AppBar(title: const Text('Saved posts')),
      body: MaxWidthBox(
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
                              child: Text('Nothing saved yet - tap the bookmark icon on any post.'),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
                            final post = _posts[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: Icon(areaPostKindIcon(post.kind)),
                                title: Text(post.title),
                                subtitle: Text(areaPostKindLabel(post.kind)),
                                onTap: () => context.push('/home/posts/${post.id}'),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
