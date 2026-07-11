import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/event.dart';
import 'event_repository.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _loading = true;
  String? _error;
  CommunityEvent? _event;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final societyId = ref.read(sessionControllerProvider).value?.society?.id;
    if (societyId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final event = await ref.read(eventRepositoryProvider).getById(societyId, widget.eventId);
      setState(() => _event = event);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rsvp(RsvpStatus status) async {
    final societyId = ref.read(sessionControllerProvider).value?.society?.id;
    if (societyId == null) return;
    try {
      await ref.read(eventRepositoryProvider).rsvp(societyId, widget.eventId, status);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(sessionControllerProvider).value?.user?.id;
    final myStatus = userId != null ? _event?.myStatus(userId) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Event')),
      body: MaxWidthBox(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _event == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(_event!.title, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(_event!.description),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 18),
                            const SizedBox(width: 4),
                            Expanded(child: Text(_event!.location)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 18),
                            const SizedBox(width: 4),
                            Expanded(child: Text(_event!.startAt.toLocal().toString())),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text('Your RSVP', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: RsvpStatus.values
                              .map(
                                (status) => ChoiceChip(
                                  label: Text(rsvpStatusLabel(status)),
                                  selected: myStatus == status,
                                  onSelected: (_) => _rsvp(status),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '${_event!.countFor(RsvpStatus.going)} going · '
                          '${_event!.countFor(RsvpStatus.maybe)} maybe · '
                          '${_event!.countFor(RsvpStatus.notGoing)} not going',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
      ),
    );
  }
}
