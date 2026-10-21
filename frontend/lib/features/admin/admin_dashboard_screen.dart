import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/admin.dart';
import 'admin_repository.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _loading = true;
  String? _error;
  AdminStats? _stats;

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
      final stats = await ref.read(adminRepositoryProvider).getStats();
      setState(() => _stats = stats);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: MaxWidthBox(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.6,
                          children: [
                            _StatCard(label: 'Total users', value: _stats!.totalUsers),
                            _StatCard(label: 'Societies', value: _stats!.totalSocieties),
                            _StatCard(label: 'Active (24h)', value: _stats!.activeLast24h),
                            _StatCard(label: 'Active (7d)', value: _stats!.activeLast7d),
                            _StatCard(label: 'Active (30d)', value: _stats!.activeLast30d),
                            _StatCard(label: 'Suspended', value: _stats!.suspendedUsers),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.people),
                            title: const Text('Manage users'),
                            subtitle: const Text('Search, view, suspend, or delete accounts'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/admin/users'),
                          ),
                        ),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.monitor_heart_outlined),
                            title: const Text('Feature health'),
                            subtitle: const Text('Which features are working vs. erroring'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/admin/feature-health'),
                          ),
                        ),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.bug_report_outlined),
                            title: const Text('Server errors'),
                            subtitle: const Text('Recent 5xx errors across the backend'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/admin/errors'),
                          ),
                        ),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.feedback_outlined),
                            title: const Text('Feedback & reviews'),
                            subtitle: const Text('Bug reports, suggestions, and reviews from users'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/admin/feedback'),
                          ),
                        ),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.account_balance_outlined),
                            title: const Text('Payout requests'),
                            subtitle: const Text('Review and pay out creator earnings'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/admin/payouts'),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$value', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
