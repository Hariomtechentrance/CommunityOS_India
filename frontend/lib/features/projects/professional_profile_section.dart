import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import 'projects_repository.dart';

/// "Look at what I can do" - headline/skills/availableFor chips plus a
/// Projects ("Build in Public") list, shown on both your own profile and
/// anyone else's. Silently renders nothing when there's no professional
/// data at all, so it never clutters a profile that hasn't opted in.
class ProfessionalProfileSection extends ConsumerWidget {
  final AppUser user;
  final bool isSelf;

  const ProfessionalProfileSection({super.key, required this.user, required this.isSelf});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasProfessionalInfo =
        user.headline != null || user.skills.isNotEmpty || user.availableFor.isNotEmpty;

    return FutureBuilder(
      future: ref.read(projectsRepositoryProvider).listForUser(user.id),
      builder: (context, snapshot) {
        final projects = snapshot.data ?? [];
        if (!hasProfessionalInfo && projects.isEmpty && !isSelf) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            if (user.headline != null)
              Text(user.headline!, style: Theme.of(context).textTheme.titleSmall),
            if (user.skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: user.skills.map((s) => Chip(label: Text(s))).toList(),
              ),
            ],
            if (user.availableFor.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: user.availableFor
                    .map((a) => Chip(
                          label: Text('Available for $a'),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        ))
                    .toList(),
              ),
            ],
            if (projects.isNotEmpty || isSelf) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Projects', style: Theme.of(context).textTheme.titleSmall),
                  if (isSelf)
                    TextButton(
                      onPressed: () => context.push('/home/projects/new'),
                      child: const Text('Start a project'),
                    ),
                ],
              ),
              ...projects.map(
                (p) => Card(
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text('${p.updateCount} updates'),
                    onTap: () => context.push('/home/projects/${p.id}'),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
