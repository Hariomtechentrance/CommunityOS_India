import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/relative_time.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/area_post.dart';
import '../area/area_post_kind_ui.dart';
import '../area/area_repository.dart';
import '../area/create_area_post_screen.dart';
import '../emergency/emergency_sos_screen.dart';
import '../live/go_live_screen.dart';
import '../live/live_now_bar.dart';
import '../stories/stories_bar.dart';

/// Primary screen after login: a social-style feed of everything posted in
/// this app for your area - shops, help requests, sports invites, updates,
/// and so on. The map view is one tap away (AppBar action) for anyone who
/// wants to see things spatially instead. Reached only once the user has
/// completed location onboarding (see LocationSetupScreen).
class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  AreaPostKind? _filter;
  bool _loading = true;
  String? _error;
  List<AreaPost> _posts = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(sessionControllerProvider).value?.user;
    if (user?.area == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await ref.read(areaRepositoryProvider).list(user!.area!, kind: _filter);
      setState(() => _posts = posts);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AreaPost> get _visiblePosts {
    if (_query.trim().isEmpty) return _posts;
    final q = _query.trim().toLowerCase();
    return _posts.where((post) {
      return post.title.toLowerCase().contains(q) ||
          post.description.toLowerCase().contains(q) ||
          (post.user?.name?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).value?.user;
    final posts = _visiblePosts;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.area ?? 'CommunityOS India'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'View on map',
            onPressed: () => context.push('/home/map'),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(user?.name ?? 'You', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(user?.area ?? ''),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('My profile'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/home/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Messages'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/home/messages');
                },
              ),
              ListTile(
                leading: const Icon(Icons.apartment),
                title: const Text('My society'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/home/society');
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log out'),
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(sessionControllerProvider.notifier).logout();
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'sos-fab',
            backgroundColor: Colors.red.shade700,
            tooltip: 'Emergency SOS',
            onPressed: () async {
              final posted = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const EmergencySosScreen()),
              );
              if (posted == true) _load();
            },
            child: const Icon(Icons.emergency, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'go-live-fab',
            tooltip: 'Go live',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GoLiveScreen()),
              );
            },
            child: const Icon(Icons.videocam),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'new-post-fab',
            onPressed: () async {
              final posted = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CreateAreaPostScreen(initialKind: _filter ?? AreaPostKind.update),
                ),
              );
              if (posted == true) _load();
            },
            icon: const Icon(Icons.add),
            label: const Text('New post'),
          ),
        ],
      ),
      body: MaxWidthBox(
        child: Column(
        children: [
          const StoriesBar(),
          const LiveNowBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search posts, shops, people...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _filter == null,
                    onSelected: (_) {
                      setState(() => _filter = null);
                      _load();
                    },
                  ),
                  const SizedBox(width: 8),
                  ...allAreaPostKinds.map(
                    (kind) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(areaPostKindIcon(kind), size: 18),
                        label: Text(areaPostKindLabel(kind)),
                        selected: _filter == kind,
                        onSelected: (_) {
                          setState(() => _filter = kind);
                          _load();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : posts.isEmpty
                          ? ListView(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    _query.isNotEmpty
                                        ? 'No posts match "$_query".'
                                        : 'Nothing here yet. Be the first to post.',
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: posts.length,
                              itemBuilder: (context, index) => _PostCard(
                                post: posts[index],
                                onTap: () => context.push('/home/posts/${posts[index].id}'),
                                onChanged: _load,
                              ),
                            ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

/// Cloudinary auto-generates a JPG frame for any uploaded video at the same
/// path with a `.jpg` extension - used as a lightweight feed thumbnail
/// instead of loading the whole video player per card.
String _videoThumbnailUrl(String videoUrl) {
  final lastDot = videoUrl.lastIndexOf('.');
  if (lastDot == -1) return videoUrl;
  return '${videoUrl.substring(0, lastDot)}.jpg';
}

class _PostCard extends ConsumerWidget {
  final AreaPost post;
  final VoidCallback onTap;
  final VoidCallback onChanged;

  const _PostCard({required this.post, required this.onTap, required this.onChanged});

  String? get _posterLocation {
    final u = post.user;
    if (u == null) return null;
    final parts = [u.area, u.city].where((p) => p != null && p.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  Future<void> _toggleInterest(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(areaRepositoryProvider).toggleInterest(post.id);
      onChanged();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  Future<void> _toggleSave(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(areaRepositoryProvider).toggleSave(post.id);
      onChanged();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = post.user?.name ?? 'Someone';
    final hasImage = post.imageUrls.isNotEmpty;
    final hasVideo = post.videoUrl != null;
    final hasAudio = post.audioUrl != null && !hasVideo;
    final locationLine = _posterLocation;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: Theme.of(context).textTheme.titleSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (post.user?.verified == true) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                        if (locationLine != null)
                          Text(
                            locationLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        Text(
                          relativeTime(post.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(areaPostKindIcon(post.kind), size: 16),
                    label: Text(areaPostKindLabel(post.kind)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(post.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                post.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (post.kind == AreaPostKind.sportsInvite &&
                  (post.sportName != null ||
                      post.activityTime != null ||
                      post.partnersNeeded != null)) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.sportName != null) Text('Activity: ${post.sportName}'),
                      if (post.activityTime != null) Text('Time: ${post.activityTime}'),
                      if (post.partnersNeeded != null)
                        Text('Looking for: ${post.partnersNeeded} partner(s)'),
                    ],
                  ),
                ),
              ],
              if (hasImage || hasVideo) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          hasImage ? post.imageUrls.first : _videoThumbnailUrl(post.videoUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.image, size: 40),
                          ),
                        ),
                        if (hasVideo)
                          Container(
                            color: Colors.black26,
                            child: const Icon(
                              Icons.play_circle_fill,
                              size: 56,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (hasAudio) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.mic, size: 18),
                      SizedBox(width: 8),
                      Text('Voice note attached'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _PostActionButton(
                    icon: post.myInterest ? Icons.favorite : Icons.favorite_border,
                    label: 'Interested (${post.interestCount})',
                    onTap: () => _toggleInterest(ref, context),
                  ),
                  _PostActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Comment',
                    onTap: onTap,
                  ),
                  _PostActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () => shareAreaPost(post),
                  ),
                  _PostActionButton(
                    icon: post.mySaved ? Icons.bookmark : Icons.bookmark_border,
                    label: 'Save',
                    onTap: () => _toggleSave(ref, context),
                  ),
                ],
              ),
              if (post.kind == AreaPostKind.sportsInvite) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _toggleInterest(ref, context),
                    icon: Icon(post.myInterest ? Icons.check_circle : Icons.people),
                    label: Text(post.myInterest ? "You're in!" : "I'm Available"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PostActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PostActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
