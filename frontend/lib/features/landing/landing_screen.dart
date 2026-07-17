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

const _pillars = [
  _Pillar(
    icon: Icons.apartment,
    title: 'Society Management',
    description:
        'Notices, complaints, and verified membership approval for your society.',
    features: [
      'Notices & announcements',
      'Complaint tracking',
      'Member approval workflow',
    ],
    live: true,
  ),
  _Pillar(
    icon: Icons.forum,
    title: 'Community',
    description:
        'Posts, questions, recommendations, polls, events, lost & found.',
    features: ['Posts & discussions', 'Polls & events', 'Lost & found'],
    live: true,
  ),
  _Pillar(
    icon: Icons.storefront,
    title: 'Hyperlocal Marketplace',
    description: 'Buy, sell, rent, donate and exchange within your locality.',
    features: ['Buy & sell', 'Rent & donate', 'Second-hand goods'],
    live: true,
  ),
  _Pillar(
    icon: Icons.local_grocery_store,
    title: 'Local Commerce',
    description: 'Every local business gets a page - residents book directly.',
    features: ['Business directory', 'Direct booking', 'Ratings & reviews'],
    live: false,
  ),
  _Pillar(
    icon: Icons.smart_toy,
    title: 'AI Assistant',
    description: 'Ask instead of searching - "Find me a trusted plumber."',
    features: [
      'Natural-language search',
      'Trusted recommendations',
      'Availability lookup',
    ],
    live: false,
  ),
  _Pillar(
    icon: Icons.celebration,
    title: 'Festival Module',
    description: 'Digitize festival donations, volunteering, and schedules.',
    features: ['Donation tracking', 'Volunteer sign-up', 'Event schedules'],
    live: false,
  ),
  _Pillar(
    icon: Icons.emergency,
    title: 'Emergency SOS',
    description: 'One button to alert family, neighbors, and security.',
    features: ['One-tap SOS', 'Neighbor alerts', 'Security notification'],
    live: false,
  ),
  _Pillar(
    icon: Icons.cleaning_services,
    title: 'Domestic Help',
    description: 'Find trusted cooks, drivers, maids, and more.',
    features: ['Verified helpers', 'Availability status', 'Direct contact'],
    live: false,
  ),
  _Pillar(
    icon: Icons.work,
    title: 'Local Jobs',
    description: 'Hire and get hired within your locality.',
    features: ['Post a need', 'Local hiring', 'Quick responses'],
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
                      'Everything your locality needs, in one app',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: nikatNavy,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A growing set of modules built for Indian communities.',
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
                (context, index) => _PillarCard(pillar: _pillars[index]),
                childCount: _pillars.length,
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
                    pillar.live ? 'Live' : 'Coming soon',
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
