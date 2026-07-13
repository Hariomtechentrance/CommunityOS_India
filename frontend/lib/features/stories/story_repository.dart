import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/story.dart';

class StoryRepository {
  final ApiClient _client;

  StoryRepository(this._client);

  Future<List<Story>> listActive() async {
    final res = await _client.dio.get('/stories');
    return (res.data as List).map((e) => Story.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Story> create({
    required String mediaUrl,
    required StoryMediaType mediaType,
    String? audioUrl,
  }) async {
    final res = await _client.dio.post(
      '/stories',
      data: {
        'mediaUrl': mediaUrl,
        'mediaType': storyMediaTypeToJson(mediaType),
        if (audioUrl != null) 'audioUrl': audioUrl,
      },
    );
    return Story.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> markViewed(String storyId) async {
    await _client.dio.post('/stories/$storyId/view');
  }

  Future<List<StoryViewer>> getViewers(String storyId) async {
    final res = await _client.dio.get('/stories/$storyId/views');
    return (res.data as List).map((e) => StoryViewer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> delete(String storyId) async {
    await _client.dio.delete('/stories/$storyId');
  }
}

final storyRepositoryProvider = Provider<StoryRepository>(
  (ref) => StoryRepository(ref.read(apiClientProvider)),
);
