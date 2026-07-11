import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../models/society.dart';
import 'society_repository.dart';

class SocietySearchScreen extends ConsumerStatefulWidget {
  const SocietySearchScreen({super.key});

  @override
  ConsumerState<SocietySearchScreen> createState() => _SocietySearchScreenState();
}

class _SocietySearchScreenState extends ConsumerState<SocietySearchScreen> {
  final _queryController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _loading = false;
  String? _error;
  List<Society>? _results;

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref.read(societyRepositoryProvider).search(
            query: _queryController.text.trim(),
            pincode: _pincodeController.text.trim(),
          );
      setState(() => _results = results);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find your society')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _queryController,
                  decoration: const InputDecoration(
                    labelText: 'Society name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pincode',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loading ? null : _search,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Search'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                if (_results != null)
                  if (_results!.isEmpty)
                    const Text('No societies found. Try creating one.')
                  else
                    ..._results!.map(
                      (society) => Card(
                        child: ListTile(
                          title: Text(society.name),
                          subtitle: Text(
                            '${society.addressLine}, ${society.city}, ${society.state} - ${society.pincode}',
                          ),
                          trailing: FilledButton(
                            onPressed: () => context.push('/societies/join', extra: society),
                            child: const Text('Join'),
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => context.push('/societies/create'),
                  child: const Text('Create a new society'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
