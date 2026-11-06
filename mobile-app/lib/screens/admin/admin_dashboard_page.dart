import 'package:flutter/material.dart';
import '../../core/app_enums.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int pending = 0,
      providers = 0,
      reports = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await AppServices.providerApplication.getApplications();
    final p = await AppServices.provider.getApprovedProviders();
    final r = await AppServices.reports.getReports();
    if (!mounted) return;
    setState(() {
      pending = a.where((x) => x.status == VerificationStatus.pending).length;
      providers = p.length;
      reports = r.where(
              (x) => x.status == ReportStatus.open ||
              x.status == ReportStatus.underReview
      ).length;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(28),
      child: loading ? const Center(
          child : CircularProgressIndicator()
      ) : ListView(
          children: [
            const Text(
                'Admin Dashboard',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700
                )
            ),
            const SizedBox(
                height: 22
            ),
            Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _stat(
                      'Pending Applications',
                      '$pending'
                  ),
                  _stat(
                      'Approved Providers',
                      '$providers'
                  ),
                  _stat(
                      'Open Reports',
                      '$reports'
                  )
                ]
            )
          ]
      )
  );

  Widget _stat(String t, String v) => SizedBox(
      width: 230,
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        t,
                        style: const TextStyle(
                            color: AppTheme.textSecondary
                        )
                    ),
                    const SizedBox(
                        height: 10
                    ),
                    Text(
                        v,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700
                        )
                    )
                  ]
              )
          )
      )
  );
}
