import '../models/provider_models.dart';
import '../models/service_models.dart';
import '../services/app_services.dart';
import 'base_viewmodel.dart';

class ProviderServicesViewModel extends BaseViewModel {
  List<ProviderServiceOffering> offerings = [];

  List<ServiceItemModel> serviceDetails = [];

  Future<void> load() async {
    final uid = AppServices.auth.currentUserId;
    if (uid == null) return;
    setLoading(true);
    try {
      offerings = await AppServices.provider.getServiceOfferings(uid);
      serviceDetails = await AppServices.catalog.getServicesByIds(offerings.map((o) => o.serviceId).toList());
      notifyListeners();
    } catch (e) {
      setError('Unable to load services: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateOffering({
    required String serviceId,
    required bool active,
    required int durationMinutes
  }) async {
    final uid = AppServices.auth.requireUserId();
    await AppServices.provider.updateServiceOffering(
        providerId: uid,
        serviceId: serviceId,
        active: active,
        estimatedDurationMinutes: durationMinutes
    );
    await load();
  }
  ServiceItemModel? detailFor(String id) {
    for (final d in serviceDetails) {
      if (d.id == id) return d;
    }
    return null;
  }
}
