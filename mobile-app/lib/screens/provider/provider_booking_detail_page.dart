import 'package:flutter/material.dart';

import '../../core/app_enums.dart';
import '../../models/booking_model.dart';
import '../../models/provider_models.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/homeassist_action_dialog.dart';

/// Business-side booking details.
class ProviderBookingDetailPage extends StatefulWidget {
  final String bookingId;

  const ProviderBookingDetailPage({super.key, required this.bookingId});

  @override
  State<ProviderBookingDetailPage> createState() =>
      _ProviderBookingDetailPageState();
}

class _ProviderBookingDetailPageState extends State<ProviderBookingDetailPage> {
  bool _updating = false;

  Future<void> _status(BookingStatus status) async {
    if (_updating) return;
    setState(() => _updating = true);

    try {
      await AppServices.booking.updateBookingStatus(
        bookingId: widget.bookingId,
        status: status,
      );
      if (!mounted) return;

      await showHomeAssistSuccessDialog(
        context: context,
        title: status == BookingStatus.accepted
            ? 'Booking Accepted!'
            : status == BookingStatus.rejected
            ? 'Booking Rejected'
            : 'Booking Updated',
        message: 'Booking status has been updated to ${status.label}.',
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to update booking ${widget.bookingId}: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;

      await showHomeAssistMessageDialog(
        context: context,
        title: 'Unable to Update Booking',
        message: 'The booking status could not be updated. '
            'Please try again.',
        type: HomeAssistMessageType.error,
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      // A live stream keeps the business view up to date when the technician
      // changes the job status from a different device.
      body: StreamBuilder<BookingModel?>(
        stream: AppServices.booking.watchBooking(widget.bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('Unable to load booking ${widget.bookingId}: '
                '${snapshot.error}');
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to load booking. Please try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final booking = snapshot.data;
          if (booking == null) {
            return const Center(child: Text('Booking not found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _statusCard(booking),
              const SizedBox(height: 20),
              _sectionTitle('Appointment'),
              const SizedBox(height: 10),
              _appointmentCard(booking),
              const SizedBox(height: 20),
              _sectionTitle('Service Location'),
              const SizedBox(height: 10),
              _card(
                icon: Icons.location_on_outlined,
                text: booking.address.isEmpty
                    ? 'No address provided.'
                    : booking.address,
              ),
              const SizedBox(height: 20),
              _sectionTitle('Service Request'),
              const SizedBox(height: 10),
              if (booking.problemDetails.isNotEmpty)
                ...booking.problemDetails.map(_problemCard)
              else
                _oldBookingProblem(booking),
              if (booking.gasBrandPreference != null &&
                  booking.gasBrandPreference!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _card(
                  icon: Icons.local_fire_department_outlined,
                  text: 'Preferred gas brand: ${booking.gasBrandPreference}',
                ),
              ],
              if (booking.technicianId.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionTitle('Assigned Technician'),
                const SizedBox(height: 10),
                _technicianCard(booking),
              ],
              const SizedBox(height: 24),
              if ({
                BookingStatus.accepted,
                BookingStatus.onTheWay,
                BookingStatus.arrived,
                BookingStatus.inProgress,
                BookingStatus.completed,
              }.contains(booking.status)) ...[
                _sectionTitle('Job Progress'),
                const SizedBox(height: 10),
                _progressCard(booking),
              ],
              const SizedBox(height: 28),
              _actionArea(booking),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
  );

  Widget _statusCard(BookingModel booking) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.track_changes),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Current Status',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Chip(label: Text(booking.status.label)),
        ],
      ),
    ),
  );

  Widget _appointmentCard(BookingModel booking) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(booking.appointmentStart);
    final start = TimeOfDay.fromDateTime(booking.appointmentStart)
        .format(context);
    final end = TimeOfDay.fromDateTime(booking.appointmentEnd)
        .format(context);
    return _card(icon: Icons.calendar_month_outlined, text: '$date\n$start - $end');
  }

  Widget _card({required IconData icon, required String text}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }

  Widget _problemCard(BookingProblemModel problem) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    problem.serviceName.trim().isEmpty
                        ? 'Service'
                        : _formatServiceName(problem.serviceName),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (problem.isPrimary)
                  const Chip(
                    label: Text('Primary'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              problem.description.trim().isEmpty
                  ? 'No additional description.'
                  : problem.description,
            ),
            if (problem.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Photos', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 105,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: problem.photoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        problem.photoUrls[index],
                        width: 105,
                        height: 105,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 105,
                          height: 105,
                          alignment: Alignment.center,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _oldBookingProblem(BookingModel booking) {
    final primaryIssue = booking.primaryIssue?.trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              primaryIssue != null && primaryIssue.isNotEmpty
                  ? _formatServiceName(primaryIssue)
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

  String _formatServiceName(String value) => value
      .trim()
      .split('_')
      .map((word) => word.isEmpty
      ? ''
      : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  Widget _technicianCard(BookingModel booking) {
    return FutureBuilder<TechnicianModel?>(
      future: AppServices.technician.getTechnician(
        providerId: booking.providerId,
        technicianId: booking.technicianId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _card(
            icon: Icons.engineering_outlined,
            text: 'Loading technician...',
          );
        }
        if (snapshot.hasError) {
          return _card(
            icon: Icons.engineering_outlined,
            text: 'Unable to load technician.',
          );
        }
        final technician = snapshot.data;
        if (technician == null) {
          return _card(
            icon: Icons.engineering_outlined,
            text: 'Technician not found.',
          );
        }
        return _card(
          icon: Icons.engineering_outlined,
          text: technician.name.isEmpty ? 'Unnamed Technician' : technician.name,
        );
      },
    );
  }

  Widget _progressCard(BookingModel booking) {
    const steps = <BookingStatus>[
      BookingStatus.accepted,
      BookingStatus.onTheWay,
      BookingStatus.arrived,
      BookingStatus.inProgress,
      BookingStatus.completed,
    ];
    final activeIndex = steps.indexOf(booking.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < steps.length; index++) ...[
              Row(
                children: [
                  Icon(
                    index <= activeIndex
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: index <= activeIndex
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    size: 21,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      steps[index].label,
                      style: TextStyle(
                        fontWeight: index == activeIndex
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (index == activeIndex)
                    const Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              if (index < steps.length - 1) const SizedBox(height: 16),
            ],
            if (booking.status == BookingStatus.onTheWay &&
                (booking.etaMinutes != null || booking.distanceKm != null)) ...[
              const Divider(height: 30),
              Row(
                children: [
                  const Icon(Icons.route_outlined, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${booking.etaMinutes == null ? 'ETA unavailable' : 'ETA ~${booking.etaMinutes} min'}'
                          ' • '
                          '${booking.distanceKm == null ? 'Distance unavailable' : '${booking.distanceKm!.toStringAsFixed(1)} km'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (!booking.trackingActive) ...[
                const SizedBox(height: 8),
                const Text(
                  'Tracking is currently inactive. The last estimate may be outdated.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ],
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(Icons.visibility_outlined,
                    size: 18, color: AppTheme.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Monitoring only. The assigned technician updates job progress.',
                    style: TextStyle(
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

  Widget _actionArea(BookingModel booking) {
    if (_updating) {
      return const Center(child: CircularProgressIndicator());
    }
    if (booking.status == BookingStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _status(BookingStatus.rejected),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _status(BookingStatus.accepted),
              child: const Text('Accept Booking'),
            ),
          ),
        ],
      );
    }
    switch (booking.status) {
      case BookingStatus.completed:
        return const _FinalStatusMessage(
          icon: Icons.check_circle_outline,
          text: 'This service has been completed.',
        );
      case BookingStatus.rejected:
        return const _FinalStatusMessage(
          icon: Icons.cancel_outlined,
          text: 'This booking was rejected.',
        );
      case BookingStatus.cancelled:
        return const _FinalStatusMessage(
          icon: Icons.event_busy_outlined,
          text: 'This booking was cancelled.',
        );
      case BookingStatus.expired:
        return const _FinalStatusMessage(
          icon: Icons.schedule_outlined,
          text: 'This booking request expired because the appointment time '
              'passed before it was accepted.',
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _FinalStatusMessage extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FinalStatusMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
