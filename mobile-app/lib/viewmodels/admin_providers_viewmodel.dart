import '../models/provider_models.dart';
import '../services/app_services.dart';
import 'base_viewmodel.dart';

class AdminProvidersViewModel extends BaseViewModel {
  List<ProviderModel> providers = [];

  Future<void> load() async {
    setLoading(true);
    try {
      providers = await AppServices.provider.getApprovedProviders();
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }

  Future<void> setActive(
      ProviderModel p,
      bool active
      ) async {
    await AppServices.provider.setProviderActive(
        providerId: p.id,
        active: active
    );
    await load();
  }
}
