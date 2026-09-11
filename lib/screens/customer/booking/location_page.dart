import 'package:flutter/material.dart';
import 'provider_list_page.dart';

class LocationPage extends StatefulWidget {
  final String category;
  final String service;
  final String problemDescription;

  const LocationPage({
    super.key,
    required this.category,
    required this.service,
    required this.problemDescription,
  });

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final TextEditingController _locationController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Service Location',
          style: TextStyle(
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
                    'Where do you need the service?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the location where the service provider should visit.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Service Location',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Enter your address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      alignLabelWithHint: true,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () {
                      _locationController.text = 'Current Location (Prototype)';
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use Current Location'),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your location will be used to find suitable service providers nearby.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // SafeArea(
          //   child: Padding(
          //     padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
          //     child: SizedBox(
          //       width: double.infinity,
          //       height: 52,
          //       child: ElevatedButton(
          //         onPressed: () {
          //           final location = _locationController.text.trim().isEmpty
          //               ? 'Current Location'
          //               : _locationController.text.trim();
          //
          //         //   Navigator.push(
          //         //     context,
          //         //     MaterialPageRoute(
          //         //       builder: (context) => ProviderListPage(
          //         //         category: widget.category,
          //         //         service: widget.service,
          //         //         problemDescription: widget.problemDescription,
          //         //         location: location,
          //         //       ),
          //         //     ),
          //         //   );
          //         // },
          //         child: const Text(
          //           'Find Providers',
          //           style: TextStyle(
          //             fontSize: 16,
          //             fontWeight: FontWeight.bold,
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
