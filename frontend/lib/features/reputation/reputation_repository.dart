import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class ReputationBadge {
  final String key;
  final String label;
  final String emoji;

  ReputationBadge({required this.key, required this.label, required this.emoji});

  factory ReputationBadge.fromJson(Map<String, dynamic> json) => ReputationBadge(
        key: json['key'] as String,
        label: json['label'] as String,
        emoji: json['emoji'] as String,
      );
}

class Reputation {
  final int score;
  final List<ReputationBadge> badges;

  Reputation({required this.score, required this.badges});

  factory Reputation.fromJson(Map<String, dynamic> json) => Reputation(
        score: json['score'] as int,
        badges: (json['badges'] as List)
            .map((e) => ReputationBadge.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ReputationRepository {
  final ApiClient _client;

  ReputationRepository(this._client);

  Future<Reputation> getReputation(String userId) async {
    final res = await _client.dio.get('/users/$userId/reputation');
    return Reputation.fromJson(res.data as Map<String, dynamic>);
  }
}

final reputationRepositoryProvider = Provider<ReputationRepository>(
  (ref) => ReputationRepository(ref.read(apiClientProvider)),
);
