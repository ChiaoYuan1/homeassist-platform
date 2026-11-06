import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final String address;
  final double latitude;
  final double longitude;

  const LocationResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  final Geocoding _geocoding = Geocoding();

  Future<LocationResult> geocodeAddress(
      String address,
      ) async {
    final locations = await _geocoding.locationFromAddress(
      address,
    );

    if (locations.isEmpty) {
      throw StateError(
        'Unable to locate that address.',
      );
    }

    final location = locations.first;

    return LocationResult(
      address: address,
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }

  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw StateError(
        'Location services are disabled.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission was not granted.',
      );
    }

    final position = await Geolocator.getCurrentPosition();

    var address =
        '${position.latitude}, ${position.longitude}';

    final placemarks =
    await _geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final placemark = placemarks.first;

      address = [
        placemark.street,
        placemark.subLocality,
        placemark.locality,
        placemark.administrativeArea,
        placemark.postalCode,
      ]
          .where(
            (value) =>
        value != null &&
            value.trim().isNotEmpty,
      )
          .join(', ');
    }

    return LocationResult(
      address: address,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  double calculateDistanceKm({
    required double customerLatitude,
    required double customerLongitude,
    required double providerLatitude,
    required double providerLongitude,
  }) {
    final distanceInMeters =
    Geolocator.distanceBetween(
      customerLatitude,
      customerLongitude,
      providerLatitude,
      providerLongitude,
    );

    return distanceInMeters / 1000;
  }
}