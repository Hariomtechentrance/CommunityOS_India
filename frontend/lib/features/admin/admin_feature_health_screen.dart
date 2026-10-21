import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/admin.dart';
import 'admin_repository.dart';

class AdminFeatureHealthScreen extends ConsumerStatefulWidget {
  const AdminFeatureHealthScreen({super.key});

  @override
  ConsumerState<AdminFeatureHealthScreen> createState() => _AdminFeatureHealthScreenState();
}

class _AdminFeatureHealthScreenState extends ConsumerState<AdminFeatureHealthScreen> {
  bool _loading = true;
  String? _error;
  List<FeatureHealth> _features = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final features = await ref.read(adminRepositoryProvider).getFeatureHealth();
      setState(() => _features = features);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'healthy':
        return Colors.green;
      case 'degraded':
        return Colors.orange;
      case 'failing':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'healthy':
        return Icons.check_circle;
      case 'degraded':
        return Icons.warning;
      case 'failing':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feature health')),
      body: MaxWidthBox(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _features.length,
                      itemBuilder: (context, index) {
                        final f = _features[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Icon(_statusIcon(f.status), color: _statusColor(f.status)),
                            title: Text(f.label),
                            subtitle: Text(
                              '${f.recentActivity} actions · ${f.recentErrors} server errors (last 7 days)',
                            ),
                            trailing: Text(
                              f.status,
                              style: TextStyle(
                                color: _statusColor(f.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: f.recentErrors > 0
                                ? () => context.push('/admin/errors')
                                : null,
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
