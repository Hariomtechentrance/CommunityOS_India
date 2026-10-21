import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/goal_community.dart';

class GoalCommunitiesRepository {
  final ApiClient _client;

  GoalCommunitiesRepository(this._client);

  Future<GoalCommunity> create({
    required String title,
    required String description,
    required int durationDays,
    String? category,
    int joinCostCoins = 0,
  }) async {
    final res = await _client.dio.post('/goal-communities', data: {
      'title': title,
      'description': description,
      'durationDays': durationDays,
      if (category != null && category.isNotEmpty) 'category': category,
      if (joinCostCoins > 0) 'joinCostCoins': joinCostCoins,
    });
    return GoalCommunity.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<GoalCommunity>> list({String? category}) async {
    final res = await _client.dio.get(
      '/goal-communities',
      queryParameters: {if (category != null) 'category': category},
    );
    return (res.data as List)
        .map((e) => GoalCommunity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GoalCommunity> getById(String id) async {
    final res = await _client.dio.get('/goal-communities/$id');
    return GoalCommunity.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> join(String id) async {
    await _client.dio.post('/goal-communities/$id/join');
  }

  Future<void> leave(String id) async {
    await _client.dio.delete('/goal-communities/$id/join');
  }

  Future<GoalCommunity> checkIn(String id, {String? note}) async {
    final res = await _client.dio.post(
      '/goal-communities/$id/check-in',
      data: {if (note != null && note.isNotEmpty) 'note': note},
    );
    return GoalCommunity.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<GoalLeaderboardEntry>> leaderboard(String id) async {
    final res = await _client.dio.get('/goal-communities/$id/leaderboard');
    return (res.data as List)
        .map((e) => GoalLeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final goalCommunitiesRepositoryProvider = Provider<GoalCommunitiesRepository>(
  (ref) => GoalCommunitiesRepository(ref.read(apiClientProvider)),
);
