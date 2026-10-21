import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/locale/locale_controller.dart';
import '../../core/session/session_controller.dart';
import '../../core/settings/data_saver_controller.dart';
import '../../core/settings/text_scale_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../l10n/generated/app_localizations.dart';
import '../users/user_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _toggleActivityNotifications(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    try {
      await ref
          .read(userRepositoryProvider)
          .updateNotificationSettings(activityNotificationsEnabled: enabled);
      await ref.read(sessionControllerProvider.notifier).refreshUser();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  Future<void> _toggleHideLikeCounts(BuildContext context, WidgetRef ref, bool enabled) async {
    try {
      await ref.read(userRepositoryProvider).updateNotificationSettings(hideLikeCounts: enabled);
      await ref.read(sessionControllerProvider.notifier).refreshUser();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  Future<void> _toggleAllowMessages(BuildContext context, WidgetRef ref, bool allowEveryone) async {
    try {
      await ref.read(userRepositoryProvider).updateNotificationSettings(
            allowMessagesFrom: allowEveryone ? 'EVERYONE' : 'NO_ONE',
          );
      await ref.read(sessionControllerProvider.notifier).refreshUser();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).value?.user;
    final dataSaverOn = ref.watch(dataSaverControllerProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: MaxWidthBox(
        child: ListView(
          children: [
            const _SectionHeader('Account'),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Edit profile'),
              onTap: () => context.push('/home/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              onTap: () => _showLanguagePicker(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Change location'),
              onTap: () => context.push('/home/profile/edit-location'),
            ),
            const Divider(height: 1),
            const _SectionHeader('Privacy & safety'),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('Blocked accounts'),
              onTap: () => context.push('/home/settings/blocked'),
            ),
            ListTile(
              leading: const Icon(Icons.volume_off_outlined),
              title: const Text('Muted accounts'),
              onTap: () => context.push('/home/settings/muted'),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.mail_outline),
              title: const Text('Allow messages from anyone'),
              subtitle: const Text(
                "Turn this off to stop new people from DMing you. Existing chats still work, "
                'and blocked users can never reach you either way.',
              ),
              value: (user?.allowMessagesFrom ?? 'EVERYONE') == 'EVERYONE',
              onChanged: (v) => _toggleAllowMessages(context, ref, v),
            ),
            const Divider(height: 1),
            const _SectionHeader('Notifications'),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('Activity notifications'),
              subtitle: const Text("Updates from people you follow"),
              value: user?.activityNotificationsEnabled ?? true,
              onChanged: (v) => _toggleActivityNotifications(context, ref, v),
            ),
            const Divider(height: 1),
            const _SectionHeader('Data usage'),
            SwitchListTile(
              secondary: const Icon(Icons.data_saver_on_outlined),
              title: const Text('Data saver'),
              subtitle: const Text("Don't auto-play reels while scrolling"),
              value: dataSaverOn,
              onChanged: (v) => ref.read(dataSaverControllerProvider.notifier).setEnabled(v),
            ),
            const Divider(height: 1),
            const _SectionHeader('Accessibility'),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Text size'),
              onTap: () => _showTextSizePicker(context, ref),
            ),
            const Divider(height: 1),
            const _SectionHeader('Content'),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('Saved posts'),
              onTap: () => context.push('/home/saved'),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.visibility_off_outlined),
              title: const Text('Hide like counts on my posts'),
              subtitle: const Text(
                'Others see "liked by a few people" instead of a number. '
                "You can still see the real count yourself.",
              ),
              value: user?.hideLikeCounts ?? false,
              onChanged: (v) => _toggleHideLikeCounts(context, ref, v),
            ),
            ListTile(
              leading: const Text('🪙', style: TextStyle(fontSize: 20)),
              title: const Text('Niikat Coins'),
              onTap: () => context.push('/home/wallet'),
            ),
            const Divider(height: 1),
            const _SectionHeader('Support'),
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('Send feedback'),
              subtitle: const Text('Report a bug, suggest a feature, or leave a review'),
              onTap: () => context.push('/home/feedback'),
            ),
            const Divider(height: 1),
            const _SectionHeader('About'),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('App version'),
              subtitle: Text('1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log out', style: TextStyle(color: Colors.red)),
              onTap: () => ref.read(sessionControllerProvider.notifier).logout(),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: const Text('Delete account', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Permanently removes your profile, posts, and data'),
              onTap: () => _confirmDeleteAccount(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Delete your account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your profile, posts, messages, wallet, and everything '
                "else tied to your account. This can't be undone.",
              ),
              const SizedBox(height: 16),
              Text('Type DELETE to confirm', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: confirmController.text.trim() == 'DELETE'
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Delete forever'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(userRepositoryProvider).deleteAccount();
      await ref.read(sessionControllerProvider.notifier).logout();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

Future<void> _showLanguagePicker(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final current = ref.read(localeControllerProvider).value;
  final choice = await showDialog<Locale?>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.chooseLanguage),
      children: [
        RadioListTile<Locale?>(
          value: const Locale('en'),
          groupValue: current,
          title: Text(l10n.languageEnglish),
          onChanged: (v) => Navigator.of(context).pop(v),
        ),
        RadioListTile<Locale?>(
          value: const Locale('hi'),
          groupValue: current,
          title: Text(l10n.languageHindi),
          onChanged: (v) => Navigator.of(context).pop(v),
        ),
      ],
    ),
  );
  if (choice == current) return;
  await ref.read(localeControllerProvider.notifier).setLocale(choice);
}

const _textSizePresets = {
  'Small': 0.85,
  'Default': 1.0,
  'Large': 1.15,
  'Extra large': 1.3,
};

Future<void> _showTextSizePicker(BuildContext context, WidgetRef ref) async {
  final current = ref.read(textScaleControllerProvider).value ?? TextScaleController.defaultScale;
  final choice = await showDialog<double>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Text size'),
      children: [
        for (final entry in _textSizePresets.entries)
          RadioListTile<double>(
            value: entry.value,
            groupValue: current,
            title: Text(entry.key, style: TextStyle(fontSize: 16 * entry.value)),
            onChanged: (v) => Navigator.of(context).pop(v),
          ),
      ],
    ),
  );
  if (choice == null || choice == current) return;
  await ref.read(textScaleControllerProvider.notifier).setScale(choice);
}
