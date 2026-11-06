import 'package:flutter/material.dart';

import 'admin_dashboard_page.dart';
import 'admin_reports_page.dart';
import 'provider_applications_page.dart';
import 'provider_management_page.dart';

class AdminNavigation extends StatefulWidget {
  const AdminNavigation({super.key});

  @override
  State<AdminNavigation> createState() => _AdminNavigationState();
}

class _AdminNavigationState extends State<AdminNavigation> {
  int _index = 0;

  final List<Widget> _pages = const [
    AdminDashboardPage(),
    ProviderApplicationsPage(),
    ProviderManagementPage(),
    AdminReportsPage(),
  ];

  final List<String> _labels = const [
    'Dashboard',
    'Applications',
    'Providers',
    'Reports',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: Material(
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'HomeAssist',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...List.generate(
                    _labels.length,
                        (index) {
                      return ListTile(
                        selected: _index == index,
                        title: Text(
                          _labels[index],
                        ),
                        onTap: () {
                          setState(() {
                            _index = index;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _pages[_index],
          ),
        ],
      ),
    );
  }
}