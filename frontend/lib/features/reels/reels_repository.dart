import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/reel.dart';

class ReelPage {
  final List<Reel> items;
  final int total;
  final int page;
  final int pageSize;

  ReelPage({required this.items, required this.total, required this.page, required this.pageSize});

  bool get hasMore => page * pageSize < total;

  factory ReelPage.fromJson(Map<String, dynamic> json) => ReelPage(
        items: (json['items'] as List)
            .map((e) => Reel.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
      );
}

class ReelsRepository {
  final ApiClient _client;

  ReelsRepository(this._client);

  Future<ReelPage> list({int page = 1}) async {
    final res = await _client.dio.get('/reels', queryParameters: {'page': page});
    return ReelPage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Reel> create({required String videoUrl, String? caption}) async {
    final res = await _client.dio.post(
      '/reels',
      data: {'videoUrl': videoUrl, if (caption != null && caption.isNotEmpty) 'caption': caption},
    );
    return Reel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> toggleLike(String reelId) async {
    final res = await _client.dio.post('/reels/$reelId/like');
    return res.data['liked'] as bool;
  }

  Future<List<ReelComment>> listComments(String reelId) async {
    final res = await _client.dio.get('/reels/$reelId/comments');
    return (res.data as List).map((e) => ReelComment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ReelComment> addComment(String reelId, String body) async {
    final res = await _client.dio.post('/reels/$reelId/comments', data: {'body': body});
    return ReelComment.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String reelId) {
    return _client.dio.delete('/reels/$reelId');
  }
}

final reelsRepositoryProvider = Provider<ReelsRepository>(
  (ref) => ReelsRepository(ref.read(apiClientProvider)),
);
