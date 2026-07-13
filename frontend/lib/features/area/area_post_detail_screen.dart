import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/area_post.dart';
import '../calls/call_service.dart';
import 'area_post_kind_ui.dart';
import 'area_repository.dart';

class AreaPostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const AreaPostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<AreaPostDetailScreen> createState() => _AreaPostDetailScreenState();
}

class _AreaPostDetailScreenState extends ConsumerState<AreaPostDetailScreen> {
  bool _loading = true;
  String? _error;
  AreaPost? _post;
  List<AreaPostComment> _comments = [];
  final _commentController = TextEditingController();
  bool _postingComment = false;

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
      final results = await Future.wait([
        ref.read(areaRepositoryProvider).getById(widget.postId),
        ref.read(areaRepositoryProvider).listComments(widget.postId),
      ]);
      if (!mounted) return;
      setState(() {
        _post = results[0] as AreaPost;
        _comments = results[1] as List<AreaPostComment>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleInterest() async {
    try {
      await ref.read(areaRepositoryProvider).toggleInterest(widget.postId);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  Future<void> _toggleSave() async {
    try {
      final saved = await ref.read(areaRepositoryProvider).toggleSave(widget.postId);
      if (!mounted) return;
      setState(() {
        _post = AreaPost(
          id: _post!.id,
          area: _post!.area,
          pincode: _post!.pincode,
          latitude: _post!.latitude,
          longitude: _post!.longitude,
          kind: _post!.kind,
          visibility: _post!.visibility,
          title: _post!.title,
          description: _post!.description,
          imageUrls: _post!.imageUrls,
          videoUrl: _post!.videoUrl,
          videoTrimStart: _post!.videoTrimStart,
          videoTrimEnd: _post!.videoTrimEnd,
          audioUrl: _post!.audioUrl,
          location: _post!.location,
          sportName: _post!.sportName,
          serviceType: _post!.serviceType,
          businessCategory: _post!.businessCategory,
          offerText: _post!.offerText,
          businessHours: _post!.businessHours,
          emergencyCategory: _post!.emergencyCategory,
          activityTime: _post!.activityTime,
          partnersNeeded: _post!.partnersNeeded,
          createdAt: _post!.createdAt,
          user: _post!.user,
          interestCount: _post!.interestCount,
          myInterest: _post!.myInterest,
          mySaved: saved,
          interestedUsers: _post!.interestedUsers,
          distanceKm: _post!.distanceKm,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  Future<void> _addComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;
    setState(() => _postingComment = true);
    try {
      final comment = await ref.read(areaRepositoryProvider).addComment(widget.postId, body);
      if (!mounted) return;
      setState(() => _comments = [..._comments, comment]);
      _commentController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _postingComment = false);
    }
  }

  bool get _canCall {
    final myId = ref.read(sessionControllerProvider).value?.user?.id;
    return myId != null && _post?.user != null && _post!.user!.id != myId;
  }

  bool get _isOwner {
    final myId = ref.read(sessionControllerProvider).value?.user?.id;
    return myId != null && _post?.user?.id == myId;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          if (_post != null) ...[
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share',
              onPressed: () => shareAreaPost(_post!),
            ),
            IconButton(
              icon: Icon(_post!.mySaved ? Icons.bookmark : Icons.bookmark_border),
              tooltip: _post!.mySaved ? 'Saved' : 'Save',
              onPressed: _toggleSave,
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _post == null
                  ? const SizedBox.shrink()
                  : MaxWidthBox(
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                if (_post!.imageUrls.isNotEmpty)
                                  SizedBox(
                                    height: 220,
                                    child: PageView(
                                      children: _post!.imageUrls
                                          .map(
                                            (url) => ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                url,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) => const ColoredBox(
                                                  color: Color(0xFFEEEEEE),
                                                  child: Icon(Icons.image_not_supported),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                if (_post!.videoUrl != null) ...[
                                  const SizedBox(height: 16),
                                  _VideoAttachment(
                                    url: _post!.videoUrl!,
                                    trimStart: _post!.videoTrimStart,
                                    trimEnd: _post!.videoTrimEnd,
                                  ),
                                ],
                                if (_post!.audioUrl != null) ...[
                                  const SizedBox(height: 16),
                                  _AudioAttachment(url: _post!.audioUrl!),
                                ],
                                const SizedBox(height: 16),
                                Chip(label: Text(areaPostKindLabel(_post!.kind))),
                                const SizedBox(height: 8),
                                Text(_post!.title, style: Theme.of(context).textTheme.headlineSmall),
                                const SizedBox(height: 8),
                                Text(_post!.description),
                                if (_post!.location != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 18),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(_post!.location!)),
                                    ],
                                  ),
                                ],
                                if (_post!.kind == AreaPostKind.sportsInvite) ...[
                                  const SizedBox(height: 12),
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (_post!.sportName != null)
                                            _InfoRow(
                                              icon: Icons.sports,
                                              label: 'Activity',
                                              value: _post!.sportName!,
                                            ),
                                          if (_post!.activityTime != null)
                                            _InfoRow(
                                              icon: Icons.schedule,
                                              label: 'Time',
                                              value: _post!.activityTime!,
                                            ),
                                          if (_post!.partnersNeeded != null)
                                            _InfoRow(
                                              icon: Icons.people,
                                              label: 'Looking for',
                                              value:
                                                  '${_post!.partnersNeeded} partner${_post!.partnersNeeded == 1 ? '' : 's'}',
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                if (_post!.kind == AreaPostKind.shop &&
                                    _post!.businessHours != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 18),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(_post!.businessHours!)),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _post!.user?.name ?? 'Someone',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (_post!.user?.verified == true) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.verified,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (_canCall) ...[
                                      IconButton(
                                        icon: const Icon(Icons.chat_bubble_outline),
                                        tooltip: 'Message ${_post!.user?.name ?? ''}',
                                        onPressed: () => context.push(
                                          '/home/messages/${_post!.user!.id}',
                                          extra: _post!.user?.name,
                                        ),
                                      ),
                                      _CallButton(post: _post!),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (_isOwner) ...[
                                  Text(
                                    _post!.kind == AreaPostKind.emergencySos
                                        ? 'People who can help (${_post!.interestCount})'
                                        : 'Interested (${_post!.interestCount})',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  if ((_post!.interestedUsers ?? []).isEmpty)
                                    Text(
                                      _post!.kind == AreaPostKind.emergencySos
                                          ? 'No one has offered to help yet.'
                                          : 'No one yet - check back soon.',
                                    )
                                  else
                                    ...(_post!.interestedUsers ?? []).map(
                                      (person) => Card(
                                        child: ListTile(
                                          leading: UserAvatar(avatarUrl: person.avatarUrl),
                                          title: Text(person.name ?? 'Someone'),
                                          trailing: IconButton.filled(
                                            icon: const Icon(Icons.call),
                                            tooltip:
                                                'Call ${person.name ?? 'them'} (no number shared)',
                                            onPressed: () {
                                              final callService = ref.read(callServiceProvider);
                                              final myName = ref
                                                      .read(sessionControllerProvider)
                                                      .value
                                                      ?.user
                                                      ?.name ??
                                                  'Someone';
                                              callService?.call(person.id, myName);
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                ] else
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: _toggleInterest,
                                        icon: Icon(
                                          _post!.myInterest
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                        ),
                                        label: Text(_interestLabel),
                                      ),
                                    ],
                                  ),
                                const Divider(height: 32),
                                Text(
                                  'Comments (${_comments.length})',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                if (_comments.isEmpty)
                                  const Text('No comments yet.')
                                else
                                  ..._comments.map(
                                    (comment) => Card(
                                      child: ListTile(
                                        title: Text(comment.body),
                                        subtitle: Text(comment.author?.name ?? 'Someone'),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _commentController,
                                      decoration: const InputDecoration(
                                        hintText: 'Add a comment...',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: _postingComment
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.send),
                                    onPressed: _postingComment ? null : _addComment,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  String get _interestLabel {
    final label = switch (_post!.kind) {
      AreaPostKind.sportsInvite => "I'm Available",
      AreaPostKind.emergencySos => "I'm nearby, I can help",
      _ => "I'm interested",
    };
    final selectedLabel =
        _post!.kind == AreaPostKind.emergencySos ? 'Offered to help' : 'Interested';
    return _post!.myInterest
        ? '$selectedLabel (${_post!.interestCount})'
        : '$label (${_post!.interestCount})';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text('$label: ', style: Theme.of(context).textTheme.labelLarge),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Plays a post's attached video, clamped to its virtual trim range (see
/// create_area_post_screen.dart for why trimming is metadata-only on web).
class _VideoAttachment extends StatefulWidget {
  final String url;
  final double? trimStart;
  final double? trimEnd;

  const _VideoAttachment({required this.url, this.trimStart, this.trimEnd});

  @override
  State<_VideoAttachment> createState() => _VideoAttachmentState();
}

class _VideoAttachmentState extends State<_VideoAttachment> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.seekTo(Duration(milliseconds: ((widget.trimStart ?? 0) * 1000).round()));
      });
    _controller.addListener(_clampToTrim);
  }

  void _clampToTrim() {
    final end = widget.trimEnd;
    if (end == null) return;
    if (_controller.value.position.inMilliseconds / 1000 >= end) {
      _controller.pause();
      _controller.seekTo(Duration(milliseconds: ((widget.trimStart ?? 0) * 1000).round()));
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_clampToTrim);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            IconButton.filled(
              icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () => setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact play/pause row for a post's attached voice note.
class _AudioAttachment extends StatefulWidget {
  final String url;

  const _AudioAttachment({required this.url});

  @override
  State<_AudioAttachment> createState() => _AudioAttachmentState();
}

class _AudioAttachmentState extends State<_AudioAttachment> {
  final _player = ap.AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playing = state == ap.PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: IconButton.filled(
          icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
          onPressed: () async {
            if (_playing) {
              await _player.pause();
            } else {
              await _player.play(ap.UrlSource(widget.url));
            }
          },
        ),
        title: const Text('Voice note'),
      ),
    );
  }
}

class _CallButton extends ConsumerWidget {
  final AreaPost post;

  const _CallButton({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callService = ref.watch(callServiceProvider);
    final myName = ref.watch(sessionControllerProvider).value?.user?.name ?? 'Someone';
    return IconButton.filled(
      icon: const Icon(Icons.call),
      tooltip: 'Call ${post.user?.name ?? ''} (no number shared)',
      onPressed: callService == null ? null : () => callService.call(post.user!.id, myName),
    );
  }
}
