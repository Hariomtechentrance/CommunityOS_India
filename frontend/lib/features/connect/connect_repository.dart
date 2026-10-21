import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/user.dart';

class ConnectMatch {
  final AppUser? user;
  final List<String> sharedInterests;
  final String? reason;

  ConnectMatch({this.user, this.sharedInterests = const [], this.reason});

  factory ConnectMatch.fromJson(Map<String, dynamic> json) => ConnectMatch(
        user: json['match'] != null
            ? AppUser.fromJson(json['match'] as Map<String, dynamic>)
            : null,
        sharedInterests: (json['sharedInterests'] as List?)?.cast<String>() ?? const [],
        reason: json['reason'] as String?,
      );
}

class ConnectRepository {
  final ApiClient _client;

  ConnectRepository(this._client);

  Future<void> updateSettings({bool? connectEnabled, List<String>? interests}) async {
    await _client.dio.patch('/connect/settings', data: {
      if (connectEnabled != null) 'connectEnabled': connectEnabled,
      if (interests != null) 'interests': interests,
    });
  }

  Future<ConnectMatch> findMatch() async {
    final res = await _client.dio.get('/connect/match');
    return ConnectMatch.fromJson(res.data as Map<String, dynamic>);
  }
}

final connectRepositoryProvider = Provider<ConnectRepository>(
  (ref) => ConnectRepository(ref.read(apiClientProvider)),
);
