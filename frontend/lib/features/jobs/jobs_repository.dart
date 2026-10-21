import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/job.dart';

class JobsRepository {
  final ApiClient _client;

  JobsRepository(this._client);

  Future<List<JobPosting>> listForArea(String area, {JobType? jobType}) async {
    final res = await _client.dio.get('/jobs', queryParameters: {
      'area': area,
      if (jobType != null) 'jobType': jobTypeToJson(jobType),
    });
    return (res.data as List).map((e) => JobPosting.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<JobPosting>> listMine() async {
    final res = await _client.dio.get('/jobs/mine');
    return (res.data as List).map((e) => JobPosting.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<JobPosting> findOne(String id) async {
    final res = await _client.dio.get('/jobs/$id');
    return JobPosting.fromJson(res.data as Map<String, dynamic>);
  }

  Future<JobPosting> create({
    required String area,
    String? pincode,
    required String title,
    required String description,
    String? companyName,
    required JobType jobType,
    int? salaryMin,
    int? salaryMax,
    String? salaryPeriod,
    String? location,
    String? contactPhone,
  }) async {
    final res = await _client.dio.post('/jobs', data: {
      'area': area,
      if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
      'title': title,
      'description': description,
      if (companyName != null && companyName.isNotEmpty) 'companyName': companyName,
      'jobType': jobTypeToJson(jobType),
      if (salaryMin != null) 'salaryMin': salaryMin,
      if (salaryMax != null) 'salaryMax': salaryMax,
      if (salaryPeriod != null && salaryPeriod.isNotEmpty) 'salaryPeriod': salaryPeriod,
      if (location != null && location.isNotEmpty) 'location': location,
      if (contactPhone != null && contactPhone.isNotEmpty) 'contactPhone': contactPhone,
    });
    return JobPosting.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> setStatus(String id, String status) {
    return _client.dio.patch('/jobs/$id/status', data: {'status': status});
  }

  Future<void> remove(String id) {
    return _client.dio.delete('/jobs/$id');
  }

  Future<void> apply(String id, {String? message}) {
    return _client.dio.post('/jobs/$id/apply', data: {
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  Future<List<JobApplication>> listApplications(String id) async {
    final res = await _client.dio.get('/jobs/$id/applications');
    return (res.data as List).map((e) => JobApplication.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateApplicationStatus(String jobId, String applicationId, String status) {
    return _client.dio
        .patch('/jobs/$jobId/applications/$applicationId/status', data: {'status': status});
  }

  Future<List<JobApplication>> listMyApplications() async {
    final res = await _client.dio.get('/jobs/my-applications');
    return (res.data as List).map((e) => JobApplication.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final jobsRepositoryProvider = Provider<JobsRepository>(
  (ref) => JobsRepository(ref.read(apiClientProvider)),
);
