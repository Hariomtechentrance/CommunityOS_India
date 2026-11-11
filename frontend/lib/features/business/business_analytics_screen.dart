import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/business.dart';
import 'business_repository.dart';

class BusinessAnalyticsScreen extends ConsumerStatefulWidget {
  const BusinessAnalyticsScreen({super.key});

  @override
  ConsumerState<BusinessAnalyticsScreen> createState() => _BusinessAnalyticsScreenState();
}

class _BusinessAnalyticsScreenState extends ConsumerState<BusinessAnalyticsScreen> {
  bool _loading = true;
  String? _error;
  BusinessAnalytics? _analytics;

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
      final analytics = await ref.read(businessRepositoryProvider).getAnalytics();
      setState(() => _analytics = analytics);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _analytics;
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: MaxWidthBox(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: GridView.count(
                      padding: const EdgeInsets.all(16),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _StatCard(label: 'Profile views', value: a!.profileViews),
                        _StatCard(label: 'Followers', value: a.followerCount),
                        _StatCard(label: 'Catalog items', value: a.catalogItemCount),
                        _StatCard(label: 'Catalog views', value: a.totalCatalogViews),
                        _StatCard(label: 'Broadcasts sent', value: a.broadcastsSent),
                        _StatCard(label: 'Total reach', value: a.totalBroadcastReach),
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700, color: nikatNavy),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
