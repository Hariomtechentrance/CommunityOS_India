import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/area_post.dart';

Future<void> shareAreaPost(AreaPost post) {
  return SharePlus.instance.share(
    ShareParams(text: '${post.title}\n\n${post.description}', subject: post.title),
  );
}

IconData areaPostKindIcon(AreaPostKind kind) {
  switch (kind) {
    case AreaPostKind.shop:
      return Icons.storefront;
    case AreaPostKind.sportsInvite:
      return Icons.sports;
    case AreaPostKind.helpRequest:
      return Icons.volunteer_activism;
    case AreaPostKind.socialEvent:
      return Icons.celebration;
    case AreaPostKind.safetyAlert:
      return Icons.warning_amber;
    case AreaPostKind.serviceRequest:
      return Icons.home_repair_service;
    case AreaPostKind.emergencySos:
      return Icons.emergency;
    case AreaPostKind.update:
      return Icons.article;
  }
}
