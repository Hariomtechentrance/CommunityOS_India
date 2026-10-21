import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/admin.dart';
import 'admin_repository.dart';

const _statuses = ['PENDING', 'APPROVED', 'REJECTED', 'PAID'];

Color _statusColor(String s) => switch (s) {
      'PENDING' => Colors.orange,
      'APPROVED' => Colors.blue,
      'PAID' => Colors.green,
      _ => Colors.red,
    };

class AdminPayoutsScreen extends ConsumerStatefulWidget {
  const AdminPayoutsScreen({super.key});

  @override
  ConsumerState<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends ConsumerState<AdminPayoutsScreen> {
  bool _loading = true;
  String? _error;
  AdminPayoutPage? _page;
  int _currentPage = 1;
  String? _statusFilter = 'PENDING';
  final _dateFormat = DateFormat('d MMM, h:mm a');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(adminRepositoryProvider).listPayouts(
            status: _statusFilter,
            page: page,
          );
      setState(() {
        _page = result;
        _currentPage = page;
      });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(AdminPayoutItem item, String status) async {
    String? adminNote;
    if (status == 'PAID' || status == 'REJECTED') {
      adminNote = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: Text(status == 'PAID' ? 'Mark as paid' : 'Reject request'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: status == 'PAID' ? 'Transfer reference (optional)' : 'Reason (optional)',
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
      if (adminNote == null) return; // cancelled
    }

    try {
      await ref.read(adminRepositoryProvider).setPayoutStatus(item.id, status, adminNote: adminNote);
      await _load(page: _currentPage);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payout requests')),
      body: MaxWidthBox(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: DropdownButtonFormField<String?>(
                initialValue: _statusFilter,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  for (final s in _statuses) DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: (v) {
                  setState(() => _statusFilter = v);
                  _load(page: 1);
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(page: _currentPage),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : (_page?.items.isEmpty ?? true)
                            ? ListView(
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text('No payout requests match this filter.'),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: _page!.items.length,
                                itemBuilder: (context, index) {
                                  final item = _page!.items[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '🪙 ${item.amountCoins} · ₹${(item.amountInPaise / 100).toStringAsFixed(0)}',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              const Spacer(),
                                              Text(
                                                item.status,
                                                style: TextStyle(
                                                  color: _statusColor(item.status),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text('${item.user?.name ?? 'Unknown'} · ${item.user?.phone ?? ''}'),
                                          Text('Payee: ${item.payeeName}'),
                                          if (item.upiId != null) Text('UPI: ${item.upiId}'),
                                          if (item.bankAccountNumber != null)
                                            Text('A/C: ${item.bankAccountNumber} · IFSC: ${item.bankIfsc}'),
                                          const SizedBox(height: 4),
                                          Text(
                                            _dateFormat.format(item.createdAt.toLocal()),
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                          if (item.adminNote != null) ...[
                                            const SizedBox(height: 4),
                                            Text('Note: ${item.adminNote}', style: const TextStyle(fontSize: 12)),
                                          ],
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              for (final s in _statuses)
                                                if (s != item.status)
                                                  OutlinedButton(
                                                    onPressed: () => _updateStatus(item, s),
                                                    child: Text('Mark $s'),
                                                  ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ),
            if (_page != null && _page!.total > _page!.pageSize)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 1 ? () => _load(page: _currentPage - 1) : null,
                    ),
                    Text('Page $_currentPage'),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _page!.hasMore ? () => _load(page: _currentPage + 1) : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
