import 'package:geolocator/geolocator.dart';

class ProviderLocationService {
  Future<Position> getCurrentPosition() async {
    await _ensureLocationAvailable();

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Stream<Position> watchPosition() async* {
    await _ensureLocationAvailable();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );

    yield* Geolocator.getPositionStream(
      locationSettings: settings,
    );
  }

  Future<void> _ensureLocationAvailable() async {
    final serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw StateError(
        'Location services are disabled. '
            'Please enable location services and try again.',
      );
    }

    var permission =
    await Geolocator.checkPermission();

    if (permission ==
        LocationPermission.denied) {
      permission =
      await Geolocator.requestPermission();
    }

    if (permission ==
        LocationPermission.denied) {
      throw StateError(
        'Location permission was denied.',
      );
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw StateError(
        'Location permission is permanently denied. '
            'Please enable it from the device settings.',
      );
    }
  }
}