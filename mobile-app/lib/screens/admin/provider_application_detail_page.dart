import 'package:flutter/material.dart';

import '../../core/app_enums.dart';
import '../../models/provider_application_model.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/admin_applications_viewmodel.dart';

class ProviderApplicationDetailPage extends StatefulWidget {
  final String applicationId;

  const ProviderApplicationDetailPage({
    super.key,
    required this.applicationId,
  });

  @override
  State<ProviderApplicationDetailPage> createState() =>
      _ProviderApplicationDetailPageState();
}

class _ProviderApplicationDetailPageState
    extends State<ProviderApplicationDetailPage> {
  final _viewModel = AdminApplicationsViewModel();

  late Future<ProviderApplicationModel?> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _reload() {
    _future = AppServices.providerApplication.getApplication(
      widget.applicationId,
    );
  }

  Future<void> _review(
      VerificationStatus status,
      ) async {
    await _viewModel.review(
      applicationId: widget.applicationId,
      status: status,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Application Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FutureBuilder<ProviderApplicationModel?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load application.\n'
                    '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final application = snapshot.data;

          if (application == null) {
            return const Center(
              child: Text(
                'Application not found.',
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 900,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.businessName,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _buildInfoCard(
                      title: 'Business Information',
                      content:
                      'Registration Number: '
                          '${application.registrationNumber}\n'
                          'Contact Person: '
                          '${application.contactName}\n'
                          'Phone: '
                          '${application.phone}\n'
                          'Email: '
                          '${application.email}\n'
                          'Business Address: '
                          '${application.businessAddress}',
                    ),

                    _buildInfoCard(
                      title: 'Services',
                      content:
                      'Categories: '
                          '${application.categoryIds.join(', ')}\n'
                          'Services: '
                          '${application.serviceIds.join(', ')}',
                    ),

                    _buildDocumentsCard(
                      application,
                    ),

                    if (application.status ==
                        VerificationStatus.pending) ...[
                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: _viewModel.isLoading
                                ? null
                                : () {
                              _review(
                                VerificationStatus
                                    .rejected,
                              );
                            },
                            child: const Text(
                              'Reject',
                            ),
                          ),

                          const SizedBox(width: 12),

                          SizedBox(
                            width: 180,
                            child: ElevatedButton(
                              onPressed:
                              _viewModel.isLoading
                                  ? null
                                  : () {
                                _review(
                                  VerificationStatus
                                      .approved,
                                );
                              },
                              child: _viewModel.isLoading
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text(
                                'Approve Provider',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(content),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsCard(
      ProviderApplicationModel application,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'Verification Documents',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            if (application.documents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 12,
                ),
                child: Text(
                  'No verification documents uploaded.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            else
              ...application.documents.map(
                    (document) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.description_outlined,
                      color: AppTheme.primary,
                    ),
                    title: Text(
                      document.label,
                    ),
                    subtitle: Text(
                      document.fileName,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}