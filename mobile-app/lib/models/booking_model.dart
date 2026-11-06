import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_enums.dart';

class BookingProblemModel {
  final String serviceId;
  final String serviceName;
  final String description;
  final List<String> photoUrls;
  final bool isPrimary;

  const BookingProblemModel({
    required this.serviceId,
    required this.serviceName,
    this.description = '',
    this.photoUrls = const [],
    this.isPrimary = false,
  });

  factory BookingProblemModel.fromMap(
      Map<String, dynamic> data,
      ) {
    return BookingProblemModel(
      serviceId:
      data['serviceId'] ?? '',

      serviceName:
      data['serviceName'] ?? '',

      description:
      data['description'] ?? '',

      photoUrls:
      List<String>.from(
        data['photoUrls'] ?? const [],
      ),

      isPrimary:
      data['isPrimary'] ?? false,
    );
  }
}

class BookingModel {
  final String id;

  final String customerId;

  final String providerId;

  final String providerBranchId;

  final String technicianId;

  final String categoryId;

  final List<String> serviceIds;

  final String? primaryIssue;

  // Old shared field.
  // Kept for compatibility with older bookings.
  final String problemDescription;

  // Old shared field.
  // Kept for compatibility with older bookings.
  final List<String> photoUrls;

  // New per-problem structure.
  final List<BookingProblemModel> problemDetails;

  final String? gasBrandPreference;

  final String address;

  final double latitude;

  final double longitude;

  final DateTime appointmentStart;

  final DateTime appointmentEnd;

  final BookingStatus status;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  // =====================================================
  // PROVIDER JOURNEY / ETA TRACKING
  // =====================================================

  final double? providerCurrentLatitude;

  final double? providerCurrentLongitude;

  final double? distanceKm;

  final int? etaMinutes;

  final DateTime? locationUpdatedAt;

  final bool trackingActive;

  const BookingModel({
    required this.id,
    required this.customerId,
    required this.providerId,
    required this.providerBranchId,
    required this.technicianId,
    required this.categoryId,
    required this.serviceIds,
    required this.problemDescription,
    required this.photoUrls,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.appointmentStart,
    required this.appointmentEnd,
    required this.status,

    this.problemDetails = const [],

    this.primaryIssue,
    this.gasBrandPreference,
    this.createdAt,
    this.updatedAt,

    this.providerCurrentLatitude,
    this.providerCurrentLongitude,
    this.distanceKm,
    this.etaMinutes,
    this.locationUpdatedAt,
    this.trackingActive = false,
  });

  factory BookingModel.fromMap(
      String id,
      Map<String, dynamic> data,
      ) {
    final rawProblemDetails =
    data['problemDetails'];

    final problemDetails =
    <BookingProblemModel>[];

    if (rawProblemDetails is List) {
      for (final item in rawProblemDetails) {
        if (item is Map) {
          problemDetails.add(
            BookingProblemModel.fromMap(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          );
        }
      }
    }

    return BookingModel(
      id:
      id,

      customerId:
      data['customerId'] ?? '',

      providerId:
      data['providerId'] ?? '',

      providerBranchId:
      data['providerBranchId'] ?? '',

      technicianId:
      data['technicianId'] ?? '',

      categoryId:
      data['categoryId'] ?? '',

      serviceIds:
      List<String>.from(
        data['serviceIds'] ?? const [],
      ),

      primaryIssue:
      data['primaryIssue'],

      problemDescription:
      data['problemDescription'] ?? '',

      photoUrls:
      List<String>.from(
        data['photoUrls'] ?? const [],
      ),

      problemDetails:
      problemDetails,

      gasBrandPreference:
      data['gasBrandPreference'],

      address:
      data['address'] ?? '',

      latitude:
      (data['latitude'] as num?)
          ?.toDouble() ??
          0,

      longitude:
      (data['longitude'] as num?)
          ?.toDouble() ??
          0,

      appointmentStart:
      (data['appointmentStart']
      as Timestamp)
          .toDate(),

      appointmentEnd:
      (data['appointmentEnd']
      as Timestamp)
          .toDate(),

      status:
      BookingStatusX.fromValue(
        data['status'] ?? 'pending',
      ),

      createdAt:
      (data['createdAt']
      as Timestamp?)
          ?.toDate(),

      updatedAt:
      (data['updatedAt']
      as Timestamp?)
          ?.toDate(),

      // ===================================================
      // PROVIDER JOURNEY / ETA TRACKING
      // ===================================================

      providerCurrentLatitude:
      (data['providerCurrentLatitude']
      as num?)
          ?.toDouble(),

      providerCurrentLongitude:
      (data['providerCurrentLongitude']
      as num?)
          ?.toDouble(),

      distanceKm:
      (data['distanceKm'] as num?)
          ?.toDouble(),

      etaMinutes:
      (data['etaMinutes'] as num?)
          ?.toInt(),

      locationUpdatedAt:
      (data['locationUpdatedAt']
      as Timestamp?)
          ?.toDate(),

      trackingActive:
      data['trackingActive'] ?? false,
    );
  }
}