import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/app_enums.dart';
import '../models/booking_draft.dart';
import '../models/booking_model.dart';
import 'notification_service.dart';

class BookingService {
  static const int slotMinutes = 30;

  final FirebaseFirestore _firestore;
  final NotificationService _notifications;

  BookingService({
    FirebaseFirestore? firestore,
    NotificationService? notifications,
  })  : _firestore =
      firestore ?? FirebaseFirestore.instance,
        _notifications =
            notifications ?? NotificationService();

  String createBookingId() =>
      _firestore.collection('bookings').doc().id;

  Future<BookingModel> createBooking({
    required String bookingId,
    required String customerId,
    required BookingDraft draft,
    required List<String> photoUrls,
    required Map<String, List<String>>
    problemPhotoUrls,
  }) async {
    final categoryId =
        draft.categoryId;

    final match =
        draft.providerMatch;

    final slot =
        draft.appointmentSlot;

    final primaryIssue =
    draft.primaryIssue?.trim();

    final problemDescription =
    draft.problemDescription.trim();

    if (categoryId == null ||
        match == null ||
        slot == null ||
        draft.latitude == null ||
        draft.longitude == null ||
        draft.serviceIds.isEmpty ||
        primaryIssue == null ||
        primaryIssue.isEmpty ||
        (primaryIssue ==
            'Other / Not sure' &&
            problemDescription.isEmpty)) {
      throw StateError(
        'The booking is incomplete.',
      );
    }

    final bookingRef =
    _firestore
        .collection('bookings')
        .doc(bookingId);

    final refs =
    _reservationRefs(
      providerId:
      match.provider.id,
      technicianId:
      slot.technicianId,
      start:
      slot.start,
      end:
      slot.end,
    );

    await _firestore.runTransaction(
          (tx) async {
        for (final ref in refs) {
          if ((await tx.get(ref)).exists) {
            throw StateError(
              'The selected appointment is no longer available.',
            );
          }
        }

        tx.set(
          bookingRef,
          {
            'customerId':
            customerId,

            'providerId':
            match.provider.id,

            'providerBranchId':
            match.branch.id,

            'technicianId':
            slot.technicianId,

            'categoryId':
            categoryId,

            'serviceIds':
            draft.serviceIds,

            'primaryIssue':
            primaryIssue,

            'problemDescription':
            problemDescription,

            'photoUrls':
            photoUrls,

            'problemDetails':
            draft.problemDetails
                .map(
                  (problem) => {
                'serviceId':
                problem.serviceId,

                'serviceName':
                problem.serviceName,

                'description':
                problem.description
                    .trim(),

                'photoUrls':
                problemPhotoUrls[
                problem
                    .serviceId] ??
                    <String>[],

                'isPrimary':
                problem.isPrimary,
              },
            )
                .toList(),

            'gasBrandPreference':
            draft.gasBrandPreference,

            'address':
            draft.address.trim(),

            'latitude':
            draft.latitude,

            'longitude':
            draft.longitude,

            'appointmentStart':
            Timestamp.fromDate(
              slot.start,
            ),

            'appointmentEnd':
            Timestamp.fromDate(
              slot.end,
            ),

            'status':
            BookingStatus.pending.value,

            // Provider journey tracking starts
            // only after Start Journey is used.
            'trackingActive':
            false,

            'createdAt':
            FieldValue.serverTimestamp(),

            'updatedAt':
            FieldValue.serverTimestamp(),
          },
        );

        for (var i = 0;
        i < refs.length;
        i++) {
          tx.set(
            refs[i],
            {
              'bookingId':
              bookingId,

              'providerId':
              match.provider.id,

              'technicianId':
              slot.technicianId,

              'slotStart':
              Timestamp.fromDate(
                slot.start.add(
                  Duration(
                    minutes:
                    slotMinutes * i,
                  ),
                ),
              ),
            },
          );
        }
      },
    );

    await _notifications
        .createNotification(
      userId:
      match.provider.id,
      title:
      'New Booking Request',
      message:
      'A customer submitted a new service request.',
      bookingId:
      bookingId,
    );

    final created =
    await bookingRef.get();

    return BookingModel.fromMap(
      created.id,
      created.data()!,
    );
  }

