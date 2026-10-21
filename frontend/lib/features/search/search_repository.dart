import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/area_post.dart';
import '../../models/goal_community.dart';
import '../../models/society.dart';
import '../../models/user.dart';

class SearchResults {
  final List<AppUser> users;
  final List<Society> communities;
  final List<AreaPost> posts;
  final List<GoalCommunity> goalCommunities;

  SearchResults({
    required this.users,
    required this.communities,
    required this.posts,
    required this.goalCommunities,
  });

  bool get isEmpty =>
      users.isEmpty && communities.isEmpty && posts.isEmpty && goalCommunities.isEmpty;

  factory SearchResults.fromJson(Map<String, dynamic> json) => SearchResults(
        users: (json['users'] as List)
            .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
            .toList(),
        communities: (json['communities'] as List)
            .map((e) => Society.fromJson(e as Map<String, dynamic>))
            .toList(),
        posts: (json['posts'] as List)
            .map((e) => AreaPost.fromJson(e as Map<String, dynamic>))
            .toList(),
        goalCommunities: (json['goalCommunities'] as List)
            .map((e) => GoalCommunity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SearchRepository {
  final ApiClient _client;

  SearchRepository(this._client);

  Future<SearchResults> searchAll(String query) async {
    final res = await _client.dio.get('/search', queryParameters: {'q': query});
    return SearchResults.fromJson(res.data as Map<String, dynamic>);
  }
}

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.read(apiClientProvider)),
);
