import 'user.dart';

enum MembershipRole { superAdmin, committeeAdmin, security, resident }

enum MembershipStatus { pending, approved, rejected }

MembershipRole membershipRoleFromJson(String value) {
  switch (value) {
    case 'SUPER_ADMIN':
      return MembershipRole.superAdmin;
    case 'COMMITTEE_ADMIN':
      return MembershipRole.committeeAdmin;
    case 'SECURITY':
      return MembershipRole.security;
    default:
      return MembershipRole.resident;
  }
}

MembershipStatus membershipStatusFromJson(String value) {
  switch (value) {
    case 'APPROVED':
      return MembershipStatus.approved;
    case 'REJECTED':
      return MembershipStatus.rejected;
    default:
      return MembershipStatus.pending;
  }
}

bool isStaffRole(MembershipRole role) =>
    role == MembershipRole.committeeAdmin ||
    role == MembershipRole.superAdmin ||
    role == MembershipRole.security;

class Membership {
  final String id;
  final String userId;
  final String societyId;
  final String? unitId;
  final MembershipRole role;
  final MembershipStatus status;
  final AppUser? user;
  final String? unitNumber;

  Membership({
    required this.id,
    required this.userId,
    required this.societyId,
    this.unitId,
    required this.role,
    required this.status,
    this.user,
    this.unitNumber,
  });

  factory Membership.fromJson(Map<String, dynamic> json) => Membership(
        id: json['id'] as String,
        userId: json['userId'] as String,
        societyId: json['societyId'] as String,
        unitId: json['unitId'] as String?,
        role: membershipRoleFromJson(json['role'] as String),
        status: membershipStatusFromJson(json['status'] as String),
        user: json['user'] != null
            ? AppUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        unitNumber: json['unit'] != null
            ? (json['unit'] as Map<String, dynamic>)['unitNumber'] as String?
            : null,
      );
}
