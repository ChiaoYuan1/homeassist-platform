import '../models/provider_models.dart';
import '../services/app_services.dart';
import 'base_viewmodel.dart';

class ProviderAvailabilityViewModel extends BaseViewModel {
  Map<int, WorkingHours> hours = {
  };

  Future<void> load() async {
    final uid = AppServices.auth.currentUserId;
    if (uid == null) return;
    setLoading(true);
    try {
      final p = await AppServices.provider.getProvider(uid);
      hours = Map<int, WorkingHours>.from(p?.workingHours ?? {});
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }

  void setDay(int weekday, WorkingHours value) {
    hours[weekday] = value;
    notifyListeners();
  }

  Future<void> save() => AppServices.provider.updateWorkingHours(
      providerId: AppServices.auth.requireUserId(),
      hours: hours
  );
}
