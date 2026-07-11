import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/api_client.dart';
import '../../core/firebase_messaging_config.dart';
import '../../core/session/session_controller.dart';
import '../../models/emergency_alert.dart';
import '../users/user_repository.dart';

/// Delivers emergency SOS alerts two ways: an instant real-time socket
/// event (works whenever the app is open, any tab, mirrors
/// call_service.dart/message_service.dart's connect/register pattern), and
/// registering a Web Push token so alerts can also reach this device when
/// the app is fully closed (handled by web/firebase-messaging-sw.js).
class EmergencyService {
  final String myUserId;
  late final io.Socket _socket;

  final ValueNotifier<EmergencyAlertData?> incoming = ValueNotifier(null);

  EmergencyService({required this.myUserId}) {
    _socket = io.io(
      apiBaseUrl,
      io.OptionBuilder().setTransports(['websocket']).build(),
    );
    _socket.onConnect((_) => _socket.emit('register', {'userId': myUserId}));
    _socket.on('alert:incoming', (data) {
      incoming.value = EmergencyAlertData.fromJson(Map<String, dynamic>.from(data as Map));
    });
    _socket.connect();
  }

  /// Best-effort - push registration silently does nothing if the user
  /// denies permission, or if the VAPID key hasn't been configured yet.
  Future<void> registerPushToken(UserRepository userRepository) async {
    if (vapidKey.startsWith('REPLACE_WITH')) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await FirebaseMessaging.instance.getToken(vapidKey: vapidKey);
      if (token != null) await userRepository.updateFcmToken(token);
    } catch (_) {
      // Push is a best-effort secondary channel - never block the app on it.
    }
  }

  void dispose() {
    _socket.dispose();
  }
}

final emergencyServiceProvider = Provider<EmergencyService?>((ref) {
  final user = ref.watch(sessionControllerProvider).value?.user;
  if (user == null) return null;
  final service = EmergencyService(myUserId: user.id);
  service.registerPushToken(ref.read(userRepositoryProvider));
  ref.onDispose(service.dispose);
  return service;
});
