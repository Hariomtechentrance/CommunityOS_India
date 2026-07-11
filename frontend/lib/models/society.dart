class Society {
  final String id;
  final String name;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;

  Society({
    required this.id,
    required this.name,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
  });

  factory Society.fromJson(Map<String, dynamic> json) => Society(
        id: json['id'] as String,
        name: json['name'] as String,
        addressLine: json['addressLine'] as String,
        city: json['city'] as String,
        state: json['state'] as String,
        pincode: json['pincode'] as String,
      );
}
