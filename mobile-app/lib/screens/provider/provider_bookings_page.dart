import 'package:flutter/material.dart';

import '../../core/app_enums.dart';
import '../../models/booking_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/provider_bookings_viewmodel.dart';
import 'provider_booking_detail_page.dart';

class ProviderBookingsPage extends StatefulWidget {
  const ProviderBookingsPage({
    super.key,
  });

  @override
  State<ProviderBookingsPage> createState() =>
      _ProviderBookingsPageState();
}

class _ProviderBookingsPageState
    extends State<ProviderBookingsPage> {
  final _vm = ProviderBookingsViewModel();

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

  Future<void> _open(
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
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bookings',
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
                // ==========================================
                // NEW REQUESTS
                // ==========================================

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'New Requests',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),

                    if (_vm.pending.isNotEmpty)
                      Container(
                        width: 9,
                        height: 9,
                        decoration:
                        const BoxDecoration(
                          color:
                          AppTheme.error,
                          shape:
                          BoxShape.circle,
                        ),
                      ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                if (_vm.pending.isEmpty)
                  const Padding(
                    padding:
                    EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: Text(
                      'No new booking requests.',
                      style: TextStyle(
                        color: AppTheme
                            .textSecondary,
                      ),
                    ),
                  ),

                ..._vm.pending.map(
                      (booking) => _card(
                    booking,
                    true,
                  ),
                ),

                const SizedBox(
                  height: 24,
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
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                if (_vm.upcoming.isEmpty)
                  const Padding(
                    padding:
                    EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: Text(
                      'No upcoming jobs.',
                      style: TextStyle(
                        color: AppTheme
                            .textSecondary,
                      ),
                    ),
                  ),

                ..._vm.upcoming.map(
                      (booking) => _card(
                    booking,
                    false,
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==========================================
                // BOOKING HISTORY
                // ==========================================

                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                if (_vm.history.isEmpty)
                  const Text(
                    'No booking history yet.',
                    style: TextStyle(
                      color: AppTheme
                          .textSecondary,
                    ),
                  ),

                ..._vm.history.map(
                      (booking) => _card(
                    booking,
                    false,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(
      BookingModel booking,
      bool unread,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Card(
        child: InkWell(
          onTap: () => _open(
            booking,
          ),
          borderRadius:
          BorderRadius.circular(18),
          child: Padding(
            padding:
            const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (unread) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration:
                        const BoxDecoration(
                          color:
                          AppTheme.error,
                          shape:
                          BoxShape.circle,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                    ],

                    Expanded(
                      child: Text(
                        _serviceNames(
                          booking,
                        ),
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight
                              .w700,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Text(
                      booking.status.label,
                      style: TextStyle(
                        color: _statusColor(
                          booking.status,
                        ),
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  _appointmentText(
                    booking,
                  ),
                  style:
                  const TextStyle(
                    color: AppTheme
                        .textSecondary,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  booking.address.isEmpty
                      ? 'No address provided'
                      : booking.address,
                  style:
                  const TextStyle(
                    color: AppTheme
                        .textSecondary,
                  ),
                ),
              ],
            ),
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

      case BookingStatus.rejected:
        return AppTheme.error;

      case BookingStatus.expired:
      case BookingStatus.cancelled:
        return AppTheme.textSecondary;

      case BookingStatus.completed:
        return Colors.green;

      case BookingStatus.accepted:
      case BookingStatus.onTheWay:
      case BookingStatus.arrived:
      case BookingStatus.inProgress:
        return AppTheme.primary;
    }
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
    ).format(context);

    final end =
    TimeOfDay.fromDateTime(
      booking.appointmentEnd,
    ).format(context);

    return '$date • $start - $end';
  }

  String _serviceNames(
      BookingModel booking,
      ) {
    final names = booking.problemDetails
        .map(
          (problem) =>
          _formatServiceName(
            problem.serviceName,
          ),
    )
        .where(
          (name) => name.isNotEmpty,
    )
        .toSet()
        .toList();

    if (names.isNotEmpty) {
      return names.join(', ');
    }

    final fallback = booking.serviceIds
        .map(
      _formatServiceName,
    )
        .where(
          (name) => name.isNotEmpty,
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
    final cleaned = value.trim();

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