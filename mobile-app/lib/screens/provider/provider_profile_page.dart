import 'package:flutter/material.dart';

import '../../core/app_enums.dart';
import '../../models/provider_models.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../auth/splash_screen.dart';

class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({
    super.key,
  });

  @override
  State<ProviderProfilePage> createState() =>
      _ProviderProfilePageState();
}

class _ProviderProfilePageState
    extends State<ProviderProfilePage> {
  late Future<_ProviderProfileData> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _loadProfile();
  }

  Future<_ProviderProfileData> _loadProfile() async {
    final uid = AppServices.auth.currentUserId;

    if (uid == null) {
      throw StateError(
        'No provider account is currently signed in.',
      );
    }

    final provider =
    await AppServices.provider.getProvider(
      uid,
    );

    if (provider == null) {
      throw StateError(
        'Provider profile not found.',
      );
    }

    final branches =
    await AppServices.provider.getBranches(
      uid,
    );

    return _ProviderProfileData(
      provider: provider,
      branches: branches,
    );
  }

  Future<void> _refresh() async {
    setState(_load);

    await _future;
  }

  Future<void> _logout(
      BuildContext context,
      ) async {
    final confirm =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Log Out?',
          ),
          content: const Text(
            'Are you sure you want to log out of the provider account?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Log Out',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await AppServices.auth.signOut();

      if (!context.mounted) {
        return;
      }

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
          const SplashScreen(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to log out: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FutureBuilder<_ProviderProfileData>(
        future: _future,
        builder: (
            context,
            snapshot,
            ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons
                          .error_outline,
                      size: 42,
                      color:
                      AppTheme.error,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Text(
                      'Unable to load provider profile.\n'
                          '${snapshot.error}',
                      textAlign:
                      TextAlign.center,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    OutlinedButton.icon(
                      onPressed: () {
                        setState(
                          _load,
                        );
                      },
                      icon:
                      const Icon(
                        Icons.refresh,
                      ),
                      label:
                      const Text(
                        'Retry',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final data =
          snapshot.data!;

          final provider =
              data.provider;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding:
              const EdgeInsets.all(20),
              children: [
                const SizedBox(
                  height: 8,
                ),

                const Center(
                  child: CircleAvatar(
                    radius: 45,
                    child: Icon(
                      Icons
                          .handyman_outlined,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                Center(
                  child: Text(
                    provider.businessName
                        .trim()
                        .isEmpty
                        ? 'Provider'
                        : provider
                        .businessName,
                    textAlign:
                    TextAlign.center,
                    style:
                    const TextStyle(
                      fontSize: 21,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Center(
                  child: Text(
                    _verificationText(
                      provider
                          .verificationStatus,
                    ),
                    style:
                    TextStyle(
                      color:
                      _verificationColor(
                        provider
                            .verificationStatus,
                      ),
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 26,
                ),

                // ==========================================
                // BUSINESS INFORMATION
                // ==========================================

                _sectionTitle(
                  'Business Information',
                ),

                const SizedBox(
                  height: 10,
                ),

                Card(
                  child: Column(
                    children: [
                      _profileItem(
                        Icons
                            .location_on_outlined,
                        'Business Address',
                        provider
                            .businessAddress
                            .trim()
                            .isEmpty
                            ? 'No business address provided.'
                            : provider
                            .businessAddress,
                      ),

                      const Divider(
                        height: 1,
                      ),

                      _profileItem(
                        Icons
                            .toggle_on_outlined,
                        'Account Status',
                        provider.active
                            ? 'Active'
                            : 'Inactive',
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                // ==========================================
                // SERVICES
                // ==========================================

                _sectionTitle(
                  'Services',
                ),

                const SizedBox(
                  height: 10,
                ),

                Card(
                  child: Padding(
                    padding:
                    const EdgeInsets.all(18),
                    child: provider
                        .serviceIds
                        .isEmpty
                        ? const Text(
                      'No services configured.',
                      style: TextStyle(
                        color: AppTheme
                            .textSecondary,
                      ),
                    )
                        : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: provider
                          .serviceIds
                          .map(
                            (serviceId) =>
                            Chip(
                              label:
                              Text(
                                _formatServiceName(
                                  serviceId,
                                ),
                              ),
                            ),
                      )
                          .toList(),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                // ==========================================
                // BRANCHES
                // ==========================================

                _sectionTitle(
                  'Branches',
                ),

                const SizedBox(
                  height: 10,
                ),

                if (data.branches.isEmpty)
                  const Card(
                    child: Padding(
                      padding:
                      EdgeInsets.all(18),
                      child: Text(
                        'No branches configured.',
                        style: TextStyle(
                          color: AppTheme
                              .textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...data.branches.map(
                        (branch) =>
                        _branchCard(
                          branch,
                        ),
                  ),

                const SizedBox(
                  height: 22,
                ),

                // ==========================================
                // WORKING HOURS
                // ==========================================

                _sectionTitle(
                  'Working Hours',
                ),

                const SizedBox(
                  height: 10,
                ),

                Card(
                  child: Column(
                    children: _workingHourRows(
                      provider,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==========================================
                // LOG OUT
                // ==========================================

                OutlinedButton.icon(
                  onPressed: () {
                    _logout(
                      context,
                    );
                  },
                  style:
                  OutlinedButton.styleFrom(
                    foregroundColor:
                    AppTheme.error,
                    side:
                    const BorderSide(
                      color:
                      AppTheme.error,
                    ),
                  ),
                  icon:
                  const Icon(
                    Icons.logout,
                  ),
                  label:
                  const Text(
                    'Log Out',
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(
      String title,
      ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color:
        AppTheme.textPrimary,
      ),
    );
  }

  Widget _profileItem(
      IconData icon,
      String title,
      String value,
      ) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primary,
      ),
      title: Text(
        title,
      ),
      subtitle: Text(
        value,
      ),
    );
  }

  Widget _branchCard(
      ProviderBranchModel branch,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 10,
      ),
      child: Card(
        child: ListTile(
          contentPadding:
          const EdgeInsets.all(16),
          leading:
          const Icon(
            Icons
                .store_mall_directory_outlined,
            color:
            AppTheme.primary,
          ),
          title: Text(
            branch.name.trim().isEmpty
                ? 'Branch'
                : branch.name,
            style:
            const TextStyle(
              fontWeight:
              FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding:
            const EdgeInsets.only(
              top: 5,
            ),
            child: Text(
              branch.address.trim().isEmpty
                  ? 'No address provided.'
                  : branch.address,
            ),
          ),
          trailing:
          Text(
            branch.active
                ? 'Active'
                : 'Inactive',
            style:
            TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.w600,
              color: branch.active
                  ? AppTheme.success
                  : AppTheme
                  .textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _workingHourRows(
      ProviderModel provider,
      ) {
    const days = {
      DateTime.monday:
      'Monday',
      DateTime.tuesday:
      'Tuesday',
      DateTime.wednesday:
      'Wednesday',
      DateTime.thursday:
      'Thursday',
      DateTime.friday:
      'Friday',
      DateTime.saturday:
      'Saturday',
      DateTime.sunday:
      'Sunday',
    };

    final rows =
    <Widget>[];

    final entries =
    days.entries.toList();

    for (var i = 0;
    i < entries.length;
    i++) {
      final entry =
      entries[i];

      final hours =
      provider.workingHours[
      entry.key];

      final value = hours == null ||
          !hours.enabled
          ? 'Closed'
          : '${_formatMinute(hours.startMinute)}'
          ' - '
          '${_formatMinute(hours.endMinute)}';

      rows.add(
        ListTile(
          leading:
          const Icon(
            Icons
                .schedule_outlined,
            color:
            AppTheme.primary,
          ),
          title: Text(
            entry.value,
          ),
          trailing: Text(
            value,
            style:
            TextStyle(
              fontWeight:
              FontWeight.w600,
              color: value == 'Closed'
                  ? AppTheme
                  .textSecondary
                  : AppTheme
                  .textPrimary,
            ),
          ),
        ),
      );

      if (i !=
          entries.length - 1) {
        rows.add(
          const Divider(
            height: 1,
          ),
        );
      }
    }

    return rows;
  }

  String _formatMinute(
      int minuteOfDay,
      ) {
    final hour =
        minuteOfDay ~/ 60;

    final minute =
        minuteOfDay % 60;

    final dateTime = DateTime(
      2026,
      1,
      1,
      hour,
      minute,
    );

    return TimeOfDay
        .fromDateTime(
      dateTime,
    ).format(
      context,
    );
  }

  String _formatServiceName(
      String value,
      ) {
    final cleaned =
    value.trim();

    if (cleaned.isEmpty) {
      return '';
    }

    return cleaned
        .split('_')
        .map(
          (word) {
        if (word.isEmpty) {
          return '';
        }

        return '${word[0].toUpperCase()}'
            '${word.substring(1)}';
      },
    )
        .join(' ');
  }

  String _verificationText(
      VerificationStatus status,
      ) {
    switch (status) {
      case VerificationStatus.approved:
        return 'Verified Provider ✓';

      case VerificationStatus.pending:
        return 'Verification Pending';

      case VerificationStatus.rejected:
        return 'Verification Rejected';
    }
  }

  Color _verificationColor(
      VerificationStatus status,
      ) {
    switch (status) {
      case VerificationStatus.approved:
        return AppTheme.success;

      case VerificationStatus.pending:
        return AppTheme.warning;

      case VerificationStatus.rejected:
        return AppTheme.error;
    }
  }
}

class _ProviderProfileData {
  final ProviderModel provider;
  final List<ProviderBranchModel> branches;

  const _ProviderProfileData({
    required this.provider,
    required this.branches,
  });
}