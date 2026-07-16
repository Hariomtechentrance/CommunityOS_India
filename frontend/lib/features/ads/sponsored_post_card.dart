import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/campaign.dart';

/// Renders an active [Campaign] inline in the area feed, styled to stand
/// out just enough to be clearly labeled "Sponsored" without looking like
/// a native post.
class SponsoredPostCard extends StatelessWidget {
  final Campaign campaign;

  const SponsoredPostCard({super.key, required this.campaign});

  Future<void> _open() async {
    final url = campaign.ctaUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.tertiary.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: campaign.ctaUrl != null ? _open : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.campaign_outlined, size: 16, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 6),
                  Text(
                    'Sponsored',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (campaign.user?.name != null)
                    Text(
                      campaign.user!.name!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (campaign.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    campaign.imageUrl!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              if (campaign.imageUrl != null) const SizedBox(height: 8),
              Text(campaign.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(campaign.description, style: theme.textTheme.bodyMedium),
              if (campaign.ctaUrl != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _open,
                    icon: const Icon(Icons.arrow_outward, size: 16),
                    label: const Text('Learn more'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
