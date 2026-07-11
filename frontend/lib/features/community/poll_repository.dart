import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/poll.dart';

class PollRepository {
  final ApiClient _client;

  PollRepository(this._client);

  Future<List<Poll>> list(String societyId) async {
    final res = await _client.dio.get('/societies/$societyId/polls');
    return (res.data as List).map((e) => Poll.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Poll> create(String societyId, {required String question, required List<String> options}) async {
    final res = await _client.dio.post(
      '/societies/$societyId/polls',
      data: {'question': question, 'options': options},
    );
    return Poll.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> vote(String societyId, String pollId, String optionId) {
    return _client.dio.post(
      '/societies/$societyId/polls/$pollId/vote',
      data: {'optionId': optionId},
    );
  }
}

final pollRepositoryProvider = Provider<PollRepository>(
  (ref) => PollRepository(ref.read(apiClientProvider)),
);
