import 'user.dart';

class BusinessProfile {
  final String id;
  final String userId;
  final String businessName;
  final String category;
  final String? description;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? website;
  final bool isVerified;
  final int profileViews;
  final AppUser? user;
  final int catalogItemCount;
  final int broadcastCount;

  BusinessProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.category,
    this.description,
    this.logoUrl,
    this.coverImageUrl,
    this.website,
    this.isVerified = false,
    this.profileViews = 0,
    this.user,
    this.catalogItemCount = 0,
    this.broadcastCount = 0,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) => BusinessProfile(
        id: json['id'] as String,
        userId: json['userId'] as String,
        businessName: json['businessName'] as String,
        category: json['category'] as String,
        description: json['description'] as String?,
        logoUrl: json['logoUrl'] as String?,
        coverImageUrl: json['coverImageUrl'] as String?,
        website: json['website'] as String?,
        isVerified: json['isVerified'] as bool? ?? false,
        profileViews: json['profileViews'] as int? ?? 0,
        user: json['user'] != null ? AppUser.fromJson(json['user'] as Map<String, dynamic>) : null,
        catalogItemCount: json['_count'] != null
            ? (json['_count'] as Map<String, dynamic>)['catalogItems'] as int? ?? 0
            : 0,
        broadcastCount: json['_count'] != null
            ? (json['_count'] as Map<String, dynamic>)['broadcasts'] as int? ?? 0
            : 0,
      );
}

class BusinessCatalogItem {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final num? price;
  final List<String> imageUrls;
  final bool inStock;
  final int viewCount;
  final DateTime createdAt;

  BusinessCatalogItem({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    this.price,
    this.imageUrls = const [],
    this.inStock = true,
    this.viewCount = 0,
    required this.createdAt,
  });

  factory BusinessCatalogItem.fromJson(Map<String, dynamic> json) => BusinessCatalogItem(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: json['price'] as num?,
        imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
        inStock: json['inStock'] as bool? ?? true,
        viewCount: json['viewCount'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class BusinessBroadcast {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final int recipientCount;
  final DateTime createdAt;

  BusinessBroadcast({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.recipientCount = 0,
    required this.createdAt,
  });

  factory BusinessBroadcast.fromJson(Map<String, dynamic> json) => BusinessBroadcast(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        imageUrl: json['imageUrl'] as String?,
        recipientCount: json['recipientCount'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class BusinessAnalytics {
  final int profileViews;
  final int followerCount;
  final int catalogItemCount;
  final int totalCatalogViews;
  final int broadcastsSent;
  final int totalBroadcastReach;

  BusinessAnalytics({
    required this.profileViews,
    required this.followerCount,
    required this.catalogItemCount,
    required this.totalCatalogViews,
    required this.broadcastsSent,
    required this.totalBroadcastReach,
  });

  factory BusinessAnalytics.fromJson(Map<String, dynamic> json) => BusinessAnalytics(
        profileViews: json['profileViews'] as int? ?? 0,
        followerCount: json['followerCount'] as int? ?? 0,
        catalogItemCount: json['catalogItemCount'] as int? ?? 0,
        totalCatalogViews: json['totalCatalogViews'] as int? ?? 0,
        broadcastsSent: json['broadcastsSent'] as int? ?? 0,
        totalBroadcastReach: json['totalBroadcastReach'] as int? ?? 0,
      );
}
