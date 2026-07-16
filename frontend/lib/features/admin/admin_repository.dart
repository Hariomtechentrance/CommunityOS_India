import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/admin.dart';
import '../../models/user.dart';

class AdminLoginResult {
  final String accessToken;
  final AppUser user;

  AdminLoginResult({required this.accessToken, required this.user});
}

class AdminRepository {
  final ApiClient _client;

  AdminRepository(this._client);

  /// Super-admin email+password login - separate from the consumer
  /// phone-OTP flow, no Firebase involved.
  Future<AdminLoginResult> login(String email, String password) async {
    final res = await _client.dio.post(
      '/admin/login',
      data: {'email': email, 'password': password},
    );
    return AdminLoginResult(
      accessToken: res.data['accessToken'] as String,
      user: AppUser.fromJson(res.data['user'] as Map<String, dynamic>),
    );
  }

  Future<AdminStats> getStats() async {
    final res = await _client.dio.get('/admin/stats');
    return AdminStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminUserPage> listUsers({String? search, int page = 1}) async {
    final res = await _client.dio.get(
      '/admin/users',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
      },
    );
    return AdminUserPage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminUserDetail> getUserDetail(String userId) async {
    final res = await _client.dio.get('/admin/users/$userId');
    return AdminUserDetail.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> setSuspended(String userId, bool suspended) {
    return _client.dio.patch('/admin/users/$userId/suspend', data: {'suspended': suspended});
  }

  Future<void> deleteUser(String userId) {
    return _client.dio.delete('/admin/users/$userId');
  }
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.read(apiClientProvider)),
);
