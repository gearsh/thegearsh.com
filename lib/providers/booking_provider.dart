import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/services/booking_service.dart';

/// Booking state containing all booking-related data
class BookingState {
  final List<Booking> upcomingBookings;
  final List<Booking> pastBookings;
  final bool isLoading;
  final String? error;

  const BookingState({
    this.upcomingBookings = const [],
    this.pastBookings = const [],
    this.isLoading = false,
    this.error,
  });

  BookingState copyWith({
    List<Booking>? upcomingBookings,
    List<Booking>? pastBookings,
    bool? isLoading,
    String? error,
  }) {
    return BookingState(
      upcomingBookings: upcomingBookings ?? this.upcomingBookings,
      pastBookings: pastBookings ?? this.pastBookings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Booking notifier for managing booking state
class BookingNotifier extends Notifier<BookingState> {
  late final BookingService _bookingService;

  @override
  BookingState build() {
    _bookingService = BookingService();
    return const BookingState();
  }

  /// Load bookings for a user
  Future<void> loadBookings(String userId, {String userType = 'client'}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final allBookings = await _bookingService.getBookings(
        userId: userId,
        userType: userType,
      );

      final now = DateTime.now();
      final upcoming = allBookings.where((b) {
        final eventDate = DateTime.tryParse(b.eventDate);
        return eventDate != null &&
               eventDate.isAfter(now) &&
               b.status != 'cancelled' &&
               b.status != 'completed';
      }).toList();

      final past = allBookings.where((b) {
        final eventDate = DateTime.tryParse(b.eventDate);
        return eventDate != null && eventDate.isBefore(now) ||
               b.status == 'completed' ||
               b.status == 'cancelled';
      }).toList();

      state = state.copyWith(
        upcomingBookings: upcoming,
        pastBookings: past,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load bookings',
      );
    }
  }

  /// Create a new booking
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
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _bookingService.createBooking(
      clientId: clientId,
      artistId: artistId,
      serviceId: serviceId,
      eventDate: eventDate,
      eventTime: eventTime,
      eventLocation: eventLocation,
      eventType: eventType,
      durationHours: durationHours,
      totalPrice: totalPrice,
      notes: notes,
    );

    state = state.copyWith(isLoading: false);

    if (result.success) {
      // Reload bookings to include the new one
      await loadBookings(clientId);
    } else {
      state = state.copyWith(error: result.error);
    }

    return result;
  }

  /// Cancel a booking
  Future<bool> cancelBooking(String bookingId, String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    final success = await _bookingService.cancelBooking(bookingId);

    if (success) {
      // Update local state
      final updatedUpcoming = state.upcomingBookings
          .map((b) => b.id == bookingId
              ? Booking(
                  id: b.id,
                  clientId: b.clientId,
                  artistId: b.artistId,
                  eventDate: b.eventDate,
                  totalPrice: b.totalPrice,
                  status: 'cancelled',
                  createdAt: b.createdAt,
                )
              : b)
          .toList();

      state = state.copyWith(
        upcomingBookings: updatedUpcoming,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel booking',
      );
    }

    return success;
  }

  /// Confirm a booking (for artists)
  Future<bool> confirmBooking(String bookingId, String userId) async {
    final success = await _bookingService.confirmBooking(bookingId);
    if (success) {
      await loadBookings(userId, userType: 'artist');
    }
    return success;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Main booking provider
final bookingProvider = NotifierProvider<BookingNotifier, BookingState>(
  BookingNotifier.new,
);

/// Booking service provider
final bookingServiceProvider = Provider((ref) => BookingService());
