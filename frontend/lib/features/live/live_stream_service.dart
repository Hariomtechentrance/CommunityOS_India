import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/turn_credentials.dart';

enum LiveRole { none, broadcaster, viewer }

class LiveViewer {
  final String profileId;
  LiveViewer(this.profileId);
}

class ActiveBroadcast {
  final String profileId;
  final String name;
  final String title;
  final int startedAt;
  final int viewerCount;

  ActiveBroadcast({
    required this.profileId,
    required this.name,
    required this.title,
    required this.startedAt,
    required this.viewerCount,
  });

  factory ActiveBroadcast.fromJson(Map<String, dynamic> json) => ActiveBroadcast(
        profileId: json['profileId'] as String,
        name: json['name'] as String,
        title: json['title'] as String,
        startedAt: json['startedAt'] as int,
        viewerCount: json['viewerCount'] as int,
      );
}

/// Signaling + WebRTC plumbing for one-to-many live streaming - one
/// broadcaster's camera fanned out to N viewers, each over its own
/// RTCPeerConnection (a simple full-mesh fan-out; fine at the scale of a
/// single society/locality, not meant for thousands of concurrent viewers).
class LiveStreamService {
  final String myProfileId;
  final ApiClient apiClient;
  late final io.Socket _socket;

  LiveRole role = LiveRole.none;
  String? _broadcasterProfileId; // set when I'm a viewer
  MediaStream? localStream;
  final remoteRenderer = RTCVideoRenderer();
  final localRenderer = RTCVideoRenderer();
  final ValueNotifier<bool> connected = ValueNotifier(false);
  final ValueNotifier<int> viewerCount = ValueNotifier(0);
  final ValueNotifier<String?> error = ValueNotifier(null);

  /// Broadcaster side: one peer connection per viewer.
  final Map<String, RTCPeerConnection> _viewerConnections = {};
  /// Viewer side: my single connection to the broadcaster.
  RTCPeerConnection? _viewerConnection;

  LiveStreamService({required this.myProfileId, required this.apiClient}) {
    remoteRenderer.initialize();
    localRenderer.initialize();
    _socket = io.io(apiBaseUrl, io.OptionBuilder().setTransports(['websocket']).build());
    _registerListeners();
    _socket.connect();
  }

  void _registerListeners() {
    _socket.onConnect((_) => _socket.emit('register', {'profileId': myProfileId}));

    // --- Broadcaster-side events ---
    _socket.on('live:viewer-joined', (data) async {
      final viewerProfileId = data['viewerProfileId'] as String;
      await _sendOfferTo(viewerProfileId);
      viewerCount.value = _viewerConnections.length;
    });
    _socket.on('live:viewer-left', (data) {
      final viewerProfileId = data['viewerProfileId'] as String;
      _viewerConnections.remove(viewerProfileId)?.close();
      viewerCount.value = _viewerConnections.length;
    });
    _socket.on('live:answer', (data) async {
      final fromProfileId = data['fromProfileId'] as String;
      final pc = _viewerConnections[fromProfileId];
      if (pc == null) return;
      final answer = data['answer'] as Map;
      await pc.setRemoteDescription(
        RTCSessionDescription(answer['sdp'] as String?, answer['type'] as String?),
      );
    });

    // --- Viewer-side events ---
    _socket.on('live:offer', (data) async {
      await _ensureViewerConnection();
      final offer = data['offer'] as Map;
      await _viewerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'] as String?, offer['type'] as String?),
      );
      final answer = await _viewerConnection!.createAnswer();
      await _viewerConnection!.setLocalDescription(answer);
      _socket.emit('live:answer', {
        'toProfileId': _broadcasterProfileId,
        'fromProfileId': myProfileId,
        'answer': answer.toMap(),
      });
      connected.value = true;
    });
    _socket.on('live:ended', (_) => _cleanupViewer());

