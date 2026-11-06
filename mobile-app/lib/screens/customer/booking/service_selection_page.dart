import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/customer_booking_viewmodel.dart';
import 'service_problem_page.dart';

class ServiceSelectionPage extends StatefulWidget {
  final String categoryName;
  final CustomerBookingViewModel viewModel;

  const ServiceSelectionPage({
    super.key,
    required this.categoryName,
    required this.viewModel
  });

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage> {

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadCategoryServices();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(widget.categoryName)
      ),
      body: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final vm = widget.viewModel;
            return Column(
                children: [
                  Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select the problem(s) you need help with',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  SizedBox(
                                    height: 4,
                                  ),

                                  Text(
                                    'Choose up to 3.',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                                '${vm.draft.serviceIds.length}/3',
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700
                                )
                            )
                          ]
                      )
                  ),
                  Expanded(
                      child: vm.isLoading ? const Center(
                          child : CircularProgressIndicator()
                      ) : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20
                          ),
                          itemCount: vm.categoryServices.length,
                          separatorBuilder: (_, __) => const SizedBox(
                              height: 10
                          ),
                          itemBuilder: (context, index) {
                            final s = vm.categoryServices[index];
                            return Card(
                                child: CheckboxListTile(
                                    value: vm.draft.serviceIds.contains(s.id),
                                    title: Text(s.name),
                                    subtitle: Text('Estimated ${s.defaultDurationMinutes} min'),
                                    onChanged: (_) => vm.toggleService(s)
                                )
                            );
                          }
                      )
                  ),
                  Padding(
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton(
                          onPressed: vm.draft.serviceIds.isEmpty ? null : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ServiceProblemPage(
                                      viewModel: vm
                                  )
                              )
                          ),
                          child: const Text('Continue')
                      )
                  )
                ]
            );
          }
      )
  );
}
