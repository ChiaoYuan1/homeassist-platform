import 'package:flutter/material.dart';

import 'provider_dashboard_page.dart';
import 'provider_bookings_page.dart';
import 'provider_schedule_page.dart';
import 'provider_notifications_page.dart';
import 'provider_profile_page.dart';

class ProviderNavigation extends StatefulWidget {
  const ProviderNavigation({super.key});

  @override
  State<ProviderNavigation> createState() => _ProviderNavigationState();
}

class _ProviderNavigationState extends State<ProviderNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ProviderDashboardPage(),
    ProviderBookingsPage(),
    ProviderSchedulePage(),
    ProviderNotificationsPage(),
    ProviderProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),

          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Schedule',
          ),

          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}