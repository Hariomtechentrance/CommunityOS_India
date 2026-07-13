import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/story.dart';
import '../../models/user.dart';
import 'story_repository.dart';
import 'story_viewers_sheet.dart';

const _imageStoryDuration = Duration(seconds: 5);

/// Full-screen tap-through viewer for one author's stories - progress-bar
/// segments at top, auto-advances, tap right/left edge to go forward/back.
class StoryViewerScreen extends ConsumerStatefulWidget {
  final AppUser author;
  final List<Story> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.author,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _index;
  late AnimationController _controller;
  VideoPlayerController? _videoController;
  ap.AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _advance();
      });
    _showCurrent();
  }

  Story get _current => widget.stories[_index];

  Future<void> _showCurrent() async {
    _controller.stop();
    _videoController?.dispose();
    _videoController = null;
    await _audioPlayer?.dispose();
    _audioPlayer = null;

    ref.read(storyRepositoryProvider).markViewed(_current.id);

    if (_current.mediaType == StoryMediaType.video) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(_current.mediaUrl));
      await controller.initialize();
      if (!mounted) return;
      setState(() => _videoController = controller);
      controller.play();
      _controller.duration = controller.value.duration;
    } else {
      _controller.duration = _imageStoryDuration;
      if (_current.audioUrl != null) {
        _audioPlayer = ap.AudioPlayer()..play(ap.UrlSource(_current.audioUrl!));
      }
    }
    _controller
      ..reset()
      ..forward();
  }

  void _advance() {
    if (_index >= widget.stories.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
    _showCurrent();
  }

  void _back() {
    if (_index <= 0) return;
    setState(() => _index--);
    _showCurrent();
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _openViewers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StoryViewersSheet(storyId: _current.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = ref.watch(sessionControllerProvider).value?.user?.id;
    final isMyStory = myUserId != null && myUserId == widget.author.id;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _current.mediaType == StoryMediaType.video
                  ? (_videoController != null && _videoController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        )
                      : const CircularProgressIndicator())
                  : Image.network(_current.mediaUrl, fit: BoxFit.contain),
            ),
            Row(
              children: [
                Expanded(child: GestureDetector(onTap: _back, behavior: HitTestBehavior.translucent)),
                Expanded(child: GestureDetector(onTap: _advance, behavior: HitTestBehavior.translucent)),
              ],
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(widget.stories.length, (i) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final value = i < _index ? 1.0 : (i > _index ? 0.0 : _controller.value);
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 3,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              top: 20,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  UserAvatar(avatarUrl: widget.author.avatarUrl, radius: 14),
                  const SizedBox(width: 8),
                  Text(widget.author.name ?? 'Someone', style: const TextStyle(color: Colors.white)),
                  const Spacer(),
                  if (isMyStory)
                    InkWell(
                      onTap: _openViewers,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.remove_red_eye, color: Colors.white, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${_current.viewCount ?? 0}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
