import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/admin_providers_viewmodel.dart';

class ProviderManagementPage extends StatefulWidget {
  const ProviderManagementPage({super.key});

  @override
  State<ProviderManagementPage> createState() => _ProviderManagementPageState();
}

class _ProviderManagementPageState extends State<ProviderManagementPage> {
  final _vm = AdminProvidersViewModel();

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
                      'Provider Management',
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
                          itemCount: _vm.providers.length,
                          separatorBuilder: (_, __) => const SizedBox(
                              height: 10
                          ),
                          itemBuilder: (context, index) {
                            final p = _vm.providers[index];
                            return Card(
                                child: SwitchListTile(
                                    value: p.active,
                                    title: Text(
                                        p.businessName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700
                                        )
                                    ),
                                    subtitle: Text(
                                        p.active ? 'Active on HomeAssist' : 'Suspended / inactive'
                                    ),
                                    secondary: Icon(
                                        Icons.business_outlined,
                                        color: p.active ? AppTheme.primary : AppTheme.error
                                    ),
                                    onChanged: (v) => _vm.setActive(
                                        p,
                                        v
                                    )
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
