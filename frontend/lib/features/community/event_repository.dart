import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/event.dart';

class EventRepository {
  final ApiClient _client;

  EventRepository(this._client);

  Future<List<CommunityEvent>> list(String societyId) async {
    final res = await _client.dio.get('/societies/$societyId/events');
    return (res.data as List)
        .map((e) => CommunityEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommunityEvent> create(
    String societyId, {
    required String title,
    required String description,
    required String location,
    required DateTime startAt,
  }) async {
    final res = await _client.dio.post(
      '/societies/$societyId/events',
      data: {
        'title': title,
        'description': description,
        'location': location,
        'startAt': startAt.toUtc().toIso8601String(),
      },
    );
    return CommunityEvent.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CommunityEvent> getById(String societyId, String eventId) async {
    final res = await _client.dio.get('/societies/$societyId/events/$eventId');
    return CommunityEvent.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> rsvp(String societyId, String eventId, RsvpStatus status) {
    return _client.dio.post(
      '/societies/$societyId/events/$eventId/rsvp',
      data: {'status': rsvpStatusToJson(status)},
    );
  }
}

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.read(apiClientProvider)),
);
