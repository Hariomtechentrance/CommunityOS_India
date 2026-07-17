import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';

class _Pillar {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final bool live;

  const _Pillar({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.live,
  });
}

List<_Pillar> _buildPillars(AppLocalizations l10n) => [
      _Pillar(
        icon: Icons.apartment,
        title: l10n.pillarSocietyTitle,
        description: l10n.pillarSocietyDesc,
        features: [l10n.pillarSocietyFeature1, l10n.pillarSocietyFeature2, l10n.pillarSocietyFeature3],
        live: true,
      ),
      _Pillar(
        icon: Icons.forum,
        title: l10n.pillarCommunityTitle,
        description: l10n.pillarCommunityDesc,
        features: [l10n.pillarCommunityFeature1, l10n.pillarCommunityFeature2, l10n.pillarCommunityFeature3],
        live: true,
      ),
      _Pillar(
        icon: Icons.storefront,
        title: l10n.pillarMarketplaceTitle,
        description: l10n.pillarMarketplaceDesc,
        features: [l10n.pillarMarketplaceFeature1, l10n.pillarMarketplaceFeature2, l10n.pillarMarketplaceFeature3],
        live: true,
      ),
      _Pillar(
        icon: Icons.local_grocery_store,
        title: l10n.pillarCommerceTitle,
        description: l10n.pillarCommerceDesc,
        features: [l10n.pillarCommerceFeature1, l10n.pillarCommerceFeature2, l10n.pillarCommerceFeature3],
        live: false,
      ),
      _Pillar(
        icon: Icons.smart_toy,
        title: l10n.pillarAiTitle,
        description: l10n.pillarAiDesc,
        features: [l10n.pillarAiFeature1, l10n.pillarAiFeature2, l10n.pillarAiFeature3],
        live: false,
      ),
      _Pillar(
        icon: Icons.celebration,
        title: l10n.pillarFestivalTitle,
        description: l10n.pillarFestivalDesc,
        features: [l10n.pillarFestivalFeature1, l10n.pillarFestivalFeature2, l10n.pillarFestivalFeature3],
        live: false,
      ),
      _Pillar(
        icon: Icons.emergency,
        title: l10n.pillarEmergencyTitle,
        description: l10n.pillarEmergencyDesc,
        features: [l10n.pillarEmergencyFeature1, l10n.pillarEmergencyFeature2, l10n.pillarEmergencyFeature3],
        live: false,
      ),
      _Pillar(
        icon: Icons.cleaning_services,
        title: l10n.pillarHelpTitle,
        description: l10n.pillarHelpDesc,
        features: [l10n.pillarHelpFeature1, l10n.pillarHelpFeature2, l10n.pillarHelpFeature3],
        live: false,
      ),
      _Pillar(
        icon: Icons.work,
        title: l10n.pillarJobsTitle,
        description: l10n.pillarJobsDesc,
        features: [l10n.pillarJobsFeature1, l10n.pillarJobsFeature2, l10n.pillarJobsFeature3],
        live: false,
      ),
    ];

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pillars = _buildPillars(l10n);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: nikatScaffoldBg,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/images/nikat_logo.jpg', height: 34, width: 34),
                ),
                const SizedBox(width: 10),
                const Text('NIKAT'),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FilledButton(
                  onPressed: () => context.push('/login'),
                  child: Text(AppLocalizations.of(context)!.login),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(child: _HeroSection()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 8),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: Column(
                  children: [
                    Text(
                      l10n.pillarsHeadline,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: nikatNavy,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.pillarsSubheadline,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                mainAxisExtent: 230,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _PillarCard(pillar: pillars[index]),
                childCount: pillars.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 64)),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: nikatHeroGradient),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: _GlowCircle(color: nikatOrange.withValues(alpha: 0.25), size: 220),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: _GlowCircle(color: Colors.white.withValues(alpha: 0.06), size: 260),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/nikat_logo.jpg',
                        height: 84,
                        width: 84,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.landingTagline,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.landingDescription,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.push('/login'),
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(AppLocalizations.of(context)!.getStarted),
                        ),
                        OutlinedButton(
                          onPressed: () => context.push('/login'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                          ),
                          child: Text(AppLocalizations.of(context)!.signIn),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  final _Pillar pillar;

  const _PillarCard({required this.pillar});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: nikatNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(pillar.icon, color: nikatNavy, size: 22),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: pillar.live
                        ? nikatOrange.withValues(alpha: 0.12)
                        : nikatNavy.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pillar.live ? AppLocalizations.of(context)!.badgeLive : AppLocalizations.of(context)!.badgeComingSoon,
                    style: TextStyle(
                      color: pillar.live ? nikatOrange : Colors.black45,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              pillar.title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700, color: nikatNavy),
            ),
            const SizedBox(height: 6),
            Text(
              pillar.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            ...pillar.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: nikatOrange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
