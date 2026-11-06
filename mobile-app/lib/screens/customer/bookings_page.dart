
import 'package:flutter/material.dart';

import '../../core/app_enums.dart';
import '../../models/booking_model.dart';
import '../../models/provider_models.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/customer_booking_list_viewmodel.dart';

import 'booking/customer_booking_status_page.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({
    super.key,
  });

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final _vm = CustomerBookingListViewModel();

  // =====================================================
  // BOOKING HISTORY
  // =====================================================

  bool _showHistory = false;

  BookingStatus _selectedHistoryStatus =
      BookingStatus.completed;

  static const List<BookingStatus> _historyStatuses = [
    BookingStatus.completed,
    BookingStatus.expired,
    BookingStatus.cancelled,
    BookingStatus.rejected,
  ];

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

  // =====================================================
  // FORMATTING
  // =====================================================

  String _formatServiceId(String serviceId) {
    return serviceId
        .split('_')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
      '${word[0].toUpperCase()}${word.substring(1)}',
    )
        .join(' ');
  }

  String _formatServices(List<String> serviceIds) {
    if (serviceIds.isEmpty) {
      return 'Service Request';
    }

    return serviceIds.map(_formatServiceId).join(', ');
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0
        ? 12
        : date.hour % 12;

    final minute = date.minute
        .toString()
        .padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // =====================================================
  // BOOKING FILTERING
  // =====================================================

  List<BookingModel> _getVisibleBookings() {
    final visible = _vm.bookings.where((booking) {
      if (_showHistory) {
        // Only show the selected historical status.
        return booking.status == _selectedHistoryStatus;
      }

      // Active & upcoming bookings exclude
      // completed, expired, cancelled and rejected.
      return !_historyStatuses.contains(booking.status);
    }).toList();

    // Active: upcoming appointments first.
    // History: newest appointment records first.
    visible.sort((a, b) {
      if (_showHistory) {
        return b.appointmentStart.compareTo(
          a.appointmentStart,
        );
      }

      return a.appointmentStart.compareTo(
        b.appointmentStart,
      );
    });

    return visible;
  }

  // =====================================================
  // SWITCH BETWEEN ACTIVE AND HISTORY
  // =====================================================

  void _openBookingHistory() {
    setState(() {
      _showHistory = true;
      _selectedHistoryStatus = BookingStatus.completed;
    });
  }

  void _backToActiveBookings() {
    setState(() {
      _showHistory = false;
    });
  }

  // =====================================================
  // HISTORY STATUS COLOUR
  // =====================================================

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.completed:
        return AppTheme.success;

      case BookingStatus.rejected:
        return AppTheme.error;

      case BookingStatus.cancelled:
        return AppTheme.textSecondary;

      case BookingStatus.expired:
        return const Color(0xFFB45309);

      default:
        return AppTheme.primary;
    }
  }

  // =====================================================
  // PAGE HEADING
  // =====================================================

  Widget _buildSectionHeader() {
    if (!_showHistory) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active & Upcoming Bookings',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Track your current service requests '
                'and upcoming appointments.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openBookingHistory,
              icon: const Icon(
                Icons.history_outlined,
              ),
              label: const Text(
                'View Booking History',
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking History',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Review your previous household '
              'service booking records.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _backToActiveBookings,
            icon: const Icon(
              Icons.arrow_back,
            ),
            label: const Text(
              'Back to Bookings',
            ),
          ),
        ),

        const SizedBox(height: 18),

        // =============================================
        // HISTORY STATUS TABS
        // =============================================

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,

          child: Row(
            children: _historyStatuses.map((status) {
              final isSelected =
                  _selectedHistoryStatus == status;

              return Padding(
                padding: const EdgeInsets.only(
                  right: 8,
                ),

                child: ChoiceChip(
                  label: Text(
                    status.label,
                  ),

                  selected: isSelected,

                  selectedColor:
                  AppTheme.primary.withValues(
                    alpha: 0.10,
                  ),

                  backgroundColor: Colors.white,

                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.border,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(10),
                  ),

                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),

                  onSelected: (_) {
                    setState(() {
                      _selectedHistoryStatus = status;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // EMPTY BOOKING MESSAGE
  // =====================================================

  Widget _buildEmptyState() {
    String message;

    if (!_showHistory) {
      message = _vm.bookings.isEmpty
          ? 'No bookings yet.'
          : 'No active or upcoming bookings.';
    } else {
      switch (_selectedHistoryStatus) {
        case BookingStatus.completed:
          message = 'No completed bookings yet.';
          break;

        case BookingStatus.expired:
          message = 'No expired bookings.';
          break;

        case BookingStatus.cancelled:
          message = 'No cancelled bookings.';
          break;

        case BookingStatus.rejected:
          message = 'No rejected bookings.';
          break;

        default:
          message = 'No booking records found.';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 48,
        horizontal: 12,
      ),

      child: Column(
        children: [
          Icon(
            _showHistory
                ? Icons.history_outlined
                : Icons.calendar_month_outlined,
            size: 48,
            color: AppTheme.textSecondary,
          ),

          const SizedBox(height: 12),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // EXISTING BOOKING CARD
  // =====================================================

  Widget _buildBookingCard(BookingModel booking) {
    return FutureBuilder<ProviderModel?>(
      future: AppServices.provider.getProvider(
        booking.providerId,
      ),

      builder: (context, providerSnapshot) {
        final providerName =
            providerSnapshot.data?.businessName ??
                'Service Provider';

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),

            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CustomerBookingStatusPage(
                        bookingId: booking.id,
                      ),
                ),
              );

              if (mounted) {
                await _vm.load();
              }
            },

            child: Padding(
              padding: const EdgeInsets.all(18),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),

                    child: Icon(
                      Icons.home_repair_service_outlined,
                      color: AppTheme.primary,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        // =============================
                        // SERVICE NAME
                        // =============================

                        Text(
                          _formatServices(
                            booking.serviceIds,
                          ),

                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // =============================
                        // PROVIDER NAME
                        // =============================

                        Text(
                          providerName,

                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // =============================
                        // APPOINTMENT DATE & TIME
                        // =============================

                        Text(
                          '${_formatDate(
                            booking.appointmentStart,
                          )} • '
                              '${_formatTime(
                            booking.appointmentStart,
                          )} - '
                              '${_formatTime(
                            booking.appointmentEnd,
                          )}',
                        ),

                        const SizedBox(height: 6),

                        // =============================
                        // CURRENT BOOKING STATUS
                        // =============================

                        Text(
                          booking.status.label,

                          style: TextStyle(
                            color: _statusColor(
                              booking.status,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // MAIN PAGE
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: ListenableBuilder(
        listenable: _vm,

        builder: (context, _) {
          if (_vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final visibleBookings =
          _getVisibleBookings();

          return RefreshIndicator(
            onRefresh: _vm.load,

            child: ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.all(20),

              children: [
                // =====================================
                // ACTIVE / HISTORY PAGE HEADER
                // =====================================

                _buildSectionHeader(),

                const SizedBox(height: 20),

                // =====================================
                // BOOKING LIST
                // =====================================

                if (visibleBookings.isEmpty)
                  _buildEmptyState()
                else
                  ...visibleBookings.map(
                        (booking) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: _buildBookingCard(booking),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
