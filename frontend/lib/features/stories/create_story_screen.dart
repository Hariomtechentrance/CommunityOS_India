import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../core/api_client.dart';
import '../../core/media_upload_service.dart';
import '../../models/story.dart';
import 'story_repository.dart';

/// Minimal "share to story" flow - pick a photo or video, preview, post.
/// No filters/stickers on the story itself yet (see plan: deferred to a
/// later round alongside Reels/photo filters).
class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  XFile? _image;
  XFile? _video;
  VideoPlayerController? _videoController;
  bool _loading = false;
  String? _error;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _image = picked;
      _video = null;
      _videoController?.dispose();
      _videoController = null;
    });
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    _videoController?.dispose();
    final controller = VideoPlayerController.networkUrl(Uri.parse(picked.path));
    await controller.initialize();
    await controller.setLooping(true);
    await controller.play();
    if (!mounted) return;
    setState(() {
      _video = picked;
      _image = null;
      _videoController = controller;
    });
  }

  Future<void> _share() async {
    if (_image == null && _video == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final upload = MediaUploadService();
      String mediaUrl;
      StoryMediaType mediaType;
      if (_image != null) {
        mediaUrl = await upload.upload(_image!);
        mediaType = StoryMediaType.image;
      } else {
        mediaUrl = await upload.uploadVideo(_video!);
        mediaType = StoryMediaType.video;
      }
      await ref.read(storyRepositoryProvider).create(mediaUrl: mediaUrl, mediaType: mediaType);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = _image != null || _video != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('New story'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _image != null
                  ? Image.network(_image!.path, fit: BoxFit.contain)
                  : _videoController != null && _videoController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        )
                      : const Icon(Icons.add_photo_alternate, color: Colors.white54, size: 80),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('Photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Video'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: hasMedia && !_loading ? _share : null,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Share'),
                    ),
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
