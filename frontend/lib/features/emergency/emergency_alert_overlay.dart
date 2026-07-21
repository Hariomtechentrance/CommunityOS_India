import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/siren_sound.dart';
import '../../models/area_post.dart';
import '../../models/emergency_alert.dart';
import 'emergency_service.dart';

/// App-wide overlay (mounted via MaterialApp.router's `builder`, alongside
/// CallOverlay) that shows a full-screen siren banner the instant an
/// emergency SOS alert arrives for this user's pincode.
class EmergencyAlertOverlay extends ConsumerStatefulWidget {
  final Widget? child;

  const EmergencyAlertOverlay({super.key, required this.child});

  @override
  ConsumerState<EmergencyAlertOverlay> createState() => _EmergencyAlertOverlayState();
}

class _EmergencyAlertOverlayState extends ConsumerState<EmergencyAlertOverlay> {
  final _player = ap.AudioPlayer();
  EmergencyService? _service;
  EmergencyAlertData? _active;
  Timer? _autoDismiss;

  void _onIncoming() {
    final alert = _service?.incoming.value;
    if (alert == null) return;
    setState(() => _active = alert);
    _player.setReleaseMode(ap.ReleaseMode.loop);
    _player.play(ap.BytesSource(buildSirenWavBytes()));
    _autoDismiss?.cancel();
    _autoDismiss = Timer(const Duration(seconds: 30), _dismiss);
  }

  void _dismiss() {
    _autoDismiss?.cancel();
    _player.stop();
    if (mounted) setState(() => _active = null);
  }

  @override
  void dispose() {
    _service?.incoming.removeListener(_onIncoming);
    _autoDismiss?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reactive on purpose - session loads asynchronously, so a one-time
    // read at first frame (the old approach) would always see a null user
    // and never re-check, silently skipping push-token registration for
    // every login on every session.
    ref.listen<EmergencyService?>(emergencyServiceProvider, (previous, next) {
      previous?.incoming.removeListener(_onIncoming);
      _service = next;
      next?.incoming.addListener(_onIncoming);
    });
    // ref.listen only fires on future changes, not the value already
    // current at this first build - covers the case where a session was
    // already restored (e.g. app relaunch) before this widget ever built.
    if (_service == null) {
      final current = ref.read(emergencyServiceProvider);
      if (current != null) {
        _service = current;
        current.incoming.addListener(_onIncoming);
      }
    }

    final alert = _active;
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        if (alert != null)
          Positioned.fill(
            child: Material(
              color: Colors.red.shade800.withValues(alpha: 0.97),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emergency, color: Colors.white, size: 72),
                      const SizedBox(height: 16),
                      Text(
                        'EMERGENCY NEAR YOU',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        emergencyCategoryLabel(
                          emergencyCategoryFromJson(alert.emergencyCategory) ??
                              EmergencyCategory.other,
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        alert.description,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.area,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red.shade800,
                            ),
                            onPressed: () {
                              final postId = alert.postId;
                              _dismiss();
                              context.push('/home/posts/$postId');
                            },
                            child: const Text('View'),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                            onPressed: _dismiss,
                            child: const Text('Dismiss'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
