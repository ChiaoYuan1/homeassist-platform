import '../core/app_enums.dart';
import '../models/provider_application_model.dart';
import '../models/service_models.dart';
import '../services/app_services.dart';
import 'base_viewmodel.dart';

class ProviderRegistrationViewModel extends BaseViewModel {
  List<ServiceCategoryModel> categories = [];
  final Map<String, List<ServiceItemModel>> servicesByCategory = {};
  final Set<String> selectedCategoryIds = {};
  final Set<String> selectedServiceIds = {};
  final List<PendingVerificationDocument> documents = [];

  Future<void> loadCategories() async {
    setLoading(true);
    clearError();

    try {
      categories = await AppServices.catalog.getCategories();
      notifyListeners();
    } catch (e) {
      setError('Unable to load service categories: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> toggleCategory({
    required String categoryId,
    required bool selected,
  }) async {
    if (selected) {
      selectedCategoryIds.add(categoryId);
      servicesByCategory[categoryId] =
      await AppServices.catalog.getServicesByCategory(categoryId);
    } else {
      selectedCategoryIds.remove(categoryId);

      final ids = servicesByCategory[categoryId]
          ?.map((service) => service.id)
          .toSet() ??
          {};

      selectedServiceIds.removeAll(ids);
      servicesByCategory.remove(categoryId);

      documents.removeWhere(
            (document) => document.serviceCategoryId == categoryId,
      );
    }

    notifyListeners();
  }

  void toggleService(String id, bool selected) {
    if (selected) {
      selectedServiceIds.add(id);
    } else {
      selectedServiceIds.remove(id);
    }
    notifyListeners();
  }

  void upsertDocument(PendingVerificationDocument document) {
    documents.removeWhere(
          (existing) =>
      existing.documentType == document.documentType &&
          existing.serviceCategoryId == document.serviceCategoryId,
    );
    documents.add(document);
    notifyListeners();
  }

  void removeDocument(PendingVerificationDocument document) {
    documents.remove(document);
    notifyListeners();
  }

  bool hasDocument(String documentType, {String? serviceCategoryId}) {
    return documents.any(
          (document) =>
      document.documentType == documentType &&
          document.serviceCategoryId == serviceCategoryId,
    );
  }

  Future<bool> submit({
    required String businessName,
    required String businessType,
    required String registrationNumber,
    required DateTime registrationDate,
    DateTime? registrationExpiryDate,
    required String contactName,
    required String phone,
    required String email,
    required String businessAddress,
  }) async {
    final uid = AppServices.auth.currentUserId;

    if (uid == null) {
      setError('Provider account is not signed in.');
      return false;
    }

    if (selectedServiceIds.isEmpty) {
      setError('Select at least one service.');
      return false;
    }

    if (!hasDocument('ssm_registration')) {
      setError('Upload the SSM business registration document.');
      return false;
    }

    if (selectedCategoryIds.contains('electrical') &&
        !hasDocument(
          'st_electrical_contractor',
          serviceCategoryId: 'electrical',
        )) {
      setError('Upload the Suruhanjaya Tenaga electrical credential.');
      return false;
    }

    if (selectedCategoryIds.contains('gas_replacement') &&
        !hasDocument(
          'kpdn_lpg_licence',
          serviceCategoryId: 'gas_replacement',
        )) {
      setError('Upload the relevant KPDN LPG licence/document.');
      return false;
    }

    setLoading(true);
    clearError();

    try {
      final existing =
      await AppServices.providerApplication.getApplicationByApplicant(uid);

      if (existing != null) {
        setError(
          'A provider application already exists for this account. '
              'Current status: ${existing.status.label}.',
        );
        return false;
      }

      final inUse = await AppServices.providerApplication.registrationNumberInUse(
        registrationNumber: registrationNumber,
        excludingApplicantUserId: uid,
      );

      if (inUse) {
        setError('This SSM registration number is already in use.');
        return false;
      }

      final applicationId =
      AppServices.providerApplication.createApplicationId();

      final uploaded = await AppServices.storage.uploadProviderDocuments(
        applicationId: applicationId,
        documents: documents,
      );

      await AppServices.providerApplication.submitApplication(
        applicationId: applicationId,
        applicantUserId: uid,
        businessName: businessName,
        businessType: businessType,
        registrationNumber: registrationNumber,
        registrationDate: registrationDate,
        registrationExpiryDate: registrationExpiryDate,
        contactName: contactName,
        phone: phone,
        email: email,
        businessAddress: businessAddress,
        categoryIds: selectedCategoryIds.toList(),
        serviceIds: selectedServiceIds.toList(),
        documents: uploaded,
      );

      return true;
    } catch (e) {
      setError('Unable to submit application: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
}
