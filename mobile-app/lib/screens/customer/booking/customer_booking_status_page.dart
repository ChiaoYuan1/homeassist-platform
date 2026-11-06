
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/app_enums.dart';
import '../../../models/booking_model.dart';
import '../../../services/app_services.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/homeassist_action_dialog.dart';
import '../customer_navigation.dart';
import 'customer_review_page.dart';

class CustomerBookingStatusPage extends StatefulWidget {
  final String bookingId;

  const CustomerBookingStatusPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<CustomerBookingStatusPage> createState() =>
      _CustomerBookingStatusPageState();
}

class _CustomerBookingStatusPageState
    extends State<CustomerBookingStatusPage> {
  bool _cancellingBooking = false;

  late final Stream<BookingModel?> _bookingStream;

  @override
  void initState() {
    super.initState();

    _bookingStream = AppServices.booking.watchBooking(
      widget.bookingId,
    );
  }

  static const _steps = [
    BookingStatus.pending,
    BookingStatus.accepted,
    BookingStatus.onTheWay,
    BookingStatus.arrived,
    BookingStatus.inProgress,
    BookingStatus.completed,
  ];

  bool _reached(
      BookingStatus current,
      BookingStatus step,
      ) {
    if (current == BookingStatus.rejected ||
        current == BookingStatus.cancelled ||
        current == BookingStatus.expired) {
      return step == BookingStatus.pending;
    }

    return _steps.indexOf(current) >= _steps.indexOf(step);
  }

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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0
        ? 12
        : date.hour % 12;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // =========================================================
  // LOAD PROVIDER AND TECHNICIAN DETAILS
  // =========================================================

  Future<_BookingDisplayDetails> _loadDisplayDetails(
      BookingModel booking,
      ) async {
    String providerName = 'Service Provider';
    String technicianName = 'Technician';

    final provider = await AppServices.provider.getProvider(
      booking.providerId,
    );

    if (provider != null &&
        provider.businessName.trim().isNotEmpty) {
      providerName = provider.businessName;
    }

    if (booking.technicianId.trim().isNotEmpty) {
      final technicianSnapshot = await FirebaseFirestore
          .instance
          .collection('providers')
          .doc(booking.providerId)
          .collection('technicians')
          .doc(booking.technicianId)
          .get();

      if (technicianSnapshot.exists) {
        final data = technicianSnapshot.data();
        final name = data?['name']?.toString().trim();

        if (name != null && name.isNotEmpty) {
          technicianName = name;
        }
      }
    }

    return _BookingDisplayDetails(
      providerName: providerName,
      technicianName: technicianName,
    );
  }

  // =========================================================
  // BOOKING DETAIL ROW
  // =========================================================

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: AppTheme.primary,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // JOURNEY TRACKING
  // =========================================================

  Widget _journeyTrackingCard({
    required BookingModel booking,
    required String technicianName,
  }) {
    final distanceKm = booking.distanceKm;
    final etaMinutes = booking.etaMinutes;
    final updatedAt = booking.locationUpdatedAt;

    // Only use a recent ETA for the arrival-soon message.
    // This is an estimate, not confirmation of arrival.
    final updateAge = updatedAt == null
        ? null
        : DateTime.now().difference(updatedAt);

    final etaIsRecent = updateAge != null &&
        !updateAge.isNegative &&
        updateAge <= const Duration(minutes: 3);

    final arrivingSoon = booking.trackingActive &&
        etaIsRecent &&
        etaMinutes != null &&
        etaMinutes >= 1 &&
        etaMinutes <= 3;

    final etaIsStale = updatedAt != null && !etaIsRecent;

    String updatedText;

    if (updatedAt == null) {
      updatedText = 'Waiting for the latest location update...';
    } else {
      final localUpdatedAt = updatedAt.toLocal();

      final difference = DateTime.now().difference(
        localUpdatedAt,
      );

      if (difference.inMinutes < 1) {
        updatedText = 'Location updated just now';
      } else if (difference.inMinutes < 60) {
        updatedText =
        'Location updated ${difference.inMinutes} min ago';
      } else {
        updatedText =
        'Last updated at ${_formatTime(localUpdatedAt)}';
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.directions_car_outlined,
                    color: AppTheme.primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        arrivingSoon
                            ? '$technicianName is arriving soon'
                            : '$technicianName is on the way',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        booking.trackingActive
                            ? 'Journey tracking is active'
                            : 'Showing latest journey information',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(),

            if (arrivingSoon) ...[
              const SizedBox(height: 12),

              Text(
                'Arriving soon — approximately $etaMinutes min away',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],

            if (etaIsStale) ...[
              const SizedBox(height: 12),

              const Text(
                'The latest ETA may be outdated. '
                    'Waiting for a new location update.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _journeyMetric(
                    icon: Icons.route_outlined,
                    value: distanceKm == null
                        ? '--'
                        : '${distanceKm.toStringAsFixed(1)} km',
                    label: 'Road distance',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _journeyMetric(
                    icon: Icons.timer_outlined,
                    value: etaMinutes == null
                        ? '--'
                        : '~$etaMinutes min',
                    label: 'Estimated arrival',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                const Icon(
                  Icons.location_searching,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    updatedText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _journeyMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primary,
          ),

          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // READ-ONLY PROBLEM DETAILS AFTER BOOKING SUBMISSION
  // =========================================================

  // Customers may cancel their own pending booking,
  // but cannot change descriptions or photos after submission.
  bool _canCancelPendingBooking(BookingModel booking) =>
      booking.status == BookingStatus.pending &&
          FirebaseAuth.instance.currentUser?.uid == booking.customerId;

  // =========================================================
  // READ-ONLY PHOTO DISPLAY
  // =========================================================

  Widget _photoTile({
    required String url,
  }) {
    return SizedBox(
      width: 88,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.border,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.broken_image_outlined,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // INDIVIDUAL SERVICE REQUEST DETAILS
  // =========================================================

  Widget _problemDetailCard({
    required BookingProblemModel problem,
    required bool showPriority,
    required bool isPrimary,
    required int secondaryNumber,
    required bool numberSecondary,
  }) {
    final problemName = problem.serviceName.trim().isNotEmpty
        ? problem.serviceName
        : _formatServiceId(problem.serviceId);

    final description = problem.description.trim();

    final photos = problem.photoUrls
        .where((photo) => photo.trim().isNotEmpty)
        .toList();

    String priorityLabel = '';

    if (showPriority) {
      if (isPrimary) {
        priorityLabel = 'Primary Issue';
      } else if (numberSecondary) {
        priorityLabel = 'Secondary Issue $secondaryNumber';
      } else {
        priorityLabel = 'Secondary Issue';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        key: ValueKey(
          'problem-${problem.serviceId}',
        ),
        initiallyExpanded: !showPriority || isPrimary,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 2,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        shape: const Border(),
        collapsedShape: const Border(),

        leading: Icon(
          isPrimary
              ? Icons.build_circle_outlined
              : Icons.home_repair_service_outlined,
          color: AppTheme.primary,
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showPriority) ...[
              Text(
                priorityLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
            ],

            Text(
              problemName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description.isEmpty
                      ? 'No additional details provided.'
                      : description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Photos',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 5),

                if (photos.isEmpty)
                  const Text(
                    'No photos provided.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: photos
                        .map(
                          (url) => _photoTile(
                        url: url,
                      ),
                    )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // COMPATIBILITY WITH OLDER BOOKINGS
  // =========================================================

  Widget _legacyProblemCard(BookingModel booking) {
    final photos = booking.photoUrls
        .where((photo) => photo.trim().isNotEmpty)
        .toList();

    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),

        title: Text(
          booking.primaryIssue?.trim().isNotEmpty == true
              ? _formatServiceId(
            booking.primaryIssue!,
          )
              : booking.serviceIds.isNotEmpty
              ? _formatServiceId(
            booking.serviceIds.first,
          )
              : 'Service Request',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),

        childrenPadding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),

        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              booking.problemDescription.trim().isEmpty
                  ? 'No description provided.'
                  : booking.problemDescription,
            ),
          ),

          const SizedBox(height: 10),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Photos',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 5),

          if (photos.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No photos provided.',
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: photos
                    .map(
                      (url) => _photoTile(
                    url: url,
                  ),
                )
                    .toList(),
              ),
            ),

          if (booking.serviceIds.length > 1 &&
              booking.primaryIssue != null &&
              booking.primaryIssue!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Other Selected Services: ${_formatServices(
                  booking.serviceIds.where(
                        (service) =>
                    service != booking.primaryIssue,
                  ).toList(),
                )}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // COMPACT STATUS OVERVIEW
  // =========================================================

  String _statusDescription(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Waiting for the provider to confirm your request.';

      case BookingStatus.accepted:
        return 'Your booking has been accepted.';

      case BookingStatus.onTheWay:
        return 'Your technician is travelling to the service address.';

      case BookingStatus.arrived:
        return 'Your technician has arrived.';

      case BookingStatus.inProgress:
        return 'Your service is currently in progress.';

      case BookingStatus.completed:
        return 'The service has been marked as completed.';

      case BookingStatus.rejected:
        return 'This booking was rejected by the provider.';

      case BookingStatus.cancelled:
        return 'This booking has been cancelled.';

      case BookingStatus.expired:
        return 'This booking has expired because it was not confirmed in time.';
    }
  }

  Widget _statusOverviewCard(BookingModel booking) {
    final currentIndex = _steps.indexOf(
      booking.status,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CURRENT STATUS',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.primary,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    booking.status.label,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              _statusDescription(booking.status),
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),

            if (currentIndex >= 0) ...[
              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value:
                  (currentIndex + 1) / _steps.length,
                  backgroundColor: AppTheme.border,
                  color: AppTheme.primary,
                ),
              ),
            ],

            ExpansionTile(
              key: ValueKey(
                'timeline-${booking.id}',
              ),
              title: const Text(
                'View status timeline',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(
                bottom: 8,
              ),
              shape: const Border(),
              collapsedShape: const Border(),

              children: _steps.map((step) {
                final reached = _reached(
                  booking.status,
                  step,
                );

                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding:
                  const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),

                  leading: Icon(
                    reached
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 19,
                    color: reached
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),

                  title: Text(
                    step.label,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  void _goToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const CustomerNavigation(
          initialIndex: 0,
        ),
      ),
          (route) => false,
    );
  }

  void _goToBookings(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const CustomerNavigation(
          initialIndex: 1,
        ),
      ),
          (route) => false,
    );
  }

  // =========================================================
  // CANCEL PENDING BOOKING
  // =========================================================

  Future<void> _cancelPendingBooking(
      BookingModel booking,
      ) async {
    if (_cancellingBooking ||
        !_canCancelPendingBooking(booking)) {
      return;
    }

    final confirmed =
    await showHomeAssistConfirmationDialog(
      context: context,
      title: 'Cancel Booking?',
      message:
      'Do you want to cancel this booking request? '
          'The provider will no longer be able to accept it. '
          'The booking will remain in your history.',
      confirmLabel: 'Cancel Booking',
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _cancellingBooking = true;
    });

    try {
      await AppServices.booking
          .cancelPendingBookingForCustomer(
        bookingId: booking.id,
      );

      if (!mounted) return;

      await showHomeAssistSuccessDialog(
        context: context,
        title: 'Booking Cancelled',
        message:
        'Your pending booking has been cancelled. '
            'The reserved appointment time has been released.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'CUSTOMER BOOKING CANCELLATION ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      await showHomeAssistMessageDialog(
        context: context,
        title: 'Unable to Cancel Booking',
        message:
        'This booking could not be cancelled. '
            'It may have been updated by the provider, '
            'or access may be restricted. '
            'Please refresh and try again.',
        type: HomeAssistMessageType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _cancellingBooking = false;
        });
      }
    }
  }

  // =========================================================
  // REPORT AN ISSUE
  // =========================================================

  Future<void> _report(
      BuildContext context,
      BookingModel booking,
      ) async {
    // The report must belong to the signed-in booking customer.
    // Firestore security rules must enforce this as well.
    final signedInUser =
        FirebaseAuth.instance.currentUser;

    if (signedInUser == null ||
        signedInUser.uid != booking.customerId) {
      await showHomeAssistMessageDialog(
        context: context,
        title: 'Unable to Report Issue',
        message:
        'Only the booking customer can report an issue.',
        type: HomeAssistMessageType.warning,
      );
      return;
    }

    const reportReasons = <String>[
      'Technician did not arrive',
      'Technician is significantly late',
      'Unable to contact provider or technician',
      'Service quality concern',
      'Unprofessional behaviour',
      'Other booking issue',
    ];

    final formKey = GlobalKey<FormState>();

    String? selectedReason;
    String reportDescription = '';

    final reportDetails =
    await showDialog<Map<String, String>>(
      context: context,

      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),

            title: const Text(
              'Report an Issue',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),

            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Describe a problem with this booking. '
                            'HomeAssist administration will review the report.',
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: selectedReason,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                        ),

                        items: reportReasons.map((reason) {
                          return DropdownMenuItem<String>(
                            value: reason,
                            child: Text(
                              reason,
                              overflow:
                              TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),

                        onChanged: (value) {
                          setDialogState(() {
                            selectedReason = value;
                          });
                        },

                        validator: (value) => value == null
                            ? 'Please select a reason.'
                            : null,
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 1000,

                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Explain what happened.',
                          alignLabelWithHint: true,
                        ),

                        onChanged: (value) {
                          reportDescription = value;
                        },

                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please describe the issue.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            actions: [
              OutlinedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cancel'),
              ),

              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }

                  Navigator.of(dialogContext).pop({
                    'subject': selectedReason!,
                    'description':
                    reportDescription.trim(),
                  });
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                ),

                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );

    if (reportDetails == null || !context.mounted) {
      return;
    }

    try {
      await AppServices.reports.createReport(
        reporterId: signedInUser.uid,
        providerId: booking.providerId,
        bookingId: booking.id,
        subject: reportDetails['subject']!,
        description: reportDetails['description']!,
      );

      if (context.mounted) {
        await showHomeAssistSuccessDialog(
          context: context,
          title: 'Report Submitted!',
          message:
          'Your report has been submitted '
              'to HomeAssist administration for review.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'REPORT SUBMISSION ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (context.mounted) {
        await showHomeAssistMessageDialog(
          context: context,
          title: 'Unable to Submit Report',
          message:
          'Unable to submit the report. '
              'Please try again.',
          type: HomeAssistMessageType.error,
        );
      }
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Booking Details',
        ),
      ),

      body: StreamBuilder<BookingModel?>(
        stream: _bookingStream,

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load booking details.',
              ),
            );
          }

          final booking = snapshot.data;

          if (booking == null) {
            return const Center(
              child: Text(
                'Booking not found.',
              ),
            );
          }

          final primaryIndex =
          booking.problemDetails.indexWhere(
                (problem) => problem.isPrimary,
          );

          final selectedPrimaryIndex =
          primaryIndex < 0 ? 0 : primaryIndex;

          final hasMultipleProblems =
              booking.problemDetails.length > 1;

          return FutureBuilder<_BookingDisplayDetails>(
            future: _loadDisplayDetails(booking),

            builder: (context, detailsSnapshot) {
              final details = detailsSnapshot.data;

              final providerName =
                  details?.providerName ?? 'Loading...';

              final technicianName =
                  details?.technicianName ?? 'Loading...';

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  24,
                ),

                children: [
                  // Current status overview.
                  _statusOverviewCard(booking),

                  // Display ETA while technician is on the way.
                  if (booking.status ==
                      BookingStatus.onTheWay) ...[
                    const SizedBox(height: 12),

                    _journeyTrackingCard(
                      booking: booking,
                      technicianName: technicianName,
                    ),
                  ],

                  const SizedBox(height: 18),

                  const Text(
                    'Booking Summary',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        4,
                      ),

                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                        children: [
                          _detailRow(
                            icon: Icons.storefront_outlined,
                            label: 'Service Provider',
                            value: providerName,
                          ),

                          _detailRow(
                            icon:
                            Icons.calendar_month_outlined,
                            label: 'Appointment',
                            value:
                            '${_formatDate(booking.appointmentStart)} · '
                                '${_formatTime(booking.appointmentStart)} - '
                                '${_formatTime(booking.appointmentEnd)}',
                          ),

                          _detailRow(
                            icon:
                            Icons.home_repair_service_outlined,
                            label: 'Services',
                            value: _formatServices(
                              booking.serviceIds,
                            ),
                          ),

                          ExpansionTile(
                            key: ValueKey(
                              'more-info-${booking.id}',
                            ),

                            tilePadding: EdgeInsets.zero,
                            childrenPadding:
                            const EdgeInsets.only(
                              top: 6,
                            ),

                            shape: const Border(),
                            collapsedShape: const Border(),

                            title: const Text(
                              'Technician & location details',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),

                            children: [
                              _detailRow(
                                icon: Icons.engineering_outlined,
                                label: 'Assigned Technician',
                                value: technicianName,
                              ),

                              _detailRow(
                                icon:
                                Icons.location_on_outlined,
                                label: 'Service Address',
                                value: booking.address,
                              ),

                              if (booking.gasBrandPreference !=
                                  null &&
                                  booking.gasBrandPreference!
                                      .trim()
                                      .isNotEmpty)
                                _detailRow(
                                  icon: Icons
                                      .local_fire_department_outlined,
                                  label: 'Gas Brand Preference',
                                  value:
                                  booking.gasBrandPreference!,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Service Requests',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Read-only individual problem details.
                  if (booking.problemDetails.isNotEmpty)
                    for (var i = 0;
                    i < booking.problemDetails.length;
                    i++)
                      _problemDetailCard(
                        problem: booking.problemDetails[i],
                        showPriority: hasMultipleProblems,
                        isPrimary:
                        i == selectedPrimaryIndex,
                        secondaryNumber:
                        i < selectedPrimaryIndex
                            ? i + 1
                            : i,
                        numberSecondary:
                        booking.problemDetails.length >
                            2,
                      )
                  else
                    _legacyProblemCard(booking),

                  // Review is available after completion.
                  if (booking.status ==
                      BookingStatus.completed) ...[
                    const SizedBox(height: 12),

                    StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('reviews')
                          .doc(booking.id)
                          .snapshots(),

                      builder: (context, reviewSnapshot) {
                        final alreadyReviewed =
                            reviewSnapshot.data?.exists ??
                                false;

                        final canReview =
                            reviewSnapshot.hasData &&
                                !reviewSnapshot.hasError &&
                                !alreadyReviewed;

                        return ElevatedButton.icon(
                          onPressed: canReview
                              ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CustomerReviewPage(
                                      booking: booking,
                                    ),
                              ),
                            );
                          }
                              : null,

                          icon: Icon(
                            alreadyReviewed
                                ? Icons.check_circle_outline
                                : Icons.star_outline,
                          ),

                          label: Text(
                            alreadyReviewed
                                ? 'Already Reviewed'
                                : reviewSnapshot.hasError
                                ? 'Review Unavailable'
                                : reviewSnapshot.hasData
                                ? 'Rate This Service'
                                : 'Checking Review...',
                          ),

                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor:
                            const Color(0xFFE5E7EB),
                            disabledForegroundColor:
                            const Color(0xFF6B7280),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Customer may cancel only a pending booking.
                  if (_canCancelPendingBooking(booking)) ...[
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: _cancellingBooking
                          ? null
                          : () =>
                          _cancelPendingBooking(booking),

                      icon: _cancellingBooking
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(
                        Icons.cancel_outlined,
                      ),

                      label: Text(
                        _cancellingBooking
                            ? 'Cancelling Booking...'
                            : 'Cancel Booking',
                      ),

                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ],

                  OutlinedButton.icon(
                    onPressed: () =>
                        _report(context, booking),
                    icon: const Icon(
                      Icons.report_outlined,
                    ),
                    label: const Text(
                      'Report an Issue',
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: () =>
                        _goToBookings(context),
                    icon: const Icon(
                      Icons.calendar_month_outlined,
                    ),
                    label: const Text(
                      'View My Bookings',
                    ),
                  ),

                  const SizedBox(height: 8),

                  OutlinedButton.icon(
                    onPressed: () =>
                        _goToHome(context),
                    icon: const Icon(
                      Icons.home_outlined,
                    ),
                    label: const Text(
                      'Back to Home',
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BookingDisplayDetails {
  final String providerName;
  final String technicianName;

  const _BookingDisplayDetails({
    required this.providerName,
    required this.technicianName,
  });
}