  Future<BookingModel?> getBooking(
      String id,
      ) async {
    final doc =
    await _firestore
        .collection('bookings')
        .doc(id)
        .get();

    if (!doc.exists) {
      return null;
    }

    return BookingModel.fromMap(
      doc.id,
      doc.data()!,
    );
  }

  Stream<BookingModel?> watchBooking(
      String id,
      ) {
    return _firestore
        .collection('bookings')
        .doc(id)
        .snapshots()
        .map(
          (doc) => doc.exists
          ? BookingModel.fromMap(
        doc.id,
        doc.data()!,
      )
          : null,
    );
  }

  Future<List<BookingModel>>
  getProviderBookings(
      String providerId,
      ) async {
    final snapshot =
    await _firestore
        .collection('bookings')
        .where(
      'providerId',
      isEqualTo:
      providerId,
    )
        .get();

    final bookings =
    snapshot.docs
        .map(
          (doc) =>
          BookingModel.fromMap(
            doc.id,
            doc.data(),
          ),
    )
        .toList();

    bookings.sort(
          (a, b) =>
          a.appointmentStart.compareTo(
            b.appointmentStart,
          ),
    );

    return bookings;
  }

  Stream<List<BookingModel>>
  watchProviderBookings(
      String providerId,
      ) {
    return _firestore
        .collection('bookings')
        .where(
      'providerId',
      isEqualTo:
      providerId,
    )
        .snapshots()
        .map(
          (snapshot) {
        final bookings =
        snapshot.docs
            .map(
              (doc) =>
              BookingModel
                  .fromMap(
                doc.id,
                doc.data(),
              ),
        )
            .toList();

        bookings.sort(
              (a, b) =>
              a.appointmentStart
                  .compareTo(
                b.appointmentStart,
              ),
        );

        return bookings;
      },
    );
  }

