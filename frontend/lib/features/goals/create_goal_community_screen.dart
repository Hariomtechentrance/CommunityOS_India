import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'goal_communities_repository.dart';

class CreateGoalCommunityScreen extends ConsumerStatefulWidget {
  const CreateGoalCommunityScreen({super.key});

  @override
  ConsumerState<CreateGoalCommunityScreen> createState() => _CreateGoalCommunityScreenState();
}

class _CreateGoalCommunityScreenState extends ConsumerState<CreateGoalCommunityScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _joinCostController = TextEditingController(text: '0');
  int _durationDays = 30;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _joinCostController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      setState(() => _error = 'Title and description are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(goalCommunitiesRepositoryProvider).create(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            durationDays: _durationDays,
            category: _categoryController.text.trim(),
            joinCostCoins: int.tryParse(_joinCostController.text.trim()) ?? 0,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start a goal community')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: '100 Days Coding Challenge',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'What counts as a check-in?',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              labelText: 'Category (optional)',
              hintText: 'Coding, Fitness, Reading...',
            ),
          ),
          const SizedBox(height: 16),
          Text('Duration: $_durationDays days', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _durationDays.toDouble(),
            min: 7,
            max: 365,
            divisions: 358,
            label: '$_durationDays days',
            onChanged: (v) => setState(() => _durationDays = v.round()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _joinCostController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Join cost (🪙 coins, optional)',
              hintText: '0 = free to join',
              helperText: 'Paid once when someone joins, goes to your Niikat Coins wallet.',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _create,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Start'),
          ),
        ],
      ),
    );
  }
}
