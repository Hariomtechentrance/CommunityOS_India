import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';
import '../../core/api_client.dart';
import '../../core/media_upload_service.dart';
import '../../core/session/session_controller.dart';
import '../../models/area_post.dart';
import 'area_post_kind_ui.dart';
import 'area_repository.dart';

class CreateAreaPostScreen extends ConsumerStatefulWidget {
  final AreaPostKind initialKind;

  const CreateAreaPostScreen({super.key, required this.initialKind});

  @override
  ConsumerState<CreateAreaPostScreen> createState() => _CreateAreaPostScreenState();
}

class _CreateAreaPostScreenState extends ConsumerState<CreateAreaPostScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _sportController = TextEditingController();
  final _serviceController = TextEditingController();
  final _businessCategoryController = TextEditingController();
  final _offerController = TextEditingController();
  final _businessHoursController = TextEditingController();
  final _activityTimeController = TextEditingController();
  final _partnersNeededController = TextEditingController(text: '1');
  late AreaPostKind _kind;
  AreaPostVisibility _visibility = AreaPostVisibility.nearby;
  final List<XFile> _images = [];
  bool _loading = false;
  String? _error;

  // Video + virtual trim.
  XFile? _video;
  VideoPlayerController? _videoController;
  RangeValues _trimRange = const RangeValues(0, 0);

  // Voice note.
  final _recorder = AudioRecorder();
  final _audioPlayer = ap.AudioPlayer();
  bool _recording = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(limit: 5);
    if (picked.isEmpty) return;
    setState(() {
      _images
        ..clear()
        ..addAll(picked.take(5));
    });
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    _videoController?.dispose();
    final controller = VideoPlayerController.networkUrl(Uri.parse(picked.path));
    await controller.initialize();
    if (!mounted) return;
    setState(() {
      _video = picked;
      _videoController = controller;
      _trimRange = RangeValues(0, controller.value.duration.inMilliseconds / 1000);
    });
  }

  void _removeVideo() {
    _videoController?.dispose();
    setState(() {
      _video = null;
      _videoController = null;
      _trimRange = const RangeValues(0, 0);
    });
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() {
        _recording = false;
        _audioPath = path;
      });
      return;
    }
    if (!await _recorder.hasPermission()) {
      setState(() => _error = 'Microphone permission is needed to record a voice note.');
      return;
    }
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: 'voice-note.m4a');
    setState(() {
      _recording = true;
      _audioPath = null;
    });
  }

  void _removeAudio() {
    setState(() => _audioPath = null);
  }

  Future<void> _submit() async {
    final user = ref.read(sessionControllerProvider).value?.user;
    if (user?.area == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final upload = MediaUploadService();
      List<String>? imageUrls;
      if (_images.isNotEmpty) {
        imageUrls = await upload.uploadAll(_images);
      }
      String? videoUrl;
      if (_video != null) {
        videoUrl = await upload.uploadVideo(_video!);
      }
      String? audioUrl;
      if (_audioPath != null) {
        final bytes = await XFile(_audioPath!).readAsBytes();
        audioUrl = await upload.uploadAudio(bytes, 'voice-note.m4a');
      }
      await ref.read(areaRepositoryProvider).create(
            area: user!.area!,
            kind: _kind,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            imageUrls: imageUrls,
            location: _locationController.text.trim(),
            sportName: _sportController.text.trim(),
            visibility: _visibility,
            serviceType: _serviceController.text.trim(),
            businessCategory: _businessCategoryController.text.trim(),
            offerText: _offerController.text.trim(),
            videoUrl: videoUrl,
            videoTrimStart: videoUrl != null ? _trimRange.start : null,
            videoTrimEnd: videoUrl != null ? _trimRange.end : null,
            audioUrl: audioUrl,
            businessHours: _businessHoursController.text.trim(),
            activityTime: _activityTimeController.text.trim(),
            partnersNeeded: _kind == AreaPostKind.sportsInvite
                ? int.tryParse(_partnersNeededController.text.trim())
                : null,
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
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _sportController.dispose();
    _serviceController.dispose();
    _businessCategoryController.dispose();
    _offerController.dispose();
    _businessHoursController.dispose();
    _activityTimeController.dispose();
    _partnersNeededController.dispose();
    _videoController?.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPincode = (ref.watch(sessionControllerProvider).value?.user?.pincode ?? '').isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('New post')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allAreaPostKinds
                      .map(
                        (kind) => ChoiceChip(
                          avatar: Icon(areaPostKindIcon(kind), size: 18),
                          label: Text(areaPostKindLabel(kind)),
                          selected: _kind == kind,
                          onSelected: (_) => setState(() => _kind = kind),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    hintText: 'Near Satpur MIDC signal',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_kind == AreaPostKind.sportsInvite) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sportController,
                    decoration: const InputDecoration(
                      labelText: 'Activity',
                      hintText: 'Badminton',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _activityTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Time (optional)',
                      hintText: '6:00 PM - 7:00 PM',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _partnersNeededController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Partners needed',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (_kind == AreaPostKind.serviceRequest) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _serviceController,
                    decoration: const InputDecoration(
                      labelText: 'Service needed',
                      hintText: 'Maid / Driver / Housekeeping',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (_kind == AreaPostKind.shop) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _businessCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'Business category (optional)',
                      hintText: 'Restaurant / Clinic / Grocery',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _offerController,
                    decoration: const InputDecoration(
                      labelText: 'Ongoing offer (optional)',
                      hintText: '20% off this week',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _businessHoursController,
                    decoration: const InputDecoration(
                      labelText: 'Business hours (optional)',
                      hintText: '8 AM - 10 PM',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text('Visible to', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<AreaPostVisibility>(
                  segments: const [
                    ButtonSegment(
                      value: AreaPostVisibility.nearby,
                      label: Text('Nearby'),
                      icon: Icon(Icons.travel_explore, size: 18),
                    ),
                    ButtonSegment(
                      value: AreaPostVisibility.pincodeOnly,
                      label: Text('My pincode only'),
                      icon: Icon(Icons.local_post_office, size: 18),
                    ),
                  ],
                  selected: {_visibility},
                  onSelectionChanged: (selection) =>
                      setState(() => _visibility = selection.first),
                ),
                if (_visibility == AreaPostVisibility.pincodeOnly && !hasPincode) ...[
                  const SizedBox(height: 4),
                  Text(
                    'You haven\'t saved a pincode yet, so this will behave like '
                    '"Nearby" until you add one in My Profile.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                Text('Attach media (optional)', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_a_photo),
                      label: Text(
                        _images.isEmpty ? 'Add photos' : '${_images.length} photo(s) selected',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _video == null ? _pickVideo : _removeVideo,
                      icon: Icon(_video == null ? Icons.videocam : Icons.close),
                      label: Text(_video == null ? 'Add video' : 'Remove video'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _toggleRecording,
                      icon: Icon(_recording ? Icons.stop_circle : Icons.mic),
                      label: Text(_recording ? 'Stop recording' : 'Record voice note'),
                    ),
                  ],
                ),
                if (_videoController != null && _videoController!.value.isInitialized) ...[
                  const SizedBox(height: 12),
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trim: ${_trimRange.start.toStringAsFixed(1)}s - '
                    '${_trimRange.end.toStringAsFixed(1)}s',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  RangeSlider(
                    values: _trimRange,
                    min: 0,
                    max: _videoController!.value.duration.inMilliseconds / 1000,
                    onChanged: (values) => setState(() => _trimRange = values),
                  ),
                ],
                if (_audioPath != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _audioPlayer.play(ap.UrlSource(_audioPath!)),
                      ),
                      const Expanded(child: Text('Voice note recorded')),
                      IconButton(icon: const Icon(Icons.delete_outline), onPressed: _removeAudio),
                    ],
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
