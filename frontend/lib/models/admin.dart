import 'user.dart';

class AdminStats {
  final int totalUsers;
  final int suspendedUsers;
  final int activeLast24h;
  final int activeLast7d;
  final int activeLast30d;
  final int totalSocieties;

  AdminStats({
    required this.totalUsers,
    required this.suspendedUsers,
    required this.activeLast24h,
    required this.activeLast7d,
    required this.activeLast30d,
    required this.totalSocieties,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: json['totalUsers'] as int,
        suspendedUsers: json['suspendedUsers'] as int,
        activeLast24h: json['activeLast24h'] as int,
        activeLast7d: json['activeLast7d'] as int,
        activeLast30d: json['activeLast30d'] as int,
        totalSocieties: json['totalSocieties'] as int,
      );
}

class AdminUserPage {
  final List<AppUser> items;
  final int total;
  final int page;
  final int pageSize;

  AdminUserPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < total;

  factory AdminUserPage.fromJson(Map<String, dynamic> json) => AdminUserPage(
        items: (json['items'] as List)
            .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
      );
}

class AdminMembershipSummary {
  final String societyName;
  final String role;
  final String status;

  AdminMembershipSummary({required this.societyName, required this.role, required this.status});

  factory AdminMembershipSummary.fromJson(Map<String, dynamic> json) => AdminMembershipSummary(
        societyName: (json['society'] as Map<String, dynamic>)['name'] as String,
        role: json['role'] as String,
        status: json['status'] as String,
      );
}

class AdminUserDetail {
  final AppUser user;
  final List<AdminMembershipSummary> memberships;
  final int postCount;
  final int complaintCount;
  final int areaPostCount;
  final int listingCount;

  AdminUserDetail({
    required this.user,
    required this.memberships,
    required this.postCount,
    required this.complaintCount,
    required this.areaPostCount,
    required this.listingCount,
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final counts = json['_count'] as Map<String, dynamic>;
    return AdminUserDetail(
      user: AppUser.fromJson(json),
      memberships: (json['memberships'] as List)
          .map((e) => AdminMembershipSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      postCount: counts['posts'] as int,
      complaintCount: counts['raisedComplaints'] as int,
      areaPostCount: counts['areaPosts'] as int,
      listingCount: counts['listings'] as int,
    );
  }
}
