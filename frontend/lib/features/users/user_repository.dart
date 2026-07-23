import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/user.dart';

class UserRepository {
  final ApiClient _client;

  UserRepository(this._client);

  Future<AppUser> getMe() async {
    final res = await _client.dio.get('/users/me');
    return AppUser.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AppUser> getById(String userId) async {
    final res = await _client.dio.get('/users/$userId/profile');
    return AppUser.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<AppUser>> search(String query) async {
    final res = await _client.dio.get('/users/search', queryParameters: {'q': query});
    return (res.data as List).map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AppUser> updateLocation({
    String? name,
    String? addressLine,
    String? city,
    String? state,
    String? pincode,
    String? area,
    double? lat,
    double? lng,
  }) async {
    final res = await _client.dio.patch(
      '/users/me/location',
      data: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (addressLine != null && addressLine.isNotEmpty) 'addressLine': addressLine,
        if (city != null && city.isNotEmpty) 'city': city,
        if (state != null && state.isNotEmpty) 'state': state,
        if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
        if (area != null && area.isNotEmpty) 'area': area,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
    );
    return AppUser.fromJson(res.data as Map<String, dynamic>);
  }

  Future<String?> detectArea({required double lat, required double lng}) async {
    final res = await _client.dio.post('/users/me/detect-area', data: {'lat': lat, 'lng': lng});
    return res.data['area'] as String?;
  }

  Future<List<AppUser>> listNeighbours(String area) async {
    final res = await _client.dio.get('/users/me/neighbours', queryParameters: {'area': area});
    return (res.data as List).map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateFcmToken(String token) async {
    await _client.dio.patch('/users/me/fcm-token', data: {'token': token});
  }

  /// Travel feed signal - records that this device is physically at (lat,
  /// lng) right now, separate from and never touching the home address set
  /// via [updateLocation]. Meant to be sent once per app foreground.
  Future<void> recordLocationVisit({required double lat, required double lng}) async {
    await _client.dio.post('/users/me/location-visit', data: {'lat': lat, 'lng': lng});
  }

  Future<AppUser> updateAvatar(String avatarUrl) async {
    final res = await _client.dio.patch('/users/me/avatar', data: {'avatarUrl': avatarUrl});
    return AppUser.fromJson(res.data as Map<String, dynamic>);
  }
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.read(apiClientProvider)),
);
