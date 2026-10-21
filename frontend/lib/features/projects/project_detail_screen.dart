import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/project.dart';
import 'projects_repository.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  bool _loading = true;
  String? _error;
  Project? _project;

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
      final project = await ref.read(projectsRepositoryProvider).getById(widget.projectId);
      setState(() => _project = project);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isOwner =>
      _project?.user?.id == ref.read(sessionControllerProvider).value?.user?.id;

  Future<void> _addUpdate() async {
    final bodyController = TextEditingController();
    final dayController = TextEditingController();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New update', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: dayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Day number (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'What happened?'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Post update'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true || bodyController.text.trim().isEmpty) return;

    try {
      await ref.read(projectsRepositoryProvider).addUpdate(
            widget.projectId,
            dayNumber: int.tryParse(dayController.text.trim()),
            body: bodyController.text.trim(),
          );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_project?.name ?? 'Project')),
      floatingActionButton: _isOwner
          ? FloatingActionButton.extended(
              onPressed: _addUpdate,
              icon: const Icon(Icons.add),
              label: const Text('Add update'),
            )
          : null,
      body: MaxWidthBox(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            UserAvatar(avatarUrl: _project!.user?.avatarUrl, radius: 16),
                            const SizedBox(width: 8),
                            Text(_project!.user?.name ?? 'Someone'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(_project!.description),
                        const SizedBox(height: 24),
                        Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if ((_project!.updates ?? []).isEmpty)
                          const Text('No updates yet.')
                        else
                          ...(_project!.updates!.map(
                            (u) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (u.dayNumber != null)
                                      Text(
                                        'Day ${u.dayNumber}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(u.body),
                                  ],
                                ),
                              ),
                            ),
                          )),
                      ],
                    ),
                  ),
      ),
    );
  }
}
