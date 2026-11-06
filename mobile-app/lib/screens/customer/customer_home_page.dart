import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'booking/service_category_page.dart';
import 'service_assistant_page.dart';

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text(
              'HomeAssist',
              style: TextStyle(
                  fontWeight: FontWeight.w700
              )
          )
      ),
      body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
                'Good morning 👋',
                style: TextStyle(
                    color: AppTheme.textSecondary
                )
            ),
            const SizedBox(
                height: 4
            ),
            const Text(
                'What can we help you with?',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700
                )
            ),
            const SizedBox(
                height: 24
            ),
            Card(
                child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: const Icon(
                        Icons.home_repair_service_outlined,
                        color: AppTheme.primary
                    ),
                    title: const Text(
                        'Find a Service',
                        style: TextStyle(
                            fontWeight: FontWeight.w700
                        )
                    ),
                    subtitle: const Text('Book a suitable nearby provider.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ServiceCategoryPage()
                        )
                    )
                )
            ),
            const SizedBox(
                height: 12
            ),
            Card(
                child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primary
                    ),
                    title: const Text(
                        'Not sure what service?',
                        style: TextStyle(
                            fontWeight: FontWeight.w700
                        )
                    ),
                    subtitle: const Text('Describe the problem for service suggestions.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ServiceAssistantPage()
                        )
                    )
                )
            )
          ]
      )
  );
}