  Stream<List<BookingModel>> watchTechnicianBookings({
    required String providerId,
    required String technicianId,
  }) {
    return _firestore
        .collection('bookings')
        .where(
      'providerId',
      isEqualTo: providerId,
    )
        .where(
      'technicianId',
      isEqualTo: technicianId,
    )
        .snapshots()
        .map(
          (snapshot) {
        final bookings = snapshot.docs
            .map(
              (doc) => BookingModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
            .toList();

        bookings.sort(
              (a, b) =>
              a.appointmentStart.compareTo(
                b.appointmentStart,
              ),
        );

        return bookings;
      },
    );
  }

  Future<List<BookingModel>>
  getProviderBookingsForDate({
    required String providerId,
    required DateTime date,
  }) async {
    final start =
    DateTime(
      date.year,
      date.month,
      date.day,
    );

    final end =
    start.add(
      const Duration(
        days: 1,
      ),
    );

    final snapshot =
    await _firestore
        .collection('bookings')
        .where(
      'providerId',
      isEqualTo:
      providerId,
    )
        .where(
      'appointmentStart',
      isGreaterThanOrEqualTo:
      Timestamp.fromDate(
        start,
      ),
    )
        .where(
      'appointmentStart',
      isLessThan:
      Timestamp.fromDate(
        end,
      ),
    )
        .get();

    final bookings =
    snapshot.docs
        .map(
          (doc) =>
          BookingModel.fromMap(
            doc.id,
            doc.data(),
          ),
    )
        .toList();

    bookings.sort(
          (a, b) =>
          a.appointmentStart.compareTo(
            b.appointmentStart,
          ),
    );

    return bookings;
  }

  Future<List<BookingModel>>
  getCustomerBookings(
      String customerId,
      ) async {
    final snapshot =
    await _firestore
        .collection('bookings')
        .where(
      'customerId',
      isEqualTo:
      customerId,
    )
        .get();

    final bookings =
    snapshot.docs
        .map(
          (doc) =>
          BookingModel.fromMap(
            doc.id,
            doc.data(),
          ),
    )
        .toList();

    bookings.sort(
          (a, b) =>
          b.appointmentStart.compareTo(
            a.appointmentStart,
          ),
    );

    return bookings;
  }


  // =====================================================
  // CUSTOMER CANCELLATION (PENDING BOOKINGS ONLY)
  // =====================================================

  Future<void> cancelPendingBookingForCustomer({
    required String bookingId,
  }) async {
    final customerId =
        FirebaseAuth.instance.currentUser?.uid;

    if (customerId == null) {
      throw StateError(
        'Please sign in before cancelling a booking.',
      );
    }

    final bookingRef =
    _firestore.collection('bookings').doc(bookingId);

    String? providerIdToNotify;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(bookingRef);

      if (!snapshot.exists) {
        throw StateError('Booking not found.');
      }

      final data = snapshot.data()!;

      // Ensure the booking belongs to this customer.
      if (data['customerId'] != customerId) {
        throw StateError(
          'You can only cancel your own bookings.',
        );
      }

      // Only pending bookings can be cancelled.
      if (data['status'] != BookingStatus.pending.value) {
        throw StateError(
          'This booking is no longer pending.',
        );
      }

      final booking = BookingModel.fromMap(
        snapshot.id,
        data,
      );

      // Find the reserved appointment slots.
      final reservationRefs = _reservationRefs(
        providerId: booking.providerId,
        technicianId: booking.technicianId,
        start: booking.appointmentStart,
        end: booking.appointmentEnd,
      );

      final ownedReservations =
      <DocumentReference<Map<String, dynamic>>>[];

      // Read before writing, as required by Firestore
      // transactions. Only delete this booking's slots.
      for (final reservationRef in reservationRefs) {
        final reservation =
        await transaction.get(reservationRef);

        if (reservation.exists &&
            reservation.data()?['bookingId'] == bookingId) {
          ownedReservations.add(reservationRef);
        }
      }

      // Change the booking status.
      transaction.update(bookingRef, {
        'status': BookingStatus.cancelled.value,
        'trackingActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Release the reservation slots.
      for (final reservationRef in ownedReservations) {
        transaction.delete(reservationRef);
      }

      providerIdToNotify = booking.providerId;
    });

    // Notify the provider after cancellation is saved.
    // A notification failure must not undo cancellation.
    if (providerIdToNotify != null) {
      try {
        await _notifications.createNotification(
          userId: providerIdToNotify!,
          title: 'Booking Cancelled',
          message:
          'A customer cancelled a pending booking request.',
          bookingId: bookingId,
        );
      } catch (error) {
        debugPrint(
          'Booking cancellation notification failed: $error',
        );
      }
    }
  }

  // =====================================================
  // BOOKING STATUS
  // =====================================================

  Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    final ref =
    _firestore
        .collection('bookings')
        .doc(bookingId);

    final snapshot =
    await ref.get();

    if (!snapshot.exists) {
      throw StateError(
        'Booking not found.',
      );
    }

    final booking =
    BookingModel.fromMap(
      snapshot.id,
      snapshot.data()!,
    );

    final currentStatus =
        booking.status;

    final appointmentHasPassed =
    DateTime.now().isAfter(
      booking.appointmentStart,
    );

    if (currentStatus ==
        BookingStatus.pending &&
        appointmentHasPassed &&
        status !=
            BookingStatus.expired) {
      throw StateError(
        'The appointment time has already passed. '
            'This booking request has expired.',
      );
    }

    if (!_isValidStatusTransition(
      currentStatus,
      status,
    )) {
      throw StateError(
        'Invalid booking status transition: '
            '${currentStatus.label} → ${status.label}.',
      );
    }

    if (status ==
        BookingStatus.rejected ||
        status ==
            BookingStatus.cancelled ||
        status ==
            BookingStatus.expired) {
      await _releaseReservations(
        booking,
      );
    }

    final updateData =
    <String, dynamic>{
      'status':
      status.value,

      'updatedAt':
      FieldValue.serverTimestamp(),
    };

    // Safety rule:
    // location tracking must no longer remain
    // active once the provider has arrived
    // or the booking has ended.
    if (status ==
        BookingStatus.arrived ||
        status ==
            BookingStatus.completed ||
        status ==
            BookingStatus.cancelled ||
        status ==
            BookingStatus.rejected ||
        status ==
            BookingStatus.expired) {
      updateData['trackingActive'] =
      false;
    }

    await ref.update(
      updateData,
    );

    await _notifications
        .createNotification(
      userId:
      booking.customerId,
      title:
      'Booking Update',
      message:
      'Your booking is now ${status.label}.',
      bookingId:
      booking.id,
    );
  }

