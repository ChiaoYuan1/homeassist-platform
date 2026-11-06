import 'package:flutter/material.dart';

import '../../core/app_enums.dart';
import '../../models/booking_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/provider_schedule_viewmodel.dart';
import 'provider_booking_detail_page.dart';

class ProviderFullCalendarPage
    extends StatelessWidget {
  final ProviderScheduleViewModel
  viewModel;

  const ProviderFullCalendarPage({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Full Calendar',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (
            context,
            _,
            ) {
          return Column(
            children: [
              CalendarDatePicker(
                initialDate:
                viewModel
                    .selectedDate,
                firstDate:
                DateTime.now()
                    .subtract(
                  const Duration(
                    days: 365,
                  ),
                ),
                lastDate:
                DateTime.now().add(
                  const Duration(
                    days: 730,
                  ),
                ),
                onDateChanged:
                    (date) {
                  viewModel
                      .loadDate(
                    date,
                  );
                },
              ),

              const Divider(
                height: 1,
              ),

              Expanded(
                child:
                viewModel.isLoading
                    ? const Center(
                  child:
                  CircularProgressIndicator(),
                )
                    : viewModel
                    .bookings
                    .isEmpty
                    ? const Center(
                  child:
                  Text(
                    'No scheduled jobs for this date.',
                  ),
                )
                    : _bookingList(
                  context,
                ),
              ),

              Padding(
                padding:
                const EdgeInsets
                    .all(20),
                child:
                SizedBox(
                  width:
                  double.infinity,
                  child:
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        viewModel
                            .selectedDate,
                      );
                    },
                    child:
                    const Text(
                      'Use This Date',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _bookingList(
      BuildContext context,
      ) {
    return ListView.separated(
      padding:
      const EdgeInsets.all(20),
      itemCount:
      viewModel.bookings.length,
      separatorBuilder:
          (_, __) =>
      const SizedBox(
        height: 10,
      ),
      itemBuilder: (
          context,
          index,
          ) {
        final booking =
        viewModel.bookings[
        index];

        return Card(
          child: ListTile(
            contentPadding:
            const EdgeInsets.all(
              16,
            ),
            leading:
            const Icon(
              Icons
                  .home_repair_service_outlined,
              color:
              AppTheme.primary,
            ),
            title:
            Text(
              _serviceNames(
                booking,
              ),
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w700,
              ),
            ),
            subtitle:
            Padding(
              padding:
              const EdgeInsets.only(
                top: 6,
              ),
              child:
              Text(
                '${_formatTime(context, booking.appointmentStart)}'
                    ' - '
                    '${_formatTime(context, booking.appointmentEnd)}\n'
                    '${booking.address}',
              ),
            ),
            isThreeLine:
            true,
            trailing:
            Column(
              mainAxisAlignment:
              MainAxisAlignment
                  .center,
              crossAxisAlignment:
              CrossAxisAlignment
                  .end,
              children: [
                Text(
                  booking
                      .status.label,
                  style:
                  TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight
                        .w600,
                    color:
                    _statusColor(
                      booking
                          .status,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                const Icon(
                  Icons
                      .chevron_right,
                ),
              ],
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProviderBookingDetailPage(
                        bookingId:
                        booking.id,
                      ),
                ),
              );

              await viewModel
                  .loadDate(
                viewModel
                    .selectedDate,
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(
      BuildContext context,
      DateTime dateTime,
      ) {
    return TimeOfDay
        .fromDateTime(
      dateTime,
    ).format(
      context,
    );
  }

  Color _statusColor(
      BookingStatus status,
      ) {
    switch (status) {
      case BookingStatus.accepted:
        return AppTheme.success;

      case BookingStatus.onTheWay:
      case BookingStatus.arrived:
      case BookingStatus.inProgress:
        return AppTheme.primary;

      case BookingStatus.completed:
        return AppTheme.success;

      case BookingStatus.pending:
        return AppTheme.warning;

      case BookingStatus.rejected:
        return AppTheme.error;

      case BookingStatus.cancelled:
      case BookingStatus.expired:
        return AppTheme.textSecondary;
    }
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