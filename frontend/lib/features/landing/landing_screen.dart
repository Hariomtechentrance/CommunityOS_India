import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            title: const Text('CommunityOS India'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FilledButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Login'),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      Text(
                        'The Operating System for Every Indian Locality',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'One verified digital space for every apartment, society, colony, '
                        'and locality in India - replacing WhatsApp groups, paper notices, '
                        'and phone calls with a single AI-powered community platform.',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => context.push('/login'),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Get started'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                mainAxisExtent: 220,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _PillarCard(pillar: _pillars[index]),
                childCount: _pillars.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(pillar.icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pillar.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(pillar.live ? 'Live' : 'Coming soon'),
                  backgroundColor: pillar.live
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: pillar.live
                        ? Colors.green.shade800
                        : Colors.grey.shade700,
                    fontSize: 11,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pillar.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ...pillar.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 14),
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
