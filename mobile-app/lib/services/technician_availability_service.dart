import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';


class TechnicianEffectiveAvailability {
  final bool isAvailable;

  final int? startMinute;
  final int? endMinute;

  final String source;

  final String? overrideStatus;


  const TechnicianEffectiveAvailability({
    required this.isAvailable,
    required this.source,
    this.startMinute,
    this.endMinute,
    this.overrideStatus,
  });

  const TechnicianEffectiveAvailability.unavailable({
    required this.source,
    this.overrideStatus,
  })  : isAvailable = false,
        startMinute = null,
        endMinute = null;


  bool get hasWorkingHours =>
      isAvailable &&
          startMinute != null &&
          endMinute != null &&
          endMinute! > startMinute!;
}



class TechnicianAvailabilityService {
  final FirebaseFirestore _firestore;


  TechnicianAvailabilityService({
    FirebaseFirestore? firestore,
  }) : _firestore =
      firestore ??
          FirebaseFirestore.instance;


  Future<TechnicianEffectiveAvailability>
  getEffectiveAvailability({
    required String providerId,
    required String technicianId,
    required DateTime date,
  }) async {
    final cleanProviderId =
    providerId.trim();

    final cleanTechnicianId =
    technicianId.trim();


    if (cleanProviderId.isEmpty) {
      throw ArgumentError(
        'Provider ID is required.',
      );
    }


    if (cleanTechnicianId.isEmpty) {
      throw ArgumentError(
        'Technician ID is required.',
      );
    }


    final providerReference =
    _firestore
        .collection(
      'providers',
    )
        .doc(
      cleanProviderId,
    );


    final technicianReference =
    providerReference
        .collection(
      'technicians',
    )
        .doc(
      cleanTechnicianId,
    );


    final exceptionReference =
    technicianReference
        .collection(
      'availabilityOverrides',
    )
        .doc(
      _dateKey(
        date,
      ),
    );


    final results =
    await Future.wait([
      providerReference.get(),
      technicianReference.get(),
      exceptionReference.get(),
    ]);


    final providerData =
    results[0].data();

    final technicianData =
    results[1].data();

    final overrideData =
    results[2].data();


    if (providerData == null) {
      return const TechnicianEffectiveAvailability
          .unavailable(
        source:
        'provider_not_found',
      );
    }


    if (technicianData == null) {
      return const TechnicianEffectiveAvailability
          .unavailable(
        source:
        'technician_not_found',
      );
    }


    /*
     * Inactive technicians must never
     * produce customer booking slots.
     */
    if (
    technicianData['active'] ==
        false
    ) {
      return const TechnicianEffectiveAvailability
          .unavailable(
        source:
        'technician_inactive',
      );
    }


    final dayKey =
    _weekdayKey(
      date,
    );


    /*
     * Business operating hours are always
     * the outer limit.
     *
     * Even if a technician is available,
     * customer slots should not appear
     * while the business itself is closed.
     */
    final providerWorkingHours =
    _asMap(
      providerData[
      'workingHours'],
    );


    final businessSchedule =
    _readSchedule(
      providerWorkingHours[
      dayKey],
    );


    if (
    businessSchedule == null ||
        !businessSchedule.enabled
    ) {
      return const TechnicianEffectiveAvailability
          .unavailable(
        source:
        'business_closed',
      );
    }


    /*
     * A date-specific exception has higher
     * priority than the technician's normal
     * weekly schedule.
     */
    if (overrideData != null) {
      final status =
      overrideData[
      'status']
          ?.toString()
          .trim();


      switch (status) {
        case 'absent':
          return const TechnicianEffectiveAvailability
              .unavailable(
            source:
            'date_override',
            overrideStatus:
            'absent',
          );


        case 'on_leave':
          return const TechnicianEffectiveAvailability
              .unavailable(
            source:
            'date_override',
            overrideStatus:
            'on_leave',
          );


        case 'custom_hours':
          final customSchedule =
          _readCustomSchedule(
            overrideData,
          );


          if (
          customSchedule ==
              null
          ) {
            return const TechnicianEffectiveAvailability
                .unavailable(
              source:
              'invalid_custom_hours',
              overrideStatus:
              'custom_hours',
            );
          }


          return _intersectSchedules(
            businessSchedule,
            customSchedule,
            source:
            'date_override',
            overrideStatus:
            'custom_hours',
          );


        case 'available':
        /*
           * Explicitly available for this
           * date.
           *
           * Business hours still limit the
           * possible appointment times.
           */
          return TechnicianEffectiveAvailability(
            isAvailable:
            true,

            startMinute:
            businessSchedule
                .startMinute,

            endMinute:
            businessSchedule
                .endMinute,

            source:
            'date_override',

            overrideStatus:
            'available',
          );
      }
    }


    final availabilityMode =
    technicianData[
    'availabilityMode']
        ?.toString()
        .trim();


    /*
     * Existing technicians may not have an
     * availabilityMode field yet.
     *
     * They therefore default to following
     * provider business hours.
     */
    if (
    availabilityMode !=
        'custom_weekly'
    ) {
      return TechnicianEffectiveAvailability(
        isAvailable:
        true,

        startMinute:
        businessSchedule
            .startMinute,

        endMinute:
        businessSchedule
            .endMinute,

        source:
        'business_hours',
      );
    }


    /*
     * Custom weekly schedule.
     */
    final weeklyAvailability =
    _asMap(
      technicianData[
      'weeklyAvailability'],
    );


    final technicianSchedule =
    _readSchedule(
      weeklyAvailability[
      dayKey],
    );


    if (
    technicianSchedule ==
        null ||
        !technicianSchedule
            .enabled
    ) {
      return const TechnicianEffectiveAvailability
          .unavailable(
        source:
        'regular_weekly_off',
      );
    }


    /*
     * The effective time must fit inside
     * both:
     *
     * business operating hours
     * AND
     * technician working hours.
     */
    return _intersectSchedules(
      businessSchedule,
      technicianSchedule,
      source:
      'custom_weekly',
    );
  }



