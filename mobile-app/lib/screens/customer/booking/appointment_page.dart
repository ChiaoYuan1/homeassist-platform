import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/customer_booking_viewmodel.dart';
import 'booking_confirmation_page.dart';

class AppointmentPage extends StatefulWidget {
  final CustomerBookingViewModel viewModel;

  const AppointmentPage({
    super.key,
    required this.viewModel
  });

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadAvailableSlots(_date);
    });
  }

  String _time(DateTime v) {
    final h =
    v.hour == 0
        ? 12
        : v.hour > 12
        ? v.hour - 12
        : v.hour;

    return '$h:${v.minute.toString().padLeft(2, '0')} '
        '${v.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _minutesToTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    final value = DateTime(
      2026,
      1,
      1,
      hour,
      minute,
    );

    return _time(value);
  }

  String _weekdayName(int weekday) {
    const names = {
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };

    return names[weekday] ?? '';
  }

  Widget _buildEmptyAvailability(
      CustomerBookingViewModel vm,
      ) {
    final provider =
        vm.draft.providerMatch?.provider;

    if (provider == null) {
      return const Center(
        child: Text(
          'No available appointments for this date.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final hours =
    provider.workingHours[_date.weekday];

    if (hours == null || !hours.enabled) {
      return Center(
        child: Text(
          '${provider.businessName} is closed on '
              '${_weekdayName(_date.weekday)}.\n\n'
              'Please choose another date.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final opening =
    _minutesToTime(
      hours.startMinute,
    );

    final closing =
    _minutesToTime(
      hours.endMinute,
    );

    final now = DateTime.now();

    final isToday =
        now.year == _date.year &&
            now.month == _date.month &&
            now.day == _date.day;

    final closingTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      hours.endMinute ~/ 60,
      hours.endMinute % 60,
    );

    if (
    isToday &&
        now.isAfter(closingTime)
    ) {
      return Center(
        child: Text(
          '${provider.businessName} operates today '
              'from $opening to $closing.\n\n'
              'Today\'s operating hours have ended. '
              'Please choose another date.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Center(
      child: Text(
        'No qualified technicians are available '
            'for the selected service(s) on this date.\n\n'
            'Operating hours: $opening – $closing.\n'
            'Please choose another date.',
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _pick() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(
          days: 60,
        ),
      ),
    );

    if (d == null) return;

    setState(
          () => _date = d,
    );

    await widget.viewModel
        .loadAvailableSlots(d);
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        appBar: AppBar(
          title: const Text(
            'Choose Appointment',
          ),
        ),

        body: ListenableBuilder(
          listenable: widget.viewModel,

          builder: (context, _) {
            final vm =
                widget.viewModel;

            return Padding(
              padding:
              const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Card(
                    child: ListTile(
                      onTap: _pick,

                      leading: const Icon(
                        Icons
                            .calendar_month_outlined,
                        color:
                        AppTheme.primary,
                      ),

                      title: const Text(
                        'Selected Date',
                      ),

                      subtitle: Text(
                        '${_date.day}/'
                            '${_date.month}/'
                            '${_date.year}',
                      ),

                      trailing:
                      const Icon(
                        Icons.chevron_right,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'Available Time Slots',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Expanded(
                    child:
                    vm.isLoading
                        ? const Center(
                      child:
                      CircularProgressIndicator(),
                    )
                        : vm.availableSlots
                        .isEmpty
                        ? _buildEmptyAvailability(
                      vm,
                    )
                        : SingleChildScrollView(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,

                        children:
                        vm.availableSlots
                            .map(
                              (slot) {
                            final selected =
                                vm.draft
                                    .appointmentSlot
                                    ?.start ==
                                    slot.start &&
                                    vm.draft
                                        .appointmentSlot
                                        ?.technicianId ==
                                        slot.technicianId;

                            return ChoiceChip(
                              selected:
                              selected,

                              label:
                              Text(
                                _time(
                                  slot.start,
                                ),
                              ),

                              onSelected:
                                  (_) =>
                                  vm.selectAppointmentSlot(
                                    slot,
                                  ),
                            );
                          },
                        ).toList(),
                      ),
                    ),
                  ),

                  ElevatedButton(
                    onPressed:
                    vm.draft
                        .appointmentSlot ==
                        null
                        ? null
                        : () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                BookingConfirmationPage(
                                  viewModel:
                                  vm,
                                ),
                          ),
                        ),

                    child:
                    const Text(
                      'Continue',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}
