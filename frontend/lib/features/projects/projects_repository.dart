import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../models/project.dart';

class ProjectsRepository {
  final ApiClient _client;

  ProjectsRepository(this._client);

  Future<Project> create({
    required String name,
    required String description,
    String? category,
  }) async {
    final res = await _client.dio.post('/projects', data: {
      'name': name,
      'description': description,
      if (category != null && category.isNotEmpty) 'category': category,
    });
    return Project.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Project>> listForUser(String userId) async {
    final res = await _client.dio.get('/users/$userId/projects');
    return (res.data as List).map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Project> getById(String id) async {
    final res = await _client.dio.get('/projects/$id');
    return Project.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ProjectUpdate> addUpdate(String projectId, {int? dayNumber, required String body}) async {
    final res = await _client.dio.post('/projects/$projectId/updates', data: {
      if (dayNumber != null) 'dayNumber': dayNumber,
      'body': body,
    });
    return ProjectUpdate.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) {
    return _client.dio.delete('/projects/$id');
  }
}

final projectsRepositoryProvider = Provider<ProjectsRepository>(
  (ref) => ProjectsRepository(ref.read(apiClientProvider)),
);
