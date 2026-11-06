import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/app_enums.dart';
import '../models/booking_model.dart';
import 'booking_service.dart';
import 'provider_location_service.dart';
import 'route_eta_service.dart';

class ProviderJourneyTrackingService {
  final ProviderLocationService locationService;
  final RouteEtaService routeEtaService;
  final BookingService bookingService;

  StreamSubscription<Position>? _positionSubscription;

  String? _activeBookingId;

  bool _processingUpdate = false;

  DateTime? _lastRouteUpdate;

  static const Duration _minimumUpdateInterval =
  Duration(
    seconds: 45,
  );

  ProviderJourneyTrackingService({
    required this.locationService,
    required this.routeEtaService,
    required this.bookingService,
  });

  bool get isTracking =>
      _positionSubscription != null;

  String? get activeBookingId =>
      _activeBookingId;


  // =====================================================
  // PREVIEW ROUTE WITHOUT STARTING JOURNEY
  // =====================================================

  Future<RouteEtaResult> previewRoute(
      BookingModel booking,
      ) async {
    final latitude = booking.latitude;
    final longitude = booking.longitude;

    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        (latitude == 0 && longitude == 0)) {
      throw StateError(
        'The customer location is invalid.',
      );
    }

    final position =
    await locationService.getCurrentPosition();

    return routeEtaService.getRouteEta(
      providerLatitude: position.latitude,
      providerLongitude: position.longitude,
      customerLatitude: latitude,
      customerLongitude: longitude,
    );
  }

  // =====================================================
  // START JOURNEY
  // =====================================================

  Future<void> startJourney(
      BookingModel booking,
      ) async {
    await stopLocalTracking();

    final position =
    await locationService
        .getCurrentPosition();

    final route =
    await routeEtaService.getRouteEta(
      providerLatitude:
      position.latitude,
      providerLongitude:
      position.longitude,
      customerLatitude:
      booking.latitude,
      customerLongitude:
      booking.longitude,
    );

    await bookingService
        .startJourneyTracking(
      bookingId:
      booking.id,
      providerLatitude:
      position.latitude,
      providerLongitude:
      position.longitude,
      distanceKm:
      route.distanceKm,
      etaMinutes:
      route.etaMinutes,
    );

    _activeBookingId =
        booking.id;

    _lastRouteUpdate =
        DateTime.now();

    await _startPositionStream(
      booking,
    );
  }

  // =====================================================
  // RESUME EXISTING JOURNEY
  // =====================================================

  Future<void> resumeJourney(
      BookingModel booking,
      ) async {
    if (booking.status !=
        BookingStatus.onTheWay) {
      return;
    }

    if (_activeBookingId ==
        booking.id &&
        _positionSubscription != null) {
      return;
    }

    await stopLocalTracking();

    _activeBookingId =
        booking.id;

    try {
      final position =
      await locationService
          .getCurrentPosition();

      await _updatePosition(
        booking: booking,
        position: position,
        force: true,
      );
    } catch (e) {
      debugPrint(
        'Unable to refresh journey '
            'tracking immediately: $e',
      );
    }

    await _startPositionStream(
      booking,
    );
  }

  // =====================================================
  // LOCATION STREAM
  // =====================================================

  Future<void> _startPositionStream(
      BookingModel booking,
      ) async {
    await _positionSubscription
        ?.cancel();

    _positionSubscription =
        locationService
            .watchPosition()
            .listen(
              (position) {
            _updatePosition(
              booking: booking,
              position: position,
            );
          },
          onError: (Object error) {
            debugPrint(
              'Provider location stream '
                  'error: $error',
            );
          },
        );
  }

  // =====================================================
  // UPDATE LOCATION + ETA
  // =====================================================

  Future<void> _updatePosition({
    required BookingModel booking,
    required Position position,
    bool force = false,
  }) async {
    if (_processingUpdate) {
      return;
    }

    final now =
    DateTime.now();

    if (!force &&
        _lastRouteUpdate != null &&
        now.difference(
          _lastRouteUpdate!,
        ) <
            _minimumUpdateInterval) {
      return;
    }

    _processingUpdate = true;

    try {
      final route =
      await routeEtaService
          .getRouteEta(
        providerLatitude:
        position.latitude,
        providerLongitude:
        position.longitude,
        customerLatitude:
        booking.latitude,
        customerLongitude:
        booking.longitude,
      );

      await bookingService
          .updateJourneyTracking(
        bookingId:
        booking.id,
        providerLatitude:
        position.latitude,
        providerLongitude:
        position.longitude,
        distanceKm:
        route.distanceKm,
        etaMinutes:
        route.etaMinutes,
      );

      _lastRouteUpdate =
          DateTime.now();
    } catch (e) {
      debugPrint(
        'Journey tracking update '
            'failed: $e',
      );
    } finally {
      _processingUpdate = false;
    }
  }

  // =====================================================
  // STOP LOCAL GPS TRACKING
  // =====================================================

  Future<void> stopLocalTracking() async {
    await _positionSubscription
        ?.cancel();

    _positionSubscription = null;
    _activeBookingId = null;
    _lastRouteUpdate = null;
    _processingUpdate = false;
  }
}