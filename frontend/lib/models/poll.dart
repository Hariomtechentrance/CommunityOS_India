import 'user.dart';

class PollOption {
  final String id;
  final String label;
  final int voteCount;

  PollOption({required this.id, required this.label, required this.voteCount});

  factory PollOption.fromJson(Map<String, dynamic> json) => PollOption(
        id: json['id'] as String,
        label: json['label'] as String,
        voteCount: json['_count'] != null
            ? (json['_count'] as Map<String, dynamic>)['votes'] as int? ?? 0
            : 0,
      );
}

class Poll {
  final String id;
  final String question;
  final DateTime createdAt;
  final AppUser? author;
  final List<PollOption> options;
  final String? myVoteOptionId;

  Poll({
    required this.id,
    required this.question,
    required this.createdAt,
    this.author,
    required this.options,
    this.myVoteOptionId,
  });

  int get totalVotes => options.fold(0, (sum, o) => sum + o.voteCount);

  factory Poll.fromJson(Map<String, dynamic> json) => Poll(
        id: json['id'] as String,
        question: json['question'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        author: json['author'] != null
            ? AppUser.fromJson(json['author'] as Map<String, dynamic>)
            : null,
        options: (json['options'] as List)
            .map((e) => PollOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        myVoteOptionId: json['myVoteOptionId'] as String?,
      );
}
