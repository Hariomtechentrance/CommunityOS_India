import 'user.dart';

enum StoryMediaType { image, video }

StoryMediaType storyMediaTypeFromJson(String value) =>
    value == 'VIDEO' ? StoryMediaType.video : StoryMediaType.image;

String storyMediaTypeToJson(StoryMediaType type) =>
    type == StoryMediaType.video ? 'VIDEO' : 'IMAGE';

class Story {
  final String id;
  final String mediaUrl;
  final StoryMediaType mediaType;
  final String? audioUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final AppUser? user;
  final bool seenByMe;

  Story({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    this.audioUrl,
    required this.createdAt,
    required this.expiresAt,
    this.user,
    this.seenByMe = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        id: json['id'] as String,
        mediaUrl: json['mediaUrl'] as String,
        mediaType: storyMediaTypeFromJson(json['mediaType'] as String),
        audioUrl: json['audioUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        user: json['user'] != null
            ? AppUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        seenByMe: json['seenByMe'] as bool? ?? false,
      );
}

/// One author's stories, newest first, plus whether any of them are unseen -
/// drives the colored-vs-grey ring in the stories bar.
class StoryGroup {
  final AppUser author;
  final List<Story> stories;

  StoryGroup({required this.author, required this.stories});

  bool get hasUnseen => stories.any((s) => !s.seenByMe);
}

List<StoryGroup> groupStoriesByAuthor(List<Story> stories) {
  final byAuthor = <String, List<Story>>{};
  final authors = <String, AppUser>{};
  for (final story in stories) {
    final author = story.user;
    if (author == null) continue;
    byAuthor.putIfAbsent(author.id, () => []).add(story);
    authors[author.id] = author;
  }
  return byAuthor.entries
      .map((e) => StoryGroup(author: authors[e.key]!, stories: e.value))
      .toList();
}
