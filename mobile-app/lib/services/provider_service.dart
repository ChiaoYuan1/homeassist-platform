
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/app_enums.dart';
import '../models/provider_models.dart';
import 'distance_service.dart';
import 'review_service.dart';

class ProviderService {
  final FirebaseFirestore _firestore;
  final ReviewService _reviewService;

  ProviderService({
    FirebaseFirestore? firestore,
    ReviewService? reviewService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _reviewService = reviewService ??
            ReviewService(
              firestore: firestore ?? FirebaseFirestore.instance,
            );

  Future<ProviderModel?> getProvider(String providerId) async {
    final document = await _firestore
        .collection('providers')
        .doc(providerId)
        .get();

    if (!document.exists) {
      return null;
    }

    return ProviderModel.fromMap(document.id, document.data()!);
  }

  Future<List<ProviderModel>> getApprovedProviders() async {
    final snapshot = await _firestore
        .collection('providers')
        .where(
      'verificationStatus',
      isEqualTo: VerificationStatus.approved.value,
    )
        .get();

    return snapshot.docs
        .map(
          (document) => ProviderModel.fromMap(
        document.id,
        document.data(),
      ),
    )
        .toList();
  }

  Future<List<ProviderBranchModel>> getBranches(
      String providerId,
      ) async {
    final snapshot = await _firestore
        .collection('providers')
        .doc(providerId)
        .collection('branches')
        .get();

    return snapshot.docs
        .map(
          (document) => ProviderBranchModel.fromMap(
        document.id,
        document.data(),
      ),
    )
        .toList();
  }

  Future<void> addBranch({
    required String providerId,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    await _firestore
        .collection('providers')
        .doc(providerId)
        .collection('branches')
        .add({
      'name': name.trim(),
      'address': address.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<ProviderMatch>> findNearbyProviders({
    required List<String> serviceIds,
    required double customerLatitude,
    required double customerLongitude,
  }) async {
    final providers = await getApprovedProviders();
    final matches = <ProviderMatch>[];

    // Match each provider using its nearest active branch.
    for (final provider in providers) {
      if (!provider.active ||
          !serviceIds.every(provider.serviceIds.contains)) {
        continue;
      }

      final branches = await getBranches(provider.id);

      ProviderBranchModel? nearest;
      double? distance;

      for (final branch in branches.where((branch) => branch.active)) {
        final distanceKm = DistanceService.haversineKm(
          lat1: customerLatitude,
          lon1: customerLongitude,
          lat2: branch.latitude,
          lon2: branch.longitude,
        );

        if (distance == null || distanceKm < distance) {
          nearest = branch;
          distance = distanceKm;
        }
      }

      if (nearest != null && distance != null) {
        matches.add(
          ProviderMatch(
            provider: provider,
            branch: nearest,
            distanceKm: distance,
          ),
        );
      }
    }

    // Load customer review summaries for matching providers.
    // Existing provider documents are not modified.
    final ratedMatches = await Future.wait(
      matches.map((match) async {
        try {
          final summary = await _reviewService.getProviderSummary(
            match.provider.id,
          );

          final original = match.provider;

          final providerWithReviews = ProviderModel(
            id: original.id,
            businessName: original.businessName,
            businessAddress: original.businessAddress,
            verificationStatus: original.verificationStatus,
            active: original.active,
            categoryIds: original.categoryIds,
            serviceIds: original.serviceIds,
            workingHours: original.workingHours,
            rating: summary.averageRating,
            reviewCount: summary.reviewCount,
          );

          return ProviderMatch(
            provider: providerWithReviews,
            branch: match.branch,
            distanceKm: match.distanceKm,
          );
        } catch (error) {
          // Failure to retrieve ratings should not stop customers
          // from finding an otherwise suitable provider.
          debugPrint(
            'Unable to load reviews for ${match.provider.id}: $error',
          );

          return match;
        }
      }),
    );

    // Keep the nearest-first ordering.
    ratedMatches.sort(
          (a, b) => a.distanceKm.compareTo(b.distanceKm),
    );

    return ratedMatches;
  }

  Future<List<ProviderServiceOffering>> getServiceOfferings(
      String providerId,
      ) async {
    final snapshot = await _firestore
        .collection('providers')
        .doc(providerId)
        .collection('serviceOfferings')
        .get();

    return snapshot.docs
        .map(
          (document) => ProviderServiceOffering.fromMap(
        document.id,
        document.data(),
      ),
    )
        .toList();
  }

  Future<void> updateServiceOffering({
    required String providerId,
    required String serviceId,
    required bool active,
    required int estimatedDurationMinutes,
  }) async {
    await _firestore
        .collection('providers')
        .doc(providerId)
        .collection('serviceOfferings')
        .doc(serviceId)
        .set({
      'active': active,
      'estimatedDurationMinutes': estimatedDurationMinutes,
    }, SetOptions(merge: true));

    final offerings = await getServiceOfferings(providerId);

    final activeIds = offerings
        .where((offering) => offering.active)
        .map((offering) => offering.serviceId)
        .toList();

    await _firestore
        .collection('providers')
        .doc(providerId)
        .update({
      'serviceIds': activeIds,
    });
  }

  Future<void> updateWorkingHours({
    required String providerId,
    required Map<int, WorkingHours> hours,
  }) async {
    const names = {
      DateTime.monday: 'monday',
      DateTime.tuesday: 'tuesday',
      DateTime.wednesday: 'wednesday',
      DateTime.thursday: 'thursday',
      DateTime.friday: 'friday',
      DateTime.saturday: 'saturday',
      DateTime.sunday: 'sunday',
    };

    final map = <String, dynamic>{};

    for (final entry in hours.entries) {
      map[names[entry.key]!] = entry.value.toMap();
    }

    await _firestore
        .collection('providers')
        .doc(providerId)
        .update({
      'workingHours': map,
    });
  }

  Future<void> setProviderActive({
    required String providerId,
    required bool active,
  }) =>
      _firestore
          .collection('providers')
          .doc(providerId)
          .update({
        'active': active,
      });
}
