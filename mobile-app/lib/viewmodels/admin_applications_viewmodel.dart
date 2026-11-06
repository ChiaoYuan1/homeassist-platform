import '../core/app_enums.dart';
import '../models/provider_application_model.dart';
import '../services/app_services.dart';
import 'base_viewmodel.dart';

class AdminApplicationsViewModel extends BaseViewModel {
  List<ProviderApplicationModel> applications = [];

  Future<void> load() async {
    setLoading(true);
    try {
      applications = await AppServices.providerApplication.getApplications();
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }

  Future<void> review({
    required String applicationId,
    required VerificationStatus status
  }) async {
    await AppServices.providerApplication.setApplicationStatus(
        applicationId: applicationId,
        status: status,
        adminUserId: AppServices.auth.requireUserId()
    );
    await load();
  }
}
