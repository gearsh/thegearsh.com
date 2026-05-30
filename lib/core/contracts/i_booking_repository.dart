import 'package:gearsh_app/services/booking_service.dart';

/// Booking data access contract (Dependency Inversion).
abstract class IBookingRepository {
  Future<BookingResult> createBooking({
    required String clientId,
    required String artistId,
    String? serviceId,
    required String eventDate,
    String? eventTime,
    String? eventLocation,
    String? eventType,
    double? durationHours,
    required double totalPrice,
    String? notes,
  });

  Future<List<Booking>> getBookings({
    required String userId,
    String userType = 'client',
    String? status,
  });

  Future<bool> cancelBooking(String bookingId);
  Future<bool> confirmBooking(String bookingId);
  Future<bool> completeBooking(String bookingId);
}
