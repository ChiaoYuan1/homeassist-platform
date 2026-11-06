import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_enums.dart';
import '../../models/booking_model.dart';
import '../../services/app_services.dart';
import '../../services/route_eta_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/homeassist_action_dialog.dart';

class TechnicianJobDetailPage extends StatefulWidget {
  final String bookingId;

  const TechnicianJobDetailPage({super.key, required this.bookingId});

  @override
  State<TechnicianJobDetailPage> createState() => _TechnicianJobDetailPageState();
}

class _TechnicianJobDetailPageState extends State<TechnicianJobDetailPage> {
  bool _updating = false;
  bool _previewingRoute = false;
  bool _editingProblem = false;
  String? _editingServiceId;
  static const _progressSteps = <BookingStatus>[
    BookingStatus.accepted, BookingStatus.onTheWay, BookingStatus.arrived,
    BookingStatus.inProgress, BookingStatus.completed,
  ];
  RouteEtaResult? _routePreview;
  String? _routePreviewBookingId;

  String? _resumeAttemptedBookingId;

  BookingStatus? _next(BookingStatus status) {
    switch (status) {
      case BookingStatus.accepted:
        return BookingStatus.onTheWay;

      case BookingStatus.onTheWay:
        return BookingStatus.arrived;

      case BookingStatus.arrived:
        return BookingStatus.inProgress;

      case BookingStatus.inProgress:
        return BookingStatus.completed;

      default:
        return null;
    }
  }

  String _buttonText(BookingStatus status) {
    switch (status) {
      case BookingStatus.accepted:
        return 'Start Journey';

      case BookingStatus.onTheWay:
        return "I've Arrived";

      case BookingStatus.arrived:
        return 'Start Service';

      case BookingStatus.inProgress:
        return 'Complete Service';

      default:
        return '';
    }
  }

  IconData _buttonIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.accepted:
        return Icons.directions_car_outlined;

      case BookingStatus.onTheWay:
        return Icons.location_on_outlined;

      case BookingStatus.arrived:
        return Icons.build_outlined;

      case BookingStatus.inProgress:
        return Icons.check_circle_outline;

