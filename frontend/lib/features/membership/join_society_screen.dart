import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../models/society.dart';
import 'membership_repository.dart';

class JoinSocietyScreen extends ConsumerStatefulWidget {
  final Society society;

  const JoinSocietyScreen({super.key, required this.society});

  @override
  ConsumerState<JoinSocietyScreen> createState() => _JoinSocietyScreenState();
}

class _JoinSocietyScreenState extends ConsumerState<JoinSocietyScreen> {
  final _unitController = TextEditingController();
  final _blockController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final membership = await ref.read(membershipRepositoryProvider).requestToJoin(
            widget.society.id,
            unitNumber: _unitController.text.trim(),
            blockName: _blockController.text.trim(),
          );
      await ref
          .read(sessionControllerProvider.notifier)
          .selectSociety(widget.society, membership);
      // Router redirect logic sends this to the pending-approval screen.
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _unitController.dispose();
    _blockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join ${widget.society.name}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Enter your unit details. A Committee Admin will approve your request.'),
                const SizedBox(height: 16),
                TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit / Flat number',
                    hintText: 'A-1203',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _blockController,
                  decoration: const InputDecoration(
                    labelText: 'Block / Tower (optional)',
                    hintText: 'Tower A',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Request to join'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
