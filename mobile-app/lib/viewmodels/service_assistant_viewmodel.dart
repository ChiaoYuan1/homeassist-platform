import 'dart:typed_data';

import '../models/service_models.dart';
import '../services/app_services.dart';
import 'base_viewmodel.dart';

class ServiceAssistantViewModel extends BaseViewModel {
  List<ServiceItemModel> suggestions = [];

  bool needsClarification = false;
  String? clarificationQuestion;

  bool noSuitableService = false;

  bool temporarilyUnavailable = false;
  int? retryAfterSeconds;

  Future<void> suggest(
      String description, {
        Uint8List? imageBytes,
        String? imageMimeType,
      }) async {
    setLoading(true);

    // Clear the previous result before starting a new analysis.
    _clearResult();

    notifyListeners();

    try {
      final cats =
      await AppServices.catalog.getCategories();

      final all = <ServiceItemModel>[];

      for (final c in cats) {
        all.addAll(
          await AppServices.catalog
              .getServicesByCategory(c.id),
        );
      }

      final result =
      await AppServices.suggestion.suggestServiceIds(
        description: description,
        availableServices: all,
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
      );

      needsClarification =
          result.needsClarification;

      clarificationQuestion =
          result.clarificationQuestion;

      noSuitableService =
          result.noSuitableService;

      temporarilyUnavailable =
          result.temporarilyUnavailable;

      retryAfterSeconds =
          result.retryAfterSeconds;

      suggestions = [];

      for (final id in result.serviceIds) {
        final matches = all.where(
              (service) => service.id == id,
        );

        if (matches.isNotEmpty) {
          suggestions.add(
            matches.first,
          );
        }
      }

      notifyListeners();
    } catch (e) {
      setError(
        'Unable to analyse the service problem: $e',
      );
    } finally {
      setLoading(false);
    }
  }

  void reset() {
    _clearResult();
    notifyListeners();
  }

  void _clearResult() {
    suggestions = [];

    needsClarification = false;
    clarificationQuestion = null;

    noSuitableService = false;

    temporarilyUnavailable = false;
    retryAfterSeconds = null;
  }
}