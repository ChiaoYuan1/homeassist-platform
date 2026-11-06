import 'dart:typed_data';

import '../../models/service_models.dart';

enum ServiceSuggestionSource {
  none,
  groqQwen,
  primaryGemini,
  primaryGeminiRetry,
  secondaryGemini,
  localFallback,
}

class ServiceSuggestionResult {
  final List<String> serviceIds;
  final bool needsClarification;
  final String? clarificationQuestion;
  final bool noSuitableService;
  final ServiceSuggestionSource source;

  final bool temporarilyUnavailable;
  final int? retryAfterSeconds;

  const ServiceSuggestionResult({
    required this.serviceIds,
    this.needsClarification = false,
    this.clarificationQuestion,
    this.noSuitableService = false,
    this.source = ServiceSuggestionSource.none,
    this.temporarilyUnavailable = false,
    this.retryAfterSeconds,
  });

  const ServiceSuggestionResult.empty()
      : serviceIds = const [],
        needsClarification = false,
        clarificationQuestion = null,
        noSuitableService = false,
        source = ServiceSuggestionSource.none,
        temporarilyUnavailable = false,
        retryAfterSeconds = null;
}

abstract class ServiceSuggestionService {
  Future<ServiceSuggestionResult> suggestServiceIds({
    required String description,
    required List<ServiceItemModel> availableServices,
    Uint8List? imageBytes,
    String? imageMimeType,
  });
}