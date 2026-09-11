import 'package:flutter/material.dart';
import 'service_selection_page.dart';

class ServiceCategoryPage extends StatelessWidget {
  const ServiceCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Find a service',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What do you need help with?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Choose a service category to get started.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 26),

            _buildServiceCard(
              context,
              primaryColor,
              icon: Icons.plumbing_rounded,
              title: 'Plumbing',
              description: 'Pipes, leaks, taps and water-related problems',
            ),

            const SizedBox(height: 14),

            _buildServiceCard(
                context,
                primaryColor,
                icon: Icons.electrical_services_rounded,
                title: 'Electrical',
                description: 'Wiring, power outlets and electrical problems',
            ),

            const SizedBox(height: 14),

            _buildServiceCard(
                context,
                primaryColor,
                icon: Icons.home_repair_service_rounded,
                title: 'Appliance Repair',
                description: 'Wiring and maintenance for household appliances',
            ),

            const SizedBox(height: 14),

            _buildServiceCard(
                context,
                primaryColor,
                icon: Icons.local_fire_department_rounded,
                title: 'Gas Tank Replacement',
                description: 'Request a replacement for your household gas tank',
            ),

            const SizedBox(height: 28),

            Center(
              child: TextButton.icon(
                onPressed: () {
                  //Will be implemented later
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Not sure what service you need?',
                ),
              ),
            ),
            // _buildServiceCard(
            //   context,
            //   icon: Icons.electrical_services,
            //   title: 'Electrical',
            //   description: ''
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
      BuildContext context,
      Color primaryColor, {
        required IconData icon,
        required String title,
        required String description,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: (){
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ServiceSelectionPage(
                    category: title,
                  ),
              ),
          );
        },
        child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 27,
                  color: primaryColor,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}