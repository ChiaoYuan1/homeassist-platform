import 'package:flutter/material.dart';
import 'service_problem_page.dart';

class ServiceSelectionPage extends StatefulWidget {
  final String category;

  const ServiceSelectionPage({
    super.key,
    required this.category,
  });

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage> {
  String? _selectedService;

  List<String> _getServices() {
    switch (widget.category) {
      case 'Plumbing':
        return [
          'Leaking Pipe',
          'Clogged Drain',
          'Broken Tap',
          'Toilet Problem',
          'Other',
        ];
      case 'Electrical':
        return [
          'Power Outage',
          'Faulty Socket',
          'Wiring Problem',
          'Light Problem',
          'Other',
        ];
      case 'Appliance Repair':
        return [
          'Air Conditioner',
          'Refrigerator',
          'Washing Machine',
          'Water Heater',
          'Other',
        ];
      case 'Gas Tank Replacement':
        return [
          'Gas Tank Replacement',
          'Empty Gas Tank',
          'Damaged Gas Tank',
          'Other',
        ];
      default:
        return ['Other'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = _getServices();
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What type of service do you need?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the option that best describes your problem.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 26),
                  ...services.map(
                        (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildServiceOption(
                        service: service,
                        primaryColor: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedService == null
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceProblemPage(
                          category: widget.category,
                          service: _selectedService!,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceOption({
    required String service,
    required Color primaryColor,
  }) {
    final isSelected = _selectedService == service;

    return Material(
      color: isSelected ? primaryColor.withValues(alpha: 0.06) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _selectedService = service;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                    ),
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  service,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
