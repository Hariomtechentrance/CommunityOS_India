import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../models/area_post.dart';
import '../../models/nearby_place.dart';
import '../area/area_repository.dart';
import 'places_repository.dart';

const _categories = ['All', 'Cafes', 'Stores', 'Medical', 'Salons'];

/// Business-discovery map for the Explore tab - blends two pin sources:
/// real nearby businesses from Google Places (violet-ish default markers)
/// and this app's own user-posted Shop listings (a distinct hue, tappable
/// through to the post detail screen) - mirrors HomeMapScreen's pattern for
/// area posts generally, scoped here to shops specifically.
class ExploreMapScreen extends ConsumerStatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  ConsumerState<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends ConsumerState<ExploreMapScreen> {
  bool _loading = true;
  String? _error;
  List<NearbyPlace> _places = [];
  List<AreaPost> _shopPosts = [];
  String _category = 'All';

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
      final results = await Future.wait([
        ref.read(placesRepositoryProvider).nearby(
              lat: user!.latitude!,
              lng: user.longitude!,
              category: _category,
            ),
        ref.read(areaRepositoryProvider).listNearby(
              lat: user.latitude!,
              lng: user.longitude!,
              kind: AreaPostKind.shop,
            ),
      ]);
      setState(() {
        _places = results[0] as List<NearbyPlace>;
        _shopPosts = results[1] as List<AreaPost>;
      });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).value?.user;

    final placeMarkers = _places.map(
      (place) => Marker(
        markerId: MarkerId('place-${place.id}'),
        position: LatLng(place.latitude, place.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: [
            if (place.rating != null) '★ ${place.rating!.toStringAsFixed(1)}',
            if (place.address != null) place.address!,
          ].join(' · '),
        ),
      ),
    );
    final shopMarkers = _shopPosts
        .where((post) => post.latitude != null && post.longitude != null)
        .map(
          (post) => Marker(
            markerId: MarkerId('shop-${post.id}'),
            position: LatLng(post.latitude!, post.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            infoWindow: InfoWindow(
              title: post.title,
              snippet: post.businessCategory ?? 'Shop',
              onTap: () => context.push('/home/posts/${post.id}'),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby businesses on map')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories
                    .map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          onSelected: (_) {
                            setState(() => _category = category);
                            _load();
                          },
                        ),
                      ),
                    )
                    .toList(),
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
                        'Use "Use my current location" from your profile setup.',
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
                              zoom: 15,
                            ),
                            myLocationButtonEnabled: false,
                            markers: {...placeMarkers, ...shopMarkers},
                          ),
          ),
        ],
      ),
    );
  }
}
