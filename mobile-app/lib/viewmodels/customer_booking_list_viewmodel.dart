import '../models/booking_model.dart';
import '../services/app_services.dart';
import 'base_viewmodel.dart';

class CustomerBookingListViewModel extends BaseViewModel {
  List<BookingModel> _bookings = [];

  List<BookingModel> get bookings => List.unmodifiable(_bookings);

  Future<void> load() async {
    final uid = AppServices.auth.currentUserId;
    if (uid == null) return;
    setLoading(true);
    try {
      _bookings = await AppServices.booking.getCustomerBookings(uid);
      notifyListeners();
    } catch (e) {
      setError('Unable to load bookings: $e');
    } finally {
      setLoading(false);
    }
  }
}
