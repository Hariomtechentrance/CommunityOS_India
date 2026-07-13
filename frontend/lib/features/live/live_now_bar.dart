import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import 'live_stream_service.dart';
import 'watch_live_screen.dart';

/// Horizontal row of who's currently live in this area, right below the
/// stories bar. Empty (renders nothing) when no one is broadcasting, so it
/// never adds dead space to the feed.
///
/// Polls on a timer rather than fetching once - the Home tab sits inside an
/// IndexedStack (see HomeShellScreen), so switching tabs and back never
/// recreates this widget or re-runs initState, and there's no push channel
/// for "someone just went live".
class LiveNowBar extends ConsumerStatefulWidget {
  const LiveNowBar({super.key});

  @override
  ConsumerState<LiveNowBar> createState() => _LiveNowBarState();
}

class _LiveNowBarState extends ConsumerState<LiveNowBar> {
  List<ActiveBroadcast> _broadcasts = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final user = ref.read(sessionControllerProvider).value?.user;
    final service = ref.read(liveStreamServiceProvider);
    if (user?.area == null || service == null) return;
    try {
      final broadcasts = await service.listActive(ref.read(apiClientProvider), user!.area!);
      if (mounted) setState(() => _broadcasts = broadcasts);
    } catch (_) {
      // Live-now discovery is a nice-to-have - a failed fetch just means the
      // row stays hidden, not an error banner on the whole feed.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_broadcasts.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _broadcasts.length,
        itemBuilder: (context, index) {
          final b = _broadcasts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      WatchLiveScreen(broadcasterProfileId: b.profileId, broadcasterName: b.name),
                ),
              ),
              child: Container(
                width: 110,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      b.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.remove_red_eye, size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          '${b.viewerCount}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
