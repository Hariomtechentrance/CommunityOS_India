import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../core/widgets/user_avatar.dart';
import 'connect_repository.dart';

const _suggestedInterests = [
  'Programming', 'AI', 'Cricket', 'Music', 'Startups', 'Fitness', 'Reading',
  'Travel', 'Photography', 'Cooking', 'Gaming', 'Art',
];

/// "Talk to strangers - safely": opt-in only, matched by shared interests,
/// never a live anonymous-chat free-for-all. Block/Report apply exactly as
/// everywhere else in the app the moment a chat starts (reuses the regular
/// messages thread, not a separate ephemeral chat system).
class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  bool _searching = false;
  String? _error;
  ConnectMatch? _result;

  Future<void> _toggleEnabled(bool enabled) async {
    try {
      await ref.read(connectRepositoryProvider).updateSettings(connectEnabled: enabled);
      await ref.read(sessionControllerProvider.notifier).refreshUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  Future<void> _editInterests() async {
    final user = ref.read(sessionControllerProvider).value?.user;
    final selected = {...(user?.interests ?? [])};
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
              Text('Your interests', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedInterests
                    .map(
                      (i) => FilterChip(
                        label: Text(i),
                        selected: selected.contains(i),
                        onSelected: (v) => setSheetState(() {
                          if (v) {
                            selected.add(i);
                          } else {
                            selected.remove(i);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true) return;

    try {
      await ref
          .read(connectRepositoryProvider)
          .updateSettings(interests: selected.toList());
      await ref.read(sessionControllerProvider.notifier).refreshUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  Future<void> _findMatch() async {
    setState(() {
      _searching = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ref.read(connectRepositoryProvider).findMatch();
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).value?.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Niikat Connect')),
      body: MaxWidthBox(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Get matched with someone nearby who shares your interests - '
              'opt-in only, and Block/Report work exactly as everywhere else.',
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Niikat Connect'),
              value: user?.connectEnabled ?? false,
              onChanged: _toggleEnabled,
            ),
            ListTile(
              title: const Text('Your interests'),
              subtitle: Text(
                (user?.interests ?? []).isEmpty
                    ? 'None yet - tap to add'
                    : user!.interests.join(', '),
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: _editInterests,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _searching ? null : _findMatch,
              icon: const Icon(Icons.shuffle),
              label: Text(_searching ? 'Finding someone...' : 'Find someone to talk to'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              if (_result!.user == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_result!.reason ?? 'No match found.'),
                  ),
                )
              else
                Card(
                  child: ListTile(
                    leading: UserAvatar(avatarUrl: _result!.user!.avatarUrl),
                    title: Text(_result!.user!.name ?? 'Someone'),
                    subtitle: Text(
                      'Shares: ${_result!.sharedInterests.join(', ')}',
                    ),
                    trailing: FilledButton(
                      onPressed: () => context.push(
                        '/home/messages/${_result!.user!.id}',
                        extra: _result!.user!.name,
                      ),
                      child: const Text('Chat'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
