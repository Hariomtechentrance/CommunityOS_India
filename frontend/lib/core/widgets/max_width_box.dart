import 'package:flutter/material.dart';

/// Centers [child] and caps its width, so list/feed/detail content reads
/// well on a wide desktop browser window instead of stretching edge-to-edge.
/// Feed/dashboard-style content defaults to a slightly wider cap than forms.
class MaxWidthBox extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const MaxWidthBox({super.key, this.maxWidth = 640, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
