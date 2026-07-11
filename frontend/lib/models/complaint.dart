import 'user.dart';

enum ComplaintStatus { open, inProgress, resolved, closed }

ComplaintStatus complaintStatusFromJson(String value) {
  switch (value) {
    case 'IN_PROGRESS':
      return ComplaintStatus.inProgress;
    case 'RESOLVED':
      return ComplaintStatus.resolved;
    case 'CLOSED':
      return ComplaintStatus.closed;
    default:
      return ComplaintStatus.open;
  }
}

String complaintStatusToJson(ComplaintStatus status) {
  switch (status) {
    case ComplaintStatus.inProgress:
      return 'IN_PROGRESS';
    case ComplaintStatus.resolved:
      return 'RESOLVED';
    case ComplaintStatus.closed:
      return 'CLOSED';
    case ComplaintStatus.open:
      return 'OPEN';
  }
}

String complaintStatusLabel(ComplaintStatus status) {
  switch (status) {
    case ComplaintStatus.inProgress:
      return 'In Progress';
    case ComplaintStatus.resolved:
      return 'Resolved';
    case ComplaintStatus.closed:
      return 'Closed';
    case ComplaintStatus.open:
      return 'Open';
  }
}

class Complaint {
  final String id;
  final String category;
  final String description;
  final ComplaintStatus status;
  final DateTime createdAt;
  final AppUser? raisedBy;

  Complaint({
    required this.id,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    this.raisedBy,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint(
        id: json['id'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        status: complaintStatusFromJson(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        raisedBy: json['raisedBy'] != null
            ? AppUser.fromJson(json['raisedBy'] as Map<String, dynamic>)
            : null,
      );
}
