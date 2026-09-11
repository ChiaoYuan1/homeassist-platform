import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            CircleAvatar(
              radius: 45,
              backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.person_outline,
                size: 50,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Customer Name',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            _buildProfileItem(
              icon: Icons.person_outline,
              title: 'Personal Information',
            ),

            _buildProfileItem(
              icon: Icons.location_on_outlined,
              title: 'Saved Locations',
            ),

            _buildProfileItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
            ),

            _buildProfileItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Feature will be implemented later
      },
    );
  }
}