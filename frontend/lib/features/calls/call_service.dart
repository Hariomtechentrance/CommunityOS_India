import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/turn_credentials.dart';

enum CallStatus { idle, calling, ringing, connecting, connected }

class IncomingCall {
  final String fromProfileId;
  final String fromName;

  IncomingCall({required this.fromProfileId, required this.fromName});
}

/// Pure signaling relay + WebRTC plumbing for in-app voice calling between
/// two authenticated users - no phone number is ever exchanged. Only one call
/// at a time is supported.
class CallService {
  final String myProfileId;
  final ApiClient apiClient;
  late final io.Socket _socket;
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  String? _peerProfileId;
  String? _peerName;

  final remoteRenderer = RTCVideoRenderer();
  final ValueNotifier<CallStatus> status = ValueNotifier(CallStatus.idle);
  final ValueNotifier<IncomingCall?> incoming = ValueNotifier(null);
  final ValueNotifier<String?> error = ValueNotifier(null);

  CallService({required this.myProfileId, required this.apiClient}) {
    remoteRenderer.initialize();
    _socket = io.io(
      apiBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': apiClient.token})
          .build(),
    );
    _registerListeners();
    _socket.connect();
  }

  void _registerListeners() {
    _socket.on('call:incoming', (data) {
      _peerProfileId = data['fromProfileId'] as String;
      _peerName = data['fromName'] as String?;
      incoming.value = IncomingCall(fromProfileId: _peerProfileId!, fromName: _peerName ?? '');
      status.value = CallStatus.ringing;
    });

    _socket.on('call:unavailable', (_) {
      status.value = CallStatus.idle;
      _peerProfileId = null;
      error.value = "Couldn't reach them - they may not have the app open right now.";
    });

    _socket.on('call:accepted', (_) async {
      status.value = CallStatus.connecting;
      await _sendOffer();
    });

    _socket.on('call:rejected', (_) => _cleanup());

    _socket.on('call:offer', (data) async {
      await _ensurePeerConnection();
      final offer = data['offer'] as Map;
      await _pc!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'] as String?, offer['type'] as String?),
      );
      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      _socket.emit('call:answer', {'toProfileId': _peerProfileId, 'answer': answer.toMap()});
      status.value = CallStatus.connected;
    });

    _socket.on('call:answer', (data) async {
      final answer = data['answer'] as Map;
      await _pc!.setRemoteDescription(
        RTCSessionDescription(answer['sdp'] as String?, answer['type'] as String?),
      );
      status.value = CallStatus.connected;
    });

    _socket.on('call:ice-candidate', (data) async {
      final c = data['candidate'] as Map?;
      if (c != null && _pc != null) {
        await _pc!.addCandidate(
          RTCIceCandidate(
            c['candidate'] as String?,
            c['sdpMid'] as String?,
            c['sdpMLineIndex'] as int?,
          ),
        );
      }
    });

    _socket.on('call:hangup', (_) => _cleanup());
  }

  Future<void> _ensurePeerConnection() async {
    if (_pc != null) return;
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    } catch (_) {
      error.value = "Couldn't access your microphone. Check your browser's mic permission.";
      hangup();
      rethrow;
    }
    _pc = await createPeerConnection({
      'iceServers': await fetchIceServers(apiClient),
    });
    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }
    _pc!.onIceCandidate = (candidate) {
      if (_peerProfileId == null) return;
      _socket.emit('call:ice-candidate', {
        'toProfileId': _peerProfileId,
        'candidate': candidate.toMap(),
      });
    };
    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };
    // Without a TURN server, calls between peers that can't reach each other
    // directly (different networks/NAT types) land here instead of "connected".
    _pc!.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        error.value = 'Call failed to connect - this can happen across some mobile networks.';
        hangup();
      }
    };
  }

  Future<void> _sendOffer() async {
    await _ensurePeerConnection();
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    _socket.emit('call:offer', {'toProfileId': _peerProfileId, 'offer': offer.toMap()});
  }

  /// Start a call to another profile - never exposes either party's phone number.
  void call(String toProfileId, String myName) {
    _peerProfileId = toProfileId;
    status.value = CallStatus.calling;
    error.value = null;
    _socket.emit('call:invite', {
      'toProfileId': toProfileId,
      'fromProfileId': myProfileId,
      'fromName': myName,
    });
  }

  void accept() {
    incoming.value = null;
    status.value = CallStatus.connecting;
    _socket.emit('call:accept', {'toProfileId': _peerProfileId});
  }

  void reject() {
    _socket.emit('call:reject', {'toProfileId': _peerProfileId});
    incoming.value = null;
    status.value = CallStatus.idle;
    _peerProfileId = null;
  }

  void hangup() {
    if (_peerProfileId != null) {
      _socket.emit('call:hangup', {'toProfileId': _peerProfileId});
    }
    _cleanup();
  }

  void _cleanup() {
    _pc?.close();
    _pc = null;
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    _localStream = null;
    remoteRenderer.srcObject = null;
    status.value = CallStatus.idle;
    incoming.value = null;
    _peerProfileId = null;
    _peerName = null;
  }

  void dispose() {
    _cleanup();
    remoteRenderer.dispose();
    _socket.dispose();
  }
}

final callServiceProvider = Provider<CallService?>((ref) {
  final user = ref.watch(sessionControllerProvider).value?.user;
  if (user == null) return null;
  final service = CallService(myProfileId: user.id, apiClient: ref.read(apiClientProvider));
  ref.onDispose(service.dispose);
  return service;
});
