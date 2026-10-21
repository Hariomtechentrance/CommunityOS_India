import 'user.dart';

class GoalCommunity {
  final String id;
  final String title;
  final String description;
  final String? category;
  final int durationDays;
  final DateTime createdAt;
  final AppUser? createdBy;
  final int memberCount;
  final bool joined;
  final int? myStreak;
  final int? myLongestStreak;
  final bool checkedInToday;
  final int joinCostCoins;

  GoalCommunity({
    required this.id,
    required this.title,
    required this.description,
    this.category,
    required this.durationDays,
    required this.createdAt,
    this.createdBy,
    this.memberCount = 0,
    this.joined = false,
    this.myStreak,
    this.myLongestStreak,
    this.checkedInToday = false,
    this.joinCostCoins = 0,
  });

  factory GoalCommunity.fromJson(Map<String, dynamic> json) => GoalCommunity(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: json['category'] as String?,
        durationDays: json['durationDays'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        createdBy: json['createdBy'] != null
            ? AppUser.fromJson(json['createdBy'] as Map<String, dynamic>)
            : null,
        memberCount: json['_count'] != null
            ? (json['_count'] as Map<String, dynamic>)['members'] as int? ?? 0
            : 0,
        joined: json['joined'] as bool? ?? false,
        myStreak: json['myStreak'] as int?,
        myLongestStreak: json['myLongestStreak'] as int?,
        checkedInToday: json['checkedInToday'] as bool? ?? false,
        joinCostCoins: json['joinCostCoins'] as int? ?? 0,
      );
}

class GoalLeaderboardEntry {
  final AppUser user;
  final int currentStreak;
  final int longestStreak;

  GoalLeaderboardEntry({
    required this.user,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory GoalLeaderboardEntry.fromJson(Map<String, dynamic> json) => GoalLeaderboardEntry(
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
        currentStreak: json['currentStreak'] as int,
        longestStreak: json['longestStreak'] as int,
      );
}
