class NearbyPlace {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final List<String> types;
  final double? rating;

  NearbyPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.types = const [],
    this.rating,
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> json) => NearbyPlace(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] as String?,
        types: (json['types'] as List?)?.cast<String>() ?? const [],
        rating: (json['rating'] as num?)?.toDouble(),
      );
}
