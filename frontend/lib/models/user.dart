class AppUser {
  final String id;
  final String phone;
  final String? name;
  final String? avatarUrl;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? pincode;
  final String? area;
  final double? latitude;
  final double? longitude;
  final bool verified;

  AppUser({
    required this.id,
    required this.phone,
    this.name,
    this.avatarUrl,
    this.addressLine,
    this.city,
    this.state,
    this.pincode,
    this.area,
    this.latitude,
    this.longitude,
    this.verified = false,
  });

  /// Whether this user has completed the post-login location onboarding.
  bool get hasLocationProfile => area != null && area!.isNotEmpty;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        phone: json['phone'] as String? ?? '',
        name: json['name'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        addressLine: json['addressLine'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        pincode: json['pincode'] as String?,
        area: json['area'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        verified: json['verified'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'avatarUrl': avatarUrl,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'pincode': pincode,
        'area': area,
        'latitude': latitude,
        'longitude': longitude,
      };
}
