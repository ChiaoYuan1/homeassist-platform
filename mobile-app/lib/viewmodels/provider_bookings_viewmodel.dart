import '../core/app_enums.dart';
import '../models/booking_model.dart';
import '../services/app_services.dart';
import 'base_viewmodel.dart';

class ProviderBookingsViewModel extends BaseViewModel {
  List<BookingModel> _bookings = [];

  List<BookingModel> get bookings => List.unmodifiable(_bookings);

  List<BookingModel> get pending => _bookings.where((b) => b.status == BookingStatus.pending).toList();

  List<BookingModel> get upcoming =>
      _bookings.where(
            (b) => ![
          BookingStatus.pending,
          BookingStatus.rejected,
          BookingStatus.cancelled,
          BookingStatus.completed,
          BookingStatus.expired,
        ].contains(b.status),
      ).toList();

  List<BookingModel> get history {
    final historyBookings = _bookings.where(
          (b) => [
        BookingStatus.completed,
        BookingStatus.rejected,
        BookingStatus.cancelled,
        BookingStatus.expired,
      ].contains(b.status),
    ).toList();

    historyBookings.sort(
          (a, b) => b.appointmentStart.compareTo(
        a.appointmentStart,
      ),
    );

    return historyBookings;
  }

  Future<void> load() async {
    final uid =
        AppServices.auth.currentUserId;

    if (uid == null) {
      return;
    }

    setLoading(true);

    try {
      await AppServices.booking
          .expirePastPendingBookingsForProvider(
        uid,
      );

      _bookings =
      await AppServices.booking
          .getProviderBookings(
        uid,
      );

      notifyListeners();
    } catch (e) {
      setError(
        'Unable to load bookings: $e',
      );
    } finally {
      setLoading(false);
    }
  }
}
