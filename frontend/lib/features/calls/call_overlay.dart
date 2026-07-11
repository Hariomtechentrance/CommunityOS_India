import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'call_service.dart';

/// App-wide overlay (mounted via MaterialApp.router's `builder`) that shows
/// an incoming-call prompt or an in-call banner regardless of which screen
/// is currently active - calling only makes sense within "My Area", but the
/// callee could be anywhere in that section when a call arrives.
class CallOverlay extends ConsumerWidget {
  final Widget? child;

  const CallOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callService = ref.watch(callServiceProvider);
    if (callService == null) return child ?? const SizedBox.shrink();

    return Stack(
      children: [
        if (child != null) child!,
        ValueListenableBuilder<IncomingCall?>(
          valueListenable: callService.incoming,
          builder: (context, incoming, _) {
            if (incoming != null) {
              return _IncomingCallCard(callService: callService, incoming: incoming);
            }
            return ValueListenableBuilder<CallStatus>(
              valueListenable: callService.status,
              builder: (context, status, _) {
                if (status == CallStatus.idle) return const SizedBox.shrink();
                return _InCallBar(callService: callService, status: status);
              },
            );
          },
        ),
      ],
    );
  }
}

class _IncomingCallCard extends StatelessWidget {
  final CallService callService;
  final IncomingCall incoming;

  const _IncomingCallCard({required this.callService, required this.incoming});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Center(
        child: Card(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${incoming.fromName.isEmpty ? "Someone" : incoming.fromName} is calling...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: callService.accept,
                      icon: const Icon(Icons.call),
                      label: const Text('Accept'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: callService.reject,
                      icon: const Icon(Icons.call_end),
                      label: const Text('Reject'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InCallBar extends StatelessWidget {
  final CallService callService;
  final CallStatus status;

  const _InCallBar({required this.callService, required this.status});

  String get _label {
    switch (status) {
      case CallStatus.calling:
        return 'Calling...';
      case CallStatus.connecting:
        return 'Connecting...';
      case CallStatus.connected:
        return 'On call';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: SafeArea(
        child: Material(
          color: Colors.green.shade700,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.call, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_label, style: const TextStyle(color: Colors.white)),
                ),
                // Kept in the tree (0x0) so the remote audio track actually plays.
                SizedBox(
                  width: 0,
                  height: 0,
                  child: RTCVideoView(callService.remoteRenderer),
                ),
                IconButton(
                  onPressed: callService.hangup,
                  icon: const Icon(Icons.call_end, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
