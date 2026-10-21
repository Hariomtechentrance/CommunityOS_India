class AppUser {
  final String id;
  final String phone;
  final String? name;
  final String? username;
  final String? avatarUrl;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? pincode;
  final String? area;
  final double? latitude;
  final double? longitude;
  final bool verified;
  final bool isSuperAdmin;
  final bool isSuspended;
  final bool activityNotificationsEnabled;
  final bool hideLikeCounts;
  final String allowMessagesFrom;
  final String? headline;
  final List<String> skills;
  final List<String> availableFor;
  final List<String> interests;
  final bool connectEnabled;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.phone,
    this.name,
    this.username,
    this.avatarUrl,
    this.addressLine,
    this.city,
    this.state,
    this.pincode,
    this.area,
    this.latitude,
    this.longitude,
    this.verified = false,
    this.isSuperAdmin = false,
    this.isSuspended = false,
    this.activityNotificationsEnabled = true,
    this.hideLikeCounts = false,
    this.allowMessagesFrom = 'EVERYONE',
    this.headline,
    this.skills = const [],
    this.availableFor = const [],
    this.interests = const [],
    this.connectEnabled = false,
    this.lastLoginAt,
    this.createdAt,
  });

  /// Whether this user has completed the post-login location onboarding.
  bool get hasLocationProfile => area != null && area!.isNotEmpty;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        phone: json['phone'] as String? ?? '',
        name: json['name'] as String?,
        username: json['username'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        addressLine: json['addressLine'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        pincode: json['pincode'] as String?,
        area: json['area'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        verified: json['verified'] as bool? ?? false,
        isSuperAdmin: json['isSuperAdmin'] as bool? ?? false,
        isSuspended: json['isSuspended'] as bool? ?? false,
        activityNotificationsEnabled: json['activityNotificationsEnabled'] as bool? ?? true,
        hideLikeCounts: json['hideLikeCounts'] as bool? ?? false,
        allowMessagesFrom: json['allowMessagesFrom'] as String? ?? 'EVERYONE',
        headline: json['headline'] as String?,
        skills: (json['skills'] as List?)?.cast<String>() ?? const [],
        availableFor: (json['availableFor'] as List?)?.cast<String>() ?? const [],
        interests: (json['interests'] as List?)?.cast<String>() ?? const [],
        connectEnabled: json['connectEnabled'] as bool? ?? false,
        lastLoginAt: json['lastLoginAt'] != null
            ? DateTime.tryParse(json['lastLoginAt'] as String)
            : null,
        createdAt:
            json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'username': username,
        'avatarUrl': avatarUrl,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'pincode': pincode,
        'area': area,
        'latitude': latitude,
        'longitude': longitude,
        'isSuperAdmin': isSuperAdmin,
        'isSuspended': isSuspended,
        'activityNotificationsEnabled': activityNotificationsEnabled,
        'lastLoginAt': lastLoginAt?.toIso8601String(),
      };
}
