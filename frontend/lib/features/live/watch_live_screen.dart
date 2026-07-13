import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'live_stream_service.dart';

/// Viewer screen: joins one broadcaster's stream and renders the incoming
/// video. Leaves cleanly on back-nav or when the broadcaster ends the stream.
class WatchLiveScreen extends ConsumerStatefulWidget {
  final String broadcasterProfileId;
  final String broadcasterName;

  const WatchLiveScreen({
    super.key,
    required this.broadcasterProfileId,
    required this.broadcasterName,
  });

  @override
  ConsumerState<WatchLiveScreen> createState() => _WatchLiveScreenState();
}

class _WatchLiveScreenState extends ConsumerState<WatchLiveScreen> {
  bool _left = false;

  @override
  void initState() {
    super.initState();
    ref.read(liveStreamServiceProvider)?.watch(widget.broadcasterProfileId);
  }

  void _leave() {
    if (_left) return;
    _left = true;
    ref.read(liveStreamServiceProvider)?.stopWatching();
  }

  @override
  void dispose() {
    _leave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(liveStreamServiceProvider);

    return PopScope(
      onPopInvokedWithResult: (_, _) => _leave(),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.broadcasterName)),
        body: service == null
            ? const SizedBox.shrink()
            : ValueListenableBuilder<bool>(
                valueListenable: service.connected,
                builder: (context, connected, _) {
                  if (!connected) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Center(
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: RTCVideoView(service.remoteRenderer),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
