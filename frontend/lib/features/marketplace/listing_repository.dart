import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/listing.dart';

class ListingRepository {
  final ApiClient _client;

  ListingRepository(this._client);

  Future<List<Listing>> list(String societyId, {ListingCategory? category}) async {
    final res = await _client.dio.get(
      '/societies/$societyId/listings',
      queryParameters: {if (category != null) 'category': listingCategoryToJson(category)},
    );
    return (res.data as List).map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Listing> create(
    String societyId, {
    required ListingCategory category,
    required String title,
    required String description,
    double? price,
    List<String>? imageUrls,
  }) async {
    final res = await _client.dio.post(
      '/societies/$societyId/listings',
      data: {
        'category': listingCategoryToJson(category),
        'title': title,
        'description': description,
        if (price != null) 'price': price,
        if (imageUrls != null && imageUrls.isNotEmpty) 'imageUrls': imageUrls,
      },
    );
    return Listing.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Listing> getById(String societyId, String listingId) async {
    final res = await _client.dio.get('/societies/$societyId/listings/$listingId');
    return Listing.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateStatus(String societyId, String listingId, ListingStatus status) {
    return _client.dio.patch(
      '/societies/$societyId/listings/$listingId/status',
      data: {'status': listingStatusToJson(status)},
    );
  }
}

final listingRepositoryProvider = Provider<ListingRepository>(
  (ref) => ListingRepository(ref.read(apiClientProvider)),
);
