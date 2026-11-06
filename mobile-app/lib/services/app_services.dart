import 'auth_service.dart';
import 'availability_service.dart';
import 'booking_service.dart';
import 'dev_seed_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'provider_application_service.dart';
import 'provider_journey_tracking_service.dart';
import 'provider_location_service.dart';
import 'provider_service.dart';
import 'report_service.dart';
import 'route_eta_service.dart';
import 'service_catalog_service.dart';
import 'storage_service.dart';
import 'technician_service.dart';
import 'user_service.dart';

import 'suggestion/gemini_suggestion.dart';
import 'suggestion/groq_suggestion.dart';
import 'suggestion/local_rules.dart';

class AppServices {
  AppServices._();

  static final auth =
  AuthService();

  static final user =
  UserService();

  static final catalog =
  ServiceCatalogService();

  static final location =
  LocationService();

  static final providerLocation =
  ProviderLocationService();

  static final routeEta =
  RouteEtaService(
    endpoint:
    'https://homeassist-ai.p23015038.workers.dev/route',
  );

  static final provider =
  ProviderService();

  static final technician =
  TechnicianService();

  static final notifications =
  NotificationService();

  static final booking =
  BookingService(
    notifications:
    notifications,
  );

  static final journeyTracking =
  ProviderJourneyTrackingService(
    locationService:
    providerLocation,
    routeEtaService:
    routeEta,
    bookingService:
    booking,
  );

  static final availability =
  AvailabilityService(
    providerService:
    provider,
    technicianService:
    technician,
  );

  static final storage =
  StorageService();

  static final providerApplication =
  ProviderApplicationService();

  static final reports =
  ReportService();

  static final suggestion =
  GroqServiceSuggestionService(
    endpoint:
    'https://homeassist-ai.p23015038.workers.dev/',
    fallback:
    AIServiceSuggestionService(
      fallback:
      LocalServiceSuggestionService(),
    ),
  );

  static final devSeed =
  DevSeedService();
}