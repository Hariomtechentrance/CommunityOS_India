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

  Future<List<FeatureHealth>> getFeatureHealth() async {
    final res = await _client.dio.get('/admin/feature-health');
    return (res.data as List)
        .map((e) => FeatureHealth.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminErrorLogPage> listErrors({String? path, int page = 1}) async {
    final res = await _client.dio.get(
      '/admin/errors',
      queryParameters: {
        if (path != null && path.isNotEmpty) 'path': path,
        'page': page,
      },
    );
    return AdminErrorLogPage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminFeedbackPage> listFeedback({String? category, String? status, int page = 1}) async {
    final res = await _client.dio.get(
      '/admin/feedback',
      queryParameters: {
        'category': ?category,
        'status': ?status,
        'page': page,
      },
    );
    return AdminFeedbackPage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> setFeedbackStatus(String id, String status) {
    return _client.dio.patch('/admin/feedback/$id/status', data: {'status': status});
  }

  Future<AdminPayoutPage> listPayouts({String? status, int page = 1}) async {
    final res = await _client.dio.get(
      '/admin/payouts',
      queryParameters: {
        if (status != null) 'status': status,
        'page': page,
      },
    );
    return AdminPayoutPage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> setPayoutStatus(String id, String status, {String? adminNote}) {
    return _client.dio.patch('/admin/payouts/$id/status', data: {
      'status': status,
      if (adminNote != null && adminNote.isNotEmpty) 'adminNote': adminNote,
    });
  }
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.read(apiClientProvider)),
);
