import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/campaign.dart';

class CampaignsRepository {
  final ApiClient _client;

  CampaignsRepository(this._client);

  Future<Campaign> create({
    required CampaignObjective objective,
    required String title,
    required String description,
    String? imageUrl,
    String? ctaUrl,
    required CampaignTargetType targetType,
    String? targetPincode,
    List<String>? targetStates,
    double? targetLatitude,
    double? targetLongitude,
    double? targetRadiusKm,
    required int budgetInPaise,
  }) async {
    final res = await _client.dio.post(
      '/campaigns',
      data: {
        'objective': campaignObjectiveToJson(objective),
        'title': title,
        'description': description,
        'imageUrl': ?imageUrl,
        if (ctaUrl != null && ctaUrl.isNotEmpty) 'ctaUrl': ctaUrl,
        'targetType': campaignTargetTypeToJson(targetType),
        'targetPincode': ?targetPincode,
        'targetStates': ?targetStates,
        'targetLatitude': ?targetLatitude,
        'targetLongitude': ?targetLongitude,
        'targetRadiusKm': ?targetRadiusKm,
        'budgetInPaise': budgetInPaise,
      },
    );
    return Campaign.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Campaign>> listMine() async {
    final res = await _client.dio.get('/campaigns/mine');
    return (res.data as List).map((e) => Campaign.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> checkout(String campaignId) async {
    final res = await _client.dio.post('/campaigns/$campaignId/checkout');
    return res.data['checkoutUrl'] as String;
  }

  Future<List<Campaign>> feed() async {
    final res = await _client.dio.get('/campaigns/feed');
    return (res.data as List).map((e) => Campaign.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final campaignsRepositoryProvider = Provider<CampaignsRepository>(
  (ref) => CampaignsRepository(ref.read(apiClientProvider)),
);
