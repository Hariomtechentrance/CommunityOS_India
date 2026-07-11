import 'user.dart';

class Comment {
  final String id;
  final String body;
  final DateTime createdAt;
  final AppUser? author;

  Comment({required this.id, required this.body, required this.createdAt, this.author});

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        author: json['author'] != null
            ? AppUser.fromJson(json['author'] as Map<String, dynamic>)
            : null,
      );
}
