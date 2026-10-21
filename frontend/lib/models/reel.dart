import 'user.dart';

class LinkedShopPost {
  final String id;
  final String title;
  final List<String> imageUrls;
  final String? offerText;

  LinkedShopPost({required this.id, required this.title, required this.imageUrls, this.offerText});

  factory LinkedShopPost.fromJson(Map<String, dynamic> json) => LinkedShopPost(
        id: json['id'] as String,
        title: json['title'] as String,
        imageUrls: (json['imageUrls'] as List?)?.cast<String>() ?? const [],
        offerText: json['offerText'] as String?,
      );
}

class Reel {
  final String id;
  final String videoUrl;
  final String? caption;
  final DateTime createdAt;
  final AppUser? user;
  final int likeCount;
  final int commentCount;
  final bool myLiked;
  final LinkedShopPost? linkedPost;

  Reel({
    required this.id,
    required this.videoUrl,
    this.caption,
    required this.createdAt,
    this.user,
    this.likeCount = 0,
    this.commentCount = 0,
    this.myLiked = false,
    this.linkedPost,
  });

  factory Reel.fromJson(Map<String, dynamic> json) => Reel(
        id: json['id'] as String,
        videoUrl: json['videoUrl'] as String,
        caption: json['caption'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        user: json['user'] != null
            ? AppUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        likeCount: json['_count'] != null
            ? (json['_count'] as Map<String, dynamic>)['likes'] as int? ?? 0
            : 0,
        commentCount: json['_count'] != null
            ? (json['_count'] as Map<String, dynamic>)['comments'] as int? ?? 0
            : 0,
        myLiked: json['myLiked'] as bool? ?? false,
        linkedPost: json['linkedPost'] != null
            ? LinkedShopPost.fromJson(json['linkedPost'] as Map<String, dynamic>)
            : null,
      );
}

class ReelComment {
  final String id;
  final String body;
  final DateTime createdAt;
  final AppUser? author;

  ReelComment({required this.id, required this.body, required this.createdAt, this.author});

  factory ReelComment.fromJson(Map<String, dynamic> json) => ReelComment(
        id: json['id'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        author: json['author'] != null
            ? AppUser.fromJson(json['author'] as Map<String, dynamic>)
            : null,
      );
}
