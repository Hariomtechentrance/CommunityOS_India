import 'user.dart';

class FeatureHealth {
  final String key;
  final String label;
  final int recentActivity;
  final int recentErrors;
  final String status; // healthy | degraded | failing

  FeatureHealth({
    required this.key,
    required this.label,
    required this.recentActivity,
    required this.recentErrors,
    required this.status,
  });

  factory FeatureHealth.fromJson(Map<String, dynamic> json) => FeatureHealth(
        key: json['key'] as String,
        label: json['label'] as String,
        recentActivity: json['recentActivity'] as int,
        recentErrors: json['recentErrors'] as int,
        status: json['status'] as String,
      );
}

class AdminErrorLog {
  final String id;
  final String method;
  final String path;
  final int statusCode;
  final String message;
  final String? userId;
  final DateTime createdAt;

  AdminErrorLog({
    required this.id,
    required this.method,
    required this.path,
    required this.statusCode,
    required this.message,
    this.userId,
    required this.createdAt,
  });

  factory AdminErrorLog.fromJson(Map<String, dynamic> json) => AdminErrorLog(
        id: json['id'] as String,
        method: json['method'] as String,
        path: json['path'] as String,
        statusCode: json['statusCode'] as int,
        message: json['message'] as String,
        userId: json['userId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class AdminErrorLogPage {
  final List<AdminErrorLog> items;
  final int total;
  final int page;
  final int pageSize;

  AdminErrorLogPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < total;

  factory AdminErrorLogPage.fromJson(Map<String, dynamic> json) => AdminErrorLogPage(
        items: (json['items'] as List)
            .map((e) => AdminErrorLog.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
      );
}

class AdminFeedbackItem {
  final String id;
  final String category;
  final int? rating;
  final String message;
  final String status;
  final DateTime createdAt;
  final AppUser? user;

  AdminFeedbackItem({
    required this.id,
    required this.category,
    this.rating,
    required this.message,
    required this.status,
    required this.createdAt,
    this.user,
  });

  factory AdminFeedbackItem.fromJson(Map<String, dynamic> json) => AdminFeedbackItem(
        id: json['id'] as String,
        category: json['category'] as String,
        rating: json['rating'] as int?,
        message: json['message'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        user: json['user'] != null ? AppUser.fromJson(json['user'] as Map<String, dynamic>) : null,
      );
}

class AdminFeedbackPage {
  final List<AdminFeedbackItem> items;
  final int total;
  final int page;
  final int pageSize;

  AdminFeedbackPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < total;

  factory AdminFeedbackPage.fromJson(Map<String, dynamic> json) => AdminFeedbackPage(
        items: (json['items'] as List)
            .map((e) => AdminFeedbackItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
      );
}

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

class AdminPayoutItem {
  final String id;
  final int amountCoins;
  final int amountInPaise;
  final String payeeName;
  final String? upiId;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String status;
  final String? adminNote;
  final DateTime createdAt;
  final AppUser? user;

  AdminPayoutItem({
    required this.id,
    required this.amountCoins,
    required this.amountInPaise,
    required this.payeeName,
    this.upiId,
    this.bankAccountNumber,
    this.bankIfsc,
    required this.status,
    this.adminNote,
    required this.createdAt,
    this.user,
  });

  factory AdminPayoutItem.fromJson(Map<String, dynamic> json) => AdminPayoutItem(
        id: json['id'] as String,
        amountCoins: json['amountCoins'] as int,
        amountInPaise: json['amountInPaise'] as int,
        payeeName: json['payeeName'] as String,
        upiId: json['upiId'] as String?,
        bankAccountNumber: json['bankAccountNumber'] as String?,
        bankIfsc: json['bankIfsc'] as String?,
        status: json['status'] as String,
        adminNote: json['adminNote'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        user: json['user'] != null ? AppUser.fromJson(json['user'] as Map<String, dynamic>) : null,
      );
}

class AdminPayoutPage {
  final List<AdminPayoutItem> items;
  final int total;
  final int page;
  final int pageSize;

  AdminPayoutPage({required this.items, required this.total, required this.page, required this.pageSize});

  bool get hasMore => page * pageSize < total;

  factory AdminPayoutPage.fromJson(Map<String, dynamic> json) => AdminPayoutPage(
        items: (json['items'] as List)
            .map((e) => AdminPayoutItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
      );
}
