import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../models/area_post.dart';
import '../area/area_post_kind_ui.dart';
import '../area/area_repository.dart';

/// Secondary, opt-in view of the area feed as a map - reached via a button
/// from [HomeFeedScreen], which is the primary post-login screen. Kept
/// separate since a real map full of Google's own place icons makes it easy
/// to miss your own app's pins otherwise.
class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen> {
  bool _loading = true;
  String? _error;
  List<AreaPost> _posts = [];
  AreaPostKind? _filter;

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
      final posts = await ref.read(areaRepositoryProvider).listNearby(
            lat: user!.latitude!,
            lng: user.longitude!,
            kind: _filter,
          );
      setState(() => _posts = posts);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).value?.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby on map')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _filter == null,
                    onSelected: (_) {
                      setState(() => _filter = null);
                      _load();
                    },
                  ),
                  const SizedBox(width: 8),
                  ...allAreaPostKinds.map(
                    (kind) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(areaPostKindIcon(kind), size: 18),
                        label: Text(areaPostKindLabel(kind)),
                        selected: _filter == kind,
                        onSelected: (_) {
                          setState(() => _filter = kind);
                          _load();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: user?.latitude == null || user?.longitude == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'We don\'t have exact coordinates for your area yet. '
                        'Use "Use my current location" from your profile setup, '
                        'or just keep browsing - posts are still visible by area name '
                        'from the feed.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(user!.latitude!, user.longitude!),
                              zoom: 14,
                            ),
                            myLocationButtonEnabled: false,
                            markers: _posts
                                .where((post) => post.latitude != null && post.longitude != null)
                                .map(
                                  (post) => Marker(
                                    markerId: MarkerId(post.id),
                                    position: LatLng(post.latitude!, post.longitude!),
                                    infoWindow: InfoWindow(
                                      title: post.title,
                                      snippet: areaPostKindLabel(post.kind),
                                      onTap: () => context.push('/home/posts/${post.id}'),
                                    ),
                                  ),
                                )
                                .toSet(),
                          ),
          ),
        ],
      ),
    );
  }
}
