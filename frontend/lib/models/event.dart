import 'user.dart';

enum RsvpStatus { going, maybe, notGoing }

RsvpStatus rsvpStatusFromJson(String value) {
  switch (value) {
    case 'GOING':
      return RsvpStatus.going;
    case 'MAYBE':
      return RsvpStatus.maybe;
    default:
      return RsvpStatus.notGoing;
  }
}

String rsvpStatusToJson(RsvpStatus status) {
  switch (status) {
    case RsvpStatus.going:
      return 'GOING';
    case RsvpStatus.maybe:
      return 'MAYBE';
    case RsvpStatus.notGoing:
      return 'NOT_GOING';
  }
}

String rsvpStatusLabel(RsvpStatus status) {
  switch (status) {
    case RsvpStatus.going:
      return 'Going';
    case RsvpStatus.maybe:
      return 'Maybe';
    case RsvpStatus.notGoing:
      return 'Not going';
  }
}

class EventRsvp {
  final String id;
  final RsvpStatus status;
  final AppUser? user;

  EventRsvp({required this.id, required this.status, this.user});

  factory EventRsvp.fromJson(Map<String, dynamic> json) => EventRsvp(
        id: json['id'] as String,
        status: rsvpStatusFromJson(json['status'] as String),
        user:
            json['user'] != null ? AppUser.fromJson(json['user'] as Map<String, dynamic>) : null,
      );
}

class CommunityEvent {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startAt;
  final AppUser? author;
  final List<EventRsvp> rsvps;

  CommunityEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startAt,
    this.author,
    this.rsvps = const [],
  });

  int countFor(RsvpStatus status) => rsvps.where((r) => r.status == status).length;

  RsvpStatus? myStatus(String userId) {
    for (final rsvp in rsvps) {
      if (rsvp.user?.id == userId) return rsvp.status;
    }
    return null;
  }

  factory CommunityEvent.fromJson(Map<String, dynamic> json) => CommunityEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        location: json['location'] as String,
        startAt: DateTime.parse(json['startAt'] as String),
        author: json['author'] != null
            ? AppUser.fromJson(json['author'] as Map<String, dynamic>)
            : null,
        rsvps: json['rsvps'] != null
            ? (json['rsvps'] as List)
                .map((e) => EventRsvp.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
      );
}
