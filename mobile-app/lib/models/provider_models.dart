import '../core/app_enums.dart';

class ProviderBranchModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final bool active;
  const ProviderBranchModel({required this.id, required this.name, required this.address, required this.latitude, required this.longitude, this.active = true});
  factory ProviderBranchModel.fromMap(String id, Map<String, dynamic> data) => ProviderBranchModel(
    id: id,
    name: data['name'] ?? '',
    address: data['address'] ?? '',
    latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
    active: data['active'] ?? true,
  );
}

class ProviderServiceOffering {
  final String serviceId;
  final bool active;
  final int estimatedDurationMinutes;
  const ProviderServiceOffering({required this.serviceId, required this.active, required this.estimatedDurationMinutes});
  factory ProviderServiceOffering.fromMap(String serviceId, Map<String, dynamic> data) => ProviderServiceOffering(
    serviceId: serviceId,
    active: data['active'] ?? true,
    estimatedDurationMinutes: (data['estimatedDurationMinutes'] as num?)?.toInt() ?? 60,
  );
}

class WorkingHours {
  final bool enabled;
  final int startMinute;
  final int endMinute;
  const WorkingHours({required this.enabled, required this.startMinute, required this.endMinute});
  factory WorkingHours.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const WorkingHours(enabled: false, startMinute: 0, endMinute: 0);
    return WorkingHours(
      enabled: data['enabled'] ?? false,
      startMinute: (data['startMinute'] as num?)?.toInt() ?? 0,
      endMinute: (data['endMinute'] as num?)?.toInt() ?? 0,
    );
  }
  Map<String, dynamic> toMap() => {'enabled': enabled, 'startMinute': startMinute, 'endMinute': endMinute};
}

class TechnicianModel {
  final String id;
  final String providerId;
  final String name;
  final String phone;
  final String workEmail;
  final String? branchId;
  final bool active;
  final List<String> serviceIds;

  const TechnicianModel({
    required this.id,
    required this.providerId,
    required this.name,
    required this.phone,
    this.workEmail = '',
    this.branchId,
    required this.active,
    required this.serviceIds,
  });

  factory TechnicianModel.fromMap(
      String id,
      String providerId,
      Map<String, dynamic> data,
      ) {
    return TechnicianModel(
      id: id,
      providerId: providerId,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      workEmail: data['workEmail'] ?? '',
      branchId: data['branchId']?.toString(),
      active: data['active'] ?? true,
      serviceIds: List<String>.from(
        data['serviceIds'] ?? const [],
      ),
    );
  }
}

class ProviderModel {
  final String id;
  final String businessName;
  final String businessAddress;
  final VerificationStatus verificationStatus;
  final bool active;
  final List<String> categoryIds;
  final List<String> serviceIds;
  final Map<int, WorkingHours> workingHours;
  final double rating;
  final int reviewCount;
  const ProviderModel({required this.id, required this.businessName, required this.businessAddress, required this.verificationStatus, required this.active, required this.categoryIds, required this.serviceIds, required this.workingHours, required this.rating, required this.reviewCount});
  factory ProviderModel.fromMap(String id, Map<String, dynamic> data) {
    final raw = Map<String, dynamic>.from(data['workingHours'] ?? const {});
    const keys = {DateTime.monday:'monday', DateTime.tuesday:'tuesday', DateTime.wednesday:'wednesday', DateTime.thursday:'thursday', DateTime.friday:'friday', DateTime.saturday:'saturday', DateTime.sunday:'sunday'};
    final hours = <int, WorkingHours>{};
    for (final e in keys.entries) {
      hours[e.key] = WorkingHours.fromMap(raw[e.value] == null ? null : Map<String, dynamic>.from(raw[e.value]));
    }
    return ProviderModel(
      id: id,
      businessName: data['businessName'] ?? '',
      businessAddress: data['businessAddress'] ?? '',
      verificationStatus: VerificationStatusX.fromValue(data['verificationStatus'] ?? 'pending'),
      active: data['active'] ?? true,
      categoryIds: List<String>.from(data['categoryIds'] ?? const []),
      serviceIds: List<String>.from(data['serviceIds'] ?? const []),
      workingHours: hours,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProviderMatch {
  final ProviderModel provider;
  final ProviderBranchModel branch;
  final double distanceKm;
  const ProviderMatch({required this.provider, required this.branch, required this.distanceKm});
}
