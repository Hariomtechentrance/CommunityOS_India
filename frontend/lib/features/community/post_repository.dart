import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/comment.dart';
import '../../models/post.dart';

class PostRepository {
  final ApiClient _client;

  PostRepository(this._client);

  Future<List<Post>> list(String societyId, {PostType? type}) async {
    final res = await _client.dio.get(
      '/societies/$societyId/posts',
      queryParameters: {if (type != null) 'type': postTypeToJson(type)},
    );
    return (res.data as List).map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Post> create(
    String societyId, {
    required PostType type,
    String? title,
    required String body,
  }) async {
    final res = await _client.dio.post(
      '/societies/$societyId/posts',
      data: {
        'type': postTypeToJson(type),
        if (title != null && title.isNotEmpty) 'title': title,
        'body': body,
      },
    );
    return Post.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Post> getById(String societyId, String postId) async {
    final res = await _client.dio.get('/societies/$societyId/posts/$postId');
    return Post.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Comment> addComment(String societyId, String postId, String body) async {
    final res = await _client.dio.post(
      '/societies/$societyId/posts/$postId/comments',
      data: {'body': body},
    );
    return Comment.fromJson(res.data as Map<String, dynamic>);
  }
}

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.read(apiClientProvider)),
);
