import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_controller.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).value;
    final societyName = session?.society?.name ?? 'your society';

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Waiting for approval',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your request to join $societyName is pending. A Committee Admin needs to approve it before you can access the community.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () =>
                      ref.read(sessionControllerProvider.notifier).refreshMembership(),
                  child: const Text('Check again'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.read(sessionControllerProvider.notifier).leaveSociety(),
                  child: const Text('Choose a different society'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
