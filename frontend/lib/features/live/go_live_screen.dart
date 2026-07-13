import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../core/session/session_controller.dart';
import 'live_stream_service.dart';

/// Broadcaster screen: starts the camera, goes live to everyone in the same
/// area, and shows a running viewer count. Stopping (button or back-nav)
/// tears down every viewer's peer connection via `live:stop`.
class GoLiveScreen extends ConsumerStatefulWidget {
  const GoLiveScreen({super.key});

  @override
  ConsumerState<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends ConsumerState<GoLiveScreen> {
  final _titleController = TextEditingController(text: 'Live now');
  bool _starting = false;
  bool _live = false;
  String? _error;

  Future<void> _start() async {
    final service = ref.read(liveStreamServiceProvider);
    final user = ref.read(sessionControllerProvider).value?.user;
    if (service == null || user?.area == null) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await service.startBroadcast(
        name: user!.name ?? 'Someone',
        area: user.area!,
        title: _titleController.text.trim().isEmpty ? 'Live now' : _titleController.text.trim(),
      );
      if (mounted) setState(() => _live = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not start camera/mic: $e');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _stop() async {
    final service = ref.read(liveStreamServiceProvider);
    await service?.stopBroadcast();
    if (mounted) setState(() => _live = false);
  }

  @override
  void dispose() {
    if (_live) {
      ref.read(liveStreamServiceProvider)?.stopBroadcast();
    }
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(liveStreamServiceProvider);

    return PopScope(
      canPop: !_live,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _live) {
          await _stop();
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Go live')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: ColoredBox(
                      color: Colors.black,
                      child: service != null && _live
                          ? RTCVideoView(service.localRenderer, mirror: true)
                          : const Center(
                              child: Icon(Icons.videocam_off, color: Colors.white54, size: 48),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_live)
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'What are you streaming?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  if (_live && service != null) ...[
                    ValueListenableBuilder<int>(
                      valueListenable: service.viewerCount,
                      builder: (context, count, _) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.remove_red_eye, size: 18),
                          const SizedBox(width: 6),
                          Text('$count watching'),
                        ],
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _starting ? null : (_live ? _stop : _start),
                    style: _live
                        ? FilledButton.styleFrom(backgroundColor: Colors.red)
                        : null,
                    icon: Icon(_live ? Icons.stop : Icons.videocam),
                    label: Text(
                      _starting ? 'Starting...' : (_live ? 'End stream' : 'Go live'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
