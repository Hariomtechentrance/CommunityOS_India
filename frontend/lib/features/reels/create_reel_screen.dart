import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../core/api_client.dart';
import '../../core/media_upload_service.dart';
import 'reels_repository.dart';

class CreateReelScreen extends ConsumerStatefulWidget {
  const CreateReelScreen({super.key});

  @override
  ConsumerState<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends ConsumerState<CreateReelScreen> {
  final _captionController = TextEditingController();
  XFile? _video;
  VideoPlayerController? _videoController;
  bool _loading = false;
  String? _error;

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    _videoController?.dispose();
    final controller = VideoPlayerController.networkUrl(Uri.parse(picked.path));
    await controller.initialize();
    controller.setLooping(true);
    controller.play();
    if (!mounted) return;
    setState(() {
      _video = picked;
      _videoController = controller;
    });
  }

  Future<void> _submit() async {
    if (_video == null) {
      setState(() => _error = 'Pick a video first.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final videoUrl = await MediaUploadService().uploadVideo(_video!);
      await ref.read(reelsRepositoryProvider).create(
            videoUrl: videoUrl,
            caption: _captionController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New reel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : InkWell(
                      onTap: _pickVideo,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.video_call_outlined, size: 48),
                              SizedBox(height: 8),
                              Text('Tap to pick a video'),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Caption (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Post reel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
