import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/complaint.dart';

class ComplaintRepository {
  final ApiClient _client;

  ComplaintRepository(this._client);

  Future<List<Complaint>> list(String societyId) async {
    final res = await _client.dio.get('/societies/$societyId/complaints');
    return (res.data as List)
        .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Complaint> create(
    String societyId, {
    required String category,
    required String description,
  }) async {
    final res = await _client.dio.post(
      '/societies/$societyId/complaints',
      data: {'category': category, 'description': description},
    );
    return Complaint.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateStatus(String societyId, String complaintId, ComplaintStatus status) {
    return _client.dio.patch(
      '/societies/$societyId/complaints/$complaintId/status',
      data: {'status': complaintStatusToJson(status)},
    );
  }
}

final complaintRepositoryProvider = Provider<ComplaintRepository>(
  (ref) => ComplaintRepository(ref.read(apiClientProvider)),
);
