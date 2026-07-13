import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'area_repository.dart';

/// Ambient "people are around" indicator - a plain count in two distance
/// bands, refreshed periodically. Deliberately never shows who or exactly
/// where anyone is: this is a reassurance/awareness signal, not a tracking
/// tool (see AreaService.nearbyActiveCounts for why that line matters).
class NearbyActivityBanner extends ConsumerStatefulWidget {
  const NearbyActivityBanner({super.key});

  @override
  ConsumerState<NearbyActivityBanner> createState() => _NearbyActivityBannerState();
}

class _NearbyActivityBannerState extends ConsumerState<NearbyActivityBanner> {
  NearbyActiveCounts? _counts;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final counts = await ref.read(areaRepositoryProvider).nearbyActiveCounts();
      if (mounted) setState(() => _counts = counts);
    } catch (_) {
      // Ambient nice-to-have - a failed fetch just means the banner stays hidden.
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;
    // Only hidden before the first successful fetch - once loaded, always
    // show something (including a zero-state) so the feature is actually
    // discoverable instead of silently vanishing.
    if (counts == null) return const SizedBox.shrink();

    final label = counts.within5Km == 0
        ? 'No one else active nearby right now'
        : counts.within1Km > 0
            ? '${counts.within1Km} people active within 1 km'
            : '${counts.within5Km} people active within 5 km';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Icon(Icons.people_alt_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
