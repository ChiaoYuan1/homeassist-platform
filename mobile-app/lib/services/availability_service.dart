
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/app_enums.dart';
import '../models/appointment_slot.dart';
import '../models/booking_model.dart';
import 'provider_service.dart';
import 'technician_availability_service.dart';
import 'technician_service.dart';

class AvailabilityService {
  static const int slotMinutes = 30;

  final FirebaseFirestore _firestore;
  final ProviderService _providerService;
  final TechnicianService _technicianService;
  final TechnicianAvailabilityService _technicianAvailabilityService;

  AvailabilityService({
    FirebaseFirestore? firestore,
    ProviderService? providerService,
    TechnicianService? technicianService,
    TechnicianAvailabilityService? technicianAvailabilityService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _providerService = providerService ?? ProviderService(),
        _technicianService = technicianService ?? TechnicianService(),
        _technicianAvailabilityService =
            technicianAvailabilityService ??
                TechnicianAvailabilityService();

  Future<List<AppointmentSlot>> getAvailableSlots({
    required String providerId,
    required String branchId,
    required List<String> serviceIds,
    required DateTime date,
  }) async {
    debugPrint('===== AVAILABILITY CHECK =====');
    debugPrint('providerId: $providerId');
    debugPrint('branchId: $branchId');
    debugPrint('date: $date');
    debugPrint('serviceIds: $serviceIds');

    // Check that the provider exists and is active.
    final provider = await _providerService.getProvider(
      providerId,
    );

    debugPrint(
      'provider: ${provider?.businessName}',
    );
    debugPrint(
      'provider active: ${provider?.active}',
    );

    if (provider == null || !provider.active) {
      debugPrint('STOP: provider missing/inactive');
      return [];
    }

    // Validate the specific branch selected by the customer.
    //
    // A missing or inactive branch must not silently
    // fall back to another branch.
    final cleanedBranchId = branchId.trim();

    if (cleanedBranchId.isEmpty) {
      debugPrint('STOP: branch ID is empty');
      return [];
    }

    final branchDocument = await _firestore
        .collection('providers')
        .doc(providerId)
        .collection('branches')
        .doc(cleanedBranchId)
        .get();

    if (!branchDocument.exists) {
      debugPrint('STOP: selected branch does not exist');
      return [];
    }

    final branchData = branchDocument.data();

    if (branchData == null || branchData['active'] == false) {
      debugPrint('STOP: selected branch is inactive');
      return [];
    }

    debugPrint(
      'selected branch: ${branchData['name']}',
    );

    // Check the provider's operating hours.
    final hours = provider.workingHours[date.weekday];

    debugPrint('weekday: ${date.weekday}');
    debugPrint('hours enabled: ${hours?.enabled}');
    debugPrint(
      'hours: ${hours?.startMinute} - ${hours?.endMinute}',
    );

    if (hours == null || !hours.enabled) {
      debugPrint('STOP: operating hours disabled');
      return [];
    }

    // Calculate the total duration of selected services.
    final duration = await _calculateDuration(
      providerId: providerId,
      serviceIds: serviceIds,
    );

    debugPrint('appointment duration: $duration');

    // Retrieve active technicians qualified for all
    // of the customer's selected services.
    final qualifiedTechnicians =
    await _technicianService.getQualifiedActiveTechnicians(
      providerId: providerId,
      serviceIds: serviceIds,
    );

    // IMPORTANT:
    // Only technicians assigned to the selected branch
    // are eligible for this appointment.
    //
    // Legacy technicians without a branch assignment
    // are excluded until the provider assigns a branch.
    final technicians = qualifiedTechnicians
        .where(
          (technician) =>
      technician.branchId == cleanedBranchId,
    )
        .toList();

    debugPrint(
      'company qualified technicians: '
          '${qualifiedTechnicians.length}',
    );

    debugPrint(
      'selected branch qualified technicians: '
          '${technicians.length}',
    );

    for (final technician in technicians) {
      debugPrint(
        'technician: ${technician.name} '
            'branch=${technician.branchId} '
            'services=${technician.serviceIds}',
      );
    }

    if (technicians.isEmpty) {
      debugPrint(
        'STOP: no qualified technician at selected branch',
      );
      return [];
    }

    // Load effective availability for each technician.
    //
    // This checks regular schedules and date-specific
    // availability exceptions.
    final availabilityResults = await Future.wait(
      technicians.map(
            (technician) =>
            _technicianAvailabilityService
                .getEffectiveAvailability(
              providerId: providerId,
              technicianId: technician.id,
              date: date,
            ),
      ),
    );

    final technicianAvailability =
    <String, TechnicianEffectiveAvailability>{};

    for (var index = 0; index < technicians.length; index++) {
      final technician = technicians[index];
      final availability = availabilityResults[index];

      technicianAvailability[technician.id] = availability;

      debugPrint(
        'effective availability: '
            '${technician.name} '
            'available=${availability.isAvailable} '
            'hours=${availability.startMinute}-'
            '${availability.endMinute} '
            'source=${availability.source} '
            'override=${availability.overrideStatus}',
      );
    }

    final dayStart = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final dayEnd = dayStart.add(
      const Duration(days: 1),
    );

    // Load provider bookings.
    //
    // Keep the collision check company-wide because
    // the same technician must never be double-booked,
    // even if branch assignments change.
    final bookingSnapshot = await _firestore
        .collection('bookings')
        .where(
      'providerId',
      isEqualTo: providerId,
    )
        .get();

    final bookings = bookingSnapshot.docs
        .map(
          (document) => BookingModel.fromMap(
        document.id,
        document.data(),
      ),
    )
        .where(
          (booking) =>
      booking.status.blocksSchedule &&
          !booking.appointmentStart.isBefore(dayStart) &&
          booking.appointmentStart.isBefore(dayEnd),
    )
        .toList();

    final opening = DateTime(
      date.year,
      date.month,
      date.day,
      hours.startMinute ~/ 60,
      hours.startMinute % 60,
    );

    final closing = DateTime(
      date.year,
      date.month,
      date.day,
      hours.endMinute ~/ 60,
      hours.endMinute % 60,
    );

    final now = DateTime.now();
    final slots = <AppointmentSlot>[];

    var current = opening;

    // Generate appointment start times in
    // 30-minute intervals.
    while (!current
        .add(Duration(minutes: duration))
        .isAfter(closing)) {
      final end = current.add(
        Duration(minutes: duration),
      );

      // Preserve the existing minimum
      // 30-minute advance booking requirement.
      if (current.isAfter(
        now.add(const Duration(minutes: 30)),
      )) {
        for (final technician in technicians) {
          final availability =
          technicianAvailability[technician.id];

          // Skip technicians who are unavailable,
          // absent, on leave or outside their schedule.
          if (availability == null ||
              !availability.hasWorkingHours) {
            continue;
          }

          final technicianStart = DateTime(
            date.year,
            date.month,
            date.day,
            availability.startMinute! ~/ 60,
            availability.startMinute! % 60,
          );

          final technicianEnd = DateTime(
            date.year,
            date.month,
            date.day,
            availability.endMinute! ~/ 60,
            availability.endMinute! % 60,
          );

          // The entire appointment must fit inside
          // the technician's effective working hours.
          final insideTechnicianHours =
              !current.isBefore(technicianStart) &&
                  !end.isAfter(technicianEnd);

          if (!insideTechnicianHours) {
            continue;
          }

          // Prevent overlapping appointments
          // assigned to the same technician.
          final collision = bookings.any(
                (booking) =>
            booking.technicianId == technician.id &&
                _overlaps(
                  current,
                  end,
                  booking.appointmentStart,
                  booking.appointmentEnd,
                ),
          );

          if (collision) {
            continue;
          }

          // Check existing Firestore slot reservations.
          final reserved = await _hasReservation(
            providerId: providerId,
            technicianId: technician.id,
            start: current,
            end: end,
          );

          if (!reserved) {
            slots.add(
              AppointmentSlot(
                start: current,
                end: end,
                technicianId: technician.id,
                technicianName: technician.name,
              ),
            );

            // Only one available technician is needed
            // to offer this appointment time.
            break;
          }
        }
      }

      current = current.add(
        const Duration(minutes: slotMinutes),
      );
    }

    debugPrint('available slots: ${slots.length}');

    return slots;
  }

  Future<int> _calculateDuration({
    required String providerId,
    required List<String> serviceIds,
  }) async {
    var total = 0;

    for (final serviceId in serviceIds) {
      final document = await _firestore
          .collection('providers')
          .doc(providerId)
          .collection('serviceOfferings')
          .doc(serviceId)
          .get();

      if (!document.exists ||
          document.data()?['active'] != true) {
        throw StateError(
          'One selected service is not currently available.',
        );
      }

      total +=
          (document.data()?['estimatedDurationMinutes'] as num?)
              ?.toInt() ??
              60;
    }

    final rounded =
        (total / slotMinutes).ceil() * slotMinutes;

    return rounded < slotMinutes ? slotMinutes : rounded;
  }

  Future<bool> _hasReservation({
    required String providerId,
    required String technicianId,
    required DateTime start,
    required DateTime end,
  }) async {
    var cursor = start;

    while (cursor.isBefore(end)) {
      final id =
          '${providerId}_${technicianId}_'
          '${cursor.toUtc().millisecondsSinceEpoch}';

      final exists = (await _firestore
          .collection('slotReservations')
          .doc(id)
          .get())
          .exists;

      if (exists) {
        return true;
      }

      cursor = cursor.add(
        const Duration(minutes: slotMinutes),
      );
    }

    return false;
  }

  bool _overlaps(
      DateTime aStart,
      DateTime aEnd,
      DateTime bStart,
      DateTime bEnd,
      ) =>
      aStart.isBefore(bEnd) &&
          bStart.isBefore(aEnd);
}
