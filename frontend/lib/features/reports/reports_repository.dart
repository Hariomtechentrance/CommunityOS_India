import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

enum ReportReason { spam, harassment, inappropriateContent, fakeAccount, other }

extension ReportReasonApi on ReportReason {
  /// Matches the backend's ReportReason enum (prisma/schema.prisma) exactly.
  String get apiValue => switch (this) {
        ReportReason.spam => 'SPAM',
        ReportReason.harassment => 'HARASSMENT',
        ReportReason.inappropriateContent => 'INAPPROPRIATE_CONTENT',
        ReportReason.fakeAccount => 'FAKE_ACCOUNT',
        ReportReason.other => 'OTHER',
      };

  String get label => switch (this) {
        ReportReason.spam => 'Spam',
        ReportReason.harassment => 'Harassment or bullying',
        ReportReason.inappropriateContent => 'Inappropriate content',
        ReportReason.fakeAccount => 'Fake account',
        ReportReason.other => 'Something else',
      };
}

class ReportsRepository {
  final ApiClient _client;

  ReportsRepository(this._client);

  Future<void> reportUser(String userId, ReportReason reason, {String? details}) async {
    await _client.dio.post('/reports', data: {
      'userId': userId,
      'reason': reason.apiValue,
      if (details != null && details.isNotEmpty) 'details': details,
    });
  }

  Future<void> reportPost(String postId, ReportReason reason, {String? details}) async {
    await _client.dio.post('/reports', data: {
      'postId': postId,
      'reason': reason.apiValue,
      if (details != null && details.isNotEmpty) 'details': details,
    });
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.read(apiClientProvider)),
);
