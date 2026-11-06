import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_enums.dart';
import 'attachment_model.dart';

class ApplicationDocumentModel {
  final String label;
  final String authority;
  final String documentType;
  final String? serviceCategoryId;
  final String fileName;
  final String downloadUrl;
  final String? registrationNumber;
  final DateTime? expiryDate;

  const ApplicationDocumentModel({
    required this.label,
    required this.authority,
    required this.documentType,
    required this.fileName,
    required this.downloadUrl,
    this.serviceCategoryId,
    this.registrationNumber,
    this.expiryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'authority': authority,
      'documentType': documentType,
      'serviceCategoryId': serviceCategoryId,
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'registrationNumber': registrationNumber,
      'expiryDate': expiryDate == null ? null : Timestamp.fromDate(expiryDate!),
    };
  }

  factory ApplicationDocumentModel.fromMap(Map<String, dynamic> data) {
    return ApplicationDocumentModel(
      label: data['label'] ?? '',
      authority: data['authority'] ?? '',
      documentType: data['documentType'] ?? '',
      serviceCategoryId: data['serviceCategoryId'],
      fileName: data['fileName'] ?? '',
      downloadUrl: data['downloadUrl'] ?? '',
      registrationNumber: data['registrationNumber'],
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
    );
  }
}

class PendingVerificationDocument {
  final String label;
  final String authority;
  final String documentType;
  final String? serviceCategoryId;
  final AttachmentModel attachment;
  final String? registrationNumber;
  final DateTime? expiryDate;

  const PendingVerificationDocument({
    required this.label,
    required this.authority,
    required this.documentType,
    required this.attachment,
    this.serviceCategoryId,
    this.registrationNumber,
    this.expiryDate,
  });
}

class ProviderApplicationModel {
  final String id;
  final String applicantUserId;
  final String businessName;
  final String businessType;
  final String registrationNumber;
  final DateTime? registrationDate;
  final DateTime? registrationExpiryDate;
  final String contactName;
  final String phone;
  final String email;
  final String businessAddress;
  final List<String> categoryIds;
  final List<String> serviceIds;
  final List<ApplicationDocumentModel> documents;
  final VerificationStatus status;
  final DateTime? submittedAt;

  const ProviderApplicationModel({
    required this.id,
    required this.applicantUserId,
    required this.businessName,
    required this.businessType,
    required this.registrationNumber,
    required this.contactName,
    required this.phone,
    required this.email,
    required this.businessAddress,
    required this.categoryIds,
    required this.serviceIds,
    required this.documents,
    required this.status,
    this.registrationDate,
    this.registrationExpiryDate,
    this.submittedAt,
  });

  factory ProviderApplicationModel.fromMap(
      String id,
      Map<String, dynamic> data,
      ) {
    final rawDocs = List<dynamic>.from(data['documents'] ?? const []);

    return ProviderApplicationModel(
      id: id,
      applicantUserId: data['applicantUserId'] ?? '',
      businessName: data['businessName'] ?? '',
      businessType: data['businessType'] ?? '',
      registrationNumber: data['registrationNumber'] ?? '',
      registrationDate: (data['registrationDate'] as Timestamp?)?.toDate(),
      registrationExpiryDate:
      (data['registrationExpiryDate'] as Timestamp?)?.toDate(),
      contactName: data['contactName'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      businessAddress: data['businessAddress'] ?? '',
      categoryIds: List<String>.from(data['categoryIds'] ?? const []),
      serviceIds: List<String>.from(data['serviceIds'] ?? const []),
      documents: rawDocs
          .map(
            (item) => ApplicationDocumentModel.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList(),
      status: VerificationStatusX.fromValue(data['status'] ?? 'pending'),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
    );
  }
}
