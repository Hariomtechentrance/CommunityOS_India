import 'package:flutter/material.dart';

/// Renders a user's avatar image when set, falling back to a generic person
/// icon otherwise - the single place this logic should live so every screen
/// showing another user's avatar (neighbours, story circles, chat threads,
/// interested-users lists, etc.) stays consistent.
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;

  const UserAvatar({super.key, this.avatarUrl, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    if (url == null || url.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Icon(Icons.person, size: radius),
      );
    }
    return CircleAvatar(radius: radius, backgroundImage: NetworkImage(url));
  }
}
