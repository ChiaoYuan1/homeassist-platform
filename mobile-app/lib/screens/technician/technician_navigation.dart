import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'technician_jobs_page.dart';
import 'technician_profile_page.dart';
import 'technician_notifications_page.dart';

class TechnicianNavigation extends StatefulWidget {
  final String providerId;
  final String technicianId;
  final String technicianName;

  const TechnicianNavigation({
    super.key,
    required this.providerId,
    required this.technicianId,
    required this.technicianName,
  });

  @override
  State<TechnicianNavigation> createState() => _TechnicianNavigationState();
}

class _TechnicianNavigationState extends State<TechnicianNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      TechnicianJobsPage(
        providerId: widget.providerId,
        technicianId: widget.technicianId,
        technicianName: widget.technicianName,
      ),
      const TechnicianNotificationsPage(),
      TechnicianProfilePage(
        providerId: widget.providerId,
        technicianId: widget.technicianId,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'My Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
