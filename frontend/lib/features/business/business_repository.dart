import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/business.dart';

class BusinessRepository {
  final ApiClient _client;

  BusinessRepository(this._client);

  Future<BusinessProfile> upsertProfile({
    required String businessName,
    required String category,
    String? description,
    String? logoUrl,
    String? coverImageUrl,
    String? website,
  }) async {
    final res = await _client.dio.post('/business/profile', data: {
      'businessName': businessName,
      'category': category,
      if (description != null && description.isNotEmpty) 'description': description,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      if (website != null && website.isNotEmpty) 'website': website,
    });
    return BusinessProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<BusinessProfile?> getMyProfile() async {
    try {
      final res = await _client.dio.get('/business/profile/me');
      if (res.data == null) return null;
      return BusinessProfile.fromJson(res.data as Map<String, dynamic>);
    } on Object catch (_) {
      return null;
    }
  }

  Future<BusinessProfile> getPublicProfile(String userId) async {
    final res = await _client.dio.get('/business/profile/$userId');
    return BusinessProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<BusinessCatalogItem>> listCatalog(String userId) async {
    final res = await _client.dio.get('/business/$userId/catalog');
    return (res.data as List)
        .map((e) => BusinessCatalogItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BusinessCatalogItem> getCatalogItem(String itemId) async {
    final res = await _client.dio.get('/business/catalog-item/$itemId');
    return BusinessCatalogItem.fromJson(res.data as Map<String, dynamic>);
  }

  Future<BusinessCatalogItem> addCatalogItem({
    required String name,
    String? description,
    num? price,
    List<String>? imageUrls,
    bool inStock = true,
  }) async {
    final res = await _client.dio.post('/business/catalog', data: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      if (price != null) 'price': price,
      if (imageUrls != null && imageUrls.isNotEmpty) 'imageUrls': imageUrls,
      'inStock': inStock,
    });
    return BusinessCatalogItem.fromJson(res.data as Map<String, dynamic>);
  }

  Future<BusinessCatalogItem> updateCatalogItem(
    String itemId, {
    required String name,
    String? description,
    num? price,
    List<String>? imageUrls,
    bool inStock = true,
  }) async {
    final res = await _client.dio.patch('/business/catalog/$itemId', data: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      if (price != null) 'price': price,
      if (imageUrls != null) 'imageUrls': imageUrls,
      'inStock': inStock,
    });
    return BusinessCatalogItem.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteCatalogItem(String itemId) {
    return _client.dio.delete('/business/catalog/$itemId');
  }

  Future<BusinessBroadcast> sendBroadcast({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    final res = await _client.dio.post('/business/broadcast', data: {
      'title': title,
      'body': body,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    return BusinessBroadcast.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<BusinessBroadcast>> listMyBroadcasts() async {
    final res = await _client.dio.get('/business/broadcasts/mine');
    return (res.data as List).map((e) => BusinessBroadcast.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BusinessAnalytics> getAnalytics() async {
    final res = await _client.dio.get('/business/analytics');
    return BusinessAnalytics.fromJson(res.data as Map<String, dynamic>);
  }
}

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepository(ref.read(apiClientProvider)),
);
