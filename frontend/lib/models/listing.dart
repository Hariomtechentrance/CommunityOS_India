import 'user.dart';

enum ListingCategory { itemSale, itemFree, itemRent, propertySale, propertyRent }

enum ListingStatus { active, closed }

ListingCategory listingCategoryFromJson(String value) {
  switch (value) {
    case 'ITEM_FREE':
      return ListingCategory.itemFree;
    case 'ITEM_RENT':
      return ListingCategory.itemRent;
    case 'PROPERTY_SALE':
      return ListingCategory.propertySale;
    case 'PROPERTY_RENT':
      return ListingCategory.propertyRent;
    default:
      return ListingCategory.itemSale;
  }
}

String listingCategoryToJson(ListingCategory category) {
  switch (category) {
    case ListingCategory.itemFree:
      return 'ITEM_FREE';
    case ListingCategory.itemRent:
      return 'ITEM_RENT';
    case ListingCategory.propertySale:
      return 'PROPERTY_SALE';
    case ListingCategory.propertyRent:
      return 'PROPERTY_RENT';
    case ListingCategory.itemSale:
      return 'ITEM_SALE';
  }
}

String listingCategoryLabel(ListingCategory category) {
  switch (category) {
    case ListingCategory.itemFree:
      return 'Free';
    case ListingCategory.itemRent:
      return 'For Rent';
    case ListingCategory.propertySale:
      return 'Property - Sale';
    case ListingCategory.propertyRent:
      return 'Property - Rent';
    case ListingCategory.itemSale:
      return 'For Sale';
  }
}

ListingStatus listingStatusFromJson(String value) =>
    value == 'CLOSED' ? ListingStatus.closed : ListingStatus.active;

String listingStatusToJson(ListingStatus status) =>
    status == ListingStatus.closed ? 'CLOSED' : 'ACTIVE';

class Listing {
  final String id;
  final ListingCategory category;
  final String title;
  final String description;
  final double? price;
  final List<String> imageUrls;
  final ListingStatus status;
  final DateTime createdAt;
  final AppUser? seller;

  Listing({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.price,
    required this.imageUrls,
    required this.status,
    required this.createdAt,
    this.seller,
  });

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
        id: json['id'] as String,
        category: listingCategoryFromJson(json['category'] as String),
        title: json['title'] as String,
        description: json['description'] as String,
        price: (json['price'] as num?)?.toDouble(),
        imageUrls: (json['imageUrls'] as List?)?.cast<String>() ?? [],
        status: listingStatusFromJson(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        seller: json['seller'] != null
            ? AppUser.fromJson(json['seller'] as Map<String, dynamic>)
            : null,
      );
}
