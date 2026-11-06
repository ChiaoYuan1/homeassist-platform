import 'package:flutter/material.dart';
import '../../core/app_enums.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/admin_applications_viewmodel.dart';
import 'provider_application_detail_page.dart';

class ProviderApplicationsPage extends StatefulWidget {
  const ProviderApplicationsPage({super.key});

  @override
  State<ProviderApplicationsPage> createState() => _ProviderApplicationsPageState();
}

class _ProviderApplicationsPageState extends State<ProviderApplicationsPage> {
  final _vm = AdminApplicationsViewModel();

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
                      'Provider Applications',
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
                          itemCount: _vm.applications.length,
                          separatorBuilder: (_, __) => const SizedBox(
                              height: 10
                          ),
                          itemBuilder: (context, index) {
                            final a = _vm.applications[index];
                            return Card(
                                child: ListTile(
                                    contentPadding: const EdgeInsets.all(18),
                                    title: Text(
                                        a.businessName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700
                                        )
                                    ),
                                    subtitle: Text(a.categoryIds.join(', ')),
                                    trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              a.status.label,
                                              style: TextStyle(
                                                  color: a.status == VerificationStatus.approved ? AppTheme.success : a.status == VerificationStatus.rejected ? AppTheme.error : AppTheme.warning
                                              )
                                          ),
                                          const Icon(Icons.chevron_right)
                                        ]
                                    ),
                                    onTap: () async {
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => ProviderApplicationDetailPage(
                                                  applicationId: a.id
                                              )
                                          )
                                      );
                                      await _vm.load();
                                    }
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
