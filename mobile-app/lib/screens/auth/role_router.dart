import 'package:flutter/material.dart';

import '../../core/app_enums.dart';
import '../../models/user_model.dart';
import '../admin/admin_navigation.dart';
import '../customer/customer_navigation.dart';
import '../technician/technician_navigation.dart';
import '../provider/provider_navigation.dart';
import '../provider/provider_registration_page.dart';

Widget destinationForUser(UserModel user) {
  switch (user.role) {
    case UserRole.admin:
      return const AdminNavigation();

    case UserRole.provider:
      if (!user.providerVerified) {
        return const ProviderRegistrationPage();
      }

      return const ProviderNavigation();

    case UserRole.technician:
      final providerId =
          user.providerId?.trim() ?? '';

      final technicianId =
          user.technicianId?.trim() ?? '';

      if (providerId.isEmpty ||
          technicianId.isEmpty) {
        return const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'This technician account has not '
                    'been linked to a provider yet.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }

      return TechnicianNavigation(
        providerId: providerId,
        technicianId: technicianId,
        technicianName:
        user.displayName.trim().isEmpty
            ? 'Technician'
            : user.displayName,
      );

    case UserRole.customer:
      return const CustomerNavigation();
  }
}