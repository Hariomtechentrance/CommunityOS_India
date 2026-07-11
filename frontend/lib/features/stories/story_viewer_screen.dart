import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../models/story.dart';
import 'story_repository.dart';

const _imageStoryDuration = Duration(seconds: 5);

/// Full-screen tap-through viewer for one author's stories - progress-bar
/// segments at top, auto-advances, tap right/left edge to go forward/back.
class StoryViewerScreen extends ConsumerStatefulWidget {
  final String authorName;
  final List<Story> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.authorName,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
                  const SizedBox(width: 8),
                  Text(widget.authorName, style: const TextStyle(color: Colors.white)),
                  const Spacer(),
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
