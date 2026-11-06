import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_enums.dart';
import '../screens/customer/booking/customer_booking_status_page.dart';
import '../theme/app_theme.dart';

class BookingAlertListener extends StatefulWidget {
  final Widget child;

  const BookingAlertListener({
    super.key,
    required this.child,
  });

  @override
  State<BookingAlertListener> createState() =>
      _BookingAlertListenerState();
}

class _BookingAlertListenerState
    extends State<BookingAlertListener> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  final Queue<_JourneyAlert> _pendingAlerts = Queue<_JourneyAlert>();
  Map<String, String> _previousStatuses = {};
  String? _customerId;
  bool _initialSnapshotReceived = false;
  bool _dialogOpen = false;
  bool _openingBooking = false;

  @override
  void initState() {
    super.initState();
    _listenForJourneyUpdates();
  }

  void _listenForJourneyUpdates() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _customerId = uid;
    _subscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('customerId', isEqualTo: uid)
        .snapshots()
        .listen(
      _handleBookingSnapshot,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Customer journey alert listener error: $error');
      },
    );
  }

  String _normaliseStatus(Object? value) =>
      (value ?? '').toString().replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();

  void _handleBookingSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
    if (!mounted || FirebaseAuth.instance.currentUser?.uid != _customerId) {
      return;
    }

    final statuses = <String, String>{};
    final onTheWay = _normaliseStatus(BookingStatus.onTheWay.name);
    final newAlerts = <_JourneyAlert>[];

    for (final document in snapshot.docs) {
      final data = document.data();
      final current = _normaliseStatus(data['status']);
      statuses[document.id] = current;

      final previous = _previousStatuses[document.id];
      // Ignore the initial set of existing bookings, including old journeys.
      if (_initialSnapshotReceived &&
          previous != null &&
          previous != onTheWay &&
          current == onTheWay) {
        newAlerts.add(_JourneyAlert.fromDocument(document.id, data));
      }
    }

    _previousStatuses = statuses;
    if (!_initialSnapshotReceived) {
      _initialSnapshotReceived = true;
      return;
    }

    _pendingAlerts.addAll(newAlerts);
    if (newAlerts.isNotEmpty && !_dialogOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showNextAlert();
      });
    }
  }

  Future<void> _showNextAlert() async {
    if (!mounted || _dialogOpen || _openingBooking || _pendingAlerts.isEmpty) {
      return;
    }

    _dialogOpen = true;
    final alert = _pendingAlerts.removeFirst();
    bool openBooking = false;

    try {
      openBooking = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _OnTheWayDialog(alert: alert),
      ) ??
          false;
    } finally {
      _dialogOpen = false;
    }

    if (!mounted || FirebaseAuth.instance.currentUser?.uid != _customerId) {
      return;
    }

    if (openBooking) {
      // Navigate only after the dialog has closed. Do not show queued dialogs
      // over the Booking Details route.
      _pendingAlerts.clear();
      _openingBooking = true;
      try {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => CustomerBookingStatusPage(
              bookingId: alert.bookingId,
            ),
          ),
        );
      } finally {
        _openingBooking = false;
      }
    }

    if (mounted && _pendingAlerts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showNextAlert();
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pendingAlerts.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _JourneyAlert {
  final String bookingId;
  final String serviceName;
  final DateTime? appointmentStart;

  const _JourneyAlert({
    required this.bookingId,
    required this.serviceName,
    required this.appointmentStart,
  });

  static _JourneyAlert fromDocument(
      String bookingId,
      Map<String, dynamic> data,
      ) {
    String? serviceName;

    final problems = data['problemDetails'];
    if (problems is List) {
      for (final item in problems) {
        if (item is Map && (item['isPrimary'] == true || item['primary'] == true)) {
          final value = item['serviceName']?.toString().trim();
          if (value != null && value.isNotEmpty) {
            serviceName = value;
            break;
          }
        }
      }
      if (serviceName == null && problems.isNotEmpty) {
        final first = problems.first;
        if (first is Map) {
          serviceName = first['serviceName']?.toString().trim();
        }
      }
    }

    if (serviceName == null || serviceName.isEmpty) {
      final ids = data['serviceIds'];
      if (ids is List && ids.isNotEmpty) {
        serviceName = ids.first.toString();
      }
    }

    if (serviceName == null || serviceName.isEmpty) {
      serviceName = data['primaryIssue']?.toString();
    }

    final cleanedServiceName = (serviceName == null || serviceName.trim().isEmpty)
        ? 'Household service'
        : _readableServiceName(serviceName);

    final appointmentValue = data['appointmentStart'];
    DateTime? appointment;
    if (appointmentValue is Timestamp) {
      appointment = appointmentValue.toDate().toLocal();
    } else if (appointmentValue is DateTime) {
      appointment = appointmentValue.toLocal();
    }

    return _JourneyAlert(
      bookingId: bookingId,
      serviceName: cleanedServiceName,
      appointmentStart: appointment,
    );
  }

  static String _readableServiceName(String raw) {
    return raw
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) =>
    '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String get shortBookingReference {
    if (bookingId.length <= 8) return bookingId;
    return '…${bookingId.substring(bookingId.length - 8)}';
  }

  String? get appointmentLabel {
    final date = appointmentStart;
    if (date == null) return null;

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minutes = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '$hour:$minutes $amPm';
  }
}

class _OnTheWayDialog extends StatelessWidget {
  final _JourneyAlert alert;

  const _OnTheWayDialog({required this.alert});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                color: AppTheme.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Technician On the Way',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your technician has started the journey to your service location.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BOOKING DETAILS',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.serviceName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Booking ref. ${alert.shortBookingReference}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (alert.appointmentLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Appointment: ${alert.appointmentLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'View Booking to check the latest appointment status and estimated arrival time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('View Booking'),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
          ],
        ),
      ),
    );
  }
}
