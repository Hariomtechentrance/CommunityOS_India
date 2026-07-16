import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/reel.dart';
import 'create_reel_screen.dart';
import 'reel_comments_sheet.dart';
import 'reels_repository.dart';

/// Full-screen vertical swipe feed of permanent short videos - a dedicated
/// section separate from the regular area feed's video posts (those stay
/// inline/trimmed within a normal post; these autoplay one-at-a-time,
/// TikTok/Reels-style).
class ReelsFeedScreen extends ConsumerStatefulWidget {
  const ReelsFeedScreen({super.key});

  @override
  ConsumerState<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends ConsumerState<ReelsFeedScreen> {
  final _pageController = PageController();
  bool _loading = true;
  String? _error;
  List<Reel> _reels = [];
  int _currentIndex = 0;
  int _page = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load({bool append = false}) async {
    setState(() {
      _loading = true;
      if (!append) _error = null;
    });
    try {
      final result = await ref.read(reelsRepositoryProvider).list(page: append ? _page + 1 : 1);
      if (!mounted) return;
      setState(() {
        _reels = append ? [..._reels, ...result.items] : result.items;
        _page = result.page;
        _hasMore = result.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    if (index >= _reels.length - 2 && _hasMore && !_loading) {
      _load(append: true);
    }
  }

  Future<void> _openCreate() async {
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateReelScreen()),
    );
    if (posted == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_loading && _reels.isEmpty)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_error != null)
            Center(
              child: Text(_error!, style: const TextStyle(color: Colors.white)),
            )
          else if (_reels.isEmpty)
            const Center(
              child: Text('No reels yet - be the first to post one!',
                  style: TextStyle(color: Colors.white)),
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _reels.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) => _ReelPage(
                key: ValueKey(_reels[index].id),
                reel: _reels[index],
                isActive: index == _currentIndex,
                onChanged: (updated) => setState(() => _reels[index] = updated),
                onDeleted: () =>
                    setState(() => _reels.removeWhere((r) => r.id == _reels[index].id)),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reels',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _openCreate,
                    tooltip: 'New reel',
                    style: IconButton.styleFrom(backgroundColor: nikatOrange),
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelPage extends ConsumerStatefulWidget {
  final Reel reel;
  final bool isActive;
  final ValueChanged<Reel> onChanged;
  final VoidCallback onDeleted;

  const _ReelPage({
    super.key,
    required this.reel,
    required this.isActive,
    required this.onChanged,
    required this.onDeleted,
  });

  @override
  ConsumerState<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends ConsumerState<_ReelPage> {
  VideoPlayerController? _controller;
  bool _liking = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl));
    await controller.initialize();
    controller.setLooping(true);
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() => _controller = controller);
    if (widget.isActive) controller.play();
  }

  @override
  void didUpdateWidget(covariant _ReelPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller == null) return;
    if (widget.isActive && !oldWidget.isActive) {
      _controller!.play();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller!.pause();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_liking) return;
    setState(() => _liking = true);
    try {
      final liked = await ref.read(reelsRepositoryProvider).toggleLike(widget.reel.id);
      widget.onChanged(
        Reel(
          id: widget.reel.id,
          videoUrl: widget.reel.videoUrl,
          caption: widget.reel.caption,
          createdAt: widget.reel.createdAt,
          user: widget.reel.user,
          likeCount: widget.reel.likeCount + (liked ? 1 : -1),
          commentCount: widget.reel.commentCount,
          myLiked: liked,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReelCommentsSheet(reelId: widget.reel.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final myId = ref.watch(sessionControllerProvider).value?.user?.id;

    return GestureDetector(
      onTap: () {
        final controller = _controller;
        if (controller == null) return;
        controller.value.isPlaying ? controller.pause() : controller.play();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          Positioned(
            left: 12,
            right: 80,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: reel.user == null
                      ? null
                      : () => context.push('/home/users/${reel.user!.id}'),
                  child: Row(
                    children: [
                      UserAvatar(avatarUrl: reel.user?.avatarUrl, radius: 16),
                      const SizedBox(width: 8),
                      Text(
                        reel.user?.name ?? 'Someone',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (reel.caption != null && reel.caption!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(reel.caption!, style: const TextStyle(color: Colors.white)),
                ],
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 24,
            child: Column(
              children: [
                IconButton(
                  onPressed: _toggleLike,
                  icon: Icon(
                    reel.myLiked ? Icons.favorite : Icons.favorite_border,
                    color: reel.myLiked ? nikatOrange : Colors.white,
                    size: 30,
                  ),
                ),
                Text('${reel.likeCount}', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                IconButton(
                  onPressed: _openComments,
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                ),
                Text('${reel.commentCount}', style: const TextStyle(color: Colors.white)),
                if (reel.user?.id == myId) ...[
                  const SizedBox(height: 16),
                  IconButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete this reel?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      await ref.read(reelsRepositoryProvider).delete(reel.id);
                      widget.onDeleted();
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
