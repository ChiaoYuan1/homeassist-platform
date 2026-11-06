import '../core/app_enums.dart';
import '../models/booking_model.dart';
import '../services/app_services.dart';
import 'base_viewmodel.dart';

class ProviderScheduleViewModel extends BaseViewModel {
  DateTime _selectedDate = DateTime.now();

  List<BookingModel> _bookings = [];

  DateTime get selectedDate => _selectedDate;

  List<BookingModel> get bookings =>
      List.unmodifiable(_bookings);

  Future<void> loadDate(
      DateTime date,
      ) async {
    final uid =
        AppServices.auth.currentUserId;

    if (uid == null) {
      return;
    }

    _selectedDate = date;

    setLoading(true);

    try {
      await AppServices.booking
          .expirePastPendingBookingsForProvider(
        uid,
      );

      final bookings =
      await AppServices.booking
          .getProviderBookingsForDate(
        providerId: uid,
        date: date,
      );

      _bookings = bookings
          .where(
            (booking) => [
          BookingStatus.accepted,
          BookingStatus.onTheWay,
          BookingStatus.arrived,
          BookingStatus.inProgress,
          BookingStatus.completed,
        ].contains(
          booking.status,
        ),
      )
          .toList();

      _bookings.sort(
            (a, b) =>
            a.appointmentStart.compareTo(
              b.appointmentStart,
            ),
      );

      notifyListeners();
    } catch (e) {
      setError(
        'Unable to load schedule: $e',
      );
    } finally {
      setLoading(false);
    }
  }
}