import 'package:flutter/material.dart';

import '../../core/app_enums.dart';
import '../../models/booking_model.dart';
import '../../services/app_services.dart';
import 'technician_job_detail_page.dart';

class TechnicianJobsPage extends StatelessWidget {
  final String providerId;
  final String technicianId;
  final String technicianName;

  const TechnicianJobsPage({
    super.key,
    required this.providerId,
    required this.technicianId,
    required this.technicianName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Jobs')),
      body: StreamBuilder<List<BookingModel>>(
        stream: AppServices.booking.watchTechnicianBookings(
          providerId: providerId,
          technicianId: technicianId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load assigned jobs.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final bookings = snapshot.data ?? <BookingModel>[];
          final currentJobs = bookings.where((booking) => {
            BookingStatus.onTheWay,
            BookingStatus.arrived,
            BookingStatus.inProgress,
          }.contains(booking.status)).toList()..sort(_compareCurrentJobs);
          final upcomingJobs = bookings.where(
                (booking) => booking.status == BookingStatus.accepted,
          ).toList()..sort(
                (first, second) => first.appointmentStart.compareTo(second.appointmentStart),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              Text(
                'Welcome, $technicianName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'View assigned jobs and update service progress.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 28),
              if (currentJobs.isNotEmpty) ...[
                const _SectionHeading(label: 'CURRENT JOB', title: 'Job in Progress'),
                const SizedBox(height: 12),
                ...currentJobs.map((booking) => _JobCard(booking: booking)),
                const SizedBox(height: 28),
              ],
              const _SectionHeading(label: 'SCHEDULE', title: 'Upcoming Jobs'),
              const SizedBox(height: 12),
              if (upcomingJobs.isEmpty)
                const _EmptyJobsCard()
              else
                ...upcomingJobs.map((booking) => _JobCard(booking: booking)),
            ],
          );
        },
      ),
    );
  }
}

int _compareCurrentJobs(BookingModel first, BookingModel second) {
  int priority(BookingStatus status) {
    if (status == BookingStatus.inProgress) return 0;
    if (status == BookingStatus.arrived) return 1;
    if (status == BookingStatus.onTheWay) return 2;
    return 99;
  }
  final firstPriority = priority(first.status);
  final secondPriority = priority(second.status);
  if (firstPriority != secondPriority) return firstPriority - secondPriority;
  return first.appointmentStart.compareTo(second.appointmentStart);
}

class _SectionHeading extends StatelessWidget {
  final String label;
  final String title;
  const _SectionHeading({required this.label, required this.title});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      )),
      const SizedBox(height: 5),
      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
      )),
    ],
  );
}

class _JobCard extends StatelessWidget {
  final BookingModel booking;
  const _JobCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(booking.appointmentStart);
    final startTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(booking.appointmentStart),
    );
    final endTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(booking.appointmentEnd),
    );
    final services = booking.serviceIds.map(_formatServiceName)
        .where((name) => name.isNotEmpty).join(', ');
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => TechnicianJobDetailPage(bookingId: booking.id),
        )),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(
                    services.isEmpty ? 'Service Job' : services,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  )),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(booking.status.label, style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.event_outlined,
                text: '$date • $startTime – $endTime',
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.location_on_outlined,
                text: booking.address.trim().isEmpty
                    ? 'No service address' : booking.address,
              ),
              const SizedBox(height: 16),
              Row(children: [
                Icon(_statusIcon(booking.status), size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(_actionLabel(booking.status), style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                )),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, size: 14,
                    color: Colors.grey.shade500),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: Colors.grey.shade600),
      const SizedBox(width: 9),
      Expanded(child: Text(text, style: TextStyle(
        color: Colors.grey.shade700,
        height: 1.4,
      ))),
    ],
  );
}

class _EmptyJobsCard extends StatelessWidget {
  const _EmptyJobsCard();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(children: [
      Icon(Icons.event_available_outlined, size: 34, color: Colors.grey.shade500),
      const SizedBox(height: 12),
      const Text('No upcoming jobs', style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 16,
      )),
      const SizedBox(height: 6),
      Text('Assigned jobs will appear here after the provider confirms them.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade600, height: 1.4),
      ),
    ]),
  );
}

String _formatServiceName(String value) => value.trim().split('_')
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

IconData _statusIcon(BookingStatus status) {
  if (status == BookingStatus.accepted) return Icons.event_available_outlined;
  if (status == BookingStatus.onTheWay) return Icons.navigation_outlined;
  if (status == BookingStatus.arrived) return Icons.location_on_outlined;
  if (status == BookingStatus.inProgress) return Icons.construction_outlined;
  return Icons.assignment_outlined;
}

String _actionLabel(BookingStatus status) {
  if (status == BookingStatus.accepted) return 'Open job';
  if (status == BookingStatus.onTheWay) return 'Continue journey';
  if (status == BookingStatus.arrived) return 'Continue job';
  if (status == BookingStatus.inProgress) return 'Continue service';
  return 'View job';
}
