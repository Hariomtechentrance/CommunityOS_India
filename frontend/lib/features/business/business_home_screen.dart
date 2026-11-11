import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/business.dart';
import 'business_repository.dart';

/// Entry point for "Niikat Business" from the drawer. No profile yet -> a
/// setup pitch (this is the WhatsApp-Business-alternative pitch in-product);
/// profile exists -> a dashboard linking to catalog/broadcasts/analytics.
class BusinessHomeScreen extends ConsumerStatefulWidget {
  const BusinessHomeScreen({super.key});

  @override
  ConsumerState<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends ConsumerState<BusinessHomeScreen> {
  bool _loading = true;
  BusinessProfile? _profile;
  String? _error;

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
      final profile = await ref.read(businessRepositoryProvider).getMyProfile();
      setState(() => _profile = profile);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Niikat Business')),
      body: MaxWidthBox(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _profile == null ? _buildPitch(context) : _buildDashboard(context, _profile!),
                  ),
      ),
    );
  }

  Widget _buildPitch(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.storefront, size: 72, color: nikatOrange),
        const SizedBox(height: 16),
        Text(
          'A storefront for your business, free of per-message pricing',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Set up a verified business profile: list your products or services, '
          'broadcast offers to your followers, and see how many people you reach - '
          'all without paying per conversation.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () async {
            final created = await context.push<bool>('/home/business/edit');
            if (created == true) _load();
          },
          child: const Text('Set up my business profile'),
        ),
      ],
    );
  }

  Widget _buildDashboard(BuildContext context, BusinessProfile profile) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: profile.logoUrl != null ? NetworkImage(profile.logoUrl!) : null,
              child: profile.logoUrl == null ? const Icon(Icons.storefront) : null,
            ),
            title: Row(
              children: [
                Flexible(child: Text(profile.businessName, overflow: TextOverflow.ellipsis)),
                if (profile.isVerified) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, size: 16, color: nikatNavy),
                ],
              ],
            ),
            subtitle: Text(profile.category),
            trailing: TextButton(
              onPressed: () async {
                final updated = await context.push<bool>('/home/business/edit');
                if (updated == true) _load();
              },
              child: const Text('Edit'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _DashboardTile(
          icon: Icons.inventory_2_outlined,
          title: 'Catalog',
          subtitle: '${profile.catalogItemCount} items',
          onTap: () => context.push('/home/business/catalog'),
        ),
        _DashboardTile(
          icon: Icons.campaign_outlined,
          title: 'Broadcasts',
          subtitle: '${profile.broadcastCount} sent',
          onTap: () => context.push('/home/business/broadcast'),
        ),
        _DashboardTile(
          icon: Icons.bar_chart_outlined,
          title: 'Analytics',
          subtitle: 'Reach and engagement',
          onTap: () => context.push('/home/business/analytics'),
        ),
        _DashboardTile(
          icon: Icons.visibility_outlined,
          title: 'View public storefront',
          subtitle: 'What customers see',
          onTap: () => context.push('/home/business/view/${profile.userId}'),
        ),
      ],
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: nikatNavy),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
