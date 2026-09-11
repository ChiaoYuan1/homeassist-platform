import 'package:flutter/material.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _buildBookingCard(
              context,
              'Plumbing Repair',
              'ABC Services',
              'Technician is on the way',
              'Today • 3:00 PM',
              Icons.plumbing,
            ),

            const SizedBox(height: 16),

            _buildBookingCard(
              context,
              'Electrical Repair',
              'XYZ Electrical',
              'Waiting for provider response',
              'Today • 5:00 PM',
              Icons.electrical_services,
            ),

            const SizedBox(height: 30),

            const Text(
              'Booking History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _buildBookingCard(
              context,
              'Air Conditioner Repair',
              'CoolFix Services',
              'Completed',
              '20 August 2026',
              Icons.ac_unit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(
      BuildContext context,
      String service,
      String provider,
      String status,
      String dateTime,
      IconData icon,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    service,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(provider),

            const SizedBox(height: 10),

            Text(
              status,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              dateTime,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}