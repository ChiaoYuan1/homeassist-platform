import '../core/app_enums.dart';
import '../models/report_model.dart';
import '../services/app_services.dart';
import 'base_viewmodel.dart';

class AdminReportsViewModel extends BaseViewModel {
  List<ReportModel> reports = [];

  Future<void> load() async {
    setLoading(true);
    try {
      reports = await AppServices.reports.getReports();
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateStatus({
    required String reportId,
    required ReportStatus status
  }) async {
    await AppServices.reports.updateStatus(
        reportId: reportId,
        status: status
    );
    await load();
  }
}
