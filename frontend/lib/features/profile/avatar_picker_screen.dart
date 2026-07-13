import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../users/user_repository.dart';

const _diceBearStyles = [
  'adventurer',
  'avataaars',
  'bottts',
  'fun-emoji',
  'lorelei',
  'micah',
];

String _avatarUrlFor(String style, String seed) =>
    'https://api.dicebear.com/9.x/$style/png?seed=${Uri.encodeComponent(seed)}';

/// Lets a user pick a free, auto-generated cartoon avatar instead of
/// uploading a photo - a style + a shuffleable seed, rendered via DiceBear's
/// no-API-key-needed PNG endpoint (PNG, not SVG, since the app has no
/// SVG-rendering package and every other avatar spot assumes a raster
/// `NetworkImage`).
class AvatarPickerScreen extends ConsumerStatefulWidget {
  const AvatarPickerScreen({super.key});

  @override
  ConsumerState<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends ConsumerState<AvatarPickerScreen> {
  late String _seed;
  String _style = _diceBearStyles.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _seed = ref.read(sessionControllerProvider).value?.user?.id ?? _randomSeed();
  }

  String _randomSeed() => '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

  void _shuffle() => setState(() => _seed = _randomSeed());

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final url = _avatarUrlFor(_style, _seed);
      await ref.read(userRepositoryProvider).updateAvatar(url);
      await ref.read(sessionControllerProvider.notifier).refreshUser();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate an avatar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 64,
              backgroundImage: NetworkImage(_avatarUrlFor(_style, _seed)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _shuffle,
              icon: const Icon(Icons.shuffle),
              label: const Text('Shuffle'),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Style', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: _diceBearStyles.map((style) {
                  final selected = style == _style;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _style = style),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(_avatarUrlFor(style, _seed)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            style,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _confirm,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Use this avatar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
