import 'user.dart';

class Notice {
  final String id;
  final String title;
  final String body;
  final bool pinned;
  final DateTime createdAt;
  final AppUser? author;

  Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.pinned,
    required this.createdAt,
    this.author,
  });

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        pinned: json['pinned'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        author: json['author'] != null
            ? AppUser.fromJson(json['author'] as Map<String, dynamic>)
            : null,
      );
}
