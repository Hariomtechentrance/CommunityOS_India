import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'user_repository.dart';

/// Best-effort travel-feed signal (see LocationVisit in the backend schema) -
/// silently does nothing on denied permission, disabled location services,
/// or any network failure. Never blocks or surfaces errors to the user, same
/// spirit as push token registration.
Future<void> recordLocationVisitBestEffort(UserRepository userRepository) async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    await userRepository.recordLocationVisit(lat: position.latitude, lng: position.longitude);
  } catch (e) {
    debugPrint('[location-visit] failed: $e');
  }
}

/// Fires at most once per signed-in user per app process - checking on every
/// cold start/login is enough resolution for an 8-day-window feed feature,
/// so this deliberately doesn't hook into app-foreground/resume beyond that.
String? _lastFiredForUserId;

void recordLocationVisitOncePerLogin(String userId, UserRepository userRepository) {
  if (_lastFiredForUserId == userId) return;
  _lastFiredForUserId = userId;
  recordLocationVisitBestEffort(userRepository);
}
