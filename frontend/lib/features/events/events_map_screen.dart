import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../models/area_post.dart';
import '../area/area_repository.dart';

/// "Events around you" map - reuses AreaPost's existing nearby-radius query
/// scoped to SOCIAL_EVENT, same pattern as ExploreMapScreen (shops). A
/// dedicated screen rather than another category filter on that one, since
/// events deserve their own entry point per the product brief.
class EventsMapScreen extends ConsumerStatefulWidget {
  const EventsMapScreen({super.key});

  @override
  ConsumerState<EventsMapScreen> createState() => _EventsMapScreenState();
}

class _EventsMapScreenState extends ConsumerState<EventsMapScreen> {
  bool _loading = true;
  String? _error;
  List<AreaPost> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(sessionControllerProvider).value?.user;
    if (user?.latitude == null || user?.longitude == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await ref.read(areaRepositoryProvider).listNearby(
            lat: user!.latitude!,
            lng: user.longitude!,
            kind: AreaPostKind.socialEvent,
          );
      setState(() => _events = events);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).value?.user;

    final markers = _events
        .where((e) => e.latitude != null && e.longitude != null)
        .map(
          (e) => Marker(
            markerId: MarkerId(e.id),
            position: LatLng(e.latitude!, e.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: e.title,
              snippet: e.activityTime ?? 'Tap to view',
              onTap: () => context.push('/home/posts/${e.id}'),
            ),
          ),
        )
        .toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Events around you')),
      body: user?.latitude == null || user?.longitude == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'We don\'t have exact coordinates for your area yet. '
                  'Use "Use my current location" from your profile setup.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _events.isEmpty
                      ? const Center(child: Text('No events nearby right now.'))
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(user!.latitude!, user.longitude!),
                            zoom: 13,
                          ),
                          myLocationButtonEnabled: false,
                          markers: markers,
                        ),
    );
  }
}
