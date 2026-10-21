import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class AiRepository {
  final ApiClient _client;

  AiRepository(this._client);

  Future<bool> isConfigured() async {
    final res = await _client.dio.get('/ai/status');
    return res.data['configured'] as bool;
  }

  Future<String> translate(String text, String targetLanguage) async {
    final res = await _client.dio.post('/ai/translate', data: {
      'text': text,
      'targetLanguage': targetLanguage,
    });
    return res.data['text'] as String;
  }

  Future<String> askCommunity(String societyId, String question) async {
    final res = await _client.dio.post('/ai/societies/$societyId/ask', data: {
      'question': question,
    });
    return res.data['answer'] as String;
  }

  Future<String> communitySummary(String societyId) async {
    final res = await _client.dio.get('/ai/societies/$societyId/summary');
    return res.data['summary'] as String;
  }
}

final aiRepositoryProvider = Provider<AiRepository>(
  (ref) => AiRepository(ref.read(apiClientProvider)),
);
