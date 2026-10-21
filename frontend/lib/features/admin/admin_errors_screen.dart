import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/admin.dart';
import 'admin_repository.dart';

class AdminErrorsScreen extends ConsumerStatefulWidget {
  const AdminErrorsScreen({super.key});

  @override
  ConsumerState<AdminErrorsScreen> createState() => _AdminErrorsScreenState();
}

class _AdminErrorsScreenState extends ConsumerState<AdminErrorsScreen> {
  final _pathController = TextEditingController();
  bool _loading = true;
  String? _error;
  AdminErrorLogPage? _page;
  int _currentPage = 1;
  final _dateFormat = DateFormat('d MMM, h:mm a');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(adminRepositoryProvider).listErrors(
            path: _pathController.text.trim().isEmpty ? null : _pathController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Server errors (last 500, 5xx only)')),
      body: MaxWidthBox(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _pathController,
                decoration: InputDecoration(
                  hintText: 'Filter by path, e.g. /area-posts',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _load(page: 1),
                  ),
                ),
                onSubmitted: (_) => _load(page: 1),
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
                                    child: Text('No server errors recorded. 🎉'),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                itemCount: _page!.items.length,
                                itemBuilder: (context, index) {
                                  final e = _page!.items[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.red.shade50,
                                      child: Text(
                                        '${e.statusCode}',
                                        style: const TextStyle(fontSize: 11, color: Colors.red),
                                      ),
                                    ),
                                    title: Text('${e.method} ${e.path}'),
                                    subtitle: Text(
                                      '${e.message}\n${_dateFormat.format(e.createdAt.toLocal())}',
                                    ),
                                    isThreeLine: true,
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
