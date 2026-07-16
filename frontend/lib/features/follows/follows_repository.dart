import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/follow.dart';
import '../../models/user.dart';

class UserPage {
  final List<AppUser> items;
  final int total;
  final int page;
  final int pageSize;

  UserPage({required this.items, required this.total, required this.page, required this.pageSize});

  bool get hasMore => page * pageSize < total;

  factory UserPage.fromJson(Map<String, dynamic> json) => UserPage(
        items: (json['items'] as List)
            .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
      );
}

class FollowsRepository {
  final ApiClient _client;

  FollowsRepository(this._client);

  Future<FollowStats> follow(String userId) async {
    final res = await _client.dio.post('/users/$userId/follow');
    return FollowStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<FollowStats> unfollow(String userId) async {
    final res = await _client.dio.delete('/users/$userId/follow');
    return FollowStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<FollowStats> getStats(String userId) async {
    final res = await _client.dio.get('/users/$userId/follow-stats');
    return FollowStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserPage> listFollowers(String userId, {int page = 1}) async {
    final res = await _client.dio.get(
      '/users/$userId/followers',
      queryParameters: {'page': page},
    );
    return UserPage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserPage> listFollowing(String userId, {int page = 1}) async {
    final res = await _client.dio.get(
      '/users/$userId/following',
      queryParameters: {'page': page},
    );
    return UserPage.fromJson(res.data as Map<String, dynamic>);
  }
}

final followsRepositoryProvider = Provider<FollowsRepository>(
  (ref) => FollowsRepository(ref.read(apiClientProvider)),
);