  bool _isValidStatusTransition(
      BookingStatus current,
      BookingStatus next,
      ) {
    switch (current) {
      case BookingStatus.pending:
        return {
          BookingStatus.accepted,
          BookingStatus.rejected,
          BookingStatus.cancelled,
          BookingStatus.expired,
        }.contains(
          next,
        );

      case BookingStatus.accepted:
        return {
          BookingStatus.onTheWay,
          BookingStatus.cancelled,
        }.contains(
          next,
        );

      case BookingStatus.onTheWay:
        return next ==
            BookingStatus.arrived;

      case BookingStatus.arrived:
        return next ==
            BookingStatus.inProgress;

      case BookingStatus.inProgress:
        return next ==
            BookingStatus.completed;

      case BookingStatus.completed:
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
      case BookingStatus.expired:
        return false;
    }
  }

  // =====================================================
  // PROVIDER JOURNEY TRACKING
  // =====================================================
  Future<void> startJourneyTracking({
    required String bookingId,
    required double providerLatitude,
    required double providerLongitude,
    required double distanceKm,
    required int etaMinutes,
  }) async {
    if (providerLatitude < -90 ||
        providerLatitude > 90) {
      throw ArgumentError(
        'Invalid provider latitude.',
      );
    }

    if (providerLongitude < -180 ||
        providerLongitude > 180) {
      throw ArgumentError(
        'Invalid provider longitude.',
      );
    }

    if (distanceKm < 0) {
      throw ArgumentError(
        'Distance cannot be negative.',
      );
    }

    if (etaMinutes < 0) {
      throw ArgumentError(
        'ETA cannot be negative.',
      );
    }

    final ref = _firestore
        .collection('bookings')
        .doc(bookingId);

    final snapshot = await ref.get();

    if (!snapshot.exists) {
      throw StateError(
        'Booking not found.',
      );
    }

    final booking = BookingModel.fromMap(
      snapshot.id,
      snapshot.data()!,
    );

    if (booking.status !=
        BookingStatus.accepted) {
      throw StateError(
        'The booking must be accepted '
            'before the journey can begin.',
      );
    }

    await ref.update({
      'status':
      BookingStatus.onTheWay.value,

      'providerCurrentLatitude':
      providerLatitude,

      'providerCurrentLongitude':
      providerLongitude,

      'distanceKm':
      distanceKm,

      'etaMinutes':
      etaMinutes,

      'locationUpdatedAt':
      FieldValue.serverTimestamp(),

      'trackingActive':
      true,

      'updatedAt':
      FieldValue.serverTimestamp(),
    });

    await _notifications.createNotification(
      userId: booking.customerId,
      title: 'Booking Update',
      message:
      'Your service provider is on the way.',
      bookingId: booking.id,
    );
  }

