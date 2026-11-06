import '../models/provider_models.dart';
import '../services/app_services.dart';
import 'base_viewmodel.dart';

class ProviderProfileViewModel extends BaseViewModel {
  ProviderModel? provider;

  List<ProviderBranchModel> branches = [];

  Future<void> load() async {
    final uid = AppServices.auth.currentUserId;
    if (uid == null) return;
    setLoading(true);
    try {
      provider = await AppServices.provider.getProvider(uid);
      branches = await AppServices.provider.getBranches(uid);
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }

  Future<void> addBranch({
    required String name,
    required String address
  }) async {
    final uid = AppServices.auth.requireUserId();
    final l = await AppServices.location.geocodeAddress(address);
    await AppServices.provider.addBranch(
        providerId: uid,
        name: name,
        address: l.address,
        latitude: l.latitude,
        longitude: l.longitude
    );
    await load();
  }
}
