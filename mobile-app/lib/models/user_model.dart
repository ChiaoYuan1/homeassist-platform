import '../core/app_enums.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String phone;
  final UserRole role;
  final bool providerVerified;

  final String? providerId;
  final String? technicianId;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.phone,
    required this.role,
    this.providerVerified = false,
    this.providerId,
    this.technicianId,
  });

  factory UserModel.fromMap(
      String id,
      Map<String, dynamic> data,
      ) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      phone: data['phone'] ?? '',
      role: UserRoleX.fromValue(
        data['role'] ?? 'customer',
      ),
      providerVerified:
      data['providerVerified'] ?? false,
      providerId: data['providerId'],
      technicianId: data['technicianId'],
    );
  }
}