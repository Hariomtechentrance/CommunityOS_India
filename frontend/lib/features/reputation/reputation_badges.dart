import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reputation_repository.dart';

/// Score + earned badges for a user - "what have you actually contributed"
/// alongside the plain follower count already shown elsewhere on the
/// profile. Silently renders nothing on error/empty, same spirit as other
/// best-effort profile widgets - never blocks the rest of the profile.
class ReputationBadges extends ConsumerWidget {
  final String userId;

  const ReputationBadges({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Reputation>(
      future: ref.read(reputationRepositoryProvider).getReputation(userId),
      builder: (context, snapshot) {
        final reputation = snapshot.data;
        if (reputation == null) return const SizedBox.shrink();
        return Column(
          children: [
            Text(
              'Reputation: ${reputation.score}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (reputation.badges.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: reputation.badges
                    .map(
                      (b) => Chip(
                        avatar: Text(b.emoji),
                        label: Text(b.label),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        );
      },
    );
  }
}
