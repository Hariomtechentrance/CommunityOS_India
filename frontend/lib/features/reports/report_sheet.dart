import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'reports_repository.dart';

/// Reason-picker bottom sheet shared by both "report a user" and "report a
/// post" flows - exactly one of [userId]/[postId] is passed by the caller.
/// Shows its own success/error snackbar, so callers just fire-and-forget.
Future<void> showReportSheet(
  BuildContext context,
  WidgetRef ref, {
  String? userId,
  String? postId,
}) async {
  assert((userId == null) != (postId == null), 'Pass exactly one of userId/postId');

  final reason = await showModalBottomSheet<ReportReason>(
    context: context,
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          for (final r in ReportReason.values)
            ListTile(
              title: Text(r.label),
              onTap: () => Navigator.of(context).pop(r),
            ),
        ],
      ),
    ),
  );
  if (reason == null || !context.mounted) return;

  try {
    final repo = ref.read(reportsRepositoryProvider);
    if (userId != null) {
      await repo.reportUser(userId, reason);
    } else {
      await repo.reportPost(postId!, reason);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks for letting us know. We\'ll review this.')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
  }
}
