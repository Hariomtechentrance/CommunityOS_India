import 'user.dart';

enum AreaPostKind {
  update,
  shop,
  sportsInvite,
  helpRequest,
  socialEvent,
  safetyAlert,
  serviceRequest,
  emergencySos,
}

const allAreaPostKinds = AreaPostKind.values;

AreaPostKind areaPostKindFromJson(String value) {
  switch (value) {
    case 'SHOP':
      return AreaPostKind.shop;
    case 'SPORTS_INVITE':
      return AreaPostKind.sportsInvite;
    case 'HELP_REQUEST':
      return AreaPostKind.helpRequest;
    case 'SOCIAL_EVENT':
      return AreaPostKind.socialEvent;
    case 'SAFETY_ALERT':
      return AreaPostKind.safetyAlert;
    case 'SERVICE_REQUEST':
      return AreaPostKind.serviceRequest;
    case 'EMERGENCY_SOS':
      return AreaPostKind.emergencySos;
    default:
      return AreaPostKind.update;
  }
}

String areaPostKindToJson(AreaPostKind kind) {
  switch (kind) {
    case AreaPostKind.shop:
      return 'SHOP';
    case AreaPostKind.sportsInvite:
      return 'SPORTS_INVITE';
    case AreaPostKind.helpRequest:
      return 'HELP_REQUEST';
    case AreaPostKind.socialEvent:
      return 'SOCIAL_EVENT';
    case AreaPostKind.safetyAlert:
      return 'SAFETY_ALERT';
    case AreaPostKind.serviceRequest:
      return 'SERVICE_REQUEST';
    case AreaPostKind.emergencySos:
      return 'EMERGENCY_SOS';
    case AreaPostKind.update:
      return 'UPDATE';
  }
}

String areaPostKindLabel(AreaPostKind kind) {
  switch (kind) {
    case AreaPostKind.shop:
      return 'Shop';
    case AreaPostKind.sportsInvite:
      return 'Sports Invite';
    case AreaPostKind.helpRequest:
      return 'Help Request';
    case AreaPostKind.socialEvent:
      return 'Social Event';
    case AreaPostKind.safetyAlert:
      return 'Safety Alert';
    case AreaPostKind.serviceRequest:
      return 'Local Service';
    case AreaPostKind.emergencySos:
      return 'Emergency SOS';
    case AreaPostKind.update:
      return 'Area Update';
  }
}

enum EmergencyCategory { accident, medical, fire, womensSafety, other }

EmergencyCategory? emergencyCategoryFromJson(String? value) {
  switch (value) {
    case 'ACCIDENT':
      return EmergencyCategory.accident;
    case 'MEDICAL':
      return EmergencyCategory.medical;
    case 'FIRE':
      return EmergencyCategory.fire;
    case 'WOMENS_SAFETY':
      return EmergencyCategory.womensSafety;
    case 'OTHER':
      return EmergencyCategory.other;
    default:
      return null;
  }
}

String emergencyCategoryToJson(EmergencyCategory category) {
  switch (category) {
    case EmergencyCategory.accident:
      return 'ACCIDENT';
    case EmergencyCategory.medical:
      return 'MEDICAL';
    case EmergencyCategory.fire:
      return 'FIRE';
    case EmergencyCategory.womensSafety:
      return 'WOMENS_SAFETY';
    case EmergencyCategory.other:
      return 'OTHER';
  }
}

String emergencyCategoryLabel(EmergencyCategory category) {
  switch (category) {
    case EmergencyCategory.accident:
      return 'Accident';
    case EmergencyCategory.medical:
      return 'Medical';
    case EmergencyCategory.fire:
      return 'Fire';
    case EmergencyCategory.womensSafety:
      return "Women's Safety";
    case EmergencyCategory.other:
      return 'Other';
  }
}

enum AreaPostVisibility { pincodeOnly, nearby }

AreaPostVisibility areaPostVisibilityFromJson(String? value) {
  return value == 'PINCODE_ONLY' ? AreaPostVisibility.pincodeOnly : AreaPostVisibility.nearby;
}

