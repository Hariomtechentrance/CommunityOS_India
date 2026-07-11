import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/message.dart';

class MessageRepository {
  final ApiClient _client;

  MessageRepository(this._client);

  Future<List<ChatThread>> listThreads() async {
    final res = await _client.dio.get('/messages/threads');
    return (res.data as List).map((e) => ChatThread.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ChatMessage>> getThread(String otherUserId) async {
    final res = await _client.dio.get('/messages/with/$otherUserId');
    return (res.data as List).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ChatMessage> send(String toUserId, String body, {MessageKind kind = MessageKind.text}) async {
    final res = await _client.dio.post(
      '/messages',
      data: {'toUserId': toUserId, 'body': body, 'kind': messageKindToJson(kind)},
    );
    return ChatMessage.fromJson(res.data as Map<String, dynamic>);
  }
}

final messageRepositoryProvider = Provider<MessageRepository>(
  (ref) => MessageRepository(ref.read(apiClientProvider)),
);
