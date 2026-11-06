import '../core/app_enums.dart';
import '../models/booking_model.dart';
import '../services/app_services.dart';
import 'base_viewmodel.dart';

class ProviderDashboardViewModel extends BaseViewModel {
  int pendingCount = 0;
  int todayCount = 0;
  int completedCount = 0;
  int upcomingCount = 0;

  List<BookingModel> todayBookings = [];
  List<BookingModel> upcomingBookings = [];

  Future<void> load() async {
    final uid = AppServices.auth.currentUserId;

    if (uid == null) {
      return;
    }

    setLoading(true);

    try {
      // First clean up any old pending requests.
      await AppServices.booking
          .expirePastPendingBookingsForProvider(
        uid,
      );

      final bookings =
      await AppServices.booking
          .getProviderBookings(
        uid,
      );

      final now = DateTime.now();

      pendingCount = bookings
          .where(
            (booking) =>
        booking.status ==
            BookingStatus.pending,
      )
          .length;

      completedCount = bookings
          .where(
            (booking) =>
        booking.status ==
            BookingStatus.completed,
      )
          .length;

      todayBookings = bookings.where(
            (booking) {
          final appointment =
              booking.appointmentStart;

          final isToday =
              appointment.year == now.year &&
                  appointment.month == now.month &&
                  appointment.day == now.day;

          final isRelevantStatus = ![
            BookingStatus.rejected,
            BookingStatus.cancelled,
            BookingStatus.expired,
          ].contains(
            booking.status,
          );

          return isToday &&
              isRelevantStatus;
        },
      ).toList();

      todayBookings.sort(
            (a, b) =>
            a.appointmentStart.compareTo(
              b.appointmentStart,
            ),
      );

      todayCount = todayBookings.length;

      upcomingBookings = bookings.where(
            (booking) {
          return [
            BookingStatus.accepted,
            BookingStatus.onTheWay,
            BookingStatus.arrived,
            BookingStatus.inProgress,
          ].contains(
            booking.status,
          );
        },
      ).toList();

      upcomingBookings.sort(
            (a, b) =>
            a.appointmentStart.compareTo(
              b.appointmentStart,
            ),
      );

      upcomingCount =
          upcomingBookings.length;

      notifyListeners();
    } catch (e) {
      setError(
        'Unable to load dashboard: $e',
      );
    } finally {
      setLoading(false);
    }
  }
}