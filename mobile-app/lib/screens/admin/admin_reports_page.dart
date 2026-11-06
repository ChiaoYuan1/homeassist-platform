import 'package:flutter/material.dart';
import '../../core/app_enums.dart';
import '../../viewmodels/admin_reports_viewmodel.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final _vm = AdminReportsViewModel();

  @override
  void initState() {
    super.initState();
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(28),
      child: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Reports & Complaints',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700
                      )
                  ),
                  const SizedBox(
                      height: 22
                  ),
                  Expanded(
                      child: ListView.separated(
                          itemCount: _vm.reports.length,
                          separatorBuilder: (_, __) => const SizedBox(
                              height: 10
                          ),
                          itemBuilder: (context, index) {
                            final r = _vm.reports[index];
                            return Card(
                                child: ExpansionTile(
                                    title: Text(
                                        r.subject,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700
                                        )
                                    ),
                                    subtitle: Text(r.status.label),
                                    childrenPadding: const EdgeInsets.fromLTRB(
                                        18,
                                        0,
                                        18,
                                        18
                                    ),
                                    children: [
                                      Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(r.description)
                                      ),
                                      const SizedBox(
                                          height: 12
                                      ),
                                      Row(
                                          children: [
                                            OutlinedButton(
                                                onPressed: () => _vm.updateStatus(
                                                    reportId: r.id,
                                                    status: ReportStatus.underReview
                                                ),
                                                child: const Text('Under Review')
                                            ),
                                            const SizedBox(
                                                width: 10
                                            ),
                                            SizedBox(
                                                width: 120,
                                                child: ElevatedButton(
                                                    onPressed: () => _vm.updateStatus(
                                                        reportId: r.id,
                                                        status: ReportStatus.resolved
                                                    ),
                                                    child: const Text('Resolve')
                                                )
                                            )
                                          ]
                                      )
                                    ]
                                )
                            );
                          }
                      )
                  )
                ]
            );
          }
      )
  );
}
