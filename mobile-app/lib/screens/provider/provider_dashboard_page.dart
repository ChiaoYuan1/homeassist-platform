import 'package:flutter/material.dart';

import '../../core/app_enums.dart';
import '../../models/booking_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/provider_dashboard_viewmodel.dart';
import 'provider_booking_detail_page.dart';

class ProviderDashboardPage extends StatefulWidget {
  const ProviderDashboardPage({
    super.key,
  });

  @override
  State<ProviderDashboardPage> createState() =>
      _ProviderDashboardPageState();
}

class _ProviderDashboardPageState
    extends State<ProviderDashboardPage> {
  final _vm = ProviderDashboardViewModel();

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

  Future<void> _openBooking(
      BookingModel booking,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProviderBookingDetailPage(
              bookingId: booking.id,
            ),
      ),
    );

    await _vm.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Provider Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (
            context,
            _,
            ) {
          return RefreshIndicator(
            onRefresh: _vm.load,
            child: ListView(
              padding:
              const EdgeInsets.all(20),
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    fontSize: 15,
                    color:
                    AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                const Text(
                  'Ready for today?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==========================================
                // DASHBOARD STATISTICS
                // ==========================================

                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Pending',
                        value: _vm
                            .pendingCount
                            .toString(),
                        icon: Icons
                            .pending_actions,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: _StatCard(
                        title: 'Today',
                        value: _vm
                            .todayCount
                            .toString(),
                        icon:
                        Icons.today,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Completed',
                        value: _vm
                            .completedCount
                            .toString(),
                        icon: Icons
                            .check_circle_outline,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: _StatCard(
                        title: 'Upcoming',
                        value: _vm
                            .upcomingCount
                            .toString(),
                        icon: Icons
                            .event_available_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 28,
                ),

                // ==========================================
                // UPCOMING JOBS
                // ==========================================

                const Text(
                  'Upcoming Jobs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                if (_vm
                    .upcomingBookings
                    .isEmpty)
                  const Padding(
                    padding:
                    EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    child: Text(
                      'No upcoming jobs.',
                      style: TextStyle(
                        color: AppTheme
                            .textSecondary,
                      ),
                    ),
                  ),

                ..._vm.upcomingBookings
                    .take(3)
                    .map(
                      (booking) =>
                      Padding(
                        padding:
                        const EdgeInsets
                            .only(
                          bottom: 12,
                        ),
                        child: _JobCard(
                          booking:
                          booking,
                          service:
                          _serviceNames(
                            booking,
                          ),
                          time:
                          _appointmentText(
                            booking,
                          ),
                          status:
                          booking
                              .status,
                          onTap: () =>
                              _openBooking(
                                booking,
                              ),
                        ),
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _greeting() {
    final hour =
        DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning 👋';
    }

    if (hour < 18) {
      return 'Good afternoon 👋';
    }

    return 'Good evening 👋';
  }

  String _appointmentText(
      BookingModel booking,
      ) {
    final localizations =
    MaterialLocalizations.of(
      context,
    );

    final date =
    localizations.formatMediumDate(
      booking.appointmentStart,
    );

    final start =
    TimeOfDay.fromDateTime(
      booking.appointmentStart,
    ).format(
      context,
    );

    final end =
    TimeOfDay.fromDateTime(
      booking.appointmentEnd,
    ).format(
      context,
    );

    return '$date • $start - $end';
  }

  String _serviceNames(
      BookingModel booking,
      ) {
    final names =
    booking.problemDetails
        .map(
          (problem) =>
          _formatServiceName(
            problem.serviceName,
          ),
    )
        .where(
          (name) =>
      name.isNotEmpty,
    )
        .toSet()
        .toList();

    if (names.isNotEmpty) {
      return names.join(', ');
    }

    final fallback =
    booking.serviceIds
        .map(
      _formatServiceName,
    )
        .where(
          (name) =>
      name.isNotEmpty,
    )
        .toList();

    if (fallback.isNotEmpty) {
      return fallback.join(', ');
    }

    return 'Service Booking';
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
}

class _StatCard
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Card(
      child: Padding(
        padding:
        const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color:
              AppTheme.primary,
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              value,
              style:
              const TextStyle(
                fontSize: 25,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              title,
              style:
              const TextStyle(
                color: AppTheme
                    .textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCard
    extends StatelessWidget {
  final BookingModel booking;
  final String service;
  final String time;
  final BookingStatus status;
  final VoidCallback onTap;

  const _JobCard({
    required this.booking,
    required this.service,
    required this.time,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        child: Padding(
          padding:
          const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                BoxDecoration(
                  color: AppTheme
                      .primary
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons
                      .home_repair_service_outlined,
                  color:
                  AppTheme.primary,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      service,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight
                            .w700,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      booking.address
                          .trim()
                          .isEmpty
                          ? 'No address provided'
                          : booking
                          .address,
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        color: AppTheme
                            .textSecondary,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      time,
                      style:
                      const TextStyle(
                        fontSize: 13,
                        color: AppTheme
                            .textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Text(
                status.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  _statusColor(
                    status,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(
      BookingStatus status,
      ) {
    switch (status) {
      case BookingStatus.pending:
        return AppTheme.warning;

      case BookingStatus.accepted:
        return AppTheme.success;

      case BookingStatus.onTheWay:
      case BookingStatus.arrived:
      case BookingStatus.inProgress:
        return AppTheme.primary;

      case BookingStatus.completed:
        return AppTheme.success;

      case BookingStatus.rejected:
        return AppTheme.error;

      case BookingStatus.cancelled:
      case BookingStatus.expired:
        return AppTheme.textSecondary;
    }
  }
}