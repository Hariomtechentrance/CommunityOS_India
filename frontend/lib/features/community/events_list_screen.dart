import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../core/widgets/max_width_box.dart';
import '../../models/event.dart';
import 'create_event_screen.dart';
import 'event_repository.dart';

class EventsListScreen extends ConsumerStatefulWidget {
  const EventsListScreen({super.key});

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> {
  bool _loading = true;
  String? _error;
  List<CommunityEvent> _events = [];

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
      final events = await ref.read(eventRepositoryProvider).list(societyId);
      setState(() => _events = events);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateEventScreen()),
          );
          if (created == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('New event'),
      ),
      body: MaxWidthBox(
        child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _events.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No events yet.'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              onTap: () =>
                                  context.push('/home/society/community/events/${event.id}'),
                              title: Text(event.title),
                              subtitle: Text(
                                '${event.startAt.toLocal()}\n${event.location}',
                              ),
                              isThreeLine: true,
                              trailing: Text('${event.countFor(RsvpStatus.going)} going'),
                            ),
                          );
                        },
                      ),
        ),
      ),
    );
  }
}
