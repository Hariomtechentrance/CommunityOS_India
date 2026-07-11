import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/membership.dart';
import '../../models/society.dart';
import '../../models/user.dart';

class VerifyFirebaseTokenResult {
  final String accessToken;
  final AppUser user;

  VerifyFirebaseTokenResult({required this.accessToken, required this.user});
}

class DemoLoginResult {
  final String accessToken;
  final AppUser user;
  final Society society;
  final Membership membership;

  DemoLoginResult({
    required this.accessToken,
    required this.user,
    required this.society,
    required this.membership,
  });
}

class DemoUserSummary {
  final String id;
  final String? name;
  final String? area;
  final String? pincode;
  final String? city;

  DemoUserSummary({this.name, this.area, this.pincode, this.city, required this.id});

  factory DemoUserSummary.fromJson(Map<String, dynamic> json) => DemoUserSummary(
        id: json['id'] as String,
        name: json['name'] as String?,
        area: json['area'] as String?,
        pincode: json['pincode'] as String?,
        city: json['city'] as String?,
      );
}

class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  Future<VerifyFirebaseTokenResult> verifyFirebaseToken(String idToken) async {
    final res = await _client.dio.post('/auth/firebase/verify', data: {'idToken': idToken});
    return VerifyFirebaseTokenResult(
      accessToken: res.data['accessToken'] as String,
      user: AppUser.fromJson(res.data['user'] as Map<String, dynamic>),
    );
  }

  /// Logs into the shared, pre-seeded Demo Society as a fresh Committee Admin
  /// - no login/Firebase required, lets every screen be explored with real data.
  Future<DemoLoginResult> loginAsDemo() async {
    final res = await _client.dio.post('/auth/demo');
    return DemoLoginResult(
      accessToken: res.data['accessToken'] as String,
      user: AppUser.fromJson(res.data['user'] as Map<String, dynamic>),
      society: Society.fromJson(res.data['society'] as Map<String, dynamic>),
      membership: Membership.fromJson(res.data['membership'] as Map<String, dynamic>),
    );
  }

  /// Lists seeded/demo identities that already have a location profile, for
  /// quickly switching between test accounts without repeated OTP/demo taps.
  Future<List<DemoUserSummary>> listDemoUsers() async {
    final res = await _client.dio.get('/auth/demo-users');
    return (res.data as List)
        .map((e) => DemoUserSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VerifyFirebaseTokenResult> demoLoginAs(String userId) async {
    final res = await _client.dio.post('/auth/demo-login/$userId');
    return VerifyFirebaseTokenResult(
      accessToken: res.data['accessToken'] as String,
      user: AppUser.fromJson(res.data['user'] as Map<String, dynamic>),
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(apiClientProvider)),
);
