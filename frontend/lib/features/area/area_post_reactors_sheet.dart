import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/user_avatar.dart';
import '../../models/user.dart';
import 'area_repository.dart';

/// Public "who reacted" list for an area post - same shape as
/// ReelLikesSheet. Optionally narrowed to a single emoji by the caller.
class AreaPostReactorsSheet extends ConsumerStatefulWidget {
  final String areaPostId;
  final String? emoji;

  const AreaPostReactorsSheet({super.key, required this.areaPostId, this.emoji});

  @override
  ConsumerState<AreaPostReactorsSheet> createState() => _AreaPostReactorsSheetState();
}

class _AreaPostReactorsSheetState extends ConsumerState<AreaPostReactorsSheet> {
  bool _loading = true;
  String? _error;
  List<AppUser> _reactors = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final reactors = await ref
          .read(areaRepositoryProvider)
          .listReactors(widget.areaPostId, emoji: widget.emoji);
      if (mounted) setState(() => _reactors = reactors);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.emoji != null
                    ? '${widget.emoji} (${_reactors.length})'
                    : 'Reactions (${_reactors.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _reactors.isEmpty
                          ? const Center(child: Text('No reactions yet.'))
                          : ListView.builder(
                              itemCount: _reactors.length,
                              itemBuilder: (context, index) {
                                final reactor = _reactors[index];
                                return ListTile(
                                  leading: UserAvatar(avatarUrl: reactor.avatarUrl),
                                  title: Text(reactor.name ?? 'Someone'),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    context.push('/home/users/${reactor.id}');
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
