import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// The result of asking for the phone's position: either the position, or
/// why it is not available.
sealed class LocationResult {
  const LocationResult();
}

/// The phone's position was found.
class LocationFound extends LocationResult {
  const LocationFound(this.position);

  final LatLng position;
}

/// The position could not be found, e.g. location is off or permission was
/// refused.
class LocationUnavailable extends LocationResult {
  const LocationUnavailable(this.reason);

  /// A message that can be shown to the user.
  final String reason;
}

/// Finds the phone's current position, asking for permission the first time.
abstract interface class LocationService {
  /// @return the position, or why it is not available
  Future<LocationResult> currentPosition();
}

/// [LocationService] backed by the phone's location services.
class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Future<LocationResult> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationUnavailable('Location is turned off on this phone.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      return const LocationUnavailable('Location permission was not given.');
    }
    try {
      // Android's own location manager, rather than Google Play services,
      // which asks users to share sensor and wireless data with Google.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15),
          forceLocationManager: true,
        ),
      );
      return LocationFound(LatLng(position.latitude, position.longitude));
    } on Exception {
      // No fresh fix in time, e.g. under tree cover: the phone's last known
      // position is usually close enough to find nearby trails.
      final last = await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: true,
      );
      if (last != null) {
        return LocationFound(LatLng(last.latitude, last.longitude));
      }
      return const LocationUnavailable('Could not find your location.');
    }
  }
}
