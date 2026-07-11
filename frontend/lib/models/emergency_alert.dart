/// An incoming real-time SOS alert pushed via [AlertsGateway] on the
/// backend - a lightweight summary, not the full AreaPost.
class EmergencyAlertData {
  final String postId;
  final String title;
  final String description;
  final String? emergencyCategory;
  final String area;

  EmergencyAlertData({
    required this.postId,
    required this.title,
    required this.description,
    this.emergencyCategory,
    required this.area,
  });

  factory EmergencyAlertData.fromJson(Map<String, dynamic> json) => EmergencyAlertData(
        postId: json['postId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        emergencyCategory: json['emergencyCategory'] as String?,
        area: json['area'] as String,
      );
}
