import 'dart:convert';

import 'package:http/http.dart' as http;

class RouteEtaResult {
  final double distanceKm;
  final int etaMinutes;

  const RouteEtaResult({
    required this.distanceKm,
    required this.etaMinutes,
  });
}

class RouteEtaService {
  final String endpoint;

  const RouteEtaService({
    required this.endpoint,
  });

  Future<RouteEtaResult> getRouteEta({
    required double providerLatitude,
    required double providerLongitude,
    required double customerLatitude,
    required double customerLongitude,
  }) async {
    final response = await http
        .post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'providerLatitude': providerLatitude,
        'providerLongitude': providerLongitude,
        'customerLatitude': customerLatitude,
        'customerLongitude': customerLongitude,
      }),
    )
        .timeout(
      const Duration(
        seconds: 20,
      ),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw StateError(
        'Unable to calculate route ETA. '
            'Status ${response.statusCode}: '
            '${response.body}',
      );
    }

    final decoded =
    jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw StateError(
        'Invalid route response.',
      );
    }

    final distanceKm =
    (decoded['distanceKm'] as num?)
        ?.toDouble();

    final etaMinutes =
    (decoded['etaMinutes'] as num?)
        ?.toInt();

    if (distanceKm == null ||
        etaMinutes == null) {
      throw StateError(
        'Route response is missing distance or ETA.',
      );
    }

    return RouteEtaResult(
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
    );
  }
}