    // --- Shared ICE relay (fromProfileId disambiguates which peer connection) ---
    _socket.on('live:ice-candidate', (data) async {
      final candidateMap = data['candidate'] as Map?;
      if (candidateMap == null) return;
      final candidate = RTCIceCandidate(
        candidateMap['candidate'] as String?,
        candidateMap['sdpMid'] as String?,
        candidateMap['sdpMLineIndex'] as int?,
      );
      if (role == LiveRole.broadcaster) {
        final fromProfileId = data['fromProfileId'] as String;
        await _viewerConnections[fromProfileId]?.addCandidate(candidate);
      } else {
        await _viewerConnection?.addCandidate(candidate);
      }
    });
  }

  Future<List<ActiveBroadcast>> listActive(ApiClient client, String area) async {
    final res = await client.dio.get('/live-streams', queryParameters: {'area': area});
    return (res.data as List)
        .map((e) => ActiveBroadcast.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Start broadcasting my camera. [area] scopes discovery to the same area
  /// feed everything else uses.
  Future<void> startBroadcast({
    required String name,
    required String area,
    required String title,
  }) async {
    role = LiveRole.broadcaster;
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });
    localRenderer.srcObject = localStream;
    _socket.emit('live:start', {
      'profileId': myProfileId,
      'name': name,
      'area': area,
      'title': title,
    });
    connected.value = true;
  }

  Future<void> _sendOfferTo(String viewerProfileId) async {
    final pc = await createPeerConnection({
      'iceServers': await fetchIceServers(apiClient),
    });
    _viewerConnections[viewerProfileId] = pc;
    for (final track in localStream!.getTracks()) {
      await pc.addTrack(track, localStream!);
    }
    pc.onIceCandidate = (candidate) {
      _socket.emit('live:ice-candidate', {
        'toProfileId': viewerProfileId,
        'fromProfileId': myProfileId,
        'candidate': candidate.toMap(),
      });
    };
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    _socket.emit('live:offer', {
      'toProfileId': viewerProfileId,
      'fromProfileId': myProfileId,
      'offer': offer.toMap(),
    });
  }

  Future<void> stopBroadcast() async {
    _socket.emit('live:stop', {'profileId': myProfileId});
    for (final pc in _viewerConnections.values) {
      await pc.close();
    }
    _viewerConnections.clear();
    for (final track in localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    localStream = null;
    localRenderer.srcObject = null;
    role = LiveRole.none;
    connected.value = false;
    viewerCount.value = 0;
  }

  /// Join an existing broadcast as a viewer.
  void watch(String broadcasterProfileId) {
    role = LiveRole.viewer;
    _broadcasterProfileId = broadcasterProfileId;
    _socket.emit('live:join', {
      'broadcasterProfileId': broadcasterProfileId,
      'viewerProfileId': myProfileId,
    });
  }

  Future<void> _ensureViewerConnection() async {
    if (_viewerConnection != null) return;
    _viewerConnection = await createPeerConnection({
      'iceServers': await fetchIceServers(apiClient),
    });
    _viewerConnection!.onIceCandidate = (candidate) {
      if (_broadcasterProfileId == null) return;
      _socket.emit('live:ice-candidate', {
        'toProfileId': _broadcasterProfileId,
        'fromProfileId': myProfileId,
        'candidate': candidate.toMap(),
      });
    };
    _viewerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };
  }

  void stopWatching() {
    if (_broadcasterProfileId != null) {
      _socket.emit('live:leave', {
        'broadcasterProfileId': _broadcasterProfileId,
        'viewerProfileId': myProfileId,
      });
    }
    _cleanupViewer();
  }

  void _cleanupViewer() {
    _viewerConnection?.close();
    _viewerConnection = null;
    remoteRenderer.srcObject = null;
    _broadcasterProfileId = null;
    role = LiveRole.none;
    connected.value = false;
    error.value ??= null;
  }

  void dispose() {
    if (role == LiveRole.broadcaster) {
      stopBroadcast();
    } else if (role == LiveRole.viewer) {
      stopWatching();
    }
    remoteRenderer.dispose();
    localRenderer.dispose();
    _socket.dispose();
  }
}

final liveStreamServiceProvider = Provider<LiveStreamService?>((ref) {
  final user = ref.watch(sessionControllerProvider).value?.user;
  if (user == null) return null;
  final service = LiveStreamService(myProfileId: user.id, apiClient: ref.read(apiClientProvider));
  ref.onDispose(service.dispose);
  return service;
});
