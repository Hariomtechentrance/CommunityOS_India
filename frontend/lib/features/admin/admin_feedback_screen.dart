import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/admin.dart';
import 'admin_repository.dart';

const _categories = ['BUG', 'SUGGESTION', 'REVIEW', 'OTHER'];
const _statuses = ['OPEN', 'REVIEWED', 'RESOLVED', 'DISMISSED'];

String _categoryLabel(String c) => switch (c) {
      'BUG' => 'Bug',
      'SUGGESTION' => 'Suggestion',
      'REVIEW' => 'Review',
      _ => 'Other',
    };

Color _statusColor(String s) => switch (s) {
      'OPEN' => Colors.blue,
      'REVIEWED' => Colors.orange,
      'RESOLVED' => Colors.green,
      _ => Colors.grey,
    };

class AdminFeedbackScreen extends ConsumerStatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  ConsumerState<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends ConsumerState<AdminFeedbackScreen> {
  bool _loading = true;
  String? _error;
  AdminFeedbackPage? _page;
  int _currentPage = 1;
  String? _categoryFilter;
  String? _statusFilter = 'OPEN';
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
      final result = await ref.read(adminRepositoryProvider).listFeedback(
            category: _categoryFilter,
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

  Future<void> _updateStatus(AdminFeedbackItem item, String status) async {
    try {
      await ref.read(adminRepositoryProvider).setFeedbackStatus(item.id, status);
      await _load(page: _currentPage);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback & reviews')),
      body: MaxWidthBox(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _categoryFilter,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        for (final c in _categories)
                          DropdownMenuItem(value: c, child: Text(_categoryLabel(c))),
                      ],
                      onChanged: (v) {
                        setState(() => _categoryFilter = v);
                        _load(page: 1);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                ],
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
                                    child: Text('No feedback matches this filter.'),
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
                                              Chip(
                                                label: Text(_categoryLabel(item.category)),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                              if (item.rating != null) ...[
                                                const SizedBox(width: 8),
                                                Row(
                                                  children: List.generate(
                                                    5,
                                                    (i) => Icon(
                                                      i < item.rating! ? Icons.star : Icons.star_border,
                                                      size: 16,
                                                      color: Colors.amber,
                                                    ),
                                                  ),
                                                ),
                                              ],
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
                                          const SizedBox(height: 8),
                                          Text(item.message),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${item.user?.name ?? item.user?.phone ?? 'Unknown user'} · '
                                            '${_dateFormat.format(item.createdAt.toLocal())}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
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
