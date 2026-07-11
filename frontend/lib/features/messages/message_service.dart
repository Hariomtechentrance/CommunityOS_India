import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../models/message.dart';

/// Real-time delivery for incoming chat messages while the app is open.
/// Message history/persistence goes over REST (see message_repository.dart) -
/// this only pushes already-saved messages live, mirroring
/// [call_service.dart]'s connection/registration pattern.
class MessageService {
  final String myUserId;
  late final io.Socket _socket;

  final ValueNotifier<ChatMessage?> incoming = ValueNotifier(null);

  MessageService({required this.myUserId}) {
    _socket = io.io(
      apiBaseUrl,
      io.OptionBuilder().setTransports(['websocket']).build(),
    );
    _socket.onConnect((_) => _socket.emit('register', {'userId': myUserId}));
    _socket.on('message:new', (data) {
      incoming.value = ChatMessage.fromJson(Map<String, dynamic>.from(data as Map));
    });
    _socket.connect();
  }

  void dispose() {
    _socket.dispose();
  }
}

final messageServiceProvider = Provider<MessageService?>((ref) {
  final user = ref.watch(sessionControllerProvider).value?.user;
  if (user == null) return null;
  final service = MessageService(myUserId: user.id);
  ref.onDispose(service.dispose);
  return service;
});
