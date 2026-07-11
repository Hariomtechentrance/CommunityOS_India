import 'comment.dart';
import 'user.dart';

enum PostType { general, question, recommendation, lostFound }

PostType postTypeFromJson(String value) {
  switch (value) {
    case 'QUESTION':
      return PostType.question;
    case 'RECOMMENDATION':
      return PostType.recommendation;
    case 'LOST_FOUND':
      return PostType.lostFound;
    default:
      return PostType.general;
  }
}

String postTypeToJson(PostType type) {
  switch (type) {
    case PostType.question:
      return 'QUESTION';
    case PostType.recommendation:
      return 'RECOMMENDATION';
    case PostType.lostFound:
      return 'LOST_FOUND';
    case PostType.general:
      return 'GENERAL';
  }
}

String postTypeLabel(PostType type) {
  switch (type) {
    case PostType.question:
      return 'Question';
    case PostType.recommendation:
      return 'Recommendation';
    case PostType.lostFound:
      return 'Lost & Found';
    case PostType.general:
      return 'General';
  }
}

class Post {
  final String id;
  final PostType type;
  final String? title;
  final String body;
  final DateTime createdAt;
  final AppUser? author;
  final int commentCount;
  final List<Comment>? comments;

  Post({
    required this.id,
    required this.type,
    this.title,
    required this.body,
    required this.createdAt,
    this.author,
    this.commentCount = 0,
    this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        type: postTypeFromJson(json['type'] as String),
        title: json['title'] as String?,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        author: json['author'] != null
            ? AppUser.fromJson(json['author'] as Map<String, dynamic>)
            : null,
        commentCount: json['_count'] != null
            ? (json['_count'] as Map<String, dynamic>)['comments'] as int? ?? 0
            : (json['comments'] as List?)?.length ?? 0,
        comments: json['comments'] != null
            ? (json['comments'] as List)
                .map((e) => Comment.fromJson(e as Map<String, dynamic>))
                .toList()
            : null,
      );
}
