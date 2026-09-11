import 'package:flutter/material.dart';
import 'booking/service_category_page.dart';

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              const Text(
                'Good morning 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'What can we help you with?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 28),

              // Find a Service
              _buildMainActionCard(
                context,
                icon: Icons.search_rounded,
                title: 'Find a Service',
                subtitle: 'Find suitable help for your home',
                filled: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServiceCategoryPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Emergency Assistance
              _buildMainActionCard(
                context,
                icon: Icons.warning_amber_rounded,
                title: 'Emergency Assistance',
                subtitle: 'Get urgent household service help',
                filled: false,
                onTap: () {
                  // Emergency assistance will be implemented later.
                },
              ),

              const SizedBox(height: 32),

              // Active Bookings
              const Text(
                'Active Bookings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 14),

              _buildBookingCard(
                context,
                service: 'Plumbing Repair',
                provider: 'ABC Home Services',
                status: 'Technician on the way',
                dateTime: 'Today · 3:00 PM',
                icon: Icons.plumbing_rounded,
              ),

              const SizedBox(height: 14),

              _buildBookingCard(
                context,
                service: 'Electrical Repair',
                provider: 'XYZ Electrical',
                status: 'Waiting for provider response',
                dateTime: 'Today · 5:00 PM',
                icon: Icons.electrical_services_rounded,
              ),

              const SizedBox(height: 10),

              // View all
              Center(
                child: TextButton(
                  onPressed: () {
                    // Will later navigate to the Bookings tab.
                  },
                  child: Text(
                    'View all bookings',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required bool filled,
        required VoidCallback onTap,
      }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: filled ? primaryColor : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: filled
                ? null
                : Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.white.withValues(alpha: 0.15)
                      : primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 25,
                  color: filled ? Colors.white : primaryColor,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: filled ? Colors.white : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: filled
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: filled ? Colors.white : Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(
      BuildContext context, {
        required String service,
        required String provider,
        required String status,
        required String dateTime,
        required IconData icon,
      }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    final bool isOnTheWay = status == 'Technician on the way';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        provider,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOnTheWay
                        ? primaryColor
                        : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: Colors.grey.shade500,
                ),

                const SizedBox(width: 6),

                Text(
                  dateTime,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}