  Future<void> updateJourneyTracking({
    required String bookingId,
    required double providerLatitude,
    required double providerLongitude,
    required double distanceKm,
    required int etaMinutes,
  }) async {
    if (providerLatitude < -90 ||
        providerLatitude > 90) {
      throw ArgumentError(
        'Invalid provider latitude.',
      );
    }

    if (providerLongitude < -180 ||
        providerLongitude > 180) {
      throw ArgumentError(
        'Invalid provider longitude.',
      );
    }

    if (distanceKm < 0) {
      throw ArgumentError(
        'Distance cannot be negative.',
      );
    }

    if (etaMinutes < 0) {
      throw ArgumentError(
        'ETA cannot be negative.',
      );
    }

    final ref =
    _firestore
        .collection('bookings')
        .doc(bookingId);

    final snapshot =
    await ref.get();

    if (!snapshot.exists) {
      throw StateError(
        'Booking not found.',
      );
    }

    final booking =
    BookingModel.fromMap(
      snapshot.id,
      snapshot.data()!,
    );

    if (booking.status !=
        BookingStatus.onTheWay) {
      throw StateError(
        'Journey tracking is only available '
            'while the provider is on the way.',
      );
    }

    await ref.update({
      'providerCurrentLatitude':
      providerLatitude,

      'providerCurrentLongitude':
      providerLongitude,

      'distanceKm':
      distanceKm,

      'etaMinutes':
      etaMinutes,

      'locationUpdatedAt':
      FieldValue.serverTimestamp(),

      'trackingActive':
      true,

      'updatedAt':
      FieldValue.serverTimestamp(),
    });
  }

  Future<void> stopJourneyTracking({
    required String bookingId,
  }) async {
    final ref =
    _firestore
        .collection('bookings')
        .doc(bookingId);

    final snapshot =
    await ref.get();

    if (!snapshot.exists) {
      throw StateError(
        'Booking not found.',
      );
    }

    await ref.update({
      'trackingActive':
      false,

      'updatedAt':
      FieldValue.serverTimestamp(),
    });
  }

  // =====================================================
  // EXPIRED BOOKINGS
  // =====================================================

  Future<void>
  expirePastPendingBookingsForProvider(
      String providerId,
      ) async {
    final bookings =
    await getProviderBookings(
      providerId,
    );

    final now =
    DateTime.now();

    final expiredBookings =
    bookings.where(
          (booking) =>
      booking.status ==
          BookingStatus.pending &&
          now.isAfter(
            booking.appointmentStart,
          ),
    );

    for (final booking
    in expiredBookings) {
      try {
        await updateBookingStatus(
          bookingId:
          booking.id,
          status:
          BookingStatus.expired,
        );
      } catch (_) {
        // Booking may already have been changed
        // by another device/action.
      }
    }
  }

  Future<void> _releaseReservations(
      BookingModel booking,
      ) async {
    final refs =
    _reservationRefs(
      providerId:
      booking.providerId,
      technicianId:
      booking.technicianId,
      start:
      booking.appointmentStart,
      end:
      booking.appointmentEnd,
    );

    final batch =
    _firestore.batch();

    for (final ref in refs) {
      batch.delete(
        ref,
      );
    }

    await batch.commit();
  }

  List<DocumentReference<
      Map<String, dynamic>>>
  _reservationRefs({
    required String providerId,
    required String technicianId,
    required DateTime start,
    required DateTime end,
  }) {
    final refs =
    <DocumentReference<
        Map<String, dynamic>>>[];

    var cursor =
        start;

    while (cursor.isBefore(end)) {
      refs.add(
        _firestore
            .collection(
          'slotReservations',
        )
            .doc(
          '${providerId}_'
              '${technicianId}_'
              '${cursor.toUtc().millisecondsSinceEpoch}',
        ),
      );

      cursor =
          cursor.add(
            const Duration(
              minutes:
              slotMinutes,
            ),
          );
    }

    return refs;
  }
}