import 'user.dart';

class ProjectUpdate {
  final String id;
  final int? dayNumber;
  final String body;
  final String? imageUrl;
  final DateTime createdAt;

  ProjectUpdate({
    required this.id,
    this.dayNumber,
    required this.body,
    this.imageUrl,
    required this.createdAt,
  });

  factory ProjectUpdate.fromJson(Map<String, dynamic> json) => ProjectUpdate(
        id: json['id'] as String,
        dayNumber: json['dayNumber'] as int?,
        body: json['body'] as String,
        imageUrl: json['imageUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class Project {
  final String id;
  final String name;
  final String description;
  final String? category;
  final DateTime createdAt;
  final AppUser? user;
  final int updateCount;
  final List<ProjectUpdate>? updates;

  Project({
    required this.id,
    required this.name,
    required this.description,
    this.category,
    required this.createdAt,
    this.user,
    this.updateCount = 0,
    this.updates,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        category: json['category'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        user: json['user'] != null
            ? AppUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        updateCount: json['_count'] != null
            ? (json['_count'] as Map<String, dynamic>)['updates'] as int? ?? 0
            : 0,
        updates: json['updates'] != null
            ? (json['updates'] as List)
                .map((e) => ProjectUpdate.fromJson(e as Map<String, dynamic>))
                .toList()
            : null,
      );
}
