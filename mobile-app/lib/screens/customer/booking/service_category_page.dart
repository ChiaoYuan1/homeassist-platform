import 'package:flutter/material.dart';
import '../../../models/service_models.dart';
import '../../../services/app_services.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/customer_booking_viewmodel.dart';
import 'service_selection_page.dart';

class ServiceCategoryPage extends StatefulWidget {
  const ServiceCategoryPage({super.key});

  @override
  State<ServiceCategoryPage> createState() => _ServiceCategoryPageState();
}

class _ServiceCategoryPageState extends State<ServiceCategoryPage> {
  late Future<List<ServiceCategoryModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppServices.catalog.getCategories();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text('Find a Service')
      ),
      body: FutureBuilder<List<ServiceCategoryModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(
                child: CircularProgressIndicator()
            );
            final cats = snapshot.data ?? [];
            return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(
                    height: 12
                ),
                itemBuilder: (context, index) {
                  final c = cats[index];
                  return Card(
                      child: ListTile(
                          contentPadding: const EdgeInsets.all(18),
                          leading: const Icon(
                              Icons.home_repair_service_outlined,
                              color: AppTheme.primary
                          ),
                          title: Text(
                              c.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700
                              )
                          ),
                          subtitle: Text(c.description),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            final vm = CustomerBookingViewModel();
                            vm.startCategory(c.id);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ServiceSelectionPage(
                                        categoryName: c.name,
                                        viewModel: vm
                                    )
                                )
                            );
                          }
                      )
                  );
                }
            );
          }
      )
  );
}
