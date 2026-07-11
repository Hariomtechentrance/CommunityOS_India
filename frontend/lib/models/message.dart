import 'user.dart';

enum MessageKind { text, sticker }

MessageKind messageKindFromJson(String? value) =>
    value == 'STICKER' ? MessageKind.sticker : MessageKind.text;

String messageKindToJson(MessageKind kind) =>
    kind == MessageKind.sticker ? 'STICKER' : 'TEXT';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String body;
  final MessageKind kind;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.body,
    this.kind = MessageKind.text,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        receiverId: json['receiverId'] as String,
        body: json['body'] as String,
        kind: messageKindFromJson(json['kind'] as String?),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class ChatThread {
  final AppUser otherUser;
  final ChatMessage lastMessage;

  ChatThread({required this.otherUser, required this.lastMessage});

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
        otherUser: AppUser.fromJson(json['otherUser'] as Map<String, dynamic>),
        lastMessage: ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>),
      );
}