      default:
        return Icons.arrow_forward;
    }
  }

  // =====================================================
  // START JOURNEY
  // =====================================================

  Future<void> _startJourney(BookingModel booking) async {
    if (_updating) {
      return;
    }

    setState(() {
      _updating = true;
    });

    try {
      await AppServices.journeyTracking.startJourney(booking);

      if (!mounted) {
        return;
      }

      await showHomeAssistSuccessDialog(
        context: context,
        title: 'Journey Started!',
        message: 'Journey tracking is active. '
            'The estimated arrival time will be updated for the customer.',
      );
    } catch (e) {
      debugPrint('Unable to start journey: $e');

      if (!mounted) {
        return;
      }

      await showHomeAssistMessageDialog(
        context: context,
        title: 'Unable to Start Journey',
        message: 'Journey tracking could not be started. '
            'Please check the location permissions and try again.',
        type: HomeAssistMessageType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  // =====================================================
  // RESUME JOURNEY IF APP/PAGE WAS REOPENED
  // =====================================================

  void _ensureJourneyTracking(BookingModel booking) {
    if (_updating) {
      return;
    }

    if (booking.status != BookingStatus.onTheWay) {
      if (_resumeAttemptedBookingId == booking.id) {
        _resumeAttemptedBookingId = null;
      }

      return;
    }

    final tracking = AppServices.journeyTracking;

    if (tracking.isTracking && tracking.activeBookingId == booking.id) {
      return;
    }

    if (_resumeAttemptedBookingId == booking.id) {
      return;
    }

    _resumeAttemptedBookingId = booking.id;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await tracking.resumeJourney(booking);
      } catch (e) {
        debugPrint('Unable to resume journey tracking: $e');

        if (!mounted) {
          return;
        }

        await showHomeAssistMessageDialog(
          context: context,
          title: 'Journey Tracking Unavailable',
          message: 'Journey tracking could not be resumed. '
              'Please check the location permissions and try again.',
          type: HomeAssistMessageType.error,
        );
      }
    });
  }

  // =====================================================
  // NORMAL STATUS UPDATE
  // =====================================================


  Future<void> _updateStatus({
    required BookingModel booking,
    required BookingStatus status,
  }) async {
    if (_updating) {
      return;
    }

    if (status == BookingStatus.completed) {
      final confirmed = await showHomeAssistConfirmationDialog(
        context: context,
        title: 'Complete Service?',
        message:
        'Please confirm that the service has been completed.',
        confirmLabel: 'Complete',
      );

      if (!confirmed || !mounted) {
        return;
      }
    }

    setState(() {
      _updating = true;
    });

    try {
      await AppServices.booking.updateBookingStatus(
        bookingId: booking.id,
        status: status,
      );

      // Stop local GPS tracking once the technician arrives.
      if (status == BookingStatus.arrived) {
        await AppServices.journeyTracking.stopLocalTracking();
      }

      if (!mounted) {
        return;
      }

      if (status == BookingStatus.completed) {
        await showHomeAssistSuccessDialog(
          context: context,
          title: 'Service Completed!',
          message:
          'The job has been marked as completed. '
              'The customer can now review the service.',
        );
      } else {
        await showHomeAssistSuccessDialog(
          context: context,
          title: 'Job Status Updated',
          message: 'Job updated to ${status.label}.',
        );
      }
    } catch (error) {
      debugPrint('Unable to update job: $error');

      if (!mounted) {
        return;
      }

      await showHomeAssistMessageDialog(
        context: context,
        title: 'Unable to Update Job',
        message: 'The job status could not be updated. '
            'Please try again.',
        type: HomeAssistMessageType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: StreamBuilder<BookingModel?>(
        stream: AppServices.booking.watchBooking(widget.bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to load job.\n${snapshot.error}',
                    textAlign: TextAlign.center),
              ),
            );
          }

          final booking = snapshot.data;
          if (booking == null) {
            return const Center(child: Text('Job not found.'));
          }

          _ensureJourneyTracking(booking);
          final nextStatus = _next(booking.status);
          final mainIndex = booking.problemDetails.indexWhere((p) => p.isPrimary);
          final mainProblemIndex = mainIndex >= 0 ? mainIndex : 0;
          final multipleProblems = booking.problemDetails.length > 1;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _statusCard(booking),
              if (nextStatus != null) ...[
                const SizedBox(height: 12),
                _actionButton(booking: booking, nextStatus: nextStatus),
              ],
              const SizedBox(height: 18),
              _sectionTitle('Job Summary'),
              const SizedBox(height: 8),
              _appointmentCard(booking),
              const SizedBox(height: 10),
              Card(
                child: ExpansionTile(
                  key: ValueKey('route-${booking.id}'),
                  initiallyExpanded: booking.status == BookingStatus.accepted ||
                      booking.status == BookingStatus.onTheWay,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  leading: const Icon(Icons.location_on_outlined,
                      color: AppTheme.primary),
                  title: const Text('Service location & navigation',
                      style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    booking.address.trim().isEmpty
                        ? 'Address unavailable' : booking.address,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12,
                        color: AppTheme.textSecondary),
                  ),
                  children: [_locationCard(booking)],
                ),
              ),
              const SizedBox(height: 18),
              _sectionTitle('Service Requests'),
              const SizedBox(height: 8),
              if (booking.problemDetails.isNotEmpty)
                for (var i = 0; i < booking.problemDetails.length; i++)
                  _problemCard(
                    booking: booking,
                    problem: booking.problemDetails[i],
                    showPriority: multipleProblems,
                    isPrimary: i == mainProblemIndex,
                    secondaryNumber: i < mainProblemIndex ? i + 1 : i,
                    numberSecondary: booking.problemDetails.length > 2,
                  )
              else
                _legacyProblemCard(booking),
              if (booking.gasBrandPreference != null &&
                  booking.gasBrandPreference!.trim().isNotEmpty)
                Card(
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.local_fire_department_outlined,
                        color: AppTheme.primary),
                    title: const Text('Gas Brand Preference'),
                    subtitle: Text(booking.gasBrandPreference!),
                  ),
                ),
              if (booking.status == BookingStatus.completed)
                _finalStatusCard(icon: Icons.check_circle,
                    message: 'Service Completed', success: true),
              if (booking.status == BookingStatus.rejected)
                _finalStatusCard(icon: Icons.cancel_outlined,
                    message: 'This booking was rejected.'),
              if (booking.status == BookingStatus.cancelled)
                _finalStatusCard(icon: Icons.event_busy_outlined,
                    message: 'This booking was cancelled.'),
              if (booking.status == BookingStatus.expired)
                _finalStatusCard(icon: Icons.schedule_outlined,
                    message: 'This booking request has expired.'),
              if (booking.status == BookingStatus.pending)
                _finalStatusCard(icon: Icons.info_outline,
                    message: 'This booking must be accepted before the job can begin.'),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
    );
  }

  String _statusDescription(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Waiting for the provider to accept this booking.';
      case BookingStatus.accepted:
        return 'The job is ready. Preview the route before starting your journey.';
      case BookingStatus.onTheWay:
        return 'You are travelling to the customer. Journey tracking is active.';
      case BookingStatus.arrived:
        return 'You have arrived at the service location.';
      case BookingStatus.inProgress:
        return 'The service is currently in progress.';
      case BookingStatus.completed:
        return 'The service has been completed.';
      case BookingStatus.rejected:
        return 'The booking was rejected.';
      case BookingStatus.cancelled:
        return 'The booking was cancelled.';
      case BookingStatus.expired:
        return 'The booking request expired.';
    }
  }

  Widget _statusCard(BookingModel booking) {
    final current = _progressSteps.indexOf(booking.status);
    final terminated = booking.status == BookingStatus.rejected ||
        booking.status == BookingStatus.cancelled ||
        booking.status == BookingStatus.expired;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CURRENT STATUS',
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.check_circle_outline, color: AppTheme.primary),
              const SizedBox(width: 9),
              Expanded(child: Text(booking.status.label,
                  style: const TextStyle(fontSize: 19,
                      fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 5),
            Text(_statusDescription(booking.status),
                style: const TextStyle(fontSize: 13,
                    color: AppTheme.textSecondary, height: 1.35)),
            if (current >= 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: (current + 1) / _progressSteps.length,
                  backgroundColor: AppTheme.border,
                  color: AppTheme.primary,
                ),
              ),
            ],
            ExpansionTile(
              key: ValueKey('status-timeline-${booking.id}'),
              title: const Text('View status timeline',
                  style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600)),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              shape: const Border(),
              collapsedShape: const Border(),
              children: _progressSteps.map((step) {
                final reached = !terminated &&
                    current >= _progressSteps.indexOf(step);
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Icon(
                    reached ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 19,
                    color: reached ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                  title: Text(step.label,
                      style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appointmentCard(BookingModel booking) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(booking.appointmentStart);
    final start = TimeOfDay.fromDateTime(booking.appointmentStart).format(context);
    final end = TimeOfDay.fromDateTime(booking.appointmentEnd).format(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.calendar_month_outlined,
                color: AppTheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Appointment',
                    style: TextStyle(fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('$start - $end',
                    style: const TextStyle(fontSize: 13)),
              ],
            )),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // SERVICE LOCATION + JOURNEY ETA
  // =====================================================

  Future<void> _previewRoute(BookingModel booking) async {
    if (_previewingRoute || _updating) {
      return;
    }

    setState(() {
      _previewingRoute = true;
      _routePreview = null;
      _routePreviewBookingId = booking.id;
    });

    try {
      final result = await AppServices.journeyTracking.previewRoute(booking);

      if (!mounted || _routePreviewBookingId != booking.id) {
        return;
      }

      setState(() {
        _routePreview = result;
      });
    } catch (e) {
      debugPrint('Unable to preview route: $e');

      if (!mounted || _routePreviewBookingId != booking.id) {
        return;
      }

      await showHomeAssistMessageDialog(
        context: context,
        title: 'Route Preview Unavailable',
        message: 'The route estimate could not be calculated. '
            'Please try again.',
        type: HomeAssistMessageType.error,
      );
    } finally {
      if (mounted && _routePreviewBookingId == booking.id) {
        setState(() {
          _previewingRoute = false;
        });
      }
    }
  }

  Future<void> _navigateToCustomer(BookingModel booking) async {
    final latitude = booking.latitude;
    final longitude = booking.longitude;

    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        (latitude == 0 && longitude == 0)) {
      if (!mounted) {
        return;
      }

      await showHomeAssistMessageDialog(
        context: context,
        title: 'Invalid Customer Location',
        message: 'The customer location is unavailable or invalid. '
            'Navigation cannot be started.',
        type: HomeAssistMessageType.warning,
      );

      return;
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        await showHomeAssistMessageDialog(
          context: context,
          title: 'Unable to Open Navigation',
          message: 'The navigation application could not be opened. '
              'Please try again.',
          type: HomeAssistMessageType.error,
        );
      }
    } catch (e) {
      debugPrint('Unable to open navigation: $e');

      if (!mounted) {
        return;
      }

      await showHomeAssistMessageDialog(
        context: context,
        title: 'Unable to Open Navigation',
        message: 'The navigation application could not be opened. '
            'Please try again.',
        type: HomeAssistMessageType.error,
      );
    }
  }

  Widget _locationCard(BookingModel booking) {
    final isOnTheWay = booking.status == BookingStatus.onTheWay;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_pin, color: AppTheme.error, size: 30),

          const SizedBox(height: 8),

          Text(
            booking.address.isEmpty ? 'No address provided.' : booking.address,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 6),

          if (booking.status == BookingStatus.accepted) ...[
            const SizedBox(height: 14),

            const Divider(),

            const SizedBox(height: 10),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 18,
                  color: AppTheme.primary,
                ),
                SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'Preview the driving distance and ETA '
                        'before starting your journey.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ],

          if (isOnTheWay) ...[
            const SizedBox(height: 14),

            const Divider(),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  booking.trackingActive
                      ? Icons.location_searching
                      : Icons.location_disabled_outlined,
                  color: booking.trackingActive
                      ? AppTheme.success
                      : AppTheme.warning,
                  size: 20,
                ),

                const SizedBox(width: 8),

                Text(
                  booking.trackingActive
                      ? 'Journey tracking active'
                      : 'Journey tracking inactive',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: booking.trackingActive
                        ? AppTheme.success
                        : AppTheme.warning,
                  ),
                ),
              ],
            ),

            if (booking.etaMinutes != null || booking.distanceKm != null) ...[
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _journeyMetric(
                      icon: Icons.timer_outlined,
                      label: 'ETA',
                      value: booking.etaMinutes == null
                          ? '--'
                          : '~${booking.etaMinutes} min',
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _journeyMetric(
                      icon: Icons.route_outlined,
                      label: 'Distance',
                      value: booking.distanceKm == null
                          ? '--'
                          : '${booking.distanceKm!.toStringAsFixed(1)} km',
                    ),
                  ),
                ],
              ),
            ],

            if (booking.locationUpdatedAt != null) ...[
              const SizedBox(height: 12),

              Text(
                'Last updated: '
                    '${_formatUpdatedTime(booking.locationUpdatedAt!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],

          const SizedBox(height: 16),

          if (booking.status == BookingStatus.accepted) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _previewingRoute || _updating
                    ? null
                    : () => _previewRoute(booking),
                icon: _previewingRoute
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.route_outlined),
                label: Text(
                  _previewingRoute ? 'Calculating Route...' : 'Preview Route',
                ),
              ),
            ),

            if (_routePreview != null &&
                _routePreviewBookingId == booking.id) ...[
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _journeyMetric(
                      icon: Icons.timer_outlined,
                      label: 'Estimated Time',
                      value: '~${_routePreview!.etaMinutes} min',
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _journeyMetric(
                      icon: Icons.route_outlined,
                      label: 'Road Distance',
                      value:
                      '${_routePreview!.distanceKm.toStringAsFixed(1)} km',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                'Route estimate only. '
                    'Journey tracking has not started.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],

            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToCustomer(booking),
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Navigate to Customer'),
            ),
          ),

          if ({
            BookingStatus.arrived,
            BookingStatus.inProgress,
            BookingStatus.completed,
          }.contains(booking.status)) ...[
            const SizedBox(height: 14),

            const Divider(),

            const SizedBox(height: 8),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 19,
                  color: AppTheme.success,
                ),
                SizedBox(width: 7),
                Text(
                  'Destination reached',
                  style: TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _journeyMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),

          const SizedBox(height: 5),

          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),

          const SizedBox(height: 2),

          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatUpdatedTime(DateTime dateTime) {
    return TimeOfDay.fromDateTime(dateTime.toLocal()).format(context);
  }

  bool _canEditProblem(BookingModel booking) => {
    BookingStatus.accepted,
    BookingStatus.onTheWay,
    BookingStatus.arrived,
    BookingStatus.inProgress,
  }.contains(booking.status);

  // Checks the Firebase technician account, not merely the client-side UI.
  // Firestore rules must independently enforce the same assignment.
  Future<String> _requireAssignedTechnician(BookingModel booking) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || booking.technicianId.trim().isEmpty) {
      throw StateError('An assigned technician must be signed in.');
    }
    final document = await FirebaseFirestore.instance
        .collection('providers')
        .doc(booking.providerId)
        .collection('technicians')
        .doc(booking.technicianId)
        .get();
    if (!document.exists || document.data()?['authUid'] != user.uid) {
      throw StateError('Only the assigned technician may edit this job.');
    }
    return user.uid;
  }

  // Update a single service problem without replacing the other problems,
  // selected services, technician assignment, or appointment information.
  Future<void> _saveProblemChange({
    required BookingModel booking,
    required BookingProblemModel problem,
    String? description,
    String? photoUrl,
    int? photoIndex,
  }) async {
    await _requireAssignedTechnician(booking);
    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(booking.id);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(bookingRef);
      if (!snapshot.exists) throw StateError('Booking no longer exists.');
      final data = snapshot.data()!;
      if (data['providerId'] != booking.providerId ||
          data['technicianId'] != booking.technicianId) {
        throw StateError('The job assignment has changed.');
      }
      const editableStatuses = {'accepted', 'onTheWay', 'arrived', 'inProgress'};
      if (!editableStatuses.contains(data['status'])) {
        throw StateError('This job can no longer be edited.');
      }
      final raw = data['problemDetails'];
      if (raw is! List) throw StateError('This booking has no individual problems.');
      final updated = raw.map((entry) =>
      Map<String, dynamic>.from(entry as Map)).toList();
      final index = updated.indexWhere((entry) => entry['serviceId'] == problem.serviceId);
      if (index < 0) throw StateError('The selected problem no longer exists.');
      final current = updated[index];
      if (description != null) current['description'] = description;
      if (photoUrl != null) {
        final photos = (current['photoUrls'] as List?)
            ?.map((item) => item.toString()).toList() ?? <String>[];
        if (photoIndex == null) {
          photos.add(photoUrl);
        } else {
          if (photoIndex < 0 || photoIndex >= photos.length) {
            throw StateError('The selected picture has changed. Reload the job.');
          }
          photos[photoIndex] = photoUrl;
        }
        current['photoUrls'] = photos;
      }
      transaction.update(bookingRef, {
        'problemDetails': updated,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _editDescription(
      BookingModel booking,
      BookingProblemModel problem,
      ) async {
    if (_editingProblem || _updating || !_canEditProblem(booking)) return;
    String editedValue = problem.description;
    final newDescription = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Description'),
        content: TextFormField(
          initialValue: problem.description,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 1000,
          onChanged: (value) => editedValue = value,
          decoration: const InputDecoration(
            hintText: 'Describe the service issue...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, editedValue.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted || newDescription == null ||
        newDescription == problem.description.trim()) return;

    setState(() { _editingProblem = true; _editingServiceId = problem.serviceId; });
    try {
      await _saveProblemChange(booking: booking, problem: problem,
          description: newDescription);
      if (!mounted) return;
      await showHomeAssistSuccessDialog(
        context: context,
        title: 'Description Updated',
        message: 'The customer will see the updated description.',
      );
    } catch (error) {
      debugPrint('Unable to edit problem description: $error');
      if (!mounted) return;
      await showHomeAssistMessageDialog(
        context: context, title: 'Unable to Edit Description',
        message: 'The description could not be saved. '
            'Check the technician assignment and Firestore permissions.',
        type: HomeAssistMessageType.error,
      );
    } finally {
      if (mounted) setState(() { _editingProblem = false; _editingServiceId = null; });
    }
  }

  Future<void> _editPicture(
      BookingModel booking,
      BookingProblemModel problem,
      int? photoIndex,
      ) async {
    if (_editingProblem || _updating || !_canEditProblem(booking)) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Picture'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source, maxWidth: 1600, imageQuality: 85,
      );
    } catch (error) {
      debugPrint('Unable to open image picker: $error');
      if (!mounted) return;
      await showHomeAssistMessageDialog(
        context: context, title: 'Unable to Select Picture',
        message: 'Please check camera or gallery permissions and try again.',
        type: HomeAssistMessageType.error,
      );
      return;
    }
    if (picked == null || !mounted) return;

    setState(() { _editingProblem = true; _editingServiceId = problem.serviceId; });
    try {
      final uid = await _requireAssignedTechnician(booking);
      final token = await FirebaseAuth.instance.currentUser!.getIdTokenResult(true);
      if (token.claims?['role'] != 'authenticated') {
        throw StateError('This technician needs the Supabase authenticated claim.');
      }
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        throw StateError('The image must be between 1 byte and 10 MB.');
      }
      final lower = picked.name.toLowerCase();
      final String type;
      final String extension;
      if (lower.endsWith('.png')) {
        type = 'image/png'; extension = 'png';
      } else if (lower.endsWith('.webp')) {
        type = 'image/webp'; extension = 'webp';
      } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
        type = 'image/jpeg'; extension = 'jpg';
      } else {
        throw StateError('Only JPG, PNG and WebP images are supported.');
      }
      final safeService = problem.serviceId.replaceAll(
          RegExp(r'[^A-Za-z0-9_-]'), '_');
      // The first folder matches this technician's Firebase UID as required
      // by booking_photos_insert_own and booking_photos_select_own policies.
      final objectPath = '$uid/${booking.id}/technician-edits/'
          '$safeService/${DateTime.now().microsecondsSinceEpoch}.$extension';
      final bucket = Supabase.instance.client.storage.from('booking-photos');
      await bucket.uploadBinary(
        objectPath,
        bytes,
        fileOptions: FileOptions(contentType: type, upsert: false),
      );
      final url = await bucket.createSignedUrl(objectPath, 7 * 24 * 60 * 60);
      await _saveProblemChange(booking: booking, problem: problem,
          photoUrl: url, photoIndex: photoIndex);
      if (!mounted) return;
      await showHomeAssistSuccessDialog(
        context: context, title: 'Picture Updated',
        message: 'The picture has been updated for this service request.',
      );
    } catch (error) {
      debugPrint('Unable to update booking picture: $error');
      if (!mounted) return;
      await showHomeAssistMessageDialog(
        context: context, title: 'Unable to Edit Picture',
        message: 'The picture could not be updated. '
            'Check the technician Supabase claim and booking permissions.',
        type: HomeAssistMessageType.error,
      );
    } finally {
      if (mounted) setState(() { _editingProblem = false; _editingServiceId = null; });
    }
  }

  Widget _problemCard({
    required BookingModel booking,
    required BookingProblemModel problem,
    required bool showPriority,
    required bool isPrimary,
    required int secondaryNumber,
    required bool numberSecondary,
  }) {
    final name = problem.serviceName.trim().isNotEmpty
        ? problem.serviceName : _formatServiceName(problem.serviceId);
    final label = !showPriority ? '' : isPrimary
        ? 'Primary Issue' : numberSecondary
        ? 'Secondary Issue $secondaryNumber' : 'Secondary Issue';
    final allowed = _canEditProblem(booking);
    final updating = _editingProblem && _editingServiceId == problem.serviceId;
    final visiblePhotos = problem.photoUrls.asMap().entries
        .where((entry) => entry.value.trim().isNotEmpty).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        key: ValueKey('tech-problem-${booking.id}-${problem.serviceId}'),
        initiallyExpanded: !showPriority || isPrimary,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(isPrimary ? Icons.build_circle_outlined
            : Icons.home_repair_service_outlined, color: AppTheme.primary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showPriority) ...[
              Text(label, style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppTheme.primary)),
              const SizedBox(height: 3),
            ],
            Text(name, style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description',
                    style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 5),
                Text(problem.description.trim().isEmpty
                    ? 'No additional details provided.' : problem.description,
                    style: const TextStyle(fontSize: 14, height: 1.4)),
                if (allowed) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: _editingProblem ? null : () => _editDescription(booking, problem),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Description'),
                  ),
                ],
                const SizedBox(height: 10),
                const Text('Photos', style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                if (visiblePhotos.isEmpty)
                  const Text('No pictures provided.',
                      style: TextStyle(color: AppTheme.textSecondary,
                          fontSize: 13))
                else
                  SizedBox(
                    height: allowed ? 145 : 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: visiblePhotos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => SizedBox(
                        width: 98,
                        child: Column(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(visiblePhotos[index].value, width: 88,
                              height: 88, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 88, height: 88,
                                decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.border),
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                          if (allowed) TextButton(
                            onPressed: _editingProblem ? null
                                : () => _editPicture(booking, problem, visiblePhotos[index].key),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: const Text('Edit Picture',
                                style: TextStyle(fontSize: 11)),
                          ),
                        ]),
                      ),
                    ),
                  ),
                if (allowed) ...[
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: _editingProblem ? null
                        : () => _editPicture(booking, problem, null),
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 17),
                    label: const Text('Add Picture'),
                  ),
                ],
                if (updating) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legacyProblemCard(BookingModel booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.primaryIssue?.trim().isNotEmpty == true
                  ? _formatServiceName(booking.primaryIssue!)
                  : 'Service Request',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            Text(
              booking.problemDescription.trim().isEmpty
                  ? 'No additional description.'
                  : booking.problemDescription,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required BookingModel booking,
    required BookingStatus nextStatus,
  }) {
    if (_updating) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (booking.status == BookingStatus.accepted) {
            _startJourney(booking);

            return;
          }

          _updateStatus(booking: booking, status: nextStatus);
        },
        icon: Icon(_buttonIcon(booking.status)),
        label: Text(_buttonText(booking.status)),
      ),
    );
  }

  Widget _finalStatusCard({
    required IconData icon,
    required String message,
    bool success = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              icon,
              color: success ? AppTheme.success : AppTheme.textSecondary,
              size: 42,
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  String _formatServiceName(String value) {
    final cleaned = value.trim();

    if (cleaned.isEmpty) {
      return 'Service';
    }

    return cleaned
        .split('_')
        .map((word) {
      if (word.isEmpty) {
        return '';
      }

      return '${word[0].toUpperCase()}'
          '${word.substring(1)}';
    })
        .join(' ');
  }
}
