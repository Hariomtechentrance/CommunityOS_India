import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/business.dart';
import 'business_repository.dart';

/// Broadcasts fan out to every follower via push notification (same pipeline
/// Area posts use) - this is the direct WhatsApp-Business-broadcast-list
/// equivalent, capped server-side to one per business per 24h.
class BusinessBroadcastScreen extends ConsumerStatefulWidget {
  const BusinessBroadcastScreen({super.key});

  @override
  ConsumerState<BusinessBroadcastScreen> createState() => _BusinessBroadcastScreenState();
}

class _BusinessBroadcastScreenState extends ConsumerState<BusinessBroadcastScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sending = false;
  bool _loadingHistory = true;
  List<BusinessBroadcast> _history = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final history = await ref.read(businessRepositoryProvider).listMyBroadcasts();
      setState(() => _history = history);
    } catch (_) {
      // Non-fatal - the compose form still works without history.
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _send() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required.')),
      );
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final broadcast = await ref.read(businessRepositoryProvider).sendBroadcast(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
          );
      if (!mounted) return;
      _titleController.clear();
      _bodyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent to ${broadcast.recipientCount} followers.')),
      );
      _loadHistory();
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcasts')),
      body: MaxWidthBox(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Weekend offer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: '20% off on all vegetables this weekend!',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 8),
            const Text(
              'Goes to every follower as a push notification. Limited to one broadcast per day.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.campaign_outlined),
              label: const Text('Send broadcast'),
            ),
            const Divider(height: 32),
            Text('Past broadcasts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_loadingHistory)
              const Center(child: CircularProgressIndicator())
            else if (_history.isEmpty)
              const Text('No broadcasts sent yet.')
            else
              ..._history.map(
                (b) => Card(
                  child: ListTile(
                    title: Text(b.title),
                    subtitle: Text(b.body),
                    trailing: Text('${b.recipientCount}', style: const TextStyle(color: Colors.black54)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
