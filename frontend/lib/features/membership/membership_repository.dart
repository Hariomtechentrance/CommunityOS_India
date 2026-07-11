import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/membership.dart';

class MembershipRepository {
  final ApiClient _client;

  MembershipRepository(this._client);

  Future<Membership?> findMine(String societyId) async {
    final res = await _client.dio.get('/societies/$societyId/memberships/me');
    if (res.data == null) return null;
    return Membership.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Membership> requestToJoin(
    String societyId, {
    String? unitNumber,
    String? blockName,
  }) async {
    final res = await _client.dio.post(
      '/societies/$societyId/memberships',
      data: {
        if (unitNumber != null && unitNumber.isNotEmpty) 'unitNumber': unitNumber,
        if (blockName != null && blockName.isNotEmpty) 'blockName': blockName,
      },
    );
    return Membership.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Membership>> listForSociety(String societyId, {MembershipStatus? status}) async {
    final res = await _client.dio.get(
      '/societies/$societyId/memberships',
      queryParameters: {
        if (status != null) 'status': _statusToJson(status),
      },
    );
    return (res.data as List)
        .map((e) => Membership.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateStatus(String societyId, String membershipId, MembershipStatus status) {
    return _client.dio.patch(
      '/societies/$societyId/memberships/$membershipId',
      data: {'status': _statusToJson(status)},
    );
  }

  String _statusToJson(MembershipStatus status) {
    switch (status) {
      case MembershipStatus.approved:
        return 'APPROVED';
      case MembershipStatus.rejected:
        return 'REJECTED';
      case MembershipStatus.pending:
        return 'PENDING';
    }
  }
}

final membershipRepositoryProvider = Provider<MembershipRepository>(
  (ref) => MembershipRepository(ref.read(apiClientProvider)),
);
