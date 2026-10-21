import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/society.dart';

class SocietyRepository {
  final ApiClient _client;

  SocietyRepository(this._client);

  Future<List<Society>> search({String? query, String? pincode, SocietyType? type}) async {
    final res = await _client.dio.get(
      '/societies',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
        if (type != null) 'type': societyTypeToJson(type),
      },
    );
    return (res.data as List)
        .map((e) => Society.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Society> getById(String id) async {
    final res = await _client.dio.get('/societies/$id');
    return Society.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Society> create({
    required String name,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
    SocietyType type = SocietyType.apartment,
    String? emailDomain,
  }) async {
    final res = await _client.dio.post(
      '/societies',
      data: {
        'name': name,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'pincode': pincode,
        'type': societyTypeToJson(type),
        if (emailDomain != null && emailDomain.isNotEmpty) 'emailDomain': emailDomain,
      },
    );
    return Society.fromJson(res.data as Map<String, dynamic>);
  }
}

final societyRepositoryProvider = Provider<SocietyRepository>(
  (ref) => SocietyRepository(ref.read(apiClientProvider)),
);
