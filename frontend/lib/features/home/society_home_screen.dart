import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/membership.dart';

class SocietyHomeScreen extends ConsumerWidget {
  const SocietyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).value;
    final society = session?.society;
    final role = session?.membership?.role ?? MembershipRole.resident;
    final isAdmin =
        role == MembershipRole.committeeAdmin || role == MembershipRole.superAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(society?.name ?? 'NIKAT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: MaxWidthBox(
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (society != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(society.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('${society.addressLine}, ${society.city}, ${society.state}'),
                    const SizedBox(height: 4),
                    Text('Your role: ${_roleLabel(role)}'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          _DashboardTile(
            icon: Icons.forum,
            label: 'Community',
            onTap: () => context.push('/home/society/community'),
          ),
          _DashboardTile(
            icon: Icons.storefront,
            label: 'Marketplace',
            onTap: () => context.push('/home/society/marketplace'),
          ),
          _DashboardTile(
            icon: Icons.campaign,
            label: 'Notices',
            onTap: () => context.push('/home/society/notices'),
          ),
          _DashboardTile(
            icon: Icons.report_problem,
            label: 'Complaints',
            onTap: () => context.push('/home/society/complaints'),
          ),
          if (isAdmin)
            _DashboardTile(
              icon: Icons.people,
              label: 'Manage members',
              onTap: () => context.push('/home/society/members'),
            ),
        ],
        ),
      ),
    );
  }

  String _roleLabel(MembershipRole role) {
    switch (role) {
      case MembershipRole.committeeAdmin:
        return 'Committee Admin';
      case MembershipRole.superAdmin:
        return 'Super Admin';
      case MembershipRole.security:
        return 'Security';
      case MembershipRole.resident:
        return 'Resident';
    }
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
