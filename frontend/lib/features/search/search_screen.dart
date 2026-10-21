import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/society.dart';
import 'search_repository.dart';

/// One search box across people, communities, posts and goal communities -
/// a distinct "search everything" entry point alongside the existing
/// people-only search (UserSearchScreen).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  SearchResults? _results;

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref.read(searchRepositoryProvider).searchAll(query);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search people, communities, posts, goals...',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _results == null
                  ? const Center(child: Text('Start typing to search everything.'))
                  : _results!.isEmpty
                      ? const Center(child: Text('No results.'))
                      : ListView(
                          children: [
                            if (_results!.users.isNotEmpty) ...[
                              const _SectionHeader('People'),
                              ..._results!.users.map(
                                (u) => ListTile(
                                  leading: UserAvatar(avatarUrl: u.avatarUrl),
                                  title: Text(u.name ?? 'Someone'),
                                  subtitle: u.area != null ? Text(u.area!) : null,
                                  onTap: () => context.push('/home/users/${u.id}'),
                                ),
                              ),
                            ],
                            if (_results!.communities.isNotEmpty) ...[
                              const _SectionHeader('Communities'),
                              ..._results!.communities.map(
                                (c) => ListTile(
                                  leading: Icon(
                                    c.type == SocietyType.college
                                        ? Icons.school
                                        : Icons.apartment,
                                  ),
                                  title: Text(c.name),
                                  subtitle: Text('${c.city}, ${c.state}'),
                                ),
                              ),
                            ],
                            if (_results!.posts.isNotEmpty) ...[
                              const _SectionHeader('Posts'),
                              ..._results!.posts.map(
                                (p) => ListTile(
                                  leading: const Icon(Icons.article_outlined),
                                  title: Text(p.title),
                                  subtitle: Text(
                                    p.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => context.push('/home/posts/${p.id}'),
                                ),
                              ),
                            ],
                            if (_results!.goalCommunities.isNotEmpty) ...[
                              const _SectionHeader('Goal communities'),
                              ..._results!.goalCommunities.map(
                                (g) => ListTile(
                                  leading: const Icon(Icons.local_fire_department_outlined),
                                  title: Text(g.title),
                                  subtitle: Text('${g.durationDays} days'),
                                  onTap: () => context.push('/home/goals/${g.id}'),
                                ),
                              ),
                            ],
                          ],
                        ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
