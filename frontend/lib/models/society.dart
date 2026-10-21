enum SocietyType { apartment, college, business }

SocietyType societyTypeFromJson(String? value) => switch (value) {
      'COLLEGE' => SocietyType.college,
      'BUSINESS' => SocietyType.business,
      _ => SocietyType.apartment,
    };

String societyTypeToJson(SocietyType type) => switch (type) {
      SocietyType.college => 'COLLEGE',
      SocietyType.business => 'BUSINESS',
      SocietyType.apartment => 'APARTMENT',
    };

class Society {
  final String id;
  final String name;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final SocietyType type;
  final String? emailDomain;

  Society({
    required this.id,
    required this.name,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    this.type = SocietyType.apartment,
    this.emailDomain,
  });

  factory Society.fromJson(Map<String, dynamic> json) => Society(
        id: json['id'] as String,
        name: json['name'] as String,
        addressLine: json['addressLine'] as String,
        city: json['city'] as String,
        state: json['state'] as String,
        pincode: json['pincode'] as String,
        type: societyTypeFromJson(json['type'] as String?),
        emailDomain: json['emailDomain'] as String?,
      );
}
