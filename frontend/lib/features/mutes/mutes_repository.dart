import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../follows/follows_repository.dart';

class MutesRepository {
  final ApiClient _client;

  MutesRepository(this._client);

  Future<void> mute(String userId) async {
    await _client.dio.post('/users/$userId/mute');
  }

  Future<void> unmute(String userId) async {
    await _client.dio.delete('/users/$userId/mute');
  }

  Future<UserPage> listMuted({int page = 1}) async {
    final res = await _client.dio.get(
      '/users/me/muted',
      queryParameters: {'page': page},
    );
    return UserPage.fromJson(res.data as Map<String, dynamic>);
  }
}

final mutesRepositoryProvider = Provider<MutesRepository>(
  (ref) => MutesRepository(ref.read(apiClientProvider)),
);
