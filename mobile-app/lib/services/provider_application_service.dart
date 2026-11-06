import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_enums.dart';
import '../models/provider_application_model.dart';
import '../models/service_models.dart';

class ProviderApplicationService {
  final FirebaseFirestore _firestore;

  ProviderApplicationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  String createApplicationId() {
    return _firestore.collection('providerApplications').doc().id;
  }

  Future<bool> registrationNumberInUse({
    required String registrationNumber,
    String? excludingApplicantUserId,
  }) async {
    final applicationSnapshot = await _firestore
        .collection('providerApplications')
        .where('registrationNumber', isEqualTo: registrationNumber)
        .limit(5)
        .get();

    final usedByAnotherApplication = applicationSnapshot.docs.any((doc) {
      final applicantUserId = doc.data()['applicantUserId'] as String?;
      return applicantUserId != excludingApplicantUserId;
    });

    if (usedByAnotherApplication) {
      return true;
    }

    final providerSnapshot = await _firestore
        .collection('providers')
        .where('registrationNumber', isEqualTo: registrationNumber)
        .limit(1)
        .get();

    return providerSnapshot.docs.isNotEmpty;
  }

  Future<void> submitApplication({
    required String applicationId,
    required String applicantUserId,
    required String businessName,
    required String businessType,
    required String registrationNumber,
    required DateTime registrationDate,
    DateTime? registrationExpiryDate,
    required String contactName,
    required String phone,
    required String email,
    required String businessAddress,
    required List<String> categoryIds,
    required List<String> serviceIds,
    required List<ApplicationDocumentModel> documents,
  }) async {
    await _firestore.collection('providerApplications').doc(applicationId).set({
      'applicantUserId': applicantUserId,
      'businessName': businessName.trim(),
      'businessType': businessType,
      'registrationNumber': registrationNumber.trim(),
      'registrationDate': Timestamp.fromDate(registrationDate),
      'registrationExpiryDate': registrationExpiryDate == null
          ? null
          : Timestamp.fromDate(registrationExpiryDate),
      'contactName': contactName.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'businessAddress': businessAddress.trim(),
      'categoryIds': categoryIds,
      'serviceIds': serviceIds,
      'documents': documents.map((document) => document.toMap()).toList(),
      'status': VerificationStatus.pending.value,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<ProviderApplicationModel>> getApplications() async {
    final snapshot = await _firestore.collection('providerApplications').get();

    final result = snapshot.docs
        .map(
          (doc) => ProviderApplicationModel.fromMap(
        doc.id,
        doc.data(),
      ),
    )
        .toList();

    result.sort(
          (a, b) => (b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(
        a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );

    return result;
  }

  Future<ProviderApplicationModel?> getApplication(String id) async {
    final doc = await _firestore.collection('providerApplications').doc(id).get();

    if (!doc.exists) {
      return null;
    }

    return ProviderApplicationModel.fromMap(
      doc.id,
      doc.data()!,
    );
  }

  Future<ProviderApplicationModel?> getApplicationByApplicant(String uid) async {
    final snapshot = await _firestore
        .collection('providerApplications')
        .where('applicantUserId', isEqualTo: uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;
    return ProviderApplicationModel.fromMap(
      doc.id,
      doc.data(),
    );
  }

  Future<void> setApplicationStatus({
    required String applicationId,
    required VerificationStatus status,
    required String adminUserId,
  }) async {
    final ref = _firestore.collection('providerApplications').doc(applicationId);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      throw StateError('Application not found.');
    }

    final application = ProviderApplicationModel.fromMap(
      snapshot.id,
      snapshot.data()!,
    );

    final serviceDocs = await Future.wait(
      application.serviceIds.map(
            (id) => _firestore.collection('services').doc(id).get(),
      ),
    );

    await _firestore.runTransaction((transaction) async {
      transaction.update(
        ref,
        {
          'status': status.value,
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': adminUserId,
        },
      );

      if (status != VerificationStatus.approved) {
        return;
      }

      final providerId = application.applicantUserId;
      final providerRef = _firestore.collection('providers').doc(providerId);

      transaction.set(
        providerRef,
        {
          'businessName': application.businessName,
          'businessType': application.businessType,
          'registrationNumber': application.registrationNumber,
          'registrationDate': application.registrationDate == null
              ? null
              : Timestamp.fromDate(application.registrationDate!),
          'registrationExpiryDate': application.registrationExpiryDate == null
              ? null
              : Timestamp.fromDate(application.registrationExpiryDate!),
          'contactName': application.contactName,
          'phone': application.phone,
          'email': application.email,
          'businessAddress': application.businessAddress,
          'verificationDocuments':
          application.documents.map((document) => document.toMap()).toList(),
          'verificationStatus': VerificationStatus.approved.value,
          'active': true,
          'categoryIds': application.categoryIds,
          'serviceIds': application.serviceIds,
          'rating': 0.0,
          'reviewCount': 0,
          'workingHours': _defaultHours(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      for (final doc in serviceDocs) {
        if (!doc.exists) {
          continue;
        }

        final service = ServiceItemModel.fromMap(
          doc.id,
          doc.data()!,
        );

        transaction.set(
          providerRef.collection('serviceOfferings').doc(service.id),
          {
            'active': true,
            'estimatedDurationMinutes': service.defaultDurationMinutes,
          },
          SetOptions(merge: true),
        );
      }

      transaction.set(
        _firestore.collection('users').doc(providerId),
        {
          'role': 'provider',
          'providerVerified': true,
        },
        SetOptions(merge: true),
      );
    });
  }

  Map<String, dynamic> _defaultHours() {
    Map<String, dynamic> day(bool enabled, {int end = 1080}) {
      return {
        'enabled': enabled,
        'startMinute': enabled ? 540 : 0,
        'endMinute': enabled ? end : 0,
      };
    }

    return {
      'monday': day(true),
      'tuesday': day(true),
      'wednesday': day(true),
      'thursday': day(true),
      'friday': day(true),
      'saturday': day(true, end: 900),
      'sunday': day(false),
    };
  }
}
