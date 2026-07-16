import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../models/campaign.dart';
import 'campaigns_repository.dart';
import 'create_campaign_screen.dart';

class MyCampaignsScreen extends ConsumerStatefulWidget {
  const MyCampaignsScreen({super.key});

  @override
  ConsumerState<MyCampaignsScreen> createState() => _MyCampaignsScreenState();
}

class _MyCampaignsScreenState extends ConsumerState<MyCampaignsScreen> {
  bool _loading = true;
  String? _error;
  List<Campaign> _campaigns = [];

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
      final campaigns = await ref.read(campaignsRepositoryProvider).listMine();
      setState(() => _campaigns = campaigns);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resumeCheckout(Campaign campaign) async {
    try {
      final checkoutUrl = await ref.read(campaignsRepositoryProvider).checkout(campaign.id);
      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My ad campaigns')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateCampaignScreen()),
          );
          if (created == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('New campaign'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _campaigns.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              "You haven't run any ad campaigns yet. Tap \"New campaign\" to reach nearby "
                              'customers, your pincode, chosen states, or all of India.',
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: _campaigns.length,
                        itemBuilder: (context, index) => _CampaignCard(
                          campaign: _campaigns[index],
                          onResumeCheckout: () => _resumeCheckout(_campaigns[index]),
                        ),
                      ),
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onResumeCheckout;

  const _CampaignCard({required this.campaign, required this.onResumeCheckout});

  Color _statusColor(BuildContext context) {
    switch (campaign.status) {
      case CampaignStatus.active:
        return Colors.green;
      case CampaignStatus.pendingPayment:
        return Colors.orange;
      case CampaignStatus.rejected:
        return Theme.of(context).colorScheme.error;
      case CampaignStatus.completed:
        return Colors.blueGrey;
      case CampaignStatus.draft:
        return Colors.grey;
    }
  }

  String _targetSummary() {
    switch (campaign.targetType) {
      case CampaignTargetType.nearby:
        return 'Within ${campaign.targetRadiusKm?.round() ?? '-'} km';
      case CampaignTargetType.pincode:
        return 'Pincode ${campaign.targetPincode ?? '-'}';
      case CampaignTargetType.states:
        return campaign.targetStates.join(', ');
      case CampaignTargetType.allIndia:
        return 'All India';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (campaign.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  campaign.imageUrl!,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
            if (campaign.imageUrl != null) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          campaign.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(context).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          campaignStatusLabel(campaign.status),
                          style: TextStyle(
                            color: _statusColor(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(campaign.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(
                    '${_targetSummary()} · ₹${campaign.budgetInRupees.toStringAsFixed(0)} budget',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (campaign.status == CampaignStatus.draft ||
                      campaign.status == CampaignStatus.pendingPayment) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: onResumeCheckout,
                      child: const Text('Complete payment'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
