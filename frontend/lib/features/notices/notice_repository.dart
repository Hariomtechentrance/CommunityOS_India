import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/notice.dart';

class NoticeRepository {
  final ApiClient _client;

  NoticeRepository(this._client);

  Future<List<Notice>> list(String societyId) async {
    final res = await _client.dio.get('/societies/$societyId/notices');
    return (res.data as List)
        .map((e) => Notice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Notice> create(
    String societyId, {
    required String title,
    required String body,
    bool pinned = false,
  }) async {
    final res = await _client.dio.post(
      '/societies/$societyId/notices',
      data: {'title': title, 'body': body, 'pinned': pinned},
    );
    return Notice.fromJson(res.data as Map<String, dynamic>);
  }
}

final noticeRepositoryProvider = Provider<NoticeRepository>(
  (ref) => NoticeRepository(ref.read(apiClientProvider)),
);
