import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../follows/follows_repository.dart';

class BlocksRepository {
  final ApiClient _client;

  BlocksRepository(this._client);

  Future<void> block(String userId) async {
    await _client.dio.post('/users/$userId/block');
  }

  Future<void> unblock(String userId) async {
    await _client.dio.delete('/users/$userId/block');
  }

  Future<UserPage> listBlocked({int page = 1}) async {
    final res = await _client.dio.get(
      '/users/me/blocked',
      queryParameters: {'page': page},
    );
    return UserPage.fromJson(res.data as Map<String, dynamic>);
  }
}

final blocksRepositoryProvider = Provider<BlocksRepository>(
  (ref) => BlocksRepository(ref.read(apiClientProvider)),
);