  TechnicianEffectiveAvailability
  _intersectSchedules(
      _AvailabilitySchedule first,
      _AvailabilitySchedule second, {
        required String source,
        String? overrideStatus,
      }) {
    final start =
    math.max(
      first.startMinute,
      second.startMinute,
    );


    final end =
    math.min(
      first.endMinute,
      second.endMinute,
    );


    if (end <= start) {
      return TechnicianEffectiveAvailability
          .unavailable(
        source:
        'no_time_overlap',

        overrideStatus:
        overrideStatus,
      );
    }


    return TechnicianEffectiveAvailability(
      isAvailable:
      true,

      startMinute:
      start,

      endMinute:
      end,

      source:
      source,

      overrideStatus:
      overrideStatus,
    );
  }



  _AvailabilitySchedule?
  _readSchedule(
      dynamic rawValue,
      ) {
    final data =
    _asMap(
      rawValue,
    );


    if (data.isEmpty) {
      return null;
    }


    final enabled =
        data['enabled'] ==
            true;


    if (!enabled) {
      return const _AvailabilitySchedule(
        enabled:
        false,

        startMinute:
        0,

        endMinute:
        0,
      );
    }


    final startMinute =
    _toInt(
      data[
      'startMinute'],
    );


    final endMinute =
    _toInt(
      data[
      'endMinute'],
    );


    if (
    startMinute == null ||
        endMinute == null ||
        !_validTimeRange(
          startMinute,
          endMinute,
        )
    ) {
      return null;
    }


    return _AvailabilitySchedule(
      enabled:
      true,

      startMinute:
      startMinute,

      endMinute:
      endMinute,
    );
  }



  _AvailabilitySchedule?
  _readCustomSchedule(
      Map<String, dynamic> data,
      ) {
    final startMinute =
    _toInt(
      data[
      'startMinute'],
    );


    final endMinute =
    _toInt(
      data[
      'endMinute'],
    );


    if (
    startMinute == null ||
        endMinute == null ||
        !_validTimeRange(
          startMinute,
          endMinute,
        )
    ) {
      return null;
    }


    return _AvailabilitySchedule(
      enabled:
      true,

      startMinute:
      startMinute,

      endMinute:
      endMinute,
    );
  }



  bool _validTimeRange(
      int startMinute,
      int endMinute,
      ) {
    return (
        startMinute >= 0 &&
            startMinute < 1440 &&
            endMinute > 0 &&
            endMinute <= 1440 &&
            endMinute >
                startMinute
    );
  }



  int? _toInt(
      dynamic value,
      ) {
    if (value is int) {
      return value;
    }


    if (value is num) {
      return value.toInt();
    }


    return int.tryParse(
      value?.toString() ??
          '',
    );
  }



  Map<String, dynamic> _asMap(
      dynamic value,
      ) {
    if (
    value is
    Map<String, dynamic>
    ) {
      return value;
    }


    if (value is Map) {
      return value.map(
            (
            key,
            item,
            ) =>
            MapEntry(
              key.toString(),
              item,
            ),
      );
    }


    return <
        String,
        dynamic>{};
  }



  String _dateKey(
      DateTime date,
      ) {
    final year =
    date.year
        .toString();


    final month =
    date.month
        .toString()
        .padLeft(
      2,
      '0',
    );


    final day =
    date.day
        .toString()
        .padLeft(
      2,
      '0',
    );


    return '$year-$month-$day';
  }



  String _weekdayKey(
      DateTime date,
      ) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'monday';

      case DateTime.tuesday:
        return 'tuesday';

      case DateTime.wednesday:
        return 'wednesday';

      case DateTime.thursday:
        return 'thursday';

      case DateTime.friday:
        return 'friday';

      case DateTime.saturday:
        return 'saturday';

      case DateTime.sunday:
        return 'sunday';

      default:
        throw StateError(
          'Invalid weekday.',
        );
    }
  }
}



class _AvailabilitySchedule {
  final bool enabled;

  final int startMinute;
  final int endMinute;


  const _AvailabilitySchedule({
    required this.enabled,
    required this.startMinute,
    required this.endMinute,
  });
}