import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/area_post.dart';
import '../../models/user.dart';

class AreaRepository {
  final ApiClient _client;

  AreaRepository(this._client);

  Future<List<AreaPost>> list(String area, {AreaPostKind? kind, bool mine = false}) async {
    final res = await _client.dio.get(
      '/area-posts',
      queryParameters: {
        'area': area,
        if (kind != null) 'kind': areaPostKindToJson(kind),
        if (mine) 'mine': 'true',
      },
    );
    return (res.data as List).map((e) => AreaPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Personalized feed ranked by overlap with the viewer's interests,
  /// reaction/interest engagement, and recency - a lightweight Instagram-style
  /// "For You" feed. See AreaService.listForYou on the backend for the scoring.
  Future<List<AreaPost>> forYou(String area) async {
    final res = await _client.dio.get('/area-posts/for-you', queryParameters: {'area': area});
    return (res.data as List).map((e) => AreaPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AreaPost> create({
    required String area,
    required AreaPostKind kind,
    required String title,
    required String description,
    List<String>? imageUrls,
    String? location,
    String? sportName,
    AreaPostVisibility visibility = AreaPostVisibility.nearby,
    String? serviceType,
    String? businessCategory,
    String? offerText,
    String? videoUrl,
    double? videoTrimStart,
    double? videoTrimEnd,
    String? audioUrl,
    EmergencyCategory? emergencyCategory,
    String? businessHours,
    String? activityTime,
    int? partnersNeeded,
    double? radiusKm,
  }) async {
    final res = await _client.dio.post(
      '/area-posts',
      data: {
        'area': area,
        'kind': areaPostKindToJson(kind),
        'title': title,
        'description': description,
        if (imageUrls != null && imageUrls.isNotEmpty) 'imageUrls': imageUrls,
        if (location != null && location.isNotEmpty) 'location': location,
        if (sportName != null && sportName.isNotEmpty) 'sportName': sportName,
        'visibility': areaPostVisibilityToJson(visibility),
        'radiusKm': ?radiusKm,
        if (serviceType != null && serviceType.isNotEmpty) 'serviceType': serviceType,
        if (businessCategory != null && businessCategory.isNotEmpty)
          'businessCategory': businessCategory,
        if (offerText != null && offerText.isNotEmpty) 'offerText': offerText,
        'videoUrl': ?videoUrl,
        'videoTrimStart': ?videoTrimStart,
        'videoTrimEnd': ?videoTrimEnd,
        'audioUrl': ?audioUrl,
        if (emergencyCategory != null)
          'emergencyCategory': emergencyCategoryToJson(emergencyCategory),
        if (businessHours != null && businessHours.isNotEmpty) 'businessHours': businessHours,
        if (activityTime != null && activityTime.isNotEmpty) 'activityTime': activityTime,
        'partnersNeeded': ?partnersNeeded,
      },
    );
    return AreaPost.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AreaPost> getById(String id) async {
    final res = await _client.dio.get('/area-posts/$id');
    return AreaPost.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<AreaPost>> listSaved() async {
    final res = await _client.dio.get('/area-posts/saved');
    return (res.data as List).map((e) => AreaPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<bool> toggleSave(String areaPostId) async {
    final res = await _client.dio.post('/area-posts/$areaPostId/save');
    return res.data['saved'] as bool;
  }

  Future<List<AreaPostComment>> listComments(String areaPostId) async {
    final res = await _client.dio.get('/area-posts/$areaPostId/comments');
    return (res.data as List)
        .map((e) => AreaPostComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AreaPostComment> addComment(String areaPostId, String body) async {
    final res =
        await _client.dio.post('/area-posts/$areaPostId/comments', data: {'body': body});
    return AreaPostComment.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<AreaPost>> listNearby({
    required double lat,
    required double lng,
    double radiusKm = 10,
    AreaPostKind? kind,
  }) async {
    final res = await _client.dio.get(
      '/area-posts/nearby',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
        if (kind != null) 'kind': areaPostKindToJson(kind),
      },
    );
    return (res.data as List).map((e) => AreaPost.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<bool> toggleInterest(String areaPostId) async {
    final res = await _client.dio.post('/area-posts/$areaPostId/interest');
    return res.data['interested'] as bool;
  }

  /// Returns the fresh summary ({myReaction, counts}) so the caller can
  /// update its UI without a second round-trip.
  Future<Map<String, dynamic>> react(String areaPostId, String emoji) async {
    final res = await _client.dio.post('/area-posts/$areaPostId/react', data: {'emoji': emoji});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> removeReaction(String areaPostId) async {
    final res = await _client.dio.delete('/area-posts/$areaPostId/react');
    return res.data as Map<String, dynamic>;
  }

  Future<List<AppUser>> listReactors(String areaPostId, {String? emoji}) async {
    final res = await _client.dio.get(
      '/area-posts/$areaPostId/reactions',
      queryParameters: {if (emoji != null) 'emoji': emoji},
    );
    return (res.data as List).map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Aggregate-only counts of people with the app currently open nearby -
  /// never individual positions/identities, by design.
  Future<NearbyActiveCounts> nearbyActiveCounts() async {
    final res = await _client.dio.get('/area-posts/nearby-active-counts');
    return NearbyActiveCounts.fromJson(res.data as Map<String, dynamic>);
  }
}

class NearbyActiveCounts {
  final int within1Km;
  final int within5Km;

  NearbyActiveCounts({required this.within1Km, required this.within5Km});

  factory NearbyActiveCounts.fromJson(Map<String, dynamic> json) => NearbyActiveCounts(
        within1Km: json['within1Km'] as int,
        within5Km: json['within5Km'] as int,
      );
}

final areaRepositoryProvider = Provider<AreaRepository>(
  (ref) => AreaRepository(ref.read(apiClientProvider)),
);
