class FollowStats {
  final int followerCount;
  final int followingCount;
  final bool? isFollowing;

  FollowStats({required this.followerCount, required this.followingCount, this.isFollowing});

  factory FollowStats.fromJson(Map<String, dynamic> json) => FollowStats(
        followerCount: json['followerCount'] as int,
        followingCount: json['followingCount'] as int,
        isFollowing: json['isFollowing'] as bool?,
      );
}
