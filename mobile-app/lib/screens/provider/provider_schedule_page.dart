import 'package:flutter/material.dart';

import '../../core/app_enums.dart';
import '../../models/booking_model.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/provider_schedule_viewmodel.dart';
import 'provider_booking_detail_page.dart';
import 'provider_full_calendar_page.dart';

class ProviderSchedulePage extends StatefulWidget {
  const ProviderSchedulePage({
    super.key,
  });

  @override
  State<ProviderSchedulePage> createState() =>
      _ProviderSchedulePageState();
}

class _ProviderSchedulePageState
    extends State<ProviderSchedulePage> {
  final _vm =
  ProviderScheduleViewModel();

  @override
  void initState() {
    super.initState();

    _vm.loadDate(
      DateTime.now(),
    );
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _calendar() async {
    final selectedDate =
    await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProviderFullCalendarPage(
              viewModel: _vm,
            ),
      ),
    );

    if (selectedDate != null) {
      await _vm.loadDate(
        selectedDate,
      );
    }
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

    await _vm.loadDate(
      _vm.selectedDate,
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Schedule'),
        actions: [
          IconButton(
            onPressed: _calendar,
            icon: const Icon(
              Icons
                  .calendar_month_outlined,
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (
            context,
            _,
            ) {
          final dates =
          List.generate(
            5,
                (i) => _vm.selectedDate.add(
              Duration(
                days: i - 2,
              ),
            ),
          );

          return Column(
            children: [
              Padding(
                padding:
                const EdgeInsets
                    .all(20),
                child: Row(
                  children:
                  dates.map(
                        (date) {
                      final selected =
                      _isSameDay(
                        date,
                        _vm.selectedDate,
                      );

                      return Expanded(
                        child:
                        Padding(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 3,
                          ),
                          child:
                          InkWell(
                            onTap: () =>
                                _vm.loadDate(
                                  date,
                                ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              14,
                            ),
                            child:
                            Container(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                vertical: 10,
                              ),
                              decoration:
                              BoxDecoration(
                                color: selected
                                    ? AppTheme
                                    .primary
                                    : Colors
                                    .white,
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  14,
                                ),
                                border:
                                Border.all(
                                  color: selected
                                      ? AppTheme
                                      .primary
                                      : AppTheme
                                      .border,
                                ),
                              ),
                              child:
                              Column(
                                mainAxisSize:
                                MainAxisSize
                                    .min,
                                children: [
                                  Text(
                                    _weekday(
                                      date,
                                    ),
                                    style:
                                    TextStyle(
                                      fontSize:
                                      11,
                                      color: selected
                                          ? Colors
                                          .white
                                          : AppTheme
                                          .textSecondary,
                                    ),
                                  ),
                                  const SizedBox(
                                    height:
                                    3,
                                  ),
                                  Text(
                                    '${date.day}',
                                    textAlign:
                                    TextAlign
                                        .center,
                                    style:
                                    TextStyle(
                                      color: selected
                                          ? Colors
                                          .white
                                          : AppTheme
                                          .textPrimary,
                                      fontWeight:
                                      FontWeight
                                          .w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),

              Padding(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 20,
                ),
                child:
                SizedBox(
                  width:
                  double.infinity,
                  child:
                  OutlinedButton.icon(
                    onPressed:
                    _calendar,
                    icon:
                    const Icon(
                      Icons
                          .calendar_month_outlined,
                    ),
                    label:
                    const Text(
                      'View Full Calendar',
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Expanded(
                child: _vm.isLoading
                    ? const Center(
                  child:
                  CircularProgressIndicator(),
                )
                    : _list(
                  _vm.bookings,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _list(
      List<BookingModel> items,
      ) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No scheduled jobs.',
        ),
      );
    }

    return ListView.separated(
      padding:
      const EdgeInsets.all(20),
      itemCount: items.length,
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
        items[index];

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
                '${_formatTime(booking.appointmentStart)}'
                    ' - '
                    '${_formatTime(booking.appointmentEnd)}\n'
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
            onTap: () =>
                _openBooking(
                  booking,
                ),
          ),
        );
      },
    );
  }

  bool _isSameDay(
      DateTime first,
      DateTime second,
      ) {
    return first.year ==
        second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
  }

  String _weekday(
      DateTime date,
      ) {
    const names = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return names[
    date.weekday - 1];
  }

  String _formatTime(
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