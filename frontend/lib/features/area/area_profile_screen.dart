import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api_client.dart';
import '../../core/media_upload_service.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/area_post.dart';
import '../../models/user.dart';
import '../../core/widgets/user_avatar.dart';
import '../calls/call_service.dart';
import '../profile/avatar_picker_screen.dart';
import '../users/user_repository.dart';
import 'area_post_kind_ui.dart';
import 'area_repository.dart';
import 'create_area_post_screen.dart';

class AreaProfileScreen extends ConsumerStatefulWidget {
  const AreaProfileScreen({super.key});

  @override
  ConsumerState<AreaProfileScreen> createState() => _AreaProfileScreenState();
}

class _AreaProfileScreenState extends ConsumerState<AreaProfileScreen> {
  bool _loading = true;
  String? _error;
  List<AppUser> _neighbours = [];
  List<AreaPost> _myPosts = [];
  bool _uploadingAvatar = false;

  Future<void> _applyAvatar(String url) async {
    setState(() => _uploadingAvatar = true);
    try {
      await ref.read(userRepositoryProvider).updateAvatar(url);
      await ref.read(sessionControllerProvider.notifier).refreshUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final url = await MediaUploadService().upload(file);
    await _applyAvatar(url);
  }

  Future<void> _chooseAvatarSource() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Choose photo'),
              onTap: () => Navigator.of(context).pop('photo'),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Generate avatar'),
              onTap: () => Navigator.of(context).pop('generate'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'photo') {
      await _pickAndUploadPhoto();
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AvatarPickerScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(sessionControllerProvider).value?.user;
    if (user?.area == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ref.read(userRepositoryProvider).listNeighbours(user!.area!),
        ref.read(areaRepositoryProvider).list(user.area!, mine: true),
      ]);
      setState(() {
        _neighbours = results[0] as List<AppUser>;
        _myPosts = results[1] as List<AreaPost>;
      });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).value?.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: 'Saved posts',
            onPressed: () => context.push('/home/saved'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_location_alt),
            tooltip: 'Edit address / area',
            onPressed: () async {
              await context.push('/home/profile/edit-location');
              _load();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final posted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const CreateAreaPostScreen(initialKind: AreaPostKind.update),
            ),
          );
          if (posted == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('New post'),
      ),
      body: MaxWidthBox(
        child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _uploadingAvatar ? null : _chooseAvatarSource,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundImage: user.avatarUrl != null
                                          ? NetworkImage(user.avatarUrl!)
                                          : null,
                                      child: _uploadingAvatar
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : user.avatarUrl == null
                                              ? const Icon(Icons.person, size: 32)
                                              : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: CircleAvatar(
                                        radius: 11,
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name ?? 'You',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.place, size: 16),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(user.area ?? '')),
                                      ],
                                    ),
                                    if (user.username != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '@${user.username}',
                                              style: const TextStyle(color: Colors.black54),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.share_outlined, size: 20),
                                            tooltip: 'Share my profile',
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => SharePlus.instance.share(
                                              ShareParams(
                                                text:
                                                    'Find me on NIKAT: @${user.username}',
                                                subject: 'My NIKAT profile',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Neighbours (${_neighbours.length})',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (_neighbours.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No one else has joined this area yet.'),
                        )
                      else
                        ..._neighbours.map(
                          (n) => Card(
                            child: ListTile(
                              leading: UserAvatar(avatarUrl: n.avatarUrl),
                              title: Text(n.name ?? 'Someone'),
                              onTap: () => context.push('/home/users/${n.id}'),
                              trailing: _NeighbourCallButton(neighbour: n),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text('My posts (${_myPosts.length})',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (_myPosts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('You haven\'t posted anything yet.'),
                        )
                      else
                        ..._myPosts.map(
                          (post) => Card(
                            child: ListTile(
                              leading: Icon(areaPostKindIcon(post.kind)),
                              title: Text(post.title),
                              subtitle: Text(areaPostKindLabel(post.kind)),
                              onTap: () => context.push('/home/posts/${post.id}'),
                            ),
                          ),
                        ),
                    ],
                  ),
        ),
      ),
    );
  }
}

class _NeighbourCallButton extends ConsumerWidget {
  final AppUser neighbour;

  const _NeighbourCallButton({required this.neighbour});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callService = ref.watch(callServiceProvider);
    final myName = ref.watch(sessionControllerProvider).value?.user?.name ?? 'Someone';
    return IconButton.filled(
      icon: const Icon(Icons.call),
      tooltip: 'Call ${neighbour.name ?? 'neighbour'} (no number shared)',
      onPressed: callService == null ? null : () => callService.call(neighbour.id, myName),
    );
  }
}
