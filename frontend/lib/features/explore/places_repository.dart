import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/nearby_place.dart';

class PlacesRepository {
  final ApiClient _client;

  PlacesRepository(this._client);

  Future<List<NearbyPlace>> nearby({
    required double lat,
    required double lng,
    String category = 'All',
  }) async {
    final res = await _client.dio.get(
      '/places/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'category': category},
    );
    return (res.data as List)
        .map((e) => NearbyPlace.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final placesRepositoryProvider = Provider<PlacesRepository>(
  (ref) => PlacesRepository(ref.read(apiClientProvider)),
);
