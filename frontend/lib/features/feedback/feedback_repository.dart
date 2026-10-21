import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

enum FeedbackCategory { bug, suggestion, review, other }

extension FeedbackCategoryApi on FeedbackCategory {
  /// Matches the backend's FeedbackCategory enum (prisma/schema.prisma) exactly.
  String get apiValue => switch (this) {
        FeedbackCategory.bug => 'BUG',
        FeedbackCategory.suggestion => 'SUGGESTION',
        FeedbackCategory.review => 'REVIEW',
        FeedbackCategory.other => 'OTHER',
      };

  String get label => switch (this) {
        FeedbackCategory.bug => 'Report a bug',
        FeedbackCategory.suggestion => 'Suggest a feature',
        FeedbackCategory.review => 'Leave a review',
        FeedbackCategory.other => 'Something else',
      };
}

class FeedbackRepository {
  final ApiClient _client;

  FeedbackRepository(this._client);

  Future<void> submit(FeedbackCategory category, String message, {int? rating}) async {
    await _client.dio.post('/feedback', data: {
      'category': category.apiValue,
      'message': message,
      if (rating != null) 'rating': rating,
    });
  }
}

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => FeedbackRepository(ref.read(apiClientProvider)),
);