String areaPostVisibilityToJson(AreaPostVisibility visibility) {
  return visibility == AreaPostVisibility.pincodeOnly ? 'PINCODE_ONLY' : 'NEARBY';
}

class AreaPost {
  final String id;
  final String area;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final AreaPostKind kind;
  final AreaPostVisibility visibility;
  final String title;
  final String description;
  final List<String> imageUrls;
  final String? videoUrl;
  final double? videoTrimStart;
  final double? videoTrimEnd;
  final String? audioUrl;
  final String? location;
  final String? sportName;
  final String? serviceType;
  final String? businessCategory;
  final String? offerText;
  final String? businessHours;
  final EmergencyCategory? emergencyCategory;
  final String? activityTime;
  final int? partnersNeeded;
  final DateTime createdAt;
  final AppUser? user;
  final int interestCount;
  final bool myInterest;
  final bool mySaved;
  final List<AppUser>? interestedUsers;
  final double? distanceKm;

  AreaPost({
    required this.id,
    required this.area,
    this.pincode,
    this.latitude,
    this.longitude,
    required this.kind,
    this.visibility = AreaPostVisibility.nearby,
    required this.title,
    required this.description,
    required this.imageUrls,
    this.videoUrl,
    this.videoTrimStart,
    this.videoTrimEnd,
    this.audioUrl,
    this.location,
    this.sportName,
    this.serviceType,
    this.businessCategory,
    this.offerText,
    this.businessHours,
    this.emergencyCategory,
    this.activityTime,
    this.partnersNeeded,
    required this.createdAt,
    this.user,
    this.interestCount = 0,
    this.myInterest = false,
    this.mySaved = false,
    this.interestedUsers,
    this.distanceKm,
  });

  factory AreaPost.fromJson(Map<String, dynamic> json) => AreaPost(
        id: json['id'] as String,
        area: json['area'] as String,
        pincode: json['pincode'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        kind: areaPostKindFromJson(json['kind'] as String),
        visibility: areaPostVisibilityFromJson(json['visibility'] as String?),
        title: json['title'] as String,
        description: json['description'] as String,
        imageUrls: (json['imageUrls'] as List?)?.cast<String>() ?? [],
        videoUrl: json['videoUrl'] as String?,
        videoTrimStart: (json['videoTrimStart'] as num?)?.toDouble(),
        videoTrimEnd: (json['videoTrimEnd'] as num?)?.toDouble(),
        audioUrl: json['audioUrl'] as String?,
        location: json['location'] as String?,
        sportName: json['sportName'] as String?,
        serviceType: json['serviceType'] as String?,
        businessCategory: json['businessCategory'] as String?,
        offerText: json['offerText'] as String?,
        businessHours: json['businessHours'] as String?,
        emergencyCategory: emergencyCategoryFromJson(json['emergencyCategory'] as String?),
        activityTime: json['activityTime'] as String?,
        partnersNeeded: json['partnersNeeded'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        user: json['user'] != null
            ? AppUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        interestCount: json['_count'] != null
            ? (json['_count'] as Map<String, dynamic>)['interests'] as int? ?? 0
            : 0,
        myInterest: json['myInterest'] as bool? ?? false,
        mySaved: json['mySaved'] as bool? ?? false,
        interestedUsers: json['interestedUsers'] != null
            ? (json['interestedUsers'] as List)
                .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
                .toList()
            : null,
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      );
}

class AreaPostComment {
  final String id;
  final String body;
  final DateTime createdAt;
  final AppUser? author;

  AreaPostComment({
    required this.id,
    required this.body,
    required this.createdAt,
    this.author,
  });

  factory AreaPostComment.fromJson(Map<String, dynamic> json) => AreaPostComment(
        id: json['id'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        author: json['author'] != null
            ? AppUser.fromJson(json['author'] as Map<String, dynamic>)
            : null,
      );
}
